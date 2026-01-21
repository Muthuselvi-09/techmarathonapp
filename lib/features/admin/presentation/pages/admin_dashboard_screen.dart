// Sync version: 2026-01-12-16-14 - Fixed imports and unified models.
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:tech_marathon_app/features/chat/data/chat_repository.dart';
import 'package:tech_marathon_app/features/auth/data/user_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart'; // for kIsWeb
import 'package:tech_marathon_app/core/providers.dart';
import 'package:tech_marathon_app/data/models/schedule.dart' as new_schedule;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/branding_provider.dart';



class AdminDashboardScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const AdminDashboardScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  int _currentTab = 0; // 0: Overview, 1: Events, 2: Members, 3: Speakers, 4: Sponsors, 5: Schedules, 6: Chat, 7: Branding
  String? _selectedEventId;
  
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

  // Gold + Black Theme Constants
  final Color _gold = const Color(0xFFFFD700);

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
                     _gold.withValues(alpha: 0.05), // Subtle gold hint
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

  void _handleFABPressed() async {
    // Method intentionally removed as FAB is no longer used
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        border: Border(bottom: BorderSide(color: _gold.withValues(alpha: 0.1))),
      ),
      child: Row(
        children: [
          InkWell(
            onTap: () => context.pop(),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
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
          color: Colors.white.withValues(alpha: 0.05),
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
          color: isSelected ? _gold : Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isSelected ? _gold : Colors.white.withValues(alpha: 0.1),
          ),
          boxShadow: isSelected 
            ? [BoxShadow(color: _gold.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))] 
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
        _sectionTitle('Control Center'),
        const SizedBox(height: 20),
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
        }
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
                    decoration: BoxDecoration(color: const Color(0xFF00FF94).withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
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
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(12)),
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
             if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
               return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
             }
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 140, child: Center(child: CircularProgressIndicator()));
            }
            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return const SizedBox(
                height: 140,
                child: Center(child: Text('No active events', style: TextStyle(color: Colors.white38))),
              );
            }
            
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
                                decoration: BoxDecoration(color: _gold.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
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



  Widget _moduleHeader(String title, IconData icon, Color accent) {
    return Row(
      children: [
        Icon(icon, color: accent, size: 18),
        const SizedBox(width: 8),
        Text(title, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildEventSelector(List<CodingEvent> events) {
    return Container(
      height: 40,
      margin: const EdgeInsets.only(top: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: events.length,
        itemBuilder: (context, index) {
          final event = events[index];
          final isSelected = event.id == _selectedEventId;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(event.name, style: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 12)),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedEventId = event.id);
              },
              backgroundColor: Colors.white12,
              selectedColor: _gold,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              showCheckmark: false,
            ),
          );
        },
      ),
    );
  }

  Widget _actionBtn(String label, IconData icon, Color color, VoidCallback onTap) {
    return _GlassCard(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
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
          // Always show header with Add button (outside StreamBuilder)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Manage Events'),
              ElevatedButton.icon(
                onPressed: () => _showEventDialog(),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Event'),
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
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                }
                
                if (snapshot.hasError) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  );
                }
                
                final firestoreEvents = snapshot.data ?? [];

                if (firestoreEvents.isEmpty) {
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available_outlined, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                          const SizedBox(height: 16),
                          Text(
                            'No events yet',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "Add Event" to create your first event',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  );
                }
                
                return ListView.builder(
                  itemCount: firestoreEvents.length,
                  itemBuilder: (context, index) {
                    final event = firestoreEvents[index];
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: event.imageUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: event.imageUrl,
                  width: 44,
                  height: 44,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Shimmer.fromColors(
                  baseColor: Colors.white10,
                  highlightColor: Colors.white24,
                  child: Container(width: 44, height: 44, color: Colors.white),
                ),
                  errorWidget: (_, __, ___) => const Icon(Icons.event_note, color: AppColors.codingRimPrimary, size: 20),
                )
              : Container(
                  width: 44,
                  height: 44,
                  color: Colors.white12,
                  child: const Icon(Icons.event_note, color: AppColors.codingRimPrimary, size: 20),
                ),
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
    
    // Generate ID immediately for new events to ensure storage path availability
    final String tempEventId = event?.id ?? FirebaseFirestore.instance.collection('events').doc().id;

    bool isSaving = false;
    XFile? selectedImageFile;
    Uint8List? selectedImageBytes;
    String? currentImageUrl = event?.imageUrl;

    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing while saving
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(event == null ? 'Add Event' : 'Edit Event', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isSaving ? null : () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery);
                    
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      Uint8List? compressed;
                      try {
                        // STRICT IMAGE COMPRESSION (1024, 70)
                        compressed = await FlutterImageCompress.compressWithList(
                          bytes,
                          minWidth: 1024,
                          minHeight: 1024,
                          quality: 70,
                        );
                      } catch (e) {
                         debugPrint('Compression error: $e');
                      }

                      final finalBytes = compressed ?? bytes;
                      setState(() { 
                        selectedImageFile = image;
                        selectedImageBytes = finalBytes; 
                      });
                    }
                  },
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white24),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                           if (selectedImageBytes != null)
                             Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                           else if (currentImageUrl != null && currentImageUrl.isNotEmpty)
                             CachedNetworkImage(
                               imageUrl: currentImageUrl!,
                               fit: BoxFit.cover,
                               placeholder: (_, __) => Shimmer.fromColors(
                                 baseColor: Colors.white10,
                                 highlightColor: Colors.white24,
                                 child: Container(color: Colors.white),
                               ),
                               errorWidget: (_, __, ___) => const Icon(Icons.error),
                             )
                           else
                             const Center(
                               child: Column(
                                 mainAxisAlignment: MainAxisAlignment.center,
                                 children: [
                                   Icon(Icons.add_photo_alternate_rounded, color: Colors.white54, size: 48),
                                   SizedBox(height: 12),
                                   Text('Tap to add cover image', style: TextStyle(color: Colors.white54, fontSize: 14)),
                                 ],
                               ),
                             ),
                           if (isSaving) 
                             Container(
                               color: Colors.black45,
                               child: const Center(child: CircularProgressIndicator()),
                             ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(enabled: !isSaving, controller: titleController, decoration: const InputDecoration(labelText: 'Event Title'), style: const TextStyle(color: Colors.white)),
                TextField(enabled: !isSaving, controller: locationController, decoration: const InputDecoration(labelText: 'Location'), style: const TextStyle(color: Colors.white)),
                TextField(enabled: !isSaving, controller: categoryController, decoration: const InputDecoration(labelText: 'Category'), style: const TextStyle(color: Colors.white)),
                TextField(enabled: !isSaving, controller: descController, decoration: const InputDecoration(labelText: 'Description'), style: const TextStyle(color: Colors.white), maxLines: 3),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isSaving ? null : () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                 if (titleController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
                    return;
                 }
                 
                 setState(() => isSaving = true);

                 try {
                   // 1. CAPTURE ALL DATA
                   final messenger = ScaffoldMessenger.of(context);
                   final repo = ref.read(adminRepositoryProvider);
                   
                   final String name = titleController.text.trim();
                   final String location = locationController.text.trim();
                   final String category = categoryController.text.trim();
                   final String desc = descController.text.trim();
                   
                   final String existingId = tempEventId;
                   final DateTime date = event?.date ?? DateTime.now();
                   final List<String> speakerIds = event?.speakerIds ?? [];
                   final int pCount = event?.participantCount ?? 0;
                   final bool isNewEntry = event == null;
                   
                   final String initialImageUrl = currentImageUrl ?? '';
                   final Uint8List? imageBytes = selectedImageBytes;

                   // 2. SEQUENTIAL WORK (No background)
                   String finalUrl = initialImageUrl;
                   
                   // Upload if new image selected
                   if (imageBytes != null) {
                      finalUrl = await repo.uploadToCloudinary(imageBytes);
                   }

                   if (finalUrl.isEmpty) {
                      throw 'Image required';
                   }

                   final newEvent = CodingEvent(
                     id: existingId, 
                     name: name,
                     location: location,
                     category: category,
                     description: desc,
                     date: date,
                     speakerIds: speakerIds,
                     imageUrl: finalUrl,
                     participantCount: pCount,
                     isActive: true,
                     // createdAt and updatedAt will be handled by repo using FieldValue.serverTimestamp()
                   );

                   await repo.saveEvent(newEvent, isNew: isNewEntry);
                   
                   // 3. SUCCESS UPDATE & CLOSE
                   if (context.mounted) {
                     Navigator.pop(context);
                     ScaffoldMessenger.of(context).showSnackBar(
                       const SnackBar(content: Text('Event Saved Successfully! ✅'), backgroundColor: Colors.green)
                     );
                   }
                 } catch (e) {
                   debugPrint('Save Error: $e');
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Error saving event: $e'), backgroundColor: Colors.red)
                     );
                   }
                 } finally {
                   if (context.mounted) {
                     setState(() => isSaving = false);
                   }
                 }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.codingRimPrimary,
                foregroundColor: Colors.black,
              ),
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Save Event'),
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator(color: Color(0xFFFFD700))));
            }
            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return SizedBox(
                height: 200,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.people_outline, size: 48, color: Colors.white.withValues(alpha: 0.1)),
                      const SizedBox(height: 16),
                      Text('No one has joined yet', style: TextStyle(color: Colors.white.withValues(alpha: 0.3))),
                    ],
                  ),
                ),
              );
            }
            
            final members = snapshot.data!;
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (context, index) => Divider(color: Colors.white.withValues(alpha: 0.05)),
              itemBuilder: (context, index) {
                final member = members[index];
                return _memberItem(member);
              },
            );
          },
        ),
      ],
    );
  }



  // --- 4. SPEAKERS SECTION (Real-time & Persisted) ---
  Widget _buildSpeakersSection() {
    final repo = ref.watch(adminRepositoryProvider);
    
    return StreamBuilder<List<CodingEvent>>(
      stream: repo.watchEvents(),
      builder: (context, eventSnapshot) {
        final events = eventSnapshot.data ?? [];
        final hasEvents = events.isNotEmpty;
        
        // Robust ID derivation: State > First Event > Null
        String? effectiveId = _selectedEventId;
        if (effectiveId == null && hasEvents) {
          effectiveId = events.first.id;
        } else if (effectiveId != null && hasEvents && !events.any((e) => e.id == effectiveId)) {
          // If selected event no longer exists, reset to first
          effectiveId = events.first.id;
        }

        final currentEvent = events.any((e) => e.id == effectiveId) 
            ? events.firstWhere((e) => e.id == effectiveId)
            : null;
        
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (eventSnapshot.connectionState == ConnectionState.waiting)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ))
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Manage Speakers'),
                          if (hasEvents)
                            _buildEventSelector(events),
                          if (currentEvent == null)
                            const Text('No event selected', style: TextStyle(color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!hasEvents) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please create an event first in the "Events" tab')),
                          );
                          return;
                        }
                        if (_selectedEventId == null) {
                          if (events.isNotEmpty) {
                            setState(() => _selectedEventId = events.first.id);
                            _showSpeakerDialog(eventId: events.first.id);
                          }
                          return;
                        }
                        _showSpeakerDialog(eventId: _selectedEventId!);
                      },
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
                  child: !hasEvents
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                            const SizedBox(height: 16),
                            const Text(
                              'No events available',
                              style: TextStyle(color: Colors.white, fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            const SizedBox(height: 8),
                            const Text(
                              'Please wait for an event to be created',
                              style: TextStyle(color: Colors.white54, fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : AdminSpeakerList(
                        eventId: effectiveId!,
                        onEdit: (speaker) => _showSpeakerDialog(speaker: speaker, eventId: speaker.eventId),
                        onDelete: (speaker) => ref.read(speakerRepositoryProvider).deleteSpeaker(speaker.eventId, speaker.id),
                      ),
                ),
              ],
            ],
          ),
        );
      }
    );
  }



  void _showSpeakerDialog({Speaker? speaker, required String eventId}) {
    final nameController = TextEditingController(text: speaker?.name);
    final roleController = TextEditingController(text: speaker?.role);
    final bioController = TextEditingController(text: speaker?.bio);
    final linkedinController = TextEditingController(text: speaker?.linkedinUrl);
    
    // Generate ID for storage path consistency
    final String tempSpeakerId = speaker?.id ?? FirebaseFirestore.instance.collection('events').doc(eventId).collection('speakers').doc().id;
    
    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    String? currentImageUrl = speaker?.imageUrl;
    bool isSaving = false;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(speaker == null ? 'Add Speaker' : 'Edit Speaker', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: isSaving ? null : () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(
                      source: ImageSource.gallery, 
                      maxWidth: 1024, 
                      maxHeight: 1024, 
                      imageQuality: 70,
                    );
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      Uint8List? compressed;
                      try {
                        compressed = await FlutterImageCompress.compressWithList(
                          bytes,
                          minWidth: 1024,
                          minHeight: 1024,
                          quality: 70,
                        );
                      } catch (e) {
                        debugPrint('Compression error: $e');
                      }

                      setState(() { 
                        selectedImage = image;
                        selectedImageBytes = compressed ?? bytes;
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24),
                    ),
                     child: ClipOval(
                       child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (selectedImageBytes != null)
                            Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                          else if (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: currentImageUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Shimmer.fromColors(
                                baseColor: Colors.white10,
                                highlightColor: Colors.white24,
                                child: Container(color: Colors.white),
                              ),
                            )
                          else
                            const Center(
                               child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.camera_alt, color: Colors.white54, size: 30),
                                    Text('Photo', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                  ],
                                )
                            ),
                           if (isSaving)
                             Container(
                               color: Colors.black45,
                               child: const Center(child: CircularProgressIndicator(color: AppColors.codingRimPrimary)),
                             ),
                        ],
                      ),
                     ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), style: const TextStyle(color: Colors.white)),
                TextField(controller: roleController, decoration: const InputDecoration(labelText: 'Role (e.g. Keynote)'), style: const TextStyle(color: Colors.white)),
                TextField(controller: bioController, decoration: const InputDecoration(labelText: 'Bio'), style: const TextStyle(color: Colors.white), maxLines: 3),
                TextField(controller: linkedinController, decoration: const InputDecoration(labelText: 'LinkedIn URL'), style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                 if (nameController.text.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                   return;
                 }

                 setState(() => isSaving = true);

                 try {
                   final messenger = ScaffoldMessenger.of(context);
                   final repo = ref.read(adminRepositoryProvider);
                   final String name = nameController.text.trim();
                   final String role = roleController.text.trim();
                   final String bio = bioController.text.trim();
                   final String linkedin = linkedinController.text.trim();
                   
                   String finalImageUrl = currentImageUrl ?? '';

                   // 1. SEQUENTIAL CLOUDINARY UPLOAD
                   if (selectedImageBytes != null) {
                      finalImageUrl = await repo.uploadToCloudinary(selectedImageBytes!);
                   }

                   if (finalImageUrl.isEmpty) {
                      throw 'Speaker photo is required.';
                   }

                   // 2. FIRESTORE SAVE
                   final newSpeaker = Speaker(
                     id: tempSpeakerId, 
                     eventId: eventId,
                     name: name,
                     role: role,
                     bio: bio,
                     imageUrl: finalImageUrl,
                     linkedinUrl: linkedin,
                     isActive: true,
                   );

                   await repo.saveSpeaker(newSpeaker, isNew: speaker == null);
                   
                   if (context.mounted) {
                     Navigator.pop(context);
                     messenger.showSnackBar(const SnackBar(content: Text('Speaker Saved! ✅'), backgroundColor: Colors.green));
                   }
                 } catch (e) {
                   debugPrint('Speaker Save Error: $e');
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Failed to save speaker: $e'), backgroundColor: Colors.red)
                     );
                   }
                 } finally {
                   if (context.mounted) {
                     setState(() => isSaving = false);
                   }
                 }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.codingRimPrimary,
                foregroundColor: Colors.black,
              ),
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Save Speaker'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 5. SPONSORS SECTION (Real-time & Persisted) ---
  Widget _buildSponsorsSection() {
    final repo = ref.watch(adminRepositoryProvider);
    
    return StreamBuilder<List<CodingEvent>>(
      stream: repo.watchEvents(),
      builder: (context, eventSnapshot) {
        final events = eventSnapshot.data ?? [];
        final hasEvents = events.isNotEmpty;
        
        // Robust ID derivation
        String? effectiveId = _selectedEventId;
        if (effectiveId == null && hasEvents) {
          effectiveId = events.first.id;
        } else if (effectiveId != null && hasEvents && !events.any((e) => e.id == effectiveId)) {
          effectiveId = events.first.id;
        }
        
        if (effectiveId != null && _selectedEventId != effectiveId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedEventId = effectiveId);
          });
        }

        final currentEvent = events.any((e) => e.id == effectiveId) 
            ? events.firstWhere((e) => e.id == effectiveId)
            : (hasEvents ? events.first : null);
        
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (eventSnapshot.connectionState == ConnectionState.waiting)
                const Center(child: Padding(
                  padding: EdgeInsets.all(40.0),
                  child: CircularProgressIndicator(),
                ))
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Manage Sponsors'),
                          if (hasEvents)
                            _buildEventSelector(events),
                          if (currentEvent == null)
                            const Text('No event selected', style: TextStyle(color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!hasEvents) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please create an event first in the "Events" tab')),
                          );
                          return;
                        }
                        if (_selectedEventId == null) {
                          if (events.isNotEmpty) {
                            setState(() => _selectedEventId = events.first.id);
                            _showSponsorDialog(eventId: events.first.id);
                          }
                          return;
                        }
                        _showSponsorDialog(eventId: _selectedEventId!);
                      },
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
                  child: !hasEvents
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                            const SizedBox(height: 16),
                            Text(
                              'No events available',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create an event in the Events tab first',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                        : StreamBuilder<List<Sponsor>>(
                        stream: ref.watch(sponsorRepositoryProvider).watchSponsors(effectiveId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                          }
                          if (snapshot.hasError) {
                            return SizedBox(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                    const SizedBox(height: 16),
                                    Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            );
                          }

                          final sponsors = snapshot.data ?? [];
                          
                          if (sponsors.isEmpty) {
                            return SizedBox(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.business_center_outlined, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No sponsors yet',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Click "Add Sponsor" to create one',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            itemCount: sponsors.length,
                            itemBuilder: (context, index) => _sponsorItem(sponsors[index]),
                          );
                        },
                      ),
                ),
              ],
            ],
          ),
        );
      }
    );
  }

  Widget _sponsorItem(Sponsor sponsor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
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
              image: sponsor.logoUrl.isNotEmpty 
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(sponsor.logoUrl), // Use locally cached image if available
                      fit: BoxFit.contain,
                    ) 
                  : null,
            ),
            child: sponsor.logoUrl.isEmpty ? const Icon(Icons.business, color: Colors.black) : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(sponsor.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text('${sponsor.tier} • ${sponsor.websiteUrl}', style: const TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent),
            onPressed: () => _showSponsorDialog(sponsor: sponsor, eventId: sponsor.eventId),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: () async {
                await ref.read(sponsorRepositoryProvider).deleteSponsor(sponsor.eventId, sponsor.id);
            },
          ),
        ],
      ),
    );
  }

  void _showSponsorDialog({Sponsor? sponsor, required String eventId}) {
    final nameController = TextEditingController(text: sponsor?.name);
    final tierController = TextEditingController(text: sponsor?.tier);
    final websiteController = TextEditingController(text: sponsor?.websiteUrl);
    
    // Generate ID for storage consistency
    final String tempSponsorId = sponsor?.id ?? FirebaseFirestore.instance.collection('events').doc(eventId).collection('sponsors').doc().id;

    XFile? selectedImage;
    Uint8List? selectedImageBytes;
    String? currentImageUrl = sponsor?.logoUrl;
    bool isSaving = false;

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
                    final image = await picker.pickImage(
                      source: ImageSource.gallery, 
                      maxWidth: 2048, 
                      maxHeight: 2048, 
                      imageQuality: 85,
                    );
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      final sizeInKb = bytes.lengthInBytes / 1024;
                      
                      if (context.mounted) {
                         ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Processing Image... (${sizeInKb.toStringAsFixed(1)} KB)'),
                            backgroundColor: Colors.blueAccent,
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      }

                      Uint8List? compressed;
                      try {
                        compressed = await FlutterImageCompress.compressWithList(
                          bytes,
                          minWidth: 1024,
                          minHeight: 1024,
                          quality: 70,
                        );
                      } catch (e) {
                        debugPrint('Sponsor compression error: $e');
                      }

                      setState(() { 
                        selectedImage = image;
                        selectedImageBytes = compressed ?? bytes;
                      });
                    }
                  },
                  child: Container(
                    height: 120,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          if (selectedImageBytes != null)
                            Image.memory(selectedImageBytes!, fit: BoxFit.contain)
                          else if (currentImageUrl != null && currentImageUrl!.isNotEmpty)
                            CachedNetworkImage(
                              imageUrl: currentImageUrl!,
                              fit: BoxFit.contain,
                              placeholder: (_, __) => Shimmer.fromColors(
                                baseColor: Colors.white10,
                                highlightColor: Colors.white24,
                                child: Container(color: Colors.white),
                              ),
                              errorWidget: (_, __, ___) => const Icon(Icons.error),
                            )
                          else
                            const Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_business_rounded, color: Colors.white54, size: 30),
                                  Text('Logo', style: TextStyle(color: Colors.white54, fontSize: 10)),
                                ],
                              ),
                            ),
                           if (isSaving)
                             Container(
                               color: Colors.black45,
                               child: const Center(child: CircularProgressIndicator(color: AppColors.codingRimPrimary)),
                             ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name'), style: const TextStyle(color: Colors.white)),
                TextField(controller: tierController, decoration: const InputDecoration(labelText: 'Tier (e.g. Gold)'), style: const TextStyle(color: Colors.white)),
                TextField(controller: websiteController, decoration: const InputDecoration(labelText: 'Website URL'), style: const TextStyle(color: Colors.white)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context), 
              child: const Text('Cancel')
            ),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                 if (nameController.text.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name is required')));
                   return;
                 }
                 
                 setState(() => isSaving = true);
                 
                 try {
                   final messenger = ScaffoldMessenger.of(context);
                   final repo = ref.read(adminRepositoryProvider);
                   final String name = nameController.text.trim();
                   final String tier = tierController.text.trim();
                   final String website = websiteController.text.trim();
                   
                   String finalLogoUrl = currentImageUrl ?? '';

                   // 1. SEQUENTIAL CLOUDINARY UPLOAD
                   if (selectedImageBytes != null) {
                      finalLogoUrl = await repo.uploadToCloudinary(selectedImageBytes!);
                   }
                   
                   if (finalLogoUrl.isEmpty) {
                      throw 'Sponsor logo is required.';
                   }

                   // 2. FIRESTORE SAVE
                   final newSponsor = Sponsor(
                     id: tempSponsorId, 
                     eventId: eventId,
                     name: name,
                     company: tier,
                     tier: tier,
                     logoUrl: finalLogoUrl,
                     websiteUrl: website,
                   );
                   
                   await repo.saveSponsor(newSponsor, isNew: sponsor == null);
                   
                   if (context.mounted) {
                     Navigator.pop(context); 
                     messenger.showSnackBar(const SnackBar(content: Text('Sponsor Saved! ✅'), backgroundColor: Colors.green));
                   }
                 } catch (e) {
                   debugPrint('Sponsor Save Error: $e');
                   if (context.mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                       SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red)
                     );
                   }
                 } finally {
                   if (context.mounted) {
                     setState(() => isSaving = false);
                   }
                 }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.codingRimPrimary,
                foregroundColor: Colors.black,
              ),
              child: isSaving 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                : const Text('Save Sponsor'),
            ),
          ],
        ),
      ),
    );
  }

  // --- 6. SCHEDULES SECTION (Real-time CRUD) ---
  Widget _buildSchedulesSection() {
    final repo = ref.watch(adminRepositoryProvider);

    return StreamBuilder<List<CodingEvent>>(
      stream: repo.watchEvents(),
      builder: (context, eventSnapshot) {
        final events = eventSnapshot.data ?? [];
        final hasEvents = events.isNotEmpty;
        
        // Robust ID derivation
        String? effectiveId = _selectedEventId;
        if (effectiveId == null && hasEvents) {
          effectiveId = events.first.id;
        } else if (effectiveId != null && hasEvents && !events.any((e) => e.id == effectiveId)) {
          effectiveId = events.first.id;
        }
        
        if (effectiveId != null && _selectedEventId != effectiveId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedEventId = effectiveId);
          });
        }

        final currentEvent = events.any((e) => e.id == effectiveId) 
            ? events.firstWhere((e) => e.id == effectiveId)
            : null;

        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              if (eventSnapshot.connectionState == ConnectionState.waiting)
                const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()))
              else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('Manage Schedules'),
                          if (hasEvents)
                            _buildEventSelector(events),
                          if (currentEvent == null)
                            const Text('No event selected', style: TextStyle(color: Colors.orange, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton.icon(
                      onPressed: () {
                        if (!hasEvents) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please create an event first in the "Events" tab')),
                          );
                          return;
                        }
                        if (_selectedEventId == null) {
                          if (events.isNotEmpty) {
                            setState(() => _selectedEventId = events.first.id);
                            _showScheduleDialog(eventId: events.first.id);
                          }
                          return;
                        }
                        _showScheduleDialog(eventId: _selectedEventId!);
                      },
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
                  child: !hasEvents
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_busy, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                            const SizedBox(height: 16),
                            Text(
                              'No events available',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Create an event in the Events tab first',
                              style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                        : StreamBuilder<List<new_schedule.Schedule>>(
                        stream: ref.watch(scheduleRepositoryProvider).watchSchedules(_selectedEventId!),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
                          }
                          if (snapshot.hasError) {
                            return SizedBox(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, color: Colors.red, size: 48),
                                    const SizedBox(height: 16),
                                    Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                                  ],
                                ),
                              ),
                            );
                          }

                          final schedules = snapshot.data ?? [];
                          
                          if (schedules.isEmpty) {
                            return SizedBox(
                              height: 200,
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.calendar_today_outlined, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                                    const SizedBox(height: 16),
                                    Text(
                                      'No schedules yet',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Click "Add Schedule" to create one',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: schedules.length,
                            itemBuilder: (context, index) => _scheduleItem(schedules[index]),
                          );
                        },
                      ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _scheduleItem(new_schedule.Schedule schedule) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: _gold.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.access_time_rounded, color: _gold, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(schedule.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                Text(
                  '${schedule.startTime.hour}:${schedule.startTime.minute.toString().padLeft(2, '0')} - ${schedule.endTime.hour}:${schedule.endTime.minute.toString().padLeft(2, '0')} • Day ${schedule.day}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blueAccent, size: 20),
            onPressed: () => _showScheduleDialog(schedule: schedule, eventId: schedule.eventId),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
            onPressed: () => ref.read(scheduleRepositoryProvider).deleteSchedule(schedule.eventId, schedule.id),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog({new_schedule.Schedule? schedule, required String eventId}) {
    final titleController = TextEditingController(text: schedule?.title);
    final descController = TextEditingController(text: schedule?.description);
    final locationController = TextEditingController(text: schedule?.location);
    final dayController = TextEditingController(text: schedule?.day.toString() ?? '1');
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(schedule == null ? 'Add Schedule Slot' : 'Edit Slot', style: const TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title'), style: const TextStyle(color: Colors.white)),
              TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), style: const TextStyle(color: Colors.white), maxLines: 2),
              TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location / Room'), style: const TextStyle(color: Colors.white)),
              TextField(controller: dayController, decoration: const InputDecoration(labelText: 'Day Number'), keyboardType: TextInputType.number, style: const TextStyle(color: Colors.white)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving ? null : () async {
                if (titleController.text.isEmpty) {
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
                   return;
                }
                
                setState(() => isSaving = true);
                
                try {
                  final messenger = ScaffoldMessenger.of(context);
                  final repo = ref.read(adminRepositoryProvider);
                  final String title = titleController.text.trim();
                  final String description = descController.text.trim();
                  final String location = locationController.text.trim();
                  final int day = int.tryParse(dayController.text) ?? 1;
                  final String scheduleId = schedule?.id ?? '';
                  final bool isNewEntry = schedule == null;
                  final DateTime startTime = schedule?.startTime ?? DateTime.now();
                  final DateTime endTime = schedule?.endTime ?? DateTime.now().add(const Duration(hours: 1));
                  final List<String> mediaUrls = schedule?.mediaUrls ?? [];

                  final newSlot = new_schedule.Schedule(
                    id: scheduleId,
                    eventId: eventId,
                    day: day,
                    title: title,
                    description: description,
                    location: location,
                    startTime: startTime,
                    endTime: endTime,
                    mediaUrls: mediaUrls,
                  );

                  await repo.saveSchedule(newSlot, isNew: isNewEntry);
                  
                  if (context.mounted) {
                     Navigator.pop(context);
                     messenger.showSnackBar(const SnackBar(content: Text('Schedule Saved!'), backgroundColor: Colors.green, duration: Duration(seconds: 2)));
                  }
                } catch (e) {
                   setState(() => isSaving = false);
                   if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving schedule: $e'), backgroundColor: Colors.red));
                   }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.codingRimPrimary,
                foregroundColor: Colors.black,
              ),
              child: isSaving 
                ? const SizedBox(
                    height: 16, 
                    width: 16, 
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)
                  ) 
                : const Text('Save'),
            ),
        ],
      ),
    ),
  );
  }

  // --- 7. CHAT SECTION (Real-time Admin List View) ---
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
                
                final threadData = snapshot.data!;
                return ListView.builder(
                  itemCount: threadData.length,
                  itemBuilder: (context, index) {
                    final chat = threadData[index];
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
        color: Colors.white.withValues(alpha: hasUnread ? 0.08 : 0.03),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: hasUnread ? _gold.withValues(alpha: 0.3) : Colors.transparent),
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
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
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
        _moduleHeader('System Actions', Icons.bolt, const Color(0xFF00FF94)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                'Add Event', 
                Icons.add_circle_outline, 
                const Color(0xFF00FF94),
                () => _showEventDialog(),
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _moduleHeader('Recent Activity', Icons.history, Colors.white38),
        const SizedBox(height: 12),
        StreamBuilder<List<Participant>>(
          stream: ref.watch(userRepositoryProvider).getRealTimeMembers(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
            }
            final members = snapshot.data ?? [];
            if (members.isEmpty) {
              return const SizedBox(
                height: 50,
                child: Center(child: Text('No recent activity', style: TextStyle(color: Colors.white38))),
              );
            }
            
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
              border: Border.all(color: _gold.withValues(alpha: 0.3)),
            ),
            child: Builder(
              builder: (context) {
                final String? imageUrl = member.profileImage;
                return CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  backgroundImage: (imageUrl != null && imageUrl.isNotEmpty)
                    ? CachedNetworkImageProvider(imageUrl) 
                    : null,
                  child: (imageUrl == null || imageUrl.isEmpty)
                    ? Text(member.name.isNotEmpty ? member.name[0] : 'U', style: const TextStyle(color: Colors.white, fontSize: 14))
                    : null,
                );
              }
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
            Builder(
              builder: (context) {
                final String? imageUrl = member.profileImage;
                return CircleAvatar(
                  radius: 40,
                  backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
                  child: imageUrl == null ? const Icon(Icons.person, size: 40, color: Colors.white54) : null,
                );
              }
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
          decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
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
        color: Colors.white.withValues(alpha: 0.05),
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
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
                fillColor: Colors.white.withValues(alpha: 0.05),
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
          color: isMe ? _gold : Colors.white.withValues(alpha: 0.1),
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

  @override
  void dispose() {
    _brandingNameController.dispose();
    super.dispose();
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
                          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
                          filled: true,
                          fillColor: Colors.white.withValues(alpha: 0.05),
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
                              Uint8List? compressed;
                              try {
                                compressed = await FlutterImageCompress.compressWithList(
                                  bytes,
                                  minWidth: 512,
                                  minHeight: 512,
                                  quality: 70,
                                );
                              } catch (e) {
                                debugPrint('Branding Logo compression error: $e');
                              }
                              setState(() {
                                _brandingLogo = image;
                                _brandingLogoBytes = compressed ?? bytes;
                              });
                            }
                          },
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
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
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28), // Premium rounded corners matching Event Home
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AdminSpeakerList extends ConsumerWidget {
  final String eventId;
  final Function(Speaker) onEdit;
  final Function(Speaker) onDelete;

  const AdminSpeakerList({
    super.key,
    required this.eventId,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return StreamBuilder<List<Speaker>>(
      stream: ref.watch(speakerRepositoryProvider).watchSpeakers(eventId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                ],
              ),
            ),
          );
        }

        final speakers = snapshot.data ?? [];
        
        if (speakers.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mic_none, size: 64, color: Colors.white.withValues(alpha: 0.1)),
                  const SizedBox(height: 16),
                  Text(
                    'No speakers yet',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Click "Add Speaker" to create one',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.2), fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        }
        
        return ListView.builder(
          itemCount: speakers.length,
          itemBuilder: (context, index) {
            final speaker = speakers[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: Colors.white12,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: speaker.imageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: speaker.imageUrl,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.white12),
                              errorWidget: (_, __, ___) => const Icon(Icons.mic, color: Colors.white),
                            )
                          : const Icon(Icons.mic, color: Colors.white),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(speaker.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('${speaker.role} • ${speaker.bio}', maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.white54, fontSize: 12)),
                      ],
                    ),
                  ),
                  PopupMenuButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white38),
                    itemBuilder: (context) => [
                      PopupMenuItem(child: const Text('Edit'), onTap: () => Future.delayed(Duration.zero, () => onEdit(speaker))),
                      PopupMenuItem(child: const Text('Delete', style: TextStyle(color: Colors.red)), 
                        onTap: () => onDelete(speaker)),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
