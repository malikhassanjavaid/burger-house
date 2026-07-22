import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../home/screens/home_screen.dart';
import '../../location/screens/location_setup_screen.dart';
import '../services/auth_service.dart';
import '../widgets/auth_form_widgets.dart';
import '../widgets/auth_loading_overlay.dart';
import '../widgets/email_verification_sheet.dart';
import '../widgets/password_field.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _authService.signIn(email: _email.text, password: _password.text);
      await _continueAfterSignIn();
    } catch (error) {
      if (!mounted) return;
      if (isUnverifiedEmailError(error)) {
        await _showVerificationRequired();
      } else if (isSignInCredentialError(error)) {
        await _showAccountHelp(error);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(friendlyAuthError(error)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showVerificationRequired() async {
    final shouldResend = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmailVerificationSheet(
        email: _email.text.trim().toLowerCase(),
        title: 'Gmail not verified',
        message:
            'Open the verification link we sent before logging in. If it expired or is missing, request a new one.',
        primaryLabel: 'RESEND EMAIL',
      ),
    );
    if (shouldResend != true || !mounted) return;

    setState(() => _isLoading = true);
    try {
      await _authService.resendEmailVerification(
        email: _email.text,
        password: _password.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('A new verification email has been sent.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(friendlyAuthError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueAfterSignIn({
    bool showWelcome = false,
    String? welcomeName,
  }) async {
    if (!mounted) return;
    final location = await _authService.getDeliveryLocation();
    if (!mounted) return;
    if (location == null) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => LocationSetupScreen(
            firstTime: true,
            destinationAfterSave: HomeScreen(
              showNewAccountWelcome: showWelcome,
              welcomeName: welcomeName,
            ),
          ),
        ),
        (route) => false,
      );
      return;
    }
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.home,
      (route) => false,
    );
  }

  Future<void> _showAccountHelp(Object error) async {
    final missing = isDefinitelyMissingAccount(error);
    final cleanEmail = normalizeAuthEmail(_email.text);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => SafeArea(
        child: Container(
          margin: const EdgeInsets.all(12),
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 22),
              const CircleAvatar(
                radius: 29,
                backgroundColor: Color(0xFFFFEEE2),
                child: Icon(Icons.person_search_rounded, size: 30),
              ),
              const SizedBox(height: 16),
              Text(
                missing
                    ? 'Account not found'
                    : 'Email or password doesn\'t match',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                missing
                    ? 'There is no Hungry Spot account for $cleanEmail. Create one to start ordering.'
                    : 'Firebase could not match $cleanEmail with that password. If an earlier sign-up was interrupted, create the account again. Otherwise reset the password securely.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, height: 1.4),
              ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RegisterScreen(initialEmail: _email.text.trim()),
                      ),
                    );
                  },
                  child: const Text('Create an account'),
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    Navigator.pushNamed(context, AppRoutes.forgotPassword);
                  },
                  child: const Text('I have an account - reset password'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLoadingOverlay(
      loading: _isLoading,
      message: 'Signing you in...',
      child: AuthFormShell(
        headline: 'Log in to the\ngood stuff',
        topSpacing: 38,
        headlineFontSize: 23,
        headlineFontWeight: FontWeight.w500,
        logoSize: 210,
        logoContentScale: 1.24,
        bottomAction: AuthPrimaryButton(
          label: 'LOG IN',
          icon: Icons.login_rounded,
          loading: _isLoading,
          onPressed: _login,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _email,
                label: 'Email',
                hintText: 'Enter Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) => !(value ?? '').contains('@')
                    ? 'Enter a valid email address'
                    : null,
              ),
              const SizedBox(height: 18),
              PasswordField(controller: _password),
              const SizedBox(height: 19),
              Align(
                alignment: Alignment.centerLeft,
                child: AuthLinkButton(
                  label: 'Forgot your password?',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.forgotPassword),
                ),
              ),
              const SizedBox(height: 42),
              AuthFooterPrompt(
                message: 'Not a member yet?',
                actionLabel: 'Sign up',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.register),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
