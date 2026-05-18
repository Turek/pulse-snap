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

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'dashboard',
      builder: (context, state) => Scaffold(
        appBar: AppBar(title: const Text('PulseSnap')),
        drawer: const _DebugDrawer(),
        body: const DashboardScreen(),
      ),
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
      path: '/history',
      name: 'history',
      builder: (context, state) => const HistoryScreen(),
      routes: [
        GoRoute(
          path: ':id',
          name: 'reading-detail',
          builder: (context, state) => ReadingDetailScreen(
            readingId: int.parse(state.pathParameters['id']!),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/calendar',
      name: 'calendar',
      builder: (context, state) => const CalendarScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
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

class _DebugDrawer extends StatelessWidget {
  const _DebugDrawer();

  @override
  Widget build(BuildContext context) {
    Widget tile(String label, String route) => ListTile(
          title: Text(label),
          onTap: () {
            Navigator.of(context).pop();
            context.go(route);
          },
        );
    return Drawer(
      child: SafeArea(
        child: ListView(
          children: [
            const DrawerHeader(child: Text('PulseSnap')),
            tile('Dashboard', '/'),
            tile('Scan', '/scan'),
            tile('History', '/history'),
            tile('Calendar', '/calendar'),
            tile('Settings', '/settings'),
          ],
        ),
      ),
    );
  }
}
