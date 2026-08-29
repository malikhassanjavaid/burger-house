import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/account/screens/privacy_account_screen.dart';
import 'package:flutter_application_1/features/account/services/account_deletion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('privacy action card compresses while held', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const PrivacyAccountScreen(canDeleteAccount: false),
      ),
    );
    await tester.pumpAndSettle();

    final action = find.bySemanticsLabel('Open Privacy policy');
    final gesture = await tester.startGesture(tester.getCenter(action));
    await tester.pump(const Duration(milliseconds: 100));

    final scale = find.descendant(
      of: action,
      matching: find.byType(AnimatedScale),
    );
    expect(scale, findsOneWidget);
    expect(tester.widget<AnimatedScale>(scale).scale, .97);

    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scale).scale, 1);
  });

  testWidgets('privacy hub fits a phone and exposes its protection actions', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const PrivacyAccountScreen(canDeleteAccount: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('Hungry Spot privacy protection banner'),
      findsOneWidget,
    );
    expect(find.text('Your privacy, protected'), findsOneWidget);
    expect(find.text('You stay in control'), findsOneWidget);
    final privacyPolicyAction = find.bySemanticsLabel('Open Privacy policy');
    final deletionInformationAction = find.bySemanticsLabel(
      'Open Account deletion information',
    );
    expect(privacyPolicyAction, findsOneWidget);
    expect(deletionInformationAction, findsOneWidget);
    expect(
      tester
          .getSemantics(privacyPolicyAction)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(
      tester
          .getSemantics(deletionInformationAction)
          .getSemanticsData()
          .hasAction(SemanticsAction.tap),
      isTrue,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('account deletion requires an exact confirmation phrase', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    var deletionCalls = 0;
    var signOutCalls = 0;
    var completed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: PrivacyAccountScreen(
          canDeleteAccount: true,
          deletionService: AccountDeletionService(
            invoke: () async => deletionCalls += 1,
          ),
          signOut: () async => signOutCalls += 1,
          onDeleted: () => completed = true,
        ),
      ),
    );

    await tester.drag(find.byType(ListView), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('delete-account')));
    await tester.pumpAndSettle();

    final confirmation = find.byKey(const ValueKey('confirm-delete-account'));
    expect(tester.widget<FilledButton>(confirmation).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('delete-account-confirmation')),
      'delete',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(confirmation).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('delete-account-confirmation')),
      'DELETE',
    );
    await tester.pump();
    expect(tester.widget<FilledButton>(confirmation).onPressed, isNotNull);

    await tester.tap(confirmation);
    await tester.pumpAndSettle();

    expect(deletionCalls, 1);
    expect(signOutCalls, 1);
    expect(completed, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-out privacy view hides destructive account controls', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: PrivacyAccountScreen(canDeleteAccount: false)),
    );

    expect(find.text('Privacy policy'), findsOneWidget);
    expect(find.byKey(const ValueKey('delete-account')), findsNothing);
  });
}
