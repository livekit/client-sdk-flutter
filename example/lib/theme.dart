import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//
// Flutter has a color profile issue so colors will look different
// on Apple devices.
// https://github.com/flutter/flutter/issues/55092
// https://github.com/flutter/flutter/issues/39113
//

extension LKColors on Colors {
  static const lkBlue = Color(0xFF5A8BFF);
  static const lkDarkBlue = Color(0xFF00153C);
  static const lkGreen = Color(0xFF4DE2C2);
  static const lkRed = Color(0xFFFF5C7A);
  static const lkGray1 = Color(0xFF0B0D12);
  static const lkGray2 = Color(0xFF151922);
  static const lkGray3 = Color(0xFF252D3A);
  static const surface = Color(0xFF11151D);
  static const surfaceAlt = Color(0xFF1A202B);
  static const border = Color(0xFF2B3444);
  static const textPrimary = Colors.white;
  static const textSecondary = Color(0xFF9BA8BD);
}

class LiveKitTheme {
  //
  final bgColor = LKColors.lkGray1;
  final textColor = LKColors.textPrimary;
  final cardColor = LKColors.surface;
  final accentColor = LKColors.lkBlue;

  ThemeData buildThemeData(BuildContext ctx) {
    final baseTextTheme = GoogleFonts.interTextTheme(Theme.of(ctx).textTheme);
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      appBarTheme: AppBarTheme(
        backgroundColor: bgColor,
        foregroundColor: textColor,
        elevation: 0,
      ),
      cardColor: cardColor,
      scaffoldBackgroundColor: bgColor,
      canvasColor: bgColor,
      iconTheme: IconThemeData(color: textColor),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStateProperty.all<TextStyle>(
            baseTextTheme.labelLarge!.copyWith(fontWeight: FontWeight.w700),
          ),
          padding: WidgetStateProperty.all<EdgeInsets>(
            const EdgeInsets.symmetric(vertical: 18, horizontal: 22),
          ),
          shape: WidgetStateProperty.all<OutlinedBorder>(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return accentColor.withValues(alpha: 0.5);
            }
            return accentColor;
          }),
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        checkColor: WidgetStateProperty.all(Colors.white),
        fillColor: WidgetStateProperty.all(accentColor),
      ),
      switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return accentColor;
          }
          return LKColors.lkGray3;
        }),
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return Colors.white;
          }
          return LKColors.textSecondary;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: LKColors.surfaceAlt,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: LKColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor,
          side: const BorderSide(color: LKColors.border),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textColor,
          disabledForegroundColor: LKColors.textSecondary.withValues(
            alpha: 0.5,
          ),
        ),
      ),
      textTheme: baseTextTheme.apply(
        displayColor: textColor,
        bodyColor: textColor,
        decorationColor: textColor,
      ),
      hintColor: LKColors.textSecondary,
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: LKColors.lkBlue),
        hintStyle: TextStyle(
          color: LKColors.textSecondary.withValues(alpha: 0.8),
        ),
        filled: false,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: LKColors.border),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: LKColors.lkBlue),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
      ),
      colorScheme: ColorScheme.fromSeed(
        brightness: Brightness.dark,
        seedColor: accentColor,
        primary: accentColor,
        surface: bgColor,
        secondary: LKColors.lkGreen,
        error: LKColors.lkRed,
      ),
    );
  }
}
