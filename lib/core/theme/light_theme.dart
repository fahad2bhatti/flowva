import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

// Light theme is similar but with light backgrounds
final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF6F8FA),

  colorScheme: const ColorScheme.light(
    primary: AppColors.accent,
    secondary: AppColors.accent,
    surface: Colors.white,
    background: Color(0xFFF6F8FA),
    error: AppColors.error,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
    onSurface: Color(0xFF1F2937),
    onBackground: Color(0xFF1F2937),
  ),

  appBarTheme: const AppBarTheme(
    backgroundColor: Color(0xFFF6F8FA),
    elevation: 0,
    centerTitle: false,
    titleTextStyle: TextStyle(
      color: Color(0xFF1F2937),
      fontSize: 20,
      fontWeight: FontWeight.w600,
      fontFamily: 'Inter',
    ),
    iconTheme: IconThemeData(
      color: Color(0xFF6B7280),
      size: 22,
    ),
  ),

  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
    ),
    margin: EdgeInsets.zero,
  ),

  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.accent, width: 1),
    ),
    hintStyle: const TextStyle(
      color: Color(0xFF9CA3AF),
      fontSize: 14,
      fontFamily: 'Inter',
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  ),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accent,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 44),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        fontFamily: 'Inter',
      ),
    ),
  ),

  textTheme: const TextTheme(
    bodyLarge: TextStyle(
      fontSize: 15,
      color: Color(0xFF1F2937),
      fontFamily: 'Inter',
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      color: Color(0xFF6B7280),
      fontFamily: 'Inter',
    ),
    bodySmall: TextStyle(
      fontSize: 12,
      color: Color(0xFF9CA3AF),
      fontFamily: 'Inter',
    ),
  ),

  dividerTheme: const DividerThemeData(
    color: Color(0xFFE5E7EB),
    thickness: 0.5,
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Colors.white,
    selectedItemColor: AppColors.accent,
    unselectedItemColor: Color(0xFF9CA3AF),
    type: BottomNavigationBarType.fixed,
    elevation: 0,
  ),
);