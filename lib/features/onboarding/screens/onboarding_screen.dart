import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;

  static const _items = [
    _OnboardingItem(
      eyebrow: 'WELCOME TO HUNGRY SPOT',
      title: 'Dive Into\nPure Flavor',
      body:
          'Explore pizzas, burgers, sides and more—prepared fresh whenever hunger calls.',
      asset: 'assets/images/superduper_pizza_promo-cutout.png',
      imageScale: 1.04,
      imageRotation: -.06,
    ),
    _OnboardingItem(
      eyebrow: 'MADE YOUR WAY',
      title: 'Step Into A\nWorld Of Flavor',
      body:
          'Choose your size, ingredients and extras, then we will make every bite just right.',
      asset: 'assets/images/firehouse_burger-cutout.png',
      imageScale: 1.08,
      imageRotation: .02,
    ),
    _OnboardingItem(
      eyebrow: 'FAST & FRESH',
      title: 'Flavor Awaits\nYou',
      body:
          'From savory favorites to sweet finishes, your next feast is only a few taps away.',
      asset: 'assets/images/cheesecake_slice-cutout.png',
      imageScale: .9,
      imageRotation: -.05,
    ),
  ];

  void _next() {
    if (_page == _items.length - 1) {
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _openLogin() {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.red,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFD9162E), AppColors.red, Color(0xFFFF5360)],
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 720;
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(22, compact ? 8 : 14, 18, 0),
                    child: Row(
                      children: [
                        Container(
                          width: 132,
                          height: 78,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: .1),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const HungrySpotLogo(size: 122),
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: _openLogin,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Skip'),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                    child: Row(
                      children: List.generate(
                        _items.length,
                        (index) => Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            height: 4,
                            margin: EdgeInsets.only(
                              right: index == _items.length - 1 ? 0 : 7,
                            ),
                            decoration: BoxDecoration(
                              color: index <= _page
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: .28),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      itemCount: _items.length,
                      onPageChanged: (value) => setState(() => _page = value),
                      itemBuilder: (_, index) => _OnboardingPage(
                        item: _items[index],
                        compact: compact,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(18, 4, 18, compact ? 12 : 18),
                    child: Column(
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: compact ? 50 : 54,
                          child: ElevatedButton(
                            onPressed: _next,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.redDark,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: Text(
                              _page == _items.length - 1
                                  ? 'Get started'
                                  : 'Continue',
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          height: compact ? 48 : 52,
                          child: OutlinedButton(
                            onPressed: _openLogin,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: .78),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              'I already have an account',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(height: 13),
                          Text(
                            'By continuing, you agree to our Terms of Service and Privacy Policy.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: .72),
                              fontSize: 10.5,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.item, required this.compact});

  final _OnboardingItem item;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(24, compact ? 18 : 26, 24, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.eyebrow,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .76),
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 9),
          Text(
            item.title,
            style: TextStyle(
              color: Colors.white,
              fontSize: compact ? 35 : 42,
              height: .96,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            item.body,
            style: TextStyle(
              color: Colors.white.withValues(alpha: .84),
              fontSize: compact ? 12.5 : 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: compact ? 230 : 280,
                    height: compact ? 230 : 280,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: .22),
                          Colors.white.withValues(alpha: .03),
                        ],
                      ),
                    ),
                  ),
                  Transform.rotate(
                    angle: item.imageRotation,
                    child: Transform.scale(
                      scale: item.imageScale,
                      child: Image.asset(
                        item.asset,
                        width: compact ? 250 : 312,
                        height: compact ? 220 : 286,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingItem {
  const _OnboardingItem({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.asset,
    required this.imageScale,
    required this.imageRotation,
  });

  final String eyebrow;
  final String title;
  final String body;
  final String asset;
  final double imageScale;
  final double imageRotation;
}
