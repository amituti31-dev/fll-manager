import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(int) navigateTo;
  const DashboardScreen({super.key, required this.navigateTo});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final lastScore = prov.scores.isEmpty ? 0 : prov.scores.last.score;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final weekLogs = prov.logs.where((l) => DateTime.tryParse(l.date)?.isAfter(weekAgo) == true).length;
    final admins   = prov.members.where((m) => m.isAdmin).length;
    final students = prov.members.length - admins;
    final total     = prov.missions.length;
    final teamTasks = prov.memberTasks.where((t) => t.memberId == 'all' && !t.done).toList();

    return ListView(padding: const EdgeInsets.all(16), children: [
      // ── Stat cards ─────────────────────────────────────
      GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.3,
        children: [
          _StatCard(
            value: '${prov.members.length}',
            label: 'חברי קבוצה',
            color: AppColors.accent3,
            sub: '$admins מנטורים, $students תלמידים',
          ),
          _StatCard(
            value: '${prov.logs.length}',
            label: 'ימנים שנכתבו',
            color: AppColors.accent,
            sub: '↑ $weekLogs השבוע',
          ),
          _StatCard(
            value: '$lastScore',
            label: 'ניקוד אחרון',
            color: AppColors.accent2,
            sub: prov.scores.isEmpty ? 'אין ריצות עדיין' : null,
          ),
          _StatCard(
            value: '${prov.doneMissions}/$total',
            label: 'משימות הושלמו',
            color: AppColors.gold,
            progress: total > 0 ? prov.doneMissions / total : 0,
          ),
        ],
      ),
      SizedBox(height: 16),

      // ── Competition countdown ──────────────────────────
      if (prov.competitionDate != null) ...[
        _CompetitionBanner(days: prov.daysToCompetition),
        SizedBox(height: 12),
      ],

      // ── Score line chart ───────────────────────────────
      if (prov.scores.isNotEmpty) ...[
        _SectionCard(
          icon: '📈',
          title: 'ניקוד לאורך העונה',
          child: SizedBox(
            height: 160,
            child: _ScoreLineChart(scores: prov.scores),
          ),
        ),
        SizedBox(height: 12),
      ],

      // ── Category progress ──────────────────────────────
      _SectionCard(
        icon: '📊',
        title: 'התקדמות לפי קטגוריה',
        child: _CategoryProgress(prov: prov),
      ),
      SizedBox(height: 12),

      // ── Recent updates ─────────────────────────────────
      _SectionCard(
        icon: '📋',
        title: 'עדכונים אחרונים',
        child: prov.logs.isEmpty
            ? const _Empty('אין עדכונים עדיין')
            : Column(
                children: prov.logs.reversed.take(3).map((l) => _LogTile(l)).toList(),
              ),
      ),
      SizedBox(height: 12),

      // ── Quick actions ──────────────────────────────────
      if (teamTasks.isNotEmpty) ...[
        _SectionCard(
          icon: '📋',
          title: 'משימות קבוצה',
          child: Column(
            children: teamTasks.map((t) => _TeamTaskTile(task: t)).toList(),
          ),
        ),
        SizedBox(height: 12),
      ],
      _SectionCard(
        icon: '⚡',
        title: 'פעולות מהירות',
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _QuickBtn('📋 תיעוד חדש',          AppColors.accent,  () => navigateTo(1)),
            _QuickBtn('📸 הוסף שיפור רובוט',   AppColors.accent3, () => navigateTo(2)),
            _QuickBtn('🎯 מחשבון ניקוד',       AppColors.accent2, () => navigateTo(3)),
            _QuickBtn('⏱️ טיימר ריצה',         AppColors.gold,    () => navigateTo(3)),
          ],
        ),
      ),
    ]);
  }
}

// ─── Score line chart ─────────────────────────────────

class _ScoreLineChart extends StatelessWidget {
  final List<ScoreRun> scores;
  const _ScoreLineChart({required this.scores});

  @override
  Widget build(BuildContext context) {
    final dates = scores.map((s) => s.date).toList();
    final first = dates.first;
    final last  = dates.last;

    return Column(children: [
      Expanded(
        child: CustomPaint(
          painter: _LineChartPainter(scores),
          child: SizedBox.expand(),
        ),
      ),
      SizedBox(height: 4),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(_formatDate(first),
            style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
        if (scores.length > 1)
          Text(_formatDate(last),
              style: TextStyle(fontSize: 10, color: AppColors.textTertiary)),
      ]),
    ]);
  }

  String _formatDate(String iso) {
    final parts = iso.split('-');
    if (parts.length < 3) return iso;
    return '${parts[2]}.${parts[1]}.${parts[0]}';
  }
}

