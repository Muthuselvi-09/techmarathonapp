import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/features/home/presentation/pages/sponsor_details_screen.dart';
import 'package:tech_marathon_app/features/profile/data/profile_repository.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';

class SavedSponsorsScreen extends ConsumerWidget {
  const SavedSponsorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('SAVED SPONSORS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: userId == null
          ? const Center(child: Text('Please login to view saved sponsors'))
          : StreamBuilder<List<String>>(
              stream: ref.watch(profileRepositoryProvider).getFavoriteSponsorIds(userId),
              builder: (context, favSnapshot) {
                if (favSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final favIds = favSnapshot.data ?? [];
                if (favIds.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border, size: 64, color: AppColors.primary.withOpacity(0.3)),
                        const SizedBox(height: 16),
                        Text('No sponsors saved yet', style: TextStyle(color: Colors.white.withOpacity(0.5))),
                      ],
                    ),
                  );
                }

                return StreamBuilder<List<Sponsor>>(
                  stream: ref.watch(adminRepositoryProvider).watchAllSponsors(),
                  builder: (context, sponsorSnapshot) {
                    if (!sponsorSnapshot.hasData) return const Center(child: CircularProgressIndicator());

                    final savedSponsors = sponsorSnapshot.data!
                        .where((s) => favIds.contains(s.id))
                        .toList();

                    return ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: savedSponsors.length,
                      itemBuilder: (context, index) {
                        final sponsor = savedSponsors[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: ListTile(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SponsorDetailsScreen(sponsor: sponsor)),
                            ),
                            contentPadding: const EdgeInsets.all(12),
                            leading: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: CachedNetworkImage(
                                  imageUrl: sponsor.logoUrl,
                                  fit: BoxFit.contain,
                                  errorWidget: (_, __, ___) => const Icon(Icons.business),
                                ),
                              ),
                            ),
                            title: Text(sponsor.name, style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
                            subtitle: Text(sponsor.tier, style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                            trailing: IconButton(
                              icon: const Icon(Icons.bookmark, color: AppColors.primary),
                              onPressed: () => ref.read(profileRepositoryProvider).toggleFavoriteSponsor(userId, sponsor.id),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }
}
