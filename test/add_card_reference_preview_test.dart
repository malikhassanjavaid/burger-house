import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/widgets/add_card_preview.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('matches the selected reference artwork and default content', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 550,
              child: AddCardPreview(
                name: '',
                last4: null,
                expiryMonth: null,
                expiryYear: null,
              ),
            ),
          ),
        ),
      ),
    );

    final artwork = tester.widget<Image>(
      find.byKey(const ValueKey('add-card-reference-artwork')),
    );
    final image = artwork.image as AssetImage;
    final aspectRatio = tester.widget<AspectRatio>(
      find.descendant(
        of: find.byType(AddCardPreview),
        matching: find.byType(AspectRatio),
      ),
    );

    expect(image.assetName, 'assets/images/add_card_reference_background.webp');
    expect(aspectRatio.aspectRatio, closeTo(550 / 333, 0.0001));
    expect(find.text('Alena Syabian'), findsOneWidget);
    expect(find.text('4241 9214 7219 3456'), findsOneWidget);
    expect(find.text('12/24'), findsOneWidget);
  });

  testWidgets('keeps cardholder, last four and expiry preview values live', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 550,
              child: AddCardPreview(
                name: 'Hassan',
                last4: '4242',
                expiryMonth: 10,
                expiryYear: 2030,
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Hassan'), findsOneWidget);
    expect(find.text('•••• •••• •••• 4242'), findsOneWidget);
    expect(find.text('10/30'), findsOneWidget);
  });

  testWidgets('switches demo values to safe placeholders when entry begins', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AddCardPreview(
            name: 'Hassan',
            last4: null,
            expiryMonth: null,
            expiryYear: null,
            hasCardInput: true,
          ),
        ),
      ),
    );

    expect(find.text('Hassan'), findsOneWidget);
    expect(find.text('•••• •••• •••• ••••'), findsOneWidget);
    expect(find.text('MM/YY'), findsOneWidget);
    expect(find.text('4241 9214 7219 3456'), findsNothing);
  });

  testWidgets('uses the reference ink color for every dynamic value', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: AddCardPreview(
            name: '',
            last4: null,
            expiryMonth: null,
            expiryYear: null,
          ),
        ),
      ),
    );

    for (final key in const ['name', 'number', 'expiry']) {
      final text = tester.widget<Text>(
        find.byKey(ValueKey('add-card-preview-$key')),
      );
      expect(text.style?.color, const Color(0xFF0C2729));
    }
  });
}
