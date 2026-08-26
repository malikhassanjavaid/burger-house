import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/home/data/sample_menu.dart';
import 'package:flutter_application_1/features/home/models/cart_item.dart';
import 'package:flutter_application_1/features/home/models/menu_item.dart';
import 'package:flutter_application_1/features/home/screens/menu_details_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('patty choices are limited to the three beef burger IDs', (
    tester,
  ) async {
    const pattyChoiceIds = {'classic-smash', 'firehouse', 'cheese-burger'};
    final burgers = sampleMenu.where((item) => item.category == 'Burgers');

    for (final burger in burgers) {
      await _pumpDetails(tester, burger, onAddToCart: (_) {});
      await _revealCustomization(tester);

      expect(
        find.text('Choose Patty'),
        pattyChoiceIds.contains(burger.id) ? findsOneWidget : findsNothing,
        reason: 'Unexpected patty selector state for ${burger.id}',
      );
    }
  });

  testWidgets('a fixed burger is added at base price without a patty size', (
    tester,
  ) async {
    final chickenBurger = sampleMenu.firstWhere(
      (item) => item.id == 'chicken-burger',
    );
    CartItem? addedItem;

    await _pumpDetails(
      tester,
      chickenBurger,
      onAddToCart: (item) => addedItem = item,
    );
    await tester.tap(find.text('ADD TO CART'));
    await tester.pumpAndSettle();

    expect(addedItem?.size, 'Regular');
    expect(addedItem?.unitPrice, chickenBurger.price);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpDetails(
  WidgetTester tester,
  MenuItem item, {
  required ValueChanged<CartItem> onAddToCart,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey('burger-details-${item.id}'),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: const TextScaler.linear(0.8)),
        child: child!,
      ),
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: FilledButton(
              onPressed: () => Navigator.push<void>(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      MenuDetailsScreen(item: item, onAddToCart: onAddToCart),
                ),
              ),
              child: const Text('Open burger'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open burger'));
  await tester.pumpAndSettle();
}

Future<void> _revealCustomization(WidgetTester tester) async {
  await tester.drag(find.byType(CustomScrollView), const Offset(0, -500));
  await tester.pumpAndSettle();
}
