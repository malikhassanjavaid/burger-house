import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'app_loader.dart';
import 'app_pressable.dart';

class AppBottomActionBar extends StatelessWidget {
  const AppBottomActionBar({
    super.key,
    required this.eyebrow,
    required this.amount,
    required this.caption,
    required this.actionLabel,
    required this.onPressed,
    this.leading,
    this.loading = false,
  });

  final String eyebrow;
  final String amount;
  final String caption;
  final String actionLabel;
  final VoidCallback? onPressed;
  final Widget? leading;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      child: SafeArea(
        top: false,
        child: Material(
          key: const ValueKey('app-bottom-action-surface'),
          color: AppColors.red,
          borderRadius: BorderRadius.circular(13),
          child: SizedBox(
            height: 76,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  if (leading != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(9),
                      child: ColoredBox(
                        color: Colors.white,
                        child: SizedBox.square(
                          dimension: 48,
                          child: Center(child: leading),
                        ),
                      ),
                    ),
                    const SizedBox(width: 11),
                  ],
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          eyebrow,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          amount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          caption,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 11),
                  ConstrainedBox(
                    constraints: const BoxConstraints(
                      minWidth: 104,
                      maxWidth: 148,
                    ),
                    child: AppBottomActionButton(
                      label: actionLabel,
                      onPressed: onPressed,
                      loading: loading,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class AppBottomActionButton extends StatelessWidget {
  const AppBottomActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  IconData? get _semanticIcon => switch (label.trim().toUpperCase()) {
    'CHECKOUT' => Icons.shopping_bag_outlined,
    'PLACE ORDER' => Icons.receipt_long_rounded,
    'CONFIRM PICKUP' => Icons.storefront_rounded,
    'PAY & CONTINUE' => Icons.lock_rounded,
    _ => null,
  };

  AppHaptic get _haptic => switch (label.trim().toUpperCase()) {
    'PLACE ORDER' || 'PAY & CONTINUE' => AppHaptic.medium,
    _ => AppHaptic.light,
  };

  @override
  Widget build(BuildContext context) {
    final semanticIcon = _semanticIcon;
    final feedbackOnPressed = AppPressable.withFeedback(
      loading ? null : onPressed,
      haptic: _haptic,
    );
    return AppPressable(
      enabled: feedbackOnPressed != null,
      child: SizedBox(
        height: 46,
        child: FilledButton(
          onPressed: feedbackOnPressed,
          style: FilledButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: AppColors.red,
            disabledBackgroundColor: Colors.white70,
            disabledForegroundColor: AppColors.red.withValues(alpha: .62),
            elevation: 0,
            overlayColor: AppColors.red.withValues(alpha: .10),
            splashFactory: InkRipple.splashFactory,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: loading
              ? const AppLoader(
                  size: 17,
                  strokeWidth: 2.2,
                  color: AppColors.red,
                  trackColor: AppColors.blush,
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (semanticIcon != null) ...[
                      Icon(semanticIcon, size: 16),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.fade,
                        softWrap: false,
                        style: const TextStyle(
                          color: AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
