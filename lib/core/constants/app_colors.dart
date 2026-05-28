import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background Colors
  static const Color background = Color(0xFF0A0A0F);     // Pure near-black
  static const Color surface = Color(0xFF0F1117);        // Card background
  static const Color card = Color(0xFF161B22);           // Card surface
  static const Color border = Color(0xFF21262D);         // Subtle borders

  // Single Accent Color (Graphite)
  static const Color accent = Color(0xFF4B5563);          // Only accent color

  // Text Colors
  static const Color textPrimary = Color(0xFFF0F6FC);     // White-ish
  static const Color textSecondary = Color(0xFF8B949E);   // Grey
  static const Color textMuted = Color(0xFF484F58);       // Muted grey

  // Status Colors (Minimal)
  static const Color error = Color(0xFFF85149);           // Red for errors only
  static const Color success = Color(0xFF3FB950);         // Green for success only (minimal)
  static const Color warning = Color(0xFFD29922);         // Yellow for warnings only

  // Backward Compatibility (for existing code)
  static const Color primary = accent;
  static const Color primaryBackground = background;
  static const Color primaryMuted = card;
  static const Color accentTeal = accent;
  static const Color accentElectricBlue = accent;
  static const Color secondaryAccent = accent;
}