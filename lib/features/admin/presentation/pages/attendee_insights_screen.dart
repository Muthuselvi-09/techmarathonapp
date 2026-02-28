import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:tech_marathon_app/core/widgets/common_widgets.dart' as common_widgets;
import 'package:cloud_firestore/cloud_firestore.dart';

final eventRegistrationsProvider = StreamProvider.family<int, String>((ref, eventId) {
  return ref.watch(adminRepositoryProvider).watchTotalRegistrations(eventId);
});

final eventCheckedInProvider = StreamProvider.family<int, String>((ref, eventId) {
  return ref.watch(adminRepositoryProvider).watchTotalCheckedIn(eventId);
});

final eventPassesProvider = StreamProvider.family<List<EntryPass>, String>((ref, eventId) {
  return ref.watch(adminRepositoryProvider).watchEntryPasses(eventId);
});

class AttendeeInsightsScreen extends ConsumerStatefulWidget {
  final String eventId;
  const AttendeeInsightsScreen({super.key, required this.eventId});

  @override
  ConsumerState<AttendeeInsightsScreen> createState() => _AttendeeInsightsScreenState();
}

class _AttendeeInsightsScreenState extends ConsumerState<AttendeeInsightsScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final registrationsAsync = ref.watch(eventRegistrationsProvider(widget.eventId));
    final checkedInAsync = ref.watch(eventCheckedInProvider(widget.eventId));
    final allPassesAsync = ref.watch(eventPassesProvider(widget.eventId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildGlobalStats(registrationsAsync, checkedInAsync),
            const SizedBox(height: 32),
            _buildAttendeeList(allPassesAsync),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'ATTENDEE INSIGHTS',
        style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2, fontSize: 16),
      ),
      centerTitle: true,
    );
  }

  Widget _buildGlobalStats(AsyncValue<int> reg, AsyncValue<int> checkIn) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Global Analytics'.toUpperCase(),
            style: GoogleFonts.outfit(color: AppColors.textDim, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildStatCard('Registrations', reg, Icons.people_outline_rounded, AppColors.primary)),
              const SizedBox(width: 16),
              Expanded(child: _buildStatCard('Checked-In', checkIn, Icons.how_to_reg_rounded, Colors.greenAccent)),
            ],
          ),
          const SizedBox(height: 16),
          _buildConversionCard(reg, checkIn),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, AsyncValue<int> val, IconData icon, Color color) {
    return common_widgets.GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 16),
          val.when(
            data: (v) => Text(v.toString(), style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white)),
            loading: () => const SizedBox(height: 32, width: 32, child: CircularProgressIndicator(strokeWidth: 2)),
            error: (_, __) => const Text('Error', style: TextStyle(color: Colors.red)),
          ),
          Text(label, style: GoogleFonts.inter(color: AppColors.textDim, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildConversionCard(AsyncValue<int> reg, AsyncValue<int> checkIn) {
    double rate = 0;
    if (reg.hasValue && checkIn.hasValue && reg.value! > 0) {
      rate = (checkIn.value! / reg.value!) * 100;
    }

    return common_widgets.GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Real-time Attendance Rate', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                const SizedBox(height: 4),
                Text('Percentage of registered users present', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
              ],
            ),
          ),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: CircularProgressIndicator(
                  value: rate / 100,
                  backgroundColor: Colors.white10,
                  color: AppColors.primary,
                  strokeWidth: 6,
                ),
              ),
              Text('${rate.toStringAsFixed(0)}%', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, color: Colors.white)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendeeList(AsyncValue<List<EntryPass>> passes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PARTICIPANT LIST'.toUpperCase(),
                style: GoogleFonts.outfit(color: AppColors.textDim, fontSize: 12, fontWeight: FontWeight.w900, letterSpacing: 1.5),
              ),
              Text(
                passes.asData?.value.length.toString() ?? '0',
                style: GoogleFonts.outfit(color: AppColors.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: TextField(
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search by name or ID...',
              hintStyle: const TextStyle(color: Colors.white24),
              prefixIcon: const Icon(Icons.search, color: Colors.white24),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
            onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
          ),
        ),
        const SizedBox(height: 24),
        passes.when(
          data: (list) {
            final filtered = list.where((p) => 
                p.userName.toLowerCase().contains(_searchQuery) || 
                p.userId.toLowerCase().contains(_searchQuery)).toList();
            
            if (filtered.isEmpty) {
              return const Center(child: Padding(
                padding: EdgeInsets.all(40),
                child: Text('No participants found', style: TextStyle(color: Colors.white38)),
              ));
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filtered.length,
              itemBuilder: (context, index) {
                final pass = filtered[index];
                return _buildAttendeeTile(pass);
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, __) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  Widget _buildAttendeeTile(EntryPass pass) {
    final isCheckedIn = pass.status == 'USED';
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isCheckedIn ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(shape: BoxShape.circle, color: isCheckedIn ? Colors.greenAccent.withValues(alpha: 0.1) : Colors.white12),
            child: Icon(isCheckedIn ? Icons.check_circle_rounded : Icons.person_outline_rounded, 
                color: isCheckedIn ? Colors.greenAccent : Colors.white38),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(pass.userName, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white)),
                Text('ID: ${pass.userId}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildMiniStatus(isCheckedIn ? 'Checked-In' : 'Registered', isCheckedIn ? Colors.greenAccent : Colors.white38),
              const SizedBox(height: 4),
              TextButton(
                onPressed: () => _showAttendeeDetails(pass),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text('Details >', style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStatus(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label.toUpperCase(), style: GoogleFonts.inter(color: color, fontSize: 8, fontWeight: FontWeight.w900)),
    );
  }

  void _showAttendeeDetails(EntryPass pass) async {
    final participation = await ref.read(adminRepositoryProvider).getAttendeeParticipation(widget.eventId, pass.userId);
    
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 32),
              Row(
                children: [
                   Container(
                     width: 60, height: 60,
                     decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.primary),
                     child: const Icon(Icons.person, color: Colors.black, size: 30),
                   ),
                   const SizedBox(width: 20),
                   Expanded(
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       children: [
                         Text(pass.userName, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                         Text('User ID: ${pass.userId}', style: const TextStyle(color: AppColors.textDim)),
                       ],
                     ),
                   ),
                ],
              ),
              const SizedBox(height: 40),
              Text('PARTICIPATION HISTORY', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 2, color: AppColors.textDim)),
              const SizedBox(height: 16),
              Expanded(
                child: participation.isEmpty 
                  ? const Center(child: Text('No attendance recorded yet', style: TextStyle(color: Colors.white24)))
                  : ListView.builder(
                      controller: scrollController,
                      itemCount: participation.length,
                      itemBuilder: (context, index) {
                        final p = participation[index];
                        return Card(
                          color: AppColors.surface,
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          child: ListTile(
                            leading: const Icon(Icons.event_available_rounded, color: Colors.greenAccent),
                            title: Text('Session Check-in', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            subtitle: Text('Recorded by Admin ID: ${p['adminId']}', style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                            trailing: Text('${(p['timestamp'] as Timestamp?)?.toDate().hour}:${(p['timestamp'] as Timestamp?)?.toDate().minute}', 
                              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
