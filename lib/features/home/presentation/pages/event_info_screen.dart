import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/event_stream_providers.dart';
import '../../../../features/home/domain/event_models.dart';
import '../../../../features/profile/data/profile_repository.dart';
import '../../../../features/admin/data/admin_repository.dart';

class EventInfoScreen extends ConsumerStatefulWidget {
  final String? eventId;
  const EventInfoScreen({super.key, this.eventId});

  @override
  ConsumerState<EventInfoScreen> createState() => _EventInfoScreenState();
}

class _EventInfoScreenState extends ConsumerState<EventInfoScreen> {
  bool _isRegistering = false;

  Future<void> _handleBooking(CodingEvent event) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to book tickets')),
      );
      return;
    }

    if (!event.isFree) {
      context.push('/payment', extra: event);
      return;
    }

    setState(() => _isRegistering = true);
    try {
      await ref.read(profileRepositoryProvider).registerEvent(user.uid, event.id);
      if (mounted) {
        _showSuccessDialog(event.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Registration failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  void _showSuccessDialog(String eventName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded, color: Colors.green, size: 64),
            const SizedBox(height: 16),
            Text(
              'REGISTRATION SUCCESSFUL!',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              'You are registered for $eventName.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  context.go('/my-events');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('VIEW MY TICKETS'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentEventAsync = widget.eventId != null
        ? ref.watch(allEventsStreamProvider).whenData((events) =>
            events.any((e) => e.id == widget.eventId) ? events.firstWhere((e) => e.id == widget.eventId) : null)
        : ref.watch(currentEventStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: currentEventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (event) {
          if (event == null) {
            return const Center(child: Text('No active event found', style: TextStyle(color: Colors.white54)));
          }

          final userId = FirebaseAuth.instance.currentUser?.uid;
          final isRegisteredAsync = userId != null
              ? ref.watch(isUserRegisteredProvider((userId, event.id)))
              : const AsyncValue.data(false);

          return Stack(
            children: [
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(event),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('EVENT OVERVIEW'),
                          const SizedBox(height: 16),
                          _buildContentCard(event.description),
                          const SizedBox(height: 32),
                          
                          _buildSectionHeader('SPEAKERS'),
                          const SizedBox(height: 16),
                          _buildSpeakersList(event.id),
                          const SizedBox(height: 32),

                          _buildSectionHeader('SPONSORS & PARTNERS'),
                          const SizedBox(height: 16),
                          _buildSponsorsList(event.id),
                          const SizedBox(height: 32),

                          _buildSectionHeader('VENUE & TIMING'),
                          const SizedBox(height: 16),
                          _buildInfoRow(Icons.calendar_today_rounded, '${event.date.day}/${event.date.month}/${event.date.year} at ${event.date.hour}:${event.date.minute.toString().padLeft(2, '0')}'),
                          const SizedBox(height: 12),
                          _buildInfoRow(Icons.business_rounded, event.location),
                          const SizedBox(height: 32),
                                                    if (event.entryTiming != null && event.entryTiming!.isNotEmpty) ...[
                             _buildSectionHeader('ENTRY TIMING'),
                             const SizedBox(height: 16),
                             _buildContentCard(event.entryTiming!),
                             const SizedBox(height: 32),
                           ],

                           if (event.rules.isNotEmpty) ...[
                             _buildSectionHeader('RULES & INSTRUCTIONS'),
                             const SizedBox(height: 16),
                             ...event.rules.map((rule) => _buildRuleItem(rule)).toList(),
                             const SizedBox(height: 32),
                           ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Bottom Booking Bar
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: _buildBottomBar(event, isRegisteredAsync.value ?? false),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSliverAppBar(CodingEvent event) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: AppColors.surface,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.black45,
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (event.imageUrl.isNotEmpty)
              Image.network(event.imageUrl, fit: BoxFit.cover)
            else
              Container(color: AppColors.surface, child: const Icon(Icons.event, size: 100, color: Colors.white10)),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    AppColors.background,
                    AppColors.background.withValues(alpha:0),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 24,
              left: 24,
              right: 24,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      event.category.toUpperCase(),
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event.name,
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
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

  Widget _buildSpeakersList(String eventId) {
    final speakersAsync = ref.watch(eventSpeakersProvider(eventId));
    
    return speakersAsync.when(
      data: (speakers) {
        if (speakers.isEmpty) return const Text('No speakers announced yet', style: TextStyle(color: Colors.white38, fontSize: 12));
        return SizedBox(
          height: 100,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: speakers.length,
            itemBuilder: (context, index) {
              final speaker = speakers[index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: speaker.imageUrl.isNotEmpty ? NetworkImage(speaker.imageUrl) : null,
                      backgroundColor: Colors.white10,
                      child: speaker.imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.white30) : null,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      speaker.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading speakers', style: TextStyle(color: Colors.red, fontSize: 12)),
    );
  }

  Widget _buildSponsorsList(String eventId) {
    final sponsorsAsync = ref.watch(eventSponsorsProvider(eventId));
    
    return sponsorsAsync.when(
      data: (sponsors) {
        if (sponsors.isEmpty) return const Text('Partners to be announced', style: TextStyle(color: Colors.white38, fontSize: 12));
        return SizedBox(
          height: 60,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sponsors.length,
            itemBuilder: (context, index) {
              final sponsor = sponsors[index];
              return Container(
                width: 100,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: sponsor.logoUrl.isNotEmpty 
                  ? Image.network(sponsor.logoUrl, fit: BoxFit.contain)
                  : Center(child: Text(sponsor.company, style: const TextStyle(color: Colors.black, fontSize: 8, fontWeight: FontWeight.bold))),
              );
            },
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Text('Error loading sponsors', style: TextStyle(color: Colors.red, fontSize: 12)),
    );
  }

  Widget _buildBottomBar(CodingEvent event, bool isRegistered) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha:0.05))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'ENTRY FEE',
                  style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDim, fontWeight: FontWeight.bold, letterSpacing: 1),
                ),
                Text(
                  event.isFree ? 'FREE' : '${event.currency}${event.entryFee}',
                  style: GoogleFonts.outfit(fontSize: 20, color: AppColors.primary, fontWeight: FontWeight.w900),
                ),
              ],
            ),
            const SizedBox(width: 32),
            Expanded(
              child: SizedBox(
                height: 54,
                child: ElevatedButton(
                  onPressed: (isRegistered || _isRegistering) ? null : () => _handleBooking(event),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    disabledBackgroundColor: Colors.white10,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: _isRegistering
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          isRegistered ? 'ALREADY BOOKED' : (event.isFree ? 'BOOK NOW' : 'SECURE SPOT'),
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1),
                        ),
                ),
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
      width: double.infinity,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String rule) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              rule,
              style: GoogleFonts.inter(
                fontSize: 13,
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

// Helper provider to check registration status
final isUserRegisteredProvider = StreamProvider.family<bool, (String, String)>((ref, args) {
  return ref.watch(profileRepositoryProvider).isUserRegistered(args.$1, args.$2);
});

final eventSpeakersProvider = StreamProvider.family<List<Speaker>, String>((ref, eventId) {
  return ref.watch(adminRepositoryProvider).watchEventSpeakers(eventId);
});

final eventSponsorsProvider = StreamProvider.family<List<Sponsor>, String>((ref, eventId) {
  return ref.watch(adminRepositoryProvider).watchEventSponsors(eventId);
});

