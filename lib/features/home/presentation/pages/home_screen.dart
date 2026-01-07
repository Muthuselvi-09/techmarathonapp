import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Direct import for robust check
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../events/data/mock_data.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../auth/data/auth_repository.dart';
import '../../../auth/data/user_repository.dart';
import '../../../../core/widgets/event_drawer.dart';
import '../../../admin/data/admin_repository.dart'; // Import AdminRepo for real data
import '../../../admin/presentation/providers/optimistic_state_provider.dart'; // Import optimistic state
import 'package:url_launcher/url_launcher.dart';
import '../../presentation/providers/search_provider.dart';
import '../../data/search_repository.dart';
import '../../../core/services/location_service.dart';
import '../../domain/event_models.dart';
import '../../data/proximity_repository.dart';
import '../../../core/models/user_location.dart';
import '../../../core/providers/user_location_provider.dart';
import 'sponsor_details_screen.dart';
import 'speaker_details_screen.dart';
import 'schedule_details_screen.dart';
import 'event_info_screen.dart';
import 'food_course_screen.dart';
import '../../../chat/presentation/pages/admin_chat_page.dart';
import 'view_all_screens.dart'; // Import ViewAll screens

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      ref.read(debouncedSearchQueryProvider.notifier).update(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _listenToLocation() {
    ref.listen(userLocationProvider, (previous, next) {
      final user = ref.read(authStateProvider).valueOrNull;
      if (user != null && next.value != null) {
        ref.read(userRepositoryProvider).updateLocation(user.uid, next.value!.toMap());
      }
    });
  }

  Future<void> _launchURL(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch $url')),
        );
      }
    }
  }


// Enhanced providers with optimistic state merging
final currentEventStreamProvider = StreamProvider<CodingEvent?>((ref) {
  final firestoreEvents = ref.watch(adminRepositoryProvider).watchEvents();
  final optimisticEvents = ref.watch(optimisticEventsProvider);
  
  return firestoreEvents.map((events) {
    // Merge optimistic events with Firestore events
    final allEvents = [...optimisticEvents, ...events];
    if (allEvents.isEmpty) return null;
    return allEvents.first;
  });
});

final mergedSpeakersProvider = StreamProvider<List<Speaker>>((ref) {
  final firestoreSpeakers = ref.watch(adminRepositoryProvider).watchSpeakers();
  final optimisticSpeakers = ref.watch(optimisticSpeakersProvider);
  
  return firestoreSpeakers.map((speakers) {
    // Merge optimistic with Firestore, avoiding duplicates
    final merged = <String, Speaker>{};
    for (final s in speakers) {
      merged[s.id] = s;
    }
    for (final s in optimisticSpeakers) {
      merged[s.id] = s; // Optimistic overrides Firestore
    }
    return merged.values.toList();
  });
});

