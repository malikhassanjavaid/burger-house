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

  testWidgets('checkout uses the complete Full HD banner artwork', (
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
    await tester.pumpAndSettle();

    final banner = find.byKey(const ValueKey('checkout-hero-banner'));
    expect(banner, findsOneWidget);

    final image = tester.widget<Image>(
      find.descendant(of: banner, matching: find.byType(Image)),
    );
    final imageProvider = switch (image.image) {
      ResizeImage(:final imageProvider) => imageProvider,
      final provider => provider,
    };
    expect(imageProvider, isA<AssetImage>());
    expect(
      (imageProvider as AssetImage).assetName,
      'assets/images/checkout_banner_full_hd.png',
    );

    await tester.runAsync(
      () => precacheImage(image.image, tester.element(banner)),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: banner, matching: find.byType(Text)),
      findsNothing,
    );
    expect(
      find.descendant(of: banner, matching: find.byType(Icon)),
      findsNothing,
    );

    await expectLater(banner, matchesGoldenFile('goldens/checkout_banner.png'));
  });
}
