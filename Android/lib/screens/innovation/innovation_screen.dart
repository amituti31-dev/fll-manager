import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:record/record.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/image_source_picker.dart';

class InnovationScreen extends StatefulWidget {
  const InnovationScreen({super.key});

  @override
  State<InnovationScreen> createState() => _InnovationScreenState();
}

class _InnovationScreenState extends State<InnovationScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return Column(children: [
      Container(
        color: AppColors.surface,
        child: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.accent2,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent2,
          tabs: const [
            Tab(text: '🎯 פרויקט'),
            Tab(text: '🔬 מחקר'),
            Tab(text: '💡 רעיונות'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _ProjectTab(prov: prov),
            _ResearchTab(prov: prov),
            _IdeasTab(prov: prov),
          ],
        ),
      ),
    ]);
  }
}

// ─── Tab 1: Project (Problem + Solution + Sharing) ────

class _ProjectTab extends StatelessWidget {
  final AppProvider prov;
  const _ProjectTab({required this.prov});

  @override
  Widget build(BuildContext context) {
    final sharingLogs = prov.logs.where((l) => l.topic == 'sharing').toList().reversed.toList();

    return ListView(padding: const EdgeInsets.all(16), children: [

      // Progress overview
      _ProgressBar(prov: prov),
      SizedBox(height: 16),

      // Problem section
      _TextSection(
        icon: '🔍',
        title: 'הגדרת הבעיה',
        subtitle: 'איזו בעיה אמיתית זיהיתם?',
        color: const Color(0xFF3D7FFF),
        text: prov.innovationProblem,
        placeholder: 'טרם הוגדרה הבעיה.\nלחצו על עריכה כדי להגדיר את הבעיה שהקבוצה מתמודדת איתה.',
        onEdit: (ctx) => _showEditDialog(
          ctx, 'הגדרת הבעיה', prov.innovationProblem,
          onSave: (t) => prov.updateInnovationProblem(t),
          hint: 'תארו את הבעיה: מה קורה, למי זה משפיע, למה זה חשוב...',
        ),
      ),
      SizedBox(height: 12),

      // Solution section
      _TextSection(
        icon: '✅',
        title: 'הפתרון שלנו',
        subtitle: 'מה הפתרון שבחרתם ולמה?',
        color: const Color(0xFF00D4A0),
        text: prov.innovationSolution,
        placeholder: 'טרם הוגדר פתרון.\nאחרי סיעור מוחות — תארו את הפתרון שבחרתם.',
        onEdit: (ctx) => _showEditDialog(
          ctx, 'הפתרון שלנו', prov.innovationSolution,
          onSave: (t) => prov.updateInnovationSolution(t),
          hint: 'תארו את הפתרון, למה בחרתם בו ומה הופך אותו לחדשני...',
        ),
      ),
      SizedBox(height: 12),

      // Sharing section
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('📢', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('שיתוף עם הקהילה',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
                Text('עם מי שיתפתם את הפתרון?',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ]),
            ),
            GestureDetector(
              onTap: () => _showAddSharing(context),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B35).withAlpha(30),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('+ הוסף',
                    style: TextStyle(fontSize: 12, color: Color(0xFFFF6B35), fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
          if (sharingLogs.isEmpty) ...[
            SizedBox(height: 12),
            Text('אין תיעוד שיתוף עדיין',
                style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
          ] else ...[
            SizedBox(height: 10),
            for (final log in sharingLogs) _SharingCard(log: log),
          ],
        ]),
      ),
    ]);
  }

  static void _showEditDialog(
    BuildContext context,
    String title,
    String currentText, {
    required Future<void> Function(String) onSave,
    required String hint,
  }) {
    final ctrl = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(title, style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          maxLines: 6,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
          ElevatedButton(
            onPressed: () async {
              await onSave(ctrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('שמור'),
          ),
        ],
      ),
    );
  }

