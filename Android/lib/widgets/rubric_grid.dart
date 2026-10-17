import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/models.dart';
import '../providers/app_provider.dart';

// Laid out like FIRST Israel's rubric tool (fll-events.firstisrael.org.il/tools/rubrics),
// including its light look. On a phone the site itself switches from the 4-column
// table to one card per criterion — that's what this mirrors.
const _tabs = [
  ('innovation', 'פרויקט החדשנות', Color(0xFF5E82BF)),
  ('robot', 'תכנון הרובוט', Color(0xFF64AF75)),
  ('values', 'ערכי הליבה', Color(0xFFE4928B)),
];
const _sectionBg = {
  'innovation': Color(0xFFD3DAED),
  'robot': Color(0xFFDAE8D8),
  'values': Color(0xFFF5DAD4),
};
const _ink = Color(0xFF1A1F36);
const _blue = Color(0xFF1E6FD9);
const _line = Color(0xFFE3E3E3);

/// The official judging rubric: pick a judging area, and for every criterion
/// just mark one of the four levels. The core-values tab is the flagged
/// criteria of the other two (same marks). Mentors mark; others read only.
class RubricGrid extends StatefulWidget {
  const RubricGrid({super.key});

  @override
  State<RubricGrid> createState() => _RubricGridState();
}

class _RubricGridState extends State<RubricGrid> {
  String _tab = 'innovation';

  Future<void> _confirmReset(AppProvider prov) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('איפוס המחוון'),
        content: const Text('לאפס את כל הסימונים בתחום השיפוט הזה?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('ביטול')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('אפס')),
        ],
      ),
    );
    if (ok == true) await prov.resetRubricTab(_tab);
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final rows = rubricRows(_tab);

    final children = <Widget>[];
    String? lastSection;
    for (final r in rows) {
      final key = '${r.cat}.${r.section.id}';
      if (key != lastSection) {
        lastSection = key;
        final prefix = _tab == 'values' ? '${rubricTitles[r.cat]} · ' : '';
        children.add(Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          color: _sectionBg[_tab],
          child: Text.rich(TextSpan(children: [
            TextSpan(text: '$prefix${r.section.title}', style: const TextStyle(fontWeight: FontWeight.w800)),
            TextSpan(text: '  -  ${r.section.description}'),
          ]), style: const TextStyle(fontSize: 12, color: _ink, height: 1.4)),
        ));
      }
      final current = prov.rubricMarks[r.cat]?[r.field.id] ?? 0;
      children.add(_FieldCard(
        cat: r.cat, field: r.field, tab: _tab, current: current, canEdit: prov.isAdmin,
      ));
      if (current == 4) {
        children.add(_NoteField(
          key: ValueKey('note-${r.cat}-${r.field.id}'),
          initial: prov.rubricNotes[r.cat]?[r.field.id] ?? '',
          readOnly: !prov.isAdmin,
          onSave: (v) => prov.setRubricNote(r.cat, r.field.id, v),
        ));
      }
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: Text('מחווני שיפוט',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                  color: Theme.of(context).textTheme.bodyLarge?.color)),
        ),
        if (prov.isAdmin)
          OutlinedButton(
            onPressed: () => _confirmReset(prov),
            style: OutlinedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF00396B),
              side: const BorderSide(color: Color(0xFF00396B)),
            ),
            child: const Text('איפוס המחוון'),
          ),
      ]),
      const SizedBox(height: 10),
      Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [BoxShadow(color: Color(0x1F000000), blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
              const Text('תחומי שיפוט', style: TextStyle(fontSize: 12, color: Color(0xFF555555))),
              for (final (key, label, dot) in _tabs)
                GestureDetector(
                  onTap: () => setState(() => _tab = key),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _tab == key ? const Color(0xFFF3F8FF) : Colors.white,
                      border: Border.all(color: _tab == key ? _blue : const Color(0xFFCCCCCC), width: _tab == key ? 2 : 1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
                      const SizedBox(width: 7),
                      Text(label, style: TextStyle(
                        fontSize: 13,
                        color: _tab == key ? _blue : const Color(0xFF333333),
                        fontWeight: _tab == key ? FontWeight.w700 : FontWeight.w400,
                      )),
                    ]),
                  ),
                ),
            ]),
          ),
          if (_tab == 'values')
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Text(
                'ערכי הליבה נשפטים דרך הקריטריונים המסומנים בעיגול מקווקו במחווני פרויקט החדשנות ותכנון הרובוט, ומהווים 25% מהניקוד. סימון כאן הוא אותו סימון כמו שם.',
                style: TextStyle(fontSize: 12, color: Color(0xFF444444), height: 1.4),
              ),
            ),
          ...children,
          // Feedback
          Container(
            color: _sectionBg[_tab],
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Text('עבודה מצוינת......', textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink)),
          ),
          _NoteField(
            key: ValueKey('fb-$_tab-greatJob'),
            initial: prov.rubricFeedback[_tab]?['greatJob'] ?? '',
            hint: 'עבודה מצוינת...',
            readOnly: !prov.isAdmin,
            onSave: (v) => prov.setRubricFeedback(_tab, 'greatJob', v),
          ),
          Container(
            color: _sectionBg[_tab],
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: const Text('חשבו על......', textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: _ink)),
          ),
          _NoteField(
            key: ValueKey('fb-$_tab-thinkAbout'),
            initial: prov.rubricFeedback[_tab]?['thinkAbout'] ?? '',
            hint: 'חשבו על...',
            readOnly: !prov.isAdmin,
            onSave: (v) => prov.setRubricFeedback(_tab, 'thinkAbout', v),
          ),
        ]),
      ),
    ]);
  }
}

