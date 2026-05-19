import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_snap/core/widgets/status_pill.dart';

void main() {
  testWidgets('StatusPill renders label and color dot', (tester) async {
    const color = Color(0xFFEB5757);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: StatusPill(label: 'High Stage 2', color: color),
        ),
      ),
    ));

    expect(find.text('High Stage 2'), findsOneWidget);

    // At least one descendant Container should be tinted with the accent
    // color (the leading dot uses it directly).
    final dotFinder = find.byWidgetPredicate((w) {
      if (w is! Container) return false;
      final decoration = w.decoration;
      if (decoration is! BoxDecoration) return false;
      return decoration.color == color && decoration.shape == BoxShape.circle;
    });
    expect(dotFinder, findsOneWidget);
  });

  testWidgets('StatusPill honours explicit backgroundColor', (tester) async {
    const bg = Color(0xFFFDECEC);
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: StatusPill(
            label: 'Crisis',
            color: Color(0xFF8B1E3F),
            backgroundColor: bg,
          ),
        ),
      ),
    ));

    final bgFinder = find.byWidgetPredicate((w) {
      if (w is! Container) return false;
      final decoration = w.decoration;
      if (decoration is! BoxDecoration) return false;
      return decoration.color == bg;
    });
    expect(bgFinder, findsWidgets);
  });
}
