import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_pressable.dart';
import '../../../core/widgets/international_phone_input.dart';
import '../controllers/phone_verification_controller.dart';
import '../services/auth_repository.dart';
import '../services/auth_service.dart';

Future<bool> showPhoneVerificationSheet(
  BuildContext context, {
  required PhoneVerificationClient client,
  String initialPhone = '',
  String? initialCountryCode,
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
      barrierColor: Colors.black.withValues(alpha: .72),
      builder: (_) => PhoneVerificationSheet(
        controller: controller,
        initialCountryCode: initialCountryCode,
      ),
    );
    return result ?? false;
  } finally {
    controller.dispose();
  }
}

class PhoneVerificationSheet extends StatefulWidget {
  const PhoneVerificationSheet({
    super.key,
    required this.controller,
    this.initialCountryCode,
  });

  final PhoneVerificationController controller;
  final String? initialCountryCode;

  @override
  State<PhoneVerificationSheet> createState() => _PhoneVerificationSheetState();
}

class _PhoneVerificationSheetState extends State<PhoneVerificationSheet> {
  final _otpController = TextEditingController();
  final _otpFocusNode = FocusNode();
  String _phoneNumber = '';
  String? _selectedCountryCode;
  String? _lastSubmittedCode;
  Timer? _successTimer;
  bool _allowExplicitPop = false;

