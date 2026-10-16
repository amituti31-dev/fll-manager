import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/models.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/month_calendar.dart';

class CalendarScreen extends StatelessWidget {
  const CalendarScreen({super.key});

  static void showAddMeetingDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _AddMeetingDialog());
  }

  static void showAddMilestoneDialog(BuildContext context) {
    showDialog(context: context, builder: (_) => const _AddMilestoneDialog());
  }

  Future<void> _editActualDate(BuildContext context, AppProvider prov, Meeting meeting) async {
    final planned = DateTime.tryParse(meeting.plannedDate) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: planned,
      firstDate: planned.subtract(const Duration(days: 90)),
      lastDate: planned.add(const Duration(days: 90)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: ColorScheme.dark(primary: AppColors.accent)),
        child: child!,
      ),
    );
    if (picked == null || !context.mounted) return;
    final actual = picked.toIso8601String().split('T')[0];
    meeting.actualDate = actual == meeting.plannedDate ? null : actual;
    await prov.updateMeeting(meeting);
  }

  Future<void> _confirmDeleteMeeting(BuildContext context, AppProvider prov, Meeting meeting) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('מחק מפגש', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('למחוק את "${meeting.title}"?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('ביטול')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: Text('מחק', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (ok == true && context.mounted) await prov.deleteMeeting(meeting.id);
  }

  String _formatDate(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day}.${d.month}.${d.year}';
  }

  void _showDaySheet(BuildContext context, DateTime day, List<Meeting> meetings, List<Milestone> milestones) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${day.day}.${day.month}.${day.year}',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
            SizedBox(height: 12),
            ...meetings.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('🗓️ ${m.title}', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                )),
            ...milestones.map((m) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('🚩 ${m.title}', style: TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                )),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final meetings = [...prov.meetings]..sort((a, b) => a.plannedDate.compareTo(b.plannedDate));
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
          meetings: prov.meetings,
          milestones: prov.milestones,
          onDayTap: (day, dayMeetings, dayMilestones) => _showDaySheet(context, day, dayMeetings, dayMilestones),
        ),
      ),
      SizedBox(height: 20),

      // ── Meetings ─────────────────────────────────────
      Row(children: [
        const _SectionTitle('🗓️', 'מפגשים'),
        const Spacer(),
        TextButton.icon(
          onPressed: () => showAddMeetingDialog(context),
          icon: Icon(Icons.add, size: 16, color: AppColors.accent),
          label: Text('מפגש חדש', style: TextStyle(color: AppColors.accent, fontSize: 13)),
        ),
      ]),
      SizedBox(height: 8),
      if (meetings.isEmpty)
        _Empty('אין מפגשים מתוכננים עדיין')
      else
        ...meetings.map((m) => _MeetingCard(
              meeting: m,
              onTapActual: () => _editActualDate(context, prov, m),
              onDelete: () => _confirmDeleteMeeting(context, prov, m),
              formatDate: _formatDate,
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

class _MeetingCard extends StatelessWidget {
  final Meeting meeting;
  final VoidCallback onTapActual;
  final VoidCallback onDelete;
  final String Function(String) formatDate;
  const _MeetingCard({
    required this.meeting, required this.onTapActual,
    required this.onDelete, required this.formatDate,
  });

  @override
  Widget build(BuildContext context) {
    final changed = meeting.actualDate != null && meeting.actualDate != meeting.plannedDate;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text(meeting.title,
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close, size: 18, color: AppColors.textTertiary),
          ),
        ]),
        SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 6, children: [
          _DateChip(
            icon: '📅', label: 'מתוכנן: ${formatDate(meeting.plannedDate)}',
            color: AppColors.accent,
          ),
          GestureDetector(
            onTap: onTapActual,
            child: _DateChip(
              icon: changed ? '✅' : '➕',
              label: changed ? 'בפועל: ${formatDate(meeting.actualDate!)}' : 'סמן תאריך בפועל',
              color: changed ? AppColors.accent2 : AppColors.textTertiary,
            ),
          ),
        ]),
        if (meeting.notes.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(meeting.notes, style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4)),
        ],
      ]),
    );
  }
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
  final String Function(String) formatDate;
  const _MilestoneTile({
    required this.milestone, required this.onToggle,
    required this.onDelete, required this.formatDate,
  });

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 8),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Row(children: [
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
      Text(formatDate(milestone.targetDate),
          style: TextStyle(fontSize: 12, color: AppColors.textTertiary)),
      SizedBox(width: 8),
      GestureDetector(onTap: onDelete, child: Icon(Icons.close, size: 16, color: AppColors.textTertiary)),
    ]),
  );
}

// ─── Add Meeting Dialog ───────────────────────────────
class _AddMeetingDialog extends StatefulWidget {
  const _AddMeetingDialog();

  @override
  State<_AddMeetingDialog> createState() => _AddMeetingDialogState();
}

class _AddMeetingDialogState extends State<_AddMeetingDialog> {
  final _titleCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _notesCtrl.dispose();
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
      title: Text('🗓️ מפגש חדש', style: TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'נושא המפגש (למשל: בניית רובוט)'),
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
          const SizedBox(height: 10),
          TextField(
            controller: _notesCtrl,
            maxLines: 2,
            style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'הערות (אופציונלי)'),
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
              setState(() => _error = 'חובה להזין נושא');
              return;
            }
            final prov = context.read<AppProvider>();
            await prov.addMeeting(Meeting(
              id: DateTime.now().millisecondsSinceEpoch,
              title: title,
              plannedDate: _date.toIso8601String().split('T')[0],
              notes: _notesCtrl.text.trim(),
            ));
            if (context.mounted) Navigator.pop(context);
          },
          child: const Text('הוסף'),
        ),
      ],
    );
  }
}

// ─── Add Milestone Dialog ─────────────────────────────
class _AddMilestoneDialog extends StatefulWidget {
  const _AddMilestoneDialog();

  @override
  State<_AddMilestoneDialog> createState() => _AddMilestoneDialogState();
}

class _AddMilestoneDialogState extends State<_AddMilestoneDialog> {
  final _titleCtrl = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(days: 7));
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
