import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/home/screens/cart_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty cart matches the Hungry Spot empty-state flow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CartScreen(
          items: const [],
          deliveryAddress: 'Test address',
          onCartChanged: (_) {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Your Cart is Empty'), findsOneWidget);
    expect(find.text('Please add some items from the menu.'), findsOneWidget);
    expect(find.text('Explore Menu'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('empty-cart-illustration')),
      findsOneWidget,
    );
    expect(find.text('Complete Your Meal'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
