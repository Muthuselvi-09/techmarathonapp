import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/event_stream_providers.dart';

class EventInfoScreen extends ConsumerWidget {
  final String? eventId;
  const EventInfoScreen({super.key, this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEventAsync = eventId != null 
        ? ref.watch(allEventsStreamProvider).whenData((events) => events.any((e) => e.id == eventId) ? events.firstWhere((e) => e.id == eventId) : null)
        : ref.watch(currentEventStreamProvider);

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
      body: currentEventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (event) {
          if (event == null) return const Center(child: Text('No active event found', style: TextStyle(color: Colors.white54)));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('EVENT OVERVIEW'),
                const SizedBox(height: 16),
                _buildContentCard(event.description),
                const SizedBox(height: 32),
                _buildSectionHeader('VENUE DETAILS'),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.business, event.location),
                const SizedBox(height: 32),
                _buildSectionHeader('ENTRY TIMING'),
                const SizedBox(height: 16),
                _buildContentCard(
                  'Registration opens at 8:00 AM. Please arrive early to collect your badge and event materials. Entry closes at 9:30 AM sharp.',
                ),
                const SizedBox(height: 32),
                _buildSectionHeader('RULES & INSTRUCTIONS'),
                const SizedBox(height: 16),
                _buildRuleItem('Carry a valid ID for registration'),
                _buildRuleItem('Maintain professional conduct at all times'),
                _buildRuleItem('Photography allowed, but respect speaker requests'),
                _buildRuleItem('Keep mobile phones on silent during sessions'),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.surface],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
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
          );
        },
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
