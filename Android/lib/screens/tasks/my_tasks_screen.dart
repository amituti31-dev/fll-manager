import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';

class MyTasksScreen extends StatefulWidget {
  const MyTasksScreen({super.key});

  @override
  State<MyTasksScreen> createState() => _MyTasksScreenState();
}

class _MyTasksScreenState extends State<MyTasksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    final uid = prov.currentUser?.id ?? '';

    final myTasks = prov.memberTasks
        .where((t) => t.memberId == uid || t.memberId == 'all')
        .toList();

    final pending  = myTasks.where((t) => !t.done).toList();
    final done     = myTasks.where((t) =>  t.done).toList();
    final overdueN = pending.where((t) => AppProvider.isTaskOverdue(t)).length;

    return Column(children: [
      // ── Stats bar ──────────────────────────────────
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: AppColors.surface,
        child: Row(children: [
          _Chip(count: pending.length, label: 'ממתין',   color: AppColors.accent),
          const SizedBox(width: 8),
          _Chip(count: done.length,    label: 'הושלם',   color: AppColors.accent2),
          if (overdueN > 0) ...[
            const SizedBox(width: 8),
            _Chip(count: overdueN, label: '⚠️ פגה תוקף', color: AppColors.red),
          ],
        ]),
      ),
      // ── Tab bar ────────────────────────────────────
      Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(bottom: BorderSide(color: AppColors.border)),
        ),
        child: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: [
            Tab(text: 'ממתין (${pending.length})'),
            Tab(text: 'הושלמו (${done.length})'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _TaskList(tasks: pending, prov: prov),
            _TaskList(tasks: done,    prov: prov),
          ],
        ),
      ),
    ]);
  }
}

// ─── Task list ────────────────────────────────────────

class _TaskList extends StatelessWidget {
  final List<MemberTask> tasks;
  final AppProvider prov;
  const _TaskList({required this.tasks, required this.prov});

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('✅', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 12),
        Text('אין משימות כאן',
            style: TextStyle(color: AppColors.textTertiary, fontSize: 15)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tasks.length,
      itemBuilder: (_, i) => _TaskCard(task: tasks[i], prov: prov),
    );
  }
}

// ─── Task card ────────────────────────────────────────

class _TaskCard extends StatelessWidget {
  final MemberTask task;
  final AppProvider prov;
  const _TaskCard({required this.task, required this.prov});

  Color get _borderColor {
    if (AppProvider.isTaskOverdue(task)) return AppColors.red;
    if (task.done) return AppColors.accent2.withAlpha(100);
    return AppColors.border;
  }

  @override
  Widget build(BuildContext context) {
    final overdue  = AppProvider.isTaskOverdue(task);
    final isForAll = task.memberId == 'all';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // ── Checkbox ────────────────────────────────
          GestureDetector(
            onTap: () => prov.toggleMemberTask(task.id),
            child: Container(
              margin: const EdgeInsets.only(top: 2),
              width: 26, height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: task.done ? AppColors.accent2 : Colors.transparent,
                border: Border.all(
                  color: task.done ? AppColors.accent2 : AppColors.border,
                  width: 2,
                ),
              ),
              child: task.done
                  ? const Icon(Icons.check, size: 14, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          // ── Content ─────────────────────────────────
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.desc, style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: task.done ? AppColors.textSecondary : AppColors.textPrimary,
              decoration: task.done ? TextDecoration.lineThrough : null,
            )),
            const SizedBox(height: 6),
            Wrap(spacing: 6, runSpacing: 4, children: [
              if (isForAll)
                _Tag(text: '👥 כל הקבוצה', color: AppColors.accent),
              if (task.due != null)
                _Tag(
                  text: '${overdue ? "⚠️ " : "📅 "}${task.due!}',
                  color: overdue ? AppColors.red : AppColors.textSecondary,
                ),
              if (overdue && !task.done)
                _Tag(text: 'פגה תוקף!', color: AppColors.red),
            ]),
          ])),
          const SizedBox(width: 8),
          // ── Done button ──────────────────────────────
          if (!task.done)
            TextButton(
              onPressed: () => prov.toggleMemberTask(task.id),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.accent2,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('✓ סיים',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
        ]),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────

class _Chip extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  const _Chip({required this.count, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: color.withAlpha(25),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: color.withAlpha(80)),
    ),
    child: Text('$count $label',
        style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w700)),
  );
}

class _Tag extends StatelessWidget {
  final String text;
  final Color color;
  const _Tag({required this.text, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: color.withAlpha(20),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Text(text, style: TextStyle(fontSize: 11, color: color)),
  );
}