  static void _showAddSharing(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddSharingSheet(),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final AppProvider prov;
  const _ProgressBar({required this.prov});

  @override
  Widget build(BuildContext context) {
    final hasProblem   = prov.innovationProblem.isNotEmpty;
    final hasResearch  = prov.logs.any((l) => l.topic == 'research');
    final hasIdeas     = prov.logs.any((l) => l.topic == 'ideas');
    final hasSolution  = prov.innovationSolution.isNotEmpty;
    final hasSharing   = prov.logs.any((l) => l.topic == 'sharing');
    final done = [hasProblem, hasResearch, hasIdeas, hasSolution, hasSharing].where((b) => b).length;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0x1A00D4A0), Color(0x0A3D7FFF)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Row(children: [
          Text('💡', style: TextStyle(fontSize: 22)),
          SizedBox(width: 10),
          Expanded(
            child: Text('התקדמות פרויקט חדשנות',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
          ),
          Text('$done/5 שלבים',
              style: TextStyle(fontSize: 12, color: AppColors.accent2, fontWeight: FontWeight.w700)),
        ]),
        SizedBox(height: 10),
        Row(children: [
          for (final item in [
            (hasProblem,  '🔍', 'בעיה'),
            (hasResearch, '🔬', 'מחקר'),
            (hasIdeas,    '💭', 'רעיונות'),
            (hasSolution, '✅', 'פתרון'),
            (hasSharing,  '📢', 'שיתוף'),
          ]) ...[
            Expanded(
              child: Column(children: [
                Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: item.$1 ? AppColors.accent2 : AppColors.surface3,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                SizedBox(height: 4),
                Text(item.$3,
                    style: TextStyle(
                      fontSize: 9,
                      color: item.$1 ? AppColors.accent2 : AppColors.textTertiary,
                      fontWeight: item.$1 ? FontWeight.w700 : FontWeight.w400,
                    )),
              ]),
            ),
            if (item != (hasSharing, '📢', 'שיתוף')) SizedBox(width: 4),
          ],
        ]),
      ]),
    );
  }
}

class _TextSection extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final String text;
  final String placeholder;
  final void Function(BuildContext) onEdit;

  const _TextSection({
    required this.icon, required this.title, required this.subtitle,
    required this.color, required this.text, required this.placeholder,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = text.isEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 4)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: TextStyle(fontSize: 20)),
          SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: color)),
            Text(subtitle, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ])),
          GestureDetector(
            onTap: () => onEdit(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(25),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(isEmpty ? Icons.add : Icons.edit, size: 12, color: color),
                SizedBox(width: 4),
                Text(isEmpty ? 'הגדר' : 'ערוך',
                    style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
              ]),
            ),
          ),
        ]),
        SizedBox(height: 10),
        Text(
          isEmpty ? placeholder : text,
          style: TextStyle(
            fontSize: 13,
            color: isEmpty ? AppColors.textTertiary : AppColors.textPrimary,
            height: 1.5,
            fontStyle: isEmpty ? FontStyle.italic : FontStyle.normal,
          ),
        ),
      ]),
    );
  }
}

class _SharingCard extends StatelessWidget {
  final LogEntry log;
  const _SharingCard({required this.log});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AppProvider>().isAdmin;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B35).withAlpha(15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFF6B35).withAlpha(60)),
      ),
      child: Row(children: [
        Text('📢', style: TextStyle(fontSize: 14)),
        SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (log.title != null && log.title!.isNotEmpty)
            Text(log.title!, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
          if (log.text.isNotEmpty)
            Text(log.text, style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        ])),
        Text(log.date, style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
        if (isAdmin) ...[
          SizedBox(width: 6),
          GestureDetector(
            onTap: () => context.read<AppProvider>().deleteLog(log.id),
            child: Icon(Icons.close, size: 14, color: AppColors.red),
          ),
        ],
      ]),
    );
  }
}

class _AddSharingSheet extends StatefulWidget {
  const _AddSharingSheet();
  @override
  State<_AddSharingSheet> createState() => _AddSharingSheetState();
}

