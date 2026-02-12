import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart'; // Ensure this package is available, used in other files
import '../../../../core/theme/app_colors.dart';

import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/data/models/schedule.dart'; // Correctly import Schedule
import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';
import 'package:tech_marathon_app/features/profile/presentation/providers/starred_sessions_provider.dart';
import 'package:tech_marathon_app/features/auth/data/auth_repository.dart';
import 'package:tech_marathon_app/features/home/data/speaker_interaction_repository.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/speaker_interactions_providers.dart';

class SpeakerDetailsScreen extends ConsumerStatefulWidget {
  final Speaker speaker;

  const SpeakerDetailsScreen({
    super.key,
    required this.speaker,
  });

  @override
  ConsumerState<SpeakerDetailsScreen> createState() => _SpeakerDetailsScreenState();
}

class _SpeakerDetailsScreenState extends ConsumerState<SpeakerDetailsScreen> {
  final TextEditingController _questionController = TextEditingController();
  final TextEditingController _feedbackController = TextEditingController();
  double _userRating = 0.0;

  @override
  void dispose() {
    _questionController.dispose();
    _feedbackController.dispose();
    super.dispose();
  }

  Future<void> _launchURL(String url) async {
    if (url.isEmpty) return;
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
       // Handle error silently or show snackbar
    }
  }

  void _showQuestionDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ask a Question', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 16),
            TextField(
              controller: _questionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Type your question for ${widget.speaker.name}...',
                hintStyle: TextStyle(color: AppColors.textDim),
                filled: true,
                fillColor: Colors.black12,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (_questionController.text.trim().isEmpty) return;
                  final user = ref.read(authStateProvider).value;
                  if (user != null) {
                    await ref.read(speakerInteractionRepositoryProvider).submitQuestion(
                      user.uid, 
                      widget.speaker.id, 
                      _questionController.text.trim()
                    );
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Question submitted!')));
                      _questionController.clear();
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Submit Question', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Rate this Speaker', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  return IconButton(
                    icon: Icon(
                      index < _userRating ? Icons.star_rounded : Icons.star_outline_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                    onPressed: () => setModalState(() => _userRating = index + 1.0),
                  );
                }),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _feedbackController,
                style: const TextStyle(color: Colors.white),
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: 'Optional feedback...',
                  hintStyle: TextStyle(color: AppColors.textDim),
                  filled: true,
                  fillColor: Colors.black12,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_userRating == 0.0) return;
                    final user = ref.read(authStateProvider).value;
                    if (user != null) {
                      await ref.read(speakerInteractionRepositoryProvider).submitRating(
                        user.uid, 
                        widget.speaker.id, 
                        _userRating,
                        _feedbackController.text.trim()
                      );
                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Rating submitted!')));
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final speaker = widget.speaker;
    final savedSpeakersAsync = ref.watch(savedSpeakerIdsProvider);
    final isSaved = savedSpeakersAsync.value?.contains(speaker.id) ?? false;
    final schedulesAsync = ref.watch(schedulesStreamProvider);
    final starredSessions = ref.watch(starredSessionsProvider);
    final user = ref.watch(authStateProvider).value;
    final allEventsAsync = ref.watch(allEventsStreamProvider);
    final eventName = allEventsAsync.asData?.value.cast<CodingEvent?>().firstWhere(
      (e) => e?.id == speaker.eventId,
      orElse: () => null,
    )?.name;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
             expandedHeight: 340, // Increased height to accommodate event name
             pinned: true,
             backgroundColor: AppColors.background,
             leading: CircleAvatar(
               backgroundColor: Colors.black26,
               child: IconButton(
                 icon: const Icon(Icons.arrow_back, color: Colors.white),
                 onPressed: () => Navigator.pop(context),
               ),
             ),
             actions: [
               IconButton(
                 icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_outline, color: isSaved ? AppColors.primary : Colors.white),
                 onPressed: () {
                   if (user != null) {
                     ref.read(speakerInteractionRepositoryProvider).toggleSaveSpeaker(user.uid, speaker.id, isSaved);
                   }
                 },
               ),
               IconButton(
                 icon: const Icon(Icons.share_outlined, color: Colors.white),
                 onPressed: () {
                   // Share functionality
                 },
               ),
             ],
             flexibleSpace: FlexibleSpaceBar(
               background: Stack(
                 fit: StackFit.expand,
                 children: [
                   if (speaker.imageUrl.isNotEmpty)
                     Image.network(
                       speaker.imageUrl,
                       fit: BoxFit.cover,
                       errorBuilder: (_,__,___) => Container(color: AppColors.surface, child: const Icon(Icons.person, size: 80, color: Colors.white24)),
                     )
                   else
                     Container(color: AppColors.surface, child: const Icon(Icons.person, size: 80, color: Colors.white24)),
                   Container(
                     decoration: BoxDecoration(
                       gradient: LinearGradient(
                         begin: Alignment.topCenter,
                         end: Alignment.bottomCenter,
                         colors: [
                           Colors.black12,
                           Colors.transparent, 
                           AppColors.background.withValues(alpha: 0.8), 
                           AppColors.background
                         ],
                         stops: const [0.0, 0.4, 0.8, 1.0],
                       ),
                     ),
                   ),
                   Positioned(
                     bottom: 20,
                     left: 24,
                     right: 24,
                     child: Column(
                       crossAxisAlignment: CrossAxisAlignment.start,
                       mainAxisSize: MainAxisSize.min,
                       children: [
                         if (eventName != null && eventName.isNotEmpty)
                           Container(
                             margin: const EdgeInsets.only(bottom: 8),
                             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                             decoration: BoxDecoration(
                               color: AppColors.primary,
                               borderRadius: BorderRadius.circular(20),
                             ),
                             child: Row(
                               mainAxisSize: MainAxisSize.min,
                               children: [
                                 const Icon(Icons.event, size: 14, color: Colors.black),
                                 const SizedBox(width: 6),
                                 Flexible(
                                   child: Text(
                                     eventName,
                                     style: GoogleFonts.inter(
                                        fontSize: 12, 
                                        fontWeight: FontWeight.bold, 
                                        color: Colors.black
                                     ),
                                     maxLines: 1,
                                     overflow: TextOverflow.ellipsis,
                                   ),
                                 ),
                               ],
                             ),
                           ),
                         Text(
                           speaker.name,
                           style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                         ),
                         const SizedBox(height: 4),
                         // Display Topic and Company prominently as Role is not editable in Admin
                         Text(
                           speaker.company.isNotEmpty 
                             ? (speaker.role.isNotEmpty ? '${speaker.role} • ${speaker.company}' : speaker.company)
                             : speaker.role,
                           style: GoogleFonts.inter(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w500),
                         ),
                         if (speaker.topic.isNotEmpty) ...[
                             const SizedBox(height: 12),
                             Wrap(
                               spacing: 8,
                               runSpacing: 8,
                               children: speaker.topic.split(',').map((tag) => Container(
                                 padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                 decoration: BoxDecoration(
                                   color: Colors.white.withValues(alpha: 0.1),
                                   borderRadius: BorderRadius.circular(20),
                                   border: Border.all(color: Colors.white24),
                                 ),
                                 child: Text(tag.trim(), style: const TextStyle(color: Colors.white70, fontSize: 10)),
                               )).toList(),
                             )
                         ]
                       ],
                     ),
                   )
                 ],
               ),
             ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Social Links
                  Row(
                    children: [
                       if (speaker.linkedinUrl.isNotEmpty) 
                         Padding(padding: const EdgeInsets.only(right: 16), child: _buildSocialIcon(Icons.link, () => _launchURL(speaker.linkedinUrl))), // Using generic link icon for LinkedIn
                       // Mock other socials since model doesn't have them yet, but UI is requested
                       _buildSocialIcon(Icons.public, () {}), // Website
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  // About
                  Text('ABOUT', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2, color: AppColors.textDim)),
                  const SizedBox(height: 12),
                  Text(
                    speaker.bio?.isNotEmpty == true ? speaker.bio! : 'No biography available.',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.white70, height: 1.6),
                  ),

                  const SizedBox(height: 32),

                  // Sessions
                  Text('SESSIONS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2, color: AppColors.textDim)),
                  const SizedBox(height: 12),
                  schedulesAsync.when(
                    data: (schedules) {
                      // Filter sessions where title or description contains speaker name (fuzzy match workaround)
                      // Or strictly if we had IDs.
                      final speakerSessions = schedules.where((s) => 
                        s.description.toLowerCase().contains(speaker.name.toLowerCase()) || 
                        s.title.toLowerCase().contains(speaker.name.toLowerCase())
                      ).toList();

                      if (speakerSessions.isEmpty) {
                        return Container(
                           width: double.infinity,
                           padding: const EdgeInsets.all(16),
                           decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                           child: const Text('No sessions listed for this speaker yet.', style: TextStyle(color: Colors.white38)),
                        );
                      }

                      return Column(
                        children: speakerSessions.map((session) => Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                                    child: Text(
                                      '${session.startTime.hour}:${session.startTime.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      session.title,
                                      style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(session.location, style: const TextStyle(color: AppColors.textDim, fontSize: 12)),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.notifications_outlined, size: 20, color: Colors.white60),
                                        onPressed: () {
                                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reminder set for this session')));
                                        },
                                      ),
                                      IconButton(
                                        icon: Icon(
                                          starredSessions.contains(session.id) ? Icons.star_rounded : Icons.star_border_rounded,
                                          size: 20,
                                          color: AppColors.primary
                                        ),
                                        onPressed: () {
                                            ref.read(starredSessionsProvider.notifier).toggleStar(session.id);
                                        },
                                      ),
                                    ],
                                  )
                                ],
                              )
                            ],
                          ),
                        )).toList(),
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (_,__) => const SizedBox.shrink(),
                  ),

                  const SizedBox(height: 32),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _showRatingDialog,
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.primary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Rate Speaker', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _showQuestionDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Ask Question', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 48),

                  // Suggested speakers
                  Text('SUGGESTED SPEAKERS', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 2, color: AppColors.textDim)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 140,
                    child: Consumer(
                      builder: (context, ref, _) {
                        final speakersAsync = ref.watch(mergedSpeakersProvider);
                        return speakersAsync.when(
                          data: (speakers) {
                            final others = speakers.where((s) => s.id != speaker.id).take(5).toList();
                            return ListView.separated(
                              scrollDirection: Axis.horizontal,
                              itemCount: others.length,
                              separatorBuilder: (_,__) => const SizedBox(width: 12),
                              itemBuilder: (ctx, idx) {
                                final s = others[idx];
                                return GestureDetector(
                                  onTap: () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => SpeakerDetailsScreen(speaker: s))),
                                  child: Container(
                                    width: 100,
                                    decoration: BoxDecoration(
                                      color: AppColors.surface,
                                      borderRadius: BorderRadius.circular(12), 
                                      border: Border.all(color: Colors.white12)
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        CircleAvatar(
                                          radius: 30,
                                          backgroundImage: s.imageUrl.isNotEmpty ? NetworkImage(s.imageUrl) : null,
                                          backgroundColor: Colors.white10,
                                          child: s.imageUrl.isEmpty ? const Icon(Icons.person, color: Colors.white24) : null,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(s.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                        Text(s.role, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.textDim, fontSize: 10)),
                                      ],
                                    ),
                                  ),
                                );
                              }
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_,__) => const SizedBox.shrink(),
                        );
                      }
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialIcon(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }
}
