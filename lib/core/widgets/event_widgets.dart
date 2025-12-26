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
    if (kIsWeb) {
      return Text(
        showZhaCommerce ? 'ZhaCommerce' : 'CODING RIM',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          fontSize: 20,
          letterSpacing: 2,
        ),
      );
    }

    // On Mobile/Desktop platforms where dart:io is supported
    return Image.file(
      io.File(showZhaCommerce 
        ? '/Users/zhacommerce/.gemini/antigravity/brain/596e026f-fb7b-4abb-bd6d-27a077ef7775/uploaded_image_0_1766472268564.png'
        : '/Users/zhacommerce/.gemini/antigravity/brain/596e026f-fb7b-4abb-bd6d-27a077ef7775/uploaded_image_1_1766472268564.jpg'
      ),
      height: 40,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => Text(
        showZhaCommerce ? 'ZhaCommerce' : 'CODING RIM',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
          fontSize: 20,
          letterSpacing: 2,
        ),
      ),
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
