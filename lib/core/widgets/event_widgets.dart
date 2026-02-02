// import 'dart:io' as io;
// import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_colors.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../features/home/presentation/providers/branding_provider.dart';

class BrandHeader extends ConsumerWidget {
  final bool showZhaCommerce;
  
  const BrandHeader({
    super.key,
    this.showZhaCommerce = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brandingAsync = ref.watch(brandingProvider);

    return brandingAsync.when(
      data: (branding) {
        final String name = showZhaCommerce ? 'ZhaCommerce' : branding.companyName.toUpperCase();
        final String? logoUrl = showZhaCommerce ? null : branding.companyLogoUrl;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (logoUrl != null && logoUrl.isNotEmpty) ...[
               CachedNetworkImage(
                imageUrl: logoUrl,
                height: 28,
                fit: BoxFit.contain,
                placeholder: (_, _) => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
                errorWidget: (_, _, _) => const Icon(Icons.business, color: AppColors.codingRimPrimary, size: 28),
              ),
              const SizedBox(width: 8),
            ] else 
              Icon(
                showZhaCommerce ? Icons.business_center_rounded : Icons.code_rounded,
                color: AppColors.codingRimPrimary,
                size: 28,
              ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                name,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                  fontSize: 20,
                  letterSpacing: 2,
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
      error: (_, _) => Row(
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
        color: color ?? AppColors.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }
}
