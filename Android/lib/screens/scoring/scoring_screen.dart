import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../providers/app_provider.dart';
import '../../services/firebase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/score_history_chart.dart';
import '../../widgets/rubric_grid.dart';

class ScoringScreen extends StatefulWidget {
  const ScoringScreen({super.key});

  @override
  State<ScoringScreen> createState() => _ScoringScreenState();
}

const _judgingPhases = [
  ('🚪', 'קבלת פני קבוצה',          2 * 60),
  ('🤖', 'תכנון רובוט',              5 * 60),
  ('❓', 'שאלות על תכנון רובוט',     5 * 60),
  ('💡', 'פרויקט חדשנות',            5 * 60),
  ('🔍', 'שאלות על פרויקט חדשנות',  5 * 60),
  ('🕐', 'זמן חופשי',                6 * 60),
];

class _ScoringScreenState extends State<ScoringScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  // Robot timer
  Timer? _robotTimer;
  int _robotSecs = 150;
  bool _robotRunning = false;
  bool _pulseTick = false;

  // Judging timer
  Timer? _judgeTimer;
  int _judgePhase = 0;
  int _judgeSecs = _judgingPhases[0].$3;
  bool _judgeRunning = false;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _robotTimer?.cancel();
    _judgeTimer?.cancel();
    super.dispose();
  }

  // ── Robot timer ────────────────────────────────────
  void _startStopRobot() {
    if (_robotRunning) {
      _robotTimer?.cancel();
      setState(() { _robotRunning = false; _pulseTick = false; });
    } else {
      _robotTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (_robotSecs > 0) {
          setState(() { _robotSecs--; _pulseTick = !_pulseTick; });
          if (_robotSecs == 30) HapticFeedback.mediumImpact();
          if (_robotSecs <= 10 && _robotSecs > 0) HapticFeedback.heavyImpact();
          if (_robotSecs == 0) {
            _robotTimer?.cancel();
            setState(() { _robotRunning = false; _pulseTick = false; });
            HapticFeedback.vibrate();
          }
        }
      });
      HapticFeedback.lightImpact();
      setState(() => _robotRunning = true);
    }
  }

  void _resetRobot() {
    _robotTimer?.cancel();
    setState(() { _robotSecs = 150; _robotRunning = false; _pulseTick = false; });
  }

  // ── Judging timer ──────────────────────────────────
  void _startStopJudge() {
    if (_judgeRunning) {
      _judgeTimer?.cancel();
      setState(() => _judgeRunning = false);
    } else {
      _judgeTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        setState(() {
          if (_judgeSecs > 0) {
            _judgeSecs--;
          } else {
            _judgeTimer?.cancel();
            _judgeRunning = false;
            if (_judgePhase < _judgingPhases.length - 1) {
              _judgePhase++;
              _judgeSecs = _judgingPhases[_judgePhase].$3;
            }
          }
        });
      });
      setState(() => _judgeRunning = true);
    }
  }

  void _resetJudge() {
    _judgeTimer?.cancel();
    setState(() {
      _judgePhase = 0;
      _judgeSecs = _judgingPhases[0].$3;
      _judgeRunning = false;
    });
  }

  void _jumpToPhase(int i) {
    _judgeTimer?.cancel();
    setState(() {
      _judgePhase = i;
      _judgeSecs = _judgingPhases[i].$3;
      _judgeRunning = false;
    });
  }

  // ── Helpers ────────────────────────────────────────
  String _nextStatus(String current) => switch (current) {
    'not_tried' => 'in_progress',
    'in_progress' => 'ready',
    _ => 'not_tried',
  };

  String _fmt(int secs) {
    final m = secs ~/ 60;
    final s = secs % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  Color get _robotColor {
    if (_robotSecs <= 10) return AppColors.red;
    if (_robotSecs <= 30) return AppColors.accent3;
    return AppColors.textPrimary;
  }

  Color get _judgeColor {
    if (_judgeSecs <= 30) return AppColors.red;
    if (_judgeSecs <= 60) return AppColors.accent3;
    return AppColors.textPrimary;
  }

  Future<void> _resetMissions(BuildContext context, AppProvider prov) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('איפוס משימות', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('לאפס לרשימת ברירת המחדל?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('ביטול')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: Text('אפס')),
        ],
      ),
    );
    if (confirm == true) await prov.resetMissions();
  }

  // ── Build ──────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return Column(children: [
      Container(
        color: AppColors.surface,
        child: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: '🤖 ריצת רובוט'),
            Tab(text: '🏛️ חדר שיפוט'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _buildRobotTab(prov),
            _buildJudgingTab(prov),
          ],
        ),
      ),
    ]);
  }

  // ── Tab 1: Robot ───────────────────────────────────
  Widget _buildRobotTab(AppProvider prov) {
    final total = prov.totalScore;

    return ListView(padding: const EdgeInsets.all(16), children: [
      // Total score
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [AppColors.accent, AppColors.accent2]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          Text('$total', style: TextStyle(
            fontSize: 64, fontWeight: FontWeight.w900, color: Colors.white, fontFamily: 'monospace',
          )),
          Text('נקודות סה"כ', style: TextStyle(color: Colors.white70, fontSize: 14)),
        ]),
      ),
      SizedBox(height: 12),
      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => context.read<AppProvider>().saveRun(),
          icon: Text('💾'),
          label: Text('שמור ריצה'),
          style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent2,
              padding: const EdgeInsets.symmetric(vertical: 12)),
        ),
      ),
      SizedBox(height: 20),

      // Robot timer
      _card(Column(children: [
        Row(children: [
          Text('⏱️', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Text('טיימר ריצת רובוט', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
        ]),
        SizedBox(height: 12),
        AnimatedScale(
          scale: _robotRunning ? (_pulseTick ? 1.04 : 0.97) : 1.0,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
          child: Text(_fmt(_robotSecs), style: TextStyle(
            fontSize: 72, fontWeight: FontWeight.w700, color: _robotColor,
            fontFamily: 'monospace', letterSpacing: 4,
          )),
        ),
        SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton.icon(
            onPressed: _startStopRobot,
            icon: Text(_robotRunning ? '⏸' : '▶'),
            label: Text(_robotRunning ? 'עצור' : 'התחל'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent),
          ),
          SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _resetRobot,
            icon: Text('↺'),
            label: Text('אפס'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
        ]),
      ])),
      SizedBox(height: 16),

      // Missions
      _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('🎯', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Expanded(child: Text('משימות', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary))),
          if (prov.isAdmin)
            GestureDetector(
              onTap: () => _resetMissions(context, prov),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.accent.withAlpha(30),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.accent.withAlpha(80)),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.refresh, size: 12, color: AppColors.accent),
                  SizedBox(width: 4),
                  Text('איפוס', style: TextStyle(
                      fontSize: 12, color: AppColors.accent, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
        ]),
        SizedBox(height: 12),
        ...prov.missions.map((m) {
          final done = prov.missionChecks[m.id] == true;
          final extra = prov.missionExtra[m.id];
          final statusEmoji = switch (m.status) {
            'in_progress' => '🔧',
            'ready' => '⭐',
            _ => '❓',
          };
          final statusColor = switch (m.status) {
            'in_progress' => AppColors.accent3,
            'ready' => AppColors.accent2,
            _ => AppColors.textTertiary,
          };
          return InkWell(
            onTap: () => context.read<AppProvider>().toggleMission(m.id),
            onLongPress: () {
              final next = _nextStatus(m.status);
              context.read<AppProvider>().setMissionStatus(m.id, next);
              HapticFeedback.selectionClick();
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Text(done ? '✅' : '⬜', style: TextStyle(fontSize: 20)),
                SizedBox(width: 12),
                Expanded(child: Text(m.name, style: TextStyle(
                  fontSize: 14,
                  color: done ? AppColors.accent2 : AppColors.textPrimary,
                  decoration: done ? TextDecoration.lineThrough : null,
                ))),
                if (extra != null && extra.bonusPts > 0) ...[
                  GestureDetector(
                    onTap: () => context.read<AppProvider>().toggleMissionBonusDone(m.id),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text(extra.bonusDone ? '✅' : '⬜', style: TextStyle(fontSize: 18)),
                      SizedBox(width: 4),
                      Text('🎁+${extra.bonusPts}', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700,
                        color: extra.bonusDone ? AppColors.gold : AppColors.textTertiary,
                      )),
                    ]),
                  ),
                  SizedBox(width: 6),
                ],
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: statusColor.withAlpha(80)),
                  ),
                  child: Text(statusEmoji, style: TextStyle(fontSize: 12)),
                ),
                SizedBox(width: 8),
                Text('${m.pts}', style: TextStyle(
                  fontFamily: 'monospace', fontWeight: FontWeight.w700,
                  color: done ? AppColors.accent2 : AppColors.textTertiary,
                )),
              ]),
            ),
          );
        }),
      ])),
      SizedBox(height: 8),
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('לחיצה ארוכה על משימה לשינוי סטטוס תרגול',
            style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
            textAlign: TextAlign.center),
      ),
      SizedBox(height: 8),

      // Mission status summary
      _card(Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        _StatusChip('❓', 'לא נסינו', prov.missionStatusCounts['not_tried'] ?? 0, AppColors.textTertiary),
        _StatusChip('🔧', 'בעבודה',   prov.missionStatusCounts['in_progress'] ?? 0, AppColors.accent3),
        _StatusChip('⭐', 'מוכן',     prov.missionStatusCounts['ready'] ?? 0, AppColors.accent2),
      ])),
      SizedBox(height: 16),

      // Score history with chart
      if (prov.scores.isNotEmpty)
        _card(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          ScoreHistoryChart(scores: prov.scores),
          SizedBox(height: 16),
          Divider(color: AppColors.border, height: 1),
          SizedBox(height: 12),
          Row(children: [
            Text('📋', style: TextStyle(fontSize: 16)),
            SizedBox(width: 8),
            Text('אחרון', style: TextStyle(
                fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
          ]),
          SizedBox(height: 8),
          ...prov.scores.reversed.take(5).map((s) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(children: [
              Text(s.notes, style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const Spacer(),
              Text('${s.score}', style: TextStyle(
                  fontFamily: 'monospace', fontWeight: FontWeight.w900,
                  color: AppColors.accent2, fontSize: 18)),
              Text(' נק\'', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
            ]),
          )),
        ])),
    ]);
  }

  // ── Tab 2: Judging Room ────────────────────────────
  Widget _buildJudgingTab(AppProvider prov) {
    return ListView(padding: const EdgeInsets.all(16), children: [

      // Judging session timer
      _card(Column(children: [
        Row(children: [
          Text('🏛️', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Expanded(child: Text('טיימר ישיבת שיפוט', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: AppColors.accent2.withAlpha(30),
                borderRadius: BorderRadius.circular(10)),
            child: Text('שלב ${_judgePhase + 1}/${_judgingPhases.length}',
                style: TextStyle(
                    fontSize: 11, color: AppColors.accent2, fontWeight: FontWeight.w700)),
          ),
        ]),
        SizedBox(height: 10),

        // Phase chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (int i = 0; i < _judgingPhases.length; i++)
              GestureDetector(
                onTap: () => _jumpToPhase(i),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: i == _judgePhase ? AppColors.accent2 : AppColors.surface2,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: i == _judgePhase ? AppColors.accent2 : AppColors.border),
                  ),
                  child: Text(_judgingPhases[i].$1, style: TextStyle(fontSize: 16)),
                ),
              ),
          ]),
        ),
        SizedBox(height: 8),
        Text(_judgingPhases[_judgePhase].$2,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
        SizedBox(height: 8),
        Text(_fmt(_judgeSecs), style: TextStyle(
          fontSize: 60, fontWeight: FontWeight.w700, color: _judgeColor,
          fontFamily: 'monospace', letterSpacing: 3,
        )),
        SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          ElevatedButton.icon(
            onPressed: _startStopJudge,
            icon: Text(_judgeRunning ? '⏸' : '▶'),
            label: Text(_judgeRunning ? 'עצור' : 'התחל'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent2),
          ),
          SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _resetJudge,
            icon: Text('↺'),
            label: Text('אפס'),
            style: OutlinedButton.styleFrom(foregroundColor: AppColors.textSecondary),
          ),
        ]),
      ])),
      SizedBox(height: 16),

      // Rubrics link
      OutlinedButton.icon(
        onPressed: () => launchUrl(
          Uri.parse('https://fll-events.firstisrael.org.il/tools/rubrics'),
          mode: LaunchMode.externalApplication,
        ),
        icon: Icon(Icons.open_in_new, size: 16),
        label: Text('מחווני שיפוט רשמיים – FIRST Israel',
            style: TextStyle(fontSize: 13)),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.accent2,
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
      SizedBox(height: 16),

      // All three official rubrics in one place — just mark a level per criterion
      const RubricGrid(),
      SizedBox(height: 12),

      // Judging PDF
      _JudgingPdfCard(prov: prov),
    ]);
  }

  Widget _card(Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: child,
  );
}

