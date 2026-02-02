import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/event_stream_providers.dart';

class ScheduleDetailsScreen extends ConsumerWidget {
  const ScheduleDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEventAsync = ref.watch(currentEventStreamProvider);
    final schedulesAsync = ref.watch(schedulesStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'EVENT SCHEDULE',
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
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: currentEventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.red))),
        data: (event) {
          if (event == null) return const Center(child: Text('No active event found', style: TextStyle(color: Colors.white54)));

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoCard(
                  icon: Icons.event,
                  title: 'Event Name',
                  content: event.name,
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.calendar_today,
                  title: 'Date',
                  content: '${event.date.day}/${event.date.month}/${event.date.year}',
                ),
                const SizedBox(height: 16),
                _buildInfoCard(
                  icon: Icons.location_on,
                  title: 'Location',
                  content: event.location,
                ),
                const SizedBox(height: 32),
                Text(
                  'EVENT AGENDA',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                    letterSpacing: 2,
                    color: AppColors.textDim,
                  ),
                ),
                const SizedBox(height: 16),
                schedulesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Text('Error loading schedule: $err', style: const TextStyle(color: Colors.red)),
                  data: (schedules) {
                    if (schedules.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.only(top: 16),
                        child: Text('No schedule slots defined yet.', style: TextStyle(color: Colors.white38)),
                      );
                    }
                    
                    // Sort by day and then by startTime
                    final sortedSchedules = List.from(schedules)..sort((a, b) {
                      final dayComp = a.day.compareTo(b.day);
                      if (dayComp != 0) return dayComp;
                      return a.startTime.compareTo(b.startTime);
                    });

                    return Column(
                      children: sortedSchedules.map((slot) => _buildAgendaItem(
                        '${slot.startTime.hour}:${slot.startTime.minute.toString().padLeft(2, '0')}',
                        '${slot.title} - Day ${slot.day}',
                      )).toList(),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textDim,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String meal, String time, String location) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  meal,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  location,
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textDim,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaItem(String time, String title) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            time,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
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
}
