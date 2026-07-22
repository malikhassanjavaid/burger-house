import 'package:flutter/material.dart';
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
    var signedOut = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SafeArea(
            child: ProfileTab(
              onDetails: () => detailsOpened = true,
              onAddress: () {},
              onOrders: () {},
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
    expect(find.text('MY FAVOURITES'), findsNothing);
    expect(tester.takeException(), isNull);

    final logoutButton = find.widgetWithText(FilledButton, 'LOGOUT');
    final logoutBottom = tester.getBottomRight(logoutButton).dy;
    expect(logoutBottom, closeTo(716, 1));

    await tester.tap(find.text('MY DETAILS'));
    expect(detailsOpened, isTrue);

    await tester.tap(find.text('LOGOUT'));
    await tester.pumpAndSettle();
    expect(find.text('Log out of Hungry Spot?'), findsOneWidget);

    await tester.tap(find.text('LOGOUT').last);
    await tester.pumpAndSettle();
    expect(signedOut, isTrue);
    expect(tester.takeException(), isNull);
  });
}
