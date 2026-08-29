import 'dart:async';

import 'package:flutter_application_1/features/auth/controllers/phone_verification_controller.dart';
import 'package:flutter_application_1/features/auth/services/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('code-sent callback moves a send into the OTP phase', () async {
    final client = FakePhoneVerificationClient();
    final controller = PhoneVerificationController(
      client: client,
      errorMapper: (_) => 'Verification failed',
    );
    addTearDown(controller.dispose);

    await controller.sendCode('+923001234567');
    expect(controller.state.phase, PhoneVerificationPhase.sending);
    expect(client.sentPhones, const ['+923001234567']);

    client.emitCodeSent('verification-1', 42);

    expect(controller.state.phase, PhoneVerificationPhase.awaitingCode);
    expect(controller.state.resendSeconds, 60);
    expect(controller.state.maskedPhone, '+92 ••• ••• 4567');
  });

  test('manual verification requires exactly six digits', () async {
    final client = FakePhoneVerificationClient();
    final controller = PhoneVerificationController(
      client: client,
      errorMapper: (_) => 'Verification failed',
    );
    addTearDown(controller.dispose);
    await controller.sendCode('+923001234567');
    client.emitCodeSent('verification-1', 7);

    await controller.verifyCode('1234');

    expect(client.confirmCount, 0);
    expect(controller.state.phase, PhoneVerificationPhase.failure);
    expect(controller.state.errorMessage, 'Enter the complete 6-digit code.');
  });

  test('a valid manual code reaches verified exactly once', () async {
    final client = FakePhoneVerificationClient();
    final controller = PhoneVerificationController(
      client: client,
      errorMapper: (_) => 'Verification failed',
    );
    addTearDown(controller.dispose);
    var verifiedTransitions = 0;
    controller.addListener(() {
      if (controller.state.phase == PhoneVerificationPhase.verified) {
        verifiedTransitions += 1;
      }
    });
    await controller.sendCode('+923001234567');
    client.emitCodeSent('verification-1', 7);

    await controller.verifyCode('123456');

    expect(client.confirmCount, 1);
    expect(client.confirmedVerificationId, 'verification-1');
    expect(client.confirmedCode, '123456');
    expect(controller.state.phase, PhoneVerificationPhase.verified);
    expect(verifiedTransitions, 1);
  });

  testWidgets('resend stays locked for sixty seconds', (tester) async {
    final client = FakePhoneVerificationClient();
    final controller = PhoneVerificationController(
      client: client,
      errorMapper: (_) => 'Verification failed',
    );
    addTearDown(controller.dispose);
    await controller.sendCode('+923001234567');
    client.emitCodeSent('verification-1', 31);

    await controller.resendCode();
    expect(client.sendCount, 1);

    await tester.pump(const Duration(seconds: 60));
    expect(controller.state.canResend, isTrue);
    await controller.resendCode();
    expect(client.sendCount, 2);
    expect(client.lastForceResendingToken, 31);
  });

  test('changing the phone ignores callbacks from the old send', () async {
    final client = FakePhoneVerificationClient();
    final controller = PhoneVerificationController(
      client: client,
      errorMapper: (_) => 'Verification failed',
    );
    addTearDown(controller.dispose);
    await controller.sendCode('+923001234567');
    final staleCodeSent = client.codeSent;

    controller.changePhone();
    staleCodeSent?.call('stale-verification', 9);

    expect(controller.state.phase, PhoneVerificationPhase.phoneEntry);
    expect(controller.state.verificationId, isNull);
  });

  test(
    'automatic verification wins a race without duplicate completion',
    () async {
      final client = FakePhoneVerificationClient();
      final pendingManual = Completer<void>();
      client.confirmCompleter = pendingManual;
      final controller = PhoneVerificationController(
        client: client,
        errorMapper: (_) => 'Verification failed',
      );
      addTearDown(controller.dispose);
      var verifiedTransitions = 0;
      controller.addListener(() {
        if (controller.state.phase == PhoneVerificationPhase.verified) {
          verifiedTransitions += 1;
        }
      });
      await controller.sendCode('+923001234567');
      client.emitCodeSent('verification-1', 7);

      final manual = controller.verifyCode('123456');
      await client.emitAutomaticVerification();
      pendingManual.complete();
      await manual;

      expect(controller.state.phase, PhoneVerificationPhase.verified);
      expect(verifiedTransitions, 1);
    },
  );

  test('provider failures keep the flow recoverable', () async {
    final client = FakePhoneVerificationClient();
    final controller = PhoneVerificationController(
      client: client,
      errorMapper: (_) => 'Request a new code and try again.',
    );
    addTearDown(controller.dispose);
    await controller.sendCode('+923001234567');

    client.emitFailure(StateError('quota'));

    expect(controller.state.phase, PhoneVerificationPhase.failure);
    expect(controller.state.errorMessage, 'Request a new code and try again.');
    expect(controller.state.phoneNumber, '+923001234567');
  });
}

final class FakePhoneVerificationClient implements PhoneVerificationClient {
  void Function(String verificationId, int? resendToken)? codeSent;
  Future<void> Function()? automatic;
  void Function(Object error)? failed;
  final List<String> sentPhones = <String>[];
  int? lastForceResendingToken;
  int confirmCount = 0;
  String? confirmedVerificationId;
  String? confirmedCode;
  Completer<void>? confirmCompleter;

  int get sendCount => sentPhones.length;

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
    lastForceResendingToken = forceResendingToken;
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
    confirmedVerificationId = verificationId;
    confirmedCode = smsCode;
    final completer = confirmCompleter;
    if (completer != null) await completer.future;
  }

  void emitCodeSent(String verificationId, int? resendToken) {
    codeSent?.call(verificationId, resendToken);
  }

  Future<void> emitAutomaticVerification() async {
    await automatic?.call();
  }

  void emitFailure(Object error) {
    failed?.call(error);
  }
}
