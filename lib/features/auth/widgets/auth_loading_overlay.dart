import 'package:flutter/material.dart';

import '../../../core/widgets/app_loader.dart';

class AuthLoadingOverlay extends StatelessWidget {
  const AuthLoadingOverlay({
    required this.loading,
    required this.message,
    required this.child,
    super.key,
  });

  final bool loading;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppLoadingOverlay(
      loading: loading,
      semanticsLabel: message,
      child: child,
    );
  }
}
