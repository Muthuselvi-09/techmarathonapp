import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:tech_marathon_app/features/home/domain/event_models.dart';

class SpeakerDetailsScreen extends StatelessWidget {
  final Speaker speaker;

  const SpeakerDetailsScreen({
    super.key,
    required this.speaker,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'SPEAKER PROFILE',
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
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(
              height: 400,
              width: double.infinity,
              child: Stack(
                children: [
                   Positioned.fill(
                    child: speaker.imageUrl.isNotEmpty
                        ? Image.network(
                            speaker.imageUrl,
                            fit: BoxFit.cover,
                            alignment: Alignment.topCenter,
                            errorBuilder: (context, error, stackTrace) => Container(color: AppColors.background, child: const Icon(Icons.mic, color: Colors.white24, size: 80)),
                          )
                        : Container(color: AppColors.surface, child: const Icon(Icons.person, color: Colors.white24, size: 80)),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.background,
                            AppColors.background.withValues(alpha: 0.0),
                            AppColors.background.withValues(alpha: 0.2),
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -60),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      speaker.name,
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      speaker.role,
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      speaker.bio ?? '',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textDim,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'BIOGRAPHY',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'An industry expert sharing insights and knowledge with the community at the event.',
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                        height: 1.6,
                      ),
                    ),
                    const SizedBox(height: 32),
                    if (speaker.linkedinUrl.isNotEmpty)
                      ElevatedButton.icon(
                        onPressed: () {}, // Link launching handled elsewhere or add here
                        icon: const Icon(Icons.link, size: 18),
                        label: const Text('View LinkedIn Profile'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
