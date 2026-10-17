import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';

const _tabs = [
  ('innovation', '💡 פרויקט החדשנות'),
  ('robot', '🤖 תכנון הרובוט'),
  ('values', '⭐ ערכי הליבה'),
];

/// The official judging rubric as on FIRST Israel's site: pick a tab, and for
/// every criterion just mark one of the four levels. The core-values tab is
/// the flagged criteria of the other two (same marks). Mentors mark; everyone
/// else sees it read-only.
class RubricGrid extends StatefulWidget {
  const RubricGrid({super.key});

  @override
  State<RubricGrid> createState() => _RubricGridState();
}

class _RubricGridState extends State<RubricGrid> {
  String _tab = 'innovation';

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final colors = rubricColors[_tab]!;
    final rows = rubricRows(_tab);
    final marked = rows.where((r) => (prov.rubricMarks[r.cat]?[r.field.id] ?? 0) > 0).length;

    final children = <Widget>[];
    String? lastSection;
    for (final r in rows) {
      final key = '${r.cat}.${r.section.id}';
      if (key != lastSection) {
        lastSection = key;
        final prefix = _tab == 'values' ? '${rubricTitles[r.cat]} · ' : '';
        children.add(Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 12, bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: colors[0], borderRadius: BorderRadius.circular(8)),
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$prefix${r.section.title}', style: const TextStyle(fontWeight: FontWeight.w800)),
            TextSpan(text: ' - ${r.section.description}'),
          ]), style: const TextStyle(fontSize: 12, color: Color(0xFF1A1F36), height: 1.4)),
        ));
      }
      children.add(_FieldCard(
        cat: r.cat, field: r.field, colors: colors,
        current: prov.rubricMarks[r.cat]?[r.field.id] ?? 0,
        canEdit: prov.isAdmin,
      ));
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📋 מחווני שיפוט',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textPrimary)),
        SizedBox(height: 10),
        Wrap(spacing: 6, runSpacing: 6, children: [
          for (final (key, label) in _tabs)
            ChoiceChip(
              label: Text(label, style: TextStyle(fontSize: 12)),
              selected: _tab == key,
              onSelected: (_) => setState(() => _tab = key),
            ),
        ]),
        SizedBox(height: 8),
        Text('סומנו $marked מתוך ${rows.length} קריטריונים${prov.isAdmin ? '' : ' · רק מנטור יכול לסמן'}',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
        if (_tab == 'values') ...[
          SizedBox(height: 6),
          Text('ערכי הליבה נשפטים דרך הקריטריונים המסומנים בעיגול מקווקו בשני המחוונים האחרים (25% מהניקוד). סימון כאן הוא אותו סימון כמו שם.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary, height: 1.4)),
        ],
        ...children,
        SizedBox(height: 12),
        _FeedbackField(key: ValueKey('$_tab-greatJob'), tab: _tab, field: 'greatJob', label: 'עבודה מצוינת...'),
        SizedBox(height: 8),
        _FeedbackField(key: ValueKey('$_tab-thinkAbout'), tab: _tab, field: 'thinkAbout', label: 'חשבו על...'),
      ]),
    );
  }
}

class _FieldCard extends StatelessWidget {
  final String cat;
  final RubricFieldDef field;
  final List<Color> colors;
  final int current;
  final bool canEdit;
  const _FieldCard({required this.cat, required this.field, required this.colors,
      required this.current, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(children: [
        for (int level = 1; level <= 4; level++)
          InkWell(
            onTap: canEdit
                ? () => context.read<AppProvider>().setRubricMark(cat, field.id, level)
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('רק מנטור יכול לסמן במחוון'))),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: current == level ? colors[level - 1] : null,
                border: level < 4 ? Border(bottom: BorderSide(color: AppColors.border.withAlpha(80))) : null,
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(
                  current == level ? Icons.radio_button_checked
                      : (field.coreValues ? Icons.motion_photos_on_outlined : Icons.radio_button_unchecked),
                  size: 18,
                  color: current == level ? const Color(0xFF1A1F36) : AppColors.textTertiary,
                ),
                SizedBox(width: 8),
                SizedBox(
                  width: 58,
                  child: Text(rubricLevels[level - 1], style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: current == level ? const Color(0xFF1A1F36) : AppColors.textSecondary,
                  )),
                ),
                Expanded(child: Text(level <= 3 ? field.levels[level - 1] : '', style: TextStyle(
                  fontSize: 12, height: 1.35,
                  color: current == level ? const Color(0xFF1A1F36) : AppColors.textPrimary,
                ))),
              ]),
            ),
          ),
      ]),
    );
  }
}

class _FeedbackField extends StatefulWidget {
  final String tab;
  final String field;
  final String label;
  const _FeedbackField({super.key, required this.tab, required this.field, required this.label});

  @override
  State<_FeedbackField> createState() => _FeedbackFieldState();
}

class _FeedbackFieldState extends State<_FeedbackField> {
  late final TextEditingController _ctrl;
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    final prov = context.read<AppProvider>();
    _ctrl = TextEditingController(text: prov.rubricFeedback[widget.tab]?[widget.field] ?? '');
    // Save once when the field loses focus, not on every keystroke.
    _focus.addListener(() {
      if (!_focus.hasFocus) prov.setRubricFeedback(widget.tab, widget.field, _ctrl.text);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = context.select<AppProvider, bool>((p) => p.isAdmin);
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      readOnly: !canEdit,
      maxLines: 2,
      style: TextStyle(color: AppColors.textPrimary, fontSize: 13),
      decoration: InputDecoration(labelText: widget.label),
    );
  }
}
