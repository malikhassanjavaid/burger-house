import 'package:flutter/material.dart';

import 'auth_form_widgets.dart';

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.hintText = 'Enter Password',
  });

  final TextEditingController controller;
  final String label;
  final String hintText;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return AuthFieldFrame(
      label: widget.label,
      child: TextFormField(
        controller: widget.controller,
        obscureText: _hidden,
        style: const TextStyle(
          color: authInk,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        decoration: authInputDecoration(
          widget.hintText,
          suffixIcon: IconButton(
            tooltip: _hidden ? 'Show password' : 'Hide password',
            onPressed: () => setState(() => _hidden = !_hidden),
            icon: Icon(
              _hidden
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: authInk,
              size: 23,
            ),
          ),
        ),
        validator: (value) =>
            (value ?? '').length < 6 ? 'Use at least 6 characters' : null,
      ),
    );
  }
}
