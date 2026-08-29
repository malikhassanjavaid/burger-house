import '../../location/models/delivery_location.dart';

abstract interface class PhoneVerificationClient {
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    int? forceResendingToken,
    required Future<void> Function() onAutomaticVerificationCompleted,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(Object error) onVerificationFailed,
    required void Function(String verificationId) onAutoRetrievalTimeout,
  });

  Future<void> confirmPhoneVerificationCode({
    required String verificationId,
    required String smsCode,
  });
}

abstract interface class AuthRepository implements PhoneVerificationClient {
  bool get hasAuthenticatedUser;

  Future<void> signIn({required String email, required String password});

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  });

  Future<void> signOut();

  Future<bool> hasVerifiedPhoneSession();

  Future<void> syncVerifiedCustomerProfile();

  Future<DeliveryLocation?> getDeliveryLocation();
}
