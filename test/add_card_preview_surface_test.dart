import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/widgets/add_card_preview_surface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('uses the Hungry Spot logo yellow for the card preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: AddCardPreviewSurface(child: SizedBox.expand())),
      ),
    );

    final decoratedBox = tester.widget<DecoratedBox>(
      find.descendant(
        of: find.byType(AddCardPreviewSurface),
        matching: find.byType(DecoratedBox),
      ),
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    final border = decoration.border as Border;

    expect(decoration.color, const Color(0xFFFDCD04));
    expect(border.top.color, const Color(0xFFFDCD04));
  });

  testWidgets('provides dark text and icon colors for card content', (
    tester,
  ) async {
    Color? textColor;
    Color? iconColor;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: AddCardPreviewSurface(
            child: Builder(
              builder: (context) {
                textColor = DefaultTextStyle.of(context).style.color;
                iconColor = IconTheme.of(context).color;
                return const SizedBox.expand();
              },
            ),
          ),
        ),
      ),
    );

    expect(textColor, const Color(0xFF171315));
    expect(iconColor, const Color(0xFF171315));
  });
}