final mergedSponsorsProvider = StreamProvider<List<Sponsor>>((ref) {
  final firestoreSponsors = ref.watch(adminRepositoryProvider).watchSponsors();
  final optimisticSponsors = ref.watch(optimisticSponsorsProvider);
  
  return firestoreSponsors.map((sponsors) {
    final merged = <String, Sponsor>{};
    for (final s in sponsors) {
      merged[s.id] = s;
    }
    for (final s in optimisticSponsors) {
      merged[s.id] = s;
    }
    return merged.values.toList();
  });
});


  @override
  Widget build(BuildContext context) {
    _listenToLocation();
    final locationAsync = ref.watch(userLocationProvider);
    final searchResultsAsync = ref.watch(searchProvider);
    final currentEventAsync = ref.watch(currentEventStreamProvider);

    return Container(
      decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        drawer: const EventDrawer(),
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              controller: _scrollController,
              child: Column(
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  _buildLocationAndSearch(
                    locationAsync.when(
                      data: (loc) => loc != null ? '${loc.area}, ${loc.city}' : (currentEventAsync.value?.location ?? MockData.currentEvent.location),
                      loading: () => 'Detecting location...',
                      error: (_, __) => currentEventAsync.value?.location ?? MockData.currentEvent.location,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildProfileCompletionBanner(),
                  const SizedBox(height: 24),
                  _buildSliderCards(),
                  const SizedBox(height: 32),
                  _buildParticipantsBanner(context),
                  const SizedBox(height: 32),
                  _buildJoinMembersList(),
                  const SizedBox(height: 48),
                  _buildSponsorsSection(),
                  const SizedBox(height: 48),
                  _buildZhaCommerceBanner(),
                  const SizedBox(height: 48),
                  _buildSpeakersSection(),
                  const SizedBox(height: 120), // Extra space for bottom nav
                ],
              ),
            ),
            // Search Results Overlay
            if (_searchController.text.length >= 2)
              _buildSearchResultsOverlay(searchResultsAsync),
          ],
        ),
      ),
      ),
    );
  }

  Widget _buildSearchResultsOverlay(AsyncValue<List<SearchResult>> searchResultsAsync) {
    return Positioned(
      top: 140, // Adjust based on search bar position
      left: 24,
      right: 24,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 400),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: searchResultsAsync.when(
          data: (results) {
            if (results.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(16),
                child: Text('No results found', style: TextStyle(color: AppColors.textDim)),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: results.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05)),
              itemBuilder: (context, index) {
                final result = results[index];
                return ListTile(
                  title: Text(result.title, style: const TextStyle(color: Colors.white)),
                  subtitle: Text(result.type, style: TextStyle(color: AppColors.primary, fontSize: 10)),
                  trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.textDim),
                  onTap: () {
                     // Navigate based on type
                     if (result.type == 'Member') {
                       final member = Participant(
                         id: result.id,
                         name: result.title,
                         email: result.data['email'] ?? '',
                         mobile: result.data['mobile'] ?? '',
                         profileImage: result.data['profileImage'],
                         profileCompletion: (result.data['profileCompletion'] ?? 0.0).toDouble(),
                       );
                       context.push('/member-profile', extra: member);
                     } else if (result.type == 'Sponsor') {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SponsorDetailsScreen(
                            image: result.data['logoUrl'] ?? '',
                            name: result.data['name'] ?? '',
                            description: result.data['company'] ?? '',
                          ),
                        ),
                      );
                     } else if (result.type == 'Speaker') {
                       Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SpeakerDetailsScreen(
                            image: result.data['photoUrl'] ?? 'assets/images/speaker1.png',
                            name: result.data['name'] ?? '',
                            role: result.data['topic'] ?? '',
                            bio: result.data['company'] ?? '',
                          ),
                        ),
                      );
                     }
                  },
                );
              },
            );
          },
          loading: () => const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Padding(
            padding: EdgeInsets.all(16),
            child: Text('Error: $err', style: TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }


  Widget _buildProfileCompletionBanner() {
    // FORCE VISIBLE - Removed isComplete check as strictly requested by user
    // final isComplete = ref.watch(profileProvider.select((s) => s.isComplete));
    // if (isComplete) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withOpacity(0.2), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Complete your profile',
                  style: GoogleFonts.outfit(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Unlock full networking features',
                  style: GoogleFonts.inter(
                    color: AppColors.textDim,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => context.push('/profile-completion'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: const Text('Complete Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }

  // Refactored to standard Widget to scroll with the page
  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
              onPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          Text(
            'CODING RIM',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 16,
              color: AppColors.textPrimary,
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.textPrimary),
                onPressed: () {
                  // Direct SDK check to avoid provider stream latency/conflicts
                  final user = FirebaseAuth.instance.currentUser;
                  if (user != null) {
                    context.push('/admin'); // Correct route path per internal router
                  } else {
                    context.push('/admin-login');
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                onPressed: () => context.push('/notifications'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationAndSearch(String location) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                location,
                style: GoogleFonts.inter(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search events or participants...',
                hintStyle: TextStyle(color: AppColors.textDim),
                icon: Icon(Icons.search, color: AppColors.textDim),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliderCards() {
    final List<Map<String, dynamic>> cards = [
      {'title': 'VIP PASS', 'color': AppColors.secondary, 'icon': Icons.stars_rounded},
      {'title': 'SCHEDULE', 'color': AppColors.primary, 'icon': Icons.event_note_rounded},
      {'title': 'LIVE FEED', 'color': AppColors.accent, 'icon': Icons.sensors_rounded},
    ];

    return SizedBox(
      height: 160,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length,
        itemBuilder: (context, index) {
          final card = cards[index];
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () {
                // Navigate based on card index
                Widget destination;
                if (index == 0) {
                  destination = const EventInfoScreen(); // VIP PASS -> Event Details
                } else if (index == 1) {
                  destination = const ScheduleDetailsScreen(); // SCHEDULE
                } else {
                  destination = const FoodCourseScreen(); // LIVE FEED -> Food/Course
                }
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => destination),
                );
              },
              child: Container(
                width: 280,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [card['color'], (card['color'] as Color).withOpacity(0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (card['color'] as Color).withOpacity(0.2),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        card['icon'],
                        size: 120,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            card['title'],
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'ACCESS NOW',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.white70,
                              letterSpacing: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildParticipantsBanner(BuildContext context) {
    final countAsync = ref.watch(totalParticipantsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: GestureDetector(
        onTap: () => context.push('/participants'),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.people_alt_rounded, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TOTAL USERS JOINED',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.textDim,
                        letterSpacing: 1.5,
                      ),
                    ),
                    countAsync.when(
                      data: (count) => Text(
                        '$count Members',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      loading: () => const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      error: (err, _) => const Text('Error'),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textDim, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildJoinMembersList() {
    final membersAsync = ref.watch(participantsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'JOIN MEMBERS',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllMembersScreen())),
                child: Text(
                  'VIEW ALL',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: membersAsync.when(
            data: (members) {
              if (members.isEmpty) {
                return Center(
                  child: Text(
                    'No members yet',
                    style: TextStyle(color: AppColors.textDim, fontSize: 12),
                  ),
                );
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return GestureDetector(
                    onTap: () => context.push('/member-profile', extra: member),
                    child: Container(
                      width: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                            ),
                            child: CircleAvatar(
                              radius: 30,
                              backgroundImage: member.profileImage != null && member.profileImage!.isNotEmpty
                                  ? NetworkImage(member.profileImage!)
                                  : null,
                              backgroundColor: AppColors.surface,
                              child: member.profileImage == null || member.profileImage!.isEmpty
                                  ? const Icon(Icons.person, color: AppColors.textDim)
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            member.name.isEmpty ? 'User' : member.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'ID: ${member.id.substring(0, 4)}...',
                            style: TextStyle(color: AppColors.textDim, fontSize: 8),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error', style: TextStyle(color: AppColors.error))),
          ),
        ),
      ],
    );
  }

  Widget _buildSponsorsSection() {
    final mergedSponsorsAsync = ref.watch(mergedSponsorsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EVENT SPONSORS',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllSponsorsScreen())),
                child: Text('VIEW ALL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 200,
          child: mergedSponsorsAsync.when(
            data: (mergedSponsors) {
              final allSponsors = [...MockData.currentEvent.sponsors, ...mergedSponsors];

              if (allSponsors.isEmpty) {
                 return const Center(child: Text('No sponsors yet', style: TextStyle(color: Colors.white38)));
              }

              return ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: allSponsors.length,
              itemBuilder: (context, index) {
                final sponsor = allSponsors[index];
                return Container(
                      width: 160,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
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
                              Text(
                                sponsor.name,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                              ),
                              Text(
                                sponsor.company,
                                style: TextStyle(color: AppColors.textDim, fontSize: 10),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sponsor.jobPosition,
                                style: const TextStyle(fontSize: 10, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading sponsors', style: TextStyle(color: AppColors.error))),
          ),
        ),
      ],
    );
  }

  Widget _buildZhaCommerceBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _launchURL('https://zhacommerce.com'),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: AppColors.tealGradient,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  'ZhaCommerce',
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'PROUDLY SUPPORTING TECH INNOVATION',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpeakersSection() {
    final mergedSpeakersAsync = ref.watch(mergedSpeakersProvider);
    final speakerImages = [
      'assets/images/speaker1.png',
      'assets/images/speaker2.png',
      'assets/images/speaker3.png',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPEAKERS',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ViewAllSpeakersScreen())),
                child: Text('VIEW ALL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          height: 240,
          child: mergedSpeakersAsync.when(
            data: (mergedSpeakers) {
              final allSpeakers = [...MockData.currentEvent.speakers, ...mergedSpeakers];

              if (allSpeakers.isEmpty) {
                 return const Center(child: Text('No speakers yet', style: TextStyle(color: Colors.white38)));
              }

              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: allSpeakers.length,
                itemBuilder: (context, index) {
                final speaker = allSpeakers[index];
                final imageAsset = speaker.photoUrl.isNotEmpty ? speaker.photoUrl : speakerImages[index % speakerImages.length];
                final isNetwork = speaker.photoUrl.isNotEmpty;
                
                return Container(
                  width: 200,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SpeakerDetailsScreen(
                              image: imageAsset,
                              name: speaker.name,
                              role: speaker.topic,
                              bio: speaker.bio ?? '',
                            ),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          isNetwork 
                            ? Image.network(imageAsset, height: double.infinity, width: double.infinity, fit: BoxFit.cover, errorBuilder: (_,__,___) => Container(color: Colors.grey))
                            : Image.asset(imageAsset, height: double.infinity, width: double.infinity, fit: BoxFit.cover),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withOpacity(0.8), Colors.transparent],
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  speaker.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                                Text(
                                  speaker.company,
                                  style: const TextStyle(fontSize: 10, color: AppColors.primary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  speaker.topic,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 10, color: Colors.white70),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error loading speakers', style: TextStyle(color: AppColors.error))),
          ),
        ),
      ],
    );
  }
}
