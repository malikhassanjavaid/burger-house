import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The single primary action button used across Hungry Spot.
///
/// Screens provide the content and behavior through constructor properties,
/// while this component owns the brand color, typography, loading indicator,
/// disabled state, and shape.
class AppPrimaryButton extends StatelessWidget {
  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.fullWidth = true,
    this.height = 54,
    this.borderRadius = 14,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final style = FilledButton.styleFrom(
      backgroundColor: AppColors.red,
      foregroundColor: Colors.white,
      disabledBackgroundColor: AppColors.red.withValues(alpha: .56),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      textStyle: const TextStyle(
        fontSize: 12.5,
        fontWeight: FontWeight.w900,
        letterSpacing: .2,
      ),
    );

    final Widget button;
    if (isLoading) {
      button = FilledButton(
        onPressed: null,
        style: style,
        child: const SizedBox.square(
          dimension: 20,
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2.2,
          ),
        ),
      );
    } else if (icon != null) {
      button = FilledButton.icon(
        onPressed: effectiveOnPressed,
        style: style,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    } else {
      button = FilledButton(
        onPressed: effectiveOnPressed,
        style: style,
        child: Text(label),
      );
    }

    return SizedBox(
      width: fullWidth ? double.infinity : null,
      height: height,
      child: button,
    );
  }
}
