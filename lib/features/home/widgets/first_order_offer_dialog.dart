import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';

const _cardWidth = 342.0;
const _cardHeight = 532.0;
const _heroHeight = 304.0;

class FirstOrderOfferDialog extends StatelessWidget {
  const FirstOrderOfferDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
      child: SafeArea(
        minimum: const EdgeInsets.all(20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = <double>[
              1,
              constraints.maxWidth / _cardWidth,
              constraints.maxHeight / _cardHeight,
            ].reduce((current, next) => current < next ? current : next);
            final displayWidth = _cardWidth * scale;
            final displayHeight = _cardHeight * scale;
            final closeInset = (36 * scale - 22).clamp(0.0, double.infinity);
            final scaledActionHeight = 54 * scale;
            final actionHitHeight = scaledActionHeight < 44
                ? 44.0
                : scaledActionHeight;
            final actionTop = 475 * scale - actionHitHeight / 2;

            return Center(
              child: SizedBox(
                key: const ValueKey('first-order-offer-card'),
                width: displayWidth,
                height: displayHeight,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: FittedBox(
                        fit: BoxFit.fill,
                        child: MediaQuery.withClampedTextScaling(
                          maxScaleFactor: 1.2,
                          child: const SizedBox(
                            width: _cardWidth,
                            height: _cardHeight,
                            child: _OfferTicket(),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: closeInset,
                      top: closeInset,
                      width: 44,
                      height: 44,
                      child: Semantics(
                        button: true,
                        label: 'Close offer',
                        child: Material(
                          color: Colors.transparent,
                          shape: const CircleBorder(),
                          child: InkWell(
                            key: const ValueKey('first-order-offer-close'),
                            customBorder: const CircleBorder(),
                            onTap: () => Navigator.pop(context),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 30 * scale,
                      right: 30 * scale,
                      top: actionTop,
                      height: actionHitHeight,
                      child: Semantics(
                        button: true,
                        label: 'Start ordering',
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(999),
                          child: InkWell(
                            key: const ValueKey(
                              'first-order-offer-start-ordering',
                            ),
                            borderRadius: BorderRadius.circular(999),
                            onTap: () => Navigator.pop(context),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OfferTicket extends StatelessWidget {
  const _OfferTicket();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: PhysicalShape(
        clipper: const _TicketClipper(seamY: _heroHeight),
        color: Colors.white,
        elevation: 22,
        shadowColor: const Color(0xB3000000),
        clipBehavior: Clip.antiAlias,
        child: Semantics(
          label:
              'First order offer. Ten percent off your first Hungry Spot order. '
              'Use code BURGER10.',
          child: Stack(
            children: [
              const Positioned.fill(
                bottom: _cardHeight - _heroHeight,
                child: _OfferHero(),
              ),
              const Positioned(
                left: 0,
                right: 0,
                top: _heroHeight,
                bottom: 0,
                child: _OfferDetails(),
              ),
              const Positioned(
                left: 28,
                right: 28,
                top: _heroHeight - .5,
                child: CustomPaint(
                  size: Size(double.infinity, 1),
                  painter: _DashedLinePainter(),
                ),
              ),
              Positioned(
                right: 14,
                top: 14,
                child: Material(
                  color: const Color(0xFFFDFDFD),
                  shape: const CircleBorder(),
                  elevation: 4,
                  shadowColor: const Color(0x33000000),
                  child: const SizedBox.square(
                    dimension: 44,
                    child: Icon(
                      Icons.close_rounded,
                      color: AppColors.dark,
                      size: 27,
                    ),
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

class _OfferHero extends StatelessWidget {
  const _OfferHero();

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFD85B), Color(0xFFFFC437), Color(0xFFFFB92C)],
          ),
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            const Positioned(
              left: 42,
              top: 77,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.red,
                size: 14,
              ),
            ),
            const Positioned(
              right: 48,
              top: 78,
              child: Icon(
                Icons.auto_awesome_rounded,
                color: AppColors.red,
                size: 13,
              ),
            ),
            const Positioned(
              left: 31,
              top: 123,
              child: Icon(
                Icons.celebration_rounded,
                color: Color(0x55F23846),
                size: 31,
              ),
            ),
            const Positioned(
              right: 31,
              top: 121,
              child: Icon(
                Icons.celebration_rounded,
                color: Color(0x66F23846),
                size: 29,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 20,
              child: Center(
                child: Container(
                  key: const ValueKey('first-order-offer-logo'),
                  width: 82,
                  height: 82,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFEFA),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFF9B518),
                      width: 2.3,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x2B9B5D00),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: HungrySpotLogo(size: 67, contentScale: 1.22),
                  ),
                ),
              ),
            ),
            const Positioned(
              left: 0,
              right: 0,
              top: 110,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _OfferDash(),
                  SizedBox(width: 10),
                  Text(
                    'FIRST ORDER',
                    style: TextStyle(
                      color: AppColors.dark,
                      fontSize: 16,
                      height: 1,
                      letterSpacing: .2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(width: 10),
                  _OfferDash(),
                ],
              ),
            ),
            const Positioned(
              left: 19,
              top: 146,
              child: Text(
                '10%',
                style: TextStyle(
                  color: Color(0xFF111214),
                  fontSize: 92,
                  height: .9,
                  letterSpacing: -8,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const Positioned(
              left: 151,
              top: 231,
              child: Text(
                'OFF',
                style: TextStyle(
                  color: Color(0xFFE31D2C),
                  fontSize: 32,
                  height: .9,
                  letterSpacing: -1.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Positioned(
              key: const ValueKey('first-order-offer-food'),
              right: -6,
              bottom: -1,
              width: 146,
              child: Image.asset(
                'assets/images/first_order_offer_food_v3.png',
                cacheWidth: 512,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferDetails extends StatelessWidget {
  const _OfferDetails();

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        const Positioned(
          left: 20,
          right: 20,
          top: 22,
          height: 26,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Your first bite is on us',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.dark,
                fontSize: 19.5,
                height: 1.15,
                letterSpacing: -.35,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const Positioned(
          left: 20,
          right: 20,
          top: 56,
          height: 18,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              'Save 10% on your first Hungry Spot order.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.muted,
                fontSize: 11.5,
                height: 1.35,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        const Positioned(
          top: 90,
          width: 250,
          height: 46,
          child: CustomPaint(
            painter: _DashedCouponPainter(),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'USE CODE',
                      style: TextStyle(
                        color: Color(0xFF7F7B78),
                        fontSize: 14,
                        height: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 13),
                    Text(
                      'BURGER10',
                      style: TextStyle(
                        color: Color(0xFFD8202F),
                        fontSize: 19,
                        height: 1,
                        letterSpacing: -.3,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 30,
          right: 30,
          bottom: 30,
          height: 54,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            child: Ink(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFF11E2F), Color(0xFFE30F21)],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x38E11A2A),
                    blurRadius: 13,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: const SizedBox(
                height: 54,
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'START ORDERING',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            height: 1,
                            letterSpacing: .1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 24),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 25,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OfferDash extends StatelessWidget {
  const _OfferDash();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 3,
      decoration: BoxDecoration(
        color: AppColors.red,
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}

class _TicketClipper extends CustomClipper<Path> {
  const _TicketClipper({required this.seamY});

  final double seamY;

  @override
  Path getClip(Size size) {
    final ticket = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(30)),
      );
    final notches = Path()
      ..addOval(Rect.fromCircle(center: Offset(0, seamY), radius: 13))
      ..addOval(Rect.fromCircle(center: Offset(size.width, seamY), radius: 13));
    return Path.combine(PathOperation.difference, ticket, notches);
  }

  @override
  bool shouldReclip(covariant _TicketClipper oldClipper) {
    return oldClipper.seamY != seamY;
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFF4B421)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dashWidth = 7.0;
    const gap = 5.0;
    for (var x = 0.0; x < size.width; x += dashWidth + gap) {
      canvas.drawLine(
        Offset(x, 0),
        Offset((x + dashWidth).clamp(0, size.width), 0),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashedCouponPainter extends CustomPainter {
  const _DashedCouponPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF7C77)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(12)),
      );

    const dashLength = 6.0;
    const gapLength = 4.0;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(
          metric.extractPath(
            distance,
            (distance + dashLength).clamp(0, metric.length),
          ),
          paint,
        );
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
