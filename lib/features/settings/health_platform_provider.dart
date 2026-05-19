import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../data/database/app_database.dart';
import '../../domain/health_platform/health_platform_service.dart';
import '../../providers.dart';

class HealthPlatformState {
  final bool available;
  final bool connected;
  final DateTime? lastSyncAt;
  final bool pendingPermission;

  const HealthPlatformState({
    required this.available,
    required this.connected,
    required this.lastSyncAt,
    required this.pendingPermission,
  });

  HealthPlatformState copyWith({
    bool? available,
    bool? connected,
    DateTime? lastSyncAt,
    bool clearLastSyncAt = false,
    bool? pendingPermission,
  }) {
    return HealthPlatformState(
      available: available ?? this.available,
      connected: connected ?? this.connected,
      lastSyncAt:
          clearLastSyncAt ? null : (lastSyncAt ?? this.lastSyncAt),
      pendingPermission: pendingPermission ?? this.pendingPermission,
    );
  }

  static const initial = HealthPlatformState(
    available: false,
    connected: false,
    lastSyncAt: null,
    pendingPermission: false,
  );
}

class HealthPlatformNotifier extends AsyncNotifier<HealthPlatformState> {
  static const _enabledKey = 'health_platform_enabled';

  IHealthPlatformService get _svc => ref.read(healthPlatformServiceProvider);
  AppDatabase get _db => ref.read(appDatabaseProvider);

  @override
  Future<HealthPlatformState> build() async {
    final prefs = await SharedPreferences.getInstance();
    final enabled = prefs.getBool(_enabledKey) ?? false;
    final available = await _svc.isAvailable();
    bool connected = false;
    if (enabled && available) {
      connected = await _svc.hasWritePermissions();
    }
    final lastSync = await _lastSyncFromDb();
    return HealthPlatformState(
      available: available,
      connected: connected,
      lastSyncAt: lastSync,
      pendingPermission: false,
    );
  }

  Future<DateTime?> _lastSyncFromDb() async {
    final rows = await (_db.select(_db.externalSyncRecords)
          ..orderBy([(t) => OrderingTerm.desc(t.syncedAt)])
          ..limit(1))
        .get();
    if (rows.isEmpty) return null;
    return rows.first.syncedAt;
  }

  Future<bool> enable() async {
    final current = state.value ?? HealthPlatformState.initial;
    state = AsyncValue.data(current.copyWith(pendingPermission: true));
    try {
      final granted = await _svc.requestWritePermissions();
      if (!granted) {
        state = AsyncValue.data(current.copyWith(pendingPermission: false));
        return false;
      }
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_enabledKey, true);
      state = AsyncValue.data(current.copyWith(
        connected: true,
        pendingPermission: false,
      ));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<void> disconnect() async {
    final current = state.value ?? HealthPlatformState.initial;
    try {
      await _svc.disconnect();
    } catch (_) {
      // best-effort
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_enabledKey);
    await _db.delete(_db.externalSyncRecords).go();
    state = AsyncValue.data(current.copyWith(
      connected: false,
      clearLastSyncAt: true,
      pendingPermission: false,
    ));
  }

  Future<void> refreshLastSync() async {
    final current = state.value;
    if (current == null) return;
    final lastSync = await _lastSyncFromDb();
    state = AsyncValue.data(current.copyWith(lastSyncAt: lastSync));
  }
}

final healthPlatformProvider =
    AsyncNotifierProvider<HealthPlatformNotifier, HealthPlatformState>(
        HealthPlatformNotifier.new);
