import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/home/data/sample_menu.dart';
import 'package:flutter_application_1/features/home/models/cart_item.dart';
import 'package:flutter_application_1/features/home/screens/cart_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final fonts = FontLoader('Plus Jakarta Sans')
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Regular.ttf'))
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-SemiBold.ttf'))
      ..addFont(rootBundle.load('assets/fonts/PlusJakartaSans-Bold.ttf'));
    await fonts.load();
  });

  testWidgets(
    'Apply Coupon opens an editable field and closes without errors',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(390, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final burger = sampleMenu.firstWhere(
        (item) => item.id == 'classic-smash',
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: CartScreen(
            items: [
              CartItem(menuItem: burger, quantity: 1, unitPrice: burger.price),
            ],
            deliveryAddress: 'Test address',
            onCartChanged: (_) {},
          ),
        ),
      );

      await tester.scrollUntilVisible(
        find.text('Apply Coupon'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('Apply Coupon'));
      await tester.pumpAndSettle();

      final couponField = find.widgetWithText(TextField, 'Coupon code');
      expect(couponField, findsOneWidget);

      await tester.enterText(couponField, 'BURGER10');
      await tester.pump();

      expect(find.text('BURGER10'), findsOneWidget);

      await tester.tap(find.text('APPLY COUPON'));
      await tester.pump();

      expect(find.text('Coupon BURGER10 applied'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(const Duration(seconds: 5));
      expect(tester.takeException(), isNull);
    },
  );
}
