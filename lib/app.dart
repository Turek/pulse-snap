import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/calendar/calendar_screen.dart';
import 'features/camera/camera_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/detail/reading_detail_screen.dart';
import 'features/history/history_screen.dart';
import 'features/review/review_screen.dart';
import 'features/settings/settings_screen.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) =>
          _AppShell(location: state.matchedLocation, child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: DashboardScreen()),
        ),
        GoRoute(
          path: '/history',
          name: 'history',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HistoryScreen()),
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: CalendarScreen()),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SettingsScreen()),
        ),
      ],
    ),
    GoRoute(
      path: '/scan',
      name: 'scan',
      builder: (context, state) => const CameraScreen(),
      routes: [
        GoRoute(
          path: 'review',
          name: 'review',
          builder: (context, state) => ReviewScreen(
            imageFile: state.extra is File ? state.extra as File : null,
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/history/:id',
      name: 'reading-detail',
      builder: (context, state) => ReadingDetailScreen(
        readingId: int.parse(state.pathParameters['id']!),
      ),
    ),
  ],
);

class PulseSnapApp extends ConsumerWidget {
  const PulseSnapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DynamicColorBuilder(
      builder: (light, dark) {
        return MaterialApp.router(
          title: 'PulseSnap',
          theme: buildTheme(light, Brightness.light),
          darkTheme: buildTheme(dark, Brightness.dark),
          routerConfig: _router,
        );
      },
    );
  }
}

/// Wraps shell-routed tabs with a Material 3 NavigationBar at the bottom.
/// Each tab owns its own AppBar so each can carry its own actions/leading.
class _AppShell extends StatelessWidget {
  final String location;
  final Widget child;
  const _AppShell({required this.location, required this.child});

  static const _destinations = [
    (icon: Icons.dashboard_outlined, selectedIcon: Icons.dashboard, label: 'Home', route: '/'),
    (icon: Icons.list_alt_outlined, selectedIcon: Icons.list_alt, label: 'History', route: '/history'),
    (icon: Icons.calendar_today_outlined, selectedIcon: Icons.calendar_today, label: 'Calendar', route: '/calendar'),
    (icon: Icons.settings_outlined, selectedIcon: Icons.settings, label: 'Settings', route: '/settings'),
  ];

  int get _currentIndex {
    for (var i = 0; i < _destinations.length; i++) {
      if (_destinations[i].route == location) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => context.go(_destinations[i].route),
        destinations: [
          for (final d in _destinations)
            NavigationDestination(
              icon: Icon(d.icon),
              selectedIcon: Icon(d.selectedIcon),
              label: d.label,
            ),
        ],
      ),
    );
  }
}
