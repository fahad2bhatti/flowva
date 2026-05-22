import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Background Colors
  static const Color primaryBackground = Color(0xFF0A0F2C);
  static const Color secondaryBackground = Color(0xFF111936);
  static const Color elevatedSurface = Color(0xFF182347);
  static const Color glassOverlay = Color(0x0AFFFFFF); // rgba(255,255,255,0.04)

  // Brand / Accents
  static const Color accentTeal = Color(0xFF00D4AA);
  static const Color accentElectricBlue = Color(0xFF4A90FF);
  static const Color aiAccent = Color(0xFF8B5CF6); // AI intelligence purple

  // Backward compatibility aliases
  static const Color accent = accentTeal;
  static const Color cardBackground = elevatedSurface;
  static const Color secondaryAccent = accentElectricBlue;
  static const Color shadow = shadowColor;
  static const LinearGradient tealGradient = brandGradient;

  // Neutral / Typography
  static const Color text = Color(0xFFF0F0F0);
  static const Color textSecondary = Color(0xFF8E9AB6);
  static const Color textMuted = Color(0xFF5D6B8C);

  // Status Colors
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);

  static const Color shadowColor = Color(0x1F4A90FF); // Soft blue glow shadow color

  // Gradients
  static const LinearGradient brandGradient = LinearGradient(
    colors: [
      Color(0xFF00D4AA),
      Color(0xFF4A90FF),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [
      Color(0xFF8B5CF6),
      Color(0xFF6366F1),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFF0A0F2C),
      Color(0xFF111936),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
