import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

class AuthLoadingOverlay extends StatelessWidget {
  const AuthLoadingOverlay({
    required this.loading,
    required this.message,
    required this.child,
    super.key,
  });

  final bool loading;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !loading,
      child: Stack(
        children: [
          child,
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: loading
                  ? const _BrandedLoader(key: ValueKey('auth-loader'))
                  : const SizedBox.shrink(key: ValueKey('auth-ready')),
            ),
          ),
          if (loading)
            Positioned.fill(
              child: Center(
                child: Semantics(
                  label: message,
                  liveRegion: true,
                  child: _LoadingCard(message: message),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _BrandedLoader extends StatelessWidget {
  const _BrandedLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xB3211A16),
      child: ModalBarrier(dismissible: false, color: Colors.transparent),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: .88, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutBack,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: Container(
        width: 270,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 36,
              offset: Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 66,
              height: 66,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFFF9B45), AppColors.orange],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Color(0x4DFF6B00),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.lunch_dining_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.dark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Please wait just a moment',
              style: TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 19),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: const LinearProgressIndicator(
                minHeight: 5,
                color: AppColors.orange,
                backgroundColor: Color(0xFFFFE4CF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
