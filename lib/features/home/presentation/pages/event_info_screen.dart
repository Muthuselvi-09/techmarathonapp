import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class EventInfoScreen extends StatelessWidget {
  const EventInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'EVENT DETAILS',
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('EVENT OVERVIEW'),
            const SizedBox(height: 16),
            _buildContentCard(
              'Tech Marathon 2025 is a premier technology conference bringing together innovators, developers, and industry leaders. Join us for a day of learning, networking, and exploring the latest trends in technology.',
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('VENUE DETAILS'),
            const SizedBox(height: 16),
            _buildInfoRow(Icons.business, 'Tech Convention Center'),
            _buildInfoRow(Icons.location_city, 'Downtown Tech District'),
            _buildInfoRow(Icons.stairs, 'Hall A, 3rd Floor'),
            _buildInfoRow(Icons.local_parking, 'Parking Available - Basement Levels 1-3'),
            const SizedBox(height: 32),
            _buildSectionHeader('ENTRY TIMING'),
            const SizedBox(height: 16),
            _buildContentCard(
              'Registration opens at 8:00 AM. Please arrive early to collect your badge and event materials. Entry closes at 9:30 AM sharp.',
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('FLOOR MAP INFO'),
            const SizedBox(height: 16),
            _buildFloorItem('3rd Floor - Hall A', 'Main Event Hall, Registration Desk'),
            _buildFloorItem('3rd Floor - Hall B', 'Workshop Rooms 1-3'),
            _buildFloorItem('2nd Floor', 'Networking Lounge, Sponsor Booths'),
            _buildFloorItem('Ground Floor', 'Cafeteria, Information Desk'),
            const SizedBox(height: 32),
            _buildSectionHeader('RULES & INSTRUCTIONS'),
            const SizedBox(height: 16),
            _buildRuleItem('Carry a valid ID for registration'),
            _buildRuleItem('Maintain professional conduct at all times'),
            _buildRuleItem('Photography allowed, but respect speaker requests'),
            _buildRuleItem('Keep mobile phones on silent during sessions'),
            _buildRuleItem('Follow COVID-19 safety guidelines'),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withOpacity(0.2), AppColors.surface],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.primary, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      'For any queries, contact the help desk or visit our information counter.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 2,
        color: AppColors.textDim,
      ),
    );
  }

  Widget _buildContentCard(String content) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Text(
        content,
        style: GoogleFonts.inter(
          fontSize: 14,
          color: AppColors.textSecondary,
          height: 1.6,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorItem(String floor, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            floor,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rule,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
