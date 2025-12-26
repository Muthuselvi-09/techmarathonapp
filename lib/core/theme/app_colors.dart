import 'package:flutter/material.dart';

class AppColors {
  // Backgrounds
  static const Color background = Color(0xFF0F0804); // Deep Warm Black
  static const Color surface = Color(0xFF1A120B); // Dark Warm Brown
  static const Color cardBg = Color(0xFF2B1F16); // Semi-transparent card feel
  
  // Brand Colors
  static const Color codingRimPrimary = Color(0xFFFFD700); // Gold
  static const Color codingRimSecondary = Color(0xFFFF8C00); // Dark Orange
  
  static const Color zhaCommercePrimary = Color(0xFF10B981); // Premium Green
  static const Color zhaCommerceSecondary = Color(0xFF059669); // Darker Green
  
  // App Theme Accents
  static const Color primary = Color(0xFFD4AF37);   // Metallic Gold
  static const Color secondary = Color(0xFF8B5A2B); // Bronze/Copper
  static const Color accent = Color(0xFF22C55E);    // Vibrant Green CTA
  
  // Gradients
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFF2D1B12), Color(0xFF0F0804)], // Gradient from Soft Copper to Deep Black
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

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
  static const Color error = Color(0xFFEF4444);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);

  // Text Colors
  static const Color textPrimary = Color(0xFFFFFBEB); // Warm White
  static const Color textSecondary = Color(0xFFD6C0B0); // Muted Beige
  static const Color textDim = Color(0xFF8D7B6F); // Warm Grey
}
