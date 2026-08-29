import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_back_button.dart';

const profilePageBackground = Colors.white;
const profilePageInk = Color(0xFF15161C);
const profilePageMuted = Color(0xFF858C98);
const profilePageBlue = Color(0xFF1597E5);

class ProfilePageHeader extends StatelessWidget {
  const ProfilePageHeader({
    super.key,
    required this.title,
    required this.onBack,
  });

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 82,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: Row(
            children: [
              AppBackButton(onPressed: onBack, tooltip: 'Back'),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.pageHeader.copyWith(
                    color: profilePageInk,
                    letterSpacing: -.2,
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
