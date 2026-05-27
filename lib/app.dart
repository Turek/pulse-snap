import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'features/camera/camera_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/detail/reading_detail_screen.dart';
import 'features/export/export_screen.dart';
import 'features/history/history_screen.dart';
import 'features/review/review_screen.dart';
import 'features/settings/settings_provider.dart';
import 'features/settings/settings_screen.dart';

final _shellNavigatorKey = GlobalKey<NavigatorState>();

const _shellRoutes = ['/', '/history', '/settings'];

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
    GoRoute(
      path: '/export',
      name: 'export',
      builder: (context, state) => const ExportScreen(),
    ),
  ],
);

class PulseSnapApp extends ConsumerWidget {
  const PulseSnapApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'PulseSnap',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(null, Brightness.light),
      darkTheme: buildTheme(null, Brightness.dark),
      routerConfig: _router,
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
  DateTime? _lastBackPress;

  int get _currentIndex {
    final i = _shellRoutes.indexOf(widget.location);
    return i < 0 ? 0 : i;
  }

  Future<void> _handleBack(BuildContext context) async {
    if (_currentIndex != 0) {
      context.go('/');
      return;
    }
    final now = DateTime.now();
    final last = _lastBackPress;
    if (last != null && now.difference(last) <= const Duration(seconds: 2)) {
      await SystemNavigator.pop();
      return;
    }
    _lastBackPress = now;
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleBack(context);
      },
      child: Scaffold(
      body: PageView(
        controller: _ctrl,
        onPageChanged: (i) {
          if (i == _currentIndex) return;
          context.go(_shellRoutes[i]);
        },
        children: const [
          DashboardScreen(),
          HistoryScreen(),
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
            icon: Icon(Icons.calendar_today_outlined),
            selectedIcon: Icon(Icons.calendar_today),
            label: 'History',
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
    ),
    );
  }
}
