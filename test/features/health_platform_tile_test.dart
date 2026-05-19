import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/data/database/app_database.dart';
import 'package:pulse_snap/domain/health_platform/health_platform_service.dart';
import 'package:pulse_snap/domain/tags/reading_with_tags.dart';
import 'package:pulse_snap/features/settings/widgets/health_platform_tile.dart';
import 'package:pulse_snap/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeHealth implements IHealthPlatformService {
  bool granted = true;
  bool available = true;
  @override
  Future<bool> isAvailable() async => available;
  @override
  Future<bool> requestWritePermissions() async => granted;
  @override
  Future<bool> hasWritePermissions() async => granted;
  @override
  Future<String?> writeReading(ReadingWithTags reading) async => 'x';
  @override
  Future<void> disconnect() async {}
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('toggle switch flips subtitle to Connected on grant',
      (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final health = _FakeHealth();
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          healthPlatformServiceProvider.overrideWithValue(health),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HealthPlatformTile()),
        ),
      ),
    );

    // Allow AsyncNotifier.build() to settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Not connected'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.textContaining('Connected'), findsOneWidget);
  });

  testWidgets('denied permission keeps state disconnected', (tester) async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final health = _FakeHealth()..granted = false;
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWithValue(db),
          healthPlatformServiceProvider.overrideWithValue(health),
        ],
        child: const MaterialApp(
          home: Scaffold(body: HealthPlatformTile()),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byType(Switch));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Not connected'), findsOneWidget);
  });
}
