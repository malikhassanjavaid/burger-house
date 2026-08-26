import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// The branded surface used by the demo card on the Add Card screen.
class AddCardPreviewSurface extends StatelessWidget {
  const AddCardPreviewSurface({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.brandYellow,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.brandYellow),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260F172A),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: IconTheme(
        data: const IconThemeData(color: AppColors.dark),
        child: DefaultTextStyle.merge(
          style: const TextStyle(color: AppColors.dark),
          child: child,
        ),
      ),
    );
  }
}
