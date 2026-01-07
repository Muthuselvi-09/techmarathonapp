import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/data/user_repository.dart';
import '../../../admin/data/admin_repository.dart';
import '../../../../features/home/domain/event_models.dart';
import 'sponsor_details_screen.dart';
import 'speaker_details_screen.dart';
import 'package:tech_marathon_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:tech_marathon_app/features/events/data/mock_data.dart';

// --- VIEW ALL MEMBERS ---
class ViewAllMembersScreen extends ConsumerWidget {
  const ViewAllMembersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final membersAsync = ref.watch(participantsStreamProvider);

    return Container(
      decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context, 'ALL MEMBERS'),
        body: membersAsync.when(
          data: (members) {
            if (members.isEmpty) return const Center(child: Text('No details found', style: TextStyle(color: Colors.white38)));
            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: members.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05)),
              itemBuilder: (context, index) {
                final member = members[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundImage: member.profileImage != null ? NetworkImage(member.profileImage!) : null,
                    radius: 20,
                    child: member.profileImage == null ? const Icon(Icons.person) : null,
                  ),
                  title: Text(member.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(member.email, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right, color: Colors.white24),
                  onTap: () => context.push('/member-profile', extra: member),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
        ),
      ),
    );
  }
}

// --- VIEW ALL SPEAKERS ---
class ViewAllSpeakersScreen extends ConsumerWidget {
  const ViewAllSpeakersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Ideally use a shared EventRepository, but reusing AdminRepo for consistent Real-Time data
    final speakersStream = ref.watch(adminRepositoryProvider).watchSpeakers();

    return Container(
      decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context, 'ALL SPEAKERS'),
        body: ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: MockData.currentEvent.speakers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final speaker = MockData.currentEvent.speakers[index];
                return GestureDetector(
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpeakerDetailsScreen(
                          image: speaker.photoUrl,
                          name: speaker.name,
                          role: speaker.topic,
                          bio: speaker.bio ?? '',
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            speaker.photoUrl,
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: Colors.white12, child: const Icon(Icons.mic, color: Colors.white)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(speaker.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(speaker.topic, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                              Text(speaker.company, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}

// --- VIEW ALL SPONSORS ---
class ViewAllSponsorsScreen extends ConsumerWidget {
  const ViewAllSponsorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reusing AdminRepo stream for Real-Time Sponsors
    final sponsorsStream = ref.watch(adminRepositoryProvider).watchSponsors();

    return Container(
      decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context, 'ALL SPONSORS'),
        body: GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: MockData.currentEvent.sponsors.length,
              itemBuilder: (context, index) {
                final sponsor = MockData.currentEvent.sponsors[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SponsorDetailsScreen(
                          image: sponsor.logoUrl,
                          name: sponsor.name,
                          description: sponsor.company,
                        ),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.05)),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Image.network(sponsor.logoUrl, height: 40, width: 40, fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.business)),
                        ),
                        const SizedBox(height: 16),
                        Text(sponsor.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(sponsor.jobPosition, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.primary, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}

AppBar _buildAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: Colors.transparent,
    elevation: 0,
    centerTitle: true,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back, color: Colors.white),
      onPressed: () => Navigator.pop(context),
    ),
    title: Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2,
      ),
    ),
  );
}
