import 'package:flutter/material.dart';

class HungrySpotLogo extends StatelessWidget {
  const HungrySpotLogo({super.key, this.size = 168, this.contentScale = 1});

  final double size;
  final double contentScale;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * .75,
      child: ClipRect(
        child: Transform.scale(
          scale: contentScale,
          child: Image.asset(
            'assets/images/hungry_spot_logo.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
          ),
        ),
      ),
    );
  }
}
