import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  String _channel = 'general';
  bool _sending = false;

  static const _publicChannels = [
    ('💬', 'general', 'כללי'),
    ('🤖', 'robot',   'רובוט'),
    ('💡', 'innov',   'חדשנות'),
  ];

  static const _mentorChannel = ('👑', 'mentors', 'מנטורים');

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _send(AppProvider prov) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || prov.teamId == null) return;
    setState(() => _sending = true);
    _ctrl.clear();
    await FirebaseService.sendChatMessage(
      teamId: prov.teamId!,
      channel: _channel,
      message: ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        authorId: prov.currentUser?.id ?? '',
        authorName: prov.currentUser?.name ?? 'אנונימי',
        text: text,
        ts: DateTime.now().toIso8601String(),
      ),
    );
    setState(() => _sending = false);
    _scrollToBottom();
  }

  Future<void> _sendAnnouncement(AppProvider prov, String text) async {
    if (text.isEmpty || prov.teamId == null) return;
    await FirebaseService.sendChatMessage(
      teamId: prov.teamId!,
      channel: _channel,
      message: ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        authorId: prov.currentUser?.id ?? '',
        authorName: prov.currentUser?.name ?? '',
        text: text,
        ts: DateTime.now().toIso8601String(),
        isAnnouncement: true,
      ),
    );
    _scrollToBottom();
  }

  Future<void> _sendPoll(AppProvider prov, String question, List<String> options) async {
    if (prov.teamId == null) return;
    await FirebaseService.sendChatMessage(
      teamId: prov.teamId!,
      channel: _channel,
      message: ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        authorId: prov.currentUser?.id ?? '',
        authorName: prov.currentUser?.name ?? '',
        text: question,
        ts: DateTime.now().toIso8601String(),
        isPoll: true,
        pollOptions: options,
        pollVotes: const {},
      ),
    );
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showAnnouncementDialog(AppProvider prov) {
    showDialog(
      context: context,
      builder: (_) => _AnnouncementDialog(
        onSend: (text) => _sendAnnouncement(prov, text),
      ),
    );
  }

  void _showPollDialog(AppProvider prov) {
    showDialog(
      context: context,
      builder: (_) => _CreatePollDialog(
        onSend: (question, options) => _sendPoll(prov, question, options),
      ),
    );
  }

  List<(String, String, String)> _visibleChannels(AppProvider prov) => [
    ..._publicChannels,
    if (prov.isAdmin) _mentorChannel,
  ];

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final tid = prov.teamId;
    final channels = _visibleChannels(prov);

    return Column(children: [
      // Channel tabs
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(children: [
          for (final ch in channels)
            Expanded(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: GestureDetector(
                onTap: () => setState(() => _channel = ch.$2),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color: _channel == ch.$2 ? AppColors.accent.withAlpha(30) : AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _channel == ch.$2 ? AppColors.accent : AppColors.border,
                    ),
                  ),
                  child: Column(children: [
                    Text(ch.$1, style: TextStyle(fontSize: 16)),
                    Text(ch.$3, style: TextStyle(
                      fontSize: 10,
                      color: _channel == ch.$2 ? AppColors.accent : AppColors.textSecondary,
                      fontWeight: _channel == ch.$2 ? FontWeight.w700 : FontWeight.normal,
                    )),
                  ]),
                ),
              ),
            )),
        ]),
      ),

      // Messages
      Expanded(
        child: tid == null
            ? Center(child: Text('לא מחובר לקבוצה', style: TextStyle(color: AppColors.textTertiary)))
            : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseService.chatStream(tid),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snap.data?.data();
                  final rawList = data?[_channel] as List?;
                  final messages = rawList == null
                      ? <ChatMessage>[]
                      : rawList
                          .map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e as Map)))
                          .toList();

                  if (messages.isEmpty) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('💬', style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text('אין הודעות עדיין', style: TextStyle(color: AppColors.textTertiary)),
                        Text('היה הראשון לכתוב!', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                      ]),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (_, i) {
                      final msg = messages[i];
                      if (msg.isAnnouncement) return AnnouncementBubble(message: msg);
                      if (msg.isPoll) return PollBubble(
                        message: msg,
                        teamId: tid,
                        channel: _channel,
                        currentUserId: prov.currentUser?.id ?? '',
                        isAdmin: prov.isAdmin,
                      );
                      return MessageBubble(
                        message: msg,
                        isMe: msg.authorId == prov.currentUser?.id,
                        member: prov.members.where((m) => m.id == msg.authorId).firstOrNull,
                      );
                    },
                  );
                },
              ),
      ),

      // Input bar
      Container(
        padding: EdgeInsets.only(
          left: 12, right: 12, top: 8,
          bottom: MediaQuery.of(context).viewInsets.bottom + 8,
        ),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.border)),
        ),
        child: Row(children: [
          if (prov.isAdmin) ...[
            // Announcement button
            _InputAction(
              emoji: '📢',
              color: AppColors.gold,
              onTap: () => _showAnnouncementDialog(prov),
            ),
            const SizedBox(width: 6),
            // Poll button
            _InputAction(
              emoji: '🗳️',
              color: AppColors.accent,
              onTap: () => _showPollDialog(prov),
            ),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: TextField(
              controller: _ctrl,
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: const InputDecoration(
                hintText: 'כתוב הודעה...',
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              onSubmitted: (_) => _send(prov),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : () => _send(prov),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _sending ? AppColors.surface2 : AppColors.accent,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ]),
      ),
    ]);
  }
}

