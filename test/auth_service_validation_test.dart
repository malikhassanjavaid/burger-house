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
}
