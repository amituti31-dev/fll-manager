import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/models.dart';
import '../../theme/app_theme.dart';
import '../chat/direct_chat_screen.dart';

class TeamScreen extends StatefulWidget {
  const TeamScreen({super.key});

  @override
  State<TeamScreen> createState() => _TeamScreenState();

  static Future<void> showAddTaskDialog(BuildContext context, {Member? forMember}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _AddTaskSheet(forMember: forMember),
    );
  }

  static void _showAddMemberDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddMemberDialog(),
    );
  }

  static void _addChecklistItem(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const _AddChecklistDialog(),
    );
  }
}

class _TeamScreenState extends State<TeamScreen> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

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
    return Column(children: [
      Container(
        color: AppColors.surface,
        child: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: const [
            Tab(text: '👥 הקבוצה'),
            Tab(text: '📋 המשימות שלי'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            _TeamTab(prov: prov),
            _MyTasksTab(prov: prov),
          ],
        ),
      ),
    ]);
  }
}

// ─── Team Tab ─────────────────────────────────────────

class _TeamTab extends StatelessWidget {
  final AppProvider prov;
  const _TeamTab({required this.prov});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.all(16), children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            Text('${prov.members.length}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            Text('חברי קבוצה', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ]),
        ),
        SizedBox(width: 12),
        if (prov.isAdmin)
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => TeamScreen._showAddMemberDialog(context),
                  icon: Icon(Icons.person_add, size: 16),
                  label: Text('הוסף חבר'),
                ),
                ElevatedButton.icon(
                  onPressed: () => TeamScreen.showAddTaskDialog(context),
                  icon: Icon(Icons.add_task, size: 16),
                  label: Text('הוסף משימה'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent2),
                ),
              ],
            ),
          ),
      ]),
      SizedBox(height: 16),
      const _SectionHeader('👥', 'חברי הקבוצה'),
      SizedBox(height: 10),
      ...prov.members.map((m) => _MemberCard(member: m, prov: prov)),
      SizedBox(height: 20),
      if (prov.isAdmin) ...[
        Row(children: [
          const _SectionHeader('✓', 'צ\'קליסט לתחרות'),
          const Spacer(),
          TextButton.icon(
            onPressed: () => TeamScreen._addChecklistItem(context),
            icon: Icon(Icons.add, size: 16, color: AppColors.accent),
            label: Text('הוסף', style: TextStyle(color: AppColors.accent, fontSize: 13)),
          ),
        ]),
        SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: prov.checklist.map((c) => _ChecklistTile(item: c)).toList(),
          ),
        ),
      ],
    ]);
  }
}

// ─── My Tasks Tab ─────────────────────────────────────

class _MyTasksTab extends StatefulWidget {
  final AppProvider prov;
  const _MyTasksTab({required this.prov});

  @override
  State<_MyTasksTab> createState() => _MyTasksTabState();
}

class _MyTasksTabState extends State<_MyTasksTab> with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

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
    final prov = widget.prov;
    final myId = prov.currentUser?.id ?? '';
    final tasks = prov.memberTasks
        .where((t) => t.memberId == myId || t.memberId == 'all')
        .toList();

    final pending = tasks.where((t) => !t.done).toList();
    final done    = tasks.where((t) => t.done).toList();

    return Column(children: [
      Container(
        color: AppColors.surface,
        child: TabBar(
          controller: _tabCtrl,
          labelColor: AppColors.accent,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.accent,
          tabs: [
            Tab(text: '⏳ משימות (${pending.length})'),
            Tab(text: '✅ הושלמו (${done.length})'),
          ],
        ),
      ),
      Expanded(
        child: TabBarView(
          controller: _tabCtrl,
          children: [
            pending.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('🎉', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('אין משימות פתוחות!',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    ]),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: pending.map((t) => _MyTaskCard(task: t)).toList(),
                  ),
            done.isEmpty
                ? Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('📋', style: TextStyle(fontSize: 48)),
                      SizedBox(height: 12),
                      Text('אין משימות שהושלמו',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                    ]),
                  )
                : ListView(
                    padding: const EdgeInsets.all(16),
                    children: done.map((t) => _MyTaskCard(task: t)).toList(),
                  ),
          ],
        ),
      ),
    ]);
  }
}

