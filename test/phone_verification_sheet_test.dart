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
    expect(
      find.byKey(const ValueKey('phone-verification-security-art')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('phone-verification-privacy-notice')),
      findsOneWidget,
    );
    expect(find.text('Continue'), findsOneWidget);
    final send = find.byKey(const ValueKey('phone-verification-send'));
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pump();
    expect(find.text('Enter a valid phone number'), findsOneWidget);

    await tester.enterText(
      find.byKey(const ValueKey('phone-verification-number-input')),
      '3001234567',
    );
    await tester.ensureVisible(send);
    await tester.tap(send);
    await tester.pump();

    expect(client.sentPhones, const ['+923001234567']);
    expect(result, isNotNull);
  });

  testWidgets('phone entry aligns the painted input surfaces', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final client = SheetFakePhoneClient();
    final result = await _openSheet(tester, client: client);
    final country = find.byKey(
      const ValueKey('phone-verification-country-selector'),
    );
    final phone = find.byKey(const ValueKey('phone-verification-number-input'));
    final countrySize = tester.getSize(country);
    final phoneEditable = find.descendant(
      of: phone,
      matching: find.byType(EditableText),
    );
    final phoneDecorator = tester.widget<InputDecorator>(
      find.descendant(of: phone, matching: find.byType(InputDecorator)),
    );
    final phoneSize = InputDecorator.containerOf(
      tester.element(phoneEditable),
    )!.size;

    expect(
      tester.getSize(
        find.byKey(const ValueKey('phone-verification-security-art')),
      ),
      const Size.square(118),
    );
    expect(phoneDecorator.decoration.counterText, isNull);
    expect(countrySize.height, closeTo(52, .01));
    expect(phoneSize.height, closeTo(countrySize.height, .01));
    expect(phoneSize.width, greaterThan(countrySize.width * 1.65));
    expect(
      tester
          .getSize(find.byKey(const ValueKey('phone-verification-send')))
          .height,
      closeTo(58, .01),
    );

    final cancel = find.byKey(const ValueKey('phone-verification-cancel'));
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets('phone entry compacts only while the keyboard is open', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    final client = SheetFakePhoneClient();
    final result = await _openSheet(tester, client: client);
    const keyboardTop = 844.0 - 300.0;
    final art = find.byKey(const ValueKey('phone-verification-security-art'));

    expect(tester.getSize(art), const Size.square(72));
    _expectVisibleAboveKeyboard(
      tester,
      keyboardTop: keyboardTop,
      finders: [
        art,
        find.byKey(const ValueKey('phone-verification-country-selector')),
        find.byKey(const ValueKey('phone-verification-number-input')),
        find.byKey(const ValueKey('phone-verification-privacy-notice')),
        find.text('View privacy details'),
        find.byKey(const ValueKey('phone-verification-send')),
        find.byKey(const ValueKey('phone-verification-cancel')),
      ],
    );

    final country = tester.getSize(
      find.byKey(const ValueKey('phone-verification-country-selector')),
    );
    final phone = tester.getSize(
      find.byKey(const ValueKey('phone-verification-number-input')),
    );
    final compactPhoneEditable = find.descendant(
      of: find.byKey(const ValueKey('phone-verification-number-input')),
      matching: find.byType(EditableText),
    );
    final compactPhoneSurface = InputDecorator.containerOf(
      tester.element(compactPhoneEditable),
    )!.size;
    expect(country.height, closeTo(46, .01));
    expect(compactPhoneSurface.height, closeTo(country.height, .01));
    expect(phone.width, greaterThan(country.width * 1.8));
    for (final action in [
      find.byKey(const ValueKey('phone-verification-privacy-details')),
      find.byKey(const ValueKey('phone-verification-send')),
      find.byKey(const ValueKey('phone-verification-cancel')),
    ]) {
      expect(
        tester.getSize(action).height,
        greaterThanOrEqualTo(44),
        reason: '${action.toString()} must retain a 44px tap target',
      );
    }

    await tester.tap(find.byKey(const ValueKey('phone-verification-cancel')));
    await tester.pumpAndSettle();
    expect(await result, isFalse);
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

    expect(
      find.byKey(const ValueKey('phone-verification-otp-surface')),
      findsOneWidget,
    );
    expect(find.text('+923001234567'), findsNothing);
    expect(find.textContaining('+92 ••• ••• 4567'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('phone-otp-security-art')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('phone-otp-security-art'))),
      const Size.square(124),
    );
    expect(find.byKey(const ValueKey('phone-otp-cell-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('phone-otp-cell-5')), findsOneWidget);
    double cellSurfaceWidth(int index) => tester
        .getSize(
          find
              .descendant(
                of: find.byKey(ValueKey('phone-otp-cell-$index')),
                matching: find.byType(DecoratedBox),
              )
              .first,
        )
        .width;

    final firstCellWidth = cellSurfaceWidth(0);
    for (var index = 1; index < 6; index++) {
      expect(cellSurfaceWidth(index), closeTo(firstCellWidth, .01));
    }
    expect(
      tester.getSize(find.byKey(const ValueKey('phone-otp-cell-0'))).height,
      closeTo(52, .01),
    );
    expect(find.text('Verify'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('phone-otp-resend-panel')),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('phone-otp-verify'))).height,
      closeTo(48, .01),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('phone-otp-resend-panel')))
          .height,
      closeTo(46, .01),
    );
    expect(find.byIcon(Icons.access_time_rounded), findsOneWidget);
    expect(find.text('Resend code in 60s'), findsOneWidget);

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

    final cancel = find.byKey(const ValueKey('phone-verification-cancel'));
    await tester.ensureVisible(cancel);
    await tester.tap(cancel);
    await tester.pumpAndSettle();
    expect(await result, isFalse);
  });

  testWidgets('OTP entry compacts and remains fully visible above keyboard', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    tester.view.viewInsets = const FakeViewPadding(bottom: 300);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    final client = SheetFakePhoneClient();
    final result = await _openSheet(
      tester,
      client: client,
      initialPhone: '+923001234567',
    );
    client.emitCodeSent('verification-1', 14);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 350));

    const keyboardTop = 844.0 - 300.0;
    final art = find.byKey(const ValueKey('phone-otp-security-art'));
    expect(tester.getSize(art), const Size.square(72));
    expect(
      tester.getSize(find.byKey(const ValueKey('phone-otp-cell-0'))).height,
      closeTo(44, .01),
    );
    expect(
      tester.getSize(find.byKey(const ValueKey('phone-otp-verify'))).height,
      closeTo(44, .01),
    );
    expect(
      tester
          .getSize(find.byKey(const ValueKey('phone-otp-resend-panel')))
          .height,
      closeTo(46, .01),
    );
    _expectVisibleAboveKeyboard(
      tester,
      keyboardTop: keyboardTop,
      finders: [
        art,
        find.text('Enter verification code'),
        find.byKey(const ValueKey('phone-otp-cell-0')),
        find.byKey(const ValueKey('phone-otp-verify')),
        find.byKey(const ValueKey('phone-otp-resend-panel')),
        find.byKey(const ValueKey('phone-verification-cancel')),
      ],
    );
    for (final action in [
      find.byKey(const ValueKey('phone-otp-verify')),
      find.byKey(const ValueKey('phone-otp-resend')),
      find.byKey(const ValueKey('phone-otp-change-number')),
      find.byKey(const ValueKey('phone-verification-cancel')),
    ]) {
      expect(
        tester.getSize(action).height,
        greaterThanOrEqualTo(44),
        reason: '${action.toString()} must retain a 44px tap target',
      );
    }

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

  testWidgets(
    'phone entry remains scroll-usable with keyboard and large text',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 640);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final client = SheetFakePhoneClient();
      final result = await _openSheet(tester, client: client);
      final send = find.byKey(const ValueKey('phone-verification-send'));
      final cancel = find.byKey(const ValueKey('phone-verification-cancel'));

      await tester.ensureVisible(send);
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(cancel);
      await tester.tap(cancel);
      await tester.pumpAndSettle();
      expect(await result, isFalse);
    },
  );
}

void _expectVisibleAboveKeyboard(
  WidgetTester tester, {
  required double keyboardTop,
  required List<Finder> finders,
}) {
  for (final finder in finders) {
    expect(finder, findsOneWidget);
    final rect = tester.getRect(finder);
    expect(
      rect.top,
      greaterThanOrEqualTo(0),
      reason: '${finder.toString()} is cut off above the viewport',
    );
    expect(
      rect.bottom,
      lessThanOrEqualTo(keyboardTop),
      reason: '${finder.toString()} is hidden behind the keyboard',
    );
  }
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
