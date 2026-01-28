import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/widgets/auth_widgets.dart';
import '../../../home/domain/event_models.dart';
import '../../data/admin_repository.dart';
import '../providers/optimistic_state_provider.dart'; // Import optimistic state
import '../../../chat/data/chat_repository.dart';
import '../../../../features/auth/data/user_repository.dart';
import '../../../../data/models/schedule.dart' as new_schedule; // Alias for Schedule
// Removed unused mock data import (non-existent package path)
// import 'package:tech_marathon_app/features/events/data/mock_data.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../home/presentation/providers/branding_provider.dart';
 
class AdminDashboardScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const AdminDashboardScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late int _currentTab; // 0: Overview, 1: Events, 2: Members, 3: Speakers, 4: Sponsors, 5: Schedules, 6: Chat, 7: Branding

  // Branding state
  XFile? _brandingLogo;
  Uint8List? _brandingLogoBytes;
  bool _isSavingBranding = false;
  final TextEditingController _brandingNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  void dispose() {
    _brandingNameController.dispose();
    super.dispose();
  }

  // Gold + Black Theme Constants
  final Color _gold = const Color(0xFFFFD700);
  final Color _darkBg = const Color(0xFF121212); // Deep Black/Grey

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Pure Black background
      body: Stack(
        children: [
          // Background subtle gradient
          Positioned.fill(
             child: Container(
               decoration: BoxDecoration(
                 gradient: LinearGradient(
                   begin: Alignment.topLeft,
                   end: Alignment.bottomRight,
                   colors: [
                     Colors.black,
                     const Color(0xFF1A1A1A),
                     _gold.withOpacity(0.05), // Subtle gold hint
                   ],
                 ),
               ),
             ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                _buildTabSwitcher(),
                Expanded(
                  child: _buildCurrentSection(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        border: Border(bottom: BorderSide(color: _gold.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            ),
          ),
          
          Expanded(
            child: Center(
              child: ref.watch(brandingProvider).when(
                data: (branding) => Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        branding.companyName.toUpperCase(),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 3,
                          color: _gold,
                        ),
                      ),
                    ),
                    if (branding.companyLogoUrl != null && branding.companyLogoUrl!.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      CachedNetworkImage(
                        imageUrl: branding.companyLogoUrl!,
                        height: 28, // Slightly larger for Admin Panel
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700))),
                        errorWidget: (_, __, ___) => const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
                loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700))),
                error: (_, __) => Text(
                  'ADMIN PANEL',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 3,
                    color: _gold,
                  ),
                ),
              ).animate().fadeIn(duration: 600.ms),
            ),
          ),
          
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconButton(Icons.notifications_none_rounded, () {}),
              const SizedBox(width: 4), // Reduced spacing
              GestureDetector(
                onTap: () => _showAdminProfile(),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold, width: 1.5),
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.black,
                    child: Icon(Icons.person, size: 18, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
      child: Row(
        children: [
          _tabItem(0, 'Overview'),
          _tabItem(1, 'Events'),
          _tabItem(2, 'Members'),
          _tabItem(3, 'Speakers'),
          _tabItem(4, 'Sponsors'),
          _tabItem(5, 'Schedules'),
          _tabItem(6, 'Chat'),
          _tabItem(7, 'Branding'),
        ],
      ),
    );
  }

  Widget _tabItem(int index, String label) {
    bool isSelected = _currentTab == index;
    return GestureDetector(
      onTap: () => setState(() => _currentTab = index),
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _gold : Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? _gold : Colors.white.withOpacity(0.1),
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: _gold.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))] 
            : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
            fontSize: 13,
            letterSpacing: 0.5,
          ),
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: 0.2, end: 0);
  }

  Widget _buildCurrentSection() {
    switch (_currentTab) {
      case 0: return _buildOverview();
      case 1: return _buildEventsSection();
      case 2: return _buildMembersSection();
      case 3: return _buildSpeakersSection();
      case 4: return _buildSponsorsSection();
      case 5: return _buildSchedulesSection();
      case 6: return _buildChatSection();
      case 7: return _buildBrandingSection();
      default: return _buildOverview();
    }
  }

  void _showAdminProfile() {
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Admin Profile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.codingRimPrimary,
              child: Icon(Icons.person, size: 30, color: Colors.black),
            ),
            const SizedBox(height: 16),
            Text(user?.displayName ?? 'Admin', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 8),
            Text(user?.email ?? 'No Email', style: const TextStyle(color: Colors.white70)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  // --- 1. OVERVIEW: CONTROL CENTER MODULES ---
  Widget _buildOverview() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      children: [
         // Module 1: Ticket Sales Analytics (Revenue Hero Card)
        _buildHeroModule(),
        const SizedBox(height: 24),
        
        // Module 2: Live Attendance Tracker
        _buildLiveAttendanceModule(),
        const SizedBox(height: 24),

        // Module 3: Event Timeline Manager
        _buildTimelineModule(),
        const SizedBox(height: 24),

        // Module 4: System Actions Grid
        _buildSystemActionsModule(),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeroModule() {
    final adminRepo = ref.watch(adminRepositoryProvider);
    return StreamBuilder<List<CodingEvent>>(
      stream: adminRepo.watchEvents(),
      builder: (context, snapshot) {
        final totalEvents = snapshot.data?.length ?? 0;
        final revenue = totalEvents * 1500; // Mock revenue

        return _GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('TICKET SALES ANALYTICS', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 12, letterSpacing: 1.5, fontWeight: FontWeight.bold)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: const Color(0xFF00FF94).withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Text('LIVE +12%', style: TextStyle(color: Color(0xFF00FF94), fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('₹$revenue', style: GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.bold, color: _gold)),
                  const SizedBox(width: 8),
                  const Padding(
                    padding: EdgeInsets.only(bottom: 6),
                    child: Text('Total Revenue', style: TextStyle(color: Colors.white38, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _statBadge(Icons.confirmation_number_outlined, '$totalEvents Events', Colors.blueAccent),
                  const SizedBox(width: 12),
                  _statBadge(Icons.airplane_ticket_outlined, 'Sold Out', const Color(0xFF00FF94)),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _statBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLiveAttendanceModule() {
    final userRepo = ref.watch(userRepositoryProvider); // Use UserRepository for presence
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _moduleHeader('Live Attendance', Icons.sensors, const Color(0xFF00FF94)), // Green for active
        const SizedBox(height: 12),
        StreamBuilder<int>(
          stream: userRepo.watchOnlineUsersCount(),
          initialData: 0,
          builder: (context, snapshot) {
             final onlineCount = snapshot.data ?? 0;
             return _GlassCard(
               child: Column(
                 children: [
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Column(
                         crossAxisAlignment: CrossAxisAlignment.start,
                         children: [
                           Text('$onlineCount', style: GoogleFonts.outfit(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                           const Text('Online Now', style: TextStyle(color: Colors.white54, fontSize: 12)),
                         ],
                       ),
                       SizedBox(
                         height: 40,
                         width: 120,
                         child: Stack(
                           children: List.generate(3, (index) {
                             return Positioned(
                               left: index * 24.0,
                               child: CircleAvatar(
                                 radius: 18,
                                 backgroundColor: Colors.black,
                                 child: CircleAvatar(
                                   radius: 16,
                                   backgroundColor: Colors.white10,
                                   child: const Icon(Icons.person, color: Colors.white54, size: 16),
                                 ),
                               ),
                             );
                           }),
                         ),
                       ),
                     ],
                   ),
                   const SizedBox(height: 16),
                   ClipRRect(
                     borderRadius: BorderRadius.circular(4),
                     child: LinearProgressIndicator(
                       value: (onlineCount / 100).clamp(0.0, 1.0), 
                       backgroundColor: Colors.white10,
                       valueColor: AlwaysStoppedAnimation(_gold),
                       minHeight: 4,
                     ),
                   ),
                   const SizedBox(height: 8),
                   const Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Traffic', style: TextStyle(color: Colors.white38, fontSize: 10)),
                       Text('Target: 100', style: TextStyle(color: Colors.white38, fontSize: 10)),
                     ],
                   ),
                 ],
               ),
             );
          }
        ),
      ],
    );
  }

  Widget _buildTimelineModule() {
    final adminRepo = ref.watch(adminRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _moduleHeader('Timeline Manager', Icons.schedule, _gold),
        const SizedBox(height: 12),
        StreamBuilder<List<CodingEvent>>(
          stream: adminRepo.watchEvents(),
          builder: (context, snapshot) {
            final events = snapshot.data ?? [];
            if (events.isEmpty) return const Text('No active events', style: TextStyle(color: Colors.white38));
            
            return SizedBox(
              height: 140, // Height for horizontal cards
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 16),
                    child: _GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: _gold.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: Text(_formatDate(event.date), style: TextStyle(color: _gold, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                              const Spacer(),
                              const Icon(Icons.more_horiz, color: Colors.white38, size: 16),
                            ],
                          ),
                          const Spacer(),
                          Text(event.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on_outlined, color: Colors.white54, size: 12),
                              const SizedBox(width: 4),
                              Expanded(child: Text(event.location, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          }
        ),
      ],
    );
  }



  Widget _actionBtn(String label, IconData icon, Color color, {bool isDarkText = false, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withOpacity(isDarkText ? 1.0 : 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withOpacity(isDarkText ? 0.0 : 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isDarkText ? Colors.black : color, size: 24),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isDarkText ? Colors.black : color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _moduleHeader(String title, IconData icon, Color accent) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} • ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // --- 2. EVENTS SECTION (Real-time CRUD UI) ---
  Widget _buildEventsSection() {
    final adminRepo = ref.watch(adminRepositoryProvider);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Manage Events'),
              ElevatedButton.icon(
                onPressed: () => _showEventDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.codingRimPrimary,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<CodingEvent>>(
              stream: adminRepo.watchEvents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.isEmpty) return const Center(child: Text('No events found', style: TextStyle(color: Colors.white38)));
                
                // Merge Firestore data (removed mock seed usage)
                final firestoreEvents = snapshot.data ?? [];
                final allEvents = [...firestoreEvents];

                if (allEvents.isEmpty) return const Center(child: Text('No events found', style: TextStyle(color: Colors.white38)));
                
                return ListView.builder(
                  itemCount: allEvents.length,
                  itemBuilder: (context, index) {
                    final event = allEvents[index];
                    return _eventItem(event);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _eventItem(CodingEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            padding: event.imageUrl.isEmpty ? const EdgeInsets.all(10) : EdgeInsets.zero,
            decoration: BoxDecoration(
              color: Colors.white12,
              borderRadius: BorderRadius.circular(12),
              image: event.imageUrl.isNotEmpty
                ? DecorationImage(
                    image: NetworkImage(event.imageUrl),
                    fit: BoxFit.cover,
                  )
                : null,
            ),
            child: event.imageUrl.isEmpty 
              ? const Icon(Icons.event_note, color: AppColors.codingRimPrimary) 
              : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(event.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(event.location, style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white38),
            itemBuilder: (context) => [
              PopupMenuItem(child: const Text('Edit'), onTap: () => Future.delayed(Duration.zero, () => _showEventDialog(event: event))),
              PopupMenuItem(child: const Text('Delete', style: TextStyle(color: Colors.red)), onTap: () => ref.read(adminRepositoryProvider).deleteEvent(event.id)),
            ],
          ),
        ],
      ),
    );
  }

  void _showEventDialog({CodingEvent? event}) {
    final titleController = TextEditingController(text: event?.name);
    final locationController = TextEditingController(text: event?.location);
    final categoryController = TextEditingController(text: event?.category);
    final descController = TextEditingController(text: event?.description);
    
    XFile? selectedImage;
    String? currentImageUrl = event?.imageUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(event == null ? 'New Event' : 'Edit Event', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (image != null) {
                      setState(() => selectedImage = image);
                    }
                  },
                  child: Container(
                    height: 150,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                      image: selectedImage != null 
                        ? DecorationImage(
                            image: kIsWeb 
                                ? NetworkImage(selectedImage!.path) 
                                : FileImage(File(selectedImage!.path)) as ImageProvider,
                            fit: BoxFit.cover
                          )
                        : (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(currentImageUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: selectedImage == null && (currentImageUrl == null || currentImageUrl!.isEmpty)
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.add_photo_alternate_rounded, color: Colors.white54, size: 40),
                            const SizedBox(height: 8),
                            const Text('Add Cover Image', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        )
                      : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Event Title'), style: const TextStyle(color: Colors.white)),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location'), style: const TextStyle(color: Colors.white)),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category'), style: const TextStyle(color: Colors.white)),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), style: const TextStyle(color: Colors.white), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: () {
                 if (titleController.text.isEmpty) return;
                 
                 // Create optimistic event with current/placeholder image
                 final optimisticEvent = CodingEvent(
                   id: event?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
                   name: titleController.text,
                   location: locationController.text,
                   category: categoryController.text,
                   description: descController.text,
                   date: event?.date ?? DateTime.now(),
                   speakerIds: event?.speakerIds ?? [],
                   imageUrl: currentImageUrl ?? 'https://images.unsplash.com/photo-1540575467063-178a50c2df87',
                 );

                 // INSTANT UPDATE: Add to optimistic state immediately
                 if (event == null) {
                   ref.read(optimisticEventsProvider.notifier).addEvent(optimisticEvent);
                 } else {
                   ref.read(optimisticEventsProvider.notifier).updateEvent(optimisticEvent);
                 }

                 // INSTANT CLOSE: Dialog closes immediately
                 Navigator.pop(context);

                 // BACKGROUND SYNC: Process image upload and backend save
                 ref.read(adminRepositoryProvider).saveEvent(
                   optimisticEvent,
                   isNew: event == null,
                   imageFile: selectedImage,
                 );

                 // Remove from optimistic state after a delay (Firestore will take over)
                 Future.delayed(const Duration(seconds: 3), () {
                   ref.read(optimisticEventsProvider.notifier).removeEvent(optimisticEvent.id);
                 });
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 3. MEMBERS SECTION (Real-time) ---
  Widget _buildMembersSection() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        _sectionTitle('Joined Members'),
        const SizedBox(height: 20),
        StreamBuilder<List<Participant>>(
          stream: ref.watch(userRepositoryProvider).getRealTimeMembers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
            if (snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    Icon(Icons.people_outline, size: 48, color: Colors.white.withOpacity(0.1)),
                    const SizedBox(height: 16),
                    Text('No one has joined yet', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                  ],
                ),
              );
            }
            
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.length,
              separatorBuilder: (_, __) => Divider(color: Colors.white.withOpacity(0.05)),
              itemBuilder: (context, index) {
                final member = snapshot.data![index];
                return _memberItem(member);
              },
            );
          },
        ),
      ],
    );
  }



  // --- 4. SPEAKERS SECTION ---
  String? _selectedSpeakerEventId; // Event ID state for speakers
  String? _selectedSponsorEventId; // Event ID state for sponsors

  Widget _buildSpeakersSection() {
    final adminRepo = ref.watch(adminRepositoryProvider);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Manage Speakers'),
              ElevatedButton.icon(
                onPressed: () => _showSpeakerDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Speaker'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Speaker>>(
              stream: adminRepo.watchAllSpeakers(), // Use global stream
              builder: (context, snapshot) {
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
                 
                 final allSpeakers = snapshot.data!;
                 if (allSpeakers.isEmpty) {
                    return Center(
                      child: Text('No speakers added yet', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                    );
                 }
                 
                 return ListView.builder(
                   itemCount: allSpeakers.length,
                   itemBuilder: (context, index) {
                      final speaker = allSpeakers[index];
                      return _speakerItem(speaker);
                   },
                 );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _speakerItem(Speaker speaker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundImage: speaker.photoUrl.isNotEmpty ? NetworkImage(speaker.photoUrl) : null,
            backgroundColor: Colors.white12,
            child: speaker.photoUrl.isEmpty ? const Icon(Icons.mic, color: Colors.white) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(speaker.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('${speaker.topic} • ${speaker.company}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white38),
            itemBuilder: (context) => [
              PopupMenuItem(child: const Text('Edit'), onTap: () => Future.delayed(Duration.zero, () => _showSpeakerDialog(speaker: speaker))),
              PopupMenuItem(
                child: const Text('Delete / Unlink', style: TextStyle(color: Colors.red)),
                onTap: () => Future.delayed(Duration.zero, () {
                   // For common list, delete also deletes global speaker
                   ref.read(adminRepositoryProvider).deleteSpeaker('', speaker.id); 
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showSpeakerDialog({Speaker? speaker, String? eventId}) {
    final nameController = TextEditingController(text: speaker?.name);
    final topicController = TextEditingController(text: speaker?.topic);
    final companyController = TextEditingController(text: speaker?.company);
    final bioController = TextEditingController(text: speaker?.bio);
    
    // Use local state for event selection in dialog
    String? selectedEventId = eventId;
    
    XFile? selectedImage;
    String? currentPhotoUrl = speaker?.photoUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(speaker == null ? 'Add Speaker' : 'Edit Speaker', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (image != null) {
                      setState(() => selectedImage = image);
                    }
                  },
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(50),
                      image: selectedImage != null 
                        ? DecorationImage(
                            image: kIsWeb 
                                ? NetworkImage(selectedImage!.path) 
                                : FileImage(File(selectedImage!.path)) as ImageProvider,
                            fit: BoxFit.cover
                          )
                        : (currentPhotoUrl != null && currentPhotoUrl!.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(currentPhotoUrl!), fit: BoxFit.cover)
                          : null,
                    ),
                    child: selectedImage == null && (currentPhotoUrl == null || currentPhotoUrl!.isEmpty)
                      ? const Icon(Icons.add_a_photo, color: Colors.white54, size: 30)
                      : null,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Event Selection inside dialog
                StreamBuilder<List<CodingEvent>>(
                  stream: ref.watch(adminRepositoryProvider).watchEvents(),
                  builder: (context, snapshot) {
                    final events = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      value: selectedEventId,
                      dropdownColor: const Color(0xFF1E1E1E),
                      decoration: const InputDecoration(labelText: 'Link to Event (Optional)'),
                      style: const TextStyle(color: Colors.white),
                      items: events.map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.name, style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (val) => setState(() => selectedEventId = val),
                    );
                  }
                ),
                
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), style: const TextStyle(color: Colors.white)),
                TextField(controller: topicController, decoration: const InputDecoration(labelText: 'Topic'), style: const TextStyle(color: Colors.white)),
                TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company'), style: const TextStyle(color: Colors.white)),
                TextField(controller: bioController, decoration: const InputDecoration(labelText: 'Bio'), style: const TextStyle(color: Colors.white), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.trim().isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
                   return;
                }
                
                final optimisticSpeaker = Speaker(
                  id: speaker?.id ?? '', 
                  name: nameController.text.trim(),
                  topic: topicController.text.trim(),
                  company: companyController.text.trim(),
                  imageUrl: currentPhotoUrl ?? '',
                  bio: bioController.text.trim(),
                  role: speaker?.role ?? '',
                  linkedinUrl: speaker?.linkedinUrl ?? '',
                );

                Navigator.pop(context);
                
                ref.read(adminRepositoryProvider).saveSpeaker(
                  optimisticSpeaker,
                  eventId: selectedEventId,
                  isNew: speaker == null,
                  imageFile: selectedImage,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. SPONSORS SECTION ---
  Widget _buildSponsorsSection() {
    final adminRepo = ref.watch(adminRepositoryProvider);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Manage Sponsors'),
              ElevatedButton.icon(
                onPressed: () => _showSponsorDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Sponsor'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Sponsor>>(
              stream: adminRepo.watchAllSponsors(),
              builder: (context, snapshot) {
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700)));
                 
                 final allSponsors = snapshot.data!;
                 if (allSponsors.isEmpty) {
                    return Center(
                      child: Text('No sponsors added yet', style: TextStyle(color: Colors.white.withOpacity(0.3))),
                    );
                 }

                 return ListView.builder(
                   itemCount: allSponsors.length,
                   itemBuilder: (context, index) {
                     final sponsor = allSponsors[index];
                     return _sponsorItem(sponsor);
                   }
                 );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sponsorItem(Sponsor sponsor) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                image: sponsor.logoUrl.isNotEmpty ? DecorationImage(image: NetworkImage(sponsor.logoUrl), fit: BoxFit.contain) : null,
              ),
              child: sponsor.logoUrl.isEmpty ? const Icon(Icons.business, color: Colors.black) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(sponsor.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  Text('${sponsor.company} • ${sponsor.jobPosition}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blueAccent),
              onPressed: () => _showSponsorDialog(sponsor: sponsor),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => ref.read(adminRepositoryProvider).deleteSponsor('', sponsor.id),
            ),
          ],
        ),
      );
    }

  void _showSponsorDialog({Sponsor? sponsor, String? eventId}) {
    final nameController = TextEditingController(text: sponsor?.name);
    final companyController = TextEditingController(text: sponsor?.company);
    final roleController = TextEditingController(text: sponsor?.jobPosition);
    
    // Use local state for event selection in dialog
    String? selectedEventId = eventId;
    
    XFile? selectedImage;
    String? currentLogoUrl = sponsor?.logoUrl;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(sponsor == null ? 'Add Sponsor' : 'Edit Sponsor', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (image != null) setState(() => selectedImage = image);
                  },
                  child: Container(
                    height: 100,
                    width: 100,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                      image: selectedImage != null 
                        ? DecorationImage(
                            image: kIsWeb 
                                ? NetworkImage(selectedImage!.path) 
                                : FileImage(File(selectedImage!.path)) as ImageProvider,
                            fit: BoxFit.contain
                          )
                        : (currentLogoUrl != null && currentLogoUrl!.isNotEmpty)
                          ? DecorationImage(image: NetworkImage(currentLogoUrl!), fit: BoxFit.contain)
                          : null,
                    ),
                    child: selectedImage == null && (currentLogoUrl == null || currentLogoUrl!.isEmpty)
                      ? const Icon(Icons.add_photo_alternate, color: Colors.white54, size: 30)
                      : null,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Event Selection inside dialog
                StreamBuilder<List<CodingEvent>>(
                  stream: ref.watch(adminRepositoryProvider).watchEvents(),
                  builder: (context, snapshot) {
                    final events = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      value: selectedEventId,
                      dropdownColor: const Color(0xFF1E1E1E),
                      decoration: const InputDecoration(labelText: 'Link to Event (Optional)'),
                      style: const TextStyle(color: Colors.white),
                      items: events.map((e) => DropdownMenuItem(
                        value: e.id,
                        child: Text(e.name, style: const TextStyle(color: Colors.white)),
                      )).toList(),
                      onChanged: (val) => setState(() => selectedEventId = val),
                    );
                  }
                ),

                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), style: const TextStyle(color: Colors.white)),
                TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company'), style: const TextStyle(color: Colors.white)),
                TextField(controller: roleController, decoration: const InputDecoration(labelText: 'Role / Position'), style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: () {
                 if (nameController.text.trim().isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
                   return;
                }
                
                final optimisticSponsor = Sponsor(
                  id: sponsor?.id ?? '', 
                  name: nameController.text.trim(),
                  company: companyController.text.trim(),
                  jobPosition: roleController.text.trim(),
                  tier: sponsor?.tier ?? 'Gold',
                  logoUrl: currentLogoUrl ?? '',
                  websiteUrl: sponsor?.websiteUrl ?? '',
                );

                Navigator.pop(context);
                
                ref.read(adminRepositoryProvider).saveSponsor(
                  optimisticSponsor,
                  eventId: selectedEventId,
                  isNew: sponsor == null,
                  imageFile: selectedImage,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. SCHEDULES SECTION ---
  Widget _buildSchedulesSection() {
    final adminRepo = ref.watch(adminRepositoryProvider);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Manage Schedules'),
              ElevatedButton.icon(
                onPressed: () => _showScheduleDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Schedule'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _gold,
                  foregroundColor: Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<CodingEvent>>(
              stream: adminRepo.watchEvents(),
              builder: (context, eventSnapshot) {
                final eventMap = {
                   for (var e in eventSnapshot.data ?? []) e.id: e.name
                };

                return StreamBuilder<List<new_schedule.Schedule>>(
                  stream: adminRepo.watchAllSchedules(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                    if (snapshot.data!.isEmpty) return const Center(child: Text('No schedules yet', style: TextStyle(color: Colors.white38)));
                    
                    final allSchedules = snapshot.data!;

                    return ListView.builder(
                      itemCount: allSchedules.length,
                      itemBuilder: (context, index) {
                         final schedule = allSchedules[index];
                         final eventName = eventMap[schedule.eventId] ?? 'Unknown Event';
                         return _scheduleItem(schedule, eventName);
                      }
                    );
                  },
                );
              }
            ),
          ),
        ],
      ),
    );
  }

  Widget _scheduleItem(new_schedule.Schedule schedule, String eventName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.schedule, color: Color(0xFFFFD700)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _gold.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(eventName, style: TextStyle(color: _gold, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white38),
            itemBuilder: (context) => [
              PopupMenuItem(child: const Text('Edit'), onTap: () => Future.delayed(Duration.zero, () => _showScheduleDialog(schedule: schedule))),
              PopupMenuItem(
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () => Future.delayed(Duration.zero, () {
                   ref.read(adminRepositoryProvider).deleteSchedule(schedule.eventId, schedule.id);
                }),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog({new_schedule.Schedule? schedule}) {
    final titleController = TextEditingController(text: schedule?.title);
    final descController = TextEditingController(text: schedule?.description);
    final locationController = TextEditingController(text: schedule?.location);
    
    DateTime startTime = schedule?.startTime ?? DateTime.now();
    DateTime endTime = schedule?.endTime ?? DateTime.now().add(const Duration(hours: 1));
    
    String? selectedEventId = schedule?.eventId;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(schedule == null ? 'Add Schedule' : 'Edit Schedule', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                  StreamBuilder<List<CodingEvent>>(
                    stream: ref.read(adminRepositoryProvider).watchEvents(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const SizedBox.shrink();
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: selectedEventId,
                            hint: const Text('Select Event', style: TextStyle(color: Colors.white54)),
                            dropdownColor: AppColors.surface,
                            isExpanded: true,
                            items: snapshot.data!.map((e) => DropdownMenuItem(
                              value: e.id,
                              child: Text(e.name, style: const TextStyle(color: Colors.white)),
                            )).toList(),
                            onChanged: (val) => setState(() => selectedEventId = val),
                          ),
                        ),
                      );
                    }
                  ),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title'), style: const TextStyle(color: Colors.white)),
                TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), style: const TextStyle(color: Colors.white), maxLines: 2),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location'), style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 16),
                
                // Time Pickers
                ListTile(
                  title: const Text('Start Time', style: TextStyle(color: Colors.white)),
                  trailing: Text(_formatDate(startTime), style: const TextStyle(color: Color(0xFFFFD700))),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: startTime, firstDate: DateTime(2024), lastDate: DateTime(2030));
                    if (date != null) {
                      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(startTime));
                      if (time != null) {
                        setState(() => startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                      }
                    }
                  },
                ),
                ListTile(
                  title: const Text('End Time', style: TextStyle(color: Colors.white)),
                  trailing: Text(_formatDate(endTime), style: const TextStyle(color: Color(0xFFFFD700))),
                  onTap: () async {
                    final date = await showDatePicker(context: context, initialDate: endTime, firstDate: DateTime(2024), lastDate: DateTime(2030));
                    if (date != null) {
                      final time = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(endTime));
                      if (time != null) {
                        setState(() => endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute));
                      }
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                 if (titleController.text.isEmpty) return;
                 
                 final eventId = selectedEventId;
                 if (eventId == null || eventId.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an event')));
                   return;
                 }

                 final newSchedule = new_schedule.Schedule(
                   id: schedule?.id ?? '',
                   eventId: eventId,
                   day: 1, // Default to day 1 for now
                   title: titleController.text,
                   description: descController.text,
                   startTime: startTime,
                   endTime: endTime,
                   location: locationController.text,
                   mediaUrls: [],
                 );
                 
                 Navigator.pop(context);

                 ref.read(adminRepositoryProvider).saveSchedule(newSchedule, isNew: schedule == null);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. CHAT SECTION (Real-time Admin List View) ---
  Widget _buildChatSection() {
    final chatRepo = ref.watch(adminChatRepositoryProvider);
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionTitle('User Inquiries'),
          const SizedBox(height: 20),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chatRepo.watchAllChats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.isEmpty) return const Center(child: Text('No active chats', style: TextStyle(color: Colors.white38)));
                
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final chat = snapshot.data![index];
                    return _chatThreadItem(chat);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatThreadItem(Map<String, dynamic> chat) {
    final bool hasUnread = chat['unreadByAdmin'] ?? false;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(hasUnread ? 0.08 : 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasUnread ? _gold.withOpacity(0.3) : Colors.transparent),
      ),
      child: ListTile(
        onTap: () => _openAdminChatRoom(chat['userId'], chat['userName'] ?? 'User'),
        leading: CircleAvatar(
          backgroundColor: Colors.white12,
          child: Text(chat['userName']?[0] ?? 'U', style: const TextStyle(color: Colors.white)),
        ),
        title: Text(chat['userName'] ?? 'User', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        subtitle: Text(chat['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        trailing: hasUnread ? CircleAvatar(radius: 4, backgroundColor: _gold) : const Icon(Icons.chevron_right, color: Colors.white24),
      ),
    );
  }

  void _openAdminChatRoom(String userId, String userName) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            gradient: AppColors.backgroundGradient,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              _buildChatHeader(userName),
              Expanded(child: _buildMessageList(userId, controller)),
              _buildMessageInput(userId),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatHeader(String name) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          Icon(Icons.chat_bubble_outline, color: _gold),
          const SizedBox(width: 16),
          Text(name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const Spacer(),
          IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white54)),
        ],
      ),
    );
  }

  // --- SYSTEM ACTIVITY / RECENT MEMBERS ---
  Widget _buildSystemActionsModule() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _moduleHeader('Recent Activity', Icons.history, const Color(0xFF00FF94)),
        const SizedBox(height: 12),
        StreamBuilder<List<Participant>>(
          stream: ref.watch(userRepositoryProvider).getRealTimeMembers(),
          builder: (context, snapshot) {
            final members = snapshot.data ?? [];
            if (members.isEmpty) return const Text('No recent activity', style: TextStyle(color: Colors.white38));
            
            // Take last 3 joined
            final recent = members.take(3).toList();
            
            return Column(
              children: recent.map((m) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                child: _GlassCard(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.person_add, color: Color(0xFF00FF94), size: 16),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'New member joined: ${m.name}', 
                          style: const TextStyle(color: Colors.white, fontSize: 13)
                        ),
                      ),
                      Text(
                        _formatTime(m.joinedAt ?? DateTime.now()),
                        style: const TextStyle(color: Colors.white38, fontSize: 10)
                      ),
                    ],
                  ),
                ),
              )).toList(),
            );
          }
        ),
      ],
    );
  }

  String _formatTime(DateTime date) {
    return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  // ... (keep _actionBtn helper if needed elsewhere, otherwise ok to remove)

  // --- MEMBER ITEM & DETAILS ---
  Widget _memberItem(Participant member) {
    return ListTile(
      onTap: () => _showMemberDetails(member),
      contentPadding: const EdgeInsets.symmetric(vertical: 8),
      leading: Stack(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _gold.withOpacity(0.3)),
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.white.withOpacity(0.1),
              backgroundImage: member.profileImage != null && member.profileImage!.isNotEmpty 
                ? NetworkImage(member.profileImage!) 
                : null,
              child: member.profileImage == null || member.profileImage!.isEmpty
                ? Text(member.name.isNotEmpty ? member.name[0] : 'U', style: const TextStyle(color: Colors.white, fontSize: 14))
                : null,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: member.isOnline ? const Color(0xFF00FF94) : Colors.grey, 
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 2),
              ),
            ),
          ),
        ],
      ),
      title: Text(member.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(member.email, style: const TextStyle(color: Colors.white54, fontSize: 11)),
          Text(
            'Joined: ${member.joinedAt?.toString().split(' ')[0] ?? 'Just now'}', 
            style: TextStyle(color: _gold, fontSize: 10, fontWeight: FontWeight.bold)
          ),
        ],
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.white24, size: 16),
    );
  }

  void _showMemberDetails(Participant member) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView( // FIX: Scrollable content
          child: Column(
            children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 24),
            CircleAvatar(
              radius: 40,
              backgroundImage: member.profileImage != null ? NetworkImage(member.profileImage!) : null,
              child: member.profileImage == null ? const Icon(Icons.person, size: 40, color: Colors.white54) : null,
            ),
            const SizedBox(height: 16),
            Text(member.name, style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
            Text(member.isOnline ? 'Online' : 'Offline', style: TextStyle(color: member.isOnline ? const Color(0xFF00FF94) : Colors.grey)),
            const SizedBox(height: 32),
            _detailRow(Icons.email, 'Email', member.email),
            const SizedBox(height: 16),
            _detailRow(Icons.phone, 'Phone', member.mobile.isEmpty ? 'N/A' : member.mobile),
            const SizedBox(height: 16),
              _detailRow(Icons.event, 'Joined Events', '0 Events'), // Placeholder logic for user-event join relation
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: _gold, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white38, fontSize: 12)),
            Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
          ],
        ),
      ],
    );
  }

  // --- CHAT FIX ---
  // ... (Chat Helper methods) ... 

  Widget _buildMessageList(String userId, ScrollController controller) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ref.watch(adminChatRepositoryProvider).watchMessages(userId),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        return ListView.builder(
          controller: controller,
          padding: const EdgeInsets.all(24),
          reverse: true, // Messages usually bottom-up
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final msg = snapshot.data![index];
            final bool isMe = msg['senderRole'] == 'admin';
            // FIX: Handle both 'message' and 'text' keys
            final String text = msg['message'] ?? msg['text'] ?? '';
            return _chatBubble(text, isMe);
          },
        );
      },
    );
  }

  Widget _buildMessageInput(String userId) {
    final controller = TextEditingController();
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Type a reply...',
                hintStyle: const TextStyle(color: Colors.white38),
                border: InputBorder.none,
                fillColor: Colors.white.withOpacity(0.05),
                filled: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(adminChatRepositoryProvider).replyToUser(userId, controller.text.trim());
                controller.clear();
              }
            },
            child: CircleAvatar(
              backgroundColor: _gold,
              child: const Icon(Icons.send, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? _gold : Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(18),
            bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(color: isMe ? Colors.black : Colors.white),
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildBrandingSection() {
    final brandingAsync = ref.watch(brandingProvider);

    return brandingAsync.when(
      loading: () => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFFFFD700)),
            const SizedBox(height: 16),
            Text(
              'Connecting to branding service...',
              style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
            ),
          ],
        ),
      ),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text('Error: $error', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => ref.invalidate(brandingProvider),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
      data: (branding) {
        // Update controller only if it was empty to avoid overwriting user input while editing
        if (_brandingNameController.text.isEmpty && branding.companyName != 'Event App') {
          _brandingNameController.text = branding.companyName;
        }

        return Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionTitle('Branding Settings'),
                const SizedBox(height: 24),
                _GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Company Name', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _brandingNameController,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Enter company name',
                          hintStyle: TextStyle(color: Colors.white.withOpacity(0.2)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.05),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text('Company Logo', style: TextStyle(color: Colors.white70, fontSize: 14)),
                      const SizedBox(height: 12),
                      Center(
                        child: GestureDetector(
                          onTap: _isSavingBranding ? null : () async {
                            final picker = ImagePicker();
                            final image = await picker.pickImage(
                              source: ImageSource.gallery,
                              maxWidth: 1024,
                              maxHeight: 1024,
                              imageQuality: 70,
                            );
                            if (image != null) {
                              final bytes = await image.readAsBytes();
                              setState(() {
                                _brandingLogo = image;
                                _brandingLogoBytes = bytes;
                              });
                            }
                          },
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withOpacity(0.1)),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (_brandingLogoBytes != null)
                                    Image.memory(_brandingLogoBytes!, fit: BoxFit.contain)
                                  else if (branding.companyLogoUrl != null)
                                    CachedNetworkImage(
                                      imageUrl: branding.companyLogoUrl!,
                                      fit: BoxFit.contain,
                                      placeholder: (_, __) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                      errorWidget: (_, __, ___) => const Icon(Icons.business, color: Colors.white24, size: 40),
                                    )
                                  else
                                    const Icon(Icons.add_photo_alternate_outlined, color: Colors.white24, size: 40),
                                  
                                  if (_isSavingBranding)
                                    Container(
                                      color: Colors.black45,
                                      child: const Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Center(
                        child: Text('Tap to change logo', style: TextStyle(color: Colors.white38, fontSize: 12)),
                      ),
                      const SizedBox(height: 32),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isSavingBranding ? null : () async {
                            if (_brandingNameController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Company name cannot be empty'))
                              );
                              return;
                            }
  
                            setState(() => _isSavingBranding = true);
                            try {
                              String finalUrl = branding.companyLogoUrl ?? '';
                              if (_brandingLogoBytes != null) {
                                finalUrl = await ref.read(adminRepositoryProvider).uploadToCloudinary(
                                  _brandingLogoBytes!, 
                                  folder: 'branding'
                                );
                              }
  
                              final updatedBranding = BrandingInfo(
                                companyName: _brandingNameController.text.trim(),
                                companyLogoUrl: finalUrl.isEmpty ? null : finalUrl,
                              );
  
                              await ref.read(adminRepositoryProvider).saveBranding(updatedBranding);
  
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Branding updated successfully!'), backgroundColor: Colors.green)
                                );
                                setState(() {
                                  _brandingLogo = null;
                                  _brandingLogoBytes = null;
                                });
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Failed to update branding: $e'), backgroundColor: Colors.red)
                                );
                              }
                            } finally {
                              if (mounted) {
                                setState(() => _isSavingBranding = false);
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _gold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isSavingBranding
                              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                              : const Text('Save Branding', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (branding.companyName != 'Event App' || branding.companyLogoUrl != null)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isSavingBranding ? null : () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Colors.grey[900],
                                  title: const Text('Delete Branding?', style: TextStyle(color: Colors.white)),
                                  content: const Text(
                                    'This will reset the header to default. The logo will be removed from the header but NOT from Cloudinary storage.',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, false),
                                      child: const Text('Cancel'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.pop(context, true),
                                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                setState(() => _isSavingBranding = true);
                                try {
                                  await ref.read(adminRepositoryProvider).deleteBranding();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Branding reset to default'), backgroundColor: Colors.orange)
                                    );
                                    setState(() {
                                      _brandingLogo = null;
                                      _brandingLogoBytes = null;
                                      _brandingNameController.text = 'Event App'; // Reset locally
                                    });
                                  }
                                } catch (e) {
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Failed to delete branding: $e'), backgroundColor: Colors.red)
                                    );
                                  }
                                } finally {
                                  if (mounted) {
                                    setState(() => _isSavingBranding = false);
                                  }
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Colors.redAccent),
                              foregroundColor: Colors.redAccent,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('Delete Branding / Reset to Default'),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;

  const _GlassCard({required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(28), // Premium rounded corners matching Event Home
        border: Border.all(color: Colors.white.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}
