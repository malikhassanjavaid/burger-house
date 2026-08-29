import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_loader.dart';
import 'app_pressable.dart';

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
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool fullWidth;
  final double height;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;
    final feedbackOnPressed = AppPressable.withFeedback(
      effectiveOnPressed,
      haptic: AppHaptic.light,
    );
    final buttonColor = backgroundColor ?? AppColors.red;
    final style = FilledButton.styleFrom(
      backgroundColor: buttonColor,
      foregroundColor: Colors.white,
      disabledBackgroundColor: buttonColor.withValues(alpha: .56),
      disabledForegroundColor: Colors.white,
      elevation: 0,
      overlayColor: Colors.white.withValues(alpha: .18),
      splashFactory: InkRipple.splashFactory,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      textStyle: AppTypography.button,
    );

    final Widget button;
    if (isLoading) {
      button = FilledButton(
        onPressed: null,
        style: style,
        child: const AppLoader(
          size: 20,
          strokeWidth: 2.2,
          color: Colors.white,
          trackColor: Color(0x4DFFFFFF),
        ),
      );
    } else if (icon != null) {
      button = FilledButton.icon(
        onPressed: feedbackOnPressed,
        style: style,
        icon: Icon(icon, size: 18),
        label: Text(label),
      );
    } else {
      button = FilledButton(
        onPressed: feedbackOnPressed,
        style: style,
        child: Text(label),
      );
    }

    return AppPressable(
      enabled: feedbackOnPressed != null,
      child: SizedBox(
        width: fullWidth ? double.infinity : null,
        height: height,
        child: button,
      ),
    );
  }
}
