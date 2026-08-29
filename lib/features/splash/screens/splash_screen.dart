import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/services/onboarding_preferences.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../auth/screens/authenticated_entry_screen.dart';
import '../../auth/services/auth_repository.dart';
import '../../auth/services/auth_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({
    super.key,
    this.repository,
    this.splashDuration = const Duration(milliseconds: 1800),
  });

  final AuthRepository? repository;
  final Duration splashDuration;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Timer? _timer;
  AuthRepository? _resolvedRepository;
  bool _hasNavigated = false;

  AuthRepository get _repository =>
      _resolvedRepository ??= widget.repository ?? AuthService();

  @override
  void initState() {
    super.initState();
    _timer = Timer(widget.splashDuration, _continueFromSplash);
  }

  Future<void> _continueFromSplash() async {
    if (!mounted || _hasNavigated) return;
    try {
      if (_repository.hasAuthenticatedUser) {
        _replaceWithVerifiedEntry();
        return;
      }

      var hasCompletedOnboarding = false;
      try {
        hasCompletedOnboarding = await OnboardingPreferences.hasCompleted()
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        // A fresh install still proceeds if local preferences are delayed.
      }
      if (!mounted || _hasNavigated) return;
      _replaceNamed(
        hasCompletedOnboarding ? AppRoutes.login : AppRoutes.onboarding,
      );
    } catch (_) {
      if (!mounted || _hasNavigated) return;
      // A restored authenticated session is never allowed to fall through to
      // home. The shared entry screen performs the trusted phone check.
      if (_repository.hasAuthenticatedUser) {
        _replaceWithVerifiedEntry();
      } else {
        _replaceNamed(AppRoutes.onboarding);
      }
    }
  }

  void _replaceWithVerifiedEntry() {
    _replace(
      MaterialPageRoute<void>(
        builder: (_) => AuthenticatedEntryScreen(repository: _repository),
      ),
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
