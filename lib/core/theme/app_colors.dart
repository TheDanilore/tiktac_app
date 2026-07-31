import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors (Shared)
  static const Color primary = Color(0xFF5E44FF);
  static const Color secondary = Color(0xFF2DD4BF);
  static const Color error = Color(0xFFEF4444);

  // Dark Mode Colors
  static const Color darkBackground = Color(0xFF0F111A);
  static const Color darkSurface = Color(0xFF181B26);
  static const Color darkSurfaceVariant = Color(0xFF222635);
  static const Color darkTextPrimary = Colors.white;
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkOutline = Color(0x1AFFFFFF); // 10% white

  // Light Mode Colors
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightOutline = Color(0x1A000000); // 10% black
}
