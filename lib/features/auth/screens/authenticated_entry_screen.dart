import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_loader.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../../core/widgets/brand_logo.dart';
import '../../home/screens/home_screen.dart';
import '../../location/models/delivery_location.dart';
import '../../location/screens/location_setup_screen.dart';
import '../services/auth_repository.dart';
import '../services/auth_service.dart';
import '../widgets/phone_verification_sheet.dart';

/// The only route allowed to resolve an authenticated customer into app
/// content. Firebase's linked phone provider is checked before profile,
/// location, or home navigation occurs.
class AuthenticatedEntryScreen extends StatefulWidget {
  const AuthenticatedEntryScreen({
    super.key,
    this.repository,
    this.initialPhone = '',
    this.showWelcome = false,
    this.welcomeName,
  });

  final AuthRepository? repository;
  final String initialPhone;
  final bool showWelcome;
  final String? welcomeName;

  @override
  State<AuthenticatedEntryScreen> createState() =>
      _AuthenticatedEntryScreenState();
}

class _AuthenticatedEntryScreenState extends State<AuthenticatedEntryScreen> {
  late final AuthRepository _repository;
  bool _resolutionStarted = false;
  bool _navigationClaimed = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AuthService();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  Future<void> _resolve() async {
    if (_resolutionStarted || _navigationClaimed || !mounted) return;
    _resolutionStarted = true;
    setState(() => _errorMessage = null);

    try {
      if (!_repository.hasAuthenticatedUser) {
        _replaceNamed(AppRoutes.login);
        return;
      }

      var verified = await _repository.hasVerifiedPhoneSession();
      if (!mounted || _navigationClaimed) return;

      if (!verified) {
        verified = await showPhoneVerificationSheet(
          context,
          client: _repository,
          initialPhone: widget.initialPhone,
        );
        if (!mounted || _navigationClaimed) return;

        if (verified) {
          // The sheet reports success only after linking, but this second
          // provider check prevents a custom client callback from granting
          // access without a real linked Firebase phone identity.
          verified = await _repository.hasVerifiedPhoneSession();
          if (!mounted || _navigationClaimed) return;
        }
      }

      if (!verified) {
        try {
          await _repository.signOut();
        } catch (_) {
          // The local route remains protected even if provider cleanup is
          // temporarily unavailable.
        }
        if (!mounted || _navigationClaimed) return;
        _replaceNamed(AppRoutes.login);
        return;
      }

      try {
        await _repository.syncVerifiedCustomerProfile();
      } on FirebaseException {
        if (!mounted || _navigationClaimed) return;
        AppNotification.show(
          context,
          message:
              'Your phone is verified. Profile details will finish syncing when the connection is restored.',
          tone: AppNotificationTone.info,
        );
      }
      if (!mounted || _navigationClaimed) return;

      final location = await _repository.getDeliveryLocation();
      if (!mounted || _navigationClaimed) return;
      _routeAfterVerification(location);
    } catch (error) {
      if (!mounted || _navigationClaimed) return;
      setState(() {
        _errorMessage = friendlyAuthError(error);
        _resolutionStarted = false;
      });
    }
  }

  void _routeAfterVerification(DeliveryLocation? location) {
    if (location == null) {
      _replace(
        MaterialPageRoute<void>(
          builder: (_) => LocationSetupScreen(
            firstTime: true,
            destinationAfterSave: HomeScreen(
              showNewAccountWelcome: widget.showWelcome,
              welcomeName: widget.welcomeName,
            ),
          ),
        ),
      );
      return;
    }

    if (widget.showWelcome || widget.welcomeName != null) {
      _replace(
        MaterialPageRoute<void>(
          builder: (_) => HomeScreen(
            showNewAccountWelcome: widget.showWelcome,
            welcomeName: widget.welcomeName,
          ),
        ),
      );
      return;
    }
    _replaceNamed(AppRoutes.home);
  }

  void _replaceNamed(String routeName) {
    if (!mounted || _navigationClaimed) return;
    _navigationClaimed = true;
    Navigator.pushNamedAndRemoveUntil(context, routeName, (route) => false);
  }

  void _replace(Route<void> route) {
    if (!mounted || _navigationClaimed) return;
    _navigationClaimed = true;
    Navigator.pushAndRemoveUntil(context, route, (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final error = _errorMessage;
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: error == null
                ? const _ResolvingAccountView()
                : _EntryErrorView(error: error, onRetry: _resolve),
          ),
        ),
      ),
    );
  }
}

class _ResolvingAccountView extends StatelessWidget {
  const _ResolvingAccountView();

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        HungrySpotLogo(size: 160, contentScale: 1.04),
        SizedBox(height: 24),
        AppLoader(semanticsLabel: 'Securing your account'),
        SizedBox(height: 16),
        Text(
          'Securing your account…',
          style: AppTypography.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _EntryErrorView extends StatelessWidget {
  const _EntryErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: AppColors.blush,
            child: Icon(Icons.shield_outlined, color: AppColors.red, size: 34),
          ),
          const SizedBox(height: 18),
          Text(
            'We could not finish securely',
            style: AppTypography.pageHeader,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(error, style: AppTypography.body, textAlign: TextAlign.center),
          const SizedBox(height: 22),
          AppPrimaryButton(
            key: const ValueKey('authenticated-entry-retry'),
            label: 'TRY AGAIN',
            icon: Icons.refresh_rounded,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
