import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';

const _profileBackground = Color(0xFFF4FAFE);
const _profileInk = Color(0xFF15161C);
const _profileMuted = Color(0xFF858C98);

class ProfileTab extends StatelessWidget {
  const ProfileTab({
    super.key,
    required this.onDetails,
    required this.onAddress,
    required this.onOrders,
  });

  final VoidCallback onDetails;
  final VoidCallback onAddress;
  final VoidCallback onOrders;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _profileBackground,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 44, 20, 190),
        children: [
          const Text(
            'MY ACCOUNT',
            style: TextStyle(
              color: AppColors.red,
              fontSize: 27,
              fontWeight: FontWeight.w900,
              letterSpacing: -.7,
            ),
          ),
          const SizedBox(height: 25),
          _ProfileMenuTile(title: 'MY DETAILS', onTap: onDetails),
          const SizedBox(height: 13),
          _ProfileMenuTile(title: 'MY ADDRESS', onTap: onAddress),
          const SizedBox(height: 13),
          _ProfileMenuTile(title: 'MY ORDERS', onTap: onOrders),
        ],
      ),
    );
  }
}

class ProfileLogoutBar extends StatelessWidget {
  const ProfileLogoutBar({super.key, required this.onSignOut});

  final VoidCallback onSignOut;

  Future<void> _confirmSignOut(BuildContext context) async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDCE4E9),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: 58,
                height: 58,
                decoration: const BoxDecoration(
                  color: AppColors.blush,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: AppColors.red,
                  size: 27,
                ),
              ),
              const SizedBox(height: 15),
              const Text(
                'Log out of Hungry Spot?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _profileInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'You can sign back in anytime with your email and password.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _profileMuted,
                  fontSize: 12,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext, false),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _profileInk,
                        minimumSize: const Size.fromHeight(48),
                        side: const BorderSide(color: Color(0xFFDDE5EA)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(13),
                        ),
                      ),
                      child: const Text(
                        'CANCEL',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: AppPrimaryButton(
                      label: 'LOGOUT',
                      onPressed: () => Navigator.pop(sheetContext, true),
                      height: 48,
                      borderRadius: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed == true) onSignOut();
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: _profileBackground,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
        child: AppPrimaryButton(
          label: 'LOGOUT',
          onPressed: () => _confirmSignOut(context),
          icon: Icons.logout_rounded,
        ),
      ),
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  const _ProfileMenuTile({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(17),
      elevation: 3,
      shadowColor: const Color(0x1A47657A),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17),
        child: SizedBox(
          height: 78,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 33,
                  decoration: BoxDecoration(
                    color: AppColors.red,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      color: _profileInk,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.15,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Color(0xFF9BA6AE),
                  size: 17,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