class _AddSharingSheetState extends State<_AddSharingSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final prov = context.read<AppProvider>();
    await prov.addLog(LogEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      topic: 'sharing',
      title: _titleCtrl.text.trim(),
      text: _descCtrl.text.trim(),
      author: prov.currentUser?.name ?? 'אנונימי',
      date: DateTime.now().toIso8601String().split('T')[0],
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📢 שיתוף עם הקהילה',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        SizedBox(height: 4),
        Text('עם מי שיתפתם? ארגון, בית ספר, כנס?',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        SizedBox(height: 14),
        TextField(
          controller: _titleCtrl, autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: 'שם האירוע / הארגון *'),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _descCtrl, maxLines: 2,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: 'תיאור קצר (אופציונלי)'),
        ),
        SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF6B35)),
            child: _saving
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('💾 שמור'),
          ),
        ),
      ]),
    );
  }
}

// ─── Tab 2: Research ──────────────────────────────────

class _ResearchTab extends StatelessWidget {
  final AppProvider prov;
  const _ResearchTab({required this.prov});

  @override
  Widget build(BuildContext context) {
    final findings = prov.logs.where((l) => l.topic == 'research').toList().reversed.toList();

    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0x1A6C63FF), Color(0x0A00D4A0)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text('🔬', style: TextStyle(fontSize: 22)),
            SizedBox(width: 8),
            Text('ממצאי מחקר', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
          ]),
          SizedBox(height: 4),
          Text('תעדו מקורות, ראיונות עם מומחים, נתונים ותובנות',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.5)),
          if (findings.isNotEmpty) ...[
            SizedBox(height: 8),
            Row(children: [
              _StatChip('📄', '${findings.length}', 'ממצאים'),
              SizedBox(width: 8),
              _StatChip('👤', '${findings.map((f) => f.author).toSet().length}', 'תורמים'),
            ]),
          ],
        ]),
      ),
      SizedBox(height: 12),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showAddFinding(context),
          icon: Text('➕'),
          label: Text('הוסף ממצא'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6C63FF),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      SizedBox(height: 16),

      if (findings.isEmpty)
        Container(
          height: 140, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('🔬', style: TextStyle(fontSize: 36)),
            SizedBox(height: 8),
            Text('אין ממצאים עדיין', style: TextStyle(color: AppColors.textTertiary)),
            Text('לחץ + להוסיף ממצא ראשון', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ]),
        )
      else
        for (final f in findings) _FindingCard(finding: f),
    ]);
  }

  static void _showAddFinding(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddFindingSheet(),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String icon;
  final String value;
  final String label;
  const _StatChip(this.icon, this.value, this.label);

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.border)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(icon, style: TextStyle(fontSize: 13)),
      SizedBox(width: 5),
      Text(value, style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary)),
      SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
    ]),
  );
}

class _FindingCard extends StatefulWidget {
  final LogEntry finding;
  const _FindingCard({required this.finding});
  @override
  State<_FindingCard> createState() => _FindingCardState();
}

class _FindingCardState extends State<_FindingCard> {
  final _player = AudioPlayer();
  bool _playing = false;

  @override
  void dispose() { _player.dispose(); super.dispose(); }

  Future<void> _togglePlay() async {
    if (_playing) {
      await _player.stop();
      setState(() => _playing = false);
    } else {
      final path = widget.finding.audioPath;
      if (path == null || !File(path).existsSync()) return;
      await _player.play(DeviceFileSource(path));
      setState(() => _playing = true);
      _player.onPlayerComplete.listen((_) { if (mounted) setState(() => _playing = false); });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AppProvider>().isAdmin;
    final f = widget.finding;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: Color(0xFF6C63FF), width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🔬', style: TextStyle(fontSize: 14)),
          SizedBox(width: 6),
          Text(f.author, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Text(f.date, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          if (isAdmin) ...[
            SizedBox(width: 4),
            GestureDetector(
              onTap: () => context.read<AppProvider>().deleteLog(f.id),
              child: Text('🗑️', style: TextStyle(fontSize: 14)),
            ),
          ],
        ]),
        if (f.title != null && f.title!.isNotEmpty) ...[
          SizedBox(height: 6),
          Text(f.title!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        ],
        if (f.text.isNotEmpty) ...[
          SizedBox(height: 4),
          Text(f.text, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ],
        if (f.imageBase64 != null) ...[
          SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Builder(builder: (_) {
              try {
                final raw = f.imageBase64!.contains(',') ? f.imageBase64!.split(',').last : f.imageBase64!;
                return Image.memory(base64Decode(raw), fit: BoxFit.cover, width: double.infinity, height: 160,
                    errorBuilder: (_, __, ___) => SizedBox.shrink());
              } catch (_) { return SizedBox.shrink(); }
            }),
          ),
        ],
        if (f.audioPath != null) ...[
          SizedBox(height: 8),
          GestureDetector(
            onTap: _togglePlay,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6C63FF).withAlpha(30),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF6C63FF).withAlpha(80)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(_playing ? Icons.stop : Icons.play_arrow, color: const Color(0xFF6C63FF), size: 18),
                SizedBox(width: 6),
                Text(_playing ? 'עצור' : 'נגן הקלטה',
                    style: TextStyle(fontSize: 12, color: Color(0xFF6C63FF))),
              ]),
            ),
          ),
        ],
      ]),
    );
  }
}

