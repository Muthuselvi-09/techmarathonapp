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
  
  // Premium Theme Colors
  static const Color navyBlue = Color(0xFF0A0E21);
  static const Color electricPurple = Color(0xFF6B4EE6);
  static const Color neonAccent = Color(0xFF00F2FF);
  static const Color goldAccent = Color(0xFFFFD700);
  
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
  
  static const LinearGradient splashGradient = LinearGradient(
    colors: [Color(0xFF0F0804), Color(0xFF1A120B), Color(0xFF2D1B12)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient premiumGradient = LinearGradient(
    colors: [Color(0xFF1A120B), Color(0xFF0F0804)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient goldGradient = LinearGradient(
    colors: [goldAccent, Color(0xFFB8860B)],
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

  // SaaS Admin Theme
  static const Color saasMainBg = Color(0xFF0F172A);
  static const Color saasSidebarBg = Color(0xFF111827);
  static const Color saasCardBg = Color(0xFF1E293B);
  static const Color saasPrimary = Color(0xFF7C3AED);
  static const Color saasHover = Color(0xFF9333EA);
  static const Color saasTextPrimary = Color(0xFFFFFFFF);
  static const Color saasTextSecondary = Color(0xFF94A3B8);
  static const Color saasBorder = Color(0xFF334155);
  static const Color saasSuccess = Color(0xFF22C55E);
  static const Color saasDanger = Color(0xFFEF4444);
  static const Color saasInfo = Color(0xFF3B82F6);

  static const LinearGradient saasGradient = LinearGradient(
    colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static List<BoxShadow> saasShadow = [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.4),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];
}
