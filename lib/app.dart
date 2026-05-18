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
import 'features/settings/settings_provider.dart';
import 'features/settings/settings_screen.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

const _shellRoutes = ['/', '/history', '/calendar', '/settings'];

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) =>
          _AppShell(location: state.matchedLocation),
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SizedBox()),
        ),
        GoRoute(
          path: '/history',
          name: 'history',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SizedBox()),
        ),
        GoRoute(
          path: '/calendar',
          name: 'calendar',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SizedBox()),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: SizedBox()),
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

/// The shell ignores ShellRoute's `child` and instead drives all four tabs
/// itself via a PageView, so the user can swipe horizontally between them
/// AND tap a NavigationBar destination. Route, PageController, and
/// NavigationBar.selectedIndex stay in sync via [_currentIndex].
class _AppShell extends ConsumerStatefulWidget {
  final String location;
  const _AppShell({required this.location});

  @override
  ConsumerState<_AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<_AppShell> {
  late final PageController _ctrl;

  int get _currentIndex {
    final i = _shellRoutes.indexOf(widget.location);
    return i < 0 ? 0 : i;
  }

  @override
  void initState() {
    super.initState();
    _ctrl = PageController(initialPage: _currentIndex);
  }

  @override
  void didUpdateWidget(_AppShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.location != widget.location && _ctrl.hasClients) {
      final target = _currentIndex;
      if ((_ctrl.page ?? 0).round() != target) {
        _ctrl.animateToPage(
          target,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutCubic,
        );
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyAsync = ref.watch(geminiApiKeyProvider);
    final missingKey =
        keyAsync.maybeWhen(data: (k) => k.isEmpty, orElse: () => false);

    return Scaffold(
      body: PageView(
        controller: _ctrl,
        onPageChanged: (i) {
          if (i == _currentIndex) return;
          context.go(_shellRoutes[i]);
        },
        children: const [
          DashboardScreen(),
          HistoryScreen(),
          CalendarScreen(),
          SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => context.go(_shellRoutes[i]),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: 'History',
          ),
          const NavigationDestination(
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'Calendar',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: missingKey,
              smallSize: 8,
              backgroundColor: Theme.of(context).colorScheme.error,
              child: const Icon(Icons.settings_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: missingKey,
              smallSize: 8,
              backgroundColor: Theme.of(context).colorScheme.error,
              child: const Icon(Icons.settings),
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
