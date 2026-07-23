import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../auth/services/auth_service.dart';
import '../widgets/profile_page_header.dart';

class ProfileDetailsScreen extends StatefulWidget {
  const ProfileDetailsScreen({super.key});

  @override
  State<ProfileDetailsScreen> createState() => _ProfileDetailsScreenState();
}

class _ProfileDetailsScreenState extends State<ProfileDetailsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();

  bool _loading = true;
  bool _saving = false;
  bool _saved = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Please sign in again to view your details.';
        });
      }
      return;
    }

    _name.text = user.displayName ?? '';
    _email.text = user.email ?? '';
    try {
      final document = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final data = document.data();
      if (data != null) {
        _name.text = (data['name'] as String?) ?? _name.text;
        _phone.text = (data['phone'] as String?) ?? '';
        _email.text = (data['email'] as String?) ?? _email.text;
      }
    } catch (error) {
      _error = friendlyAuthError(error);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate() || _saving) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() {
      _saving = true;
      _saved = false;
      _error = null;
    });
    try {
      final cleanName = _name.text.trim();
      final cleanPhone = _phone.text.trim();
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'name': cleanName,
        'email': user.email?.toLowerCase(),
        'phone': cleanPhone,
        'role': 'customer',
        'profileUpdatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      if (user.displayName != cleanName) {
        await user.updateDisplayName(cleanName);
      }
      if (!mounted) return;
      setState(() => _saved = true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = friendlyAuthError(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profilePageBackground,
      body: Column(
        children: [
          ProfilePageHeader(
            title: 'MY DETAILS',
            onBack: () => Navigator.pop(context, _saved),
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.red),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 34),
                    children: [
                      const Text(
                        'MY DETAILS',
                        style: TextStyle(
                          color: profilePageInk,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      const Text(
                        'Keep your contact information accurate for smooth deliveries.',
                        style: TextStyle(
                          color: profilePageMuted,
                          fontSize: 11.5,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Center(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              width: 94,
                              height: 94,
                              decoration: BoxDecoration(
                                color: AppColors.blush,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.red,
                                  width: 2,
                                ),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                _name.text.trim().isEmpty
                                    ? 'F'
                                    : _name.text.trim()[0].toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.red,
                                  fontSize: 36,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            Positioned(
                              right: -2,
                              bottom: 1,
                              child: Container(
                                width: 31,
                                height: 31,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: AppColors.red),
                                ),
                                child: const Icon(
                                  Icons.person_rounded,
                                  color: AppColors.red,
                                  size: 17,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            _ProfileField(
                              controller: _name,
                              label: 'Full name',
                              icon: Icons.person_outline_rounded,
                              textCapitalization: TextCapitalization.words,
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 2
                                  ? 'Enter your full name'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _ProfileField(
                              controller: _phone,
                              label: 'Phone number',
                              icon: Icons.phone_outlined,
                              keyboardType: TextInputType.phone,
                              validator: (value) =>
                                  (value?.trim().length ?? 0) < 7
                                  ? 'Enter a valid phone number'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            _ProfileField(
                              controller: _email,
                              label: 'Email address',
                              icon: Icons.mail_outline_rounded,
                              readOnly: true,
                            ),
                          ],
                        ),
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 14),
                        _InlineStatus(
                          message: _error!,
                          icon: Icons.error_outline_rounded,
                          color: AppColors.red,
                        ),
                      ],
                      if (_saved) ...[
                        const SizedBox(height: 14),
                        const _InlineStatus(
                          message: 'Your profile is up to date.',
                          icon: Icons.check_circle_outline_rounded,
                          color: Color(0xFF24A765),
                        ),
                      ],
                      const SizedBox(height: 22),
                      AppPrimaryButton(
                        label: 'UPDATE PROFILE',
                        onPressed: _saveProfile,
                        isLoading: _saving,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _ProfileField extends StatelessWidget {
  const _ProfileField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.validator,
    this.readOnly = false,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final String? Function(String?)? validator;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      style: TextStyle(
        color: readOnly ? profilePageMuted : profilePageInk,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: profilePageMuted, fontSize: 11.5),
        prefixIcon: Icon(icon, color: profilePageMuted, size: 19),
        filled: true,
        fillColor: readOnly ? const Color(0xFFF0F4F7) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: Color(0xFFDDE6EC)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(13),
          borderSide: const BorderSide(color: AppColors.red, width: 1.4),
        ),
      ),
    );
  }
}

class _InlineStatus extends StatelessWidget {
  const _InlineStatus({
    required this.message,
    required this.icon,
    required this.color,
  });

  final String message;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