// ─── Input action button ──────────────────────────────
class _InputAction extends StatelessWidget {
  final String emoji;
  final Color color;
  final VoidCallback onTap;
  const _InputAction({required this.emoji, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        shape: BoxShape.circle,
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Text(emoji, style: const TextStyle(fontSize: 16)),
    ),
  );
}

// ─── Poll bubble ──────────────────────────────────────
class PollBubble extends StatefulWidget {
  final ChatMessage message;
  final String teamId;
  final String channel;
  final String currentUserId;
  final bool isAdmin;
  const PollBubble({
    super.key,
    required this.message,
    required this.teamId,
    required this.channel,
    required this.currentUserId,
    required this.isAdmin,
  });

  @override
  State<PollBubble> createState() => _PollBubbleState();
}

class _PollBubbleState extends State<PollBubble> {
  bool _voting = false;

  ChatMessage get msg => widget.message;
  int? get _myVote => msg.pollVotes[widget.currentUserId];
  bool get _hasVoted => msg.pollVotes.containsKey(widget.currentUserId);
  int get _total => msg.pollVotes.length;
  int _countFor(int i) => msg.pollVotes.values.where((v) => v == i).length;

  int _winnerIndex() {
    if (_total == 0) return -1;
    int best = -1, bestCount = -1;
    for (var i = 0; i < msg.pollOptions.length; i++) {
      final c = _countFor(i);
      if (c > bestCount) { bestCount = c; best = i; }
    }
    return best;
  }

  String _formatTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  Future<void> _vote(int optionIndex) async {
    if (msg.pollClosed || _voting) return;
    setState(() => _voting = true);
    await FirebaseService.voteChatPoll(
      teamId: widget.teamId,
      channel: widget.channel,
      messageId: msg.id,
      memberId: widget.currentUserId,
      optionIndex: optionIndex,
    );
    if (mounted) setState(() => _voting = false);
  }

  Future<void> _close() async {
    await FirebaseService.closeChatPoll(
      teamId: widget.teamId,
      channel: widget.channel,
      messageId: msg.id,
    );
  }