// ─── Status Chip ──────────────────────────────────────

class _StatusChip extends StatelessWidget {
  final String emoji;
  final String label;
  final int count;
  final Color color;
  const _StatusChip(this.emoji, this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
    Text(emoji, style: TextStyle(fontSize: 20)),
    SizedBox(height: 4),
    Text('$count', style: TextStyle(
      fontSize: 18, fontWeight: FontWeight.w800, color: color, fontFamily: 'monospace',
    )),
    Text(label, style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
  ]);
}

// ─── Judging PDF Card ─────────────────────────────────

class _JudgingPdfCard extends StatefulWidget {
  final AppProvider prov;
  const _JudgingPdfCard({required this.prov});

  @override
  State<_JudgingPdfCard> createState() => _JudgingPdfCardState();
}

class _JudgingPdfCardState extends State<_JudgingPdfCard> {
  bool _uploading = false;
  bool _opening = false;

  Future<void> _pickAndUpload() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    final file = result.files.single;

    setState(() => _uploading = true);
    try {
      await FirebaseService.saveJudgingPdf(
        widget.prov.teamId!,
        file.bytes!,
        file.name,
      );
      await widget.prov.setJudgingPdfName(file.name);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בהעלאה: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _openPdf() async {
    setState(() => _opening = true);
    try {
      final data = await FirebaseService.loadJudgingPdf(widget.prov.teamId!);
      if (data == null) return;
      final bytes = base64Decode(data['data'] as String);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/judging.pdf');
      await file.writeAsBytes(bytes);
      await Share.shareXFiles([XFile(file.path)], text: 'מסמך חדר שיפוט');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('שגיאה בפתיחה: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _opening = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = widget.prov;
    final hasPdf = prov.judgingPdfName != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('📄', style: TextStyle(fontSize: 18)),
          SizedBox(width: 8),
          Expanded(child: Text('מסמך חדר שיפוט', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15,
              color: AppColors.textPrimary))),
          if (prov.isAdmin && hasPdf)
            GestureDetector(
              onTap: () async {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: Text('מחיקת מסמך',
                        style: TextStyle(color: AppColors.textPrimary)),
                    content: Text('למחוק את המסמך הנוכחי?',
                        style: TextStyle(color: AppColors.textSecondary)),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('ביטול')),
                      ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.red),
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('מחק')),
                    ],
                  ),
                );
                if (ok == true) await prov.removeJudgingPdf();
              },
              child: Icon(Icons.delete_outline,
                  size: 20, color: AppColors.textTertiary),
            ),
        ]),
        SizedBox(height: 12),
        if (!hasPdf) ...[
          Text('לא הועלה מסמך עדיין',
              style: TextStyle(
                  color: AppColors.textTertiary, fontSize: 13)),
          if (prov.isAdmin) ...[
            SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _uploading ? null : _pickAndUpload,
                icon: _uploading
                    ? SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text('📤'),
                label: Text(_uploading ? 'מעלה...' : 'העלה PDF'),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent2,
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              ),
            ),
          ],
        ] else ...[
          Row(children: [
            Icon(Icons.picture_as_pdf, color: AppColors.red, size: 28),
            SizedBox(width: 10),
            Expanded(child: Text(
              prov.judgingPdfName ?? 'מסמך שיפוט',
              style: TextStyle(
                  fontSize: 13, color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            )),
          ]),
          SizedBox(height: 12),
          Row(children: [
            Expanded(child: ElevatedButton.icon(
              onPressed: _opening ? null : _openPdf,
              icon: _opening
                  ? SizedBox(
                      width: 16, height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(Icons.open_in_new, size: 16),
              label: Text(_opening ? 'טוען...' : 'פתח מסמך'),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent2,
                  padding: const EdgeInsets.symmetric(vertical: 12)),
            )),
            if (prov.isAdmin) ...[
              SizedBox(width: 10),
              Expanded(child: OutlinedButton.icon(
                onPressed: _uploading ? null : _pickAndUpload,
                icon: _uploading
                    ? SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text('📤'),
                label: Text(_uploading ? 'מעלה...' : 'החלף'),
                style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                    padding: const EdgeInsets.symmetric(vertical: 12)),
              )),
            ],
          ]),
        ],
      ]),
    );
  }
}
