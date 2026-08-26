import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// The shared page-level back control used throughout Hungry Spot.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.onPressed, this.tooltip = 'Back'});

  final VoidCallback? onPressed;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 44,
      child: Material(
        color: Colors.white,
        elevation: 4,
        shadowColor: const Color(0x1F304A5C),
        borderRadius: BorderRadius.circular(14),
        child: IconButton(
          tooltip: tooltip,
          onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
          padding: EdgeInsets.zero,
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.navigationBlue,
            size: 19,
          ),
        ),
      ),
    );
  }
}
