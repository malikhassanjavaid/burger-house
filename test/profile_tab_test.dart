import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/home/widgets/profile_tab.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('profile tab shows only requested actions and handles taps', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var detailsOpened = false;
    var privacyOpened = false;
    var signedOut = false;
    final platformCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
          platformCalls.add(call);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: ProfileTab(
              onDetails: () => detailsOpened = true,
              onAddress: () {},
              onOrders: () {},
              onPrivacy: () => privacyOpened = true,
            ),
          ),
          bottomNavigationBar: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProfileLogoutBar(onSignOut: () => signedOut = true),
              const SizedBox(height: 72),
            ],
          ),
        ),
      ),
    );

    expect(find.text('MY DETAILS'), findsOneWidget);
    expect(find.text('MY ADDRESS'), findsOneWidget);
    expect(find.text('MY ORDERS'), findsOneWidget);
    expect(find.text('PRIVACY & ACCOUNT'), findsOneWidget);
    expect(find.text('MY FAVOURITES'), findsNothing);
    expect(tester.takeException(), isNull);

    final logoutButton = find.widgetWithText(FilledButton, 'LOGOUT');
    final logoutBottom = tester.getBottomRight(logoutButton).dy;
    expect(logoutBottom, closeTo(716, 1));

    await tester.tap(find.text('MY DETAILS'));
    expect(detailsOpened, isTrue);
    final detailHaptics = platformCalls
        .where((call) => call.method == 'HapticFeedback.vibrate')
        .toList();
    expect(detailHaptics, hasLength(1));
    expect(detailHaptics.single.arguments, 'HapticFeedbackType.selectionClick');

    platformCalls.clear();
    await tester.tap(find.text('PRIVACY & ACCOUNT'));
    expect(privacyOpened, isTrue);
    final privacyHaptics = platformCalls
        .where((call) => call.method == 'HapticFeedback.vibrate')
        .toList();
    expect(privacyHaptics, hasLength(1));
    expect(
      privacyHaptics.single.arguments,
      'HapticFeedbackType.selectionClick',
    );

    await tester.tap(find.text('LOGOUT'));
    await tester.pumpAndSettle();
    expect(find.text('Log out of Hungry Spot?'), findsOneWidget);

    await tester.tap(find.text('LOGOUT').last);
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
    expect(tester.takeException(), isNull);
  });
}
