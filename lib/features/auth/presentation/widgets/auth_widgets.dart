import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:google_fonts/google_fonts.dart';

class AnimatedGradientBackground extends StatelessWidget {
  final Widget child;
  const AnimatedGradientBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.backgroundGradient,
      ),
      child: child,
    );
  }
}

class PremiumTextField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final TextEditingController? controller;
  final Widget? suffixIcon;

  const PremiumTextField({
    super.key,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.controller,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: Colors.white60),
          prefixIcon: Icon(icon, color: Colors.white70, size: 22),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
      ),
    );
  }
}

class PremiumGradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final List<Color>? colors;

  const PremiumGradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: AppColors.codingRimGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.codingRimPrimary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ),
      ),
    ).animate()
     .scale(begin: const Offset(1, 1), end: const Offset(1, 1), curve: Curves.easeInOut)
     .shimmer(duration: 3.seconds, color: Colors.white24);
  }
}
