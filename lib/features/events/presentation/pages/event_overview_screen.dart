import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/core/widgets/event_widgets.dart' as event_widgets;
import 'package:tech_marathon_app/core/widgets/common_widgets.dart' as common_widgets;
import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart' as new_speaker;
import 'package:tech_marathon_app/features/home/domain/event_models.dart' as new_sponsor;
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/features/profile/data/profile_repository.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:tech_marathon_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:tech_marathon_app/core/services/notification_service.dart';


class EventOverviewScreen extends ConsumerStatefulWidget {
  const EventOverviewScreen({super.key});

  @override
  ConsumerState<EventOverviewScreen> createState() => _EventOverviewScreenState();
}

class _EventOverviewScreenState extends ConsumerState<EventOverviewScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndShowFeedbackPopup();
    });
  }


  @override
  Widget build(BuildContext context) {
    final currentEventAsync = ref.watch(currentEventStreamProvider);
    final speakersAsync = ref.watch(mergedSpeakersProvider);
    final sponsorsAsync = ref.watch(mergedSponsorsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: currentEventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
        data: (event) {
          if (event == null) return const Center(child: Text('No active event', style: TextStyle(color: Colors.white38)));

          return CustomScrollView(
            slivers: [
              _buildSliverAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildEventTitle(event),
                      const SizedBox(height: 32),
                      _buildEntryPass(context),
                      const SizedBox(height: 48),
                      _buildParticipantsBanner(context),
                      const SizedBox(height: 48),
                      sponsorsAsync.when(
                        data: (sponsors) => _buildSponsorsSlider(sponsors),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 48),
                      speakersAsync.when(
                        data: (speakers) => _buildSpeakersList(speakers),
                        loading: () => const CircularProgressIndicator(),
                        error: (_, _) => const SizedBox.shrink(),
                      ),
                      const SizedBox(height: 120),
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

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 120.0,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: const event_widgets.BrandHeader(),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.primary.withValues(alpha: 0.1),
                AppColors.background,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEventTitle(CodingEvent event) {
    return Consumer(
      builder: (context, ref, _) {
        final userId = FirebaseAuth.instance.currentUser?.uid;
        final registrationStream = userId != null 
            ? ref.watch(profileRepositoryProvider).isUserRegistered(userId, event.id)
            : Stream.value(false);

        return StreamBuilder<bool>(
          stream: registrationStream,
          initialData: false,
          builder: (context, snapshot) {
            final isRegistered = snapshot.data ?? false;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.name.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimary,
                          height: 1.1,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: event.isFree ? Colors.green.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: event.isFree ? Colors.green : AppColors.primary, width: 1),
                      ),
                      child: Text(
                        event.isFree ? 'FREE' : '${event.currency}${event.entryFee}',
                        style: GoogleFonts.inter(
                          color: event.isFree ? Colors.green : AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      event.location,
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                    ),
                    const SizedBox(width: 24),
                    const Icon(Icons.calendar_today_rounded, color: AppColors.primary, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(event.date),
                      style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
                if (event.totalSeats > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.event_seat_rounded, color: AppColors.primary, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${event.availableSeats} / ${event.totalSeats} Seats Available',
                        style: GoogleFonts.inter(
                          color: event.availableSeats <= 5 ? Colors.redAccent : AppColors.textSecondary, 
                          fontSize: 14,
                          fontWeight: event.availableSeats <= 5 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: Builder(
                    builder: (context) {
                      final isSoldOut = event.totalSeats > 0 && event.availableSeats <= 0;
                      return ElevatedButton(
                        onPressed: (isRegistered || isSoldOut) ? null : () async {
                          if (userId != null) {
                            if (!event.isFree) {
                              context.push('/payment', extra: event);
                              return;
                            }

                            await ref.read(profileRepositoryProvider).registerEvent(userId, event.id);
                            final userName = FirebaseAuth.instance.currentUser?.displayName ?? 'Attendee';
                            await ref.read(adminRepositoryProvider).createEntryPass(event.id, userId, userName);
                            // 6. Push Notifications - Schedule reminders for joined event
                            final schedules = await ref.read(adminRepositoryProvider).getSchedulesForEvent(event.id);
                            await notificationService.scheduleAllSessionReminders(
                              sessions: schedules.map((s) => {
                                'id': s.id,
                                'title': s.title,
                                'startTime': s.startTime,
                              }).toList(),
                              eventName: event.name,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(event.isFree ? 'Successfully joined event!' : 'Ticket purchased successfully!'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: (isRegistered || isSoldOut) ? Colors.white10 : AppColors.primary,
                          foregroundColor: (isRegistered || isSoldOut) ? Colors.white38 : Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: (isRegistered || isSoldOut) ? 0 : 8,
                        ),
                        child: Text(
                          isRegistered 
                              ? 'ALREADY REGISTERED' 
                              : (isSoldOut ? 'SOLD OUT' : (event.isFree ? 'JOIN EVENT NOW' : 'BUY TICKET NOW')),
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 1),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  Widget _buildEntryPass(BuildContext context) {
    // Attempt to get real user data if possible, otherwise fallback
    final user = FirebaseAuth.instance.currentUser;
    final userName = user?.displayName ?? 'Valued Member';
    final userId = user?.uid.substring(0, 8).toUpperCase() ?? 'CR-EVT-USER';

    return common_widgets.GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: AppColors.mainGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DIGITAL ENTRY PASS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withValues(alpha: 0.6),
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'PREMIUM MEMBER',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.nfc_rounded, color: Colors.black),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildPassInfo('HOLDER', userName),
                      const SizedBox(height: 16),
                      _buildPassInfo('ID', 'CR-EVT-$userId'),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: 'CR-EVT-$userId-$userName',
                    version: QrVersions.auto,
                    size: 80.0,
                    backgroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPassInfo(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 10, color: AppColors.textDim, letterSpacing: 1),
        ),
        Text(
          value,
          style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildParticipantsBanner(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final countAsync = ref.watch(totalParticipantsProvider);
        return GestureDetector(
          onTap: () => context.push('/participants'),
          child: common_widgets.GlassCard(
            color: AppColors.primary.withValues(alpha: 0.05),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.people_alt_rounded, color: Colors.black),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countAsync.when(
                          data: (count) => '${count.toString().toUpperCase()} MEMBERS JOINED',
                          loading: () => '... MEMBERS JOINED',
                          error: (_, _) => 'MEMBERS JOINED',
                        ),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'Network with the community now',
                        style: GoogleFonts.inter(color: AppColors.textDim, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textDim, size: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkAndShowFeedbackPopup() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final currentEvent = ref.read(currentEventStreamProvider).value;
    if (currentEvent == null) return;

    final schedules = await ref.read(adminRepositoryProvider).getSchedulesForEvent(currentEvent.id);
    final now = DateTime.now();

    for (final session in schedules) {
      // If session ended in the last 30 minutes
      if (session.endTime.isBefore(now) && session.endTime.isAfter(now.subtract(const Duration(minutes: 30)))) {
        // Check if user already gave feedback
        final feedbackExists = await FirebaseFirestore.instance
            .collection('session_feedback')
            .where('userId', isEqualTo: userId)
            .where('sessionId', isEqualTo: session.id)
            .get()
            .then((val) => val.docs.isNotEmpty);

        if (!feedbackExists && mounted) {
          _showFeedbackDialog(session.id, session.title);
          break; // Show only one at a time
        }
      }
    }
  }

  void _showFeedbackDialog(String sessionId, String title) {
    int rating = 5;
    final commentController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Rate Session', style: GoogleFonts.outfit(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < rating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                    onPressed: () => setDialogState(() => rating = index + 1),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: commentController,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Any comments?',
                  hintStyle: const TextStyle(color: Colors.white24),
                  filled: true,
                  fillColor: Colors.white10,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Maybe Later')),
            ElevatedButton(
              onPressed: () async {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  await ref.read(profileRepositoryProvider).submitSessionFeedback(
                    userId: userId,
                    sessionId: sessionId,
                    rating: rating,
                    comment: commentController.text,
                  );
                  if (context.mounted) Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.black),
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSponsorsSlider(List<new_sponsor.Sponsor> sponsors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('EVENT SPONSORS'),
        const SizedBox(height: 24),
        SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: sponsors.length,
            clipBehavior: Clip.none,
            itemBuilder: (context, index) {
              final sponsor = sponsors[index];
              return GestureDetector(
                onTap: () => _showSponsorDetails(sponsor),
                child: Container(
                  width: 110,
                  margin: const EdgeInsets.only(right: 16),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Center(
                    child: Hero(
                      tag: 'sponsor_${sponsor.name}',
                      child: Image.network(
                        sponsor.logoUrl,
                        height: 50,
                        width: 50,
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showSponsorDetails(new_sponsor.Sponsor sponsor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.background,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(sponsor.logoUrl, height: 80),
            const SizedBox(height: 24),
            Text(sponsor.name, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(sponsor.tier.toUpperCase(), style: const TextStyle(color: AppColors.primary, letterSpacing: 2, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text(sponsor.description ?? 'Proud sponsor of the event.', textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null) {
                        ref.read(profileRepositoryProvider).trackSponsorInteraction(userId, sponsor.id, 'visit_booth');
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Locating booth on map...')));
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('VISIT BOOTH'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      final userId = FirebaseAuth.instance.currentUser?.uid;
                      if (userId != null) {
                        ref.read(profileRepositoryProvider).trackSponsorInteraction(userId, sponsor.id, 'claim_offer');
                        // 6. Push Notifications - Sponsor offer alert
                        notificationService.showSponsorOfferAlert(
                          sponsorId: sponsor.id,
                          sponsorName: sponsor.name,
                          offerText: 'Your offer has been claimed! Visit the booth to collect.',
                        );
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Offer claimed successfully!'), backgroundColor: Colors.green));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('CLAIM OFFER'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  Widget _buildSpeakersList(List<new_speaker.Speaker> speakers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader('KEYNOTE SPEAKERS'),
        const SizedBox(height: 24),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: speakers.length,
          itemBuilder: (context, index) {
            final speaker = speakers[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: common_widgets.GlassCard(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white12,
                      ),
                      child: ClipOval(
                        child: speaker.imageUrl.isNotEmpty
                            ? Image.network(
                                speaker.imageUrl,
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const Icon(Icons.person, color: Colors.white),
                              )
                            : const Icon(Icons.person, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            speaker.name,
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            speaker.role,
                            style: const TextStyle(color: AppColors.primary, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            speaker.bio ?? '',
                            style: const TextStyle(color: AppColors.textDim, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w900,
        fontSize: 14,
        letterSpacing: 2,
        color: AppColors.textDim,
      ),
    );
  }
}
