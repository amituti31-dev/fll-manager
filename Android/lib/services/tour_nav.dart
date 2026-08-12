import 'package:flutter/material.dart';

/// Bridge so the tour (a plain service, not a widget) can drive
/// ShellScreen's navigation — its selected-tab index and drawer are
/// private State, so ShellScreen registers callbacks here on init.
class TourNav {
  static void Function(int)? _jumpToIndex;
  static VoidCallback? _openDrawer;
  static VoidCallback? _closeDrawer;

  static void register({
    required void Function(int) jumpToIndex,
    required VoidCallback openDrawer,
    required VoidCallback closeDrawer,
  }) {
    _jumpToIndex = jumpToIndex;
    _openDrawer = openDrawer;
    _closeDrawer = closeDrawer;
  }

  static void jumpToIndex(int i) => _jumpToIndex?.call(i);
  static void openDrawer() => _openDrawer?.call();
  static void closeDrawer() => _closeDrawer?.call();

  // Generic bridge for screens with their own internal TabController
  // (values, innovation, scoring, …) — each registers itself under a
  // unique id in its initState so the tour can flip its tab.
  static final Map<String, void Function(int)> _tabSwitchers = {};

  static void registerTabs(String id, void Function(int) switchTab) {
    _tabSwitchers[id] = switchTab;
  }

  static void unregisterTabs(String id) => _tabSwitchers.remove(id);

  static void switchTab(String id, int index) => _tabSwitchers[id]?.call(index);
}
