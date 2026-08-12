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

  // Daily
  static final dailyFilterBar = GlobalKey();
  static final dailyTimeline = GlobalKey();

  // Robot
  static final robotProgressHeader = GlobalKey();
  static final robotMissionsGrid = GlobalKey();
  static final robotGallerySection = GlobalKey();

  // Scoring
  static final scoringTabBar = GlobalKey();
  static final scoringRobotTimer = GlobalKey();
  static final scoringMissions = GlobalKey();
  static final scoringJudgeTimer = GlobalKey();
  static final scoringRubrics = GlobalKey();

  // Values
  static final valuesTabBar = GlobalKey();
  static final valuesStickiesTab = GlobalKey();
  static final valuesBoardTab = GlobalKey();

  // Innovation
  static final innovationTabBar = GlobalKey();
  static final innovationProjectTab = GlobalKey();
  static final innovationResearchTab = GlobalKey();
  static final innovationInterviewsTab = GlobalKey();
  static final innovationIdeasTab = GlobalKey();

  // Chat
  static final chatChannelTabs = GlobalKey();
  static final chatInputBar = GlobalKey();
  static final chatAnnounceBtn = GlobalKey();
  static final chatPollBtn = GlobalKey();

  // Team
  static final teamTabBar = GlobalKey();
  static final teamAddButtons = GlobalKey();
  static final teamMembersList = GlobalKey();
  static final teamChecklist = GlobalKey();

  // My Tasks
  static final myTasksStatsBar = GlobalKey();
  static final myTasksTabBar = GlobalKey();

  // Archive
  static final archiveCurrentSeasonCard = GlobalKey();
  static final archivesList = GlobalKey();

  // Gallery
  static final galleryHeaderBar = GlobalKey();

  // Judging
  static final judgingTabBar = GlobalKey();
  static final judgingProgressHeader = GlobalKey();
  static final judgingQuestionsList = GlobalKey();

  // Links
  static final linksTabBar = GlobalKey();

  // Strategy board
  static final strategyBoardsGrid = GlobalKey();
}
