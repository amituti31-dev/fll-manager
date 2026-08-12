import 'package:flutter/material.dart';

/// Stable GlobalKeys the guided tour spotlights. Kept in one place (rather
/// than created inline in each screen's build method) so the same key
/// instance survives rebuilds — GlobalKeys must be stable to be usable.
class TourKeys {
  // Shell / navigation
  static final menuButton = GlobalKey();
  static final addButton = GlobalKey();
  static final drawerNavItems = List.generate(15, (_) => GlobalKey());
  static final drawerFooter = GlobalKey();

  // Dashboard
  static final dashboardStats = GlobalKey();
  static final dashboardCategoryProgress = GlobalKey();
  static final dashboardRecentUpdates = GlobalKey();
  static final dashboardQuickActions = GlobalKey();

  // Settings
  static final settingsThemeSwitch = GlobalKey();
  static final settingsHelpButton = GlobalKey();
}
