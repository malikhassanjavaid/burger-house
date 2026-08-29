import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../location/models/delivery_location.dart';
import 'auth_repository.dart';

class AuthService implements AuthRepository {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  static Future<void>? _googleInitialization;

  User? get currentUser => _auth.currentUser;

  @override
  bool get hasAuthenticatedUser => currentUser != null;

  @override
  Future<void> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: normalizeAuthEmail(email),
      password: password,
    );
    if (credential.user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account was returned for these credentials.',
      );
    }
  }

  Future<UserCredential?> signInWithGoogle() async {
    _googleInitialization ??= GoogleSignIn.instance.initialize();
    await _googleInitialization;

    GoogleSignInAccount googleUser;
    try {
      googleUser = await GoogleSignIn.instance.authenticate();
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) return null;
      rethrow;
    }

    final googleAuth = googleUser.authentication;
    final idToken = googleAuth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw const GoogleSignInException(
        code: GoogleSignInExceptionCode.providerConfigurationError,
        description: 'Google did not return an identity token.',
      );
    }

    final credential = GoogleAuthProvider.credential(idToken: idToken);
    return _auth.signInWithCredential(credential);
  }

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cleanEmail = normalizeAuthEmail(email);
    if (!isValidEmailAddress(cleanEmail)) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Enter a valid email address.',
      );
    }

    final credential = await _auth.createUserWithEmailAndPassword(
      email: cleanEmail,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-created',
        message: 'The account could not be created.',
      );
    }

    final cleanName = name.trim();
    try {
      await user.updateDisplayName(cleanName);
    } on FirebaseAuthException {
      // Profile synchronization retries after the phone credential is linked.
    }
  }

  @override
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    int? forceResendingToken,
    required Future<void> Function() onAutomaticVerificationCompleted,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(Object error) onVerificationFailed,
    required void Function(String verificationId) onAutoRetrievalTimeout,
  }) async {
    if (currentUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Sign in again before verifying your phone.',
      );
    }

    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      forceResendingToken: forceResendingToken,
      verificationCompleted: (credential) async {
        try {
          await _linkPhoneCredential(credential);
          await onAutomaticVerificationCompleted();
        } catch (error) {
          onVerificationFailed(error);
        }
      },
      verificationFailed: onVerificationFailed,
      codeSent: onCodeSent,
      codeAutoRetrievalTimeout: onAutoRetrievalTimeout,
    );
  }

  @override
  Future<void> confirmPhoneVerificationCode({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    return _linkPhoneCredential(credential);
  }

  Future<void> _linkPhoneCredential(PhoneAuthCredential credential) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Sign in again before verifying your phone.',
      );
    }

    try {
      await user.linkWithCredential(credential);
    } on FirebaseAuthException catch (error) {
      if (error.code != 'provider-already-linked') rethrow;
    }

    await user.reload();
    final refreshed = currentUser;
    if (refreshed == null || !_userHasVerifiedPhone(refreshed)) {
      throw FirebaseAuthException(
        code: 'phone-not-verified',
        message: 'The phone number could not be verified.',
      );
    }
    await refreshed.getIdToken(true);
  }

  @override
  Future<bool> hasVerifiedPhoneSession() async {
    final user = currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshed = currentUser;
    return refreshed != null && _userHasVerifiedPhone(refreshed);
  }

  @override
  Future<void> syncVerifiedCustomerProfile() async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Sign in again before continuing.',
      );
    }
    await user.reload();
    final refreshed = currentUser;
    if (refreshed == null || !_userHasVerifiedPhone(refreshed)) {
      throw FirebaseAuthException(
        code: 'phone-not-verified',
        message: 'Verify your phone number before continuing.',
      );
    }
    await refreshed.getIdToken(true);

    final reference = _firestore.collection('users').doc(refreshed.uid);
    final snapshot = await reference.get();
    final existing = snapshot.data();
    final verifiedPhone = refreshed.phoneNumber!.trim();
    final profile = <String, dynamic>{
      'uid': refreshed.uid,
      'name': refreshed.displayName?.trim().isNotEmpty == true
          ? refreshed.displayName!.trim()
          : (existing?['name'] as String?)?.trim().isNotEmpty == true
          ? (existing!['name'] as String).trim()
          : 'Customer',
      'email': normalizeAuthEmail(refreshed.email ?? ''),
      'phone': verifiedPhone,
      'role': 'customer',
      'profileUpdatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };
    if (!snapshot.exists || existing?['createdAt'] == null) {
      profile['createdAt'] = FieldValue.serverTimestamp();
    }
    if (existing?['phoneVerifiedAt'] == null ||
        existing?['phone'] != verifiedPhone) {
      profile['phoneVerifiedAt'] = FieldValue.serverTimestamp();
    }
    await reference.set(profile, SetOptions(merge: true));
  }

  bool _userHasVerifiedPhone(User user) {
    return hasVerifiedPhoneIdentity(
      providerIds: user.providerData.map((provider) => provider.providerId),
      phoneNumber: user.phoneNumber,
    );
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: normalizeAuthEmail(email));
  }

  Future<void> saveDeliveryLocation(DeliveryLocation location) async {
    final user = currentUser;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Please sign in before saving a delivery location.',
      );
    }
    await _firestore.collection('users').doc(user.uid).update({
      'deliveryAddress': location.toMap(),
      'addressUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<DeliveryLocation?> getDeliveryLocation() async {
    final user = currentUser;
    if (user == null) return null;
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data();
    final address = data?['deliveryAddress'];
    if (address is! Map) return null;
    return DeliveryLocation.fromMap(Map<String, dynamic>.from(address));
  }

  @override
  Future<void> signOut() async {
    final usedGoogle =
        currentUser?.providerData.any(
          (provider) => provider.providerId == GoogleAuthProvider.PROVIDER_ID,
        ) ??
        false;
    if (usedGoogle) {
      try {
        _googleInitialization ??= GoogleSignIn.instance.initialize();
        await _googleInitialization;
        await GoogleSignIn.instance.signOut();
      } catch (_) {
        // Firebase sign-out still completes if Google is unavailable.
      }
    }
    await _auth.signOut();
  }
}

