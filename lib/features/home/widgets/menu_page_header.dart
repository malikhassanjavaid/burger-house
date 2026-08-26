import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';

class MenuPageHeader extends StatelessWidget {
  const MenuPageHeader({
    required this.onBack,
    required this.onSearch,
    super.key,
  });

  final VoidCallback onBack;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFF0F2F5))),
      ),
      child: Row(
        children: [
          AppBackButton(onPressed: onBack, tooltip: 'Back to home'),
          const SizedBox(width: 14),
          const Expanded(
            child: Text(
              'Explore Menu',
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 16,
                fontWeight: FontWeight.w700,
                letterSpacing: -.2,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Search menu',
            onPressed: onSearch,
            icon: const Icon(
              Icons.search_rounded,
              color: AppColors.dark,
              size: 24,
            ),
          ),
        ],
      ),
    );
  }
}
