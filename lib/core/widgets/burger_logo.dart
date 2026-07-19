import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FeastStationLogo extends StatelessWidget {
  const FeastStationLogo({super.key, this.size = 132, this.showTagline = true});

  final double size;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: Image.asset(
            'assets/images/feast_station_logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
        if (showTagline) ...[
          const SizedBox(height: 12),
          const Text(
            'Fresh flavor. Fast delivery.',
            style: TextStyle(
              color: AppColors.red,
              fontWeight: FontWeight.w700,
              letterSpacing: .2,
            ),
          ),
        ],
      ],
    );
  }
}