String normalizeAuthEmail(String value) => value.trim().toLowerCase();

bool isValidEmailAddress(String value) {
  final email = normalizeAuthEmail(value);
  if (email.contains(RegExp(r'\s'))) return false;
  final parts = email.split('@');
  if (parts.length != 2 || parts.first.isEmpty || parts.last.isEmpty) {
    return false;
  }
  final local = RegExp(r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+$");
  final domain = RegExp(
    r'^(?:[a-z0-9](?:[a-z0-9-]{0,61}[a-z0-9])?\.)+[a-z]{2,63}$',
  );
  return local.hasMatch(parts.first) && domain.hasMatch(parts.last);
}

bool hasVerifiedPhoneIdentity({
  required Iterable<String> providerIds,
  required String? phoneNumber,
}) {
  return providerIds.contains(PhoneAuthProvider.PROVIDER_ID) &&
      phoneNumber?.trim().isNotEmpty == true;
}

String friendlyAuthError(Object error) {
  if (error is GoogleSignInException) {
    switch (error.code) {
      case GoogleSignInExceptionCode.clientConfigurationError:
      case GoogleSignInExceptionCode.providerConfigurationError:
        return 'Google sign-in is not configured yet. Enable Google in Firebase Authentication and add this app\'s SHA-1 fingerprint.';
      case GoogleSignInExceptionCode.interrupted:
      case GoogleSignInExceptionCode.uiUnavailable:
        return 'Google sign-in could not open. Please try again.';
      default:
        return error.description ?? 'Google sign-in failed. Please try again.';
    }
  }

  if (error is FirebaseAuthException) {
    switch (error.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Incorrect email or password.';
      case 'user-not-found':
        return 'No account exists for this email. Please create an account first.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-phone-number':
      case 'missing-phone-number':
        return 'Enter a valid phone number and try again.';
      case 'invalid-verification-code':
        return 'That verification code is incorrect. Try again.';
      case 'session-expired':
      case 'code-expired':
        return 'This code has expired. Request a new code.';
      case 'credential-already-in-use':
        return 'This phone number is already linked to another account.';
      case 'phone-not-verified':
        return 'Verify your phone number before continuing.';
      case 'quota-exceeded':
        return 'SMS service is temporarily unavailable. Please try again later.';
      case 'app-not-authorized':
      case 'captcha-check-failed':
        return 'Phone verification is not configured for this app build.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
      case 'operation-not-allowed':
        return 'Phone verification is not available right now. Please try again later.';
      default:
        return error.message ?? 'Authentication failed. Please try again.';
    }
  }

  if (error is FirebaseException) {
    if (error.code == 'permission-denied') {
      return 'The customer profile could not be saved. Check Firestore rules.';
    }
    return error.message ?? 'Firebase could not complete the request.';
  }

  return 'Something went wrong. Please try again.';
}

bool isSignInCredentialError(Object error) {
  return error is FirebaseAuthException &&
      const {
        'invalid-credential',
        'wrong-password',
        'user-not-found',
      }.contains(error.code);
}

bool isDefinitelyMissingAccount(Object error) {
  return error is FirebaseAuthException && error.code == 'user-not-found';
}
