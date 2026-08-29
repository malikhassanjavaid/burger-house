import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/routes/app_routes.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/core/widgets/app_primary_button.dart';
import 'package:flutter_application_1/features/auth/screens/login_screen.dart';
import 'package:flutter_application_1/features/auth/screens/register_screen.dart';
import 'package:flutter_application_1/features/auth/services/auth_repository.dart';
import 'package:flutter_application_1/features/location/models/delivery_location.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('registration forwards the normalized phone into the gate', (
    tester,
  ) async {
    final repository = RouteFakeAuthRepository();
    await _pumpAuthScreen(
      tester,
      repository: repository,
      child: RegisterScreen(repository: repository),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Aisha Khan');
    await tester.enterText(fields.at(1), 'aisha@example.com');
    await tester.enterText(
      find.byKey(const ValueKey('signup-phone-number-input')),
      '3001234567',
    );
    await tester.enterText(fields.last, 'secure123');

    tester.widget<AppPrimaryButton>(find.byType(AppPrimaryButton)).onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.registerCount, 1);
    expect(repository.registeredPhone, '+923001234567');
    expect(repository.sentPhones, const ['+923001234567']);
    expect(
      find.byKey(const ValueKey('phone-verification-number-input')),
      findsOneWidget,
    );
    expect(find.text('Verify your Gmail'), findsNothing);
    await _cancelVerification(tester);
  });

  testWidgets('login always enters the shared phone gate before home', (
    tester,
  ) async {
    final repository = RouteFakeAuthRepository();
    await _pumpAuthScreen(
      tester,
      repository: repository,
      child: LoginScreen(repository: repository),
    );

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'customer@example.com');
    await tester.enterText(fields.at(1), 'secure123');
    tester.widget<AppPrimaryButton>(find.byType(AppPrimaryButton)).onPressed!();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(repository.signInCount, 1);
    expect(
      find.byKey(const ValueKey('phone-verification-number-input')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('home-destination')), findsNothing);
    expect(find.text('Gmail not verified'), findsNothing);
    await _cancelVerification(tester);
  });
}

Future<void> _pumpAuthScreen(
  WidgetTester tester, {
  required RouteFakeAuthRepository repository,
  required Widget child,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = const Size(390, 844);
  tester.platformDispatcher.localeTestValue = const Locale('en', 'PK');
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  await tester.pumpWidget(
    MaterialApp(
      theme: AppTheme.light,
      locale: const Locale('en', 'PK'),
      supportedLocales: const [Locale('en', 'PK')],
      localizationsDelegates: const [CountryLocalizations.delegate],
      routes: {
        AppRoutes.login: (_) => const Scaffold(body: Text('Login route')),
        AppRoutes.home: (_) => const Scaffold(
          key: ValueKey('home-destination'),
          body: Text('Home'),
        ),
      },
      home: child,
    ),
  );
  await tester.pump();
}

Future<void> _cancelVerification(WidgetTester tester) async {
  final cancel = find.byKey(const ValueKey('phone-verification-cancel'));
  tester.widget<TextButton>(cancel).onPressed!();
  await tester.pump();
  await tester.pumpAndSettle();
}

final class RouteFakeAuthRepository implements AuthRepository {
  bool authenticated = false;
  int registerCount = 0;
  int signInCount = 0;
  int signOutCount = 0;
  String? registeredPhone;
  final List<String> sentPhones = <String>[];

  @override
  bool get hasAuthenticatedUser => authenticated;

  @override
  Future<void> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    registerCount += 1;
    registeredPhone = phone;
    authenticated = true;
  }

  @override
  Future<void> signIn({required String email, required String password}) async {
    signInCount += 1;
    authenticated = true;
  }

  @override
  Future<void> signOut() async {
    signOutCount += 1;
    authenticated = false;
  }

  @override
  Future<bool> hasVerifiedPhoneSession() async => false;

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
  }

  @override
  Future<void> confirmPhoneVerificationCode({
    required String verificationId,
    required String smsCode,
  }) async {}

  @override
  Future<void> syncVerifiedCustomerProfile() async {}

  @override
  Future<DeliveryLocation?> getDeliveryLocation() async => null;
}
