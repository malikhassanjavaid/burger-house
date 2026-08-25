import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class FirstOrderOfferDialog extends StatelessWidget {
  const FirstOrderOfferDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      minimum: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth < 304
              ? constraints.maxWidth
              : 304.0;

          return Center(
            child: Material(
              color: Colors.transparent,
              child: Container(
                key: const ValueKey('first-order-offer-card'),
                width: cardWidth,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFFFE39C)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x52000000),
                      blurRadius: 38,
                      offset: Offset(0, 18),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [_OfferHero(), _OfferDetails()],
                    ),
                    Positioned(
                      right: 12,
                      top: 12,
                      child: Semantics(
                        button: true,
                        label: 'Close offer',
                        child: Material(
                          color: const Color(0xF2FFFFFF),
                          shape: const CircleBorder(
                            side: BorderSide(color: Color(0x55FFFFFF)),
                          ),
                          elevation: 2,
                          shadowColor: const Color(0x33000000),
                          child: InkWell(
                            key: const ValueKey('first-order-offer-close'),
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(context),
                            child: const SizedBox.square(
                              dimension: 44,
                              child: Icon(
                                Icons.close_rounded,
                                color: AppColors.dark,
                                size: 21,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OfferHero extends StatelessWidget {
  const _OfferHero();

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Ten percent off your first Hungry Spot order',
      child: ExcludeSemantics(
        child: Container(
          height: 154,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFFDC55), Color(0xFFFFB928)],
            ),
          ),
          child: Stack(
            children: [
              const Positioned(
                left: -30,
                top: -38,
                child: _OfferBubble(size: 105, color: Color(0x33FFFFFF)),
              ),
              const Positioned(
                right: -24,
                bottom: -42,
                child: _OfferBubble(size: 116, color: Color(0x1FF23846)),
              ),
              Positioned(
                left: 18,
                top: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.dark,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.restaurant_rounded,
                        color: Colors.white,
                        size: 13,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'FIRST ORDER',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          letterSpacing: .9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 20,
                right: 20,
                bottom: 16,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '10',
                      style: TextStyle(
                        color: AppColors.dark,
                        fontSize: 76,
                        height: .78,
                        letterSpacing: -5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 5, bottom: 1),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '%',
                            style: TextStyle(
                              color: AppColors.red,
                              fontSize: 35,
                              height: .8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            'OFF',
                            style: TextStyle(
                              color: AppColors.dark,
                              fontSize: 28,
                              height: .8,
                              letterSpacing: -.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OfferDetails extends StatelessWidget {
  const _OfferDetails();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 17, 20, 20),
      child: Column(
        children: [
          const Text(
            'Your first bite is on us',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.dark,
              fontSize: 18,
              height: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 7),
          const Text(
            'Save 10% on your first Hungry Spot order.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.muted,
              fontSize: 12.5,
              height: 1.4,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7E2),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFFDEA0)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.local_offer_rounded, color: AppColors.red, size: 18),
                SizedBox(width: 8),
                Text(
                  'USE CODE',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 9,
                    letterSpacing: .8,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(width: 7),
                Text(
                  'BURGER10',
                  style: TextStyle(
                    color: AppColors.dark,
                    fontSize: 13,
                    letterSpacing: .5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OfferBubble extends StatelessWidget {
  const _OfferBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