class _LineChartPainter extends CustomPainter {
  final List<ScoreRun> scores;
  _LineChartPainter(this.scores);

  @override
  void paint(Canvas canvas, Size size) {
    if (scores.isEmpty) return;

    final maxScore = scores.map((s) => s.score).reduce(math.max).toDouble();
    final minScore = 0.0;
    final range = maxScore > 0 ? maxScore - minScore : 1.0;
    const pad = 8.0;

    Offset toPoint(int i, int score) {
      final x = scores.length == 1
          ? size.width / 2
          : pad + (i / (scores.length - 1)) * (size.width - pad * 2);
      final y = size.height - pad - ((score - minScore) / range) * (size.height - pad * 2);
      return Offset(x, y);
    }

    final points = [for (int i = 0; i < scores.length; i++) toPoint(i, scores[i].score)];

    // Grid lines
    final gridPaint = Paint()
      ..color = AppColors.border.withAlpha(80)
      ..strokeWidth = 1;
    for (int i = 0; i <= 3; i++) {
      final y = pad + i / 3 * (size.height - pad * 2);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Fill
    final fillPath = Path()..moveTo(points.first.dx, size.height);
    for (final p in points) { fillPath.lineTo(p.dx, p.dy); }
    fillPath.lineTo(points.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [AppColors.accent.withAlpha(80), AppColors.accent.withAlpha(10)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill);

    // Line
    final linePaint = Paint()
      ..color = AppColors.accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < points.length - 1; i++) {
      canvas.drawLine(points[i], points[i + 1], linePaint);
    }

    // Dots + score labels
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      canvas.drawCircle(p, 5, Paint()..color = AppColors.accent);
      canvas.drawCircle(p, 3, Paint()..color = Colors.white);

      final tp = TextPainter(
        text: TextSpan(
          text: '${scores[i].score}',
          style: TextStyle(color: AppColors.textPrimary, fontSize: 10, fontWeight: FontWeight.w700),
        ),
        textDirection: TextDirection.rtl,
      )..layout();
      tp.paint(canvas, Offset(p.dx - tp.width / 2, p.dy - 18));
    }
  }

  @override
  bool shouldRepaint(_LineChartPainter old) => old.scores != scores;
}

// ─── Category progress ────────────────────────────────

class _CategoryProgress extends StatelessWidget {
  final AppProvider prov;
  const _CategoryProgress({required this.prov});

  @override
  Widget build(BuildContext context) {
    // Robot: missions completed + score vs max + improvements + runs
    final missionsPct = prov.missions.isEmpty ? 0.0
        : prov.doneMissions / prov.missions.length;
    final maxPts   = prov.missions.fold(0, (s, m) => s + m.pts);
    final scorePct = maxPts == 0 ? 0.0
        : math.min(prov.bestScore / maxPts, 1.0);
    final improvPct = math.min(prov.improvements.length / 15.0, 1.0);
    final runsPct   = math.min(prov.scores.length / 10.0, 1.0);
    final robotPct  = (missionsPct + scorePct + improvPct + runsPct) / 4;

    // Innovation: problem filled + solution filled + rubric scores + innovation logs
    final problemPct  = prov.innovationProblem.trim().isNotEmpty ? 1.0 : 0.0;
    final solutionPct = prov.innovationSolution.trim().isNotEmpty ? 1.0 : 0.0;
    final innovItems  = prov.rubrics['innovation'] ?? [];
    final rubricPct   = innovItems.isEmpty ? 0.0
        : innovItems.map((r) => r.score).reduce((a, b) => a + b) / (innovItems.length * 4.0);
    final innovLogs   = prov.logs.where((l) => l.topic == 'innovation').length;
    final logsPct     = math.min(innovLogs / 5.0, 1.0);
    final innovPct    = (problemPct + solutionPct + rubricPct + logsPct) / 4;

    // Values: how many of the 6 core values have at least one sticky note
    const coreValues = ['discovery', 'innovation', 'impact', 'inclusion', 'teamwork', 'fun'];
    final covered    = coreValues.where((v) => prov.stickies.any((s) => s.value == v)).length;
    final valuesPct  = covered / coreValues.length;

    return Column(children: [
      _ProgressRow('🤖 תכנון רובוט',   robotPct,  AppColors.accent),
      SizedBox(height: 10),
      _ProgressRow('💡 פרויקט חדשנות', innovPct,  AppColors.accent2),
      SizedBox(height: 10),
      _ProgressRow('⭐ ערכי ליבה',     valuesPct, AppColors.gold),
    ]);
  }
}

class _ProgressRow extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  const _ProgressRow(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(children: [
      Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      const Spacer(),
      Text('${(value * 100).round()}%',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    ]),
    SizedBox(height: 4),
    ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: value, minHeight: 7,
        backgroundColor: AppColors.surface3,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    ),
  ]);
}

