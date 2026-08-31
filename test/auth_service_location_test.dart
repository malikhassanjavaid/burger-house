import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: depend_on_referenced_packages
import 'package:cloud_firestore_platform_interface/src/pigeon/messages.pigeon.dart'
    as firestore_pigeon;
import 'package:firebase_auth/firebase_auth.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_auth_platform_interface/firebase_auth_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:flutter/services.dart';
import 'package:flutter_application_1/features/auth/services/auth_service.dart';
import 'package:flutter_application_1/features/location/models/delivery_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();

  late FirebaseApp app;

  setUpAll(() async {
    app = await Firebase.initializeApp();
  });

  test('location save uses a create-capable write for new customers', () async {
    final previousAuthPlatform = FirebaseAuthPlatform.instance;
    FirebaseAuthPlatform.instance = _SignedInAuthPlatform(app);
    addTearDown(() => FirebaseAuthPlatform.instance = previousAuthPlatform);

    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
    const setChannel =
        'dev.flutter.pigeon.cloud_firestore_platform_interface.'
        'FirebaseFirestoreHostApi.documentReferenceSet';
    const updateChannel =
        'dev.flutter.pigeon.cloud_firestore_platform_interface.'
        'FirebaseFirestoreHostApi.documentReferenceUpdate';
    const codec = firestore_pigeon.FirebaseFirestoreHostApi.pigeonChannelCodec;
    var setCount = 0;
    var updateCount = 0;
    messenger.setMockMessageHandler(setChannel, (ByteData? message) async {
      setCount += 1;
      return codec.encodeMessage(<Object?>[null]);
    });
    messenger.setMockMessageHandler(updateChannel, (ByteData? message) async {
      updateCount += 1;
      return codec.encodeMessage(<Object?>[null]);
    });
    addTearDown(() {
      messenger.setMockMessageHandler(setChannel, null);
      messenger.setMockMessageHandler(updateChannel, null);
    });

    final service = AuthService(
      auth: FirebaseAuth.instanceFor(app: app),
      firestore: FirebaseFirestore.instanceFor(app: app),
    );

    await service.saveDeliveryLocation(_location);

    expect(setCount, 1);
    expect(updateCount, 0);
  });
}

const _location = DeliveryLocation(
  label: 'Home',
  area: 'Central',
  addressLine: '1 Test Street',
);

final class _SignedInAuthPlatform extends FirebaseAuthPlatform {
  _SignedInAuthPlatform(FirebaseApp app) : super(appInstance: app) {
    _currentUser = _SignedInUserPlatform(this);
  }

  late final UserPlatform _currentUser;

  @override
  FirebaseAuthPlatform delegateFor({required FirebaseApp app}) => this;

  @override
  FirebaseAuthPlatform setInitialValues({
    InternalUserDetails? currentUser,
    String? languageCode,
  }) => this;

  @override
  UserPlatform get currentUser => _currentUser;

  @override
  set currentUser(UserPlatform? userPlatform) {}

  @override
  String? get languageCode => null;
}

final class _SignedInUserPlatform extends UserPlatform {
  _SignedInUserPlatform(FirebaseAuthPlatform auth)
    : super(
        auth,
        _TestMultiFactorPlatform(auth),
        InternalUserDetails(
          userInfo: InternalUserInfo(
            uid: 'customer-1',
            isAnonymous: false,
            isEmailVerified: true,
          ),
          providerData: const <Map<Object?, Object?>?>[],
        ),
      );
}

final class _TestMultiFactorPlatform extends MultiFactorPlatform {
  _TestMultiFactorPlatform(super.auth);
}
