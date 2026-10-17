import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/month_calendar.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  static String isoOf(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Add (or, if [plan] is given / a meeting exists on [date], edit) a meeting plan.
  static void showMeetingPlanDialog(BuildContext context, {DateTime? date, MeetingPlan? plan}) {
    final existing = plan ?? (date != null ? context.read<AppProvider>().meetingForDay(isoOf(date)) : null);
    showDialog(context: context, builder: (_) => _MeetingPlanDialog(initialDate: date, existing: existing));
  }

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
    final meeting = context.read<AppProvider>().meetingForDay(isoOf(day));
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
            if (milestones.isEmpty && stickies.isEmpty && meeting == null) ...[
              SizedBox(height: 12),
              Text('אין פריטים ביום הזה', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ] else
              Flexible(
                child: SingleChildScrollView(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(height: 12),
                    if (meeting != null) _MeetingCard(meeting: meeting),
                    ...milestones.map((m) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('🚩 ${m.title}', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                        )),
                    if (stickies.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text('📌 ${meeting != null ? 'פתקים מהמפגש' : 'פתקים'} (${stickies.length})',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textTertiary)),
                      ),
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
            Row(children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    showMeetingPlanDialog(context, date: day);
                  },
                  icon: Text(meeting != null ? '✏️' : '📋'),
                  label: Text(meeting != null ? 'ערוך מפגש' : 'תכנית מפגש'),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    showAddMilestoneDialog(context, initialDate: day);
                  },
                  icon: Text('🚩'),
                  label: Text('אבן דרך'),
                ),
              ),
            ]),
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
          meetingPlans: prov.meetingPlans,
          onDayTap: (day, dayMilestones, dayStickies) => showDaySheet(context, day, dayMilestones, dayStickies),
        ),
      ),
      SizedBox(height: 20),

      // ── Meeting plans ────────────────────────────────
      Row(children: [
        const _SectionTitle('📋', 'מפגשים'),
        const Spacer(),
        TextButton.icon(
          onPressed: () => showMeetingPlanDialog(context),
          icon: Icon(Icons.add, size: 16, color: AppColors.accent),
          label: Text('מפגש', style: TextStyle(color: AppColors.accent, fontSize: 13)),
        ),
      ]),
      SizedBox(height: 8),
      if (prov.meetingPlans.isEmpty)
        _Empty('אין מפגשים עדיין. לחצו על יום בלוח כדי להוסיף תכנית מפגש.')
      else
        ...([...prov.meetingPlans]..sort((a, b) => b.date.compareTo(a.date))).map((m) => GestureDetector(
              onTap: () => showMeetingPlanDialog(context, plan: m),
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Wrap(spacing: 8, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                    Text('📋 ${m.displayTitle}',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                    _DateChip(icon: '📅', label: _formatDate(m.date), color: AppColors.accent),
                    if (m.summary.isNotEmpty)
                      Text('✅ סוכם', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.accent2)),
                    if (prov.stickies.any((s) => s.date == m.date))
                      Text('📌 ${prov.stickies.where((s) => s.date == m.date).length} פתקים',
                          style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
                  ]),
                  if (m.plan.isNotEmpty) ...[
                    SizedBox(height: 4),
                    Text(m.plan, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ]),
              ),
            )),
      SizedBox(height: 24),

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

/// The meeting's plan + summary, shown at the top of the day sheet.
class _MeetingCard extends StatelessWidget {
  final MeetingPlan meeting;
  const _MeetingCard({required this.meeting});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.surface2,
      borderRadius: BorderRadius.circular(10),
      border: Border(right: BorderSide(color: AppColors.accent, width: 3)),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('📋 ${meeting.displayTitle}',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
      if (meeting.plan.isNotEmpty) ...[
        SizedBox(height: 6),
        Text('מה מתכננים', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent)),
        Text(meeting.plan, style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
      ],
      if (meeting.summary.isNotEmpty) ...[
        SizedBox(height: 6),
        Text('מה קרה בפועל', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent2)),
        Text(meeting.summary, style: TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4)),
      ],
    ]),
  );
}

// ─── Meeting Plan Dialog ──────────────────────────────
class _MeetingPlanDialog extends StatefulWidget {
  final DateTime? initialDate;
  final MeetingPlan? existing;
  const _MeetingPlanDialog({this.initialDate, this.existing});

  @override
  State<_MeetingPlanDialog> createState() => _MeetingPlanDialogState();
}

class _MeetingPlanDialogState extends State<_MeetingPlanDialog> {
  late final _titleCtrl = TextEditingController(text: widget.existing?.title ?? '');
  late final _planCtrl = TextEditingController(text: widget.existing?.plan ?? '');
  late final _summaryCtrl = TextEditingController(text: widget.existing?.summary ?? '');
  late DateTime _date = DateTime.tryParse(widget.existing?.date ?? '') ?? widget.initialDate ?? DateTime.now();
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _planCtrl.dispose();
    _summaryCtrl.dispose();
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
      title: Text(widget.existing != null ? '📋 תכנית מפגש' : '📋 מפגש חדש',
          style: TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
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
          const SizedBox(height: 10),
          TextField(
            controller: _titleCtrl,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'כותרת (למשל: בניית זרוע למשימה M03)'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _planCtrl,
            maxLines: 4,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(labelText: 'מה מתכננים לעשות', hintText: 'סדר יום, מטרות, מי עושה מה...'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _summaryCtrl,
            maxLines: 3,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(labelText: 'מה קרה בפועל (אחרי המפגש)'),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: TextStyle(color: AppColors.red, fontSize: 12)),
          ],
        ]),
      ),
      actions: [
        if (widget.existing != null)
          TextButton(
            onPressed: () async {
              await context.read<AppProvider>().deleteMeetingPlan(widget.existing!.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('🗑️ מחק', style: TextStyle(color: AppColors.red)),
          ),
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('ביטול')),
        ElevatedButton(
          onPressed: () async {
            final title = _titleCtrl.text.trim();
            final plan = _planCtrl.text.trim();
            if (title.isEmpty && plan.isEmpty) {
              setState(() => _error = 'נדרשת כותרת או תכנית');
              return;
            }
            final ok = await context.read<AppProvider>().saveMeetingPlan(MeetingPlan(
              id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch,
              date: CalendarScreen.isoOf(_date),
              title: title,
              plan: plan,
              summary: _summaryCtrl.text.trim(),
            ));
            if (!ok) {
              setState(() => _error = 'כבר יש מפגש בתאריך הזה');
              return;
            }
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('שמור'),
        ),
      ],
    );
  }
}
