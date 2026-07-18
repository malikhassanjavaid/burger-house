import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../location/models/delivery_location.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentUser => _auth.currentUser;

  Future<void> signIn({required String email, required String password}) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
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
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': cleanName,
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'role': 'customer',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (error) {
      // Avoid leaving an Auth account without its required customer profile.
      await user.delete();
      rethrow;
    }
  }

  Future<void> sendPasswordResetEmail(String email) {
    return _auth.sendPasswordResetEmail(email: email.trim());
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

  Future<void> signOut() => _auth.signOut();
}

String friendlyAuthError(Object error) {
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
