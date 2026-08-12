import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'tour_keys.dart';
import 'tour_nav.dart';

/// One step of the guided tour. [targetKey] is spotlighted; if null the
/// step is shown as a centered card with a full dim backdrop. [screenIndex]
/// switches ShellScreen's active tab before the step renders. [before] runs
/// after that switch (e.g. to open the drawer, or flip an in-screen tab).
/// [actionClick] steps only advance when the user taps the real spotlighted
/// widget (its own handler still fires) rather than a "Next" button.
class TourStep {
  final int? screenIndex;
  final GlobalKey? targetKey;
  final VoidCallback? before;
  final String title;
  final String text;
  final bool actionClick;
  final bool adminOnly;

  const TourStep({
    this.screenIndex,
    this.targetKey,
    this.before,
    required this.title,
    required this.text,
    this.actionClick = false,
    this.adminOnly = false,
  });
}

class TourController {
  TourController._();
  static final navigatorKey = GlobalKey<NavigatorState>();

  static List<TourStep> _steps = [];
  static int _index = 0;
  static OverlayEntry? _entry;
  static Rect? _targetRect;
  static bool _isAdmin = false;

  static Future<String> _prefsKey(BuildContext context) async {
    final email = context.read<AppProvider>().currentUser?.email ?? 'local';
    return 'fll_tour_seen_$email';
  }

  /// Call once after login. Shows the tour automatically the first time
  /// this user ever reaches the app on this device, never again after.
  static Future<void> maybeAutoStart(BuildContext context) async {
    final key = await _prefsKey(context);
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(key) == true) return;
    await Future.delayed(const Duration(milliseconds: 700));
    if (context.mounted) start(context);
  }

  static List<TourStep> _buildSteps() => [
    const TourStep(
      screenIndex: 0,
      title: '👋 ברוכים הבאים ל-FLL Manager!',
      text: 'בואו נעשה סיור קצר באפליקציה. אפשר להפעיל את הסיור הזה שוב בכל רגע דרך ההגדרות.',
    ),
    TourStep(
      screenIndex: 0,
      targetKey: TourKeys.menuButton,
      title: '☰ תפריט ראשי',
      text: 'לחצו כאן (או גררו מהקצה) כדי לראות את כל מסכי האפליקציה ולעבור ביניהם.',
    ),
    TourStep(
      screenIndex: 0,
      targetKey: TourKeys.dashboardStats,
      title: '📊 כרטיסי סיכום',
      text: 'ארבעה מספרים שמתעדכנים לבד: חברי קבוצה, יומנים שנכתבו, הניקוד האחרון, ומשימות רובוט שהושלמו.',
    ),
    TourStep(
      screenIndex: 0,
      targetKey: TourKeys.dashboardCategoryProgress,
      title: '📈 התקדמות לפי קטגוריה',
      text: 'סרגלי התקדמות לרובוט, חדשנות וערכים — מחושבים אוטומטית לפי כמה תיעדתם בכל תחום.',
    ),
    TourStep(
      screenIndex: 0,
      targetKey: TourKeys.dashboardRecentUpdates,
      title: '📋 עדכונים אחרונים',
      text: 'התיעודים האחרונים שחברי הקבוצה כתבו, כדי שתדעו מה קרה גם אם לא הייתם שם.',
    ),
    TourStep(
      screenIndex: 0,
      targetKey: TourKeys.dashboardQuickActions,
      title: '⚡ פעולות מהירות',
      text: 'קיצורי דרך לפעולות נפוצות — תיעוד חדש, הוספת שיפור רובוט, ומחשבון ניקוד.',
    ),
    TourStep(
      screenIndex: 0,
      targetKey: TourKeys.addButton,
      title: '➕ הוספה מהירה',
      text: 'כפתור זה זמין מכל מסך, ופותח את הפעולה המתאימה לאותו מסך — למשל תיעוד חדש.',
    ),
    TourStep(
      screenIndex: 14,
      targetKey: TourKeys.settingsThemeSwitch,
      title: '🌙 / ☀️ מצב כהה ובהיר',
      text: 'אפשר להחליף בין מצב כהה למצב בהיר בכל רגע. נסו ללחוץ על המתג עכשיו!',
      actionClick: true,
    ),
    TourStep(
      screenIndex: 14,
      targetKey: TourKeys.settingsHelpButton,
      title: '🎓 סיימנו!',
      text: 'זה היה סיור לדוגמה על הדשבורד וההגדרות — בהמשך יתווספו כאן סיורים גם לשאר המסכים. את הסיור הזה תמיד אפשר להפעיל שוב מכאן.',
    ),
  ];

  static void start(BuildContext context) {
    end();
    _isAdmin = context.read<AppProvider>().isAdmin;
    _steps = _buildSteps();
    if (_steps.isEmpty) return;
    _index = 0;
    final overlayState = navigatorKey.currentState?.overlay;
    if (overlayState == null) return;
    _entry = OverlayEntry(builder: (ctx) => _TourOverlay());
    overlayState.insert(_entry!);
    _renderStep(context, 1);
  }

  static void _renderStep(BuildContext context, int direction) async {
    if (_index < 0 || _index >= _steps.length) { end(); return; }
    final step = _steps[_index];

    if (step.adminOnly && !_isAdmin) {
      _index += direction;
      _renderStep(context, direction);
      return;
    }
    if (step.screenIndex != null) TourNav.jumpToIndex(step.screenIndex!);
    if (step.before != null) step.before!();

    // Let the frame settle after navigation/tab changes before measuring.
    await Future.delayed(const Duration(milliseconds: 120));
    if (!context.mounted) return;

    if (step.targetKey != null) {
      final rect = _rectFor(step.targetKey!);
      if (rect == null) {
        _index += direction;
        _renderStep(context, direction);
        return;
      }
      _targetRect = rect;
    } else {
      _targetRect = null;
    }
    _entry?.markNeedsBuild();
  }

  static Rect? _rectFor(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return null;
    final box = ctx.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return null;
    if (box.size.isEmpty) return null;
    final topLeft = box.localToGlobal(Offset.zero);
    return topLeft & box.size;
  }

  static void advance(BuildContext context) {
    _index++;
    if (_index >= _steps.length) { end(); return; }
    _renderStep(context, 1);
  }

  static void back(BuildContext context) {
    _index--;
    if (_index < 0) { _index = 0; return; }
    _renderStep(context, -1);
  }

  static Future<void> end() async {
    _entry?.remove();
    _entry = null;
    _targetRect = null;
    final ctx = navigatorKey.currentContext;
    if (ctx != null && ctx.mounted) {
      final key = await _prefsKey(ctx);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(key, true);
    }
  }

  static TourStep? get currentStep => (_index >= 0 && _index < _steps.length) ? _steps[_index] : null;
  static int get index => _index;
  static int get total => _steps.length;
  static Rect? get targetRect => _targetRect;
}

