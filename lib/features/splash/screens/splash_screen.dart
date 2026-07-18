import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/burger_logo.dart';
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
    _timer = Timer(const Duration(seconds: 2), _continueFromSplash);
  }

  Future<void> _continueFromSplash() async {
    final authService = AuthService();
    if (!mounted) return;
    if (authService.currentUser == null) {
      Navigator.pushReplacementNamed(context, AppRoutes.onboarding);
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
    return const Scaffold(
      backgroundColor: AppColors.orange,
      body: Center(child: BurgerLogo()),
    );
  }
}
