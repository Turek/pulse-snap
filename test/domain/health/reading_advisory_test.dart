import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/domain/health/blood_pressure_status.dart';
import 'package:pulse_snap/domain/health/heart_rate_status.dart';
import 'package:pulse_snap/domain/health/reading_advisory.dart';

void main() {
  group('computeAdvisory', () {
    test('crisis BP sets banner message', () {
      final a = computeAdvisory(
        bp: BloodPressureStatus.crisis,
        hr: null,
        tags: const <String>{},
      );
      expect(a.bannerMessage, isNotNull);
      expect(a.bannerMessage, contains('medical advice'));
    });

    test('low BP with dizziness tag escalates subtitle', () {
      final a = computeAdvisory(
        bp: BloodPressureStatus.low,
        hr: null,
        tags: const <String>{'Dizziness'},
      );
      expect(a.bpSubtitle, isNotNull);
      expect(a.bpSubtitle, contains('consider seeking medical advice'));
    });

    test('low BP with headache tag escalates subtitle', () {
      final a = computeAdvisory(
        bp: BloodPressureStatus.low,
        hr: null,
        tags: const <String>{'headache'},
      );
      expect(a.bpSubtitle, contains('consider seeking medical advice'));
    });

    test('low BP without symptoms is informative only', () {
      final a = computeAdvisory(
        bp: BloodPressureStatus.low,
        hr: null,
        tags: const <String>{'morning'},
      );
      expect(a.bpSubtitle, isNotNull);
      expect(a.bpSubtitle, contains('Below the typical range'));
      expect(a.bpSubtitle, isNot(contains('seeking medical advice')));
    });

    test('elevated HR with after-exercise tag references activity', () {
      final a = computeAdvisory(
        bp: null,
        hr: HeartRateStatus.high,
        tags: const <String>{'after exercise'},
      );
      expect(a.hrSubtitle, isNotNull);
      expect(a.hrSubtitle, contains('recent activity'));
    });

    test('elevated HR without exercise tag is the standard subtitle', () {
      final a = computeAdvisory(
        bp: null,
        hr: HeartRateStatus.mildlyHigh,
        tags: const <String>{},
      );
      expect(a.hrSubtitle, isNotNull);
      expect(a.hrSubtitle, contains('above the normal range'));
    });

    test('normal values yield no copy', () {
      final a = computeAdvisory(
        bp: BloodPressureStatus.normal,
        hr: HeartRateStatus.normal,
        tags: const <String>{},
      );
      expect(a.bannerMessage, isNull);
      expect(a.bpSubtitle, isNull);
      expect(a.hrSubtitle, isNull);
    });
  });
}
