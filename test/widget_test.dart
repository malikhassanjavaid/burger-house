import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/app.dart';
import 'package:flutter_application_1/core/routes/app_routes.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/widgets/brand_logo.dart';
import 'package:flutter_application_1/features/auth/services/auth_repository.dart';
import 'package:flutter_application_1/features/location/models/delivery_location.dart';
import 'package:flutter_application_1/features/splash/screens/splash_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Hungry Spot starts on a plain centered splash screen', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(const HungrySpotApp());
    await tester.pump(const Duration(milliseconds: 700));

    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    final logoRect = tester.getRect(find.byType(HungrySpotLogo));

    expect(scaffold.backgroundColor, Colors.white);
    expect(find.byType(HungrySpotLogo), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(logoRect.center.dx, closeTo(195, .5));
    expect(logoRect.center.dy, closeTo(422, .5));
    expect(logoRect.width, inInclusiveRange(248, 292));
    expect(tester.takeException(), isNull);
  });

  testWidgets('restored unverified session enters phone gate, never home', (
    tester,
  ) async {
    final repository = SplashFakeAuthRepository();
    tester.platformDispatcher.localeTestValue = const Locale('en', 'PK');
    addTearDown(tester.platformDispatcher.clearLocaleTestValue);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        locale: const Locale('en', 'PK'),
        supportedLocales: const [Locale('en', 'PK')],
        localizationsDelegates: const [CountryLocalizations.delegate],
        routes: {
          AppRoutes.login: (_) => const Scaffold(body: Text('Login')),
          AppRoutes.home: (_) => const Scaffold(
            key: ValueKey('home-destination'),
            body: Text('Home'),
          ),
        },
        home: SplashScreen(
          repository: repository,
          splashDuration: Duration.zero,
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    expect(
      find.byKey(const ValueKey('phone-verification-number-input')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home-destination')), findsNothing);

    final cancel = find.byKey(const ValueKey('phone-verification-cancel'));
    tester.widget<TextButton>(cancel).onPressed!();
    await tester.pump();
    await tester.pumpAndSettle();
  });
}

final class SplashFakeAuthRepository implements AuthRepository {
  bool authenticated = true;

  @override
  bool get hasAuthenticatedUser => authenticated;
  @override
  Future<bool> hasVerifiedPhoneSession() async => false;

  @override
  Future<void> signOut() async {
    authenticated = false;
  }

  @override
  Future<void> sendPhoneVerificationCode({
    required String phoneNumber,
    int? forceResendingToken,
    required Future<void> Function() onAutomaticVerificationCompleted,
    required void Function(String verificationId, int? resendToken) onCodeSent,
    required void Function(Object error) onVerificationFailed,
    required void Function(String verificationId) onAutoRetrievalTimeout,
  }) async {}

  @override
  Future<void> confirmPhoneVerificationCode({
    required String verificationId,
    required String smsCode,
  }) async {}

  @override
  Future<void> syncVerifiedCustomerProfile() async {}

  @override
  Future<DeliveryLocation?> getDeliveryLocation() async => null;

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
