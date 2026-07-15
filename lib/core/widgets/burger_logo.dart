import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class BurgerLogo extends StatelessWidget {
  const BurgerLogo({super.key, this.size = 110, this.showName = true});

  final double size;
  final bool showName;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: .08),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text('🍔', style: TextStyle(fontSize: size * .55)),
        ),
        if (showName) ...[
          const SizedBox(height: 20),
          const Text(
            'BURGER HOUSE',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.4,
              color: AppColors.dark,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Fresh. Fast. Delicious.',
            style: TextStyle(
              color: AppColors.orange,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
