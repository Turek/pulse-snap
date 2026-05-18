import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/core/utils/bp_category.dart';

void main() {
  group('bpCategory', () {
    test('null inputs → unknown', () {
      expect(bpCategory(null, null), BpCategory.unknown);
      expect(bpCategory(120, null), BpCategory.unknown);
      expect(bpCategory(null, 80), BpCategory.unknown);
    });

    test('normal: <120/<80', () {
      expect(bpCategory(119, 79), BpCategory.normal);
      expect(bpCategory(100, 60), BpCategory.normal);
    });

    test('elevated: 120-129 and <80', () {
      expect(bpCategory(120, 79), BpCategory.elevated);
      expect(bpCategory(129, 79), BpCategory.elevated);
    });

    test('stage1: 130-139 or 80-89', () {
      expect(bpCategory(130, 79), BpCategory.stage1);
      expect(bpCategory(119, 80), BpCategory.stage1);
      expect(bpCategory(139, 89), BpCategory.stage1);
    });

    test('stage2: 140+ or 90+', () {
      expect(bpCategory(140, 89), BpCategory.stage2);
      expect(bpCategory(120, 90), BpCategory.stage2);
      expect(bpCategory(180, 120), BpCategory.stage2);
    });

    test('crisis: >180 or >120', () {
      expect(bpCategory(181, 80), BpCategory.crisis);
      expect(bpCategory(120, 121), BpCategory.crisis);
      expect(bpCategory(200, 130), BpCategory.crisis);
    });
  });
}