class _MyTaskCard extends StatelessWidget {
  final MemberTask task;
  const _MyTaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final overdue = AppProvider.isTaskOverdue(task);
    final textColor = task.done
        ? AppColors.textTertiary
        : (overdue ? AppColors.red : AppColors.textPrimary);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: overdue && !task.done ? AppColors.red.withAlpha(100) : AppColors.border,
        ),
      ),
      child: Row(children: [
        GestureDetector(
          onTap: () => context.read<AppProvider>().toggleMemberTask(task.id),
          child: Text(task.done ? '✅' : '⬜', style: TextStyle(fontSize: 20)),
        ),
        SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(task.desc, style: TextStyle(
            fontSize: 14, color: textColor,
            decoration: task.done ? TextDecoration.lineThrough : null,
          )),
          if (task.memberId == 'all')
            Text('👥 כל הקבוצה', style: TextStyle(fontSize: 11, color: AppColors.textTertiary)),
          if (task.due != null)
            Text(
              overdue && !task.done ? '⚠️ ${task.due!} - עבר הדדליין!' : '📅 ${task.due!}',
              style: TextStyle(
                fontSize: 11,
                color: overdue && !task.done ? AppColors.red : AppColors.textTertiary,
                fontWeight: overdue && !task.done ? FontWeight.w700 : FontWeight.normal,
              ),
            ),
        ])),
      ]),
    );
  }
}

// ─── Shared widgets ────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String icon;
  final String title;
  const _SectionHeader(this.icon, this.title);
  @override
  Widget build(BuildContext context) => Row(children: [
    Text(icon, style: TextStyle(fontSize: 18)),
    SizedBox(width: 8),
    Text(title, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
  ]);
}

class _MemberCard extends StatelessWidget {
  final Member member;
  final AppProvider prov;
  const _MemberCard({required this.member, required this.prov});

