import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/widgets/international_phone_input.dart';
import 'package:flutter_application_1/features/auth/screens/register_screen.dart';
import 'package:flutter_application_1/features/home/models/cart_item.dart';
import 'package:flutter_application_1/features/home/models/menu_item.dart';
import 'package:flutter_application_1/features/home/screens/checkout_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(Firebase.initializeApp);

  test('legacy local profile numbers remain valid during migration', () {
    expect(validateInternationalPhoneNumber('03001234567'), isNull);
  });

  testWidgets('signup phone field exposes a flag and country dial code', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.binding.platformDispatcher.localeTestValue = const Locale(
      'en',
      'PK',
    );
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.binding.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'PK'),
        theme: AppTheme.light,
        home: const RegisterScreen(),
      ),
    );

    expect(
      find.byKey(const ValueKey('signup-phone-country-selector')),
      findsOneWidget,
    );
    expect(find.text('+92'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('signup-phone-number-input')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('signup-phone-country-selector')),
    );
    await tester.pumpAndSettle();
    expect(find.text('Saudi Arabia'), findsWidgets);

    await tester.tap(find.text('Saudi Arabia').first);
    await tester.pumpAndSettle();
    expect(find.text('+966'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('country picker uses a half-height scrollable sheet', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: Center(
            child: InternationalPhoneInput(
              value: '+923001234567',
              onChanged: (_) {},
              countrySelectorKey: const ValueKey(
                'half-height-country-selector',
              ),
              phoneFieldKey: const ValueKey('half-height-phone-input'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('half-height-country-selector')),
    );
    await tester.pumpAndSettle();

    final sheetHeight = tester.getSize(find.byType(BottomSheet)).height;
    expect(sheetHeight, inInclusiveRange(380, 465));

    final countryList = find.byType(ListView);
    final countryScroll = find.descendant(
      of: countryList,
      matching: find.byType(Scrollable),
    );
    final scrollState = tester.state<ScrollableState>(countryScroll);
    expect(scrollState.position.maxScrollExtent, greaterThan(0));

    await tester.drag(countryList, const Offset(0, -220));
    await tester.pumpAndSettle();
    expect(scrollState.position.pixels, greaterThan(0));
    expect(tester.takeException(), isNull);
  });

  testWidgets('checkout shows the saved number and uses generic validation', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'PK'),
        theme: AppTheme.light,
        home: CheckoutScreen(
          items: const [
            CartItem(
              menuItem: MenuItem(
                id: 'phone-test',
                name: 'Test Burger',
                description: 'Checkout phone test',
                category: 'Burgers',
                emoji: '',
                assetPath: 'assets/images/beefburger.webp',
                price: 9.99,
              ),
              quantity: 1,
              unitPrice: 9.99,
            ),
          ],
          initialAddress: 'Test address',
          initialPhoneNumber: '+923001234567',
          deliveryFee: 2,
          onOrderPlaced: () {},
        ),
      ),
    );
    await tester.pump();

    expect(find.text('+923001234567'), findsOneWidget);

    await tester.tap(find.text('Change phone number'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('checkout-phone-country-selector')),
      findsOneWidget,
    );
    expect(find.text('+92'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('checkout-phone-number-input')),
      '',
    );
    await tester.tap(find.text('SAVE NUMBER'));
    await tester.pump();

    expect(find.text('Enter a valid phone number'), findsOneWidget);
    expect(find.textContaining('US'), findsNothing);
  });

  testWidgets('checkout loads the signup phone from the customer profile', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CheckoutScreen(
          items: const [
            CartItem(
              menuItem: MenuItem(
                id: 'profile-phone-test',
                name: 'Test Burger',
                description: 'Saved profile phone test',
                category: 'Burgers',
                emoji: '',
                assetPath: 'assets/images/beefburger.webp',
                price: 9.99,
              ),
              quantity: 1,
              unitPrice: 9.99,
            ),
          ],
          initialAddress: 'Test address',
          profileLoader: () async => const {
            'name': 'Hassan',
            'phone': '+923001234567',
          },
          deliveryFee: 2,
          onOrderPlaced: () {},
        ),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('+923001234567'), findsOneWidget);
    expect(find.text('Change phone number'), findsOneWidget);
  });
}
