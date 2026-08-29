import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

enum AppHaptic { none, selection, light, medium }

/// Adds consistent press compression and optional haptics without replacing
/// the semantics or gesture behavior owned by the wrapped Material control.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = .97,
    this.alignment = Alignment.center,
  });

  final Widget child;
  final bool enabled;
  final double pressedScale;
  final Alignment alignment;

  static VoidCallback? withFeedback(
    VoidCallback? action, {
    AppHaptic haptic = AppHaptic.light,
  }) {
    if (action == null) return null;
    return () {
      switch (haptic) {
        case AppHaptic.none:
          break;
        case AppHaptic.selection:
          HapticFeedback.selectionClick();
          break;
        case AppHaptic.light:
          HapticFeedback.lightImpact();
          break;
        case AppHaptic.medium:
          HapticFeedback.mediumImpact();
          break;
      }
      action();
    };
  }

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;
  int? _activePointer;
  Offset? _pointerOrigin;

  void _setPressed(bool value) {
    if ((value && !widget.enabled) || _pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handlePointerDown(PointerDownEvent event) {
    if (!widget.enabled || _activePointer != null) return;
    _activePointer = event.pointer;
    _pointerOrigin = event.position;
    _setPressed(true);
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (event.pointer != _activePointer || !_pressed) return;
    final origin = _pointerOrigin;
    if (origin != null && (event.position - origin).distance > 12) {
      _setPressed(false);
    }
  }

  void _finishPointer(PointerEvent event) {
    if (event.pointer != _activePointer) return;
    _activePointer = null;
    _pointerOrigin = null;
    _setPressed(false);
  }

  @override
  void didUpdateWidget(covariant AppPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _pressed) _pressed = false;
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: _handlePointerDown,
      onPointerMove: _handlePointerMove,
      onPointerUp: _finishPointer,
      onPointerCancel: _finishPointer,
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: const Duration(milliseconds: 90),
        curve: Curves.easeOutCubic,
        alignment: widget.alignment,
        child: widget.child,
      ),
    );
  }
}
