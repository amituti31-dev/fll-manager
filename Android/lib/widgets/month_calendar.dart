import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

const _hebrewMonths = [
  'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
  'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
];
const _hebrewWeekdays = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש']; // Sunday-first

/// A month-grid calendar: meetings (planned/actual) and milestones show as
/// small colored dots on their day. Tapping a day with items calls [onDayTap].
class MonthCalendar extends StatefulWidget {
  final List<Meeting> meetings;
  final List<Milestone> milestones;
  final void Function(DateTime day, List<Meeting> meetings, List<Milestone> milestones)? onDayTap;

  const MonthCalendar({super.key, required this.meetings, required this.milestones, this.onDayTap});

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  late DateTime _month; // always day=1

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _month = DateTime(now.year, now.month, 1);
  }

  void _shiftMonth(int delta) {
    setState(() => _month = DateTime(_month.year, _month.month + delta, 1));
  }

  String _iso(DateTime d) => d.toIso8601String().split('T')[0];

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = DateTime(_month.year, _month.month, 1).weekday % 7; // 0=Sun
    final totalCells = leading + daysInMonth;
    final trailing = (7 - totalCells % 7) % 7;
    final cellCount = leading + daysInMonth + trailing;
    final today = DateTime.now();
    final isCurrentMonth = today.year == _month.year && today.month == _month.month;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header: prev / month-year / next
      Row(children: [
        IconButton(
          onPressed: () => _shiftMonth(-1),
          icon: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text('${_hebrewMonths[_month.month - 1]} ${_month.year}',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
        ),
        IconButton(
          onPressed: () => _shiftMonth(1),
          icon: Icon(Icons.chevron_left, color: AppColors.textSecondary),
        ),
      ]),
      // Weekday header
      Row(children: _hebrewWeekdays
          .map((w) => Expanded(
                child: Center(
                  child: Text(w, style: TextStyle(fontSize: 11, color: AppColors.textTertiary, fontWeight: FontWeight.w700)),
                ),
              ))
          .toList()),
      SizedBox(height: 4),
      // Day grid
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cellCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7),
        itemBuilder: (_, i) {
          final dayNum = i - leading + 1;
          if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox.shrink();
          final date = DateTime(_month.year, _month.month, dayNum);
          final iso = _iso(date);
          final isToday = isCurrentMonth && today.day == dayNum;

          final plannedHere = widget.meetings.where((m) => m.plannedDate == iso).toList();
          final actualHere = widget.meetings.where((m) => m.actualDate == iso).toList();
          final milestonesHere = widget.milestones.where((m) => m.targetDate == iso).toList();
          final hasItems = plannedHere.isNotEmpty || actualHere.isNotEmpty || milestonesHere.isNotEmpty;

          return GestureDetector(
            onTap: hasItems && widget.onDayTap != null
                ? () => widget.onDayTap!(date, [...plannedHere, ...actualHere], milestonesHere)
                : null,
            child: Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: isToday ? AppColors.accent.withAlpha(30) : null,
                borderRadius: BorderRadius.circular(8),
                border: isToday ? Border.all(color: AppColors.accent, width: 1.2) : null,
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('$dayNum', style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                    color: isToday ? AppColors.accent : AppColors.textPrimary)),
                if (hasItems) ...[
                  SizedBox(height: 2),
                  Wrap(spacing: 2, alignment: WrapAlignment.center, children: [
                    if (plannedHere.isNotEmpty) _Dot(AppColors.accent),
                    if (actualHere.isNotEmpty) _Dot(AppColors.accent2),
                    if (milestonesHere.isNotEmpty) _Dot(AppColors.gold),
                  ]),
                ],
              ]),
            ),
          );
        },
      ),
      SizedBox(height: 10),
      Wrap(spacing: 14, children: [
        _Legend(AppColors.accent, 'מתוכנן'),
        _Legend(AppColors.accent2, 'בפועל'),
        _Legend(AppColors.gold, 'אבן דרך'),
      ]),
    ]);
  }
}

class _Dot extends StatelessWidget {
  final Color color;
  const _Dot(this.color);

  @override
  Widget build(BuildContext context) =>
      Container(width: 5, height: 5, decoration: BoxDecoration(color: color, shape: BoxShape.circle));
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);

  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
    Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
    SizedBox(width: 5),
    Text(label, style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
  ]);
}
