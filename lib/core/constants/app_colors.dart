import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF5B5FEF);
  static const Color primaryDark = Color(0xFF3D3FCF);
  static const Color secondary = Color(0xFF00D9C0);

  static const Color lightBackground = Color(0xFFF7F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);

  static const Color darkBackground = Color(0xFF0F0F1A);
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkCard = Color(0xFF1E1E32);

  static const Color success = Color(0xFF00C48C);
  static const Color error = Color(0xFFFF5C5C);
  static const Color warning = Color(0xFFFFB020);
  static const Color income = Color(0xFF00C48C);
  static const Color expense = Color(0xFFFF5C5C);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glassGradient = LinearGradient(
    colors: [Color(0x33FFFFFF), Color(0x0DFFFFFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const List<Color> categoryColors = [
    Color(0xFFFF6B6B),
    Color(0xFF4ECDC4),
    Color(0xFFFFD93D),
    Color(0xFF6C5CE7),
    Color(0xFFFF9F43),
    Color(0xFF00C48C),
    Color(0xFFEE5A6F),
    Color(0xFF54A0FF),
    Color(0xFFA29BFE),
    Color(0xFF95A5A6),
  ];
}
