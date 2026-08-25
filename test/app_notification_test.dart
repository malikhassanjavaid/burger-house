import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/widgets/app_notification.dart';
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

  testWidgets('temporary notification appears at top-right for five seconds', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: FilledButton(
                onPressed: () => AppNotification.show(
                  context,
                  message: 'Changes saved',
                  tone: AppNotificationTone.success,
                ),
                child: const Text('Show message'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Show message'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));

    final notification = find.byKey(const ValueKey('app-notification'));
    expect(notification, findsOneWidget);
    expect(find.text('Changes saved'), findsOneWidget);
    final bounds = tester.getRect(notification);
    expect(bounds.top, lessThan(100));
    expect(bounds.right, closeTo(378, 1));

    await tester.pump(const Duration(milliseconds: 4819));
    expect(notification, findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1));
    expect(notification, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('cart removal notification restores the item with Undo', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final burger = sampleMenu.firstWhere((item) => item.id == 'classic-smash');
    var latestCart = <CartItem>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: CartScreen(
          items: [
            CartItem(menuItem: burger, quantity: 1, unitPrice: burger.price),
          ],
          deliveryAddress: 'Test address',
          onCartChanged: (items) => latestCart = items,
        ),
      ),
    );

    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pump();

    expect(find.text('Classic Smash removed'), findsOneWidget);
    expect(find.text('UNDO'), findsOneWidget);
    expect(latestCart, isEmpty);
    expect(
      tester.getRect(find.byKey(const ValueKey('app-notification'))).top,
      lessThan(100),
    );

    await tester.tap(find.text('UNDO'));
    await tester.pump();

    expect(find.text('Classic Smash'), findsOneWidget);
    expect(latestCart, hasLength(1));
    expect(find.byKey(const ValueKey('app-notification')), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
