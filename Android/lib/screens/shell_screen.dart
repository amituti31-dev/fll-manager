import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_provider.dart';
import '../theme/app_theme.dart';
import 'dashboard/dashboard_screen.dart';
import 'daily/daily_screen.dart';
import 'robot/robot_screen.dart';
import 'scoring/scoring_screen.dart';
import 'team/team_screen.dart';
import 'values/values_screen.dart';
import 'innovation/innovation_screen.dart';
import 'chat/chat_screen.dart';
import 'settings/settings_screen.dart';
import 'archive/archive_screen.dart';
import 'gallery/gallery_screen.dart';
import 'judging/judging_screen.dart';
import 'tasks/my_tasks_screen.dart';
import 'links/links_screen.dart';
import 'strategy/strategy_board_screen.dart';

class ShellScreen extends StatefulWidget {
  const ShellScreen({super.key});

  @override
  State<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends State<ShellScreen> {
  int _selectedIndex = 0;
  bool _overdueChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_overdueChecked) {
      final prov = Provider.of<AppProvider>(context, listen: false);
      if (prov.status == AppStatus.ready) {
        _overdueChecked = true;
        final count = prov.overdueCountForMe;
        if (count > 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('⚠️ יש לך $count משימ${count == 1 ? 'ה' : 'ות'} שעבר הדדליין!'),
                backgroundColor: AppColors.red,
                duration: const Duration(seconds: 5),
                action: SnackBarAction(
                  label: 'הצג',
                  textColor: Colors.white,
                  onPressed: () => setState(() => _selectedIndex = 8),
                ),
              ));
            }
          });
        }
      }
    }
  }

  static const _navItems = [
    _NavItem('🏠', 'לוח בקרה'),
    _NavItem('📝', 'יומן יומי'),
    _NavItem('🤖', 'תכנון רובוט'),
    _NavItem('🎯', 'ניקוד ותחרויות'),
    _NavItem('⭐', 'ערכי FLL'),
    _NavItem('💡', 'חדשנות'),
    _NavItem('💬', 'צ\'אט קבוצתי'),
    _NavItem('👥', 'ניהול קבוצה'),
    _NavItem('📋', 'המשימות שלי'),
    _NavItem('📦', 'ארכיון עונות'),
    _NavItem('🖼️', 'גלריית עונה'),
    _NavItem('🎓', 'שאלות שיפוט'),
    _NavItem('🔗', 'ספריית קישורים'),
    _NavItem('🗺️', 'לוח אסטרטגיה'),
    _NavItem('⚙️', 'הגדרות'),
  ];

  Widget _buildScreen(int index) {
    return switch (index) {
      0 => DashboardScreen(navigateTo: (i) => setState(() => _selectedIndex = i)),
      1 => const DailyScreen(),
      2 => RobotScreen(navigateTo: (i) => setState(() => _selectedIndex = i)),
      3 => const ScoringScreen(),
      4 => const ValuesScreen(),
      5 => const InnovationScreen(),
      6 => const ChatScreen(),
      7 => const TeamScreen(),
      8 => const MyTasksScreen(),
      9 => const ArchiveScreen(),
      10 => const GalleryScreen(),
      11 => const JudgingScreen(),
      12 => const LinksScreen(),
      13 => const StrategyBoardScreen(),
      14 => const SettingsScreen(),
      _ => DashboardScreen(navigateTo: (i) => setState(() => _selectedIndex = i)),
    };
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AppProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text(_navItems[_selectedIndex].label),
        actions: [
          IconButton(
            icon: Text('➕', style: TextStyle(fontSize: 20)),
            onPressed: () => _onAddTap(context),
          ),
        ],
      ),
      drawer: _buildDrawer(prov),
      body: IndexedStack(
        index: _selectedIndex,
        children: List.generate(_navItems.length, _buildScreen),
      ),
    );
  }

  Widget _buildDrawer(AppProvider prov) {
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: AppColors.accent,
                radius: 22,
                child: Text('🤖', style: TextStyle(fontSize: 20)),
              ),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(prov.teamName,
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppColors.textPrimary)),
                Text('Unearthed 2026',
                    style: TextStyle(fontSize: 11, color: AppColors.accent3)),
              ])),
            ]),
          ),
          // Nav items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final selected = _selectedIndex == i;
                return ListTile(
                  leading: Text(_navItems[i].icon, style: TextStyle(fontSize: 20)),
                  title: Text(_navItems[i].label,
                      style: TextStyle(
                        color: selected ? AppColors.accent : AppColors.textSecondary,
                        fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 14,
                      )),
                  tileColor: selected ? AppColors.accent.withAlpha(25) : Colors.transparent,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  onTap: () {
                    setState(() => _selectedIndex = i);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          // Footer: user + sign out
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              CircleAvatar(
                backgroundColor: prov.currentUser?.color ?? AppColors.accent,
                radius: 16,
                child: Text(
                  (prov.currentUser?.name.isNotEmpty == true)
                      ? prov.currentUser!.name[0]
                      : '?',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(prov.currentUser?.name ?? '',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                Text(prov.isAdmin ? 'מנטור 👑' : 'תלמיד 🎓',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              ])),
              IconButton(
                icon: Text('🚪', style: TextStyle(fontSize: 18)),
                onPressed: () async {
                  Navigator.pop(context);
                  await context.read<AppProvider>().signOut();
                },
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  void _onAddTap(BuildContext context) {
    switch (_selectedIndex) {
      case 1:
        DailyScreen.showAddDialog(context);
      case 2:
        RobotScreen.showAddDialog(context);
      case 7:
        TeamScreen.showAddTaskDialog(context);
      case 12:
        LinksScreen.showAddDialog(context);
      case 13:
        StrategyBoardScreen.showAddDialog(context);
      default:
        DailyScreen.showAddDialog(context);
    }
  }

}

class _NavItem {
  final String icon;
  final String label;
  const _NavItem(this.icon, this.label);
}
