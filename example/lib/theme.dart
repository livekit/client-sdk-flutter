import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//
// Flutter has a color profile issue so colors will look different
// on Apple devices.
// https://github.com/flutter/flutter/issues/55092
// https://github.com/flutter/flutter/issues/39113

extension LKColors on Colors {
  // ===== LiveKit brand =====
  static const lkAccent = Color(0xFF002CF2); // light-mode accent
  static const lkAccentDark = Color(0xFF1FD5F9); // dark-mode accent

  // Legacy aliases. Existing widgets reference these; values were refreshed to
  // match the new dark-mode palette so the rest of the UI keeps building.
  static const lkBlue = lkAccentDark; // was Color(0xFF5A8BFF)
  static const lkDarkBlue = neutral900; // was Color(0xFF00153C)

  // ===== Semantic theme tokens — dark mode =====
  static const bgDark = neutral950; // --background
  static const fgDark = neutral50; // --foreground
  static const cardDark = neutral900; // --card
  static const cardFgDark = neutral50; // --card-foreground
  static const popoverDark = neutral800; // --popover
  static const popoverFgDark = neutral50; // --popover-foreground
  static const primaryDark = neutral200; // --primary
  static const primaryFgDark = neutral900; // --primary-foreground
  static const secondaryDark = neutral800; // --secondary
  static const secondaryFgDark = neutral50; // --secondary-foreground
  static const mutedDark = neutral800; // --muted
  static const mutedFgDark = Color(0xFFA3A3A3); // --muted-foreground (~neutral-400)
  static const accentMutedDark = Color(0xFF5C5C5C); // --accent (oklch(0.371))
  static const accentFgDark = neutral50; // --accent-foreground
  static const destructiveDark = Color(0xFFF87171); // --destructive (~red-400)
  static const borderDark = Color(0x1AFFFFFF); // --border (white/10)
  static const inputDark = Color(0x26FFFFFF); // --input (white/15)
  static const inputFillDark = Color(0x0DFFFFFF); // dark:bg-input/30 (~white/5)
  static const ringDark = Color(0xFF8E8E8E); // --ring (oklch(0.556))
  static const sidebarDark = neutral900;
  static const sidebarFgDark = neutral50;
  static const sidebarBorderDark = Color(0x1AFFFFFF);
  static const sidebarRingDark = Color(0xFF6F6F6F); // oklch(0.439)

  // ===== Semantic theme tokens — light mode =====
  static const bgLight = Color(0xFFFFFFFF);
  static const fgLight = neutral950;
  static const cardLight = Color(0xFFFFFFFF);
  static const cardFgLight = neutral950;
  static const popoverLight = Color(0xFFFFFFFF);
  static const popoverFgLight = neutral950;
  static const primaryLight = neutral900;
  static const primaryFgLight = neutral50;
  static const secondaryLight = neutral100;
  static const secondaryFgLight = neutral900;
  static const mutedLight = neutral100;
  static const mutedFgLight = Color(0xFF737373); // oklch(0.556) ~ neutral-500
  static const accentMutedLight = neutral100;
  static const accentFgLight = neutral900;
  static const destructiveLight = Color(0xFFDC2626); // ~red-600
  static const borderLight = neutral200;
  static const inputLight = neutral200;
  static const ringLight = Color(0xFFB4B4B4); // oklch(0.708)

  // ===== Chart tokens =====
  // Light-mode charts (warm/cool mix; shadcn defaults).
  static const chart1Light = orange500;
  static const chart2Light = teal600;
  static const chart3Light = blue800;
  static const chart4Light = amber300;
  static const chart5Light = amber400;

  // Dark-mode charts (vibrant against the dark surface).
  static const chart1Dark = indigo500;
  static const chart2Dark = emerald400;
  static const chart3Dark = amber400;
  static const chart4Dark = violet500;
  static const chart5Dark = rose500;

  // ===== Tailwind color scales =====
  // Neutral (the backbone of the dark/light surfaces).
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

