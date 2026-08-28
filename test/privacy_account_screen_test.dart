import 'package:flutter/material.dart';
import 'package:flutter_application_1/features/account/screens/privacy_account_screen.dart';
import 'package:flutter_application_1/features/account/services/account_deletion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('account deletion requires an exact confirmation phrase', (
    tester,
  ) async {
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
