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
import '../providers/event_stream_providers.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart' as new_speaker;
import 'package:tech_marathon_app/features/home/domain/event_models.dart' as new_sponsor;
import 'event_info_screen.dart';

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
              separatorBuilder: (_, _) => Divider(color: Colors.white.withValues(alpha: 0.05)),
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
    final speakersAsync = ref.watch(mergedSpeakersProvider);

    return Container(
      decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context, 'ALL SPEAKERS'),
        body: speakersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
          data: (speakers) {
            if (speakers.isEmpty) return const Center(child: Text('No speakers yet', style: TextStyle(color: Colors.white38)));
            
            return ListView.separated(
              padding: const EdgeInsets.all(24),
              itemCount: speakers.length,
              separatorBuilder: (_, _) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final speaker = speakers[index];
                return GestureDetector(
                  onTap: () {
                     Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SpeakerDetailsScreen(speaker: speaker),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: speaker.imageUrl.isNotEmpty
                            ? Image.network(
                                speaker.imageUrl,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => Container(width: 60, height: 60, color: Colors.white12, child: const Icon(Icons.mic, color: Colors.white)),
                              )
                            : Container(width: 60, height: 60, color: Colors.white12, child: const Icon(Icons.person, color: Colors.white)),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(speaker.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              const SizedBox(height: 4),
                              Text(speaker.role, style: const TextStyle(color: AppColors.primary, fontSize: 12)),
                              Text(speaker.bio ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
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
    final sponsorsAsync = ref.watch(mergedSponsorsProvider);

    return Container(
      decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: _buildAppBar(context, 'ALL SPONSORS'),
        body: sponsorsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
          data: (sponsors) {
            if (sponsors.isEmpty) return const Center(child: Text('No sponsors yet', style: TextStyle(color: Colors.white38)));
            
            return GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: sponsors.length,
              itemBuilder: (context, index) {
                final sponsor = sponsors[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SponsorDetailsScreen(sponsor: sponsor),
                      ),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
                          child: sponsor.logoUrl.isNotEmpty
                            ? Image.network(sponsor.logoUrl, height: 40, width: 40, fit: BoxFit.contain, errorBuilder: (_,__,___) => const Icon(Icons.business))
                            : const Icon(Icons.business, color: Colors.black),
                        ),
                        const SizedBox(height: 16),
                        Text(sponsor.name, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(sponsor.tier, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.primary, fontSize: 10)),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

// --- VIEW ALL EVENTS ---
class ViewAllEventsScreen extends ConsumerStatefulWidget {
  const ViewAllEventsScreen({super.key});

  @override
  ConsumerState<ViewAllEventsScreen> createState() => _ViewAllEventsScreenState();
}

class _ViewAllEventsScreenState extends ConsumerState<ViewAllEventsScreen> {
  String selectedCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  final List<String> categories = ['All', 'Weddings', 'Concerts', 'Sports', 'Education'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(allEventsStreamProvider);
    final userProfile = ref.watch(profileProvider);
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildListingHeader(userProfile.user?.name ?? 'Guest'),
              const SizedBox(height: 16),
              _buildPremiumSearchBar(),
              const SizedBox(height: 24),
              _buildCategoryChips(),
              const SizedBox(height: 24),
              Expanded(
                child: categoriesAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                  data: (categories) {
                    return eventsAsync.when(
                      data: (events) {
                        final searchQuery = _searchController.text.toLowerCase();
                        final filteredEvents = events.where((e) {
                          final matchesCategory = selectedCategory == 'All' || 
                                               e.category == selectedCategory || 
                                               e.categoryId == selectedCategory;
                          final matchesSearch = e.name.toLowerCase().contains(searchQuery) || 
                                             e.location.toLowerCase().contains(searchQuery);
                          return matchesCategory && matchesSearch;
                        }).toList();

                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (filteredEvents.isNotEmpty && searchQuery.isEmpty)
                                _buildFeaturedCard(filteredEvents.first),
                              if (filteredEvents.isNotEmpty && searchQuery.isEmpty)
                                const SizedBox(height: 32),
                              
                              if (filteredEvents.isNotEmpty) ...[
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      searchQuery.isEmpty ? 'Trending' : 'Search Results',
                                      style: GoogleFonts.outfit(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    if (searchQuery.isEmpty)
                                      Text(
                                        'See All',
                                        style: GoogleFonts.inter(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                ...filteredEvents.map((e) => _buildTrendingItem(e)),
                              ] else
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 80),
                                    child: Column(
                                      children: [
                                        Icon(Icons.search_off_rounded, size: 64, color: Colors.white24),
                                        SizedBox(height: 16),
                                        Text('No events found', style: TextStyle(color: Colors.white38)),
                                      ],
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 100),
                            ],
                          ),
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
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

  Widget _buildListingHeader(String name) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.arrow_back, color: Colors.white)),
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hello,', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  Text(name, style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => context.push('/notifications'),
              padding: const EdgeInsets.all(8),
              icon: const Icon(Icons.notifications_none, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.white70, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {}),
                      style: GoogleFonts.inter(color: Colors.white, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: 'Search',
                        hintStyle: GoogleFonts.inter(color: Colors.white54, fontSize: 16),
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              // Open filter/category selector or just focus search
              FocusScope.of(context).unfocus();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              height: 56,
              width: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(Icons.tune, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categoriesAsync = ref.watch(categoriesStreamProvider);

    return categoriesAsync.when(
      loading: () => const SizedBox(height: 40),
      error: (_, _) => const SizedBox(height: 40),
      data: (categories) {
        final activeCategories = categories.where((c) => c.isEnabled).map((c) => c.name).toList();
        final allCats = ['All', ...activeCategories];

        return SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allCats.length,
            itemBuilder: (context, index) {
              final cat = allCats[index];
              final isSelected = selectedCategory == cat;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: GestureDetector(
                  onTap: () => setState(() => selectedCategory = cat),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? AppColors.mainGradient
                          : null,
                      color: isSelected ? null : Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: isSelected ? null : Border.all(color: Colors.white.withValues(alpha: 0.1)),
                    ),
                    child: Text(
                      cat,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFeaturedCard(CodingEvent event) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventInfoScreen(eventId: event.id)),
      ),
      child: Container(
        height: 380,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          image: (event.imageUrl.isNotEmpty)
              ? DecorationImage(
                  image: NetworkImage(event.imageUrl),
                  fit: BoxFit.cover,
                )
              : null,
          color: AppColors.surface,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                Colors.black.withValues(alpha: 0.9),
                Colors.black.withValues(alpha: 0.4),
                Colors.transparent,
              ],
            ),
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                event.name,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${event.date.month}/${event.date.day}/${event.date.year}', 
                style: GoogleFonts.inter(fontSize: 14, color: Colors.white70),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.location_on, size: 16, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text(event.location, style: GoogleFonts.inter(fontSize: 12, color: Colors.white70)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      event.isFree ? 'Free Entry' : '${event.currency}${event.entryFee} Entry',
                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      if (event.isFree) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => EventInfoScreen(eventId: event.id)),
                        );
                      } else {
                        context.push('/payment', extra: event);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        gradient: AppColors.mainGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrendingItem(CodingEvent event) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => EventInfoScreen(eventId: event.id)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                event.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(width: 80, height: 80, color: Colors.white10),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 12, color: Colors.white70),
                      const SizedBox(width: 4),
                      Text(event.location, style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                if (event.isFree) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EventInfoScreen(eventId: event.id)),
                  );
                } else {
                  context.push('/payment', extra: event);
                }
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  gradient: AppColors.mainGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  event.isFree ? 'FREE' : '${event.currency}${event.entryFee}',
                  style: const TextStyle(color: Colors.black, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
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
