import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ui/common/widgets/loaders/hexagonal_ripple_loader.dart';

void main() {
  testWidgets('HexagonalRippleLoader renders and has correct semantics', (WidgetTester tester) async {
    // Build the widget
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: HexagonalRippleLoader(),
        ),
      ),
    );

    // Let the animation run for a frame
    await tester.pump(); 

    // Verify the loader is present
    expect(find.byType(HexagonalRippleLoader), findsOneWidget);

    // Verify the CustomPaint is used (core of the visual)
    expect(find.byType(CustomPaint), findsOneWidget);

    // Verify the accessibility label
    expect(find.bySemanticsLabel('Loading feed'), findsOneWidget);
  });

  // Golden test to capture visual appearance
  testWidgets('HexagonalRippleLoader golden test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          // Ensure a consistent size for the golden file
          body: Center(
            child: SizedBox(
              width: 200,
              height: 200,
              child: HexagonalRippleLoader(),
            ),
          ),
        ),
      ),
    );

    // Pump a few frames to let the animation progress slightly
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 100));

    await expectLater(
      find.byType(HexagonalRippleLoader),
      matchesGoldenFile('goldens/hexagonal_ripple_loader.png'),
    );
  });
} 