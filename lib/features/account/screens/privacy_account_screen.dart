import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/app_primary_button.dart';
import '../../home/widgets/profile_page_header.dart';
import '../services/account_deletion_service.dart';

class PrivacyAccountScreen extends StatefulWidget {
  const PrivacyAccountScreen({
    super.key,
    this.deletionService,
    this.canDeleteAccount,
    this.signOut,
    this.onDeleted,
  });

  final AccountDeletionService? deletionService;
  final bool? canDeleteAccount;
  final Future<void> Function()? signOut;
  final VoidCallback? onDeleted;

  @override
  State<PrivacyAccountScreen> createState() => _PrivacyAccountScreenState();
}

class _PrivacyAccountScreenState extends State<PrivacyAccountScreen> {
  bool _deleting = false;

  bool get _canDeleteAccount =>
      widget.canDeleteAccount ?? FirebaseAuth.instance.currentUser != null;

  Future<void> _openExternal(String value) async {
    final uri = Uri.tryParse(value);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (!mounted) return;
      AppNotification.show(
        context,
        message: 'That link could not be opened on this device.',
        tone: AppNotificationTone.error,
      );
    }
  }

  Future<bool> _confirmDeletion() async {
    var enabled = false;
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Delete your account?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This permanently removes your Hungry Spot profile, saved details, and order history. This cannot be undone.',
              ),
              const SizedBox(height: 18),
              const Text(
                'Type DELETE to confirm',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              TextField(
                key: const ValueKey('delete-account-confirmation'),
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.characters,
                onChanged: (value) =>
                    setDialogState(() => enabled = value.trim() == 'DELETE'),
                decoration: const InputDecoration(hintText: 'DELETE'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('CANCEL'),
            ),
            FilledButton(
              key: const ValueKey('confirm-delete-account'),
              onPressed: enabled
                  ? () => Navigator.pop(dialogContext, true)
                  : null,
              style: FilledButton.styleFrom(backgroundColor: AppColors.red),
              child: const Text('DELETE ACCOUNT'),
            ),
          ],
        ),
      ),
    );
    return confirmed == true;
  }

  Future<void> _deleteAccount() async {
    if (_deleting || !await _confirmDeletion()) return;
    setState(() => _deleting = true);
    try {
      await (widget.deletionService ?? AccountDeletionService())
          .deleteAccount();
      await (widget.signOut ?? FirebaseAuth.instance.signOut)();
      if (!mounted) return;
      setState(() => _deleting = false);
      if (widget.onDeleted != null) {
        widget.onDeleted!();
      } else {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRoutes.login,
          (route) => false,
        );
      }
    } on AccountDeletionException catch (error) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppNotification.show(
        context,
        message: error.message,
        tone: AppNotificationTone.error,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      AppNotification.show(
        context,
        message: 'We could not delete your account. Please try again.',
        tone: AppNotificationTone.error,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: profilePageBackground,
      body: Column(
        children: [
          ProfilePageHeader(
            title: 'Privacy & account',
            onBack: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              children: [
                const _AccountHero(),
                const SizedBox(height: 20),
                _AccountLinkCard(
                  icon: Icons.shield_outlined,
                  title: 'Privacy policy',
                  description:
                      'See what Hungry Spot collects, why it is needed, and how your information is protected.',
                  actionLabel: 'VIEW POLICY',
                  onPressed: () => _openExternal(AppConfig.privacyPolicyUrl),
                ),
                const SizedBox(height: 14),
                _AccountLinkCard(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Account deletion information',
                  description:
                      'Review the deletion process from any browser, even if you no longer have the app.',
                  actionLabel: 'VIEW ONLINE',
                  onPressed: () => _openExternal(AppConfig.accountDeletionUrl),
                ),
                if (AppConfig.supportEmail.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  _AccountLinkCard(
                    icon: Icons.support_agent_rounded,
                    title: 'Contact support',
                    description: AppConfig.supportEmail,
                    actionLabel: 'EMAIL SUPPORT',
                    onPressed: () => _openExternal(
                      'mailto:${AppConfig.supportEmail}?subject=Hungry%20Spot%20support',
                    ),
                  ),
                ],
                if (_canDeleteAccount) ...[
                  const SizedBox(height: 28),
                  const Text(
                    'DANGER ZONE',
                    style: TextStyle(
                      color: AppColors.red,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.blush,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFFFC9D0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delete Hungry Spot account',
                          style: TextStyle(
                            color: profilePageInk,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 7),
                        const Text(
                          'Your profile, addresses, favorites, and order history will be permanently removed.',
                          style: AppTypography.body,
                        ),
                        const SizedBox(height: 16),
                        AppPrimaryButton(
                          key: const ValueKey('delete-account'),
                          label: 'DELETE ACCOUNT',
                          icon: Icons.delete_outline_rounded,
                          isLoading: _deleting,
                          onPressed: _deleteAccount,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountHero extends StatelessWidget {
  const _AccountHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: AppColors.red,
            child: Icon(Icons.lock_outline_rounded, color: Colors.white),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your data, your choice',
                  style: TextStyle(
                    color: profilePageInk,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Clear controls for privacy, support, and account removal.',
                  style: AppTypography.body,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountLinkCard extends StatelessWidget {
  const _AccountLinkCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE7EAEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.blush,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: AppColors.red, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: profilePageInk,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(description, style: AppTypography.body),
          const SizedBox(height: 10),
          TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              foregroundColor: AppColors.red,
              minimumSize: const Size(48, 48),
              padding: const EdgeInsets.symmetric(horizontal: 0),
              alignment: Alignment.centerLeft,
            ),
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}
