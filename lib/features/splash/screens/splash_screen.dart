import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../auth/services/auth_service.dart';
import '../../home/screens/home_screen.dart';
import '../../location/screens/location_setup_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer(const Duration(milliseconds: 2400), _continueFromSplash);
  }

  Future<void> _continueFromSplash() async {
    final authService = AuthService();
    if (!mounted) return;
    if (authService.currentUser == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
      return;
    }
    bool verified;
    try {
      verified = await authService.hasVerifiedSession();
    } catch (_) {
      await authService.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }
    if (!verified) {
      await authService.signOut();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.login);
      return;
    }
    try {
      final location = await authService.getDeliveryLocation();
      if (!mounted) return;
      if (location == null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const LocationSetupScreen(
              firstTime: true,
              destinationAfterSave: HomeScreen(),
            ),
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, AppRoutes.home);
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const _SplashBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: .76, end: 1),
                    duration: const Duration(milliseconds: 850),
                    curve: Curves.easeOutBack,
                    builder: (context, value, child) => Transform.scale(
                      scale: value,
                      child: Opacity(opacity: value.clamp(0, 1), child: child),
                    ),
                    child: Container(
                      width: 286,
                      height: 232,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(42),
                        border: Border.all(color: AppColors.blush, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.red.withValues(alpha: .2),
                            blurRadius: 44,
                            offset: const Offset(0, 22),
                          ),
                        ],
                      ),
                      child: const HungrySpotLogo(size: 265),
                    ),
                  ),
                  const Spacer(flex: 2),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: const SizedBox(
                      width: 112,
                      child: LinearProgressIndicator(
                        minHeight: 4,
                        color: AppColors.red,
                        backgroundColor: AppColors.blush,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.white, Color(0xFFFFF4F5)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: _orb(270, AppColors.red.withValues(alpha: .1)),
          ),
          Positioned(
            left: -86,
            bottom: 72,
            child: _orb(190, AppColors.red.withValues(alpha: .07)),
          ),
          Positioned(
            top: 132,
            left: 32,
            child: _orb(18, AppColors.red.withValues(alpha: .18)),
          ),
        ],
      ),
    );
  }

  Widget _orb(double size, Color color) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