class _FieldCard extends StatelessWidget {
  final String cat;
  final RubricFieldDef field;
  final String tab;
  final int current;
  final bool canEdit;
  const _FieldCard({required this.cat, required this.field, required this.tab,
      required this.current, required this.canEdit});

  @override
  Widget build(BuildContext context) {
    final colors = rubricColors[tab]!;
    return Container(
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: _line))),
      child: Column(children: [
        for (int level = 1; level <= 4; level++)
          InkWell(
            onTap: canEdit
                ? () => context.read<AppProvider>().setRubricMark(cat, field.id, level)
                : () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('רק מנטור יכול לסמן במחוון'))),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: current == level ? const Color(0xFFF3F8FF) : null,
                border: level > 1 ? const Border(top: BorderSide(color: Color(0xFFF0F0F0))) : null,
              ),
              child: Row(children: [
                _Radio(selected: current == level, dashed: field.coreValues),
                const SizedBox(width: 10),
                Container(
                  width: 62,
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  decoration: BoxDecoration(color: colors[level - 1], borderRadius: BorderRadius.circular(4)),
                  child: Text(rubricLevels[level - 1], textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: _ink)),
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(level <= 3 ? field.levels[level - 1] : '',
                    style: const TextStyle(fontSize: 13, height: 1.4, color: _ink))),
              ]),
            ),
          ),
      ]),
    );
  }
}

/// Radio like the site's: dotted outline for criteria that also count toward core values.
class _Radio extends StatelessWidget {
  final bool selected;
  final bool dashed;
  const _Radio({required this.selected, required this.dashed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: 22, height: 22,
    child: CustomPaint(
      painter: _RadioPainter(selected: selected, dashed: dashed),
    ),
  );
}

class _RadioPainter extends CustomPainter {
  final bool selected;
  final bool dashed;
  _RadioPainter({required this.selected, required this.dashed});

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    final r = size.width / 2 - 1.5;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = dashed ? 2.6 : 2
      ..color = selected ? _blue : const Color(0xFF666666);
    if (dashed) {
      const n = 12;
      for (var i = 0; i < n; i++) {
        final start = i * 2 * 3.14159265 / n;
        canvas.drawArc(Rect.fromCircle(center: c, radius: r), start, 3.14159265 / n, false, paint);
      }
    } else {
      canvas.drawCircle(c, r, paint);
    }
    if (selected) canvas.drawCircle(c, 5, Paint()..color = _blue);
  }

  @override
  bool shouldRepaint(_RadioPainter old) => old.selected != selected || old.dashed != dashed;
}

/// Multi-line text field that saves once when it loses focus.
class _NoteField extends StatefulWidget {
  final String initial;
  final String? hint;
  final bool readOnly;
  final ValueChanged<String> onSave;
  const _NoteField({super.key, required this.initial, required this.readOnly,
      required this.onSave, this.hint});

  @override
  State<_NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<_NoteField> {
  late final TextEditingController _ctrl = TextEditingController(text: widget.initial);
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) widget.onSave(_ctrl.text);
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
    final isNote = widget.hint == null;
    return Container(
      color: isNote ? const Color(0xFFFAFBFD) : Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (isNote)
          const Padding(
            padding: EdgeInsets.only(bottom: 4),
            child: Text('הערות', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _ink)),
          ),
        TextField(
          controller: _ctrl,
          focusNode: _focus,
          readOnly: widget.readOnly,
          minLines: isNote ? 2 : 4,
          maxLines: null,
          style: const TextStyle(fontSize: 13, color: _ink),
          decoration: InputDecoration(
            hintText: widget.hint ?? 'כיצד הקבוצה הצטיינה?',
            hintStyle: const TextStyle(color: Color(0xFF999999)),
            filled: true,
            fillColor: Colors.white,
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(6),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
          ),
        ),
      ]),
    );
  }
}
