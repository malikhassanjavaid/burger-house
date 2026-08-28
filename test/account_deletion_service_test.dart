import 'package:flutter_application_1/features/account/services/account_deletion_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('account deletion error codes have safe customer-facing messages', () {
    expect(
      accountDeletionMessageForCode('unauthenticated'),
      'Your session expired. Sign in again before deleting your account.',
    );
    expect(
      accountDeletionMessageForCode('failed-precondition'),
      'Your account could not be deleted yet. Please try again in a moment.',
    );
    expect(
      accountDeletionMessageForCode('anything-else'),
      'We could not delete your account. Please try again.',
    );
  });

  test('account deletion invokes the configured remote request', () async {
    var calls = 0;
    final service = AccountDeletionService(
      invoke: () async {
        calls += 1;
      },
    );

    await service.deleteAccount();

    expect(calls, 1);
  });
}
