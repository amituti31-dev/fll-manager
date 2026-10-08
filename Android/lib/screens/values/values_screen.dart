import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class ValuesScreen extends StatefulWidget {
  const ValuesScreen({super.key});

  @override
  State<ValuesScreen> createState() => _ValuesScreenState();
}

class _ValuesScreenState extends State<ValuesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
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
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: '⭐ ערכי FLL'),
            Tab(text: '📌 לוח פתקים'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _StickiesTab(prov: prov),
            _BoardTab(prov: prov),
          ],
        ),
      ),
    ]);
  }
}

// ─── Stickies Tab ─────────────────────────────────────

class _StickiesTab extends StatelessWidget {
  final AppProvider prov;
  const _StickiesTab({required this.prov});

  static const _values = [
    ('🔍', 'גילוי',      'discovery',  Color(0xFF3D7FFF)),
    ('💡', 'חדשנות',    'innovation', Color(0xFF00D4A0)),
    ('🌍', 'השפעה',     'impact',     Color(0xFFFF6B35)),
    ('🤝', 'הכלה',     'inclusion',  Color(0xFFFFD700)),
    ('👥', 'עבודת צוות','teamwork',   Color(0xFFAB47BC)),
    ('😄', 'כיף',       'fun',        Color(0xFFEC407A)),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      for (final v in _values) ...[
        _ValueSection(
          icon: v.$1,
          label: v.$2,
          value: v.$3,
          color: v.$4,
          notes: prov.stickies.where((s) => s.value == v.$3).toList(),
        ),
        SizedBox(height: 12),
      ],
    ]);
  }
}

class _ValueSection extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color color;
  final List<StickyNote> notes;

  const _ValueSection({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.notes,
  });

  @override
  Widget build(BuildContext context) {
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
          Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: color)),
          const Spacer(),
          GestureDetector(
            onTap: () => _showAddSheet(context, value, color),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withAlpha(30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('+ הוסף', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
            ),
          ),
        ]),
        if (notes.isNotEmpty) ...[
          SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [
            for (final note in notes)
              _StickyChip(note: note, color: color),
          ]),
        ] else ...[
          SizedBox(height: 8),
          Text('אין תיעוד עדיין', style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
        ],
      ]),
    );
  }

  void _showAddSheet(BuildContext context, String val, Color col) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _AddStickySheet(value: val, color: col, label: label),
    );
  }
}

class _StickyChip extends StatelessWidget {
  final StickyNote note;
  final Color color;
  const _StickyChip({required this.note, required this.color});

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.read<AppProvider>().isAdmin;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Flexible(child: Text(note.text, style: TextStyle(fontSize: 13, color: AppColors.textPrimary))),
        if (isAdmin) ...[
          SizedBox(width: 6),
          GestureDetector(
            onTap: () => context.read<AppProvider>().deleteSticky(note.id),
            child: Text('✕', style: TextStyle(fontSize: 12, color: AppColors.red)),
          ),
        ],
      ]),
    );
  }
}

class _AddStickySheet extends StatefulWidget {
  final String value;
  final Color color;
  final String label;
  const _AddStickySheet({required this.value, required this.color, required this.label});

  @override
  State<_AddStickySheet> createState() => _AddStickySheetState();
}

class _AddStickySheetState extends State<_AddStickySheet> {
  final _ctrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (_ctrl.text.trim().isEmpty) return;
    setState(() => _saving = true);
    await context.read<AppProvider>().addSticky(StickyNote(
      id: DateTime.now().millisecondsSinceEpoch,
      value: widget.value,
      text: _ctrl.text.trim(),
      date: DateTime.now().toIso8601String().split('T')[0],
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
        Text('${_iconForLabel()} ${widget.label}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: widget.color)),
        SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          maxLines: 3,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: 'תיאור הפעילות / הדגמה...'),
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(backgroundColor: widget.color),
            child: _saving
                ? SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                : Text('💾 שמור'),
          ),
        ),
      ]),
    );
  }

  String _iconForLabel() {
    const map = {
      'גילוי': '🔍', 'חדשנות': '💡', 'השפעה': '🌍',
      'הכלה': '🤝', 'עבודת צוות': '👥', 'כיף': '😄',
    };
    return map[widget.label] ?? '⭐';
  }
}

// ─── Board Tab ────────────────────────────────────────

class _BoardTab extends StatelessWidget {
  final AppProvider prov;
  const _BoardTab({required this.prov});

  static const _values = [
    ('🔍', 'גילוי',       'discovery',  Color(0xFF3D7FFF)),
    ('💡', 'חדשנות',     'innovation', Color(0xFF00D4A0)),
    ('🌍', 'השפעה',      'impact',     Color(0xFFFF6B35)),
    ('🤝', 'הכלה',      'inclusion',  Color(0xFFFFD700)),
    ('👥', 'עבודת צוות', 'teamwork',   Color(0xFFAB47BC)),
    ('😄', 'כיף',        'fun',        Color(0xFFEC407A)),
  ];

  @override
  Widget build(BuildContext context) {
    final isAdmin = prov.isAdmin;
    final allNotes = prov.stickies;

    if (allNotes.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('📌', style: TextStyle(fontSize: 48)),
          SizedBox(height: 12),
          Text('הלוח ריק', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
          SizedBox(height: 4),
          Text('הוסף פתקים מהטאב ערכי FLL',
              style: TextStyle(fontSize: 13, color: AppColors.textTertiary)),
        ]),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (final v in _values) ...[
          Builder(builder: (ctx) {
            final notes = allNotes.where((s) => s.value == v.$3).toList();
            if (notes.isEmpty) return SizedBox.shrink();
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(children: [
                  Text(v.$1, style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(v.$2, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w800, color: v.$4)),
                  SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: v.$4.withAlpha(30),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('${notes.length}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: v.$4)),
                  ),
                ]),
              ),
              Wrap(spacing: 10, runSpacing: 10, children: [
                for (final note in notes)
                  _StickyCard(note: note, color: v.$4, icon: v.$1, isAdmin: isAdmin),
              ]),
              SizedBox(height: 20),
            ]);
          }),
        ],
      ]),
    );
  }
}

class _StickyCard extends StatelessWidget {
  final StickyNote note;
  final Color color;
  final String icon;
  final bool isAdmin;
  const _StickyCard({
    required this.note, required this.color,
    required this.icon, required this.isAdmin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withAlpha(28),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withAlpha(20), blurRadius: 6, offset: const Offset(2, 3)),
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(icon, style: TextStyle(fontSize: 14)),
          const Spacer(),
          if (isAdmin)
            GestureDetector(
              onTap: () => context.read<AppProvider>().deleteSticky(note.id),
              child: Icon(Icons.close, size: 14, color: color.withAlpha(160)),
            ),
        ]),
        SizedBox(height: 8),
        Text(note.text,
            style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
        SizedBox(height: 8),
        Text(note.date,
            style: TextStyle(fontSize: 10, color: color.withAlpha(180), fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

