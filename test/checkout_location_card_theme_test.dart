import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/home/models/cart_item.dart';
import 'package:flutter_application_1/features/home/models/menu_item.dart';
import 'package:flutter_application_1/features/home/screens/checkout_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(Firebase.initializeApp);

  testWidgets('checkout Home location card uses the brand red accents', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    const menuItem = MenuItem(
      id: 'test-item',
      name: 'Test Burger',
      description: 'Test checkout item',
      category: 'Burgers',
      emoji: '',
      assetPath: 'assets/images/beefburger.webp',
      price: 9.99,
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CheckoutScreen(
          items: const [
            CartItem(menuItem: menuItem, quantity: 1, unitPrice: 9.99),
          ],
          initialAddress: 'Test address',
          deliveryFee: 2,
          onOrderPlaced: () {},
        ),
      ),
    );
    await tester.pump();

    final locationCard = find.byKey(
      const ValueKey('checkout-delivery-location'),
    );
    expect(locationCard, findsOneWidget);

    const brandRed = Color(0xFFF23845);
    const brandTint = Color(0xFFFFF0F2);

    final eyebrow = tester.widget<Text>(
      find.descendant(of: locationCard, matching: find.text('DELIVER TO')),
    );
    expect(eyebrow.style?.color, brandRed);

    final homeIcon = tester.widget<Icon>(
      find.descendant(
        of: locationCard,
        matching: find.byIcon(Icons.home_rounded),
      ),
    );
    expect(homeIcon.color, brandRed);

    final actionText = tester.widget<Text>(
      find.descendant(of: locationCard, matching: find.text('Change address')),
    );
    expect(actionText.style?.color, brandRed);

    final tintedSurfaces = tester
        .widgetList<Container>(
          find.descendant(of: locationCard, matching: find.byType(Container)),
        )
        .where(
          (container) =>
              container.decoration is BoxDecoration &&
              (container.decoration! as BoxDecoration).color == brandTint,
        );
    expect(tintedSurfaces, hasLength(2));
  });
}