  @override
  Widget build(BuildContext context) {
    final showResults = _hasVoted || msg.pollClosed;
    final winner = msg.pollClosed ? _winnerIndex() : -1;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: msg.pollClosed
                ? AppColors.border
                : AppColors.accent.withAlpha(70),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              const Text('🗳️', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(msg.text,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary)),
              ),
              Text(_formatTime(msg.ts),
                  style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
            ]),
            const SizedBox(height: 3),
            Text('${msg.authorName} · $_total הצביעו',
                style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
            const SizedBox(height: 10),

            // Options
            if (!showResults)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(msg.pollOptions.length, (i) => GestureDetector(
                  onTap: _voting ? null : () => _vote(i),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accent.withAlpha(80)),
                    ),
                    child: _voting
                        ? const SizedBox(width: 14, height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(msg.pollOptions[i],
                            style: TextStyle(
                                fontSize: 13,
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600)),
                  ),
                )),
              )
            else
              Column(children: List.generate(msg.pollOptions.length, (i) {
                final count = _countFor(i);
                final pct = _total == 0 ? 0.0 : count / _total;
                final isMyVote = _myVote == i;
                final isWinner = i == winner;
                final barColor = isWinner
                    ? AppColors.gold
                    : isMyVote
                        ? AppColors.accent
                        : AppColors.accent.withAlpha(50);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      if (isWinner && msg.pollClosed)
                        const Padding(padding: EdgeInsets.only(right: 4),
                            child: Text('🏆', style: TextStyle(fontSize: 12))),
                      if (isMyVote && !isWinner)
                        Padding(padding: const EdgeInsets.only(right: 4),
                            child: Icon(Icons.check_circle, size: 13, color: AppColors.accent)),
                      Expanded(
                        child: Text(msg.pollOptions[i],
                            style: TextStyle(
                                fontSize: 13,
                                color: isWinner ? AppColors.gold : AppColors.textPrimary,
                                fontWeight: isWinner || isMyVote ? FontWeight.w700 : FontWeight.normal)),
                      ),
                      Text('$count',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600)),
                    ]),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 6,
                        backgroundColor: AppColors.surface2,
                        valueColor: AlwaysStoppedAnimation<Color>(barColor),
                      ),
                    ),
                  ]),
                );
              })),

            // Footer
            const SizedBox(height: 4),
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: msg.pollClosed ? AppColors.surface2 : AppColors.accent2.withAlpha(20),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  msg.pollClosed ? '🔒 סגור' : '🟢 פתוח',
                  style: TextStyle(
                      fontSize: 11,
                      color: msg.pollClosed ? AppColors.textTertiary : AppColors.accent2,
                      fontWeight: FontWeight.w600),
                ),
              ),
              if (widget.isAdmin && !msg.pollClosed) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _close,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surface2,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Text('סגור הצבעה',
                        style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                  ),
                ),
              ],
              if (!msg.pollClosed && !_hasVoted) ...[
                const Spacer(),
                Text('לחץ להצביע',
                    style: TextStyle(fontSize: 11, color: AppColors.accent)),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Announcement bubble ──────────────────────────────
class AnnouncementBubble extends StatelessWidget {
  final ChatMessage message;
  const AnnouncementBubble({super.key, required this.message});

  String _formatTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.gold.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withAlpha(80)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Text('📢', style: TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Expanded(
            child: Text('הכרזה מ-${message.authorName}',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.gold)),
          ),
          Text(_formatTime(message.ts),
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
        ]),
        const SizedBox(height: 8),
        Text(message.text,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
      ]),
    );
  }
}

// ─── Announcement dialog ──────────────────────────────
class _AnnouncementDialog extends StatefulWidget {
  final Future<void> Function(String) onSend;
  const _AnnouncementDialog({required this.onSend});

  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _ctrl = TextEditingController();
  bool _sending = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(children: [
        const Text('📢', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text('הכרזה קבוצתית', style: TextStyle(color: AppColors.textPrimary)),
      ]),
      content: TextField(
        controller: _ctrl,
        autofocus: true,
        maxLines: 3,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: const InputDecoration(hintText: 'כתוב את ההכרזה...'),
      ),
      actions: [
        TextButton(onPressed: _sending ? null : () => Navigator.pop(context), child: const Text('ביטול')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.gold, foregroundColor: Colors.black),
          onPressed: _sending ? null : () async {
            final text = _ctrl.text.trim();
            if (text.isEmpty) return;
            setState(() => _sending = true);
            await widget.onSend(text);
            if (mounted) Navigator.pop(context);
          },
          child: _sending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('שלח הכרזה'),
        ),
      ],
    );
  }
}

