import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF01040D);
  static const Color surface = Color(0xFF0F172A);
  static const Color cardBg = Color(0xFF1E293B);
  
  // Brand Colors
  static const Color codingRimPrimary = Color(0xFFFFC107);
  static const Color codingRimSecondary = Color(0xFFFF5722);
  
  static const Color zhaCommercePrimary = Color(0xFF00CBA9);
  static const Color zhaCommerceSecondary = Color(0xFF00E676);
  
  // App Theme Accents
  static const Color primary = Color(0xFF00D2FF);
  static const Color secondary = Color(0xFF7000FF);
  static const Color accent = Color(0xFF00FF94);
  
  // Gradients
  static const LinearGradient mainGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient tealGradient = LinearGradient(
    colors: [zhaCommercePrimary, zhaCommerceSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient zhaCommerceGradient = tealGradient;
  static const LinearGradient codingRimGradient = LinearGradient(
    colors: [codingRimPrimary, codingRimSecondary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status Colors
  static const Color error = Color(0xFFFF4B4B);
  static const Color success = Color(0xFF00FF94);
  static const Color warning = Color(0xFFFFB800);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDim = Color(0xFF64748B);
}
