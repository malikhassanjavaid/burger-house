import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
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
    this.topSpacing = 8,
    this.headlineFontSize = 30,
    this.headlineFontWeight = FontWeight.w900,
    this.logoSize = 180,
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
            final headerWidth = (constraints.maxWidth - 44)
                .clamp(0.0, 430.0)
                .toDouble();
            final resolvedLogoSize = headerWidth >= 340
                ? logoSize
                : headerWidth * .52;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 18),
              child: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 430,
                    minHeight: constraints.maxHeight - 30,
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
                              child: Text(
                                headline,
                                maxLines: 2,
                                softWrap: false,
                                style: TextStyle(
                                  color: authInk,
                                  fontSize: headlineFontSize,
                                  height: 1.16,
                                  fontWeight: headlineFontWeight,
                                  letterSpacing: -.45,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            SizedBox(
                              width: resolvedLogoSize,
                              child: HungrySpotLogo(
                                size: resolvedLogoSize,
                                contentScale: logoContentScale,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 38),
                        child,
                        const Spacer(),
                        const SizedBox(height: 34),
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
        style: const TextStyle(
          color: authInk,
          fontSize: 14,
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
          style: const TextStyle(
            color: authMuted,
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

InputDecoration authInputDecoration(String hintText, {Widget? suffixIcon}) {
  OutlineInputBorder outline(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(6),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return InputDecoration(
    hintText: hintText,
    hintStyle: const TextStyle(
      color: Color(0xFF77777C),
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 18),
    border: outline(authBorder),
    enabledBorder: outline(authBorder),
    focusedBorder: outline(AppColors.red, 1.4),
    errorBorder: outline(AppColors.red),
    focusedErrorBorder: outline(AppColors.red, 1.4),
    errorStyle: const TextStyle(fontSize: 10.5),
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
    final buttonStyle = FilledButton.styleFrom(
      backgroundColor: AppColors.red,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.red.withValues(alpha: .58),
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: const TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        letterSpacing: .3,
      ),
    );

    if (loading) {
      return FilledButton(
        onPressed: null,
        style: buttonStyle,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.2,
          ),
        ),
      );
    }

    if (icon != null) {
      return FilledButton.icon(
        onPressed: onPressed,
        style: buttonStyle,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    }

    return FilledButton(
      onPressed: onPressed,
      style: buttonStyle,
      child: Text(label),
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
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Text(
          label,
          style: const TextStyle(
            color: authLink,
            fontSize: 12.5,
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
          style: const TextStyle(
            color: authInk,
            fontSize: 12.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        AuthLinkButton(label: actionLabel, onPressed: onPressed),
      ],
    );
  }
}
