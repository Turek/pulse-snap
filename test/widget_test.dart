import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:pulse_snap/app.dart';

void main() {
  testWidgets('App boots to dashboard', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: PulseSnapApp()));
    await tester.pump();
    expect(find.text('PulseSnap'), findsOneWidget);
  });
}
