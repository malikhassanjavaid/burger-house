import 'package:cloud_functions/cloud_functions.dart';

typedef AccountDeletionInvoke = Future<void> Function();

class AccountDeletionException implements Exception {
  const AccountDeletionException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AccountDeletionService {
  AccountDeletionService({AccountDeletionInvoke? invoke})
    : _invoke = invoke ?? _firebaseInvoke;

  final AccountDeletionInvoke _invoke;

  static Future<void> _firebaseInvoke() async {
    await FirebaseFunctions.instance
        .httpsCallable('deleteAccount')
        .call<void>();
  }

  Future<void> deleteAccount() async {
    try {
      await _invoke();
    } on FirebaseFunctionsException catch (error) {
      throw AccountDeletionException(accountDeletionMessageForCode(error.code));
    } on AccountDeletionException {
      rethrow;
    } catch (_) {
      throw const AccountDeletionException(
        'We could not delete your account. Please try again.',
      );
    }
  }
}

String accountDeletionMessageForCode(String code) {
  return switch (code) {
    'unauthenticated' =>
      'Your session expired. Sign in again before deleting your account.',
    'failed-precondition' =>
      'Your account could not be deleted yet. Please try again in a moment.',
    _ => 'We could not delete your account. Please try again.',
  };
}
