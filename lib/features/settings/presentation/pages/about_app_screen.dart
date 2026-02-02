import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../core/theme/app_colors.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  Future<PackageInfo> _getPackageInfo() => PackageInfo.fromPlatform();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'ABOUT APP',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: FutureBuilder<PackageInfo>(
        future: _getPackageInfo(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.primary));
          }

          final info = snapshot.data!;
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.code_rounded, size: 48, color: AppColors.primary),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Tech Marathon App',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Version ${info.version} (Build ${info.buildNumber})',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 48),
                  Text(
                    '© 2025 Tech Marathon Inc.\nAll rights reserved.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.textDim,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