class _TourOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final step = TourController.currentStep;
    if (step == null) return const SizedBox.shrink();
    final size = MediaQuery.of(context).size;
    final r = TourController.targetRect;
    const pad = 6.0;

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (event) {
        if (step.actionClick && r != null && r.inflate(pad).contains(event.position)) {
          Future.delayed(const Duration(milliseconds: 350), () {
            if (context.mounted) TourController.advance(context);
          });
        }
      },
      child: Stack(children: [
        if (r == null)
          Positioned.fill(child: Container(color: Colors.black.withAlpha(184)))
        else ...[
          _mask(0, 0, size.width, r.top - pad),
          _mask(0, r.bottom + pad, size.width, size.height - r.bottom - pad),
          _mask(0, r.top - pad, r.left - pad, r.height + pad * 2),
          _mask(r.right + pad, r.top - pad, size.width - r.right - pad, r.height + pad * 2),
          Positioned(
            left: r.left - pad, top: r.top - pad,
            width: r.width + pad * 2, height: r.height + pad * 2,
            child: IgnorePointer(
              child: Container(decoration: BoxDecoration(
                border: Border.all(color: AppColors.accent2, width: 2),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: AppColors.accent2.withAlpha(140), blurRadius: 16, spreadRadius: 2)],
              )),
            ),
          ),
          if (!step.actionClick)
            Positioned(
              left: r.left - pad, top: r.top - pad,
              width: r.width + pad * 2, height: r.height + pad * 2,
              child: GestureDetector(behavior: HitTestBehavior.opaque, onTap: () {}),
            ),
        ],
        _tooltip(context, step, r, size),
        Positioned(
          top: MediaQuery.of(context).padding.top + 8, left: 16,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => TourController.end(),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Text('✕ דלג על הסיור', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _mask(double x, double y, double w, double h) {
    if (w <= 0 || h <= 0) return const SizedBox.shrink();
    return Positioned(
      left: x, top: y, width: w, height: h,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {},
        child: Container(color: Colors.black.withAlpha(184)),
      ),
    );
  }

  Widget _tooltip(BuildContext context, TourStep step, Rect? r, Size screenSize) {
    const margin = 16.0;
    const width = 300.0;

    double top;
    double left;
    if (r == null) {
      top = screenSize.height / 2 - 90;
      left = (screenSize.width - width) / 2;
    } else {
      final spaceBelow = screenSize.height - r.bottom;
      final spaceAbove = r.top;
      top = (spaceBelow >= 190 || spaceBelow >= spaceAbove)
          ? (r.bottom + margin).clamp(margin, screenSize.height - 190 - margin)
          : (r.top - 190 - margin).clamp(margin, screenSize.height - margin);
      left = (r.left + r.width / 2 - width / 2).clamp(margin, screenSize.width - width - margin);
    }

    return Positioned(
      left: left, top: top, width: width,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(100), blurRadius: 20, offset: const Offset(0, 8))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(step.title, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.textPrimary)),
            SizedBox(height: 8),
            Text(step.text, style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.textSecondary)),
            if (step.actionClick) ...[
              SizedBox(height: 12),
              Row(children: [
                Text('👆', style: TextStyle(fontSize: 14)),
                SizedBox(width: 6),
                Expanded(child: Text('לחצו על הרכיב המודגש כדי להמשיך',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.accent2))),
              ]),
            ],
            SizedBox(height: 14),
            Row(children: [
              Text('${TourController.index + 1} / ${TourController.total}',
                  style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
              const Spacer(),
              if (TourController.index > 0)
                TextButton(
                  onPressed: () => TourController.back(context),
                  child: Text('חזרה', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                ),
              if (!step.actionClick)
                ElevatedButton(
                  onPressed: () => TourController.advance(context),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent2, foregroundColor: Colors.black),
                  child: Text(TourController.index == TourController.total - 1 ? 'סיום' : 'הבא', style: TextStyle(fontSize: 12)),
                ),
            ]),
          ]),
        ),
      ),
    );
  }
}