  @override
  Widget build(BuildContext context) {
    final isMe = member.id == prov.currentUser?.id;
    final tasks = prov.memberTasks
        .where((t) => (t.memberId == member.id || t.memberId == 'all') && !t.done)
        .toList();
    final pending = tasks.length;

    final card = Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface2, borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            backgroundColor: member.color,
            radius: 22,
            child: Text(member.name.isNotEmpty ? member.name[0] : '?',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 16)),
          ),
          SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(member.name, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
              if (isMe) ...[
                SizedBox(width: 6),
                Container(padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.accent.withAlpha(40), borderRadius: BorderRadius.circular(10)),
                  child: Text('אני', style: TextStyle(fontSize: 10, color: AppColors.accent, fontWeight: FontWeight.w700)),
                ),
              ],
            ]),
            Text(member.isAdmin ? '👑 מנטור' : '🎓 תלמיד',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
          ])),
          if (pending > 0)
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.accent3, borderRadius: BorderRadius.circular(20)),
              child: Text('$pending משימות', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ),
          if (prov.isAdmin) ...[
            IconButton(
              icon: Icon(Icons.add_task, size: 18, color: AppColors.accent2),
              onPressed: () => TeamScreen.showAddTaskDialog(context, forMember: member),
              tooltip: 'הוסף משימה',
            ),
            if (!isMe)
              IconButton(
                icon: Text('✕', style: TextStyle(color: AppColors.red)),
                onPressed: () => _confirmRemove(context, member),
              ),
          ] else if (!member.isAdmin) ...[
            IconButton(
              icon: const Icon(Icons.add_task, size: 18, color: AppColors.accent2),
              onPressed: () => TeamScreen.showAddTaskDialog(context, forMember: member),
              tooltip: 'הוסף משימה',
            ),
          ],
        ]),
        if (tasks.isNotEmpty) ...[
          Divider(color: AppColors.border, height: 16),
          ...tasks.map((t) {
            final overdue = AppProvider.isTaskOverdue(t);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(children: [
                GestureDetector(
                  onTap: () => context.read<AppProvider>().toggleMemberTask(t.id),
                  child: Text(t.done ? '✅' : '⬜', style: TextStyle(fontSize: 16)),
                ),
                SizedBox(width: 8),
                Expanded(child: Text(t.desc,
                  style: TextStyle(fontSize: 12,
                    color: overdue ? AppColors.red : AppColors.textPrimary),
                )),
                if (t.due != null)
                  Text(
                    overdue && !t.done ? '⚠️ ${t.due!}' : t.due!,
                    style: TextStyle(fontSize: 11,
                      color: overdue && !t.done ? AppColors.red : AppColors.textTertiary,
                      fontWeight: overdue && !t.done ? FontWeight.w700 : FontWeight.normal),
                  ),
              ]),
            );
          }),
        ],
      ]),
    );

    if (isMe) return card;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DirectChatScreen(member: member)),
      ),
      child: card,
    );
  }

  static void _confirmRemove(BuildContext context, Member member) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('הסרת חבר', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('להסיר את ${member.name} מהקבוצה?', style: TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
          TextButton(
            onPressed: () {
              context.read<AppProvider>().removeMember(member.id);
              Navigator.pop(context);
            },
            child: Text('הסר', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
  }
}

class _ChecklistTile extends StatelessWidget {
  final ChecklistItem item;
  const _ChecklistTile({required this.item});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(children: [
      GestureDetector(
        onTap: () => context.read<AppProvider>().toggleChecklist(item.id),
        child: Text(item.done ? '✅' : '⬜', style: TextStyle(fontSize: 20)),
      ),
      SizedBox(width: 10),
      Expanded(child: Text(item.text,
        style: TextStyle(fontSize: 14,
          color: item.done ? AppColors.textTertiary : AppColors.textPrimary,
          decoration: item.done ? TextDecoration.lineThrough : null),
      )),
    ]),
  );
}

// ─── Dialogs ──────────────────────────────────────────

class _AddMemberDialog extends StatefulWidget {
  const _AddMemberDialog();

  @override
  State<_AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends State<_AddMemberDialog> {
  final _nameCtrl  = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _role = 'student';
  String? _error;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('➕ הוסף חבר קבוצה', style: TextStyle(color: AppColors.textPrimary)),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: _nameCtrl, style: TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(hintText: 'שם מלא')),
        SizedBox(height: 8),
        TextField(controller: _emailCtrl, style: TextStyle(color: AppColors.textPrimary),
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(hintText: 'אימייל')),
        if (_error != null) ...[
          SizedBox(height: 6),
          Text(_error!, style: TextStyle(color: AppColors.red, fontSize: 12)),
        ],
        SizedBox(height: 8),
        DropdownButton<String>(
          value: _role, isExpanded: true,
          dropdownColor: AppColors.surface2,
          style: TextStyle(color: AppColors.textPrimary),
          items: const [
            DropdownMenuItem(value: 'student', child: Text('🎓 תלמיד')),
            DropdownMenuItem(value: 'admin',   child: Text('👑 מנטור')),
          ],
          onChanged: (v) => setState(() => _role = v ?? 'student'),
        ),
      ])),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
        ElevatedButton(
          onPressed: () async {
            if (_nameCtrl.text.trim().isEmpty || _emailCtrl.text.trim().isEmpty) return;
            final prov = context.read<AppProvider>();
            final emailLower = _emailCtrl.text.trim().toLowerCase();
            if (prov.members.any((m) => m.email == emailLower)) {
              setState(() => _error = 'כבר קיים חבר עם אימייל זה');
              return;
            }
            final m = Member(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: _nameCtrl.text.trim(),
              email: emailLower,
              role: _role,
              color: AppColors.avatarColors[prov.members.length % AppColors.avatarColors.length],
            );
            await prov.addMember(m);
            if (mounted) Navigator.pop(context);
          },
          child: Text('הוסף'),
        ),
      ],
    );
  }
}

class _AddChecklistDialog extends StatefulWidget {
  const _AddChecklistDialog();

  @override
  State<_AddChecklistDialog> createState() => _AddChecklistDialogState();
}

class _AddChecklistDialogState extends State<_AddChecklistDialog> {
  final _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text('הוסף פריט', style: TextStyle(color: AppColors.textPrimary)),
      content: TextField(
        controller: _ctrl, autofocus: true,
        style: TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(hintText: 'שם פריט חדש'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('ביטול')),
        ElevatedButton(
          onPressed: () async {
            if (_ctrl.text.trim().isEmpty) return;
            await context.read<AppProvider>().addChecklistItem(_ctrl.text.trim());
            if (mounted) Navigator.pop(context);
          },
          child: Text('הוסף'),
        ),
      ],
    );
  }
}