class _AddFindingSheet extends StatefulWidget {
  const _AddFindingSheet();
  @override
  State<_AddFindingSheet> createState() => _AddFindingSheetState();
}

class _AddFindingSheetState extends State<_AddFindingSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _saving = false;
  String? _imageBase64;
  bool _pickingImage = false;
  final _recorder = AudioRecorder();
  bool _recording = false;
  String? _audioPath;

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); _recorder.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    try {
      final picked = await pickImageWithSource(context, maxWidth: 800, maxHeight: 800, quality: 70);
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(() => _imageBase64 = base64Encode(bytes));
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _toggleRecord() async {
    if (_recording) {
      final path = await _recorder.stop();
      setState(() { _recording = false; _audioPath = path; });
    } else {
      if (!await _recorder.hasPermission()) return;
      final dir = await getApplicationDocumentsDirectory();
      final path = '${dir.path}/finding_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _recorder.start(const RecordConfig(), path: path);
      setState(() { _recording = true; _audioPath = null; });
    }
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty && _descCtrl.text.trim().isEmpty) return;
    final prov  = context.read<AppProvider>();
    final title = _titleCtrl.text.trim();
    final desc  = _descCtrl.text.trim();
    final img   = _imageBase64;
    if (_recording) {
      final path = await _recorder.stop();
      setState(() { _recording = false; _audioPath = path; });
    }
    setState(() => _saving = true);
    final audio = _audioPath;
    await prov.addLog(LogEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      topic: 'research',
      text: desc,
      author: prov.currentUser?.name ?? 'אנונימי',
      date: DateTime.now().toIso8601String().split('T')[0],
      title: title.isEmpty ? null : title,
      imageBase64: img,
      audioPath: audio,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('🔬 הוסף ממצא מחקר',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        SizedBox(height: 16),
        TextField(controller: _titleCtrl,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'מקור / נושא / כותרת')),
        SizedBox(height: 8),
        TextField(controller: _descCtrl, maxLines: 3, autofocus: true,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'מה גיליתם? מה למדתם?')),
        SizedBox(height: 10),

        if (_imageBase64 != null) ...[
          Stack(children: [
            ClipRRect(borderRadius: BorderRadius.circular(8),
              child: Builder(builder: (_) {
                try { return Image.memory(base64Decode(_imageBase64!), width: double.infinity, height: 120, fit: BoxFit.cover); }
                catch (_) { return SizedBox.shrink(); }
              }),
            ),
            Positioned(top: 4, right: 4,
              child: GestureDetector(
                onTap: () => setState(() => _imageBase64 = null),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: Icon(Icons.close, color: Colors.white, size: 14),
                ),
              ),
            ),
          ]),
          SizedBox(height: 8),
        ],

        if (_audioPath != null && !_recording) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent2.withAlpha(30), borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.accent2.withAlpha(80)),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle, color: AppColors.accent2, size: 14),
              SizedBox(width: 6),
              Text('הקלטה נשמרה', style: TextStyle(fontSize: 12, color: AppColors.accent2)),
            ]),
          ),
          SizedBox(height: 8),
        ],

        Row(children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickingImage ? null : _pickImage,
              icon: _pickingImage
                  ? SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.image, size: 16),
              label: Text(_imageBase64 != null ? 'החלף' : 'תמונה', style: TextStyle(fontSize: 13)),
              style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary),
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _toggleRecord,
              icon: Icon(_recording ? Icons.stop : Icons.mic, size: 16,
                  color: _recording ? AppColors.red : null),
              label: Text(_recording ? 'עצור' : (_audioPath != null ? 'הקלט שוב' : 'הקלטה'),
                  style: TextStyle(fontSize: 13, color: _recording ? AppColors.red : null)),
              style: OutlinedButton.styleFrom(
                foregroundColor: _recording ? AppColors.red : AppColors.textSecondary,
                side: _recording ? BorderSide(color: AppColors.red) : null,
              ),
            ),
          ),
        ]),
        SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6C63FF)),
            child: _saving
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('💾 שמור ממצא'),
          ),
        ),
      ]),
    );
  }
}

