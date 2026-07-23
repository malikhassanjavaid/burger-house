import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/onboarding_preferences.dart';
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
      var hasCompletedOnboarding = false;
      try {
        hasCompletedOnboarding = await OnboardingPreferences.hasCompleted();
      } catch (_) {
        // Fall back to onboarding when local preferences are unavailable.
      }
      if (!mounted) return;
      Navigator.pushReplacementNamed(
        context,
        hasCompletedOnboarding ? AppRoutes.login : AppRoutes.onboarding,
      );
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoSize = (constraints.maxWidth * .74).clamp(248.0, 292.0);
            return Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: .94, end: 1),
                duration: const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Transform.scale(
                  scale: value,
                  child: Opacity(opacity: value, child: child),
                ),
                child: HungrySpotLogo(size: logoSize, contentScale: 1.04),
              ),
            );
          },
        ),
      ),
    );
  }
}
