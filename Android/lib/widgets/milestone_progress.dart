import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

// Milestone progress — plan (target date) vs actual. Mirrors web's
// milestoneStatus()/milestoneProgress() in calendar.js.

int _daysBetween(String fromIso, String toIso) {
  final a = DateTime.tryParse(fromIso), b = DateTime.tryParse(toIso);
  if (a == null || b == null) return 0;
  return DateTime(b.year, b.month, b.day).difference(DateTime(a.year, a.month, a.day)).inDays;
}

String _todayIso() {
  final d = DateTime.now();
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

/// (icon, text, color, kind) — kind: ontime | late | early | overdue | today | upcoming
(String, String, Color, String) milestoneStatus(Milestone m) {
  if (m.done) {
    final actual = m.actualDate ?? m.targetDate; // actualDate is only stored when it differs
    final diff = _daysBetween(m.targetDate, actual);
    if (diff > 0) return ('⏰', 'באיחור של $diff ימים', AppColors.accent3, 'late');
    if (diff < 0) return ('⚡', 'הוקדם ב-${-diff} ימים', AppColors.accent2, 'early');
    return ('✅', 'בזמן', AppColors.accent2, 'ontime');
  }
  final left = _daysBetween(_todayIso(), m.targetDate);
  if (left < 0) return ('🔴', 'היעד עבר לפני ${-left} ימים', AppColors.red, 'overdue');
  if (left == 0) return ('📍', 'היעד היום', AppColors.gold, 'today');
  return ('⏳', 'בעוד $left ימים', AppColors.textTertiary, 'upcoming');
}

/// "X מתוך Y הושגו" + bar + on-time/late/overdue counts + the next milestone.
class MilestoneProgress extends StatelessWidget {
  final List<Milestone> milestones;
  const MilestoneProgress({super.key, required this.milestones});

  @override
  Widget build(BuildContext context) {
    if (milestones.isEmpty) return const SizedBox.shrink();
    final kinds = milestones.map((m) => milestoneStatus(m).$4).toList();
    final done = milestones.where((m) => m.done).length;
    final onTime = kinds.where((k) => k == 'ontime' || k == 'early').length;
    final late = kinds.where((k) => k == 'late').length;
    final overdue = kinds.where((k) => k == 'overdue').length;
    final pending = milestones.where((m) => !m.done).toList()..sort((a, b) => a.targetDate.compareTo(b.targetDate));
    final next = pending.isEmpty ? null : pending.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Wrap(spacing: 10, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
          Text('🚩 $done מתוך ${milestones.length} אבני דרך הושגו',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          if (onTime > 0) Text('✅ $onTime בזמן', style: TextStyle(fontSize: 12, color: AppColors.accent2)),
          if (late > 0) Text('⏰ $late באיחור', style: TextStyle(fontSize: 12, color: AppColors.accent3)),
          if (overdue > 0) Text('🔴 $overdue עבר היעד', style: TextStyle(fontSize: 12, color: AppColors.red)),
        ]),
        SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: done / milestones.length,
            minHeight: 6,
            backgroundColor: AppColors.surface2,
            color: AppColors.accent2,
          ),
        ),
        SizedBox(height: 6),
        Text(next == null ? 'כל אבני הדרך הושגו 🎉' : 'הבאה: ${next.title} · ${milestoneStatus(next).$2}',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ]),
    );
  }
}
