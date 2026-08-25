import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum AppNotificationTone { info, success, error }

abstract final class AppNotification {
  static const defaultDuration = Duration(seconds: 5);

  static OverlayEntry? _currentEntry;
  static Timer? _dismissTimer;

  static void show(
    BuildContext context, {
    required String message,
    AppNotificationTone tone = AppNotificationTone.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = defaultDuration,
  }) {
    _removeCurrent();

    final overlay = Overlay.of(context, rootOverlay: true);
    late final OverlayEntry entry;

    void dismiss() {
      if (!identical(_currentEntry, entry)) return;
      _dismissTimer?.cancel();
      _dismissTimer = null;
      if (entry.mounted) entry.remove();
      _currentEntry = null;
    }

    entry = OverlayEntry(
      builder: (overlayContext) {
        final mediaQuery = MediaQuery.of(overlayContext);
        final compact = mediaQuery.size.width < 600;
        return Positioned(
          top: mediaQuery.padding.top + 12,
          right: 12,
          left: compact ? 12 : null,
          width: compact ? null : 360,
          child: _AppNotificationCard(
            message: message,
            tone: tone,
            actionLabel: actionLabel,
            onAction: actionLabel != null && onAction != null
                ? () {
                    dismiss();
                    onAction();
                  }
                : null,
          ),
        );
      },
    );

    _currentEntry = entry;
    overlay.insert(entry);
    _dismissTimer = Timer(duration, dismiss);
  }

  static void _removeCurrent() {
    _dismissTimer?.cancel();
    _dismissTimer = null;
    final entry = _currentEntry;
    _currentEntry = null;
    if (entry?.mounted ?? false) entry!.remove();
  }
}

class _AppNotificationCard extends StatelessWidget {
  const _AppNotificationCard({
    required this.message,
    required this.tone,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final AppNotificationTone tone;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final palette = switch (tone) {
      AppNotificationTone.info => const (
        icon: Icons.info_outline_rounded,
        accent: Color(0xFF1597E5),
        background: Color(0xFF17212F),
      ),
      AppNotificationTone.success => const (
        icon: Icons.check_circle_outline_rounded,
        accent: Color(0xFF35B976),
        background: Color(0xFF173126),
      ),
      AppNotificationTone.error => const (
        icon: Icons.error_outline_rounded,
        accent: AppColors.red,
        background: Color(0xFF351C22),
      ),
    };

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      tween: Tween(begin: 0, end: 1),
      builder: (context, value, child) => Opacity(
        opacity: value,
        child: Transform.translate(
          offset: Offset(22 * (1 - value), 0),
          child: child,
        ),
      ),
      child: Semantics(
        liveRegion: true,
        child: Material(
          key: const ValueKey('app-notification'),
          color: palette.background,
          elevation: 12,
          shadowColor: Colors.black38,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: palette.accent, width: 4)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(palette.icon, color: palette.accent, size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (actionLabel != null && onAction != null) ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: onAction,
                      style: TextButton.styleFrom(
                        foregroundColor: palette.accent,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(
                        actionLabel!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .3,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
