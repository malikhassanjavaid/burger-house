import 'package:flutter/material.dart';

const profilePageBackground = Color(0xFFF4FAFE);
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
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                elevation: 4,
                shadowColor: const Color(0x1F47657A),
                child: IconButton(
                  onPressed: onBack,
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: profilePageBlue,
                    size: 19,
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Text(
                title,
                style: const TextStyle(
                  color: profilePageInk,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
