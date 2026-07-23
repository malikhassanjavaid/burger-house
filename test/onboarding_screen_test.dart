import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/routes/app_routes.dart';
import 'package:flutter_application_1/core/widgets/brand_logo.dart';
import 'package:flutter_application_1/features/onboarding/screens/onboarding_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('onboarding shows the three food stories in order', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpOnboarding(tester);

    expect(find.text('Good food,\nmade for your moment.'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-image-0')), findsOneWidget);
    expect(find.byType(HungrySpotLogo), findsNothing);
    expect(tester.takeException(), isNull);

    await _continue(tester);
    expect(find.text('Every bite,\nmade your way.'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-image-1')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _continue(tester);
    expect(find.text('Your next craving,\none tap away.'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-image-2')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await _continue(tester);
    expect(find.text('Login destination'), findsOneWidget);
  });

  testWidgets('header and centered images stay aligned on a compact phone', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await _pumpOnboarding(tester);

    final progressTop = tester
        .getRect(find.byKey(const ValueKey('onboarding-progress-0')))
        .top;
    expect(
      tester.getRect(find.byKey(const ValueKey('onboarding-progress-1'))).top,
      progressTop,
    );
    expect(
      tester.getRect(find.byKey(const ValueKey('onboarding-progress-2'))).top,
      progressTop,
    );

    for (var index = 0; index < 3; index++) {
      final hero = tester.getRect(
        find.byKey(ValueKey('onboarding-hero-stage-$index')),
      );
      final image = tester.getRect(
        find.byKey(ValueKey('onboarding-image-$index')),
      );
      expect(image.left, greaterThanOrEqualTo(hero.left));
      expect(image.top, greaterThanOrEqualTo(hero.top));
      expect(image.right, lessThanOrEqualTo(hero.right));
      expect(image.bottom, lessThanOrEqualTo(hero.bottom));
      expect(tester.takeException(), isNull);
      if (index < 2) await _continue(tester);
    }

    final button = tester.getRect(
      find.byKey(const ValueKey('onboarding-continue')),
    );
    expect(button.left, greaterThanOrEqualTo(20));
    expect(button.right, lessThanOrEqualTo(340));
    expect(button.bottom, lessThanOrEqualTo(640));
  });
}

Future<void> _pumpOnboarding(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      routes: {
        AppRoutes.login: (_) =>
            const Scaffold(body: Center(child: Text('Login destination'))),
      },
      home: OnboardingScreen(onCompleted: () async {}),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _continue(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('onboarding-continue')));
  await tester.pumpAndSettle();
}
