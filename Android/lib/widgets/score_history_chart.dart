import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../models/models.dart';
import '../theme/app_theme.dart';

/// Full run-history line chart — shared between the Scoring screen (its own
/// "גרף התקדמות" card) and the dashboard's "open full history" popup.
class ScoreHistoryChart extends StatelessWidget {
  final List<ScoreRun> scores;
  const ScoreHistoryChart({super.key, required this.scores});

  @override
  Widget build(BuildContext context) {
    final maxScore = scores.fold(0, (m, s) => s.score > m ? s.score : m);
    final bestIdx = scores.indexWhere((s) => s.score == maxScore);
    final spots = scores.asMap().entries
        .map((e) => FlSpot((e.key + 1).toDouble(), e.value.score.toDouble()))
        .toList();
    final yMax = (maxScore + 30).clamp(50, 500).toDouble();
    final xInterval = scores.length > 8 ? 2.0 : 1.0;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text('📈', style: TextStyle(fontSize: 18)),
        SizedBox(width: 8),
        Text('גרף התקדמות', style: TextStyle(
            fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
        Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.gold.withAlpha(30),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text('🏆 שיא: $maxScore', style: TextStyle(
              fontSize: 12, color: AppColors.gold, fontWeight: FontWeight.w700)),
        ),
      ]),
      SizedBox(height: 16),
      SizedBox(
        height: 180,
        child: LineChart(LineChartData(
          minX: 1,
          maxX: scores.length.toDouble(),
          minY: 0,
          maxY: yMax,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 50,
            getDrawingHorizontalLine: (_) => FlLine(
              color: AppColors.border,
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 50,
                reservedSize: 36,
                getTitlesWidget: (val, meta) {
                  if (val == 0) return const SizedBox.shrink();
                  return Text('${val.toInt()}',
                      style: TextStyle(fontSize: 10, color: AppColors.textTertiary));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: xInterval,
                reservedSize: 20,
                getTitlesWidget: (val, meta) {
                  final i = val.toInt();
                  if (val != i.toDouble()) return const SizedBox.shrink();
                  return Text('$i',
                      style: TextStyle(fontSize: 10, color: AppColors.textTertiary));
                },
              ),
            ),
          ),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipColor: (_) => AppColors.surface2,
              getTooltipItems: (spots) => spots.map((s) => LineTooltipItem(
                'ריצה ${s.x.toInt()}: ${s.y.toInt()} נק\'',
                TextStyle(
                  color: AppColors.accent2,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              )).toList(),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: scores.length > 2,
              curveSmoothness: 0.3,
              color: AppColors.accent,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.accent.withAlpha(40),
              ),
              dotData: FlDotData(
                show: true,
                getDotPainter: (spot, _, __, idx) => FlDotCirclePainter(
                  radius: idx == bestIdx ? 6 : 4,
                  color: idx == bestIdx ? AppColors.gold : AppColors.accent,
                  strokeWidth: 2,
                  strokeColor: Colors.white,
                ),
              ),
            ),
          ],
        )),
      ),
    ]);
  }
}
