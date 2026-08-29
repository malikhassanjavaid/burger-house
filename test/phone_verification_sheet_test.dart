import 'package:country_picker/country_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_application_1/core/theme/app_theme.dart';
import 'package:flutter_application_1/features/auth/services/auth_repository.dart';
import 'package:flutter_application_1/features/auth/widgets/phone_verification_sheet.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('empty initial number starts with recoverable phone entry', (
    tester,
  ) async {
    final client = SheetFakePhoneClient();
    final result = await _openSheet(tester, client: client);

    expect(
      find.byKey(const ValueKey('phone-verification-number-input')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('phone-verification-send')));
    await tester.pump();
    expect(find.text('Enter a valid phone number'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('phone-verification-number-input')),
      '3001234567',
    );
    await tester.tap(find.byKey(const ValueKey('phone-verification-send')));
    await tester.pump();

    expect(client.sentPhones, const ['+923001234567']);
    expect(result, isNotNull);
  });

  testWidgets('six digit paste verifies and returns success once', (
    tester,
  ) async {
    final client = SheetFakePhoneClient();
    final result = await _openSheet(
      tester,
      client: client,
      initialPhone: '+923001234567',
    );
    expect(client.sentPhones, const ['+923001234567']);
    client.emitCodeSent('verification-1', 14);
    await tester.pump();

    expect(find.text('+923001234567'), findsNothing);
    expect(find.textContaining('+92 ••• ••• 4567'), findsOneWidget);
    expect(find.byKey(const ValueKey('phone-otp-cell-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('phone-otp-cell-5')), findsOneWidget);
    expect(find.text('Resend in 60s'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('phone-otp-input')),
      '123456',
    );
    await tester.pump();

    expect(client.confirmCount, 1);
    expect(client.confirmedCode, '123456');
    expect(find.text('Phone verified'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    expect(await result, isTrue);
  });

  testWidgets('change number and explicit cancel never grant verification', (
    tester,
  ) async {
    final client = SheetFakePhoneClient();
    final result = await _openSheet(
      tester,
      client: client,
      initialPhone: '+923001234567',
    );
    client.emitCodeSent('verification-1', 14);
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('phone-otp-change-number')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('phone-verification-number-input')),
      findsOneWidget,
    );
    final phoneField = tester.widget<TextFormField>(
      find.byKey(const ValueKey('phone-verification-number-input')),
    );
    expect(phoneField.controller?.text, '3001234567');
    expect(find.text('+92'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('phone-verification-cancel')));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets('OTP sheet is screen-reader live and keyboard-safe', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final semantics = tester.ensureSemantics();

    final client = SheetFakePhoneClient();
    await _openSheet(tester, client: client, initialPhone: '+923001234567');
    client.emitCodeSent('verification-1', 14);
    await tester.pump();

    final status = tester.getSemantics(
      find.byKey(const ValueKey('phone-verification-status')),
    );
    expect(status.flagsCollection.isLiveRegion, isTrue);
    semantics.dispose();
    expect(tester.takeException(), isNull);
    final cancel = find.byKey(const ValueKey('phone-verification-cancel'));
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
  });
}

Future<Future<bool>> _openSheet(
  WidgetTester tester, {
  required SheetFakePhoneClient client,
  String initialPhone = '',
}) async {
  Future<bool>? result;
  tester.platformDispatcher.localeTestValue = const Locale('en', 'PK');
  addTearDown(tester.platformDispatcher.clearLocaleTestValue);
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('en', 'PK'),
      localizationsDelegates: const [CountryLocalizations.delegate],
      supportedLocales: const [Locale('en', 'PK')],
      theme: AppTheme.light,
      home: Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              key: const ValueKey('open-verification'),
              onPressed: () {
                result = showPhoneVerificationSheet(
                  context,
                  client: client,
                  initialPhone: initialPhone,
                );
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('open-verification')));
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
  return result!;
}

final class SheetFakePhoneClient implements PhoneVerificationClient {
  final List<String> sentPhones = <String>[];
  void Function(String verificationId, int? resendToken)? codeSent;
  Future<void> Function()? automatic;
  void Function(Object error)? failed;
  int confirmCount = 0;
  String? confirmedCode;

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
    codeSent = onCodeSent;
    automatic = onAutomaticVerificationCompleted;
    failed = onVerificationFailed;
  }

  @override
  Future<void> confirmPhoneVerificationCode({
    required String verificationId,
    required String smsCode,
  }) async {
    confirmCount += 1;
    confirmedCode = smsCode;
  }

  void emitCodeSent(String verificationId, int? resendToken) {
    codeSent?.call(verificationId, resendToken);
  }
}
