import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../location/models/delivery_location.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  static Future<void>? _googleInitialization;

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: normalizeAuthEmail(email),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account was returned for these credentials.',
      );
    }

    await user.reload();
    final refreshedUser = _auth.currentUser;
    if (refreshedUser == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'The account could not be loaded.',
      );
    }

    if (_requiresEmailVerification(refreshedUser) &&
        !refreshedUser.emailVerified) {
      await _auth.signOut();
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message: 'Verify your Gmail address before signing in.',
      );
    }

    // Authentication has already succeeded at this point. A profile/audit sync
    // must never turn a valid Firebase Auth login into a failed login.
    await _syncVerifiedCustomerProfile(refreshedUser);
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
    final result = await _auth.signInWithCredential(credential);
    final user = result.user;
    if (user != null) {
      final profile = <String, dynamic>{
        'uid': user.uid,
        'name': user.displayName ?? googleUser.displayName ?? 'Customer',
        'email': (user.email ?? googleUser.email).toLowerCase(),
        'role': 'customer',
        'profileUpdatedAt': FieldValue.serverTimestamp(),
      };
      if (result.additionalUserInfo?.isNewUser ?? false) {
        profile['phone'] = user.phoneNumber ?? '';
        profile['createdAt'] = FieldValue.serverTimestamp();
      }
      await _firestore
          .collection('users')
          .doc(user.uid)
          .set(profile, SetOptions(merge: true));
    }
    return result;
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final cleanEmail = normalizeAuthEmail(email);
    if (!isValidGmailAddress(cleanEmail)) {
      throw FirebaseAuthException(
        code: 'gmail-required',
        message: 'Use a valid @gmail.com address to create an account.',
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
      await user.sendEmailVerification();
      try {
        await user.updateDisplayName(cleanName);
      } on FirebaseAuthException {
        // The display name is also stored in Firestore. A temporary failure
        // here must not invalidate the newly created login credentials.
      }
      await _saveNewCustomerProfile(
        user: user,
        name: cleanName,
        email: cleanEmail,
        phone: phone.trim(),
      );
    } finally {
      // Verification is completed from email, so keep no unverified session
      // active inside the customer app.
      await _auth.signOut();
    }
  }

  Future<void> resendEmailVerification({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: normalizeAuthEmail(email),
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'No account exists for this email.',
      );
    }

    try {
      await user.reload();
      final refreshedUser = _auth.currentUser;
      if (refreshedUser == null) {
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'The account could not be loaded.',
        );
      }
      if (refreshedUser.emailVerified) {
        throw FirebaseAuthException(
          code: 'email-already-verified',
          message: 'This Gmail address is already verified. You can log in.',
        );
      }
      await refreshedUser.sendEmailVerification();
    } finally {
      await _auth.signOut();
    }
  }

  Future<bool> hasVerifiedSession() async {
    final user = currentUser;
    if (user == null) return false;
    await user.reload();
    final refreshedUser = currentUser;
    if (refreshedUser == null) return false;
    return !_requiresEmailVerification(refreshedUser) ||
        refreshedUser.emailVerified;
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

  Future<DeliveryLocation?> getDeliveryLocation() async {
    final user = currentUser;
    if (user == null) return null;
    final snapshot = await _firestore.collection('users').doc(user.uid).get();
    final data = snapshot.data();
    final address = data?['deliveryAddress'];
    if (address is! Map) return null;
    return DeliveryLocation.fromMap(Map<String, dynamic>.from(address));
  }

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
        // Firebase sign-out must still complete if the provider is unavailable.
      }
    }
    await _auth.signOut();
  }

  Future<void> _saveNewCustomerProfile({
    required User user,
    required String name,
    required String email,
    required String phone,
  }) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': name,
        'email': email,
        'emailVerified': false,
        'phone': phone,
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // The Firebase Auth account and verification email are already valid.
      // Keep them. The missing profile is repaired after the first verified
      // login instead of deleting the customer's account.
    }
  }

  Future<void> _syncVerifiedCustomerProfile(User user) async {
    try {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': user.displayName?.trim().isNotEmpty == true
            ? user.displayName!.trim()
            : 'Customer',
        'email': normalizeAuthEmail(user.email ?? ''),
        'emailVerified': true,
        'role': 'customer',
        'profileUpdatedAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } on FirebaseException {
      // Login remains successful. Profile-dependent screens can report their
      // own Firestore problem without mislabeling it as a password failure.
    }
  }
}

String normalizeAuthEmail(String value) => value.trim().toLowerCase();

bool isValidGmailAddress(String value) {
  final email = normalizeAuthEmail(value);
  if (email.contains(RegExp(r'\s'))) return false;
  final parts = email.split('@');
  if (parts.length != 2 || parts.first.isEmpty) return false;
  if (parts.last != 'gmail.com') return false;
  return RegExp(r"^[a-z0-9.!#$%&'*+/=?^_`{|}~-]+$").hasMatch(parts.first);
}

bool _requiresEmailVerification(User user) {
  return user.providerData.any(
    (provider) => provider.providerId == EmailAuthProvider.PROVIDER_ID,
  );
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
      case 'gmail-required':
        return 'Please use a valid @gmail.com address.';
      case 'email-not-verified':
        return 'Verify your Gmail address before logging in.';
      case 'email-already-verified':
        return 'Your Gmail address is already verified. You can log in.';
      case 'weak-password':
        return 'Choose a stronger password with at least 6 characters.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      case 'network-request-failed':
        return 'Check your internet connection and try again.';
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

bool isUnverifiedEmailError(Object error) {
  return error is FirebaseAuthException && error.code == 'email-not-verified';
}
