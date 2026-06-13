import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class DailyScreen extends StatefulWidget {
  const DailyScreen({super.key});

  static void showAddDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AddLogSheet(),
    );
  }

  @override
  State<DailyScreen> createState() => _DailyScreenState();
}

class _DailyScreenState extends State<DailyScreen> {
  String _filter = '';
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    var items = prov.logs.reversed.toList();
    if (_filter.isNotEmpty) { items = items.where((l) => l.topic == _filter).toList(); }
    if (_search.isNotEmpty) { items = items.where((l) => l.text.contains(_search) || l.author.contains(_search)).toList(); }

    return Column(children: [
      // Filter bar
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.surface,
        child: Row(children: [
          Expanded(
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'חיפוש...', prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          SizedBox(width: 8),
          DropdownButton<String>(
            value: _filter.isEmpty ? null : _filter,
            hint: Text('הכל', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
            dropdownColor: AppColors.surface2,
            style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
            underline: SizedBox.shrink(),
            items: const [
              DropdownMenuItem(value: '', child: Text('הכל')),
              DropdownMenuItem(value: 'robot', child: Text('🤖 רובוט')),
              DropdownMenuItem(value: 'innovation', child: Text('💡 חדשנות')),
              DropdownMenuItem(value: 'values', child: Text('⭐ ערכים')),
              DropdownMenuItem(value: 'general', child: Text('📌 כללי')),
            ],
            onChanged: (v) => setState(() => _filter = v ?? ''),
          ),
        ]),
      ),
      // Timeline
      Expanded(
        child: items.isEmpty
            ? Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text('📋', style: TextStyle(fontSize: 48)),
                  SizedBox(height: 12),
                  Text('אין פעילויות עדיין', style: TextStyle(color: AppColors.textTertiary)),
                  Text('לחץ + להוסיף תיעוד', style: TextStyle(color: AppColors.textTertiary, fontSize: 12)),
                ]),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => SizedBox(height: 12),
                itemBuilder: (_, i) => _LogCard(log: items[i]),
              ),
      ),
    ]);
  }
}

class _LogCard extends StatelessWidget {
  final LogEntry log;
  const _LogCard({required this.log});

  static final _topicConfig = {
    'robot':      ('🤖', AppColors.accent,  'tag-robot'),
    'innovation': ('💡', AppColors.accent2, 'tag-innovation'),
    'values':     ('⭐', AppColors.gold,    'tag-values'),
    'general':    ('📌', AppColors.textSecondary, 'tag-general'),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _topicConfig[log.topic] ?? _topicConfig['general']!;
    final isAdmin = context.read<AppProvider>().isAdmin;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border(left: BorderSide(color: cfg.$2, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(cfg.$1, style: TextStyle(fontSize: 16)),
          SizedBox(width: 6),
          Text(log.author, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          const Spacer(),
          Text(log.date, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          if (isAdmin) ...[
            SizedBox(width: 4),
            GestureDetector(
              onTap: () => _confirmDelete(context),
              child: Text('🗑️', style: TextStyle(fontSize: 16)),
            ),
          ],
        ]),
        SizedBox(height: 8),
        Text(log.text, style: TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5)),
        if (log.imageBase64 != null && log.imageBase64!.startsWith('data:image')) ...[
          SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.memory(
              _decodeBase64Image(log.imageBase64!),
              fit: BoxFit.cover, width: double.infinity, height: 180,
            ),
          ),
        ],
      ]),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('מחיקת רשומה', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('למחוק את הרשומה לצמיתות?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().deleteLog(log.id);
              Navigator.pop(context);
            },
            child: Text('מחק', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }

  static Uint8List _decodeBase64Image(String dataUrl) {
    final raw = dataUrl.contains(',') ? dataUrl.split(',').last : dataUrl;
    return base64Decode(raw);
  }
}

// ─── Add Log Bottom Sheet ─────────────────────────────
class _AddLogSheet extends StatefulWidget {
  const _AddLogSheet();

  @override
  State<_AddLogSheet> createState() => _AddLogSheetState();
}

class _AddLogSheetState extends State<_AddLogSheet> {
  final _textCtrl = TextEditingController();
  String _topic = 'general';
  String? _imageBase64;
  bool _saving = false;
  bool _pickingImage = false;

  @override
  void dispose() { _textCtrl.dispose(); super.dispose(); }

  Future<void> _pickImage() async {
    setState(() => _pickingImage = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 70,
      );
      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() => _imageBase64 = 'data:image/jpeg;base64,${base64Encode(bytes)}');
      }
    } finally {
      if (mounted) setState(() => _pickingImage = false);
    }
  }

  Future<void> _save() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _saving = true);
    final prov = context.read<AppProvider>();
    await prov.addLog(LogEntry(
      id: DateTime.now().millisecondsSinceEpoch,
      topic: _topic,
      text: text,
      author: prov.currentUser?.name ?? 'אנונימי',
      date: DateTime.now().toIso8601String().split('T')[0],
      imageBase64: _imageBase64,
    ));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📝 תיעוד יומי חדש',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        SizedBox(height: 16),
        Row(children: [
          for (final t in [('📌', 'general'), ('🤖', 'robot'), ('💡', 'innovation'), ('⭐', 'values')])
            Expanded(child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GestureDetector(
                onTap: () => setState(() => _topic = t.$2),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _topic == t.$2 ? AppColors.accent.withAlpha(40) : AppColors.surface2,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _topic == t.$2 ? AppColors.accent : AppColors.border),
                  ),
                  child: Text(t.$1, textAlign: TextAlign.center, style: TextStyle(fontSize: 20)),
                ),
              ),
            )),
        ]),
        SizedBox(height: 12),
        TextField(
          controller: _textCtrl,
          maxLines: 4,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: 'מה עשיתם היום?'),
        ),
        SizedBox(height: 10),

        // Image picker row
        Row(children: [
          GestureDetector(
            onTap: _pickingImage ? null : _pickImage,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: _imageBase64 != null ? AppColors.accent2.withAlpha(30) : AppColors.surface2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: _imageBase64 != null ? AppColors.accent2 : AppColors.border),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                _pickingImage
                    ? SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent2))
                    : Icon(_imageBase64 != null ? Icons.check_circle : Icons.add_photo_alternate,
                        size: 18, color: _imageBase64 != null ? AppColors.accent2 : AppColors.textSecondary),
                SizedBox(width: 6),
                Text(_imageBase64 != null ? 'תמונה נבחרה' : 'הוסף תמונה',
                    style: TextStyle(fontSize: 13,
                        color: _imageBase64 != null ? AppColors.accent2 : AppColors.textSecondary)),
              ]),
            ),
          ),
          if (_imageBase64 != null) ...[
            SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _imageBase64 = null),
              child: Icon(Icons.close, size: 18, color: AppColors.textTertiary),
            ),
          ],
        ]),

        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('💾 שמור'),
          ),
        ),
      ]),
    );
  }
}

