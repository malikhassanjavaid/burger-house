import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/international_phone_input.dart';
import '../services/auth_repository.dart';
import '../services/auth_service.dart';
import '../widgets/auth_form_widgets.dart';
import '../widgets/auth_loading_overlay.dart';
import '../widgets/password_field.dart';
import 'authenticated_entry_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({this.initialEmail = '', this.repository, super.key});

  final String initialEmail;
  final AuthRepository? repository;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final AuthRepository _repository;
  String _phoneNumber = '';
  String _phoneCountryCode = 'US';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? AuthService();
    _email.text = widget.initialEmail;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate() || _isLoading) return;

    setState(() => _isLoading = true);
    try {
      final name = _name.text.trim();
      await _repository.register(
        name: name,
        email: _email.text,
        phone: _phoneNumber,
        password: _password.text,
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute<void>(
          builder: (_) => AuthenticatedEntryScreen(
            repository: _repository,
            initialPhone: _phoneNumber,
            initialPhoneCountryCode: _phoneCountryCode,
            showWelcome: true,
            welcomeName: name,
          ),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;
      AppNotification.show(
        context,
        message: friendlyAuthError(error),
        tone: AppNotificationTone.error,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthLoadingOverlay(
      loading: _isLoading,
      message: 'Securing your account...',
      child: AuthFormShell(
        headline: 'Create your\naccount',
        topSpacing: 18,
        headlineFontSize: 25,
        headlineFontWeight: FontWeight.w700,
        logoSize: 150,
        logoContentScale: 1.08,
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
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Enter your name' : null,
              ),
              const SizedBox(height: 11),
              AuthTextField(
                controller: _email,
                label: 'Email',
                hintText: 'Enter Email',
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                validator: (value) => isValidEmailAddress(value ?? '')
                    ? null
                    : 'Enter a valid email address',
              ),
              const SizedBox(height: 11),
              AuthFieldFrame(
                label: 'Phone number',
                child: InternationalPhoneInput(
                  value: _phoneNumber,
                  onChanged: (value) => _phoneNumber = value,
                  countrySelectorKey: const ValueKey(
                    'signup-phone-country-selector',
                  ),
                  phoneFieldKey: const ValueKey('signup-phone-number-input'),
                  defaultCountryCode: 'US',
                  onCountryChanged: (country) {
                    _phoneCountryCode = country.countryCode;
                  },
                  validator: validateInternationalPhoneNumber,
                  fieldDecoration: authInputDecoration('Enter Phone Number'),
                  countryBorderColor: authBorder,
                  countryAccentColor: AppColors.red,
                  textStyle: AppTypography.bodyMedium.copyWith(
                    color: authInk,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 11),
              PasswordField(controller: _password),
              const SizedBox(height: 18),
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
