import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tech_marathon_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/event_widgets.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart' as new_speaker;
import 'package:tech_marathon_app/features/home/domain/event_models.dart' as new_sponsor;
import 'package:tech_marathon_app/features/home/domain/event_models.dart';


class EventOverviewScreen extends ConsumerWidget {
  const EventOverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        title: const BrandHeader(),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          event.name.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 32,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            height: 1.1,
          ),
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
      ],
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

    return GlassCard(
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
          child: GlassCard(
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
              return Container(
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
              );
            },
          ),
        ),
      ],
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
              child: GlassCard(
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
                            style: TextStyle(color: AppColors.primary, fontSize: 12),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            speaker.bio ?? '',
                            style: TextStyle(color: AppColors.textDim, fontSize: 13),
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
