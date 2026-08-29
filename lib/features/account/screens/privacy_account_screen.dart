import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routes/app_routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_notification.dart';
import '../../../core/widgets/app_pressable.dart';
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
      backgroundColor: const Color(0xFFFFFAFA),
      body: Column(
        children: [
          ProfilePageHeader(
            title: 'Privacy & account',
            onBack: () => Navigator.maybePop(context),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 36),
              children: [
                const _AccountHero(),
                const SizedBox(height: 24),
                const _AccountSectionIntro(),
                const SizedBox(height: 13),
                _AccountLinkCard(
                  icon: Icons.shield_outlined,
                  title: 'Privacy policy',
                  description:
                      'See what Hungry Spot collects, why it is needed, and how your information is protected.',
                  actionLabel: 'VIEW POLICY',
                  onPressed: () => _openExternal(AppConfig.privacyPolicyUrl),
                ),
                const SizedBox(height: 12),
                _AccountLinkCard(
                  icon: Icons.manage_accounts_outlined,
                  title: 'Account deletion information',
                  description:
                      'Review the deletion process from any browser, even if you no longer have the app.',
                  actionLabel: 'VIEW ONLINE',
                  onPressed: () => _openExternal(AppConfig.accountDeletionUrl),
                ),
                if (AppConfig.supportEmail.isNotEmpty) ...[
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 30),
                  const Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.red,
                        size: 17,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'DANGER ZONE',
                        style: TextStyle(
                          color: AppColors.red,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Container(
                    key: const ValueKey('privacy-danger-zone'),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFFCDD3)),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.red.withValues(alpha: .07),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            _DangerIcon(),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Delete Hungry Spot account',
                                style: TextStyle(
                                  color: profilePageInk,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Your profile, addresses, favorites, and order history will be permanently removed.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            height: 1.45,
                            fontWeight: FontWeight.w500,
                          ),
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
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'Hungry Spot privacy protection banner',
      child: Container(
        key: const ValueKey('privacy-security-banner'),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF4A57), AppColors.redDark],
          ),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.red.withValues(alpha: .24),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -42,
              top: -62,
              child: Container(
                width: 166,
                height: 166,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white.withValues(alpha: .14),
                    width: 22,
                  ),
                ),
              ),
            ),
            Positioned(
              right: 58,
              bottom: -64,
              child: Container(
                width: 118,
                height: 118,
                decoration: BoxDecoration(
                  color: AppColors.brandYellow.withValues(alpha: .16),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(21, 21, 17, 21),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 320;
                  return Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 9,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: .16),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: .22),
                                ),
                              ),
                              child: const Text(
                                'PRIVACY CENTER',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            const SizedBox(height: 13),
                            const Text(
                              'Your privacy, protected',
                              maxLines: 2,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                height: 1.08,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -.55,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Simple controls for your data and Hungry Spot account.',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: .82),
                                fontSize: 12,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 14),
                            const _ControlBadge(),
                          ],
                        ),
                      ),
                      SizedBox(width: compact ? 8 : 14),
                      _SecurityArtwork(size: compact ? 70 : 82),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ControlBadge extends StatelessWidget {
  const _ControlBadge();

  @override
  Widget build(BuildContext context) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.fromLTRB(7, 6, 10, 6),
        decoration: BoxDecoration(
          color: const Color(0xFF9E1022).withValues(alpha: .42),
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 9,
              backgroundColor: AppColors.brandYellow,
              child: Icon(
                Icons.check_rounded,
                color: AppColors.redDark,
                size: 13,
              ),
            ),
            SizedBox(width: 7),
            Text(
              'You stay in control',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SecurityArtwork extends StatelessWidget {
  const _SecurityArtwork({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .14),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: .28),
                width: 1.5,
              ),
            ),
            alignment: Alignment.center,
            child: Container(
              width: size * .66,
              height: size * .66,
              decoration: const BoxDecoration(
                color: AppColors.brandYellow,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: AppColors.redDark,
                size: size * .37,
              ),
            ),
          ),
          Positioned(
            right: -1,
            bottom: 2,
            child: Container(
              width: size * .27,
              height: size * .27,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.red, width: 2),
              ),
              child: Icon(
                Icons.lock_rounded,
                color: AppColors.red,
                size: size * .14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSectionIntro extends StatelessWidget {
  const _AccountSectionIntro();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionIcon(),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage your information',
                style: TextStyle(
                  color: profilePageInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.25,
                ),
              ),
              SizedBox(height: 4),
              Text(
                'Review our policies or get help with your account.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12.5,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionIcon extends StatelessWidget {
  const _SectionIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 39,
      height: 39,
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.verified_user_outlined,
        color: AppColors.red,
        size: 21,
      ),
    );
  }
}

class _DangerIcon extends StatelessWidget {
  const _DangerIcon();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.blush,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.delete_forever_outlined,
        color: AppColors.red,
        size: 22,
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
    final feedbackOnPressed = AppPressable.withFeedback(
      onPressed,
      haptic: AppHaptic.selection,
    );
    return Semantics(
      button: true,
      label: 'Open $title',
      onTap: feedbackOnPressed,
      excludeSemantics: true,
      child: AppPressable(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF32151A).withValues(alpha: .06),
                blurRadius: 18,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: feedbackOnPressed,
              splashColor: AppColors.red.withValues(alpha: .10),
              highlightColor: AppColors.red.withValues(alpha: .04),
              child: Ink(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFF0E5E7)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFFF0F2), AppColors.blush],
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Icon(icon, color: AppColors.red, size: 23),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              color: profilePageInk,
                              fontSize: 14.5,
                              height: 1.2,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            description,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11.5,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            actionLabel,
                            style: const TextStyle(
                              color: AppColors.red,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: .65,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3F4),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: AppColors.red,
                        size: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
