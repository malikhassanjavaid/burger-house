import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/brand_logo.dart';

const authInk = Color(0xFF242426);
const authMuted = Color(0xFF6E6E73);
const authBorder = Color(0xFF747478);
const authLink = Color(0xFF0877A8);

class AuthFormShell extends StatelessWidget {
  const AuthFormShell({
    super.key,
    required this.headline,
    required this.child,
    required this.bottomAction,
    this.topSpacing = 18,
    this.headlineFontSize = 25,
    this.headlineFontWeight = FontWeight.w700,
    this.logoSize = 150,
    this.logoContentScale = 1,
  });

  final String headline;
  final Widget child;
  final Widget bottomAction;
  final double topSpacing;
  final double headlineFontSize;
  final FontWeight headlineFontWeight;
  final double logoSize;
  final double logoContentScale;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final headerWidth = (constraints.maxWidth - 40)
                .clamp(0.0, 430.0)
                .toDouble();
            final resolvedLogoSize = logoSize
                .clamp(104.0, headerWidth * .42)
                .toDouble();

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 14),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 430,
                    minHeight: constraints.maxHeight - 22,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(height: topSpacing),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  headline,
                                  maxLines: 2,
                                  style: AppTypography.screenTitle.copyWith(
                                    color: authInk,
                                    fontSize: headlineFontSize,
                                    fontWeight: headlineFontWeight,
                                    height: 1.08,
                                    letterSpacing: -.35,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: resolvedLogoSize,
                              child: HungrySpotLogo(
                                size: resolvedLogoSize,
                                contentScale: logoContentScale,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        child,
                        const Spacer(),
                        const SizedBox(height: 22),
                        bottomAction,
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class AuthTextField extends StatelessWidget {
  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.textInputAction,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String hintText;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction? textInputAction;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return AuthFieldFrame(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        validator: validator,
        style: AppTypography.bodyMedium.copyWith(
          color: authInk,
          fontWeight: FontWeight.w600,
        ),
        decoration: authInputDecoration(hintText),
      ),
    );
  }
}

class AuthFieldFrame extends StatelessWidget {
  const AuthFieldFrame({super.key, required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.label.copyWith(
            color: authMuted,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

InputDecoration authInputDecoration(String hintText, {Widget? suffixIcon}) {
  OutlineInputBorder outline(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    hintStyle: AppTypography.body.copyWith(
      color: const Color(0xFF77777C),
      fontWeight: FontWeight.w500,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: outline(authBorder),
    enabledBorder: outline(authBorder),
    focusedBorder: outline(AppColors.red, 1.4),
    errorBorder: outline(AppColors.red),
    focusedErrorBorder: outline(AppColors.red, 1.4),
    errorStyle: const TextStyle(fontSize: 11),
  );
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return AppPrimaryButton(
      label: label,
      onPressed: onPressed,
      icon: icon,
      isLoading: loading,
    );
  }
}

class AuthLinkButton extends StatelessWidget {
  const AuthLinkButton({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(
          label,
          style: AppTypography.label.copyWith(
            color: authLink,
            fontWeight: FontWeight.w500,
            decoration: TextDecoration.underline,
            decorationColor: authLink,
          ),
        ),
      ),
    );
  }
}

class AuthFooterPrompt extends StatelessWidget {
  const AuthFooterPrompt({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 8,
      children: [
        Text(
          message,
          style: AppTypography.label.copyWith(
            color: authInk,
            fontWeight: FontWeight.w500,
          ),
        ),
        AuthLinkButton(label: actionLabel, onPressed: onPressed),
      ],
    );
  }
}