// ─── Shared widgets ───────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final Color color;
  final double? progress;
  final String? sub;

  const _StatCard({required this.value, required this.label, required this.color, this.progress, this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 3, decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, Colors.transparent]),
          borderRadius: BorderRadius.circular(2),
        )),
        SizedBox(height: 8),
        Text(value, style: TextStyle(
          fontSize: 28, fontWeight: FontWeight.w900, color: color, fontFamily: 'monospace',
        )),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        if (sub != null)
          Text(sub!, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
        if (progress != null) ...[
          SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress, backgroundColor: AppColors.surface3,
              valueColor: AlwaysStoppedAnimation(color), minHeight: 5,
            ),
          ),
        ],
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String icon;
  final String title;
  final Widget child;
  const _SectionCard({required this.icon, required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(icon, style: TextStyle(fontSize: 20)),
        SizedBox(width: 8),
        Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
      ]),
      SizedBox(height: 12),
      child,
    ]),
  );
}

class _LogTile extends StatelessWidget {
  final LogEntry log;
  const _LogTile(this.log);

  @override
  Widget build(BuildContext context) {
    final topicColor = {
      'robot': AppColors.accent,
      'innovation': AppColors.accent2,
      'values': AppColors.gold,
      'general': AppColors.textSecondary,
    }[log.topic] ?? AppColors.textSecondary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 3, height: 40,
            decoration: BoxDecoration(color: topicColor, borderRadius: BorderRadius.circular(2))),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(log.text, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: AppColors.textPrimary)),
          Text('${log.author} · ${log.date}',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ])),
      ]),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _QuickBtn(this.label, this.color, this.onTap);

  @override
  Widget build(BuildContext context) => ElevatedButton(
    onPressed: onTap,
    style: ElevatedButton.styleFrom(
      backgroundColor: color.withAlpha(30),
      foregroundColor: color,
      side: BorderSide(color: color.withAlpha(80)),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      elevation: 0,
    ),
    child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
  );
}

class _Empty extends StatelessWidget {
  final String msg;
  const _Empty(this.msg);
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Text(msg, style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
    ),
  );
}

class _CompetitionBanner extends StatelessWidget {
  final int? days;
  const _CompetitionBanner({required this.days});

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    final String emoji;

    if (days == null) {
      return SizedBox.shrink();
    } else if (days! > 0) {
      text = 'נותרו $days ימים לתחרות';
      color = days! <= 7 ? AppColors.red : (days! <= 30 ? AppColors.accent3 : AppColors.accent2);
      emoji = days! <= 7 ? '🔥' : '📅';
    } else if (days == 0) {
      text = 'התחרות היום!';
      color = AppColors.gold;
      emoji = '🏆';
    } else {
      text = 'התחרות עברה לפני ${-days!} ימים';
      color = AppColors.textTertiary;
      emoji = '✅';
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(40), color.withAlpha(15)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(100)),
      ),
      child: Row(children: [
        Text(emoji, style: TextStyle(fontSize: 24)),
        SizedBox(width: 12),
        Expanded(child: Text(text, style: TextStyle(
          fontSize: 15, fontWeight: FontWeight.w800, color: color,
        ))),
        if (days != null && days! > 0)
          Text('$days', style: TextStyle(
            fontSize: 32, fontWeight: FontWeight.w900,
            color: color, fontFamily: 'monospace',
          )),
      ]),
    );
  }
}

class _TeamTaskTile extends StatelessWidget {
  final MemberTask task;
  const _TeamTaskTile({required this.task});

  static bool _overdue(MemberTask t) {
    if (t.done || t.due == null) return false;
    final parts = t.due!.split('/');
    if (parts.length != 3) return false;
    final d = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final y = int.tryParse(parts[2]);
    if (d == null || m == null || y == null) return false;
    return DateTime(y, m, d).isBefore(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final late = _overdue(task);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(children: [
        Container(
          width: 3, height: 36,
          decoration: BoxDecoration(
            color: late ? AppColors.red : AppColors.accent2,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task.desc, maxLines: 2, overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 13, color: late ? AppColors.red : AppColors.textPrimary)),
          if (task.due != null)
            Text(
              late ? '⚠️ ${task.due!} - עבר הדדליין!' : '📅 ${task.due!}',
              style: TextStyle(fontSize: 11, color: late ? AppColors.red : AppColors.textTertiary),
            ),
        ])),
        GestureDetector(
          onTap: () => context.read<AppProvider>().toggleMemberTask(task.id),
          child: Icon(Icons.check_circle_outline, size: 20, color: AppColors.accent2),
        ),
      ]),
    );
  }
}
