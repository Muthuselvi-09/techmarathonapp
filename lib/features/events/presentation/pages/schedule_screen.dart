import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../data/models/schedule.dart';
import '../../../home/presentation/providers/event_stream_providers.dart';
import 'session_detail_screen.dart';

import 'package:tech_marathon_app/features/profile/presentation/providers/starred_sessions_provider.dart';

// Local state providers
final selectedDayProvider = StateProvider<int>((ref) => 1);
final searchQueryProvider = StateProvider<String>((ref) => '');
final showMyScheduleProvider = StateProvider<bool>((ref) => false);
final selectedFilterProvider = StateProvider<String?>((ref) => null);

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch providers
    final schedulesAsync = ref.watch(schedulesStreamProvider);
    final selectedDay = ref.watch(selectedDayProvider);
    final searchQuery = ref.watch(searchQueryProvider);
    final showMySchedule = ref.watch(showMyScheduleProvider);
    final selectedFilter = ref.watch(selectedFilterProvider);
    final starredSessions = ref.watch(starredSessionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildHeader(context, ref, showMySchedule),
            
            // Filters Section
            Container(
              padding: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: Column(
                children: [
                  _buildDayTabs(ref, selectedDay),
                  const SizedBox(height: 12),
                  _buildFilterChips(ref, selectedFilter),
                ],
              ),
            ),

            // Timeline List
            Expanded(
              child: schedulesAsync.when(
                data: (schedules) {
                  // Filter logic
                  var filtered = schedules.where((s) {
                    // Day Filter (Assuming 'day' field is 'Day 1', 'Day 2' etc or just match index)
                    // If 'day' string is "Day 1", we match it. 
                    // Let's assume day selection needs to match the parsing logic.
                    // For now, simpler: check if s.day contains selectedDay number.
                    final matchesDay = s.day == selectedDay;
                    
                    // Search
                    final matchesSearch = s.title.toLowerCase().contains(searchQuery.toLowerCase());
                    
                    // Filter Chips (Track/Type/Hall) - Checking description/location/title
                    final matchesFilter = selectedFilter == null || 
                        s.title.contains(selectedFilter) || 
                        s.location.contains(selectedFilter) ||
                        s.description.contains(selectedFilter);

                    // My Schedule
                    final matchesMySchedule = !showMySchedule || starredSessions.contains(s.id);

                    return matchesDay && matchesSearch && matchesFilter && matchesMySchedule;
                  }).toList();

                  // Sort by time
                  filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.white.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'No sessions found',
                            style: TextStyle(color: Colors.white.withOpacity(0.5)),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final session = filtered[index];
                      return _buildTimelineItem(context, ref, session, starredSessions.contains(session.id));
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              ),
            ),
            const SizedBox(height: 80), // Space for bottom nav
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref, bool showMySchedule) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.1)),
                  ),
                  child: TextField(
                    onChanged: (val) => ref.read(searchQueryProvider.notifier).state = val,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search sessions...',
                      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                      prefixIcon: Icon(Icons.search, color: Colors.white.withOpacity(0.4), size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Material(
                color: showMySchedule ? AppColors.primary : Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  onTap: () => ref.read(showMyScheduleProvider.notifier).state = !showMySchedule,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        Icon(
                          showMySchedule ? Icons.star : Icons.star_border, 
                          color: showMySchedule ? Colors.black : Colors.white,
                          size: 20
                        ),
                        if (showMySchedule) ...[
                          const SizedBox(width: 8),
                          const Text(
                            'My Schedule',
                            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayTabs(WidgetRef ref, int selectedDay) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(3, (index) {
          final day = index + 1;
          final isSelected = selectedDay == day;
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => ref.read(selectedDayProvider.notifier).state = day,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
                  ),
                ),
                child: Text(
                  'Day $day',
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildFilterChips(WidgetRef ref, String? selectedFilter) {
    final filters = ['AI', 'Tech', 'Workshop', 'Talk', 'Main Stage'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          if (selectedFilter != null)
             Padding(
               padding: const EdgeInsets.only(right: 8),
               child: GestureDetector(
                 onTap: () => ref.read(selectedFilterProvider.notifier).state = null,
                 child: const CircleAvatar(
                   radius: 14,
                   backgroundColor: Colors.white24,
                   child: Icon(Icons.close, size: 14, color: Colors.white),
                 ),
               ),
             ),
          ...filters.map((filter) {
            final isSelected = selectedFilter == filter;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: isSelected,
                label: Text(filter),
                onSelected: (val) {
                  ref.read(selectedFilterProvider.notifier).state = val ? filter : null;
                },
                backgroundColor: Colors.white.withOpacity(0.05),
                selectedColor: AppColors.primary.withOpacity(0.2),
                checkmarkColor: AppColors.primary,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.primary : Colors.white70,
                  fontSize: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary.withOpacity(0.5) : Colors.transparent,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(BuildContext context, WidgetRef ref, Schedule session, bool isStarred) {
    final now = DateTime.now();
    final isLive = now.isAfter(session.startTime) && now.isBefore(session.endTime);
    final isCompleted = now.isAfter(session.endTime);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SessionDetailScreen(session: session)),
        );
      },
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time Column
            SizedBox(
              width: 60,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat('hh:mm').format(session.startTime),
                    style: GoogleFonts.outfit(
                      color: isLive ? AppColors.primary : Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    DateFormat('a').format(session.startTime),
                    style: GoogleFonts.outfit(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 2,
                        color: isLive ? AppColors.primary : Colors.white12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Card Content
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isLive ? AppColors.primary.withOpacity(0.05) : Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: isLive ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isLive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              margin: const EdgeInsets.only(right: 8, top: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'LIVE',
                                style: TextStyle(
                                  color: Colors.black, 
                                  fontWeight: FontWeight.bold, 
                                  fontSize: 10
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              session.title,
                              style: GoogleFonts.inter(
                                color: isCompleted ? Colors.white54 : Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              ref.read(starredSessionsProvider.notifier).toggleStar(session.id);
                            },
                            child: Icon(
                              isStarred ? Icons.star : Icons.star_border,
                              color: isStarred ? AppColors.primary : Colors.white38,
                              size: 20,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 12, color: AppColors.primary.withOpacity(0.7)),
                          const SizedBox(width: 4),
                          Text(
                            session.location.isEmpty ? 'Main Hall' : session.location,
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                          const Spacer(),
                           IconButton(
                            constraints: const BoxConstraints(),
                            padding: EdgeInsets.zero,
                            icon: const Icon(Icons.notifications_none, size: 18, color: Colors.white38),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Reminder set for 15 mins before!')),
                              );
                            },
                          ),
                        ],
                      ),
                      if (session.description.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const CircleAvatar(
                              radius: 10,
                              backgroundColor: Colors.white12,
                              child: Icon(Icons.person, size: 12, color: Colors.white),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                // Very rough extraction or fallback
                                'Speaker Name', 
                                style: TextStyle(color: Colors.white54, fontSize: 12),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ]
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
