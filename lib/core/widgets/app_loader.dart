import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Hungry Spot's single, text-free loading indicator.
class AppLoader extends StatelessWidget {
  const AppLoader({
    super.key,
    this.size = 38,
    this.strokeWidth = 3.2,
    this.color = AppColors.red,
    this.trackColor = const Color(0xFFF2DDE0),
    this.semanticsLabel = 'Loading',
  });

  final double size;
  final double strokeWidth;
  final Color color;
  final Color trackColor;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel,
      liveRegion: true,
      child: SizedBox.square(
        dimension: size,
        child: CircularProgressIndicator(
          color: color,
          backgroundColor: trackColor,
          strokeWidth: strokeWidth,
          strokeCap: StrokeCap.round,
        ),
      ),
    );
  }
}

/// Blocks interaction and presents the shared loader over an in-progress view.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.loading,
    required this.child,
    this.semanticsLabel = 'Loading',
  });

  final bool loading;
  final Widget child;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !loading,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          child,
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: loading
                  ? _LoaderLayer(
                      key: const ValueKey('app-loading-overlay'),
                      semanticsLabel: semanticsLabel,
                    )
                  : const SizedBox.shrink(key: ValueKey('app-loading-ready')),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoaderLayer extends StatelessWidget {
  const _LoaderLayer({super.key, required this.semanticsLabel});

  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xC7F5F9FC),
      child: AbsorbPointer(
        child: Center(
          child: Container(
            width: 66,
            height: 66,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE6EBEF)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x18304A5C),
                  blurRadius: 22,
                  offset: Offset(0, 9),
                ),
              ],
            ),
            child: AppLoader(
              size: 31,
              strokeWidth: 3,
              semanticsLabel: semanticsLabel,
            ),
          ),
        ),
      ),
    );
  }
}