  // Red (destructive family).
  static const red50 = Color(0xFFFEF2F2);
  static const red100 = Color(0xFFFEE2E2);
  static const red200 = Color(0xFFFECACA);
  static const red300 = Color(0xFFFCA5A5);
  static const red400 = Color(0xFFF87171);
  static const red500 = Color(0xFFEF4444);
  static const red600 = Color(0xFFDC2626);
  static const red700 = Color(0xFFB91C1C);
  static const red800 = Color(0xFF991B1B);
  static const red900 = Color(0xFF7F1D1D);
  static const red950 = Color(0xFF450A0A);

  // Orange (chart-1 light family).
  static const orange50 = Color(0xFFFFF7ED);
  static const orange100 = Color(0xFFFFEDD5);
  static const orange200 = Color(0xFFFED7AA);
  static const orange300 = Color(0xFFFDBA74);
  static const orange400 = Color(0xFFFB923C);
  static const orange500 = Color(0xFFF97316);
  static const orange600 = Color(0xFFEA580C);
  static const orange700 = Color(0xFFC2410C);
  static const orange800 = Color(0xFF9A3412);
  static const orange900 = Color(0xFF7C2D12);
  static const orange950 = Color(0xFF431407);

  // Amber (chart-4/-5 light, chart-3 dark).
  static const amber50 = Color(0xFFFFFBEB);
  static const amber100 = Color(0xFFFEF3C7);
  static const amber200 = Color(0xFFFDE68A);
  static const amber300 = Color(0xFFFCD34D);
  static const amber400 = Color(0xFFFBBF24);
  static const amber500 = Color(0xFFF59E0B);
  static const amber600 = Color(0xFFD97706);
  static const amber700 = Color(0xFFB45309);
  static const amber800 = Color(0xFF92400E);
  static const amber900 = Color(0xFF78350F);
  static const amber950 = Color(0xFF451A03);

  // Teal (chart-2 light family).
  static const teal50 = Color(0xFFF0FDFA);
  static const teal100 = Color(0xFFCCFBF1);
  static const teal200 = Color(0xFF99F6E4);
  static const teal300 = Color(0xFF5EEAD4);
  static const teal400 = Color(0xFF2DD4BF);
  static const teal500 = Color(0xFF14B8A6);
  static const teal600 = Color(0xFF0D9488);
  static const teal700 = Color(0xFF0F766E);
  static const teal800 = Color(0xFF115E59);
  static const teal900 = Color(0xFF134E4A);
  static const teal950 = Color(0xFF042F2E);

  // Blue (brand-blue family; chart-3 light leans into the deep end).
  static const blue50 = Color(0xFFEFF6FF);
  static const blue100 = Color(0xFFDBEAFE);
  static const blue200 = Color(0xFFBFDBFE);
  static const blue300 = Color(0xFF93C5FD);
  static const blue400 = Color(0xFF60A5FA);
  static const blue500 = Color(0xFF3B82F6);
  static const blue600 = Color(0xFF2563EB);
  static const blue700 = Color(0xFF1D4ED8);
  static const blue800 = Color(0xFF1E40AF);
  static const blue900 = Color(0xFF1E3A8A);
  static const blue950 = Color(0xFF172554);

  // Cyan (dark-mode accent family; #1FD5F9 sits between cyan-300 and cyan-400).
  static const cyan50 = Color(0xFFECFEFF);
  static const cyan100 = Color(0xFFCFFAFE);
  static const cyan200 = Color(0xFFA5F3FC);
  static const cyan300 = Color(0xFF67E8F9);
  static const cyan400 = Color(0xFF22D3EE);
  static const cyan500 = Color(0xFF06B6D4);
  static const cyan600 = Color(0xFF0891B2);
  static const cyan700 = Color(0xFF0E7490);
  static const cyan800 = Color(0xFF155E75);
  static const cyan900 = Color(0xFF164E63);
  static const cyan950 = Color(0xFF083344);

  // Indigo (chart-1 dark family).
  static const indigo50 = Color(0xFFEEF2FF);
  static const indigo100 = Color(0xFFE0E7FF);
  static const indigo200 = Color(0xFFC7D2FE);
  static const indigo300 = Color(0xFFA5B4FC);
  static const indigo400 = Color(0xFF818CF8);
  static const indigo500 = Color(0xFF6366F1);
  static const indigo600 = Color(0xFF4F46E5);
  static const indigo700 = Color(0xFF4338CA);
  static const indigo800 = Color(0xFF3730A3);
  static const indigo900 = Color(0xFF312E81);
  static const indigo950 = Color(0xFF1E1B4B);

