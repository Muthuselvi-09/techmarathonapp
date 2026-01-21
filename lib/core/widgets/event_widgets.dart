import 'dart:io' as io;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

class BrandHeader extends StatelessWidget {
  final bool showZhaCommerce;
  
  const BrandHeader({
    super.key,
    this.showZhaCommerce = false,
  });

  @override
  Widget build(BuildContext context) {
    // Cross-platform safe image loading
    // On Web, absolute filesystem paths are not accessible and Image.file is not supported.
    // Simplified branding to avoid hardcoded absolute logic
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          showZhaCommerce ? Icons.business_center_rounded : Icons.code_rounded,
          color: AppColors.codingRimPrimary,
          size: 28,
        ),
        const SizedBox(width: 12),
        Text(
          showZhaCommerce ? 'ZhaCommerce' : 'CODING RIM',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            fontSize: 20,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? color;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color ?? AppColors.surface.withOpacity(0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
