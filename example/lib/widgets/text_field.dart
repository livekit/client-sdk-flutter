import 'package:flutter/material.dart';

import '../theme.dart';

class LKTextField extends StatelessWidget {
  final String label;
  final TextEditingController? ctrl;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  const LKTextField({
    required this.label,
    this.ctrl,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: LKColors.fgDark,
              ),
            ),
          ),
          TextField(
            controller: ctrl,
            obscureText: obscureText,
            keyboardType: keyboardType,
            autocorrect: false,
            style: const TextStyle(fontSize: 15, color: LKColors.fgDark),
            cursorColor: LKColors.fgDark,
            decoration: InputDecoration(
              prefixIcon: icon == null ? null : Icon(icon, size: 18),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 42,
                minHeight: 44,
              ),
            ),
          ),
        ],
      );
}
