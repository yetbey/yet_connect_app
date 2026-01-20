// core/constants/app_colors.dart - Genişletilmiş versiyon

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Dark Colors
  static const Color background = Color(0xFF121212);
  static const Color surface = Color(0xFF1E1E1E);
  static const Color primary = Color(0xFFBB86FC);
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFCF6679);
  static const Color onBackground = Colors.white;
  static const Color onSurface = Colors.white;

  // Grey Dark Colors
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;
  static const Color divider = Colors.white24;

  // Light Colors
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimary = Color(0xFF6200EE);
  static const Color lightSecondary = Color(0xFF018786);
  static const Color lightError = Color(0xFFB00020);

  static const Color lightTextPrimary = Color(0xFF1A1A1A);
  static const Color lightTextSecondary = Color(0xFF757575);
  static const Color lightDivider = Color(0xFFE0E0E0);

  // Common Colors
  static const Color transparent = Colors.transparent;
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);

  // 🎨 Primary Colors
  static const Color primaryLight = Color(0xFF64D8CB);
  static const Color primaryDark = Color(0xFF00766C);

  // 🎨 Text Colors
  static const Color textColor = Color(0xFFF5F5F5);
  static const Color textHint = Color(0xFF9E9E9E);
  static const Color textDisabled = Color(0xFF757575);

  // 🎨 Background Colors
  static const Color baachgroundColor = Color(0xFF121212);
  static const Color surfaceColor = Color(0xFF1E1E1E);
  static const Color cardColor = Color(0xFF2C2C2C);

  // 🎨 Accent Colors
  static const Color info = Color(0xFF42A5F5);

  // 🎨 Utility Colors
  static const Color flat = Color(0xFFFFFFFF);
  static const Color shadow = Color(0x1F000000);

  // 🎨 Form Colors
  static const Color textFormFieldShadowColor = Color(0xFF1a1a1a);
  static const Color textFormFieldBorderColor = Color(0xFF333333);

  // 🎨 Gradient Presets
  static const List<Color> gradientWarm = [
    Color(0xFFFF6B6B),
    Color(0xFFFFE66D),
  ];

  static const List<Color> gradientCool = [
    Color(0xFF4FACFE),
    Color(0xFF00F2FE),
  ];

  static const List<Color> gradientPurple = [
    Color(0xFFB06AB3),
    Color(0xFF4568DC),
  ];

  static const List<Color> gradientSunset = [
    Color(0xFFFF512F),
    Color(0xFFDD2476),
  ];

  static const List<Color> gradientOcean = [
    Color(0xFF2E3192),
    Color(0xFF1BFFFF),
  ];

  // 🎨 Dynamic Gradient Generator
  static LinearGradient getGradient(int index) {
    final gradients = [
      gradientWarm,
      gradientCool,
      gradientPurple,
      gradientSunset,
      gradientOcean,
    ];

    final selectedGradient = gradients[index % gradients.length];

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: selectedGradient,
    );
  }

  // 🎨 Glassmorphism Colors
  static Color glassBackground(double opacity) =>
      Colors.white.withValues(alpha: opacity);

  static Color glassBorder(double opacity) => Colors.white.withValues(alpha:  opacity);
}
