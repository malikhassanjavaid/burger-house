import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Authentication input normalization', () {
    test('normalizes email casing and surrounding spaces consistently', () {
      expect(
        normalizeAuthEmail('  Customer.Name@GMAIL.COM  '),
        'customer.name@gmail.com',
      );
    });
  });

  group('Registration email validation', () {
    test('accepts normalized addresses from common providers', () {
      expect(isValidEmailAddress('customer@gmail.com'), isTrue);
      expect(isValidEmailAddress('Customer.Name+orders@GMAIL.COM'), isTrue);
      expect(isValidEmailAddress('customer@outlook.com'), isTrue);
    });

    test('rejects malformed and blank addresses', () {
      expect(isValidEmailAddress('customer@'), isFalse);
      expect(isValidEmailAddress('@example.com'), isFalse);
      expect(isValidEmailAddress('not an email@example.com'), isFalse);
      expect(isValidEmailAddress('customer@example'), isFalse);
      expect(isValidEmailAddress(''), isFalse);
    });
  });

  group('Verified phone identity', () {
    test('requires both the linked provider and Firebase phone number', () {
      expect(
        hasVerifiedPhoneIdentity(
          providerIds: const ['password', 'phone'],
          phoneNumber: '+923001234567',
        ),
        isTrue,
      );
      expect(
        hasVerifiedPhoneIdentity(
          providerIds: const ['password'],
          phoneNumber: '+923001234567',
        ),
        isFalse,
      );
      expect(
        hasVerifiedPhoneIdentity(
          providerIds: const ['password', 'phone'],
          phoneNumber: '',
        ),
        isFalse,
      );
    });
  });

  group('Phone verification errors', () {
    test('hides Firebase provider configuration details from customers', () {
      expect(
        friendlyAuthError(
          FirebaseAuthException(
            code: 'operation-not-allowed',
            message:
                'This operation is not allowed. Enable it in the Firebase console.',
          ),
        ),
        'Phone verification is not available right now. Please try again later.',
      );
    });

    test('maps invalid phone and code failures to recovery copy', () {
      expect(
        friendlyAuthError(FirebaseAuthException(code: 'invalid-phone-number')),
        'Enter a valid phone number and try again.',
      );
      expect(
        friendlyAuthError(
          FirebaseAuthException(code: 'invalid-verification-code'),
        ),
        'That verification code is incorrect. Try again.',
      );
      expect(
        friendlyAuthError(FirebaseAuthException(code: 'session-expired')),
        'This code has expired. Request a new code.',
      );
    });

    test('does not hide duplicate phone and quota recovery actions', () {
      expect(
        friendlyAuthError(
          FirebaseAuthException(code: 'credential-already-in-use'),
        ),
        'This phone number is already linked to another account.',
      );
      expect(
        friendlyAuthError(FirebaseAuthException(code: 'quota-exceeded')),
        'SMS service is temporarily unavailable. Please try again later.',
      );
      expect(
        friendlyAuthError(FirebaseAuthException(code: 'phone-not-verified')),
        'Verify your phone number before continuing.',
      );
    });
  });
}
