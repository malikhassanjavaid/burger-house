import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/auth_repository.dart';

enum PhoneVerificationPhase {
  phoneEntry,
  sending,
  awaitingCode,
  verifying,
  verified,
  failure,
}

@immutable
class PhoneVerificationState {
  const PhoneVerificationState({
    required this.phase,
    this.phoneNumber = '',
    this.verificationId,
    this.resendToken,
    this.resendSeconds = 0,
    this.errorMessage,
  });

  final PhoneVerificationPhase phase;
  final String phoneNumber;
  final String? verificationId;
  final int? resendToken;
  final int resendSeconds;
  final String? errorMessage;

  bool get canResend {
    return verificationId != null &&
        resendSeconds == 0 &&
        phase != PhoneVerificationPhase.sending &&
        phase != PhoneVerificationPhase.verifying &&
        phase != PhoneVerificationPhase.verified;
  }

  String get maskedPhone {
    final value = phoneNumber.trim();
    if (value.length <= 7) return value;
    final prefixLength = value.startsWith('+') ? 3 : 2;
    final prefix = value.substring(0, prefixLength.clamp(0, value.length));
    final suffix = value.substring(value.length - 4);
    return '$prefix ••• ••• $suffix';
  }
}

class PhoneVerificationController extends ChangeNotifier {
  PhoneVerificationController({
    required PhoneVerificationClient client,
    String initialPhone = '',
    Duration resendDelay = const Duration(seconds: 60),
    String Function(Object error)? errorMapper,
  }) : // Keep public dependency-injection parameter names for callers.
       // ignore: prefer_initializing_formals
       _client = client,
       // ignore: prefer_initializing_formals
       _resendDelay = resendDelay,
       _errorMapper = errorMapper ?? _defaultErrorMapper,
       _state = PhoneVerificationState(
         phase: PhoneVerificationPhase.phoneEntry,
         phoneNumber: initialPhone.trim(),
       );

  final PhoneVerificationClient _client;
  final Duration _resendDelay;
  final String Function(Object error) _errorMapper;
  PhoneVerificationState _state;
  PhoneVerificationState get state => _state;

  Timer? _resendTimer;
  int _generation = 0;
  bool _operationInFlight = false;
  bool _completionClaimed = false;
  bool _disposed = false;

  Future<void> sendCode(String phoneNumber) {
    return _sendCode(phoneNumber.trim(), forceResendingToken: null);
  }

  Future<void> _sendCode(
    String phoneNumber, {
    required int? forceResendingToken,
  }) async {
    if (_operationInFlight || _completionClaimed) return;
    if (!RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(phoneNumber)) {
      _setState(
        PhoneVerificationState(
          phase: PhoneVerificationPhase.failure,
          phoneNumber: phoneNumber,
          errorMessage: 'Enter a valid phone number',
        ),
      );
      return;
    }

    _operationInFlight = true;
    _resendTimer?.cancel();
    final generation = ++_generation;
    _setState(
      PhoneVerificationState(
        phase: PhoneVerificationPhase.sending,
        phoneNumber: phoneNumber,
      ),
    );
    try {
      await _client.sendPhoneVerificationCode(
        phoneNumber: phoneNumber,
        forceResendingToken: forceResendingToken,
        onAutomaticVerificationCompleted: () async {
          if (!_isCurrent(generation)) return;
          _claimVerified();
        },
        onCodeSent: (verificationId, resendToken) {
          if (!_isCurrent(generation) || _completionClaimed) return;
          _setState(
            PhoneVerificationState(
              phase: PhoneVerificationPhase.awaitingCode,
              phoneNumber: phoneNumber,
              verificationId: verificationId,
              resendToken: resendToken,
              resendSeconds: _resendDelay.inSeconds,
            ),
          );
          _startResendCountdown(generation);
        },
        onVerificationFailed: (error) {
          if (!_isCurrent(generation) || _completionClaimed) return;
          _setState(
            PhoneVerificationState(
              phase: PhoneVerificationPhase.failure,
              phoneNumber: phoneNumber,
              verificationId: _state.verificationId,
              resendToken: _state.resendToken,
              resendSeconds: _state.resendSeconds,
              errorMessage: _errorMapper(error),
            ),
          );
        },
        onAutoRetrievalTimeout: (verificationId) {
          if (!_isCurrent(generation) || _completionClaimed) return;
          if (_state.verificationId == null) {
            _setState(
              PhoneVerificationState(
                phase: PhoneVerificationPhase.awaitingCode,
                phoneNumber: phoneNumber,
                verificationId: verificationId,
                resendToken: _state.resendToken,
                resendSeconds: _state.resendSeconds,
              ),
            );
          }
        },
      );
    } catch (error) {
      if (_isCurrent(generation) && !_completionClaimed) {
        _setState(
          PhoneVerificationState(
            phase: PhoneVerificationPhase.failure,
            phoneNumber: phoneNumber,
            errorMessage: _errorMapper(error),
          ),
        );
      }
    } finally {
      _operationInFlight = false;
    }
  }

