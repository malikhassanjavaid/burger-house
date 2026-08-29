import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../services/auth_repository.dart';
import '../services/auth_service.dart';
import '../widgets/auth_form_widgets.dart';
import '../widgets/auth_loading_overlay.dart';
import '../widgets/password_field.dart';
import 'authenticated_entry_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.repository});

  final AuthRepository? repository;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AuthRepository _repository;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AuthService();
  }

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
      await _repository.signIn(email: _email.text, password: _password.text);
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(
          builder: (_) => AuthenticatedEntryScreen(repository: _repository),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      if (isSignInCredentialError(error)) {
        await _showAccountHelp(error);
      } else {
        AppNotification.show(
          context,
          message: friendlyAuthError(error),
          tone: AppNotificationTone.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
                style: AppTypography.pageHeader,
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
              AppPrimaryButton(
                label: 'CREATE AN ACCOUNT',
                onPressed: () {
                  Navigator.pop(sheetContext);
                  Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => RegisterScreen(
                        initialEmail: _email.text.trim(),
                        repository: _repository,
                      ),
                    ),
                  );
                },
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
        topSpacing: 18,
        headlineFontSize: 25,
        headlineFontWeight: FontWeight.w700,
        logoSize: 150,
        logoContentScale: 1.08,
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
              const SizedBox(height: 14),
              PasswordField(controller: _password),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: AuthLinkButton(
                  label: 'Forgot your password?',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.forgotPassword),
                ),
              ),
              const SizedBox(height: 24),
              AuthFooterPrompt(
                message: 'Not a member yet?',
                actionLabel: 'Sign up',
                onPressed: () =>
                    Navigator.pushNamed(context, AppRoutes.register),
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.center,
                child: AuthLinkButton(
                  label: 'Privacy & account information',
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.privacyAccount),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
