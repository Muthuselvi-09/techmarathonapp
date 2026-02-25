// Sync version: 2026-01-09-15-45
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Direct import for robust check
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

import 'package:tech_marathon_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tech_marathon_app/features/auth/data/auth_repository.dart';
import 'package:tech_marathon_app/features/auth/data/user_repository.dart';
import 'package:tech_marathon_app/core/widgets/event_drawer.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/search_provider.dart';
import 'package:tech_marathon_app/features/home/data/search_repository.dart';
import 'package:tech_marathon_app/features/core/services/location_service.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/features/home/data/proximity_repository.dart';
import 'package:tech_marathon_app/features/core/models/user_location.dart';
import 'package:tech_marathon_app/features/core/providers/user_location_provider.dart';
import 'package:tech_marathon_app/core/providers.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart' as new_speaker;
import 'package:tech_marathon_app/features/home/domain/event_models.dart' as new_sponsor;
import 'package:tech_marathon_app/data/models/schedule.dart' as new_schedule;

import 'sponsor_details_screen.dart';
import 'speaker_details_screen.dart';
import 'schedule_details_screen.dart';
import 'event_info_screen.dart';
import 'food_course_screen.dart';
import 'live_feed_screen.dart';
import '../../../chat/presentation/pages/admin_chat_page.dart';
import 'view_all_screens.dart'; // Import ViewAll screens


