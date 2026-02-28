import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/event_stream_providers.dart';
import '../../../profile/presentation/providers/starred_sessions_provider.dart';
import 'package:tech_marathon_app/data/models/schedule.dart' as new_schedule;
import 'package:flutter_animate/flutter_animate.dart';

class ScheduleDetailsScreen extends ConsumerStatefulWidget {
  final String? initialSearchQuery;
  final int? initialDay;

  const ScheduleDetailsScreen({
    super.key,
    this.initialSearchQuery,
    this.initialDay,
  });

  @override
  ConsumerState<ScheduleDetailsScreen> createState() => _ScheduleDetailsScreenState();
}

class _ScheduleDetailsScreenState extends ConsumerState<ScheduleDetailsScreen> {
  late String _searchQuery;
  String _selectedTrack = 'All';
  int? _selectedDay;
  bool _showMyAgenda = false;
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchQuery = widget.initialSearchQuery ?? '';
    _selectedDay = widget.initialDay;
    _searchController = TextEditingController(text: _searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
        leading: Navigator.canPop(context) 
          ? IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      ),
      body: currentEventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: Colors.red))),
        data: (event) {
          if (event == null) return const Center(child: Text('No active event found', style: TextStyle(color: Colors.white54)));

          return Column(
            children: [
              // Filters & Search Section
              Container(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
                ),
                child: Column(
                  children: [
                    // Search Bar
                    TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() => _searchQuery = val),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search sessions...',
                        hintStyle: TextStyle(color: AppColors.textDim),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Day Selector if multi-day
                    schedulesAsync.when(
                      data: (schedules) {
                        final days = schedules.map((s) => s.day).where((d) => d > 0).toSet().toList()..sort();
                        if (days.length <= 1) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: days.map((day) {
                                final isSelected = (_selectedDay ?? days.first) == day;
                                return Padding(
                                  padding: const EdgeInsets.only(right: 12),
                                  child: ChoiceChip(
                                    selected: isSelected,
                                    label: Text('DAY $day', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: isSelected ? Colors.black : Colors.white)),
                                    onSelected: (selected) {
                                      if (selected) setState(() => _selectedDay = day);
                                    },
                                    backgroundColor: AppColors.surface,
                                    selectedColor: AppColors.primary,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),
                    // Track Filters & My Agenda Toggle
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 40,
                            child: schedulesAsync.when(
                              data: (schedules) {
                                final activeDay = _selectedDay ?? (schedules.isNotEmpty ? (schedules.map((s) => s.day).where((d) => d > 0).toSet().toList()..sort()).first : 1);
                                final tracks = ['All', ...schedules.where((s) => s.day == activeDay).map((s) => s.hall).where((h) => h.isNotEmpty).toSet()];
                                return ListView.builder(
                                  scrollDirection: Axis.horizontal,
                                  itemCount: tracks.length,
                                  itemBuilder: (context, index) {
                                    final track = tracks[index];
                                    final isSelected = _selectedTrack == track;
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: FilterChip(
                                        selected: isSelected,
                                        label: Text(track, style: TextStyle(color: isSelected ? Colors.black : Colors.white, fontSize: 12)),
                                        onSelected: (_) => setState(() => _selectedTrack = track),
                                        backgroundColor: AppColors.surface,
                                        selectedColor: AppColors.primary,
                                        checkmarkColor: Colors.black,
                                        padding: EdgeInsets.zero,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                      ),
                                    );
                                  },
                                );
                              },
                              loading: () => const SizedBox.shrink(),
                              error: (_, __) => const SizedBox.shrink(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => setState(() => _showMyAgenda = !_showMyAgenda),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: _showMyAgenda ? AppColors.primary : AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star_rounded, color: _showMyAgenda ? Colors.black : AppColors.primary, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  'MY AGENDA',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _showMyAgenda ? Colors.black : Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Removed _buildInfoCard from here to leave more space for the timetable
                      // But kept event name as a header if needed
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _showMyAgenda ? 'MY BOOKMARKED SESSIONS' : 'DAY ${_selectedDay ?? (schedulesAsync.hasValue && schedulesAsync.value!.isNotEmpty ? (schedulesAsync.value!.map((s) => s.day).where((d) => d > 0).toSet().toList()..sort()).first : 1)} AGENDA',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w900,
                              fontSize: 12,
                              letterSpacing: 2,
                              color: AppColors.textDim,
                            ),
                          ),
                          if (schedulesAsync.hasValue)
                             Text(
                               '${schedulesAsync.value!.where((s) => s.status == 'published' && s.day == (_selectedDay ?? (schedulesAsync.value!.isNotEmpty ? (schedulesAsync.value!.map((s) => s.day).where((d) => d > 0).toSet().toList()..sort()).first : 1))).length} Sessions',
                               style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDim),
                             ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      schedulesAsync.when(
                        loading: () => const Center(child: CircularProgressIndicator()),
                        error: (err, _) => Text('Error loading schedule: $err', style: const TextStyle(color: Colors.red)),
                        data: (schedules) {
                          final starredIds = ref.watch(starredSessionsProvider);
                          
                          // FILTERING LOGIC
                          var filtered = schedules.where((s) => s.status == 'published').toList();

                          if (!_showMyAgenda) {
                            final firstDay = schedules.isNotEmpty ? (schedules.map((s) => s.day).where((d) => d > 0).toSet().toList()..sort()).first : 1;
                            filtered = filtered.where((s) => s.day == (_selectedDay ?? firstDay)).toList();
                          }
                          
                          if (_showMyAgenda) {
                             filtered = filtered.where((s) => starredIds.contains(s.id)).toList();
                             // For My Agenda, maybe show all days or just current day? 
                             // Usually "My Agenda" shows all bookmarked items regardless of day, sorted by time/day
                          }
                          
                          if (_selectedTrack != 'All') {
                            filtered = filtered.where((s) => s.hall == _selectedTrack).toList();
                          }
                          
                          if (_searchQuery.isNotEmpty) {
                            filtered = filtered.where((s) => 
                              s.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                              s.description.toLowerCase().contains(_searchQuery.toLowerCase())
                            ).toList();
                          }

                          if (filtered.isEmpty) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 40),
                                child: Column(
                                  children: [
                                    Icon(Icons.event_busy_rounded, size: 48, color: Colors.white12),
                                    const SizedBox(height: 16),
                                    Text(
                                      _showMyAgenda ? 'No sessions bookmarked yet' : 'No sessions matching your filters',
                                      style: TextStyle(color: Colors.white38, fontSize: 13),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          // Sort by day then startTime
                          final sortedSchedules = List.from(filtered)..sort((a, b) {
                             if (a.day != b.day) return a.day.compareTo(b.day);
                             return a.startTime.compareTo(b.startTime);
                          });

                          return Column(
                            children: sortedSchedules.map((slot) {
                              final now = DateTime.now();
                              final isLive = slot.startTime.isBefore(now) && slot.endTime.isAfter(now);
                              
                              return _buildAgendaItem(
                                context,
                                ref,
                                slot,
                                starredIds.contains(slot.id),
                                isLive,
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
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

  Widget _buildAgendaItem(
    BuildContext context,
    WidgetRef ref,
    new_schedule.Schedule session,
    bool isStarred,
    bool isLive,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isLive ? AppColors.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
        boxShadow: isLive ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 10)] : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            // Future: Navigate to Session Details
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Time & Live Indicator
                Column(
                  children: [
                    Text(
                      '${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isLive ? Colors.red : AppColors.primary,
                      ),
                    ),
                    if (isLive) ...[
                      const SizedBox(height: 8),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                      ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1,1), end: const Offset(1.5,1.5), duration: 800.ms).fadeOut(),
                    ],
                  ],
                ),
                const SizedBox(width: 20),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              session.sessionType.toUpperCase(),
                              style: GoogleFonts.inter(color: AppColors.primary, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (session.hall.isNotEmpty) ...[
                             const SizedBox(width: 8),
                             Text(
                               '•  ${session.hall}',
                               style: GoogleFonts.inter(color: AppColors.textDim, fontSize: 10),
                             ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        session.title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (session.speakerIds.isNotEmpty) ...[
                         const SizedBox(height: 8),
                         Row(
                           children: [
                             const Icon(Icons.people_alt_outlined, color: AppColors.textDim, size: 12),
                             const SizedBox(width: 4),
                             Text(
                               '${session.speakerIds.length} Speakers',
                               style: GoogleFonts.inter(color: AppColors.textDim, fontSize: 10),
                             ),
                           ],
                         ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Star Button
                IconButton(
                  icon: Icon(
                    isStarred ? Icons.star_rounded : Icons.star_border_rounded,
                    color: AppColors.primary,
                    size: 24,
                  ),
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                  onPressed: () {
                    ref.read(starredSessionsProvider.notifier).toggleStar(session.id);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
