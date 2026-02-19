import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:go_router/go_router.dart';

class LiveFeedScreen extends ConsumerWidget {
  const LiveFeedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentEventAsync = ref.watch(currentEventStreamProvider);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'LIVE FEED',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 18,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => context.pop(),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.backgroundGradient),
        child: SafeArea(
          child: currentEventAsync.when(
            data: (event) {
              if (event == null) return const Center(child: Text('No active event found', style: TextStyle(color: Colors.white38)));
              
              return StreamBuilder<List<LiveFeedItem>>(
                stream: ref.watch(adminRepositoryProvider).watchLiveFeedItems(event.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
                  final items = snapshot.data!;
                  
                  if (items.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sensors_off_rounded, size: 64, color: AppColors.primary.withValues(alpha: 0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'NO UPDATES YET',
                            style: GoogleFonts.outfit(color: Colors.white38, letterSpacing: 2, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildFeedItem(context, item).animate().fadeIn(delay: (index * 100).ms).slideY(begin: 0.1, end: 0);
                    },
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(child: Text('Error: $err', style: TextStyle(color: AppColors.error))),
          ),
        ),
      ),
    );
  }

  Widget _buildFeedItem(BuildContext context, LiveFeedItem item) {
    if (item.type == 'video') {
      return _buildVideoItem(context, item);
    } else if (item.type == 'template') {
      return _buildTemplateItem(context, item);
    } else {
      return _buildImageItem(context, item);
    }
  }

  Widget _buildVideoItem(BuildContext context, LiveFeedItem item) {
    return Container(
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                    ),
                    child: item.contentUrl != null 
                        ? Image.network(
                          item.contentUrl!, 
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.3),
                          colorBlendMode: BlendMode.darken,
                          loadingBuilder: (context, child, progress) => progress == null ? child : _buildImageLoading(),
                        ) 
                      : const Icon(Icons.videocam_rounded, size: 40, color: Colors.white12),
                  ),
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.codingRimPrimary.withValues(alpha: 0.3),
                      blurRadius: 20,
                      spreadRadius: 2,
                    )
                  ],
                ),
                child: IconButton(
                  icon: const Icon(Icons.play_circle_fill_rounded, size: 64, color: AppColors.codingRimPrimary),
                  onPressed: () async {
                    if (item.contentUrl != null) {
                      final uri = Uri.parse(item.contentUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri);
                      }
                    }
                  },
                ),
              ),
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.circle, color: Colors.redAccent, size: 6),
                      const SizedBox(width: 8),
                      Text(
                        'LIVE UPDATE',
                        style: GoogleFonts.outfit(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w900, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.templateData['title'] ?? 'Event Moment',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                if (item.templateData['caption'] != null && item.templateData['caption'].isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    item.templateData['caption'],
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, color: Colors.white24, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Tap to play full video',
                          style: GoogleFonts.inter(color: Colors.white24, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: AppColors.codingRimPrimary, size: 20),
                      onPressed: () => _downloadFile(item.contentUrl),
                      tooltip: 'Download Video',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageItem(BuildContext context, LiveFeedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          if (item.contentUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(
                item.contentUrl!, 
                fit: BoxFit.cover,
                loadingBuilder: (context, child, progress) => progress == null ? child : _buildImageLoading(),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    item.templateData['title'] ?? 'LATEST UPDATE',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.download_rounded, color: AppColors.codingRimPrimary, size: 20),
                  onPressed: () => _downloadFile(item.contentUrl),
                  tooltip: 'Download Image',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateItem(BuildContext context, LiveFeedItem item) {
    // Check for new categorized image uploads first
    final category = item.templateData['category'];
    if (category != null) {
      return _buildCategorizedImage(item, category);
    }

    switch (item.templateType) {
      case 'certificate': return _buildCertificateTemplate(item);
      case 'guest': return _buildGuestTemplate(item);
      case 'invite': return _buildInviteTemplate(item);
      case 'sponsor': return _buildSponsorTemplate(item);
      case 'intro': return _buildIntroTemplate(item);
      default: return _buildImageItem(context, item);
    }
  }

  Widget _buildCategorizedImage(LiveFeedItem item, String category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Badge Overlay
          Stack(
            children: [
              if (item.contentUrl != null)
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                  child: Image.network(
                    item.contentUrl!, 
                    width: double.infinity, 
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) => progress == null ? child : _buildImageLoading(),
                  ),
                ),
            ],
          ),
          // Content Information
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.codingRimPrimary, Color(0xFFD4AF37)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        category.toUpperCase(),
                        style: GoogleFonts.outfit(
                          color: Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.download_rounded, color: AppColors.codingRimPrimary, size: 20),
                      onPressed: () => _downloadFile(item.contentUrl),
                      tooltip: 'Download',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (item.templateData['name'] != null && item.templateData['name'].isNotEmpty) ...[
                  Text(
                    item.templateData['name'],
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                ],
                if (item.templateData['title'] != null && item.templateData['title'].isNotEmpty) ...[
                  Text(
                    item.templateData['title'],
                    style: GoogleFonts.outfit(color: AppColors.codingRimPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                ],
                if (item.templateData['message'] != null && item.templateData['message'].isNotEmpty)
                  Text(
                    item.templateData['message'],
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
                if (item.templateData['caption'] != null && item.templateData['caption'].isNotEmpty)
                  Text(
                    item.templateData['caption'],
                    style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCertificateTemplate(LiveFeedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.codingRimPrimary, Color(0xFFD4AF37)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: AppColors.codingRimPrimary.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, 10))],
      ),
      child: AspectRatio(
        aspectRatio: 1,
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              const Icon(Icons.workspace_premium_rounded, size: 64, color: Colors.black),
              const SizedBox(height: 24),
              Text(
                item.templateData['title'] ?? 'CERTIFICATE OF APPRECIATION',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 4),
              ),
              const Spacer(),
              Text(
                item.templateData['name'] ?? 'Recipient Name',
                style: GoogleFonts.outfit(color: Colors.black, fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Text(
                item.templateData['message'] ?? 'Successfully completed the challenge',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.black87, fontSize: 14),
              ),
              const Spacer(),
              const Divider(color: Colors.black26),
              const SizedBox(height: 12),
              const Text('OFFICIAL EVENT RECOGNITION', style: TextStyle(color: Colors.black38, fontSize: 8, letterSpacing: 2, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuestTemplate(LiveFeedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.5,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                image: item.contentUrl != null ? DecorationImage(image: NetworkImage(item.contentUrl!), fit: BoxFit.cover) : null,
              ),
              child: item.contentUrl == null ? const Icon(Icons.person_rounded, size: 60, color: Colors.white10) : null,
            ),
          ),
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'CHIEF GUEST',
                  style: GoogleFonts.outfit(color: AppColors.codingRimPrimary, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  item.templateData['name'] ?? 'Guest Name',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                Text(
                  item.templateData['message'] ?? 'Special Appearance',
                  style: GoogleFonts.inter(color: Colors.white54, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInviteTemplate(LiveFeedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.codingRimPrimary.withValues(alpha: 0.2), width: 2),
      ),
      child: Column(
        children: [
          const Icon(Icons.mail_rounded, color: AppColors.codingRimPrimary, size: 48),
          const SizedBox(height: 24),
          Text(
            item.templateData['title'] ?? 'YOU ARE INVITED',
            style: GoogleFonts.outfit(color: AppColors.codingRimPrimary, fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 4),
          ),
          const SizedBox(height: 32),
          Text(
            'TECH MARATHON 2026',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(border: Border.all(color: Colors.white10)),
            child: Text(
              item.templateData['message'] ?? 'Grand Ballroom, 10:00 AM',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSponsorTemplate(LiveFeedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Text(
            'POWERED BY',
            style: GoogleFonts.outfit(color: Colors.black26, fontWeight: FontWeight.w900, fontSize: 10, letterSpacing: 4),
          ),
          const SizedBox(height: 24),
          if (item.contentUrl != null)
            Image.network(
              item.contentUrl!, 
              height: 100, 
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) => progress == null ? child : _buildImageLoading(),
            )
          else
            const Icon(Icons.business_rounded, size: 80, color: Colors.black12),
          const SizedBox(height: 24),
          Text(
            item.templateData['name'] ?? 'Company Name',
            style: GoogleFonts.outfit(color: Colors.black, fontSize: 22, fontWeight: FontWeight.bold),
          ),
          Text(
            item.templateData['message'] ?? 'Official Partner',
            style: GoogleFonts.inter(color: Colors.black45, fontSize: 13),
          ),
          const SizedBox(height: 24),
          const Text(
            'THANK YOU FOR YOUR PARTNERSHIP',
            style: TextStyle(color: AppColors.codingRimPrimary, fontSize: 9, fontWeight: FontWeight.w900, letterSpacing: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroTemplate(LiveFeedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        image: item.contentUrl != null ? DecorationImage(image: NetworkImage(item.contentUrl!), fit: BoxFit.cover) : null,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  color: AppColors.codingRimPrimary,
                  child: const Icon(Icons.bolt, size: 16, color: Colors.black),
                ),
                const SizedBox(height: 16),
                Text(
                  item.templateData['title'] ?? 'EVENT HIGHLIGHTS',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.1),
                ),
                const SizedBox(height: 8),
                Text(
                  item.templateData['message'] ?? 'Key updates from the platform',
                  style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageLoading() {
    return Container(
      height: 200,
      width: double.infinity,
      color: Colors.white.withValues(alpha: 0.05),
      child: const Center(
        child: CircularProgressIndicator(
          color: AppColors.codingRimPrimary,
          strokeWidth: 2,
        ),
      ),
    );
  }

  Future<void> _downloadFile(String? url) async {
    if (url == null) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