  Future<void> verifyCode(String smsCode) async {
    if (_operationInFlight || _completionClaimed) return;
    final verificationId = _state.verificationId;
    if (smsCode.length != 6 || !RegExp(r'^\d{6}$').hasMatch(smsCode)) {
      _setState(
        PhoneVerificationState(
          phase: PhoneVerificationPhase.failure,
          phoneNumber: _state.phoneNumber,
          verificationId: verificationId,
          resendToken: _state.resendToken,
          resendSeconds: _state.resendSeconds,
          errorMessage: 'Enter the complete 6-digit code.',
        ),
      );
      return;
    }
    if (verificationId == null) return;

    _operationInFlight = true;
    final generation = _generation;
    _setState(
      PhoneVerificationState(
        phase: PhoneVerificationPhase.verifying,
        phoneNumber: _state.phoneNumber,
        verificationId: verificationId,
        resendToken: _state.resendToken,
        resendSeconds: _state.resendSeconds,
      ),
    );
    try {
      await _client.confirmPhoneVerificationCode(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      if (_isCurrent(generation)) _claimVerified();
    } catch (error) {
      if (_isCurrent(generation) && !_completionClaimed) {
        _setState(
          PhoneVerificationState(
            phase: PhoneVerificationPhase.failure,
            phoneNumber: _state.phoneNumber,
            verificationId: verificationId,
            resendToken: _state.resendToken,
            resendSeconds: _state.resendSeconds,
            errorMessage: _errorMapper(error),
          ),
        );
      }
    } finally {
      _operationInFlight = false;
    }
  }

  Future<void> resendCode() async {
    if (!state.canResend) return;
    await _sendCode(state.phoneNumber, forceResendingToken: state.resendToken);
  }

  void changePhone() {
    _generation += 1;
    _operationInFlight = false;
    _completionClaimed = false;
    _resendTimer?.cancel();
    _setState(
      PhoneVerificationState(
        phase: PhoneVerificationPhase.phoneEntry,
        phoneNumber: state.phoneNumber,
      ),
    );
  }

  void clearError() {
    if (state.errorMessage == null) return;
    _setState(
      PhoneVerificationState(
        phase: state.verificationId == null
            ? PhoneVerificationPhase.phoneEntry
            : PhoneVerificationPhase.awaitingCode,
        phoneNumber: state.phoneNumber,
        verificationId: state.verificationId,
        resendToken: state.resendToken,
        resendSeconds: state.resendSeconds,
      ),
    );
  }

  void _claimVerified() {
    if (_completionClaimed || _disposed) return;
    _completionClaimed = true;
    _resendTimer?.cancel();
    _setState(
      PhoneVerificationState(
        phase: PhoneVerificationPhase.verified,
        phoneNumber: state.phoneNumber,
        verificationId: state.verificationId,
        resendToken: state.resendToken,
      ),
    );
  }

  void _startResendCountdown(int generation) {
    _resendTimer?.cancel();
    if (_resendDelay.inSeconds <= 0) return;
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!_isCurrent(generation) || _completionClaimed) {
        timer.cancel();
        return;
      }
      final next = state.resendSeconds - 1;
      _setState(
        PhoneVerificationState(
          phase: state.phase,
          phoneNumber: state.phoneNumber,
          verificationId: state.verificationId,
          resendToken: state.resendToken,
          resendSeconds: next.clamp(0, _resendDelay.inSeconds),
          errorMessage: state.errorMessage,
        ),
      );
      if (next <= 0) timer.cancel();
    });
  }

  bool _isCurrent(int generation) => !_disposed && generation == _generation;

  void _setState(PhoneVerificationState value) {
    if (_disposed) return;
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    _resendTimer?.cancel();
    super.dispose();
  }

  static String _defaultErrorMapper(Object _) {
    return 'Phone verification failed. Please try again.';
  }
}
