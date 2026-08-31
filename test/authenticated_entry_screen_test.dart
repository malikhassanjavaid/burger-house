import 'dart:async';

import 'package:country_picker/country_picker.dart';
import 'package:firebase_core/firebase_core.dart';
// ignore: depend_on_referenced_packages
import 'package:firebase_core_platform_interface/src/pigeon/mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/routes/app_routes.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/widgets/app_loader.dart';
import 'package:flutter_application_1/core/widgets/brand_logo.dart';
import 'package:flutter_application_1/features/auth/screens/authenticated_entry_screen.dart';
import 'package:flutter_application_1/features/auth/services/auth_repository.dart';
import 'package:flutter_application_1/features/location/models/delivery_location.dart';
import 'package:flutter_application_1/features/location/screens/location_setup_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setupFirebaseCoreMocks();
  setUpAll(Firebase.initializeApp);

  testWidgets('session resolution shows only the plain loading indicator', (
    tester,
  ) async {
    final pendingVerification = Completer<bool>();
    final repository = GateFakeAuthRepository(
      verificationStatus: pendingVerification.future,
    );

    await _pumpGate(tester, repository: repository);

    expect(find.byType(AppLoader), findsOneWidget);
    expect(find.byType(HungrySpotLogo), findsNothing);
    expect(find.textContaining('Securing your account'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    pendingVerification.complete(false);
    await tester.pump();
  });

  testWidgets('signed-out sessions return to login', (tester) async {
    final repository = GateFakeAuthRepository(hasUser: false);

    await _pumpGate(tester, repository: repository);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('login-destination')), findsOneWidget);
    expect(repository.syncCount, 0);
  });

  testWidgets('verified sessions start synchronization and enter home', (
    tester,
  ) async {
    final repository = GateFakeAuthRepository(
      verified: true,
      location: _savedLocation,
    );

    await _pumpGate(tester, repository: repository);
    await tester.pumpAndSettle();

    expect(repository.syncCount, 1);
    expect(repository.locationReadCount, 1);
    expect(find.byKey(const ValueKey('home-destination')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('phone-verification-number-input')),
      findsNothing,
    );
  });

  testWidgets('pending profile sync does not hold the entry loader open', (
    tester,
  ) async {
    final pendingProfileSync = Completer<void>();
    final repository = GateFakeAuthRepository(
      verified: true,
      location: _savedLocation,
      profileSync: pendingProfileSync.future,
    );

    await _pumpGate(tester, repository: repository);
    await tester.pumpAndSettle();

    expect(repository.syncCount, 1);
    expect(find.byKey(const ValueKey('home-destination')), findsOneWidget);
    expect(find.byType(AppLoader), findsNothing);

    pendingProfileSync.complete();
    await tester.pump();
  });

  testWidgets('unverified sessions must complete OTP before entering home', (
    tester,
  ) async {
    final repository = GateFakeAuthRepository(location: _savedLocation);

    await _pumpGate(
      tester,
      repository: repository,
      initialPhone: '+923001234567',
    );
    expect(repository.sentPhones, const ['+923001234567']);

    repository.emitCodeSent('verification-1', 22);
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey('phone-otp-input')),
      '123456',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pumpAndSettle();

    expect(repository.confirmCount, 1);
    expect(repository.syncCount, 1);
    expect(find.byKey(const ValueKey('home-destination')), findsOneWidget);
  });

  testWidgets('cancelling required verification signs out securely', (
    tester,
  ) async {
    final repository = GateFakeAuthRepository();

    await _pumpGate(
      tester,
      repository: repository,
      initialPhone: '+923001234567',
    );
    final cancel = find.byKey(const ValueKey('phone-verification-cancel'));
    final cancelButton = tester.widget<TextButton>(cancel);
    cancelButton.onPressed!();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(repository.signOutCount, 1);
    expect(repository.syncCount, 0);
    expect(find.byKey(const ValueKey('login-destination')), findsOneWidget);
  });

  testWidgets('verified sessions without a location enter location setup', (
    tester,
  ) async {
    final repository = GateFakeAuthRepository(verified: true);

    await _pumpGate(tester, repository: repository);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(find.byType(LocationSetupScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('home-destination')), findsNothing);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('profile sync failure does not revoke verified session', (
    tester,
  ) async {
    final repository = GateFakeAuthRepository(
      verified: true,
      location: _savedLocation,
      failSync: true,
    );

    await _pumpGate(tester, repository: repository);
    await tester.pumpAndSettle();

    expect(repository.syncCount, 1);
    expect(repository.locationReadCount, 1);
    expect(find.byKey(const ValueKey('home-destination')), findsOneWidget);
    await tester.pump(const Duration(seconds: 5));
  });
}

const _savedLocation = DeliveryLocation(
  label: 'Home',
  area: 'Central',
  addressLine: '1 Test Street',
);

Future<void> _pumpGate(
  WidgetTester tester, {
  required GateFakeAuthRepository repository,
  String initialPhone = '',
}) async {
  tester.platformDispatcher.localeTestValue = const Locale('en', 'PK');
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en', 'PK'),
      supportedLocales: const [Locale('en', 'PK')],
      localizationsDelegates: const [CountryLocalizations.delegate],
      routes: {
        AppRoutes.login: (_) => const Scaffold(
          key: ValueKey('login-destination'),
          body: Text('Login'),
        ),
        AppRoutes.home: (_) => const Scaffold(
          key: ValueKey('home-destination'),
          body: Text('Home'),
        ),
      },
      home: AuthenticatedEntryScreen(
        repository: repository,
        initialPhone: initialPhone,
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

final class GateFakeAuthRepository implements AuthRepository {
  GateFakeAuthRepository({
    this.hasUser = true,
    this.verified = false,
    this.location,
    this.failSync = false,
    this.verificationStatus,
    this.profileSync,
  });

  final bool hasUser;
  bool verified;
  final DeliveryLocation? location;
  final bool failSync;
  final Future<bool>? verificationStatus;
  final Future<void>? profileSync;
  final List<String> sentPhones = <String>[];
  void Function(String verificationId, int? resendToken)? _codeSent;
  int confirmCount = 0;
  int syncCount = 0;
  int signOutCount = 0;
  int locationReadCount = 0;

  @override
  bool get hasAuthenticatedUser => hasUser && signOutCount == 0;

  @override
  Future<bool> hasVerifiedPhoneSession() async =>
      verificationStatus == null ? verified : await verificationStatus!;

  @override
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    int? forceResendingToken,
    required Future<void> Function() onAutomaticVerificationCompleted,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(Object error) onVerificationFailed,
    required void Function(String verificationId) onAutoRetrievalTimeout,
  }) async {
    sentPhones.add(phoneNumber);
    _codeSent = onCodeSent;
  }

  @override
  Future<void> confirmPhoneVerificationCode({
    required String verificationId,
    required String smsCode,
  }) async {
    confirmCount += 1;
    verified = true;
  }

  void emitCodeSent(String verificationId, int? resendToken) {
    _codeSent?.call(verificationId, resendToken);
  }

  @override
  Future<void> syncVerifiedCustomerProfile() async {
    syncCount += 1;
    if (profileSync != null) await profileSync;
    if (failSync) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'unavailable',
        message: 'Offline',
      );
    }
  }

  @override
  Future<DeliveryLocation?> getDeliveryLocation() async {
    locationReadCount += 1;
    return location;
  }

  @override
  Future<void> signOut() async {
    signOutCount += 1;
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {}

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {}
}
