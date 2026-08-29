import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/international_phone_input.dart';
import '../controllers/phone_verification_controller.dart';
import '../services/auth_repository.dart';
import '../services/auth_service.dart';

Future<bool> showPhoneVerificationSheet(
  BuildContext context, {
  required PhoneVerificationClient client,
  String initialPhone = '',
  Duration resendDelay = const Duration(seconds: 60),
}) async {
  final controller = PhoneVerificationController(
    client: client,
    initialPhone: initialPhone,
    resendDelay: resendDelay,
    errorMapper: friendlyAuthError,
  );
  try {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => PhoneVerificationSheet(controller: controller),
    );
    return result ?? false;
  } finally {
    controller.dispose();
  }
}

class PhoneVerificationSheet extends StatefulWidget {
  const PhoneVerificationSheet({super.key, required this.controller});

  final PhoneVerificationController controller;

  @override
  State<PhoneVerificationSheet> createState() => _PhoneVerificationSheetState();
}

class _PhoneVerificationSheetState extends State<PhoneVerificationSheet> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  String _phoneNumber = '';
  String? _lastSubmittedCode;
  Timer? _successTimer;
  bool _allowExplicitPop = false;

  @override
  void initState() {
    super.initState();
    _phoneNumber = widget.controller.state.phoneNumber;
    widget.controller.addListener(_handleControllerChange);
    if (_phoneNumber.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) widget.controller.sendCode(_phoneNumber);
      });
    }
  }

  @override
  void dispose() {
    _successTimer?.cancel();
    widget.controller.removeListener(_handleControllerChange);
    _otpController.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  void _handleControllerChange() {
    if (!mounted) return;
    final state = widget.controller.state;
    setState(() {
      _phoneNumber = state.phoneNumber;
      if (state.phase == PhoneVerificationPhase.failure) {
        _lastSubmittedCode = null;
      }
    });
    if (state.phase == PhoneVerificationPhase.awaitingCode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _otpFocusNode.requestFocus();
      });
    }
    if (state.phase == PhoneVerificationPhase.verified &&
        _successTimer == null) {
      _successTimer = Timer(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() => _allowExplicitPop = true);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) Navigator.pop(context, true);
        });
      });
    }
  }

  void _cancel() {
    if (_allowExplicitPop) return;
    setState(() => _allowExplicitPop = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) Navigator.pop(context, false);
    });
  }

  void _changeNumber() {
    _otpController.clear();
    _lastSubmittedCode = null;
    widget.controller.changePhone();
  }

  void _handleOtpChanged(String value) {
    widget.controller.clearError();
    setState(() {});
    if (value.length == 6 && value != _lastSubmittedCode) {
      _lastSubmittedCode = value;
      widget.controller.verifyCode(value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.controller.state;
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final maxHeight = (screenHeight - keyboard - 24)
        .clamp(220.0, screenHeight * .82)
        .toDouble();
    final phoneEntry =
        state.phase == PhoneVerificationPhase.phoneEntry ||
        state.phase == PhoneVerificationPhase.sending ||
        (state.phase == PhoneVerificationPhase.failure &&
            state.verificationId == null);

    return PopScope(
      canPop: _allowExplicitPop,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(12, 12, 12, keyboard + 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.black12,
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFECEE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.phone_iphone_rounded,
                        color: AppColors.red,
                        size: 31,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      state.phase == PhoneVerificationPhase.verified
                          ? 'Phone verified'
                          : phoneEntry
                          ? 'Secure your account'
                          : 'Enter verification code',
                      textAlign: TextAlign.center,
                      style: AppTypography.sectionTitle.copyWith(
                        color: const Color(0xFF242426),
                      ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      state.phase == PhoneVerificationPhase.verified
                          ? 'Your number is securely linked to this account.'
                          : phoneEntry
                          ? 'We use this number to protect your account and contact you about deliveries.'
                          : 'We sent a 6-digit security code to ${state.maskedPhone}.',
                      textAlign: TextAlign.center,
                      style: AppTypography.body.copyWith(
                        color: const Color(0xFF6E6E73),
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (phoneEntry)
                      _buildPhoneEntry(state)
                    else if (state.phase == PhoneVerificationPhase.verified)
                      const _VerifiedMark()
                    else
                      _buildOtpEntry(state),
                    Semantics(
                      key: const ValueKey('phone-verification-status'),
                      liveRegion: true,
                      label: state.errorMessage ?? _statusLabel(state),
                      child: state.errorMessage == null
                          ? const SizedBox(height: 4)
                          : Container(
                              width: double.infinity,
                              margin: const EdgeInsets.only(top: 12),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFECEE),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                state.errorMessage!,
                                textAlign: TextAlign.center,
                                style: AppTypography.body.copyWith(
                                  color: AppColors.red,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneEntry(PhoneVerificationState state) {
    final sending = state.phase == PhoneVerificationPhase.sending;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InternationalPhoneInput(
          value: _phoneNumber,
          onChanged: (value) {
            widget.controller.clearError();
            _phoneNumber = value;
          },
          countrySelectorKey: const ValueKey(
            'phone-verification-country-selector',
          ),
          phoneFieldKey: const ValueKey('phone-verification-number-input'),
          autofocus: _phoneNumber.isEmpty,
          textInputAction: TextInputAction.done,
          fieldDecoration: InputDecoration(
            hintText: 'Phone number',
            filled: true,
            fillColor: const Color(0xFFF8F8FA),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE1E1E6)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE1E1E6)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Firebase/Google processes this number to send the security code and prevent abuse.',
          textAlign: TextAlign.center,
          style: AppTypography.body.copyWith(
            color: const Color(0xFF74747A),
            fontSize: 12,
          ),
        ),
        TextButton(
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.privacyAccount),
          child: const Text('VIEW PRIVACY DETAILS'),
        ),
        AppPrimaryButton(
          key: const ValueKey('phone-verification-send'),
          label: 'SEND SECURITY CODE',
          icon: Icons.sms_rounded,
          isLoading: sending,
          onPressed: sending
              ? null
              : () => widget.controller.sendCode(_phoneNumber),
        ),
        TextButton(
          key: const ValueKey('phone-verification-cancel'),
          onPressed: _cancel,
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  Widget _buildOtpEntry(PhoneVerificationState state) {
    final verifying = state.phase == PhoneVerificationPhase.verifying;
    final code = _otpController.text;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(6, (index) {
                final digit = index < code.length ? code[index] : '';
                final active = index == code.length && code.length < 6;
                return Expanded(
                  child: Container(
                    key: ValueKey('phone-otp-cell-$index'),
                    height: 54,
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 5),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: digit.isEmpty
                          ? const Color(0xFFF8F8FA)
                          : const Color(0xFFFFF4F5),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: active || digit.isNotEmpty
                            ? AppColors.red
                            : const Color(0xFFE1E1E6),
                        width: active ? 1.8 : 1,
                      ),
                    ),
                    child: Text(
                      digit,
                      style: AppTypography.sectionTitle.copyWith(
                        color: const Color(0xFF242426),
                      ),
                    ),
                  ),
                );
              }),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: .01,
                child: TextField(
                  key: const ValueKey('phone-otp-input'),
                  controller: _otpController,
                  focusNode: _otpFocusNode,
                  autofocus: true,
                  keyboardType: TextInputType.number,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  textInputAction: TextInputAction.done,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(6),
                  ],
                  onChanged: _handleOtpChanged,
                  onSubmitted: widget.controller.verifyCode,
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        AppPrimaryButton(
          key: const ValueKey('phone-otp-verify'),
          label: 'VERIFY',
          icon: Icons.verified_user_rounded,
          isLoading: verifying,
          onPressed: verifying || code.length != 6
              ? null
              : () => widget.controller.verifyCode(code),
        ),
        const SizedBox(height: 4),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            TextButton(
              key: const ValueKey('phone-otp-resend'),
              onPressed: state.canResend ? widget.controller.resendCode : null,
              child: Text(
                state.canResend
                    ? 'RESEND CODE'
                    : 'Resend in ${state.resendSeconds}s',
              ),
            ),
            TextButton(
              key: const ValueKey('phone-otp-change-number'),
              onPressed: verifying ? null : _changeNumber,
              child: const Text('CHANGE NUMBER'),
            ),
          ],
        ),
        TextButton(
          key: const ValueKey('phone-verification-cancel'),
          onPressed: verifying ? null : _cancel,
          child: const Text('CANCEL'),
        ),
      ],
    );
  }

  String _statusLabel(PhoneVerificationState state) {
    return switch (state.phase) {
      PhoneVerificationPhase.phoneEntry => 'Enter your phone number',
      PhoneVerificationPhase.sending => 'Sending security code',
      PhoneVerificationPhase.awaitingCode => 'Security code sent',
      PhoneVerificationPhase.verifying => 'Verifying security code',
      PhoneVerificationPhase.verified => 'Phone verified',
      PhoneVerificationPhase.failure => 'Phone verification needs attention',
    };
  }
}

class _VerifiedMark extends StatelessWidget {
  const _VerifiedMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: const BoxDecoration(
        color: Color(0xFFEAF8EF),
        shape: BoxShape.circle,
      ),
      child: const Icon(
        Icons.check_rounded,
        color: Color(0xFF218A52),
        size: 42,
      ),
    );
  }
}
