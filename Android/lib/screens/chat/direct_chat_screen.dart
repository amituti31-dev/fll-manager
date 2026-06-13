import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import 'chat_screen.dart' show MessageBubble;

class DirectChatScreen extends StatefulWidget {
  final Member member;
  const DirectChatScreen({super.key, required this.member});

  @override
  State<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends State<DirectChatScreen> {
  final _ctrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  bool _sending = false;

  String _privateKey(String myId) {
    final ids = [myId, widget.member.id]..sort();
    return ids.join('_');
  }

  Future<void> _send(AppProvider prov) async {
    final text = _ctrl.text.trim();
    if (text.isEmpty || prov.teamId == null) return;
    setState(() => _sending = true);
    _ctrl.clear();
    final key = _privateKey(prov.currentUser?.id ?? '');
    await FirebaseService.sendChatMessage(
      teamId: prov.teamId!,
      channel: 'private',
      privateKey: key,
      message: ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        authorId: prov.currentUser?.id ?? '',
        authorName: prov.currentUser?.name ?? 'אנונימי',
        text: text,
        ts: DateTime.now().toIso8601String(),
      ),
    );
    setState(() => _sending = false);
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

  @override
  void dispose() {
    _ctrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final tid = prov.teamId;
    final key = _privateKey(prov.currentUser?.id ?? '');

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          CircleAvatar(
            backgroundColor: widget.member.color,
            radius: 16,
            child: Text(
              widget.member.name.isNotEmpty ? widget.member.name[0] : '?',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
          SizedBox(width: 10),
          Text(widget.member.name),
        ]),
      ),
      body: Column(children: [
        Expanded(
          child: tid == null
              ? Center(child: Text('לא מחובר לקבוצה', style: TextStyle(color: AppColors.textTertiary)))
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: FirebaseService.chatStream(tid),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    final data = snap.data?.data();
                    final pvt = data?['private'] as Map?;
                    final rawList = pvt?[key] as List?;
                    final messages = rawList == null
                        ? <ChatMessage>[]
                        : rawList
                            .map((e) => ChatMessage.fromMap(Map<String, dynamic>.from(e as Map)))
                            .toList();

                    if (messages.isEmpty) {
                      return Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Text('💬', style: TextStyle(fontSize: 48)),
                          SizedBox(height: 12),
                          Text('שלח הודעה ל${widget.member.name}',
                              style: TextStyle(color: AppColors.textTertiary)),
                          Text('זו שיחה פרטית', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                        ]),
                      );
                    }

                    return ListView.builder(
                      controller: _scrollCtrl,
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (_, i) => MessageBubble(
                        message: messages[i],
                        isMe: messages[i].authorId == prov.currentUser?.id,
                        member: prov.members.where((m) => m.id == messages[i].authorId).firstOrNull,
                      ),
                    );
                  },
                ),
        ),

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
            Expanded(
              child: TextField(
                controller: _ctrl,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'כתוב הודעה...',
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _send(prov),
              ),
            ),
            SizedBox(width: 8),
            GestureDetector(
              onTap: _sending ? null : () => _send(prov),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _sending ? AppColors.surface2 : AppColors.accent,
                  shape: BoxShape.circle,
                ),
                child: _sending
                    ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}