  @override
  void initState() {
    super.initState();
    _phoneNumber = widget.controller.state.phoneNumber;
    _selectedCountryCode = widget.initialCountryCode;
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
    final compactForKeyboard = keyboard > 0;
    final maxHeight = compactForKeyboard
        ? (screenHeight - keyboard - 8)
              .clamp(0.0, screenHeight * .92)
              .toDouble()
        : (screenHeight - 18).clamp(280.0, screenHeight * .92).toDouble();
    final phoneEntry =
        state.phase == PhoneVerificationPhase.phoneEntry ||
        state.phase == PhoneVerificationPhase.sending ||
        (state.phase == PhoneVerificationPhase.failure &&
            state.verificationId == null);
    final otpEntry =
        !phoneEntry && state.phase != PhoneVerificationPhase.verified;

    return PopScope(
      canPop: _allowExplicitPop,
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            10,
            compactForKeyboard ? 4 : 8,
            10,
            keyboard + (compactForKeyboard ? 4 : 10),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  compactForKeyboard
                      ? (otpEntry ? 24 : 18)
                      : (otpEntry ? 39 : 24),
                  compactForKeyboard ? 8 : 14,
                  compactForKeyboard
                      ? (otpEntry ? 24 : 18)
                      : (otpEntry ? 39 : 24),
                  compactForKeyboard ? 8 : (otpEntry ? 37 : 14),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: otpEntry ? 36 : 46,
                      height: 5,
                      decoration: BoxDecoration(
                        color: otpEntry
                            ? const Color(0xFFF9D9DE)
                            : const Color(0xFFD5D5D9),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    SizedBox(
                      height: compactForKeyboard ? 6 : (otpEntry ? 12 : 14),
                    ),
                    if (otpEntry)
                      _OtpSecurityArtwork(compact: compactForKeyboard)
                    else
                      _SecurityArtwork(compact: compactForKeyboard),
                    SizedBox(
                      height: compactForKeyboard ? 4 : (otpEntry ? 6 : 10),
                    ),
                    Text(
                      state.phase == PhoneVerificationPhase.verified
                          ? 'Phone verified'
                          : phoneEntry
                          ? 'Secure your account'
                          : 'Enter verification code',
                      textAlign: TextAlign.center,
                      style: AppTypography.pageHeader.copyWith(
                        color: const Color(0xFF242426),
                        fontSize: compactForKeyboard
                            ? (otpEntry ? 18 : 20)
                            : (otpEntry ? 20 : 24),
                        fontWeight: otpEntry
                            ? FontWeight.w700
                            : FontWeight.w800,
                      ),
                    ),
                    SizedBox(
                      height: compactForKeyboard ? 3 : (otpEntry ? 6 : 8),
                    ),
                    if (otpEntry)
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'We sent a 6-digit security code to',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: const Color(0xFF6E6E73),
                              fontSize: compactForKeyboard ? 11.5 : 13,
                              height: compactForKeyboard ? 1.25 : 1.35,
                            ),
                          ),
                          SizedBox(height: compactForKeyboard ? 0 : 2),
                          Text(
                            '${state.maskedPhone}.',
                            textAlign: TextAlign.center,
                            style: AppTypography.body.copyWith(
                              color: const Color(0xFF626269),
                              fontSize: compactForKeyboard ? 11.5 : 13,
                              height: compactForKeyboard ? 1.25 : 1.35,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      )
                    else
                      Text(
                        state.phase == PhoneVerificationPhase.verified
                            ? 'Your number is securely linked to this account.'
                            : 'We use this number to protect your account and contact you about deliveries.',
                        textAlign: TextAlign.center,
                        style: AppTypography.body.copyWith(
                          color: const Color(0xFF6E6E73),
                          fontSize: compactForKeyboard ? 12 : 14,
                          height: compactForKeyboard ? 1.32 : 1.42,
                        ),
                      ),
                    SizedBox(height: compactForKeyboard ? 8 : 18),
                    if (phoneEntry)
                      _buildPhoneEntry(state, compact: compactForKeyboard)
                    else if (state.phase == PhoneVerificationPhase.verified)
                      const _VerifiedMark()
                    else
                      _buildOtpEntry(state, compact: compactForKeyboard),
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
                    if (state.phase != PhoneVerificationPhase.verified) ...[
                      SizedBox(
                        height: compactForKeyboard ? 0 : (otpEntry ? 0 : 4),
                      ),
                      TextButton(
                        key: const ValueKey('phone-verification-cancel'),
                        onPressed:
                            state.phase == PhoneVerificationPhase.verifying
                            ? null
                            : _cancel,
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF4F4F55),
                          minimumSize: Size(
                            0,
                            compactForKeyboard ? 44 : (otpEntry ? 36 : 40),
                          ),
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: compactForKeyboard ? 3 : 6,
                          ),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          textStyle: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: compactForKeyboard
                                ? (otpEntry ? 10 : 13)
                                : (otpEntry ? 11.5 : 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: compactForKeyboard
                                ? (otpEntry ? 9.5 : 13)
                                : (otpEntry ? 10 : 16),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneEntry(
    PhoneVerificationState state, {
    required bool compact,
  }) {
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
          defaultCountryCode: _selectedCountryCode,
          onCountryChanged: (country) {
            _selectedCountryCode = country.countryCode;
          },
          autofocus: _phoneNumber.isEmpty,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) {
            if (!sending) widget.controller.sendCode(_phoneNumber);
          },
          countryWidth: compact ? 94 : 104,
          countryHeight: compact ? 46 : 52,
          phoneFieldHeight: compact ? 46 : 52,
          fieldGap: compact ? 6 : 8,
          countryBorderRadius: compact ? 12 : 14,
          countryBorderColor: const Color(0xFFDADAE0),
          flagTextStyle: TextStyle(fontSize: compact ? 19 : 21),
          countryCodeTextStyle: TextStyle(
            color: const Color(0xFF202026),
            fontSize: compact ? 14 : 15,
            fontWeight: FontWeight.w700,
          ),
          textStyle: TextStyle(
            color: const Color(0xFF202026),
            fontSize: compact ? 15 : 16.5,
            fontWeight: FontWeight.w600,
          ),
          fieldDecoration: InputDecoration(
            hintText: 'Phone number',
            filled: true,
            fillColor: Colors.white,
            prefixIcon: const Icon(
              Icons.phone_outlined,
              color: Color(0xFF85858E),
              size: 22,
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: 48,
              minHeight: compact ? 46 : 52,
            ),
            contentPadding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
              borderSide: const BorderSide(color: Color(0xFFDADAE0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
              borderSide: const BorderSide(color: Color(0xFFDADAE0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(compact ? 12 : 14),
              borderSide: const BorderSide(color: AppColors.red, width: 1.6),
            ),
          ),
        ),
        SizedBox(height: compact ? 7 : 12),
        _PrivacyNotice(compact: compact),
        SizedBox(height: compact ? 2 : 6),
        TextButton(
          key: const ValueKey('phone-verification-privacy-details'),
          onPressed: () =>
              Navigator.pushNamed(context, AppRoutes.privacyAccount),
          style: TextButton.styleFrom(
            foregroundColor: AppColors.red,
            minimumSize: Size(0, compact ? 44 : 36),
            padding: EdgeInsets.symmetric(
              horizontal: 10,
              vertical: compact ? 3 : 6,
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('View privacy details'),
                SizedBox(width: 7),
                Icon(Icons.arrow_forward_ios_rounded, size: 15),
              ],
            ),
          ),
        ),
        SizedBox(height: compact ? 2 : 4),
        _VerificationActionButton(
          key: const ValueKey('phone-verification-send'),
          label: 'Continue',
          leadingIcon: Icons.lock_rounded,
          loading: sending,
          compact: compact,
          onPressed: sending
              ? null
              : () => widget.controller.sendCode(_phoneNumber),
        ),
      ],
    );
  }

  Widget _buildOtpEntry(PhoneVerificationState state, {required bool compact}) {
    final verifying = state.phase == PhoneVerificationPhase.verifying;
    final code = _otpController.text;
    final resendLabel = state.canResend
        ? 'Resend code'
        : 'Resend code in ${state.resendSeconds}s';
    return Container(
      key: const ValueKey('phone-verification-otp-surface'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 0; index < 6; index++) ...[
                    if (index > 0) SizedBox(width: compact ? 5 : 7),
                    Expanded(child: _buildOtpCell(index, code, compact)),
                  ],
                ],
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
          SizedBox(height: compact ? 10 : 18),
          _OtpVerificationButton(
            key: const ValueKey('phone-otp-verify'),
            loading: verifying,
            compact: compact,
            onPressed: verifying || code.length != 6
                ? null
                : () => widget.controller.verifyCode(code),
          ),
          SizedBox(height: compact ? 10 : 18),
          Container(
            key: const ValueKey('phone-otp-resend-panel'),
            width: double.infinity,
            height: 46,
            padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7F8),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFE2E5)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: Semantics(
                    button: true,
                    enabled: state.canResend,
                    label: resendLabel,
                    child: TextButton(
                      key: const ValueKey('phone-otp-resend'),
                      onPressed: state.canResend
                          ? widget.controller.resendCode
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.red,
                        disabledForegroundColor: const Color(0xFF74747C),
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 44),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.access_time_rounded,
                              color: AppColors.red,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            if (state.canResend)
                              const Text(
                                'Resend code',
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: AppColors.red,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              )
                            else
                              Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    color: Color(0xFF74747C),
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  children: [
                                    const TextSpan(text: 'Resend code in '),
                                    TextSpan(
                                      text: '${state.resendSeconds}s',
                                      style: const TextStyle(
                                        color: AppColors.red,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: compact ? 24 : 28,
                  margin: EdgeInsets.symmetric(horizontal: compact ? 7 : 10),
                  color: const Color(0xFFE2E2E6),
                ),
                Expanded(
                  flex: 4,
                  child: TextButton(
                    key: const ValueKey('phone-otp-change-number'),
                    onPressed: verifying ? null : _changeNumber,
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.red,
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 44),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      textStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('Change number'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOtpCell(int index, String code, bool compact) {
    final digit = index < code.length ? code[index] : '';
    final active = index == code.length && code.length < 6;
    return Container(
      key: ValueKey('phone-otp-cell-$index'),
      height: compact ? 44 : 52,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active || digit.isNotEmpty
            ? Colors.white
            : const Color(0xFFFAFAFB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: active || digit.isNotEmpty
              ? AppColors.red
              : const Color(0xFFE1E1E5),
          width: active ? 1.3 : 1,
        ),
      ),
      child: digit.isNotEmpty
          ? Text(
              digit,
              style: AppTypography.sectionTitle.copyWith(
                color: const Color(0xFF242426),
              ),
            )
          : active
          ? Container(
              width: 2,
              height: 25,
              decoration: BoxDecoration(
                color: AppColors.red,
                borderRadius: BorderRadius.circular(99),
              ),
            )
          : Text(
              '–',
              style: AppTypography.sectionTitle.copyWith(
                color: const Color(0xFFD7D7DC),
                fontSize: 17,
                fontWeight: FontWeight.w500,
              ),
            ),
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

class _SecurityArtwork extends StatelessWidget {
  const _SecurityArtwork({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const ValueKey('phone-verification-security-art'),
      dimension: compact ? 72 : 118,
      child: Transform.scale(
        scale: 1.18,
        child: Image.asset(
          'assets/images/security_verification_illustration.png',
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          semanticLabel: 'Secure phone verification',
        ),
      ),
    );
  }
}

class _OtpSecurityArtwork extends StatelessWidget {
  const _OtpSecurityArtwork({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      key: const ValueKey('phone-otp-security-art'),
      dimension: compact ? 72 : 124,
      child: Image.asset(
        'assets/images/otp_verification_illustration.png',
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        semanticLabel: 'Phone protected by verification',
      ),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('phone-verification-privacy-notice'),
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 10 : 12,
        vertical: compact ? 6 : 9,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F8FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD8E8FF)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 28 : 34,
            height: compact ? 28 : 34,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF63A7FF)),
            ),
            child: Icon(
              Icons.shield_outlined,
              color: const Color(0xFF378FEB),
              size: compact ? 16 : 19,
            ),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Text(
              'Firebase/Google processes this number to send the security code and prevent abuse.',
              style: AppTypography.body.copyWith(
                color: const Color(0xFF40546A),
                fontSize: compact ? 10.5 : 11.5,
                height: compact ? 1.3 : 1.38,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerificationActionButton extends StatelessWidget {
  const _VerificationActionButton({
    super.key,
    required this.label,
    required this.leadingIcon,
    required this.onPressed,
    this.loading = false,
    this.compact = false,
  });

  final String label;
  final IconData leadingIcon;
  final VoidCallback? onPressed;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final feedbackOnPressed = AppPressable.withFeedback(
      loading ? null : onPressed,
      haptic: AppHaptic.medium,
    );
    return Opacity(
      opacity: feedbackOnPressed == null ? .62 : 1,
      child: AppPressable(
        enabled: feedbackOnPressed != null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 15 : 18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33F23845),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: AppColors.red,
            borderRadius: BorderRadius.circular(compact ? 15 : 18),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: feedbackOnPressed,
              splashFactory: InkRipple.splashFactory,
              overlayColor: WidgetStatePropertyAll(
                Colors.white.withValues(alpha: .14),
              ),
              child: SizedBox(
                height: compact ? 48 : 58,
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: compact ? 10 : 13),
                  child: loading
                      ? const Center(
                          child: AppLoader(
                            size: 23,
                            strokeWidth: 2.4,
                            color: Colors.white,
                            trackColor: Color(0x55FFFFFF),
                          ),
                        )
                      : Row(
                          children: [
                            Container(
                              width: compact ? 34 : 42,
                              height: compact ? 34 : 42,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                leadingIcon,
                                color: AppColors.red,
                                size: compact ? 17 : 20,
                              ),
                            ),
                            Container(
                              width: 1,
                              height: compact ? 24 : 30,
                              margin: EdgeInsets.only(left: compact ? 9 : 12),
                              color: const Color(0x99FFFFFF),
                            ),
                            Expanded(
                              child: Text(
                                label,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Plus Jakarta Sans',
                                  color: Colors.white,
                                  fontSize: compact ? 15 : 17,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white,
                              size: compact ? 17 : 20,
                            ),
                            SizedBox(width: compact ? 1 : 3),
                          ],
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OtpVerificationButton extends StatelessWidget {
  const _OtpVerificationButton({
    super.key,
    required this.onPressed,
    this.loading = false,
    this.compact = false,
  });

  final VoidCallback? onPressed;
  final bool loading;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final feedbackOnPressed = AppPressable.withFeedback(
      loading ? null : onPressed,
      haptic: AppHaptic.medium,
    );
    return AppPressable(
      enabled: feedbackOnPressed != null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x2EF23845),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: AppColors.red,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: feedbackOnPressed,
            splashFactory: InkRipple.splashFactory,
            overlayColor: WidgetStatePropertyAll(
              Colors.white.withValues(alpha: .14),
            ),
            child: SizedBox(
              height: compact ? 44 : 48,
              child: Center(
                child: loading
                    ? const AppLoader(
                        size: 23,
                        strokeWidth: 2.4,
                        color: Colors.white,
                        trackColor: Color(0x55FFFFFF),
                      )
                    : const FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.verified_user_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Verify',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
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
