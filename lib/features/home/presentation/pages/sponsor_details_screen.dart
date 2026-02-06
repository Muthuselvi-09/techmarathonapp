import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/features/profile/data/profile_repository.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:tech_marathon_app/features/chat/presentation/pages/admin_chat_page.dart';

class SponsorDetailsScreen extends ConsumerStatefulWidget {
  final Sponsor sponsor;

  const SponsorDetailsScreen({
    super.key,
    required this.sponsor,
  });

  @override
  ConsumerState<SponsorDetailsScreen> createState() => _SponsorDetailsScreenState();
}

class _SponsorDetailsScreenState extends ConsumerState<SponsorDetailsScreen> {
  final ScrollController _scrollController = ScrollController();
  double _headerOpacity = 0.0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      final opacity = (_scrollController.offset / 200).clamp(0.0, 1.0);
      if (opacity != _headerOpacity) {
        setState(() => _headerOpacity = opacity);
      }
    });
  }

  void _claimOffer(Map<String, dynamic> offer) async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    try {
      await ref.read(profileRepositoryProvider).claimOffer(userId, widget.sponsor.id, offer);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offer "${offer['title']}" claimed! check your profile.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to claim offer. Please try again.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: [
              _buildAppBar(),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      _buildTagline(),
                      const SizedBox(height: 32),
                      _buildAboutSection(),
                      const SizedBox(height: 48),
                      _buildOffersSection(),
                      const SizedBox(height: 48),
                      _buildProductsSection(),
                      const SizedBox(height: 48),
                      _buildMediaGallery(),
                      const SizedBox(height: 48),
                      _buildBoothInfo(),
                      const SizedBox(height: 48),
                      _buildSocialLinks(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),
          
          // Floating Top Bar with back button and favorite
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _circularButton(
                  icon: Icons.arrow_back,
                  onTap: () => Navigator.pop(context),
                ),
                if (currentUserId != null)
                  StreamBuilder<List<String>>(
                    stream: ref.watch(profileRepositoryProvider).getFavoriteSponsorIds(currentUserId),
                    builder: (context, snapshot) {
                      final isFav = snapshot.data?.contains(widget.sponsor.id) ?? false;
                      return _circularButton(
                        icon: isFav ? Icons.bookmark : Icons.bookmark_border,
                        iconColor: isFav ? AppColors.primary : Colors.white,
                        onTap: () => ref.read(profileRepositoryProvider).toggleFavoriteSponsor(currentUserId, widget.sponsor.id),
                      );
                    }
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 350,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.background,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Banner Image
            if (widget.sponsor.bannerUrl.isNotEmpty)
              CachedNetworkImage(
                imageUrl: widget.sponsor.bannerUrl,
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1A1A1A), Color(0xFF2A2A2A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withOpacity(0.8),
                    Colors.transparent,
                    Colors.black.withOpacity(0.9),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            
            // Logo and Name overlay
            Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, spreadRadius: 5),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CachedNetworkImage(
                      imageUrl: widget.sponsor.logoUrl,
                      height: 80,
                      width: 80,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const SizedBox(height: 80, width: 80),
                      errorWidget: (context, url, error) => const Icon(Icons.business, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  widget.sponsor.name.toUpperCase(),
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.2),
                    border: Border.all(color: AppColors.primary.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.sponsor.tier.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagline() {
    if (widget.sponsor.tagline.isEmpty) return const SizedBox.shrink();
    return Center(
      child: Text(
        "\"${widget.sponsor.tagline}\"",
        textAlign: TextAlign.center,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w500,
          color: Colors.white.withOpacity(0.8),
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("ABOUT SPONSOR", Icons.info_outline),
        const SizedBox(height: 16),
        Text(
          widget.sponsor.detailedDescription ?? widget.sponsor.description ?? "No description available.",
          style: GoogleFonts.inter(
            fontSize: 16,
            color: Colors.white70,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          "Proud Sponsor of Tech Marathon 2026",
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildOffersSection() {
    final offers = widget.sponsor.offers;
    
    if (offers.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("EXCLUSIVE OFFERS", Icons.card_giftcard),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: offers.length,
            itemBuilder: (context, index) {
              final offer = offers[index];
              return Container(
                width: 280,
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.15), Colors.white.withOpacity(0.05)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(offer['title'] ?? 'Special Offer', 
                      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                    const SizedBox(height: 4),
                    Text(offer['description'] ?? '', 
                      maxLines: 2, style: GoogleFonts.inter(fontSize: 12, color: Colors.white54)),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(offer['code'] ?? 'N/A', 
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                        TextButton(
                          onPressed: () => _claimOffer(offer),
                          child: Text("CLAIM", style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary)),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductsSection() {
    final products = widget.sponsor.products;
    
    if (products.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("PRODUCTS & SERVICES", Icons.shopping_bag_outlined),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          itemBuilder: (context, index) {
            final p = products[index];
            return Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: CachedNetworkImage(
                        imageUrl: p['image'] ?? '',
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (context, url, error) => Container(color: Colors.white12),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p['name'] ?? '', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white)),
                          const SizedBox(height: 4),
                          Text("Learn more →", style: GoogleFonts.inter(fontSize: 12, color: AppColors.primary)),
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

  Widget _buildMediaGallery() {
    final media = widget.sponsor.media;
    
    if (media.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader("MEDIA GALLERY", Icons.movie_outlined),
        const SizedBox(height: 20),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: media.length,
            itemBuilder: (context, index) {
              return Container(
                width: 240,
                margin: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: DecorationImage(
                    image: CachedNetworkImageProvider(media[index]),
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBoothInfo() {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.location_on, color: AppColors.primary),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("VISIT BOOTH", style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.primary)),
                  Text(widget.sponsor.boothLocation ?? "Nearby Main Stage, Hall A", 
                    style: GoogleFonts.inter(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to chat - using admin chat for sponsor communication
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                         builder: (context) => AdminChatPage(userId: currentUserId ?? 'anonymous_admin'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline, size: 18),
                  label: const Text("CHAT NOW"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white12,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Show booth location info
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: AppColors.surface,
                        title: const Text('Booth Location', style: TextStyle(color: Colors.white)),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.location_on, color: AppColors.primary, size: 48),
                            const SizedBox(height: 16),
                            Text(
                              widget.sponsor.boothLocation ?? 'Nearby Main Stage, Hall A',
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Visit us at the event venue',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Close'),
                          ),
                        ],
                      ),
                    );
                  },
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text("SEE MAP"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLinks() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _socialIcon(FontAwesomeIcons.globe, widget.sponsor.websiteUrl),
            _socialIcon(FontAwesomeIcons.instagram, widget.sponsor.instagramUrl),
            _socialIcon(FontAwesomeIcons.linkedin, widget.sponsor.linkedinUrl),
            _socialIcon(FontAwesomeIcons.youtube, widget.sponsor.youtubeUrl),
          ],
        ),
        const SizedBox(height: 16),
        Text("Connect with us on social media", style: GoogleFonts.inter(fontSize: 12, color: Colors.white38)),
      ],
    );
  }

  Widget _socialIcon(IconData icon, String? url) {
    if (url == null || url.isEmpty) return const SizedBox.shrink();
    return IconButton(
      icon: FaIcon(icon, color: Colors.white70, size: 24),
      onPressed: () {}, // Open URL
    );
  }

  Widget _sectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 12),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _circularButton({required IconData icon, required VoidCallback onTap, Color iconColor = Colors.white}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: iconColor, size: 22),
      ),
    );
  }
}
