import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme/app_colors.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _emailSupport() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@techmarathon.app',
      query: 'subject=Support Request - Tech Marathon App',
    );

    if (!await launchUrl(emailLaunchUri)) {
      debugPrint('Could not launch email client');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'HELP & SUPPORT',
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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.codingRimPrimary.withValues(alpha: 0.2), AppColors.surface],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.codingRimPrimary.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                const Icon(Icons.headset_mic_rounded, size: 48, color: AppColors.codingRimPrimary),
                const SizedBox(height: 16),
                Text(
                  'Need Help?',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Our support team is available to assist you with any issues.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: AppColors.textSecondary,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _emailSupport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  ),
                  child: Text(
                    'Contact Support',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Frequently Asked Questions',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildFaqItem('How do I reset my password?', 'Go to Privacy & Security settings and tap "Change Password". You will receive an email with instructions.'),
          _buildFaqItem('Can I change my email?', 'Currently, email addresses cannot be changed for security reasons. Please contact support.'),
          _buildFaqItem('Are payments secure?', 'Yes, all payments are processed securely through trusted payment gateways.'),
        ],
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ExpansionTile(
        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textDim,
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              answer,
              style: GoogleFonts.inter(
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
