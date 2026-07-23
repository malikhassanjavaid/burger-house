import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/onboarding_preferences.dart';
import '../../../core/theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key, this.onCompleted});

  final Future<void> Function()? onCompleted;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _page = 0;
  bool _finishing = false;

  static const _yellow = Color(0xFFFFC400);

  static const _pages = [
    _OnboardingPageData(
      background: AppColors.red,
      progressColor: Colors.white,
      eyebrow: 'FRESHLY MADE',
      title: 'Good food,\nmade for your moment.',
      body:
          'Discover crowd favorites prepared fresh and ready whenever hunger calls.',
      asset: 'assets/images/onboarding/intro_1_cutout.png',
      imageWidthFactor: .94,
      imageLabel: 'Happy customer holding a fresh pizza',
    ),
    _OnboardingPageData(
      background: _yellow,
      progressColor: AppColors.dark,
      eyebrow: 'MADE YOUR WAY',
      title: 'Every bite,\nmade your way.',
      body:
          'Choose your size, extras, and ingredients for a meal that feels personal.',
      asset: 'assets/images/onboarding/intro_2_cutout.png',
      imageWidthFactor: .92,
      imageLabel: 'Freshly prepared cheeseburger',
    ),
    _OnboardingPageData(
      background: AppColors.red,
      progressColor: Colors.white,
      eyebrow: 'FAST TO YOUR DOOR',
      title: 'Your next craving,\none tap away.',
      body:
          'Place your order and follow every step from our kitchen to your door.',
      asset: 'assets/images/onboarding/intro_3_cutout.png',
      imageWidthFactor: 1,
      imageLabel: 'Fresh cheese pizza',
    ),
  ];

  Future<void> _completeOnboarding() async {
    if (_finishing) return;
    setState(() => _finishing = true);
    try {
      if (widget.onCompleted != null) {
        await widget.onCompleted!();
      } else {
        await OnboardingPreferences.markCompleted();
      }
    } catch (_) {
      // A local storage problem should never keep the customer from signing in.
    }
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, AppRoutes.login);
  }

  Future<void> _next() async {
    if (_page == _pages.length - 1) {
      await _completeOnboarding();
      return;
    }
    await _controller.nextPage(
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = _pages[_page];
    return Scaffold(
      body: AnimatedContainer(
        key: const ValueKey('onboarding-background'),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        color: current.background,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxHeight < 700;
              return Column(
                children: [
                  _OnboardingHeader(
                    currentPage: _page,
                    pageCount: _pages.length,
                    color: current.progressColor,
                    compact: compact,
                    onSkip: _completeOnboarding,
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _controller,
                      physics: const BouncingScrollPhysics(),
                      itemCount: _pages.length,
                      onPageChanged: (value) => setState(() => _page = value),
                      itemBuilder: (_, index) => _OnboardingHero(
                        key: ValueKey('onboarding-page-$index'),
                        data: _pages[index],
                        index: index,
                        compact: compact,
                      ),
                    ),
                  ),
                  _OnboardingBottomPanel(
                    data: current,
                    page: _page,
                    compact: compact,
                    loading: _finishing,
                    onContinue: _next,
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

class _OnboardingHeader extends StatelessWidget {
  const _OnboardingHeader({
    required this.currentPage,
    required this.pageCount,
    required this.color,
    required this.compact,
    required this.onSkip,
  });

  final int currentPage;
  final int pageCount;
  final Color color;
  final bool compact;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: compact ? 54 : 62,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Semantics(
                label: 'Page ${currentPage + 1} of $pageCount',
                child: Row(
                  children: List.generate(
                    pageCount,
                    (index) => Expanded(
                      child: AnimatedContainer(
                        key: ValueKey('onboarding-progress-$index'),
                        duration: const Duration(milliseconds: 240),
                        height: 4,
                        margin: EdgeInsets.only(
                          right: index == pageCount - 1 ? 0 : 8,
                        ),
                        decoration: BoxDecoration(
                          color: color.withValues(
                            alpha: index == currentPage
                                ? 1
                                : index < currentPage
                                ? .58
                                : .24,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 20),
            SizedBox(
              width: 48,
              child: TextButton(
                key: const ValueKey('onboarding-skip'),
                onPressed: onSkip,
                style: TextButton.styleFrom(
                  foregroundColor: color,
                  padding: EdgeInsets.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  alignment: Alignment.centerRight,
                ),
                child: const Text(
                  'Skip',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingHero extends StatelessWidget {
  const _OnboardingHero({
    super.key,
    required this.data,
    required this.index,
    required this.compact,
  });

  final _OnboardingPageData data;
  final int index;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(18, compact ? 4 : 10, 18, compact ? 8 : 14),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            key: ValueKey('onboarding-hero-stage-$index'),
            alignment: Alignment.center,
            fit: StackFit.expand,
            children: [
              Center(
                child: Container(
                  width: constraints.biggest.shortestSide * .82,
                  height: constraints.biggest.shortestSide * .82,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: data.progressColor.withValues(alpha: .065),
                  ),
                ),
              ),
              Center(
                child: FractionallySizedBox(
                  widthFactor: data.imageWidthFactor,
                  heightFactor: .96,
                  child: Semantics(
                    label: data.imageLabel,
                    image: true,
                    child: Image.asset(
                      data.asset,
                      key: ValueKey('onboarding-image-$index'),
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (_, _, _) => Icon(
                        Icons.fastfood_rounded,
                        size: 132,
                        color: data.progressColor.withValues(alpha: .32),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _OnboardingBottomPanel extends StatelessWidget {
  const _OnboardingBottomPanel({
    required this.data,
    required this.page,
    required this.compact,
    required this.loading,
    required this.onContinue,
  });

  final _OnboardingPageData data;
  final int page;
  final bool compact;
  final bool loading;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('onboarding-bottom-panel'),
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        24,
        compact ? 19 : 23,
        24,
        compact ? 14 : 18,
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 230),
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(.03, 0),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: Column(
              key: ValueKey('onboarding-copy-$page'),
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  data.eyebrow,
                  style: TextStyle(
                    color: data.progressColor.withValues(alpha: .76),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.35,
                  ),
                ),
                SizedBox(height: compact ? 6 : 8),
                SizedBox(
                  height: compact ? 56 : 64,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      data.title,
                      maxLines: 2,
                      style: TextStyle(
                        color: data.progressColor,
                        fontSize: compact ? 27 : 31,
                        height: 1.02,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -.85,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: compact ? 7 : 9),
                Text(
                  data.body,
                  style: TextStyle(
                    color: data.progressColor.withValues(alpha: .76),
                    fontSize: compact ? 11 : 12,
                    height: 1.4,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: compact ? 16 : 20),
          _OnboardingContinueButton(
            key: const ValueKey('onboarding-continue'),
            pageBackground: data.background,
            height: compact ? 49 : 52,
            loading: loading,
            onPressed: onContinue,
          ),
        ],
      ),
    );
  }
}

class _OnboardingContinueButton extends StatelessWidget {
  const _OnboardingContinueButton({
    super.key,
    required this.pageBackground,
    required this.height,
    required this.loading,
    required this.onPressed,
  });

  final Color pageBackground;
  final double height;
  final bool loading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final yellowPage = pageBackground == _OnboardingScreenState._yellow;
    final background = yellowPage ? AppColors.dark : Colors.white;
    final foreground = yellowPage ? Colors.white : AppColors.red;

    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton.icon(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: .68),
          disabledForegroundColor: foreground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          textStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            letterSpacing: .4,
          ),
        ),
        icon: loading
            ? SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: foreground,
                ),
              )
            : const Icon(Icons.arrow_forward_rounded, size: 18),
        label: Text(loading ? 'PLEASE WAIT' : 'CONTINUE'),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.background,
    required this.progressColor,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.asset,
    required this.imageWidthFactor,
    required this.imageLabel,
  });

  final Color background;
  final Color progressColor;
  final String eyebrow;
  final String title;
  final String body;
  final String asset;
  final double imageWidthFactor;
  final String imageLabel;
}
