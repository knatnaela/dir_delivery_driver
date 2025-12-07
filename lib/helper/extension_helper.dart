import 'package:flutter/material.dart';
import 'package:dir_delivery_driver/Theme/custom_theme_colors.dart';

extension ContextInfo on BuildContext {
  //theme context
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colorScheme => theme.colorScheme;
  CustomThemeColors get customThemeColors => theme.extension<CustomThemeColors>()!;

  //scaffold context
  ScaffoldMessengerState get scaffoldMessengerState => ScaffoldMessenger.of(this);
}
