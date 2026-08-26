import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/home/screens/home_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  setUpAll(Firebase.initializeApp);

  testWidgets('adding a featured deal opens Menu with the View Cart summary', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(0.8)),
          child: child!,
        ),
        home: const HomeScreen(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    final offerClose = find.byKey(const ValueKey('first-order-offer-close'));
    if (offerClose.evaluate().isNotEmpty) {
      await tester.tap(offerClose);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
    }

    for (var attempt = 0; attempt < 10; attempt++) {
      if (find
          .byKey(const PageStorageKey('home-content'))
          .evaluate()
          .isNotEmpty) {
        break;
      }
      await tester.pump(const Duration(milliseconds: 100));
    }

    final homeList = find.byKey(const PageStorageKey('home-content'));
    expect(homeList, findsOneWidget);
    final homeScrollable = find
        .descendant(of: homeList, matching: find.byType(Scrollable))
        .first;
    final pizzaDeal = find.byKey(const ValueKey('deal-poster-wow-pizza-deal'));
    await tester.scrollUntilVisible(pizzaDeal, 240, scrollable: homeScrollable);
    await tester.tap(pizzaDeal);
    await tester.pumpAndSettle();

    expect(find.text('WOW Pizza Deal'), findsOneWidget);
    await tester.tap(find.text('ADD TO CART'));
    await tester.pumpAndSettle();

    expect(find.text('Explore Menu'), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-cart-summary')), findsOneWidget);
    expect(find.text('1 ITEM'), findsOneWidget);
    expect(find.text(r'$24.99'), findsOneWidget);
    expect(find.text('View Cart'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
