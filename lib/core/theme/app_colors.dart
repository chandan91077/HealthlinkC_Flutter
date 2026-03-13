import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF0D9488); // Teal
  static const Color primaryLight = Color(0xFF2DD4BF); // Cyan
  static const Color secondary = Color(0xFF0F172A); // Dark Slate

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF8FAFC);
  static const Color backgroundDark = Color(0xFF020617);

  // Surface
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF0F172A);

  // Gradient
  static const List<Color> heroGradient = [
    Color(0xFF020617),
    Color(0xFF0D9488),
  ];

  // Text
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF334155);
  static const Color textDisabled = Color(0xFF94A3B8);

  // Status
  static const Color error = Color(0xFFFF3B30);
  static const Color warning = Color(0xFFFF9500);
  static const Color success = Color(0xFF34C759);
  static const Color info = Color(0xFF0A7AFF);

  // Border
  static const Color border = Color(0xFFE5E7EB);
  static const Color borderDark = Color(0xFF374151);
}