class _AddTaskSheet extends StatefulWidget {
  final Member? forMember;
  const _AddTaskSheet({this.forMember});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _descCtrl = TextEditingController();
  DateTime? _due;
  late bool _forAll;
  Member? _selected;

  @override
  void initState() {
    super.initState();
    _forAll = widget.forMember == null;
    final prov = context.read<AppProvider>();
    final assignable = prov.isAdmin ? prov.members : prov.members.where((m) => !m.isAdmin).toList();
    _selected = widget.forMember ?? (assignable.isNotEmpty ? assignable.first : null);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.read<AppProvider>();
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('📋 הוסף משימה', style: TextStyle(
            fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        SizedBox(height: 16),
        TextField(
          controller: _descCtrl,
          autofocus: true,
          style: TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(hintText: 'תיאור המשימה'),
          maxLines: 2,
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _due ?? DateTime.now().add(const Duration(days: 7)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 365)),
              locale: const Locale('he', 'IL'),
              builder: (ctx, child) => Theme(
                data: Theme.of(ctx).copyWith(
                  colorScheme: ColorScheme.dark(
                    primary: AppColors.accent,
                    surface: AppColors.surface2,
                  ),
                ),
                child: child!,
              ),
            );
            if (picked != null) setState(() => _due = picked);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _due != null ? AppColors.accent : AppColors.border),
            ),
            child: Row(children: [
              Text('📅', style: TextStyle(fontSize: 16)),
              SizedBox(width: 10),
              Text(
                _due == null
                    ? 'בחר תאריך דדליין (אופציונלי)'
                    : '${_due!.day}/${_due!.month}/${_due!.year}',
                style: TextStyle(
                  color: _due == null ? AppColors.textTertiary : AppColors.accent,
                  fontSize: 14,
                ),
              ),
              if (_due != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => setState(() => _due = null),
                  child: Icon(Icons.close, size: 16, color: AppColors.textTertiary),
                ),
              ],
            ]),
          ),
        ),
        SizedBox(height: 12),
        GestureDetector(
          onTap: () => setState(() => _forAll = !_forAll),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: _forAll ? AppColors.accent.withAlpha(20) : AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _forAll ? AppColors.accent : AppColors.border),
            ),
            child: Row(children: [
              Text('👥', style: TextStyle(fontSize: 16)),
              SizedBox(width: 10),
              Expanded(child: Text('משימה לכל הקבוצה',
                  style: TextStyle(fontSize: 14, color: AppColors.textPrimary))),
              Switch(
                value: _forAll,
                onChanged: (v) => setState(() => _forAll = v),
                activeThumbColor: AppColors.accent,
              ),
            ]),
          ),
        ),
        if (!_forAll && prov.members.isNotEmpty) ...[
          SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface2,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButton<Member>(
              value: _selected,
              isExpanded: true,
              dropdownColor: AppColors.surface2,
              underline: SizedBox.shrink(),
              style: TextStyle(color: AppColors.textPrimary, fontSize: 14),
              items: (prov.isAdmin ? prov.members : prov.members.where((m) => !m.isAdmin).toList()).map((m) => DropdownMenuItem(
                value: m,
                child: Row(children: [
                  CircleAvatar(backgroundColor: m.color, radius: 12,
                      child: Text(m.name.isNotEmpty ? m.name[0] : '?',
                          style: TextStyle(color: Colors.white, fontSize: 10))),
                  SizedBox(width: 8),
                  Text(m.name),
                ]),
              )).toList(),
              onChanged: (m) => setState(() => _selected = m),
            ),
          ),
        ],
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () async {
              if (_descCtrl.text.trim().isEmpty) return;
              final assignId   = _forAll ? 'all' : (_selected?.id ?? 'all');
              final assignName = _forAll ? 'כל הקבוצה' : (_selected?.name ?? '');
              final dueStr = _due == null ? null : '${_due!.day}/${_due!.month}/${_due!.year}';
              await prov.addMemberTask(MemberTask(
                id: DateTime.now().millisecondsSinceEpoch,
                memberId: assignId,
                memberName: assignName,
                desc: _descCtrl.text.trim(),
                due: dueStr,
              ));
              if (mounted) Navigator.pop(context);
            },
            child: Text('✓ הוסף משימה'),
          ),
        ),
      ]),
    );
  }
}
