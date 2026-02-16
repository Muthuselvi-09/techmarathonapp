import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:tech_marathon_app/data/models/schedule.dart' as new_schedule;
import 'package:tech_marathon_app/core/widgets/common_widgets.dart' as common_widgets;
import 'package:go_router/go_router.dart';

class ProfessionalCalendarScreen extends ConsumerStatefulWidget {
  const ProfessionalCalendarScreen({super.key});

  @override
  ConsumerState<ProfessionalCalendarScreen> createState() => _ProfessionalCalendarScreenState();
}

class _ProfessionalCalendarScreenState extends ConsumerState<ProfessionalCalendarScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedTab = 0; // 0: Agenda, 1: My Events

  @override
  Widget build(BuildContext context) {
    final schedulesAsync = ref.watch(schedulesStreamProvider);
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildDateSelector(),
          const SizedBox(height: 24),
          _buildViewTabs(),
          const SizedBox(height: 24),
          Expanded(
            child: schedulesAsync.when(
              data: (schedules) => _buildAgendaList(schedules),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'EVENT CALENDAR',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildDateSelector() {
    // Show a 14-day window around the selected date
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: 14,
        itemBuilder: (context, index) {
          final date = DateTime.now().add(Duration(days: index - 2));
          final isSelected = date.day == _selectedDate.day && date.month == _selectedDate.month;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedDate = date),
            child: AnimatedContainer(
              duration: 250.ms,
              width: 65,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? AppColors.primary : Colors.white.withValues(alpha: 0.05)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    DateFormat('E').format(date).toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.black54 : AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date.day.toString(),
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: isSelected ? Colors.black : Colors.white,
                    ),
                  ),
                  if (isSelected) 
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      width: 4, height: 4,
                      decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.black54),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildViewTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            _buildTab(0, 'FULL AGENDA'),
            _buildTab(1, 'MY RSVP'),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(int index, String label) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              letterSpacing: 1,
              color: isSelected ? AppColors.primary : AppColors.textDim,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAgendaList(List<new_schedule.Schedule> schedules) {
    // Filter by selected date
    final dailySessions = schedules.where((s) {
      return s.sessionDate.day == _selectedDate.day && 
             s.sessionDate.month == _selectedDate.month &&
             s.sessionDate.year == _selectedDate.year;
    }).toList();

    // Sort by start time
    dailySessions.sort((a, b) => a.startTime.compareTo(b.startTime));

    if (dailySessions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_month_rounded, color: Colors.white10, size: 80),
            const SizedBox(height: 16),
            Text('No sessions scheduled\nfor this day', 
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(color: Colors.white24, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: dailySessions.length,
      itemBuilder: (context, index) {
        final session = dailySessions[index];
        return _buildSessionCard(session);
      },
    );
  }

  Widget _buildSessionCard(new_schedule.Schedule session) {
    final timeStr = DateFormat('hh:mm a').format(session.startTime);
    final endTimeStr = DateFormat('hh:mm a').format(session.endTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Column
          Column(
            children: [
              Text(
                timeStr.split(' ')[0],
                style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white),
              ),
              Text(
                timeStr.split(' ')[1],
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDim, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(width: 1, height: 40, color: Colors.white12),
            ],
          ),
          const SizedBox(width: 20),
          // Content Card
          Expanded(
            child: common_widgets.GlassCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildHallTag(session.hall),
                      Text('$timeStr - $endTimeStr', style: const TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    session.title,
                    style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.person_pin_rounded, color: AppColors.primary, size: 14),
                      const SizedBox(width: 4),
                      Text(session.speakerIds.isNotEmpty ? 'Session Speaker' : 'TBA', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                      const Spacer(),
                      IconButton(
                        onPressed: () => context.push('/session-detail', extra: session),
                        icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHallTag(String hall) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        hall.toUpperCase(),
        style: GoogleFonts.inter(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w900),
      ),
    );
  }
}
