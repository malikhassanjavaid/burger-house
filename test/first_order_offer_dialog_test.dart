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

  testWidgets('new signup sees the branded welcome card before the offer', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(
          showNewAccountWelcome: true,
          welcomeName: 'Hassan Ali',
          hasOrderHistoryLoader: () async => false,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final welcome = find.byKey(const ValueKey('new-account-welcome-card'));
    expect(welcome, findsOneWidget);
    expect(find.text('Welcome, Hassan!', findRichText: true), findsOneWidget);
    expect(
      find.byKey(const ValueKey('new-account-welcome-logo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('new-account-welcome-ticket-rail')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('new-account-welcome-logo-seal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('new-account-welcome-celebration')),
      findsOneWidget,
    );
    expect(find.text('Enjoy!'), findsNothing);
    final welcomeSize = tester.getSize(welcome);
    expect(welcomeSize, const Size(360, 500));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('new-account-start-ordering')))
          .height,
      56,
    );
    expect(find.byKey(const ValueKey('first-order-offer-card')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('new-account-start-ordering')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(welcome, findsNothing);
    expect(
      find.byKey(const ValueKey('first-order-offer-card')),
      findsOneWidget,
    );
  });

  testWidgets(
    'first-order offer matches the selected ticket design and both actions work',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(360, 640);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light,
          home: HomeScreen(hasOrderHistoryLoader: () async => false),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final offer = find.byKey(const ValueKey('first-order-offer-card'));
      expect(offer, findsOneWidget);
      final offerSize = tester.getSize(offer);
      expect(offerSize.width, lessThanOrEqualTo(342));
      expect(offerSize.height, lessThanOrEqualTo(540));
      expect(offerSize.height / offerSize.width, closeTo(532 / 342, .03));

      expect(
        find.byKey(const ValueKey('first-order-offer-logo')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('first-order-offer-food')),
        findsOneWidget,
      );
      expect(find.text('FIRST ORDER'), findsOneWidget);
      expect(find.text('10%'), findsOneWidget);
      expect(find.text('OFF'), findsOneWidget);
      expect(find.text('Your first bite is on us'), findsOneWidget);
      expect(find.text('BURGER10'), findsOneWidget);

      final close = find.byKey(const ValueKey('first-order-offer-close'));
      expect(close, findsOneWidget);
      final closeBounds = tester.getRect(close);
      expect(closeBounds.width, greaterThanOrEqualTo(44));
      expect(closeBounds.height, greaterThanOrEqualTo(44));

      final startOrdering = find.byKey(
        const ValueKey('first-order-offer-start-ordering'),
      );
      expect(startOrdering, findsOneWidget);
      expect(tester.getRect(startOrdering).height, greaterThanOrEqualTo(44));

      await tester.tap(startOrdering);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(offer, findsNothing);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('home-notification-button')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(offer, findsOneWidget);

      await tester.tap(close);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(offer, findsNothing);
    },
  );

  testWidgets('first-order ticket stays usable in a short safe area', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);
    tester.view.padding = const FakeViewPadding(top: 24, bottom: 20);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(hasOrderHistoryLoader: () async => false),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    final offer = find.byKey(const ValueKey('first-order-offer-card'));
    expect(offer, findsOneWidget);
    final bounds = tester.getRect(offer);
    expect(bounds.top, greaterThanOrEqualTo(24));
    expect(bounds.bottom, lessThanOrEqualTo(480 - 20));
    expect(
      find
          .byKey(const ValueKey('first-order-offer-start-ordering'))
          .hitTestable(),
      findsOneWidget,
    );
    final closeBounds = tester.getRect(
      find.byKey(const ValueKey('first-order-offer-close')),
    );
    final actionBounds = tester.getRect(
      find.byKey(const ValueKey('first-order-offer-start-ordering')),
    );
    expect(closeBounds.width, greaterThanOrEqualTo(44));
    expect(closeBounds.height, greaterThanOrEqualTo(44));
    expect(actionBounds.height, greaterThanOrEqualTo(44));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'first-order ticket respects large text and keeps actions usable',
    (tester) async {
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
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: HomeScreen(hasOrderHistoryLoader: () async => false),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final offer = find.byKey(const ValueKey('first-order-offer-card'));
      expect(offer, findsOneWidget);
      final title = find.text('Your first bite is on us');
      expect(title, findsOneWidget);
      expect(
        MediaQuery.textScalerOf(tester.element(title)).scale(20),
        greaterThanOrEqualTo(24),
      );
      expect(
        tester
            .getRect(find.byKey(const ValueKey('first-order-offer-close')))
            .height,
        greaterThanOrEqualTo(44),
      );
      expect(
        tester
            .getRect(
              find.byKey(const ValueKey('first-order-offer-start-ordering')),
            )
            .height,
        greaterThanOrEqualTo(44),
      );
      expect(tester.takeException(), isNull);

      await tester.tap(
        find.byKey(const ValueKey('first-order-offer-start-ordering')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(offer, findsNothing);
    },
  );

  testWidgets('offer is hidden when the customer already placed an order', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(hasOrderHistoryLoader: () async => true),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('first-order-offer-card')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('home-notification-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('first-order-offer-card')), findsNothing);
  });

  testWidgets('offer stays hidden when order history cannot be checked', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: HomeScreen(
          hasOrderHistoryLoader: () => Future<bool>.error('offline'),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('first-order-offer-card')), findsNothing);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('home-notification-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byKey(const ValueKey('first-order-offer-card')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('zero-order offer appears on each fresh home entry', (
    tester,
  ) async {
    Widget home(Key key) => MaterialApp(
      home: HomeScreen(key: key, hasOrderHistoryLoader: () async => false),
    );

    await tester.pumpWidget(home(const ValueKey('first-entry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      find.byKey(const ValueKey('first-order-offer-card')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('first-order-offer-close')));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpWidget(home(const ValueKey('second-entry')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const ValueKey('first-order-offer-card')),
      findsOneWidget,
    );
  });

  testWidgets('ineligible signup sees welcome without a follow-up offer', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          showNewAccountWelcome: true,
          welcomeName: 'Hassan',
          hasOrderHistoryLoader: () async => true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(
      find.byKey(const ValueKey('new-account-welcome-card')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('new-account-start-ordering')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byKey(const ValueKey('first-order-offer-card')), findsNothing);
  });

  testWidgets('welcome card remains usable at 200 percent text scale', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: HomeScreen(
          showNewAccountWelcome: true,
          welcomeName: 'Alexandra',
          hasOrderHistoryLoader: () async => true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final welcome = find.byKey(const ValueKey('new-account-welcome-card'));
    expect(welcome, findsOneWidget);
    final bounds = tester.getRect(welcome);
    expect(bounds.top, greaterThanOrEqualTo(0));
    expect(bounds.bottom, lessThanOrEqualTo(640));
    expect(
      find.byKey(const ValueKey('new-account-start-ordering')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    final body = find.textContaining('Your account is ready');
    await tester.ensureVisible(body);
    await tester.pump();
    expect(body, findsOneWidget);
    expect(
      find.byKey(const ValueKey('new-account-start-ordering')).hitTestable(),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('new-account-start-ordering')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(welcome, findsNothing);
  });

  testWidgets('welcome card stays inside a padded short safe area', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 480);
    tester.view.padding = const FakeViewPadding(top: 40, bottom: 28);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);

    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          showNewAccountWelcome: true,
          welcomeName: 'Hassan',
          hasOrderHistoryLoader: () async => true,
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    final welcome = find.byKey(const ValueKey('new-account-welcome-card'));
    expect(welcome, findsOneWidget);
    final bounds = tester.getRect(welcome);
    expect(bounds.top, greaterThanOrEqualTo(40));
    expect(bounds.bottom, lessThanOrEqualTo(480 - 28));
    expect(bounds.height, 480 - 40 - 28);
    expect(tester.takeException(), isNull);
  });
}
