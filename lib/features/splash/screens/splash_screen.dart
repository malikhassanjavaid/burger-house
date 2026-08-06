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
  static const _splashDuration = Duration(milliseconds: 1800);
  static const _startupTimeout = Duration(seconds: 6);

  Timer? _timer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer(_splashDuration, _continueFromSplash);
  }

  Future<void> _continueFromSplash() async {
    final authService = AuthService();
    try {
      await _resolveDestination(authService).timeout(_startupTimeout);
    } on TimeoutException {
      _useStartupFallback(authService);
    } catch (_) {
      _useStartupFallback(authService);
    }
  }

  Future<void> _resolveDestination(AuthService authService) async {
    if (!mounted || _hasNavigated) return;
    if (authService.currentUser == null) {
      var hasCompletedOnboarding = false;
      try {
        hasCompletedOnboarding = await OnboardingPreferences.hasCompleted()
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        // A fresh install should still continue when local storage is delayed.
      }
      _replaceNamed(
        hasCompletedOnboarding ? AppRoutes.login : AppRoutes.onboarding,
      );
      return;
    }

    final verified = await authService.hasVerifiedSession().timeout(
      const Duration(seconds: 4),
      onTimeout: () => authService.currentUser?.emailVerified ?? false,
    );
    if (!verified) {
      try {
        await authService.signOut().timeout(const Duration(seconds: 2));
      } catch (_) {
        // Navigation must not wait forever for a provider sign-out.
      }
      _replaceNamed(AppRoutes.login);
      return;
    }

    try {
      final location = await authService.getDeliveryLocation().timeout(
        const Duration(seconds: 4),
      );
      if (location == null) {
        _replace(
          MaterialPageRoute(
            builder: (_) => const LocationSetupScreen(
              firstTime: true,
              destinationAfterSave: HomeScreen(),
            ),
          ),
        );
      } else {
        _replaceNamed(AppRoutes.home);
      }
    } catch (_) {
      // A verified customer can enter with cached authentication while
      // Firestore is temporarily offline.
      _replaceNamed(AppRoutes.home);
    }
  }

  void _useStartupFallback(AuthService authService) {
    if (!mounted || _hasNavigated) return;
    _replaceNamed(
      authService.currentUser == null ? AppRoutes.onboarding : AppRoutes.home,
    );
  }

  void _replaceNamed(String routeName) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.pushReplacementNamed(context, routeName);
  }

  void _replace(Route<void> route) {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;
    Navigator.pushReplacement(context, route);
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
