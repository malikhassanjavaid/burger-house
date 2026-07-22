import 'package:flutter/material.dart';

import '../../../core/routes/app_routes.dart';
import '../services/auth_service.dart';
import '../widgets/auth_form_widgets.dart';
import '../widgets/auth_loading_overlay.dart';
import '../widgets/email_verification_sheet.dart';
import '../widgets/password_field.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({this.initialEmail = '', super.key});

  final String initialEmail;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _email.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      await _authService.register(
        name: _name.text,
        email: _email.text,
        phone: _phone.text,
        password: _password.text,
      );
      if (!mounted) return;
      await _showVerificationSent();
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

  Future<void> _showVerificationSent() async {
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => EmailVerificationSheet(
        email: _email.text.trim().toLowerCase(),
        title: 'Verify your Gmail',
        message:
            'We sent a verification link to your inbox. Open it to confirm this Gmail address, then return and log in.',
        primaryLabel: 'GO TO LOGIN',
        showSecondaryAction: false,
      ),
    );
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.login,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AuthLoadingOverlay(
      loading: _isLoading,
      message: 'Creating your account...',
      child: AuthFormShell(
        headline: 'Create your\naccount',
        topSpacing: 38,
        headlineFontSize: 23,
        headlineFontWeight: FontWeight.w500,
        logoSize: 210,
        logoContentScale: 1.24,
        bottomAction: AuthPrimaryButton(
          label: 'SIGN UP',
          icon: Icons.person_add_alt_1_rounded,
          loading: _isLoading,
          onPressed: _register,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AuthTextField(
                controller: _name,
                label: 'Full name',
                hintText: 'Enter Full Name',
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _email,
                label: 'Email',
                hintText: 'Enter Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (v) => isValidGmailAddress(v ?? '')
                    ? null
                    : 'Use a valid @gmail.com address',
              ),
              const SizedBox(height: 14),
              AuthTextField(
                controller: _phone,
                label: 'Phone number',
                hintText: 'Enter Phone Number',
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                validator: (v) =>
                    (v ?? '').length < 7 ? 'Enter a valid phone number' : null,
              ),
              const SizedBox(height: 14),
              PasswordField(controller: _password),
              const SizedBox(height: 26),
              AuthFooterPrompt(
                message: 'Already a member?',
                actionLabel: 'Log in',
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
