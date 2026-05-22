import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';

final ThemeData darkTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.dark,
  scaffoldBackgroundColor: AppColors.primaryBackground,
  primaryColor: AppColors.accentTeal,
  fontFamily: 'Inter',
  
  colorScheme: const ColorScheme.dark(
    primary: AppColors.accentTeal,
    secondary: AppColors.accentElectricBlue,
    surface: AppColors.elevatedSurface,
    error: AppColors.error,
  ),

  // Typography System
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.bold,
      letterSpacing: -1.0,
      color: AppColors.text,
    ),
    displayMedium: TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      letterSpacing: -0.5,
      color: AppColors.text,
    ),
    titleLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: AppColors.text,
    ),
    bodyLarge: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      color: AppColors.text,
    ),
    bodyMedium: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      color: AppColors.textSecondary,
    ),
    labelSmall: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.textMuted,
    ),
  ),

  // Card Theme Setup
  cardTheme: CardThemeData(
    color: AppColors.elevatedSurface,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusCard),
      side: BorderSide(
        color: AppColors.accentTeal.withValues(alpha: 0.05),
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
    fillColor: AppColors.secondaryBackground,
    hintStyle: const TextStyle(
      color: AppColors.textSecondary,
      fontSize: 14,
    ),
    prefixIconColor: AppColors.textSecondary,
    suffixIconColor: AppColors.textSecondary,
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
    backgroundColor: AppColors.elevatedSurface,
    elevation: 10,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppSizes.radiusModal),
    ),
  ),
);
