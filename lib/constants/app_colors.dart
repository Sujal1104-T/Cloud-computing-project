import 'package:flutter/material.dart';

class AppColors {
  // Background
  static const Color background = Color(0xFF0F172A);
  static const Color surfaceDark = Color(0xFF1E293B);

  // Accents
  static const Color neonBlue = Color(0xFF00C6FF);
  static const Color deepPurple = Color(0xFF7F00FF);

  // Glass
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBorder = Color(0x33FFFFFF);

  // Text
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB0BEC5);
  static const Color textMuted = Color(0xFF607D8B);

  // Status
  static const Color success = Color(0xFF00E676);
  static const Color error = Color(0xFFFF1744);
  static const Color warning = Color(0xFFFFD600);

  // Rank Badges
  static const Color gold = Color(0xFFFFD700);
  static const Color silver = Color(0xFFC0C0C0);
  static const Color bronze = Color(0xFFCD7F32);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [neonBlue, deepPurple],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF0F172A), Color(0xFF1A0A2E), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0x2200C6FF), Color(0x227F00FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Category card gradients
  static const LinearGradient mcqGradient = LinearGradient(
    colors: [Color(0xFF00C6FF), Color(0xFF0072FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient codingGradient = LinearGradient(
    colors: [Color(0xFF7F00FF), Color(0xFFE100FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  static const LinearGradient aptitudeGradient = LinearGradient(
    colors: [Color(0xFF00B4DB), Color(0xFF0083B0)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