import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/branding_provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      final location = next.value;
      if (user != null && location != null) {
        ref.read(userRepositoryProvider).updateLocation(user.uid, location.toMap());
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
// Enhanced providers using proper Repository pattern and Event ID dependency


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
                      data: (loc) => loc != null ? '${loc.area}, ${loc.city}' : (currentEventAsync.value?.location ?? 'Unknown Location'),
                      loading: () => 'Detecting location...',
                      error: (_, _) => currentEventAsync.value?.location ?? 'Unknown Location',
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildProfileCompletionBanner(),
                  const SizedBox(height: 32),
                  _buildEventsSection(),
                  const SizedBox(height: 32),
                  _buildSponsorsSection(),
                  const SizedBox(height: 48),
                  _buildSliderCards(),
                  const SizedBox(height: 32),
                  _buildParticipantsBanner(context),
                  const SizedBox(height: 32),
                  _buildJoinMembersList(),
                  const SizedBox(height: 48),
                  _buildZhaCommerceBanner(),
                  const SizedBox(height: 48),
                  _buildSpeakersSection(),
                  const SizedBox(height: 120),
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
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
              separatorBuilder: (_, _) => Divider(color: Colors.white.withValues(alpha: 0.05)),
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
                       final sponsor = new_sponsor.Sponsor(
                         id: result.id,
                         eventId: result.data['eventId'] ?? '',
                         name: result.data['name'] ?? '',
                         tier: result.data['tier'] ?? 'Gold',
                         company: result.data['company'] ?? result.data['tier'] ?? 'Gold',
                         logoUrl: result.data['logoUrl'] ?? '',
                         websiteUrl: result.data['websiteUrl'] ?? '',
                       );
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => SponsorDetailsScreen(sponsor: sponsor),
                         ),
                       );
                     } else if (result.type == 'Speaker') {
                       final speaker = new_speaker.Speaker(
                         id: result.id,
                         eventId: result.data['eventId'] ?? '',
                         name: result.data['name'] ?? '',
                         imageUrl: result.data['imageUrl'] ?? result.data['photoUrl'] ?? '',
                         role: result.data['role'] ?? result.data['topic'] ?? '',
                         bio: result.data['bio'] ?? result.data['company'] ?? '',
                         linkedinUrl: result.data['linkedinUrl'] ?? result.data['linkedInUrl'] ?? '',
                       );
                       Navigator.push(
                         context,
                         MaterialPageRoute(
                           builder: (context) => SpeakerDetailsScreen(speaker: speaker),
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
          colors: [AppColors.primary.withValues(alpha: 0.2), AppColors.surface],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
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
                    fontSize: 14, // Slightly smaller for narrow
                  ),
                ),
                Text(
                  'Unlock networking features', // Shortened
                  style: GoogleFonts.inter(
                    color: AppColors.textDim,
                    fontSize: 11, // Slightly smaller
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            height: 36,
            child: ElevatedButton(
              onPressed: () => context.push('/profile-completion'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: const Text('Complete', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)), // Shortened text
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2, end: 0, duration: 600.ms, curve: Curves.easeOut);
  }

  Widget _buildHeader(BuildContext context) {
    final brandingAsync = ref.watch(brandingProvider);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
      child: brandingAsync.when(
        data: (branding) => Stack(
          alignment: Alignment.center,
          children: [
            // Left: Menu
            Align(
              alignment: Alignment.centerLeft,
              child: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            
            // Center: Company Name + Logo
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48.0),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo (moved from right)
                    if (branding.companyLogoUrl != null && branding.companyLogoUrl!.isNotEmpty) ...[
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 40, maxHeight: 40),
                        child: CachedNetworkImage(
                          imageUrl: branding.companyLogoUrl!,
                          fit: BoxFit.contain,
                          placeholder: (_, _) => const SizedBox(width: 20, height: 20),
                          errorWidget: (_, _, _) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    
                    // Name
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 200),
                        child: Text(
                          branding.companyName.toUpperCase(),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2,
                            fontSize: 18,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Right: Actions
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.textPrimary),
                    onPressed: () {
                      // Bypass login for now as requested
                      context.push('/admin');
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                    onPressed: () => context.push('/notifications'),
                  ),
                ],
              ),
            ),
          ],
        ),
        loading: () => Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            Text(
              'EVENT APP',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.textPrimary),
                    onPressed: () => context.push('/admin-login'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                    onPressed: () => context.push('/notifications'),
                  ),
                ],
              ),
            ),
          ],
        ),
        error: (_, _) => Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu_rounded, color: AppColors.textPrimary),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
            ),
            Text(
              'EVENT APP',
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
                fontSize: 16,
                color: AppColors.textPrimary,
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined, color: AppColors.textPrimary),
                    onPressed: () => context.push('/admin-login'),
                  ),
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                    onPressed: () => context.push('/notifications'),
                  ),
                ],
              ),
            ),
          ],
        ),
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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

  Widget _buildEventsSection() {
    final allEventsAsync = ref.watch(allEventsStreamProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EVENTS',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ViewAllEventsScreen()),
                ),
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
          height: 220,
          child: allEventsAsync.when(
            data: (events) {
              if (events.isEmpty) {
                return const Center(child: Text('No events found', style: TextStyle(color: Colors.white38)));
              }
              return ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Stack(
                        children: [
                          if (event.imageUrl.isNotEmpty)
                            Positioned.fill(
                              child: Image.network(
                                event.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(
                                  color: Colors.white12,
                                  child: const Center(child: Icon(Icons.event_note, color: Colors.white10, size: 40)),
                                ),
                              ),
                            )
                          else
                             Positioned.fill(
                              child: Container(
                                color: Colors.white12,
                                child: const Center(child: Icon(Icons.event_note, color: Colors.white10, size: 40)),
                              ),
                            ),
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.8),
                                    Colors.black.withValues(alpha: 0.2),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(24),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EventInfoScreen(eventId: event.id),
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      event.name,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on, size: 12, color: AppColors.primary),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            event.location,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary.withValues(alpha: 0.2),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                          ),
                                          child: Text(
                                            event.isFree ? 'Free' : '${event.currency}${event.entryFee}',
                                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
          ),
        ),
      ],
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
                  destination = const LiveFeedScreen(); // LIVE FEED
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
                    colors: [card['color'], (card['color'] as Color).withValues(alpha: 0.5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: (card['color'] as Color).withValues(alpha: 0.2),
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
                        color: Colors.white.withValues(alpha: 0.1),
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
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
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
                              border: Border.all(color: AppColors.primary.withValues(alpha: 0.5)),
                            ),
                            child: Builder(
                              builder: (context) {
                                final String? imageUrl = member.profileImage;
                                return CircleAvatar(
                                  radius: 30,
                                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                                      ? NetworkImage(imageUrl)
                                      : null,
                                  backgroundColor: AppColors.surface,
                                  child: (imageUrl == null || imageUrl.isEmpty)
                                      ? const Icon(Icons.person, color: AppColors.textDim)
                                      : null,
                                );
                              }
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
              final allSponsors = mergedSponsors;

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
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(24),
                          onTap: () {
                            if (index == 1) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const ScheduleDetailsScreen(),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SponsorDetailsScreen(sponsor: sponsor),
                                ),
                              );
                            }
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
                                sponsor.tier,
                                style: TextStyle(color: AppColors.textDim, fontSize: 10),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                sponsor.websiteUrl,
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
            error: (err, _) => Center(child: Text('Error loading sponsors: $err', style: TextStyle(color: AppColors.error))),
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
              final allSpeakers = mergedSpeakers;

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
                final imageAsset = speaker.imageUrl;
                final isNetwork = speaker.imageUrl.isNotEmpty;
                
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
                            builder: (context) => SpeakerDetailsScreen(speaker: speaker),
                          ),
                        );
                      },
                      child: Stack(
                        children: [
                          isNetwork 
                            ? Image.network(
                                imageAsset, 
                                height: double.infinity, 
                                width: double.infinity, 
                                fit: BoxFit.cover, 
                                errorBuilder: (_,__,___) => Container(
                                  color: Colors.white12,
                                  child: const Icon(Icons.person, color: Colors.white24, size: 50),
                                ),
                              )
                            : Container(
                                color: Colors.white12,
                                child: const Icon(Icons.person, color: Colors.white24, size: 50),
                              ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
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
                                  speaker.role, // Use role
                                  style: const TextStyle(fontSize: 10, color: AppColors.primary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  speaker.bio ?? '', // Bio provided
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

  Widget _buildScheduleSnapshot() {
    final schedulesAsync = ref.watch(schedulesStreamProvider);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'LIVE & UPCOMING',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 2,
                  color: AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ScheduleDetailsScreen())),
                child: Text('VIEW ALL', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          schedulesAsync.when(
            data: (schedules) {
               if (schedules.isEmpty) return const SizedBox.shrink();
               
               final now = DateTime.now();
               final published = schedules.where((s) => s.status == 'published').toList();
               if (published.isEmpty) return const SizedBox.shrink();

               final sorted = List.from(published)..sort((a,b) => a.startTime.compareTo(b.startTime));
               
               final liveSessions = sorted.where((s) => s.startTime.isBefore(now) && s.endTime.isAfter(now)).toList();
               final nextSessions = sorted.where((s) => s.startTime.isAfter(now)).toList();
               
               if (liveSessions.isEmpty && nextSessions.isEmpty) return const SizedBox.shrink();
               
               final session = liveSessions.isNotEmpty ? liveSessions.first : nextSessions.first;
               final isLive = liveSessions.isNotEmpty;
               
               return _sessionHighlightCard(session, isLive);
            },
            loading: () => Container(
              height: 120,
              decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(24)),
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (err, _) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _sessionHighlightCard(new_schedule.Schedule session, bool isLive) {
     return Container(
       padding: const EdgeInsets.all(24),
       decoration: BoxDecoration(
         color: AppColors.surface,
         borderRadius: BorderRadius.circular(24),
         border: Border.all(color: isLive ? AppColors.primary.withValues(alpha: 0.3) : Colors.white.withValues(alpha: 0.05)),
         boxShadow: isLive ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 20, spreadRadius: 5)] : null,
       ),
       child: Column(
         crossAxisAlignment: CrossAxisAlignment.start,
         children: [
           Row(
             children: [
               if (isLive) ...[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                  ).animate(onPlay: (c) => c.repeat()).scale(begin: const Offset(1,1), end: const Offset(1.5,1.5), duration: 800.ms).fadeOut(),
                  const SizedBox(width: 8),
                  Text('LIVE NOW', style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
               ] else ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text('UP NEXT', style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 10, letterSpacing: 1)),
                  ),
               ],
               const Spacer(),
               Text('${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}', style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12)),
             ],
           ),
           const SizedBox(height: 16),
           Text(
             session.title, 
             style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white, height: 1.2),
             maxLines: 2,
             overflow: TextOverflow.ellipsis,
           ),
           const SizedBox(height: 12),
           Row(
             children: [
               const Icon(Icons.room_rounded, color: AppColors.primary, size: 14),
               const SizedBox(width: 4),
               Expanded(
                 child: Text(
                   session.hall.isNotEmpty ? session.hall : (session.location.isNotEmpty ? session.location : 'Main Hall'), 
                   style: GoogleFonts.inter(color: AppColors.textDim, fontSize: 12),
                   maxLines: 1,
                   overflow: TextOverflow.ellipsis,
                 ),
               ),
               const SizedBox(width: 16),
               const Icon(Icons.person_outline_rounded, color: AppColors.primary, size: 14),
               const SizedBox(width: 4),
               Text(
                 '${session.speakerIds.length} Speaker${session.speakerIds.length > 1 ? 's' : ''}', 
                 style: GoogleFonts.inter(color: AppColors.textDim, fontSize: 12),
               ),
             ],
           ),
         ],
       ),
     );
  }
}
