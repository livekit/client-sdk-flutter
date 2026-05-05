import 'package:flutter/material.dart';

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
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              label,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
          TextField(
            controller: ctrl,
            obscureText: obscureText,
            keyboardType: keyboardType,
            autocorrect: false,
            decoration: InputDecoration(
              prefixIcon: icon == null ? null : Icon(icon),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 16,
                horizontal: 15,
              ),
            ),
          ),
        ],
      );
}
