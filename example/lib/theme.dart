//
//
//

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

//
// Flutter has a color profile issue so colors will look different
// on Apple devices.
// https://github.com/flutter/flutter/issues/55092
// https://github.com/flutter/flutter/issues/39113
//
class LiveKitTheme {
  //
  final bgColor = Colors.black;
  final textColor = Colors.white;
  final cardColor = const Color(0xFF00163c);
  final accentColor = const Color(0xFF2d6aef);

  ThemeData buildThemeData(BuildContext ctx) => ThemeData(
        backgroundColor: bgColor,
        // accentColor: accentColor,
        colorScheme: ColorScheme.fromSwatch(primarySwatch: Colors.blue),
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
            foregroundColor: MaterialStateProperty.all<Color>(Colors.white),
            // backgroundColor: MaterialStateProperty.all<Color>(accentColor),
            backgroundColor: MaterialStateProperty.resolveWith((states) {
              if (states.contains(MaterialState.disabled)) return accentColor.withOpacity(0.5);
              return accentColor;
            }),
          ),
        ),
        checkboxTheme: CheckboxThemeData(
          checkColor: MaterialStateProperty.all(Colors.white),
          fillColor: MaterialStateProperty.all(accentColor),
        ),
        dialogBackgroundColor: cardColor,
        textTheme: GoogleFonts.latoTextTheme(
          Theme.of(ctx).textTheme,
        ).apply(
          displayColor: textColor,
          bodyColor: textColor,
          decorationColor: textColor,
        ),
        hintColor: Colors.red,
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: TextStyle(
            color: textColor.withOpacity(.5),
          ),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: textColor.withOpacity(0.1)),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: accentColor),
          ),
        ),
      );
}
