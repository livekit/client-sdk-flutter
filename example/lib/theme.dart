import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//
// Flutter has a color profile issue so colors will look different
// on Apple devices.
// https://github.com/flutter/flutter/issues/55092
// https://github.com/flutter/flutter/issues/39113

extension LKColors on Colors {
  // LiveKit brand accents.
  static const lkAccent = Color(0xFF002CF2);
  static const lkAccentDark = Color(0xFF1FD5F9);

  // Neutral scale.
  static const neutral50 = Color(0xFFFAFAFA);
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral200 = Color(0xFFE5E5E5);
  static const neutral300 = Color(0xFFD4D4D4);
  static const neutral400 = Color(0xFFA3A3A3);
  static const neutral500 = Color(0xFF737373);
  static const neutral600 = Color(0xFF525252);
  static const neutral700 = Color(0xFF404040);
  static const neutral800 = Color(0xFF262626);
  static const neutral900 = Color(0xFF171717);
  static const neutral950 = Color(0xFF0A0A0A);

  // Supporting semantic colors.
  static const emerald400 = Color(0xFF34D399);
  static const red400 = Color(0xFFF87171);

  static const bgDark = neutral950;
  static const fgDark = neutral50;
  static const cardDark = neutral900;
  static const primaryFgDark = neutral900;
  static const secondaryDark = neutral800;
  static const mutedFgDark = Color(0xFFA3A3A3);
  static const destructiveDark = red400;
  static const borderDark = Color(0x1AFFFFFF);
  static const inputDark = Color(0x26FFFFFF);
  static const inputFillDark = Color(0x0DFFFFFF);

  // Legacy aliases used by the example widgets.
  static const lkBlue = lkAccentDark;
  static const lkDarkBlue = neutral900;
  static const lkGreen = Color(0xFF4DE2C2);
  static const lkRed = Color(0xFFFF5C7A);
  static const lkGray1 = bgDark;
  static const lkGray2 = cardDark;
  static const lkGray3 = neutral800;
  static const surface = cardDark;
  static const surfaceAlt = neutral800;
  static const border = borderDark;
  static const textPrimary = fgDark;
  static const textSecondary = mutedFgDark;
}

class LiveKitTheme {
  final bgColor = LKColors.bgDark;
  final textColor = LKColors.fgDark;
  final cardColor = LKColors.cardDark;
  final accentColor = LKColors.lkAccentDark;
  final destructiveColor = LKColors.destructiveDark;

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
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return Colors.white.withValues(alpha: 0.5);
            }
            return Colors.white;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return accentColor.withValues(alpha: 0.5);
            }
            if (states.contains(WidgetState.pressed) ||
                states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.focused)) {
              return accentColor.withValues(alpha: 0.9);
            }
            return accentColor;
          }),
          overlayColor: WidgetStateProperty.all<Color>(Colors.transparent),
          animationDuration: const Duration(milliseconds: 150),
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
          disabledForegroundColor: LKColors.textSecondary.withValues(alpha: 0.5),
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
        hintStyle: TextStyle(color: LKColors.textSecondary.withValues(alpha: 0.8)),
        filled: true,
        fillColor: LKColors.inputFillDark,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 14,
        ),
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: LKColors.inputDark),
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: LKColors.inputDark),
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
        error: destructiveColor,
      ),
    );
  }
}