// ─── Create poll dialog ───────────────────────────────
class _CreatePollDialog extends StatefulWidget {
  final Future<void> Function(String question, List<String> options) onSend;
  const _CreatePollDialog({required this.onSend});

  @override
  State<_CreatePollDialog> createState() => _CreatePollDialogState();
}

class _CreatePollDialogState extends State<_CreatePollDialog> {
  final _questionCtrl = TextEditingController();
  final List<TextEditingController> _optionCtrls = [
    TextEditingController(),
    TextEditingController(),
  ];
  bool _sending = false;

  @override
  void dispose() {
    _questionCtrl.dispose();
    for (final c in _optionCtrls) c.dispose();
    super.dispose();
  }

  void _addOption() {
    if (_optionCtrls.length >= 4) return;
    setState(() => _optionCtrls.add(TextEditingController()));
  }

  void _removeOption(int i) {
    if (_optionCtrls.length <= 2) return;
    _optionCtrls[i].dispose();
    setState(() => _optionCtrls.removeAt(i));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Row(children: [
        const Text('🗳️', style: TextStyle(fontSize: 20)),
        const SizedBox(width: 8),
        Text('הצבעה חדשה', style: TextStyle(color: AppColors.textPrimary)),
      ]),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _questionCtrl,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(hintText: 'שאלת ההצבעה...'),
          ),
          const SizedBox(height: 14),
          ...List.generate(_optionCtrls.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _optionCtrls[i],
                  style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'אפשרות ${i + 1}',
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              if (_optionCtrls.length > 2) ...[
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => _removeOption(i),
                  child: Icon(Icons.remove_circle_outline, color: AppColors.red, size: 20),
                ),
              ],
            ]),
          )),
          if (_optionCtrls.length < 4)
            TextButton.icon(
              onPressed: _addOption,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('הוסף אפשרות'),
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: _sending ? null : () => Navigator.pop(context), child: const Text('ביטול')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          onPressed: _sending ? null : () async {
            final question = _questionCtrl.text.trim();
            final options = _optionCtrls
                .map((c) => c.text.trim())
                .where((s) => s.isNotEmpty)
                .toList();
            if (question.isEmpty || options.length < 2) return;
            setState(() => _sending = true);
            await widget.onSend(question, options);
            if (mounted) Navigator.pop(context);
          },
          child: _sending
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('שלח הצבעה'),
        ),
      ],
    );
  }
}

// ─── Message bubble ───────────────────────────────────
class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final Member? member;

  const MessageBubble({super.key, required this.message, required this.isMe, this.member});

  String _formatTime(String ts) {
    try {
      final dt = DateTime.parse(ts).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final avatarColor = member?.color ?? AppColors.accent;
    final initial = message.authorName.isNotEmpty ? message.authorName[0] : '?';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: isMe
            ? [_bubble(), const SizedBox(width: 8), _avatar(avatarColor, initial)]
            : [_avatar(avatarColor, initial), const SizedBox(width: 8), _bubble()],
      ),
    );
  }

  Widget _avatar(Color color, String initial) => CircleAvatar(
    backgroundColor: color, radius: 14,
    child: Text(initial,
        style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
  );

  Widget _bubble() {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isMe ? AppColors.accent : AppColors.surface2,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start, children: [
          if (!isMe)
            Text(message.authorName,
                style: TextStyle(fontSize: 11, color: AppColors.accent, fontWeight: FontWeight.w700)),
          if (!isMe) const SizedBox(height: 2),
          Text(message.text,
              style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: 2),
          Text(_formatTime(message.ts),
              style: TextStyle(fontSize: 10, color: isMe ? Colors.white60 : AppColors.textTertiary)),
        ]),
      ),
    );
  }
}