  // Emerald (chart-2 dark family).
  static const emerald50 = Color(0xFFECFDF5);
  static const emerald100 = Color(0xFFD1FAE5);
  static const emerald200 = Color(0xFFA7F3D0);
  static const emerald300 = Color(0xFF6EE7B7);
  static const emerald400 = Color(0xFF34D399);
  static const emerald500 = Color(0xFF10B981);
  static const emerald600 = Color(0xFF059669);
  static const emerald700 = Color(0xFF047857);
  static const emerald800 = Color(0xFF065F46);
  static const emerald900 = Color(0xFF064E3B);
  static const emerald950 = Color(0xFF022C22);

  // Violet (chart-4 dark family).
  static const violet50 = Color(0xFFF5F3FF);
  static const violet100 = Color(0xFFEDE9FE);
  static const violet200 = Color(0xFFDDD6FE);
  static const violet300 = Color(0xFFC4B5FD);
  static const violet400 = Color(0xFFA78BFA);
  static const violet500 = Color(0xFF8B5CF6);
  static const violet600 = Color(0xFF7C3AED);
  static const violet700 = Color(0xFF6D28D9);
  static const violet800 = Color(0xFF5B21B6);
  static const violet900 = Color(0xFF4C1D95);
  static const violet950 = Color(0xFF2E1065);

  // Rose (chart-5 dark family).
  static const rose50 = Color(0xFFFFF1F2);
  static const rose100 = Color(0xFFFFE4E6);
  static const rose200 = Color(0xFFFECDD3);
  static const rose300 = Color(0xFFFDA4AF);
  static const rose400 = Color(0xFFFB7185);
  static const rose500 = Color(0xFFF43F5E);
  static const rose600 = Color(0xFFE11D48);
  static const rose700 = Color(0xFFBE123C);
  static const rose800 = Color(0xFF9F1239);
  static const rose900 = Color(0xFF881337);
  static const rose950 = Color(0xFF4C0519);
}

class LiveKitTheme {
  //
  final bgColor = LKColors.bgDark;
  final textColor = LKColors.fgDark;
  final cardColor = LKColors.cardDark;
  final accentColor = LKColors.lkAccentDark;
  final mutedColor = LKColors.mutedFgDark;
  final borderColor = LKColors.borderDark;
  final destructiveColor = LKColors.destructiveDark;

  ThemeData buildThemeData(BuildContext ctx) => ThemeData(
        appBarTheme: AppBarTheme(
          backgroundColor: cardColor,
        ),
        cardColor: cardColor,
        scaffoldBackgroundColor: bgColor,
        canvasColor: bgColor,
        iconTheme: IconThemeData(
          color: textColor,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            textStyle: WidgetStateProperty.all<TextStyle>(GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            )),
            padding: WidgetStateProperty.all<EdgeInsets>(const EdgeInsets.symmetric(vertical: 20, horizontal: 25)),
            shape:
                WidgetStateProperty.all<OutlinedBorder>(RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.disabled)) {
                return LKColors.primaryFgDark.withValues(alpha: 0.5);
              }
              return LKColors.primaryFgDark;
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
          checkColor: WidgetStateProperty.all(LKColors.primaryFgDark),
          fillColor: WidgetStateProperty.all(accentColor),
        ),
        switchTheme: SwitchThemeData(
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return accentColor;
            }
            return accentColor.withValues(alpha: 0.3);
          }),
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return LKColors.fgDark;
            }
            return LKColors.fgDark.withValues(alpha: 0.3);
          }),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
        textTheme: GoogleFonts.montserratTextTheme(
          Theme.of(ctx).textTheme,
        ).apply(
          displayColor: textColor,
          bodyColor: textColor,
          decorationColor: textColor,
        ),
        hintColor: destructiveColor,
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(
            color: LKColors.lkAccentDark,
          ),
          hintStyle: TextStyle(
            color: LKColors.lkAccentDark.withValues(alpha: 5),
          ),
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
        colorScheme: ColorScheme.fromSeed(
          seedColor: accentColor,
          brightness: Brightness.dark,
          surface: bgColor,
          primary: accentColor,
          secondary: LKColors.secondaryDark,
          error: destructiveColor,
        ),
      );
}
