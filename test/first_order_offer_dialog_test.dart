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

  testWidgets(
    'first-order offer is compact and its close control dismisses it',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(theme: AppTheme.light, home: const HomeScreen()),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final offer = find.byKey(const ValueKey('first-order-offer-card'));
      expect(offer, findsOneWidget);
      final offerSize = tester.getSize(offer);
      expect(offerSize.width, lessThanOrEqualTo(312));
      expect(offerSize.height, lessThanOrEqualTo(390));

      final close = find.byKey(const ValueKey('first-order-offer-close'));
      expect(close, findsOneWidget);
      final closeSize = tester.getSize(close);
      expect(closeSize.width, greaterThanOrEqualTo(44));
      expect(closeSize.height, greaterThanOrEqualTo(44));

      await tester.tap(close);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(offer, findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
