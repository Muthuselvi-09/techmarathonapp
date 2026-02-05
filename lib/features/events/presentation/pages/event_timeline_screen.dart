import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/core/widgets/common_widgets.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';
import 'package:tech_marathon_app/features/profile/data/profile_repository.dart';

class EventTimelineScreen extends ConsumerWidget {
  const EventTimelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(schedulesStreamProvider);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('FULL SCHEDULE'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: scheduleAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (sessions) {
          if (sessions.isEmpty) {
            return const Center(child: Text('No sessions planned yet', style: TextStyle(color: Colors.white38)));
          }

          // Sort sessions by startTime
          final sortedSessions = List.from(sessions)..sort((a, b) => a.startTime.compareTo(b.startTime));

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: sortedSessions.length,
            itemBuilder: (context, index) {
              final session = sortedSessions[index];
              final startTimeStr = DateFormat('hh:mm a').format(session.startTime);
              
              return IntrinsicHeight(
                child: Row(
                  children: [
                    _buildTimelineIndicator(index == 0, index == sortedSessions.length - 1),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: StreamBuilder<List<String>>(
                          stream: userId != null 
                              ? ref.watch(profileRepositoryProvider).getStarredSessionIds(userId)
                              : Stream.value([]),
                          builder: (context, snapshot) {
                            final starredIds = snapshot.data ?? [];
                            final isStarred = starredIds.contains(session.id);

                            return GlassCard(
                              padding: const EdgeInsets.all(16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          startTimeStr,
                                          style: GoogleFonts.inter(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          session.title,
                                          style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          session.description,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: GoogleFonts.inter(
                                            color: AppColors.textDim,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isStarred ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: isStarred ? AppColors.primary : Colors.white24,
                                    ),
                                    onPressed: () {
                                      if (userId != null) {
                                        ref.read(profileRepositoryProvider).toggleStarSession(userId, session.id);
                                      }
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildTimelineIndicator(bool isFirst, bool isLast) {
    return Column(
      children: [
        if (!isFirst) Container(width: 2, height: 20, color: Colors.white10),
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.primary,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.5),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: const Center(
            child: CircleAvatar(radius: 4, backgroundColor: Colors.black),
          ),
        ),
        if (!isLast) Expanded(child: Container(width: 2, color: Colors.white10)),
      ],
    );
  }
}
