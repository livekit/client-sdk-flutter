import 'package:flutter/material.dart';

import '../theme.dart';

class LKTextField extends StatelessWidget {
  final String label;
  final TextEditingController? ctrl;
  const LKTextField({
    required this.label,
    this.ctrl,
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
                fontWeight: FontWeight.w500,
                color: LKColors.fgDark,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: LKColors.inputFillDark,
              border: Border.all(width: 1, color: LKColors.inputDark),
              borderRadius: BorderRadius.circular(6),
            ),
            child: TextField(
              controller: ctrl,
              style: const TextStyle(
                fontSize: 15,
                color: LKColors.fgDark,
              ),
              cursorColor: LKColors.fgDark,
              decoration: const InputDecoration.collapsed(hintText: ''),
              keyboardType: TextInputType.url,
              autocorrect: false,
            ),
          ),
        ],
      );
}
