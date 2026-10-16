import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

const _hebrewMonths = [
  'ינואר', 'פברואר', 'מרץ', 'אפריל', 'מאי', 'יוני',
  'יולי', 'אוגוסט', 'ספטמבר', 'אוקטובר', 'נובמבר', 'דצמבר',
];
const _hebrewWeekdays = ['א', 'ב', 'ג', 'ד', 'ה', 'ו', 'ש']; // Sunday-first

class _DayChip {
  final String icon;
  final String text;
  final Color color;
  const _DayChip(this.icon, this.text, this.color);
}

/// A Google-Calendar-style month grid: a full rectangle of day cells
/// (greyed-out leading/trailing days from adjacent months fill it out),
/// each showing small colored event chips (not just dots) for meetings
/// (planned/actual) and milestones due that day, with a "+N" overflow and
/// a circular highlight on today. Tapping a day with items calls [onDayTap].
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

  String _iso(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<_DayChip> _chipsFor(String iso) {
    final chips = <_DayChip>[];
    for (final m in widget.meetings) {
      if (m.plannedDate == iso) chips.add(_DayChip('🗓️', m.title, AppColors.accent));
      if (m.actualDate == iso) chips.add(_DayChip('✅', m.title, AppColors.accent2));
    }
    for (final m in widget.milestones) {
      if (m.targetDate == iso) chips.add(_DayChip('🚩', m.title, AppColors.gold));
      if (m.actualDate == iso) chips.add(_DayChip('✅', m.title, AppColors.accent2));
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateTime(_month.year, _month.month + 1, 0).day;
    final leading = DateTime(_month.year, _month.month, 1).weekday % 7; // 0=Sun
    final daysInPrevMonth = DateTime(_month.year, _month.month, 0).day;
    final totalCells = leading + daysInMonth;
    final trailing = (7 - totalCells % 7) % 7;
    final cellCount = leading + daysInMonth + trailing;
    final today = DateTime.now();

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
      // Day grid — a full rectangle, prev/next month days greyed out
      GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: cellCount,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 0.72),
        itemBuilder: (_, i) {
          late DateTime date;
          late bool inMonth;
          if (i < leading) {
            date = DateTime(_month.year, _month.month - 1, daysInPrevMonth - (leading - i - 1));
            inMonth = false;
          } else if (i < leading + daysInMonth) {
            date = DateTime(_month.year, _month.month, i - leading + 1);
            inMonth = true;
          } else {
            date = DateTime(_month.year, _month.month + 1, i - leading - daysInMonth + 1);
            inMonth = false;
          }
          final iso = _iso(date);
          final isToday = date.year == today.year && date.month == today.month && date.day == today.day;
          final chips = inMonth ? _chipsFor(iso) : const <_DayChip>[];
          final visible = chips.take(2).toList();
          final overflow = chips.length - visible.length;

          return GestureDetector(
            onTap: widget.onDayTap != null
                ? () => widget.onDayTap!(
                    date,
                    widget.meetings.where((m) => m.plannedDate == iso || m.actualDate == iso).toList(),
                    widget.milestones.where((m) => m.targetDate == iso || m.actualDate == iso).toList(),
                  )
                : null,
            child: Container(
              margin: const EdgeInsets.all(1.5),
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Container(
                    width: 20, height: 20,
                    alignment: Alignment.center,
                    decoration: isToday
                        ? BoxDecoration(color: AppColors.accent, shape: BoxShape.circle)
                        : null,
                    child: Text('${date.day}', style: TextStyle(
                        fontSize: 11,
                        fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
                        color: isToday
                            ? Colors.white
                            : (inMonth ? AppColors.textPrimary : AppColors.textTertiary.withAlpha(120)))),
                  ),
                ),
                SizedBox(height: 2),
                ...visible.map((c) => Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 1.5),
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(color: c.color.withAlpha(50), borderRadius: BorderRadius.circular(3)),
                      child: Text('${c.icon} ${c.text}',
                          maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 8.5, color: c.color, fontWeight: FontWeight.w700)),
                    )),
                if (overflow > 0)
                  Text('+$overflow עוד', style: TextStyle(fontSize: 8, color: AppColors.textTertiary)),
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
