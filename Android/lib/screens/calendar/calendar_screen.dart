import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/month_calendar.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  static void showAddMilestoneDialog(BuildContext context, {DateTime? initialDate}) {
    showDialog(context: context, builder: (_) => _AddMilestoneDialog(initialDate: initialDate));
  }

  Future<void> _editMilestoneActualDate(BuildContext context, AppProvider prov, Milestone milestone) async {
    final target = DateTime.tryParse(milestone.targetDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: target,
      firstDate: target.subtract(const Duration(days: 90)),
      lastDate: target.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.dark(primary: AppColors.accent)),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;
    final actual = picked.toIso8601String().split('T')[0];
    milestone.actualDate = actual == milestone.targetDate ? null : actual;
    await prov.updateMilestone(milestone);
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day}.${d.month}.${d.year}';
  }

  static void showDaySheet(BuildContext context, DateTime day, List<Milestone> milestones, List<StickyNote> stickies) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${day.day}.${day.month}.${day.year}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
            if (milestones.isEmpty && stickies.isEmpty) ...[
              SizedBox(height: 12),
              Text('אין פריטים ביום הזה', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ] else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(height: 12),
                    ...milestones.map((m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('🚩 ${m.title}', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        )),
                    ...stickies.map((s) {
                      final style = coreValueStyles[s.value] ?? ('📌', s.value, AppColors.textTertiary);
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${style.$1} ${style.$2}',
                              style: TextStyle(color: style.$3, fontSize: 13, fontWeight: FontWeight.w700)),
                          SizedBox(height: 2),
                          Text(s.text, style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.4)),
                        ]),
                      );
                    }),
                  ]),
                ),
              ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.pop(sheetContext);
                  showAddMilestoneDialog(context, initialDate: day);
                },
                icon: Text('🚩'),
                label: Text('הוסף אבן דרך'),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final milestones = [...prov.milestones]..sort((a, b) => a.targetDate.compareTo(b.targetDate));

    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Month grid ───────────────────────────────────
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: MonthCalendar(
          milestones: prov.milestones,
          stickies: prov.stickies,
          onDayTap: (day, dayMilestones, dayStickies) => showDaySheet(context, day, dayMilestones, dayStickies),
        ),
      ),
      SizedBox(height: 20),

      // ── Milestones ───────────────────────────────────
      Row(children: [
        const _SectionTitle('🚩', 'אבני דרך'),
        const Spacer(),
        TextButton.icon(
          onPressed: () => showAddMilestoneDialog(context),
          icon: Icon(Icons.add, size: 16, color: AppColors.accent),
          label: Text('אבן דרך', style: TextStyle(color: AppColors.accent, fontSize: 13)),
        ),
      ]),
      SizedBox(height: 8),
      if (milestones.isEmpty)
        _Empty('אין אבני דרך עדיין')
      else
        ...milestones.map((m) => _MilestoneTile(
              milestone: m,
              onToggle: () => prov.toggleMilestone(m.id),
              onDelete: () => prov.deleteMilestone(m.id),
              onTapActual: () => _editMilestoneActualDate(context, prov, m),
              formatDate: _formatDate,
            )),
    ]);
  }
}

class _SectionTitle extends StatelessWidget {
  final String icon;
  final String label;
  const _SectionTitle(this.icon, this.label);

  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: TextStyle(fontSize: 18)),
    SizedBox(width: 8),
    Text(label, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
  ]);
}

class _Empty extends StatelessWidget {
  final String text;
  const _Empty(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Text(text, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
  );
}

class _DateChip extends StatelessWidget {
  final String icon;
  final String label;
  final Color color;
  const _DateChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(color: color.withAlpha(30), borderRadius: BorderRadius.circular(20)),
    child: Text('$icon $label', style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600)),
  );
}

class _MilestoneTile extends StatelessWidget {
  final Milestone milestone;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onTapActual;
  final String Function(String) formatDate;
  const _MilestoneTile({
    required this.milestone, required this.onToggle, required this.onDelete,
    required this.onTapActual, required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final changed = milestone.actualDate != null && milestone.actualDate != milestone.targetDate;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: onToggle,
            child: Icon(
              milestone.done ? Icons.check_circle : Icons.radio_button_unchecked,
              color: milestone.done ? AppColors.accent2 : AppColors.textTertiary,
              size: 22,
            ),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text(milestone.title,
                style: TextStyle(
                  fontSize: 14, color: AppColors.textPrimary,
                  decoration: milestone.done ? TextDecoration.lineThrough : null,
                )),
          ),
          GestureDetector(onTap: onDelete, child: Icon(Icons.close, size: 16, color: AppColors.textTertiary)),
        ]),
        SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.only(right: 32),
          child: Wrap(spacing: 8, runSpacing: 6, children: [
            _DateChip(icon: '🚩', label: 'יעד: ${formatDate(milestone.targetDate)}', color: AppColors.gold),
            GestureDetector(
              onTap: onTapActual,
              child: _DateChip(
                icon: changed ? '✅' : '➕',
                label: changed ? 'בוצע בפועל: ${formatDate(milestone.actualDate!)}' : 'סמן תאריך בפועל',
                color: changed ? AppColors.accent2 : AppColors.textTertiary,
              ),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Add Milestone Dialog ─────────────────────────────
class _AddMilestoneDialog extends StatefulWidget {
  final DateTime? initialDate;
  const _AddMilestoneDialog({this.initialDate});

  @override
  State<_AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<_AddMilestoneDialog> {
  final _titleCtrl = TextEditingController();
  late DateTime _date = widget.initialDate ?? DateTime.now().add(const Duration(days: 7));
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.dark(primary: AppColors.accent)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('🚩 אבן דרך חדשה', style: TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'למשל: סיום בניית הרובוט'),
          ),
          const SizedBox(height: 10),
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text('📅 ${_date.day}.${_date.month}.${_date.year}',
                  style: TextStyle(color: AppColors.textPrimary)),
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: AppColors.red, fontSize: 12)),
          ],
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
        ElevatedButton(
          onPressed: () async {
            final title = _titleCtrl.text.trim();
            if (title.isEmpty) {
              setState(() => _error = 'חובה להזין כותרת');
              return;
            }
            final prov = context.read<AppProvider>();
            await prov.addMilestone(Milestone(
              id: DateTime.now().millisecondsSinceEpoch,
              title: title,
              targetDate: _date.toIso8601String().split('T')[0],
            ));
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('הוסף'),
        ),
      ],
    );
  }
}
