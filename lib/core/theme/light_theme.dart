import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

final ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  scaffoldBackgroundColor: const Color(0xFFF8F9FD), // Sleek, breathable light gray-blue background
  primaryColor: AppColors.accentTeal,
  fontFamily: 'Inter',
  
  colorScheme: const ColorScheme.light(
    primary: AppColors.accentTeal,
    secondary: AppColors.accentElectricBlue,
    surface: Colors.white, // Elevated surfaces (cards, modals) are pure white
    error: AppColors.error,
  ),

  // Typography System (Parallel to dark mode, matching sizes & hierarchy)
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      letterSpacing: -1.0,
      color: AppColors.primaryBackground, // Use deep navy for high-contrast premium headers
    ),
    displayMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: AppColors.primaryBackground,
    ),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: AppColors.primaryBackground,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: Color(0xFF1E293B), // Premium dark slate for excellent readability
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: Color(0xFF64748B), // Slate secondary text
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: Color(0xFF94A3B8), // Slate muted text
    ),
  ),

  // Card Theme Setup (Beautiful shadow/glow and crisp border)
  cardTheme: CardThemeData(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      side: BorderSide(
        color: AppColors.accentElectricBlue.withValues(alpha: 0.08),
        width: 1,
      ),
    ),
  ),

  // Reusable Buttons Styling
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.accentTeal,
      foregroundColor: Colors.white,
      minimumSize: const Size(double.infinity, 56),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.radiusButton),
      ),
      elevation: 0,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
      ),
    ),
  ),

  // Custom Input Decoration Setup
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: const Color(0xFFEDF0F5), // Breathable filled background for text fields
    hintStyle: const TextStyle(
      color: Color(0xFF94A3B8),
      fontSize: 14,
    ),
    prefixIconColor: const Color(0xFF64748B),
    suffixIconColor: const Color(0xFF64748B),
    contentPadding: const EdgeInsets.symmetric(
      horizontal: 16,
      vertical: 18,
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusInput),
      borderSide: BorderSide.none,
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusInput),
      borderSide: const BorderSide(
        color: AppColors.accentTeal,
        width: 1.5,
      ),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusInput),
      borderSide: const BorderSide(
        color: AppColors.error,
        width: 1.5,
      ),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusInput),
      borderSide: const BorderSide(
        color: AppColors.error,
        width: 1.5,
      ),
    ),
  ),

  // Dialog & Modal Themes
  dialogTheme: DialogThemeData(
    backgroundColor: Colors.white,
    elevation: 10,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusModal),
    ),
  ),
);
