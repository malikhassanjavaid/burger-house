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

  group('Gmail registration validation', () {
    test('accepts Gmail addresses without case sensitivity', () {
      expect(isValidGmailAddress('customer@gmail.com'), isTrue);
      expect(isValidGmailAddress('Customer.Name+orders@GMAIL.COM'), isTrue);
    });

    test('rejects non-Gmail, malformed, and blank addresses', () {
      expect(isValidGmailAddress('customer@yahoo.com'), isFalse);
      expect(isValidGmailAddress('customer@gmail.co'), isFalse);
      expect(isValidGmailAddress('@gmail.com'), isFalse);
      expect(isValidGmailAddress('not an email@gmail.com'), isFalse);
      expect(isValidGmailAddress(''), isFalse);
    });
  });
}
