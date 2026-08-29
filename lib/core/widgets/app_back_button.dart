import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_pressable.dart';

/// The shared page-level back control used throughout Hungry Spot.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.tooltip = 'Back'});

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    final feedbackOnPressed = AppPressable.withFeedback(
      onPressed ?? () => Navigator.of(context).maybePop(),
      haptic: AppHaptic.selection,
    );
    return AppPressable(
      child: SizedBox.square(
        dimension: 44,
        child: Material(
          color: Colors.white,
          elevation: 4,
          shadowColor: const Color(0x1F304A5C),
          borderRadius: BorderRadius.circular(14),
          child: IconButton(
            tooltip: tooltip,
            onPressed: feedbackOnPressed,
            padding: EdgeInsets.zero,
            style: IconButton.styleFrom(
              overlayColor: AppColors.navigationBlue.withValues(alpha: .12),
            ),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.navigationBlue,
              size: 19,
            ),
          ),
        ),
      ),
    );
  }
}
