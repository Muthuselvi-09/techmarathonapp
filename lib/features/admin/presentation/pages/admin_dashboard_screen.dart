import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/app_icons.dart';
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
import 'package:flutter/foundation.dart' hide Category; // for kIsWeb
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import '../../../home/presentation/providers/branding_provider.dart';
import '../widgets/admin_sidebar.dart';
import 'admin_entry_management_screen.dart';
 
class AdminDashboardScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const AdminDashboardScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentTab; // 0: Overview, 1: Events, 2: Members, 3: Speakers, 4: Sponsors, 5: Schedules, 6: Chat, 7: Branding

  // Branding state
  XFile? _brandingLogo;
  Uint8List? _brandingLogoBytes;
  bool _isSavingBranding = false;
  bool _isDeletingBranding = false;
  final TextEditingController _brandingNameController = TextEditingController();

  // Splash Screen state
  final TextEditingController _splashTextController = TextEditingController();
  String _splashAnimationType = 'scale';
  XFile? _splashImage;
  Uint8List? _splashImageBytes;

  // Onboarding Screen state
  // Profile Actions state
  List<TextEditingController> _profileActionTitles = [];
  List<IconData> _profileActionIcons = [];
  List<String> _profileActionTypes = [];
  List<String> _profileActionValues = [];
  bool _isSavingProfile = false;


  @override
  void initState() {
    super.initState();
    _currentTab = widget.initialTab;
  }

  @override
  void dispose() {
    _brandingNameController.dispose();
    _splashTextController.dispose();
    super.dispose();
  }

  // Gold + Black Theme Constants
  final Color _gold = const Color(0xFFFFD700);
  final Color _darkBg = const Color(0xFF121212); // Deep Black/Grey

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 1100;
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: Colors.black,
          drawer: isNarrow ? Drawer(
            width: 280,
            backgroundColor: Colors.black,
            child: AdminSidebar(
              currentIndex: _currentTab,
              onTabSelected: (index) {
                setState(() => _currentTab = index);
                _scaffoldKey.currentState?.closeDrawer();
              },
              onBack: () => context.pop(),
            ),
          ) : null,
          body: Row(
            children: [
              if (!isNarrow)
                AdminSidebar(
                  currentIndex: _currentTab,
                  onTabSelected: (index) => setState(() => _currentTab = index),
                  onBack: () => context.pop(),
                ),
              Expanded(
                child: Column(
                  children: [
                    _buildTopBar(isNarrow),
                    Expanded(
                      child: AnimatedSwitcher(
                        duration: 400.ms,
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        child: KeyedSubtree(
                          key: ValueKey(_currentTab),
                          child: _buildCurrentSection(isNarrow),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTopBar(bool isNarrow) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 32, vertical: isNarrow ? 16 : 24),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(bottom: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          if (isNarrow) ...[
            if (_currentTab == 0)
              _iconButton(Icons.menu_rounded, () => _scaffoldKey.currentState?.openDrawer())
            else
              _iconButton(Icons.arrow_back_rounded, () => setState(() => _currentTab = 0)),
            const SizedBox(width: 16),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTabTitle(_currentTab),
                  style: GoogleFonts.outfit(
                    fontSize: isNarrow ? 20 : 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (!isNarrow) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Manage your tech marathon platform',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: Colors.white38,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          _iconButton(Icons.notifications_none_rounded, () {}),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _showAdminProfile(),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _gold, width: 1.5),
              ),
              child: CircleAvatar(
                radius: isNarrow ? 16 : 18,
                backgroundColor: AppColors.surface,
                child: Icon(Icons.person, size: isNarrow ? 18 : 20, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTabTitle(int index) {
    switch (index) {
      case 0: return 'Overview';
      case 1: return 'Events';
      case 2: return 'Members';
      case 3: return 'Speakers';
      case 4: return 'Sponsors';
      case 5: return 'Schedules';
      case 6: return 'Chat';
      case 7: return 'Branding';
      case 8: return 'Profile';
      default: return 'Admin Panel';
    }
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


  Widget _buildCurrentSection(bool isNarrow) {
    switch (_currentTab) {
      case 0: return _buildOverview(isNarrow);
      case 1: return _buildEventsSection(isNarrow);
      case 2: return _buildMembersSection(isNarrow);
      case 3: return _buildSpeakersSection(isNarrow);
      case 4: return _buildSponsorsSection(isNarrow);
      case 5: return _buildSchedulesSection(isNarrow);
      case 6: return _buildChatSection(isNarrow);
      case 7: return _buildBrandingSection(isNarrow);
      case 8: return _buildProfileSection(isNarrow);
      default: return _buildOverview(isNarrow);
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
  Widget _buildOverview(bool isNarrow) {
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 32, vertical: 24),
      children: [
        if (isNarrow) ...[
          _buildHeroModule(isNarrow),
          const SizedBox(height: 24),
          _buildLiveAttendanceModule(isNarrow),
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildHeroModule(isNarrow)),
              const SizedBox(width: 24),
              Expanded(flex: 1, child: _buildLiveAttendanceModule(isNarrow)),
            ],
          ),
        const SizedBox(height: 32),
        _buildTimelineModule(isNarrow),
        const SizedBox(height: 32),
        _buildSystemActionsModule(isNarrow),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildHeroModule(bool isNarrow) {
    final adminRepo = ref.watch(adminRepositoryProvider);
    return StreamBuilder<List<CodingEvent>>(
      stream: adminRepo.watchEvents(),
      builder: (context, snapshot) {
        final totalEvents = snapshot.data?.length ?? 0;
        final revenue = totalEvents * 1500;

        return _GlassCard(
          padding: EdgeInsets.all(isNarrow ? 20 : 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'REVENUE ANALYTICS',
                    style: GoogleFonts.outfit(
                      color: Colors.white30,
                      fontSize: 12,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00FF94).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF00FF94).withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'LIVE +12.5%',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF00FF94),
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    '₹$revenue',
                    style: GoogleFonts.outfit(
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      color: _gold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'total earnings',
                    style: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  _statBadge(Icons.confirmation_number_outlined, '$totalEvents Active Events', Colors.blueAccent),
                  const SizedBox(width: 16),
                  _statBadge(Icons.analytics_outlined, '4.2k Attendees', Colors.purpleAccent),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLiveAttendanceModule(bool isNarrow) {
    final userRepo = ref.watch(userRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _moduleHeader('Live Presence', Icons.sensors_rounded, const Color(0xFF00FF94)),
        const SizedBox(height: 16),
        StreamBuilder<int>(
          stream: userRepo.watchOnlineUsersCount(),
          initialData: 0,
          builder: (context, snapshot) {
            final onlineCount = snapshot.data ?? 0;
            return _GlassCard(
              padding: EdgeInsets.all(isNarrow ? 20 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$onlineCount',
                            style: GoogleFonts.outfit(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Active Users',
                            style: GoogleFonts.outfit(
                              color: Colors.white38,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.trending_up_rounded, color: Color(0xFF00FF94), size: 24),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: (onlineCount / 100).clamp(0.0, 1.0),
                      backgroundColor: Colors.white.withValues(alpha: 0.05),
                      valueColor: AlwaysStoppedAnimation(_gold),
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Peak today: 84 users',
                    style: GoogleFonts.outfit(
                      color: Colors.white24,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTimelineModule(bool isNarrow) {
    final adminRepo = ref.watch(adminRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _moduleHeader('Event Timeline', Icons.calendar_today_rounded, _gold),
        const SizedBox(height: 16),
        StreamBuilder<List<CodingEvent>>(
          stream: adminRepo.watchEvents(),
          builder: (context, snapshot) {
            final events = snapshot.data ?? [];
            if (events.isEmpty) {
              return _GlassCard(
                child: Center(
                  child: Text(
                    'No active events scheduled',
                    style: GoogleFonts.outfit(color: Colors.white24),
                  ),
                ),
              );
            }
            
            return SizedBox(
              height: 180,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Container(
                    width: 320,
                    margin: const EdgeInsets.only(right: 20),
                    child: _GlassCard(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: _gold.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatDate(event.date).toUpperCase(),
                                  style: GoogleFonts.outfit(
                                    color: _gold,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white24, size: 14),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            event.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, color: Colors.white24, size: 14),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  event.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white38,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
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
          color: color.withValues(alpha: isDarkText ? 1.0 : 0.15),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: isDarkText ? 0.0 : 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isDarkText ? Colors.black : color, size: 24),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: isDarkText ? Colors.black : color, fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
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
  Widget _buildEventsSection(bool isNarrow) {
    final adminRepo = ref.watch(adminRepositoryProvider);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNarrow)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('EVENT MANAGEMENT', 'Create and organize your events'),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                     OutlinedButton.icon(
                      onPressed: () => _showManageCategoriesDialog(),
                      icon: const Icon(Icons.category_outlined, size: 18),
                      label: Text('CATEGORIES', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _gold,
                        side: BorderSide(color: _gold.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showEventDialog(),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text('NEW EVENT', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'EVENT MANAGEMENT',
                        style: GoogleFonts.outfit(
                          color: Colors.white30,
                          fontSize: 12,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create and organize your events',
                        style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.end,
                    children: [
                       OutlinedButton.icon(
                        onPressed: () => _showManageCategoriesDialog(),
                        icon: const Icon(Icons.category_outlined, size: 18),
                        label: Text('CATEGORIES', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _gold,
                          side: BorderSide(color: _gold.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showEventDialog(),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text('NEW EVENT', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 40),
          Expanded(
            child: StreamBuilder<List<CodingEvent>>(
              stream: adminRepo.watchEvents(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                if (snapshot.data!.isEmpty) return const Center(child: Text('No events found', style: TextStyle(color: Colors.white38)));
                
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

  void _showManageCategoriesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Manage Categories', style: TextStyle(color: Colors.white)),
            ElevatedButton.icon(
              onPressed: () => _showCategoryDialog(),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<List<Category>>(
            stream: ref.watch(adminRepositoryProvider).watchCategories(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
              final categories = snapshot.data!;
              if (categories.isEmpty) return const Center(child: Text('No categories found', style: TextStyle(color: Colors.white38)));

              return ListView.builder(
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return _categoryItem(category);
                },
              );
            },
          ),
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

  Widget _eventItem(CodingEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: _GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                image: event.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(event.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              ),
              child: event.imageUrl.isEmpty 
                ? const Icon(Icons.event_available_rounded, color: AppColors.codingRimPrimary, size: 24) 
                : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white24, size: 14),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _iconButton(Icons.qr_code_2_rounded, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => AdminEntryManagementScreen(event: event),
                ),
              );
            }),
            const SizedBox(width: 8),
            _iconButton(Icons.edit_outlined, () => _showEventDialog(event: event)),
            const SizedBox(width: 8),
            _iconButton(Icons.delete_outline_rounded, () => ref.read(adminRepositoryProvider).deleteEvent(event.id)),
          ],
        ),
      ),
    );
  }

  void _showEventDialog({CodingEvent? event}) {
    final titleController = TextEditingController(text: event?.name);
    final locationController = TextEditingController(text: event?.location);
    final descController = TextEditingController(text: event?.description);
    final feeController = TextEditingController(text: event?.entryFee.toString());
    final currencyController = TextEditingController(text: event?.currency ?? '₹');
    final entryTimingController = TextEditingController(text: event?.entryTiming);
    List<String> rules = List<String>.from(event?.rules ?? []);
    
    XFile? selectedImage;
    String? currentImageUrl = event?.imageUrl;
    String? selectedCategoryId = event?.categoryId;
    bool isFree = event?.isFree ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          final categoriesAsync = ref.watch(adminRepositoryProvider).watchCategories();

          return AlertDialog(
            backgroundColor: AppColors.surface,
            title: Text(event == null ? 'New Event' : 'Edit Event', style: const TextStyle(color: Colors.white)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  
                  const SizedBox(height: 16),
                  const Text('Category', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  StreamBuilder<List<Category>>(
                    stream: ref.watch(adminRepositoryProvider).watchCategories(),
                    builder: (context, snapshot) {
                      final categoriesList = snapshot.data ?? [];
                      final categories = categoriesList.where((c) => c.isEnabled).toList();
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedCategoryId,
                              dropdownColor: AppColors.surface,
                              style: const TextStyle(color: Colors.white),
                              decoration: const InputDecoration(
                                hintText: 'Select Category',
                                hintStyle: TextStyle(color: Colors.white24),
                              ),
                              items: categories.map((cat) => DropdownMenuItem<String>(
                                value: cat.id,
                                child: Text(cat.name),
                              )).toList(),
                              onChanged: (val) => setState(() => selectedCategoryId = val),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () => _showCategoryDialog(),
                            icon: Icon(Icons.add_circle_outline, color: _gold),
                            tooltip: 'Add New Category',
                          ),
                        ],
                      );
                    },
                  ),

                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Free Event', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      Switch(
                        value: isFree,
                        onChanged: (val) => setState(() => isFree = val),
                        activeThumbColor: _gold,
                      ),
                    ],
                  ),
                  if (!isFree) ...[
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: currencyController,
                            decoration: const InputDecoration(labelText: 'Currency'),
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: feeController,
                            decoration: const InputDecoration(labelText: 'Entry Fee'),
                            keyboardType: TextInputType.number,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 16),
                  TextField(controller: descController, decoration: const InputDecoration(labelText: 'Description'), style: const TextStyle(color: Colors.white), maxLines: 3),
                  
                  const SizedBox(height: 16),
                  TextField(controller: entryTimingController, decoration: const InputDecoration(labelText: 'Entry Timing (e.g. Registration opens at 8:00 AM)'), style: const TextStyle(color: Colors.white)),
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Rules & Instructions', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
                      IconButton(
                        onPressed: () => setState(() => rules.add('')),
                        icon: Icon(Icons.add_circle_outline, color: _gold),
                      ),
                    ],
                  ),
                  ...rules.asMap().entries.map((entry) {
                    final index = entry.key;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              initialValue: entry.value,
                              decoration: InputDecoration(hintText: 'Rule ${index + 1}', hintStyle: const TextStyle(color: Colors.white24)),
                              style: const TextStyle(color: Colors.white, fontSize: 13),
                              onChanged: (val) => rules[index] = val,
                            ),
                          ),
                          IconButton(
                            onPressed: () => setState(() => rules.removeAt(index)),
                            icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context), 
                child: const Text('Cancel')
              ),
              ElevatedButton(
                onPressed: () async {
                   if (titleController.text.isEmpty) return;
                   
                   final price = double.tryParse(feeController.text) ?? 0.0;
                   
                   // Fetch category name for backward compatibility
                   String catName = '';
                   if (selectedCategoryId != null) {
                     final repo = ref.read(adminRepositoryProvider);
                     // This is a bit slow for a sync callback, but we need it for 'category' string field
                     // Alternatively, we just save without it and let it be empty or placeholder.
                     // The prompt said "Decide which event belongs to which category"
                   }

                   final repo = ref.read(adminRepositoryProvider);
                   final categories = await repo.watchCategories().first;
                   catName = categories.firstWhere((c) => c.id == selectedCategoryId, orElse: () => Category(id: '', name: 'All')).name;

                   final optimisticEvent = CodingEvent(
                     id: event?.id ?? 'temp_${DateTime.now().millisecondsSinceEpoch}',
                     name: titleController.text,
                     location: locationController.text,
                     category: catName, // Preserving name
                     categoryId: selectedCategoryId,
                     isFree: isFree,
                     entryFee: isFree ? 0.0 : price,
                     currency: currencyController.text,
                     description: descController.text,
                     date: event?.date ?? DateTime.now(),
                     speakerIds: event?.speakerIds ?? [],
                     imageUrl: currentImageUrl ?? 'https://images.unsplash.com/photo-1540575467063-178a50c2df87',
                     entryTiming: entryTimingController.text,
                     rules: rules.where((r) => r.trim().isNotEmpty).toList(),
                   );

                   if (event == null) {
                     ref.read(optimisticEventsProvider.notifier).addEvent(optimisticEvent);
                   } else {
                     ref.read(optimisticEventsProvider.notifier).updateEvent(optimisticEvent);
                   }

                   Navigator.pop(context);

                   ref.read(adminRepositoryProvider).saveEvent(
                     optimisticEvent,
                     isNew: event == null,
                     imageFile: selectedImage,
                   );

                   Future.delayed(const Duration(seconds: 3), () {
                     ref.read(optimisticEventsProvider.notifier).removeEvent(optimisticEvent.id);
                   });
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- 3. MEMBERS SECTION (Real-time) ---
  Widget _buildMembersSection(bool isNarrow) {
    final userRepo = ref.watch(userRepositoryProvider);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('USER MANAGEMENT', 'View and manage platform participants'),
          const SizedBox(height: 40),
          Expanded(
            child: StreamBuilder<List<Participant>>(
              stream: userRepo.getRealTimeMembers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.codingRimPrimary));
                if (snapshot.data!.isEmpty) {
                  return _emptySection(Icons.people_outline_rounded, 'No one has joined yet');
                }
                
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    final member = snapshot.data![index];
                    return _memberItem(member);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }



  // --- 4. SPEAKERS SECTION ---
  Widget _buildSpeakersSection(bool isNarrow) {
    final adminRepo = ref.watch(adminRepositoryProvider);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNarrow)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('SPEAKERS & GUESTS', 'Manage event speakers and their assignments'),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showSpeakerDialog(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text('ADD SPEAKER', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _sectionHeader('SPEAKERS & GUESTS', 'Manage event speakers and their assignments'),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSpeakerDialog(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text('ADD SPEAKER', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 40),
          Expanded(
            child: StreamBuilder<List<Speaker>>(
              stream: adminRepo.watchAllSpeakers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.codingRimPrimary));
                if (snapshot.data!.isEmpty) return _emptySection(Icons.mic_none_rounded, 'No speakers added yet');
                
                return ListView.builder(
                  itemCount: snapshot.data!.length,
                  itemBuilder: (context, index) {
                    return _speakerItem(snapshot.data![index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _selectedSpeakerEventId; // Event ID state for speakers
  String? _selectedSponsorEventId; // Event ID state for sponsors

  Widget _speakerItem(Speaker speaker) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: _GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                image: speaker.photoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(speaker.photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              ),
              child: speaker.photoUrl.isEmpty 
                ? const Icon(Icons.mic_none_rounded, color: AppColors.codingRimPrimary, size: 24) 
                : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    speaker.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${speaker.topic} • ${speaker.company}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _iconButton(Icons.edit_outlined, () => _showSpeakerDialog(speaker: speaker)),
            const SizedBox(width: 8),
            _iconButton(Icons.delete_outline_rounded, () => ref.read(adminRepositoryProvider).deleteSpeaker(speaker.eventId, speaker.id)),
          ],
        ),
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
  Widget _buildSponsorsSection(bool isNarrow) {
    final adminRepo = ref.watch(adminRepositoryProvider);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNarrow)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('SPONSOR PARTNERS', 'Maintain and organize platform sponsors'),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showSponsorDialog(),
                  icon: const Icon(Icons.add_rounded, size: 20),
                  label: Text('ADD SPONSOR', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _sectionHeader('SPONSOR PARTNERS', 'Maintain and organize platform sponsors'),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () => _showSponsorDialog(),
                    icon: const Icon(Icons.add_rounded, size: 20),
                    label: Text('ADD SPONSOR', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 40),
          Expanded(
            child: StreamBuilder<List<Sponsor>>(
              stream: adminRepo.watchAllSponsors(),
              builder: (context, snapshot) {
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.codingRimPrimary));
                 
                 final allSponsors = snapshot.data!;
                 if (allSponsors.isEmpty) {
                    return _emptySection(Icons.business_outlined, 'No sponsors added yet');
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
      margin: const EdgeInsets.only(bottom: 20),
      child: _GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                image: sponsor.logoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(sponsor.logoUrl),
                      fit: BoxFit.contain,
                    )
                  : null,
              ),
              child: sponsor.logoUrl.isEmpty 
                ? const Icon(Icons.business_outlined, color: Colors.black54, size: 24) 
                : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sponsor.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${sponsor.tier.toUpperCase()} • Active Partner',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
            _iconButton(Icons.edit_outlined, () => _showSponsorDialog(sponsor: sponsor)),
            const SizedBox(width: 8),
            _iconButton(Icons.delete_outline_rounded, () => ref.read(adminRepositoryProvider).deleteSponsor(sponsor.eventId, sponsor.id)),
          ],
        ),
      ),
    );
  }
  void _showSponsorDialog({Sponsor? sponsor, String? eventId}) {
    final nameController = TextEditingController(text: sponsor?.name);
    final companyController = TextEditingController(text: sponsor?.company);
    final roleController = TextEditingController(text: sponsor?.jobPosition);
    final taglineController = TextEditingController(text: sponsor?.tagline);
    final websiteController = TextEditingController(text: sponsor?.websiteUrl);
    final descriptionController = TextEditingController(text: sponsor?.detailedDescription ?? sponsor?.description);
    final boothLocationController = TextEditingController(text: sponsor?.boothLocation);
    final instagramController = TextEditingController(text: sponsor?.instagramUrl);
    final linkedinController = TextEditingController(text: sponsor?.linkedinUrl);
    final youtubeController = TextEditingController(text: sponsor?.youtubeUrl);
    
    String tier = sponsor?.tier ?? 'Gold';
    String? selectedEventId = eventId ?? sponsor?.eventId;
    
    XFile? logoImage;
    XFile? bannerImage;
    String? currentLogoUrl = sponsor?.logoUrl;
    String? currentBannerUrl = sponsor?.bannerUrl;
    bool isUploadingMedia = false;
    
    // Local mutable state for lists
    final List<Map<String, dynamic>> tempOffers = List.from(sponsor?.offers ?? []);
    final List<Map<String, dynamic>> tempProducts = List.from(sponsor?.products ?? []);
    final List<String> tempMedia = List.from(sponsor?.media ?? []);

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
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('Logo', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 70,
                                maxWidth: 1080,
                                maxHeight: 1080,
                              );
                              if (image != null) setState(() => logoImage = image);
                            },
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(12),
                                image: logoImage != null
                                    ? DecorationImage(
                                        image: kIsWeb ? NetworkImage(logoImage!.path) : FileImage(File(logoImage!.path)) as ImageProvider,
                                        fit: BoxFit.contain,
                                      )
                                    : (currentLogoUrl != null && currentLogoUrl!.isNotEmpty)
                                        ? DecorationImage(image: NetworkImage(currentLogoUrl!), fit: BoxFit.contain)
                                        : null,
                              ),
                              child: logoImage == null && (currentLogoUrl == null || currentLogoUrl!.isEmpty) ? const Icon(Icons.add_photo_alternate, color: Colors.white54) : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: [
                          const Text('Banner', style: TextStyle(color: Colors.white70, fontSize: 12)),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: () async {
                              final picker = ImagePicker();
                              final image = await picker.pickImage(
                                source: ImageSource.gallery,
                                imageQuality: 75,
                                maxWidth: 1080,
                                maxHeight: 1080,
                              );
                              if (image != null) setState(() => bannerImage = image);
                            },
                            child: Container(
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.white12,
                                borderRadius: BorderRadius.circular(12),
                                image: bannerImage != null
                                    ? DecorationImage(
                                        image: kIsWeb ? NetworkImage(bannerImage!.path) : FileImage(File(bannerImage!.path)) as ImageProvider,
                                        fit: BoxFit.cover,
                                      )
                                    : (currentBannerUrl != null && currentBannerUrl!.isNotEmpty)
                                        ? DecorationImage(image: NetworkImage(currentBannerUrl!), fit: BoxFit.cover)
                                        : null,
                              ),
                              child: bannerImage == null && (currentBannerUrl == null || currentBannerUrl!.isEmpty) ? const Icon(Icons.image, color: Colors.white54) : null,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<List<CodingEvent>>(
                  stream: ref.watch(adminRepositoryProvider).watchEvents(),
                  builder: (context, snapshot) {
                    final events = snapshot.data ?? [];
                    return DropdownButtonFormField<String>(
                      value: (events.any((e) => e.id == selectedEventId)) ? selectedEventId : null,
                      dropdownColor: const Color(0xFF1E1E1E),
                      decoration: const InputDecoration(labelText: 'Link to Event (Optional)'),
                      style: const TextStyle(color: Colors.white),
                      items: events
                          .map((e) => DropdownMenuItem(
                                value: e.id,
                                child: Text(e.name, style: const TextStyle(color: Colors.white)),
                              ))
                          .toList(),
                      onChanged: (val) => setState(() => selectedEventId = val),
                    );
                  },
                ),
                DropdownButtonFormField<String>(
                  value: tier,
                  dropdownColor: const Color(0xFF1E1E1E),
                  decoration: const InputDecoration(labelText: 'Sponsorship Tier'),
                  style: const TextStyle(color: Colors.white),
                  items: ['Platinum', 'Gold', 'Silver', 'Bronze']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t, style: const TextStyle(color: Colors.white))))
                      .toList(),
                  onChanged: (val) => setState(() => tier = val!),
                ),
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Sponsor Name'), style: const TextStyle(color: Colors.white)),
                TextField(controller: taglineController, decoration: const InputDecoration(labelText: 'Tagline'), style: const TextStyle(color: Colors.white)),
                TextField(controller: companyController, decoration: const InputDecoration(labelText: 'Company'), style: const TextStyle(color: Colors.white)),
                TextField(controller: roleController, decoration: const InputDecoration(labelText: 'Role / Position'), style: const TextStyle(color: Colors.white)),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Detailed Description'), style: const TextStyle(color: Colors.white), maxLines: 3),
                TextField(controller: boothLocationController, decoration: const InputDecoration(labelText: 'Booth/Stall Location (e.g. B12)'), style: const TextStyle(color: Colors.white)),
                TextField(controller: websiteController, decoration: const InputDecoration(labelText: 'Website URL'), style: const TextStyle(color: Colors.white)),
                const SizedBox(height: 24),
                
                // Offers Management
                _dialogSectionHeader('Offers & Deals'),
                const SizedBox(height: 8),
                ...List.generate(tempOffers.length, (i) {
                  final offer = tempOffers[i];
                  return Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(child: Text(offer['title'] ?? 'Offer', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                          onPressed: () => setState(() => tempOffers.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => _showAddOfferDialog(context, (newOffer) => setState(() => tempOffers.add(newOffer))),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Add New Offer', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(iconColor: _gold, foregroundColor: _gold),
                ),
                
                const SizedBox(height: 16),
                const SizedBox(height: 16),
                _dialogSectionHeader('Products & Services'),
                const SizedBox(height: 8),
                ...List.generate(tempProducts.length, (i) {
                  final p = tempProducts[i];
                  return Container(
                    padding: const EdgeInsets.all(8),
                    margin: const EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Expanded(child: Text(p['name'] ?? 'Product', style: const TextStyle(color: Colors.white70, fontSize: 12))),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red, size: 16),
                          onPressed: () => setState(() => tempProducts.removeAt(i)),
                        ),
                      ],
                    ),
                  );
                }),
                TextButton.icon(
                  onPressed: () => _showAddProductDialog(context, (newProduct) => setState(() => tempProducts.add(newProduct))),
                  icon: const Icon(Icons.add_circle_outline, size: 16),
                  label: const Text('Add New Product', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(iconColor: _gold, foregroundColor: _gold),
                ),

                const SizedBox(height: 16),
                _dialogSectionHeader('Media Gallery'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ...List.generate(tempMedia.length, (i) {
                      return Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              image: DecorationImage(image: NetworkImage(tempMedia[i]), fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            right: -8,
                            top: -8,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red, size: 18),
                              onPressed: () => setState(() => tempMedia.removeAt(i)),
                            ),
                          ),
                        ],
                      );
                    }),
                    GestureDetector(
                      onTap: isUploadingMedia ? null : () async {
                        final picker = ImagePicker();
                        final image = await picker.pickImage(
                          source: ImageSource.gallery, 
                          imageQuality: 70,
                          maxWidth: 1080,
                          maxHeight: 1080,
                        );
                        if (image != null) {
                          setState(() => isUploadingMedia = true);
                          try {
                            // Show loading feedback
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Uploading media...'), duration: Duration(seconds: 1)),
                            );
                            
                            final bytes = await image.readAsBytes();
                            final url = await ref.read(adminRepositoryProvider).uploadToCloudinary(bytes, folder: 'sponsors/media');
                            
                            setState(() {
                              tempMedia.add(url);
                              isUploadingMedia = false;
                            });
                          } catch (e) {
                            setState(() => isUploadingMedia = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                          }
                        }
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.white10, 
                          borderRadius: BorderRadius.circular(8), 
                          border: Border.all(color: Colors.white24, style: BorderStyle.solid),
                        ),
                        child: isUploadingMedia 
                            ? const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFFD700))))
                            : const Icon(Icons.add_a_photo, color: Colors.white38, size: 20),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
                  return;
                }
                
                final optimisticSponsor = Sponsor(
                  id: sponsor?.id ?? '',
                  name: nameController.text.trim(),
                  company: companyController.text.trim(),
                  jobPosition: roleController.text.trim(),
                  tier: tier,
                  logoUrl: currentLogoUrl ?? '',
                  bannerUrl: currentBannerUrl ?? '',
                  tagline: taglineController.text.trim(),
                  websiteUrl: websiteController.text.trim(),
                  detailedDescription: descriptionController.text.trim(),
                  boothLocation: boothLocationController.text.trim(),
                  instagramUrl: instagramController.text.trim(),
                  linkedinUrl: linkedinController.text.trim(),
                  youtubeUrl: youtubeController.text.trim(),
                  eventId: selectedEventId ?? '',
                  offers: tempOffers,
                  products: tempProducts,
                  media: tempMedia,
                );

                Navigator.pop(context);
                
                await ref.read(adminRepositoryProvider).saveSponsor(
                      optimisticSponsor,
                      eventId: selectedEventId,
                      isNew: sponsor == null,
                      logoFile: logoImage,
                      bannerFile: bannerImage,
                    );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: _gold,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save Sponsor', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Row(
        children: [
          Container(width: 4, height: 16, color: _gold),
          const SizedBox(width: 8),
          Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
        ],
      ),
    );
  }

  void _showAddOfferDialog(BuildContext context, Function(Map<String, dynamic>) onAdd) {
    final titleC = TextEditingController();
    final descC = TextEditingController();
    final codeC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Offer', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleC, decoration: const InputDecoration(labelText: 'Title'), style: const TextStyle(color: Colors.white)),
            TextField(controller: descC, decoration: const InputDecoration(labelText: 'Description'), style: const TextStyle(color: Colors.white)),
            TextField(controller: codeC, decoration: const InputDecoration(labelText: 'Promo Code'), style: const TextStyle(color: Colors.white)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onAdd({'title': titleC.text, 'description': descC.text, 'code': codeC.text});
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog(BuildContext context, Function(Map<String, dynamic>) onAdd) {
    final nameC = TextEditingController();
    final descC = TextEditingController();
    XFile? selectedImage;
    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          title: const Text('Add Product/Service', style: TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              GestureDetector(
                onTap: () async {
                  final picker = ImagePicker();
                  final image = await picker.pickImage(
                    source: ImageSource.gallery, 
                    imageQuality: 70,
                    maxWidth: 1080,
                    maxHeight: 1080,
                  );
                  if (image != null) setState(() => selectedImage = image);
                },
                child: Container(
                  height: 100,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white12,
                    borderRadius: BorderRadius.circular(12),
                    image: selectedImage != null
                        ? DecorationImage(
                            image: kIsWeb ? NetworkImage(selectedImage!.path) : FileImage(File(selectedImage!.path)) as ImageProvider,
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: selectedImage == null
                      ? const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate, color: Colors.white54, size: 32),
                            SizedBox(height: 8),
                            Text('Tap to upload image', style: TextStyle(color: Colors.white54, fontSize: 12)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Name'), style: const TextStyle(color: Colors.white)),
              TextField(controller: descC, decoration: const InputDecoration(labelText: 'Short Description'), style: const TextStyle(color: Colors.white)),
              if (isUploading) ...[
                const SizedBox(height: 16),
                const LinearProgressIndicator(color: Color(0xFFFFD700)),
                const SizedBox(height: 8),
                const Text('Uploading image...', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ],
          ),
          actions: [
            if (!isUploading) TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isUploading ? null : () async {
                if (nameC.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a name')));
                  return;
                }
                
                String imageUrl = '';
                if (selectedImage != null) {
                  setState(() => isUploading = true);
                  try {
                    final bytes = await selectedImage!.readAsBytes();
                    imageUrl = await ref.read(adminRepositoryProvider).uploadToCloudinary(bytes, folder: 'sponsors/products');
                  } catch (e) {
                    setState(() => isUploading = false);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
                    return;
                  }
                }

                onAdd({'name': nameC.text, 'desc': descC.text, 'image': imageUrl});
                if (context.mounted) Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFD700), foregroundColor: Colors.black),
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddMediaUrlDialog(BuildContext context, Function(String) onAdd) {
    final urlC = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Add Gallery Image URL', style: TextStyle(color: Colors.white)),
        content: TextField(controller: urlC, decoration: const InputDecoration(hintText: 'https://...', labelText: 'Image URL'), style: const TextStyle(color: Colors.white)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              onAdd(urlC.text);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  // --- 6. SCHEDULES SECTION ---
  Widget _buildSchedulesSection(bool isNarrow) {
    final adminRepo = ref.watch(adminRepositoryProvider);
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNarrow)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('EVENT SCHEDULES', 'Organize and manage session timings'),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: () => _showScheduleDialog(),
                  icon: const Icon(Icons.event_available_rounded, size: 20),
                  label: Text('NEW SESSION', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.black)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _sectionHeader('EVENT SCHEDULES', 'Organize and manage session timings'),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: ElevatedButton.icon(
                    onPressed: () => _showScheduleDialog(),
                    icon: const Icon(Icons.event_available_rounded, size: 20),
                    label: Text('NEW SESSION', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.black)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 40),
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
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.codingRimPrimary));
                    if (snapshot.data!.isEmpty) return _emptySection(Icons.schedule_rounded, 'No schedules yet');
                    
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
      margin: const EdgeInsets.only(bottom: 20),
      child: _GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.schedule_rounded, color: AppColors.codingRimPrimary, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.title,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                        style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _gold.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _gold.withValues(alpha: 0.2)),
                        ),
                        child: Text(
                          eventName,
                          style: GoogleFonts.outfit(color: _gold, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _iconButton(Icons.edit_outlined, () => _showScheduleDialog(schedule: schedule)),
            const SizedBox(width: 8),
            _iconButton(Icons.delete_outline_rounded, () => ref.read(adminRepositoryProvider).deleteSchedule(schedule.eventId, schedule.id)),
          ],
        ),
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
                            value: (snapshot.data!.any((e) => e.id == selectedEventId)) ? selectedEventId : null,
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
  Widget _buildChatSection(bool isNarrow) {
    final chatRepo = ref.watch(adminChatRepositoryProvider);
    
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('USER INQUIRIES', 'Communicate with platform users in real-time'),
          const SizedBox(height: 40),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: chatRepo.watchAllChats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.codingRimPrimary));
                if (snapshot.data!.isEmpty) return _emptySection(Icons.chat_bubble_outline_rounded, 'No active chats');
                
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
      margin: const EdgeInsets.only(bottom: 20),
      child: _GlassCard(
        padding: const EdgeInsets.all(12),
        borderColor: hasUnread ? _gold.withValues(alpha: 0.3) : Colors.transparent,
        child: ListTile(
          onTap: () => _openAdminChatRoom(chat['userId'], chat['userName'] ?? 'User'),
          leading: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: hasUnread ? _gold : Colors.white12, width: 2),
            ),
            child: CircleAvatar(
              backgroundColor: Colors.white.withValues(alpha: 0.05),
              child: Text(
                chat['userName']?[0] ?? 'U',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          title: Text(
            chat['userName'] ?? 'User',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: hasUnread ? FontWeight.w900 : FontWeight.bold,
              fontSize: 16,
            ),
          ),
          subtitle: Text(
            chat['lastMessage'] ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              color: hasUnread ? Colors.white60 : Colors.white38,
              fontSize: 13,
            ),
          ),
          trailing: hasUnread 
            ? Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: _gold, shape: BoxShape.circle),
              ) 
            : const Icon(Icons.chevron_right_rounded, color: Colors.white24),
        ),
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
  Widget _buildSystemActionsModule(bool isNarrow) {
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
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: _GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _gold.withValues(alpha: 0.2)),
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    backgroundImage: member.profileImage != null && member.profileImage!.isNotEmpty 
                      ? NetworkImage(member.profileImage!) 
                      : null,
                    child: member.profileImage == null || member.profileImage!.isEmpty
                      ? Text(
                          member.name.isNotEmpty ? member.name[0] : 'U',
                          style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        )
                      : null,
                  ),
                ),
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: member.isOnline ? const Color(0xFF00FF94) : Colors.grey, 
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2.5),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    member.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    member.email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            _iconButton(Icons.mail_outline_rounded, () {}),
            const SizedBox(width: 8),
            _iconButton(Icons.more_vert_rounded, () {}),
          ],
        ),
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

  Widget _sectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: Colors.white30,
            fontSize: 12,
            letterSpacing: 2,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: GoogleFonts.outfit(color: Colors.white60, fontSize: 13),
        ),
      ],
    );
  }

  Widget _emptySection(IconData icon, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 80),
          Icon(icon, size: 64, color: Colors.white.withValues(alpha: 0.05)),
          const SizedBox(height: 24),
          Text(
            message,
            style: GoogleFonts.outfit(color: Colors.white24, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _statBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
    );
  }

  Widget _buildBrandingSection(bool isNarrow) {
    final brandingAsync = ref.watch(brandingProvider);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 40, vertical: 32),
      child: brandingAsync.when(
        loading: () => _buildBrandingForm(BrandingInfo(companyName: 'Event App'), isNarrow),
        error: (error, _) => _buildBrandingForm(BrandingInfo(companyName: 'Event App'), isNarrow),
        data: (branding) => _buildBrandingForm(branding, isNarrow),
      ),
    );
  }

  Widget _buildBrandingForm(BrandingInfo branding, bool isNarrow) {
    if (_brandingNameController.text.isEmpty && branding.companyName != 'Event App') {
      _brandingNameController.text = branding.companyName;
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader('BRANDING SETTINGS', 'Customize your platform appearance and identity'),
          const SizedBox(height: 40),
          _GlassCard(
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _gold.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.palette_outlined, color: _gold, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Identity & Visuals',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
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
                      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
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
                              Image.memory(_brandingLogoBytes!, fit: BoxFit.cover)
                            else if (branding.companyLogoUrl != null)
                              CachedNetworkImage(
                                imageUrl: branding.companyLogoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                              )
                            else
                              const Icon(Icons.add_photo_alternate_outlined, color: Colors.white24, size: 40),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                                ),
                              ),
                            ),
                            const Positioned(
                              bottom: 8,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: Text(
                                  'CHANGE LOGO',
                                  style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: ElevatedButton(
                    onPressed: _isSavingBranding ? null : () async {
                      setState(() => _isSavingBranding = true);
                      try {
                         final adminRepo = ref.read(adminRepositoryProvider);
                         String? logoUrl = branding.companyLogoUrl;
                         if (_brandingLogoBytes != null) {
                           logoUrl = await adminRepo.uploadToCloudinary(_brandingLogoBytes!, folder: 'branding');
                         }
                         await adminRepo.saveBranding(branding.copyWith(
                           companyName: _brandingNameController.text,
                           companyLogoUrl: logoUrl,
                         ));
                         if (mounted) {
                           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branding saved successfully!'), backgroundColor: Colors.green));
                           ref.invalidate(brandingProvider);
                         }
                      } catch (e) {
                         if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                      } finally {
                         if (mounted) setState(() => _isSavingBranding = false);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _gold,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isSavingBranding 
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text('SAVE BRANDING', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: _isDeletingBranding ? null : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Text('Reset Branding?', style: TextStyle(color: Colors.white)),
                          content: const Text(
                            'This will reset the Company Name and Logo to the default "EVENT APP". This action cannot be undone.',
                            style: TextStyle(color: Colors.white70),
                          ),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true), 
                              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                              child: const Text('Reset'),
                            ),
                          ],
                        ),
                      );

                      if (confirm == true) {
                        setState(() => _isDeletingBranding = true);
                        try {
                          await ref.read(adminRepositoryProvider).deleteBranding();
                          
                          if (mounted) {
                            _brandingNameController.clear();
                            setState(() {
                              _brandingLogo = null;
                              _brandingLogoBytes = null;
                            });
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Branding reset to default!'), backgroundColor: Colors.green));
                            ref.invalidate(brandingProvider); // Force refresh
                          }
                        } catch (e) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                        } finally {
                          if (mounted) setState(() => _isDeletingBranding = false);
                        }
                      }
                    },
                    icon: _isDeletingBranding 
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.redAccent))
                      : const Icon(Icons.delete_outline_rounded, size: 18),
                    label: Text(_isDeletingBranding ? 'RESETTING...' : 'RESET TO DEFAULT', style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.redAccent.withValues(alpha: 0.8),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
// --- CATEGORIES SECTION (Refactored to Dialog) ---
  // The Categories section is now managed via _showManageCategoriesDialog() 
  // accessed from the Manage Events header.


  Widget _categoryItem(Category category) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          Icon(Icons.category_outlined, color: category.isEnabled ? _gold : Colors.white24, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: TextStyle(
                    color: category.isEnabled ? Colors.white : Colors.white38,
                    fontWeight: FontWeight.bold,
                    decoration: category.isEnabled ? null : TextDecoration.lineThrough,
                  ),
                ),
                Text(
                  category.isEnabled ? 'Active' : 'Disabled',
                  style: TextStyle(color: category.isEnabled ? Colors.greenAccent : Colors.white24, fontSize: 10),
                ),
              ],
            ),
          ),
          Switch(
            value: category.isEnabled,
            onChanged: (val) {
              ref.read(adminRepositoryProvider).saveCategory(category.copyWith(isEnabled: val));
            },
            activeThumbColor: _gold,
          ),
          PopupMenuButton(
            icon: const Icon(Icons.more_vert, color: Colors.white38),
            itemBuilder: (context) => [
              PopupMenuItem(child: const Text('Edit'), onTap: () => Future.delayed(Duration.zero, () => _showCategoryDialog(category: category))),
              PopupMenuItem(
                child: const Text('Delete', style: TextStyle(color: Colors.red)),
                onTap: () => ref.read(adminRepositoryProvider).deleteCategory(category.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCategoryDialog({Category? category}) {
    final nameController = TextEditingController(text: category?.name);
    bool isEnabled = category?.isEnabled ?? true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(category == null ? 'New Category' : 'Edit Category', style: const TextStyle(color: Colors.white)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'Category Name'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Enable Category', style: TextStyle(color: Colors.white70)),
                  Switch(
                    value: isEnabled,
                    onChanged: (val) => setState(() => isEnabled = val),
                    activeThumbColor: _gold,
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isEmpty) return;
                final newCategory = Category(
                  id: category?.id ?? '',
                  name: nameController.text.trim(),
                  isEnabled: isEnabled,
                );
                ref.read(adminRepositoryProvider).saveCategory(newCategory);
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }


  // --- 8. PROFILE APP SECTION ---
  Widget _buildProfileSection(bool isNarrow) {
    final adminRepo = ref.watch(adminRepositoryProvider);
 
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 40, vertical: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isNarrow)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sectionHeader('PROFILE LAYOUT', 'Control which options appear on the user profile screen'),
                const SizedBox(height: 20),
                Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                     OutlinedButton.icon(
                      onPressed: () => _seedInitialProfileTiles(),
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: Text('SEED DEFAULT', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _gold,
                        side: BorderSide(color: _gold.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showProfileItemDialog(),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: Text('NEW TILE', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.black)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _sectionHeader('PROFILE LAYOUT', 'Control which options appear on the user profile screen'),
                ),
                const SizedBox(width: 16),
                Flexible(
                  child: Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    alignment: WrapAlignment.end,
                    children: [
                       OutlinedButton.icon(
                        onPressed: () => _seedInitialProfileTiles(),
                        icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                        label: Text('SEED DEFAULT', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _gold,
                          side: BorderSide(color: _gold.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _showProfileItemDialog(),
                        icon: const Icon(Icons.add_rounded, size: 20),
                        label: Text('NEW TILE', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 1, color: Colors.black)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _gold,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          const SizedBox(height: 40),
          Expanded(
            child: StreamBuilder<List<ProfileItem>>(
              stream: adminRepo.watchProfileItems(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.codingRimPrimary));
                
                final items = snapshot.data!;
                if (items.isEmpty) {
                  return _emptySection(Icons.dashboard_customize_outlined, 'No profile tiles configured');
                }

                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _profileItemCard(item);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileItemCard(ProfileItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: _GlassCard(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: item.isEnabled ? _gold.withValues(alpha: 0.1) : Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
              child: Icon(
                AppIcons.getIcon(item.iconCodePoint),
                color: item.isEnabled ? _gold : Colors.white24,
                size: 24,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: item.isEnabled ? Colors.white : Colors.white38,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Route: ${item.route}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(color: Colors.white24, fontSize: 13),
                  ),
                ],
              ),
            ),
            Switch(
              value: item.isEnabled,
              activeThumbColor: _gold,
              onChanged: (val) {
                ref.read(adminRepositoryProvider).saveProfileItem(item.copyWith(isEnabled: val));
              },
            ),
            const SizedBox(width: 8),
            _iconButton(Icons.edit_outlined, () => _showProfileItemDialog(item: item)),
            const SizedBox(width: 8),
            _iconButton(Icons.delete_outline_rounded, () => _confirmDeleteProfileItem(item)),
          ],
        ),
      ),
    );
  }

  void _showProfileItemDialog({ProfileItem? item}) {
    final titleController = TextEditingController(text: item?.title);
    final routeController = TextEditingController(text: item?.route);
    final orderController = TextEditingController(text: (item?.order ?? 0).toString());
    int selectedIconCode = item?.iconCodePoint ?? 0xe1b0;

    final List<Map<String, dynamic>> availableIcons = [
      {'name': 'Event', 'code': 0xe22e},
      {'name': 'School', 'code': 0xe559},
      {'name': 'Certificate', 'code': 0xe13d},
      {'name': 'Calendar', 'code': 0xe112},
      {'name': 'QR Code', 'code': 0xe507},
      {'name': 'History', 'code': 0xe314},
      {'name': 'Settings', 'code': 0xe57f},
      {'name': 'Person', 'code': 0xe491},
      {'name': 'Notifications', 'code': 0xe44f},
      {'name': 'Email', 'code': 0xe22a},
      {'name': 'Security', 'code': 0xe54c},
      {'name': 'Star', 'code': 0xe5f9},
    ];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(item == null ? 'New Profile Tile' : 'Edit Profile Tile', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _adminInputDecoration('Title', Icons.title),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: routeController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _adminInputDecoration('Route (e.g. /my-schedule)', Icons.link),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: orderController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _adminInputDecoration('Display Order', Icons.sort),
                ),
                const SizedBox(height: 24),
                const Text('Select Icon', style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: availableIcons.map((ic) {
                    bool isSelected = selectedIconCode == ic['code'];
                    return GestureDetector(
                      onTap: () => setDialogState(() => selectedIconCode = ic['code']),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected ? _gold.withValues(alpha: 0.2) : Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: isSelected ? _gold : Colors.transparent),
                        ),
                        child: Icon(
                          AppIcons.getIcon(ic['code']),
                          color: isSelected ? _gold : Colors.white54,
                          size: 24,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                if (titleController.text.isEmpty || routeController.text.isEmpty) return;
                
                final newItem = (item ?? ProfileItem(
                  id: '',
                  title: '',
                  iconCodePoint: 0,
                  route: '',
                )).copyWith(
                  title: titleController.text,
                  route: routeController.text,
                  order: int.tryParse(orderController.text) ?? 0,
                  iconCodePoint: selectedIconCode,
                  isEnabled: item?.isEnabled ?? true,
                );

                await ref.read(adminRepositoryProvider).saveProfileItem(newItem);
                if (context.mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteProfileItem(ProfileItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Tile', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${item.title}" from the profile?', style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(adminRepositoryProvider).deleteProfileItem(item.id);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  Future<void> _seedInitialProfileTiles() async {
    final adminRepo = ref.read(adminRepositoryProvider);
    final List<ProfileItem> initialTiles = [
      ProfileItem(id: '', title: 'Registered Events', iconCodePoint: 0xe22e, route: '/my-events', order: 1),
      ProfileItem(id: '', title: 'My Courses', iconCodePoint: 0xe559, route: '/my-courses', order: 2),
      ProfileItem(id: '', title: 'Certificates', iconCodePoint: 0xe13d, route: '/certificates', order: 3),
      ProfileItem(id: '', title: 'My Schedule', iconCodePoint: 0xe112, route: '/my-schedule', order: 4),
      ProfileItem(id: '', title: 'My QR Pass', iconCodePoint: 0xe507, route: '/qr-pass', order: 5),
      ProfileItem(id: '', title: 'Past Events', iconCodePoint: 0xe314, route: '/past-events', order: 6),
      ProfileItem(id: '', title: 'My Offers', iconCodePoint: 0xe3e0, route: '/my-offers', order: 7),
      ProfileItem(id: '', title: 'Saved Sponsors', iconCodePoint: 0xe098, route: '/saved-sponsors', order: 8),
      ProfileItem(id: '', title: 'Settings', iconCodePoint: 0xe57f, route: '/profile-settings', order: 10),
    ];

    for (var tile in initialTiles) {
      await adminRepo.saveProfileItem(tile);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Initial profile tiles seeded successfully!'), backgroundColor: Colors.green),
      );
    }
  }

  InputDecoration _adminInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _gold, size: 20),
      labelStyle: const TextStyle(color: Colors.white70),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.white10)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _gold)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.05),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Color? borderColor;

  const _GlassCard({required this.child, this.padding, this.borderColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28), // Premium rounded corners matching Event Home
        border: Border.all(color: borderColor ?? Colors.white.withValues(alpha: 0.08)),
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
