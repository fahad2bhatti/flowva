import 'package:flutter/material.dart';
import 'light_theme.dart' as lt;
import 'dark_theme.dart' as dt;

class AppTheme {
  AppTheme._();

  static ThemeData get lightTheme => lt.lightTheme;
  static ThemeData get darkTheme => dt.buildDarkTheme();
}

