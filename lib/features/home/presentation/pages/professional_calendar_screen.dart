import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:tech_marathon_app/data/models/schedule.dart' as new_schedule;
import 'package:tech_marathon_app/core/widgets/common_widgets.dart' as common_widgets;
import 'package:go_router/go_router.dart';
import '../../domain/event_models.dart';
import '../../../auth/data/user_repository.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import 'add_personal_event_screen.dart';

class ProfessionalCalendarScreen extends ConsumerStatefulWidget {
  const ProfessionalCalendarScreen({super.key});

  @override
  ConsumerState<ProfessionalCalendarScreen> createState() => _ProfessionalCalendarScreenState();
}

class _ProfessionalCalendarScreenState extends ConsumerState<ProfessionalCalendarScreen> {
  DateTime _selectedDay = DateTime.now();
  DateTime _focusedDay = DateTime.now();
  int _selectedTab = 0; // 0: Agenda, 1: My RSVP
  CalendarFormat _calendarFormat = CalendarFormat.month;

  @override
  Widget build(BuildContext context) {
    // schedulesStreamProvider already watches the current event internally in event_stream_providers.dart
    final sessionsAsync = ref.watch(schedulesStreamProvider);
    final userProfile = ref.watch(profileProvider).user;
    final personalEventsAsync = userProfile != null 
        ? ref.watch(personalEventsStreamProvider(userProfile.id))
        : const AsyncValue<List<PersonalEvent>>.data([]);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: Container(
        decoration: BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildCalendar(sessionsAsync.value ?? [], personalEventsAsync.value ?? []),
              const SizedBox(height: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildTabs(),
                    Expanded(
                      child: _selectedTab == 0
                          ? _buildFullAgenda(sessionsAsync, personalEventsAsync)
                          : _buildMyRSVP(sessionsAsync),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Text(
        'EVENT CALENDAR',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16, color: AppColors.textPrimary),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
        onPressed: () {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/home'); // Fallback to home if nothing to pop
          }
        },
      ),
    );
  }

  Widget _buildCalendar(List<new_schedule.Schedule> sessions, List<PersonalEvent> personalEvents) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 56),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: TableCalendar(
        firstDay: DateTime.utc(2024, 1, 1),
        lastDay: DateTime.utc(2026, 12, 31),
        focusedDay: _focusedDay,
        selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
        calendarFormat: _calendarFormat,
        startingDayOfWeek: StartingDayOfWeek.monday,
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
          leftChevronIcon: const Icon(Icons.chevron_left, color: Colors.white70),
          rightChevronIcon: const Icon(Icons.chevron_right, color: Colors.white70),
        ),
        calendarStyle: CalendarStyle(
          defaultTextStyle: const TextStyle(color: AppColors.textPrimary),
          weekendTextStyle: const TextStyle(color: AppColors.textPrimary),
          selectedDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: AppColors.primary.withOpacity(0.3), shape: BoxShape.circle),
          markersMaxCount: 3,
          markerDecoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
        ),
        eventLoader: (day) {
          final daySessions = sessions.where((new_schedule.Schedule s) => isSameDay(s.sessionDate, day)).toList();
          final dayPersonal = personalEvents.where((PersonalEvent e) => isSameDay(e.startDate, day)).toList();
          return [...daySessions, ...dayPersonal];
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        onFormatChanged: (format) => setState(() => _calendarFormat = format),
        onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      ),
    );
  }

  Widget _buildTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Container(
        height: 50,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
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
            color: isSelected ? Colors.white.withOpacity(0.1) : Colors.transparent,
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

  Widget _buildFullAgenda(AsyncValue<List<new_schedule.Schedule>> sessionsAsync, AsyncValue<List<PersonalEvent>> personalAsync) {
    return sessionsAsync.when(
      data: (sessions) => personalAsync.when(
        data: (personal) {
          final dailySessions = sessions.where((new_schedule.Schedule s) => isSameDay(s.sessionDate, _selectedDay)).toList();
          final dailyPersonal = personal.where((PersonalEvent e) => isSameDay(e.startDate, _selectedDay)).toList();

          if (dailySessions.isEmpty && dailyPersonal.isEmpty) {
            return _buildEmptyState();
          }

          return ListView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 100), // Extra bottom padding for scroll
            children: [
              ...dailyPersonal.map((e) => _buildPersonalEventCard(e)),
              ...dailySessions.map((s) => _buildSessionCard(s)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildEmptyState() {
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

  Widget _buildSessionCard(new_schedule.Schedule session) {
    final timeStr = DateFormat('hh:mm a').format(session.startTime);
    final endTimeStr = DateFormat('hh:mm a').format(session.endTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(timeStr.split(' ')[0], style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: Colors.white)),
              Text(timeStr.split(' ')[1], style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDim, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(width: 1, height: 40, color: Colors.white12),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: common_widgets.GlassCard(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                        child: Text(session.hall.toUpperCase(), style: const TextStyle(color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      Text('$timeStr - $endTimeStr', style: const TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(session.title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalEventCard(PersonalEvent event) {
    final timeStr = DateFormat('hh:mm a').format(event.startDate);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(timeStr.split(' ')[0], style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary)),
              Text(timeStr.split(' ')[1], style: GoogleFonts.inter(fontSize: 10, color: AppColors.primary.withOpacity(0.7), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Container(width: 1, height: 40, color: AppColors.primary.withOpacity(0.2)),
            ],
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(6)),
                        child: const Text('PERSONAL', style: TextStyle(color: Colors.black, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      if (event.isAllDay) const Text('All Day', style: TextStyle(color: AppColors.textSecondary, fontSize: 10)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(event.title, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                  if (event.location.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 14),
                        const SizedBox(width: 4),
                        Text(event.location, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyRSVP(AsyncValue<List<new_schedule.Schedule>> sessionsAsync) {
    // Current placeholder, could filter by starred sessions
    return sessionsAsync.when(
      data: (sessions) => const Center(child: Text('Coming Soon', style: TextStyle(color: Colors.white24))),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}
