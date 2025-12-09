import 'package:flutter/material.dart';

import 'custom_theme_colors.dart';

ThemeData darkTheme = ThemeData(
    fontFamily: 'SFProText',
    primaryColor: const Color(0xFFA61E49),
    brightness: Brightness.dark,
    cardColor: const Color(0xFF242424),
    hintColor: const Color(0xFF9F9F9F),
    scaffoldBackgroundColor: const Color(0xFF1C1F1F),
    primaryColorDark: const Color(0xff01463e),
    extensions: <ThemeExtension<CustomThemeColors>>[CustomThemeColors.dark()],
    colorScheme: const ColorScheme.dark(
        primary: Color(0xFFA61E49),
        error: Color(0xFFFF6767),
        secondary: Color(0xFFA61E49),
        tertiary: Color(0xFFA61E49),
        tertiaryContainer: Color(0xFFC98B3E),
        secondaryContainer: Color(0xFFEE6464),
        onTertiary: Color(0xFFD9D9D9),
        onSecondary: Color(0xFF00FEE1),
        onSecondaryContainer: Color(0xFFA8C5C1),
        onTertiaryContainer: Color(0xFF425956),
        outline: Color(0xFF8CFFF1),
        onPrimaryContainer: Color(0xFF929494),
        primaryContainer: Color(0xFFFFA800),
        onSurface: Color(0xFFFFE6AD),
        onPrimary: Color(0xFF064A42),
        surfaceContainer: Color(0xFF0094FF),
        secondaryFixedDim: Color(0xFF808080)),
    textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: const Color(0xFFA61E49))),
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontWeight: FontWeight.w300, color: Color(0xFF202020)),
      displayMedium: TextStyle(fontWeight: FontWeight.w300, color: Color(0xFF393939)),
      displaySmall: TextStyle(fontWeight: FontWeight.w300, color: Color(0xFF282828)),
      bodyLarge: TextStyle(fontWeight: FontWeight.w300, color: Color(0xFF272727)),
      bodyMedium: TextStyle(fontWeight: FontWeight.w300, color: Color(0xffffffff)),
      bodySmall: TextStyle(fontWeight: FontWeight.w300, color: Color(0xFF1D2D2B)),
    ));