// ─── Tab 3: Ideas ─────────────────────────────────────

class _IdeasTab extends StatelessWidget {
  final AppProvider prov;
  const _IdeasTab({required this.prov});

  @override
  Widget build(BuildContext context) {
    final ideas = prov.logs.where((l) => l.topic == 'ideas').toList().reversed.toList();

    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [Color(0x1AFFD700), Color(0x1AFF6B35)]),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          Text('💭', style: TextStyle(fontSize: 28)),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('סיעור מוחות',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
            Text('${ideas.length} רעיונות — רשמו את כל הרעיונות לפתרון',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
        ]),
      ),
      SizedBox(height: 12),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _showAddIdea(context),
          icon: Text('💡'),
          label: Text('הוסף רעיון'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
      SizedBox(height: 16),

      if (ideas.isEmpty)
        Container(
          height: 140, alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('💭', style: TextStyle(fontSize: 36)),
            SizedBox(height: 8),
            Text('אין רעיונות עדיין', style: TextStyle(color: AppColors.textTertiary)),
            Text('כל רעיון — גם מוזר — ראוי לתיעוד!',
                style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
          ]),
        )
      else
        for (final idea in ideas) _IdeaCard(idea: idea),
    ]);
  }

  static void _showAddIdea(BuildContext context) {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _AddIdeaSheet(),
    );
  }
}

class _IdeaCard extends StatelessWidget {
  final LogEntry idea;
  const _IdeaCard({required this.idea});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AppProvider>().isAdmin;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface, borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: AppColors.gold, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('💡', style: TextStyle(fontSize: 14)),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              idea.title != null && idea.title!.isNotEmpty ? idea.title! : 'רעיון ללא שם',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
          ),
          if (isAdmin)
            GestureDetector(
              onTap: () => context.read<AppProvider>().deleteLog(idea.id),
              child: Icon(Icons.delete_outline, size: 16, color: AppColors.red),
            ),
        ]),
        if (idea.text.isNotEmpty) ...[
          SizedBox(height: 6),
          Text(idea.text,
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.5)),
        ],
        SizedBox(height: 6),
        Text('${idea.author} · ${idea.date}',
            style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
      ]),
    );
  }
}

class _AddIdeaSheet extends StatefulWidget {
  const _AddIdeaSheet();
  @override
  State<_AddIdeaSheet> createState() => _AddIdeaSheetState();
}

class _AddIdeaSheetState extends State<_AddIdeaSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl  = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _titleCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    final prov = context.read<AppProvider>();
    await prov.addLog(LogEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      topic: 'ideas',
      title: _titleCtrl.text.trim(),
      text: _descCtrl.text.trim(),
      author: prov.currentUser?.name ?? 'אנונימי',
      date: DateTime.now().toIso8601String().split('T')[0],
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('💡 רעיון חדש',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        SizedBox(height: 4),
        Text('כל רעיון שווה — גם אם נשמע לא מעשי',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        SizedBox(height: 14),
        TextField(
          controller: _titleCtrl, autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: 'שם הרעיון *'),
        ),
        SizedBox(height: 8),
        TextField(
          controller: _descCtrl, maxLines: 3,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: 'פרטים, יתרונות, חסרונות... (אופציונלי)'),
        ),
        SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold, foregroundColor: Colors.black87),
            child: _saving
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('💾 שמור רעיון'),
          ),
        ),
      ]),
    );
  }
}
