import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../../core/utils/app_icons.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'add_video_feed_screen.dart';
import 'add_image_feed_screen.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../features/auth/presentation/widgets/auth_widgets.dart';
import '../../../home/domain/event_models.dart';
import '../../data/admin_repository.dart';
import '../providers/optimistic_state_provider.dart'; // Import optimistic state
import '../../../chat/data/chat_repository.dart';
import 'admin_settings_screen.dart';
import '../../../auth/data/user_repository.dart';
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
import 'create_event_screen.dart';
import 'create_speaker_screen.dart';
import 'create_sponsor_screen.dart';
import 'create_schedule_screen.dart';
import 'package:tech_marathon_app/features/admin/presentation/pages/attendee_insights_screen.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';

Widget _buildHeaderAction({required String label, required IconData icon, required VoidCallback onPressed}) {
  return Container(
    decoration: BoxDecoration(
      gradient: AppColors.saasGradient,
      borderRadius: BorderRadius.circular(12),
      boxShadow: AppColors.saasShadow,
    ),
    child: ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: Colors.white),
      label: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
  );
}

class AdminDashboardScreen extends ConsumerStatefulWidget {
  final int initialTab;
  const AdminDashboardScreen({super.key, this.initialTab = 0});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  Widget _buildHeaderAction({required String label, required IconData icon, required VoidCallback onPressed}) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.saasGradient,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16, color: Colors.white),
        label: Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _currentTab; // 0: Overview, 1: Events, 2: Members, 3: Speakers, 4: Sponsors, 5: Schedules, 6: Chat, 7: Branding

  // Branding state
  XFile? _brandingLogo;
  Uint8List? _brandingLogoBytes;
  bool _isSavingBranding = false;
  bool _isDeletingBranding = false;
  final TextEditingController _brandingNameController = TextEditingController();

  // No longer needed: Splash Screen state

  // Search State
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  int _scheduleSubTab = 0; // 0: All, 1: Draft, 2: Published, 3: Completed, 4: Conflicts


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
    super.dispose();
  }

  // SaaS Theme Constants
  final Color _primary = AppColors.saasPrimary;
  final Color _darkBg = AppColors.saasMainBg;
  final Color _sidebarBg = AppColors.saasSidebarBg;
  final Color _cardBg = AppColors.saasCardBg;
  final Color _secondaryText = AppColors.saasTextSecondary;
  final Color _borderColor = AppColors.saasBorder;

  final Color _gold = AppColors.saasPrimary; // Map legacy gold to SaaS Primary for quick compatibility

  void _handleSearch(String query) {
    if (query.isEmpty) return;
    
    // Simple navigation logic for menu items
    final q = query.toLowerCase();
    if (q.contains('event')) setState(() => _currentTab = 1);
    else if (q.contains('member') || q.contains('user')) setState(() => _currentTab = 2);
    else if (q.contains('speaker')) setState(() => _currentTab = 3);
    else if (q.contains('sponsor')) setState(() => _currentTab = 4);
    else if (q.contains('schedule') || q.contains('session')) setState(() => _currentTab = 5);
    else if (q.contains('chat')) setState(() => _currentTab = 6);
    else if (q.contains('brand')) setState(() => _currentTab = 7);
    else if (q.contains('live') || q.contains('feed')) setState(() => _currentTab = 8);
    else if (q.contains('profile')) setState(() => _currentTab = 9);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final bool isNarrow = constraints.maxWidth < 1100;
        
        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: _darkBg,
          drawer: isNarrow ? Drawer(
            width: 280,
            backgroundColor: _sidebarBg,
            child: AdminSidebar(
              currentIndex: _currentTab,
              onTabSelected: (index) {
                setState(() => _currentTab = index);
                _scaffoldKey.currentState?.closeDrawer();
              },
              onBack: () => context.pop(),
            ),
          ) : null,
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1A1A1A),
                  Colors.black,
                  const Color(0xFF0D0D0D),
                  const Color(0xFF151515),
                ],
                stops: const [0.0, 0.3, 0.7, 1.0],
              ),
            ),
            child: Row(
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
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .shimmer(duration: 5.seconds, color: Colors.white.withValues(alpha: 0.03)),
        );
      },
    );
  }

  Widget _buildTopBar(bool isNarrow) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        isNarrow ? 20 : 32, 
        isNarrow ? 50 : 24, // More top padding for mobile comfort
        isNarrow ? 20 : 32, 
        20
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
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
                    fontSize: isNarrow ? 22 : 28,
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
                      fontSize: 14,
                      color: Colors.white38,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          // Search Bar
          if (!isNarrow) ...[
            Container(
              width: 300,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                onSubmitted: _handleSearch,
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: const InputDecoration(
                  hintText: 'Search...',
                  hintStyle: TextStyle(color: Colors.white38, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: Colors.white38, size: 20),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(width: 24),
          ],
          _iconButton(Icons.settings_outlined, () => _openSettings()),
          const SizedBox(width: 16),
          _iconButton(Icons.notifications_none_rounded, () {}),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () => _showAdminProfile(),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: _gold, width: 2),
              ),
              child: CircleAvatar(
                radius: isNarrow ? 18 : 22,
                backgroundColor: AppColors.saasCardBg,
                child: Icon(Icons.person, size: isNarrow ? 20 : 24, color: Colors.white),
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
      case 2: return 'Participants';
      case 3: return 'Speakers';
      case 4: return 'Sponsors';
      case 5: return 'Schedules';
      case 6: return 'Chat';
      case 7: return 'Branding';
      case 8: return 'Live Feed';
      case 9: return 'Profile';
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
      case 8: return _buildLiveFeedSection(isNarrow);
      case 9: return _buildProfileSection(isNarrow);
      default: return _buildOverview(isNarrow);
    }
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AdminSettingsScreen()),
    );
  }

  void _showAdminProfile() {
    final user = FirebaseAuth.instance.currentUser;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.saasCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Admin Profile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.saasPrimary,
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
        _buildIntegratedSearch(isNarrow),
        const SizedBox(height: 32),
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
                      color: AppColors.saasPrimary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'total earnings',
                    style: GoogleFonts.outfit(
                      color: AppColors.saasTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              const SizedBox(height: 32),
              StreamBuilder<List<CodingEvent>>(
                stream: adminRepo.watchEvents(),
                builder: (context, eventSnap) {
                  final events = eventSnap.data ?? [];
                  int totalSeats = 0;
                  int bookedSeats = 0;
                  for (var e in events) {
                    totalSeats += e.totalSeats;
                    bookedSeats += e.bookedSeats;
                  }
                  final available = totalSeats - bookedSeats;

                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildLargeStatCard(
                              title: 'Active Events',
                              value: '$totalEvents',
                              icon: Icons.confirmation_number_outlined,
                              color: AppColors.saasInfo,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildLargeStatCard(
                              title: 'Attendees',
                              value: '4.2k',
                              icon: Icons.analytics_outlined,
                              color: AppColors.saasPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildLargeStatCard(
                              title: 'Booked',
                              value: '$bookedSeats',
                              icon: Icons.event_seat_rounded,
                              color: Colors.orangeAccent,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildLargeStatCard(
                              title: 'Available',
                              value: '$available',
                              icon: Icons.chair_alt_rounded,
                              color: AppColors.saasSuccess,
                            ),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLargeStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.saasCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.saasBorder),
        boxShadow: AppColors.saasShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );

  }

  Widget _buildIntegratedSearch(bool isNarrow) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            onChanged: (val) {
              setState(() => _searchQuery = val.trim());
            },
            onSubmitted: _handleSearch,
            decoration: InputDecoration(
              hintText: 'Search menu, attendees (Name, Email, Mobile)...',
              hintStyle: const TextStyle(color: AppColors.saasTextSecondary, fontSize: 14),
              prefixIcon: const Icon(Icons.search, color: AppColors.saasPrimary, size: 22),
              border: InputBorder.none,
              suffixIcon: _searchQuery.isNotEmpty 
                  ? IconButton(
                      icon: const Icon(Icons.close, color: Colors.white38, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
          if (_searchQuery.isNotEmpty) ...[
            const Divider(color: Colors.white10, height: 24),
            _buildSearchResults(isNarrow),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isNarrow) {
    final q = _searchQuery.toLowerCase();
    
    // 1. Menu Matches
    final menuItems = [
      {'title': 'Events Management', 'tab': 1, 'icon': Icons.event},
      {'title': 'Participant Directory', 'tab': 2, 'icon': Icons.people},
      {'title': 'Speaker Management', 'tab': 3, 'icon': Icons.mic},
      {'title': 'Sponsor Directory', 'tab': 4, 'icon': Icons.business},
      {'title': 'Schedule Builder', 'tab': 5, 'icon': Icons.calendar_today},
      {'title': 'Admin Chat', 'tab': 6, 'icon': Icons.chat},
      {'title': 'Branding Settings', 'tab': 7, 'icon': Icons.brush},
      {'title': 'Live Feed Management', 'tab': 8, 'icon': Icons.sensors_rounded},
    ];

    final matchedMenu = menuItems.where((m) => (m['title'] as String).toLowerCase().contains(q)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (matchedMenu.isNotEmpty) ...[
          Text('MENU OPTIONS', style: GoogleFonts.outfit(color: AppColors.saasPrimary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
          const SizedBox(height: 8),
          ...matchedMenu.map((m) => ListTile(
            leading: Icon(m['icon'] as IconData, color: Colors.white70, size: 18),
            title: Text(m['title'] as String, style: const TextStyle(color: Colors.white, fontSize: 14)),
            dense: true,
            onTap: () {
              setState(() {
                _currentTab = m['tab'] as int;
                _searchQuery = '';
                _searchController.clear();
              });
            },
          )),
          const SizedBox(height: 16),
        ],
        
        // 2. Attendee Matches (Streaming from members)
        Text('ATTENDEES', style: GoogleFonts.outfit(color: AppColors.saasPrimary, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
        const SizedBox(height: 8),
        StreamBuilder<List<Participant>>(
          stream: ref.watch(userRepositoryProvider).getRealTimeMembers(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox.shrink();
            final matches = snapshot.data!.where((p) => 
               p.name.toLowerCase().contains(q) || 
               p.email.toLowerCase().contains(q) || 
               p.mobile.contains(q)
            ).take(5).toList();

            if (matches.isEmpty) return const Text('No attendees found', style: TextStyle(color: Colors.white24, fontSize: 12));

            return Column(
              children: matches.map((p) => ListTile(
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.saasPrimary.withValues(alpha: 0.2),
                  child: Text(p.name[0].toUpperCase(), style: const TextStyle(color: AppColors.saasPrimary, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                title: Text(p.name, style: const TextStyle(color: Colors.white, fontSize: 14)),
                subtitle: Text('${p.email} • ${p.mobile}', style: const TextStyle(color: Colors.white38, fontSize: 11)),
                dense: true,
                onTap: () {
                  setState(() {
                    _currentTab = 2; // Members tab
                    _searchQuery = p.email; // Seed the members list search
                    _searchController.text = p.email;
                  });
                },
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLiveAttendanceModule(bool isNarrow) {
    final userRepo = ref.watch(userRepositoryProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _moduleHeader('Live Presence', Icons.sensors_rounded, AppColors.saasSuccess),
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
                      const Icon(Icons.trending_up_rounded, color: AppColors.saasSuccess, size: 24),
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
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  event.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.inter(
                                    color: Colors.white38,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                                _buildHeaderAction(
                                  label: 'ANALYTICS',
                                  icon: Icons.analytics_rounded,
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => AttendeeInsightsScreen(eventId: event.id)),
                                    );
                                  },
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
                    _buildHeaderAction(
                      label: 'NEW EVENT',
                      icon: Icons.add_rounded,
                      onPressed: () => _showEventDialog(),
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
                          foregroundColor: AppColors.saasPrimary,
                          side: BorderSide(color: AppColors.saasPrimary.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      _buildHeaderAction(
                        label: 'NEW EVENT',
                        icon: Icons.add_rounded,
                        onPressed: () => _showEventDialog(),
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
                
                final filteredEvents = _searchQuery.isEmpty 
                    ? allEvents 
                    : allEvents.where((e) => e.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                if (filteredEvents.isEmpty) {
                   if (_searchQuery.isNotEmpty) return Center(child: Text('No events matching "$_searchQuery"', style: const TextStyle(color: Colors.white38)));
                   return const Center(child: Text('No events found', style: TextStyle(color: Colors.white38)));
                }
                
                return ListView.builder(
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    final event = filteredEvents[index];
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
        backgroundColor: AppColors.saasCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Manage Categories', style: TextStyle(color: Colors.white)),
            _buildHeaderAction(
              label: 'Add',
              icon: Icons.add,
              onPressed: () => _showCategoryDialog(),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: StreamBuilder<List<Category>>(
            stream: ref.watch(adminRepositoryProvider).watchCategories(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.saasPrimary));
              final categories = snapshot.data!;
              if (categories.isEmpty) return const Center(child: Text('No categories found', style: TextStyle(color: AppColors.saasTextSecondary)));

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
            child: const Text('Close', style: TextStyle(color: AppColors.saasTextSecondary)),
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
                color: AppColors.saasSidebarBg,
                borderRadius: BorderRadius.circular(12),
                image: event.imageUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(event.imageUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              ),
              child: event.imageUrl.isEmpty 
                ? const Icon(Icons.event_available_rounded, color: AppColors.saasPrimary, size: 24) 
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
                  if (event.totalSeats > 0) ...[
                    const SizedBox(height: 8),
                    _statBadge(
                      Icons.event_seat_rounded, 
                      '${event.bookedSeats}/${event.totalSeats} Seats Booked', 
                      event.bookedSeats >= event.totalSeats ? Colors.redAccent : _gold
                    ),
                  ],
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'edit') {
                  _showEventDialog(event: event);
                } else if (value == 'delete') {
                  ref.read(adminRepositoryProvider).deleteEvent(event.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showEventDialog({CodingEvent? event}) {
    Navigator.push(
      context, 
      MaterialPageRoute(builder: (_) => CreateEventScreen(event: event))
    );
  }

  // --- 3. PARTICIPANTS SECTION (Real-time) ---
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
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.saasPrimary));
                
                final members = snapshot.data!;
                if (members.isEmpty) {
                  return _emptySection(Icons.people_outline_rounded, 'No one has joined yet');
                }

                final filteredMembers = _searchQuery.isEmpty 
                    ? members 
                    : members.where((m) => 
                        m.name.toLowerCase().contains(_searchQuery.toLowerCase()) || 
                        m.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                        m.mobile.contains(_searchQuery)
                      ).toList();

                if (filteredMembers.isEmpty && _searchQuery.isNotEmpty) {
                   return _emptySection(Icons.search_off, 'No participants found matching "$_searchQuery"');
                }
                
                return ListView.builder(
                  itemCount: filteredMembers.length,
                  itemBuilder: (context, index) {
                    final member = filteredMembers[index];
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
                  child: _buildHeaderAction(
                    label: 'ADD SPEAKER',
                    icon: Icons.add_rounded,
                    onPressed: () => _showSpeakerDialog(),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 40),
          Expanded(
            child: StreamBuilder<List<Speaker>>(
              stream: adminRepo.watchAllSpeakers(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.saasPrimary));
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
                color: AppColors.saasSidebarBg,
                borderRadius: BorderRadius.circular(12),
                image: speaker.photoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(speaker.photoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
              ),
              child: speaker.photoUrl.isEmpty 
                ? const Icon(Icons.mic_none_rounded, color: AppColors.saasPrimary, size: 24) 
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
            const Spacer(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'edit') {
                  _showSpeakerDialog(speaker: speaker);
                } else if (value == 'delete') {
                  ref.read(adminRepositoryProvider).deleteSpeaker(speaker.eventId, speaker.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSpeakerDialog({Speaker? speaker, String? eventId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSpeakerScreen(
          speaker: speaker,
          preselectedEventId: eventId,
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
                _buildHeaderAction(
                  onPressed: () => _showSponsorDialog(),
                  icon: Icons.add_rounded,
                  label: 'ADD SPONSOR',
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
                  child: _buildHeaderAction(
                    onPressed: () => _showSponsorDialog(),
                    icon: Icons.add_rounded,
                    label: 'ADD SPONSOR',
                  ),
                ),
              ],
            ),
          const SizedBox(height: 40),
          Expanded(
            child: StreamBuilder<List<Sponsor>>(
              stream: adminRepo.watchAllSponsors(),
              builder: (context, snapshot) {
                 if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.saasPrimary));
                 
                 final allSponsors = snapshot.data!;
                 if (allSponsors.isEmpty) {
                    return _emptySection(Icons.business_outlined, 'No sponsors added yet');
                 }

                 final filteredSponsors = _searchQuery.isEmpty 
                    ? allSponsors 
                    : allSponsors.where((s) => s.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                 if (filteredSponsors.isEmpty && _searchQuery.isNotEmpty) {
                    return _emptySection(Icons.search_off, 'No sponsors found matching "$_searchQuery"');
                 }
 
                 return ListView.builder(
                   itemCount: filteredSponsors.length,
                   itemBuilder: (context, index) {
                     final sponsor = filteredSponsors[index];
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
                borderRadius: BorderRadius.circular(12),
                image: sponsor.logoUrl.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(sponsor.logoUrl),
                      fit: BoxFit.contain,
                    )
                  : null,
              ),
              child: sponsor.logoUrl.isEmpty 
                ? const Icon(Icons.business_outlined, color: AppColors.saasBorder, size: 24) 
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
            const Spacer(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'edit') {
                  _showSponsorDialog(sponsor: sponsor);
                } else if (value == 'delete') {
                  ref.read(adminRepositoryProvider).deleteSponsor(sponsor.eventId, sponsor.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
              ],
            ),
          ],
        ),
      ),
    );
  }
  void _showSponsorDialog({Sponsor? sponsor, String? eventId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSponsorScreen(
          sponsor: sponsor, 
          preselectedEventId: eventId,
        ),
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
                _buildHeaderAction(
                  onPressed: () => _showScheduleDialog(),
                  icon: Icons.event_available_rounded,
                  label: 'NEW SESSION',
                ),
              ],
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _sectionHeader('SCHEDULE DASHBOARD', 'Manage session timings, tracks, and speakers'),
                ),
                const SizedBox(width: 16),
                _statBadge(Icons.verified_rounded, 'No Conflicts', AppColors.saasSuccess),
                const SizedBox(width: 16),
                Flexible(
                  child: _buildHeaderAction(
                    onPressed: () => _showScheduleDialog(),
                    icon: Icons.event_available_rounded,
                    label: 'NEW SESSION',
                  ),
                ),
              ],
            ),
          const SizedBox(height: 32),
          
          // Sub Tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _subTabItem('All', 0),
                _subTabItem('Drafts', 1),
                _subTabItem('Published', 2),
                _subTabItem('Completed', 3),
                _subTabItem('Conflicts', 4, isWarning: true),
              ],
            ),
          ),
          const SizedBox(height: 24),

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
                    if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.saasPrimary));
                    
                    var filteredSchedules = snapshot.data!;
                    
                    // Filter based on sub-tab
                    if (_scheduleSubTab == 1) filteredSchedules = filteredSchedules.where((s) => s.status == 'draft').toList();
                    else if (_scheduleSubTab == 2) filteredSchedules = filteredSchedules.where((s) => s.status == 'published').toList();
                    else if (_scheduleSubTab == 3) filteredSchedules = filteredSchedules.where((s) => s.status == 'completed').toList();
                    else if (_scheduleSubTab == 4) {
                      // Conflict Logic: sessions in same hall at same time
                      final conflicts = <new_schedule.Schedule>[];
                      for (var i = 0; i < filteredSchedules.length; i++) {
                        for (var j = i + 1; j < filteredSchedules.length; j++) {
                          final a = filteredSchedules[i];
                          final b = filteredSchedules[j];
                          if (a.hall == b.hall && a.hall.isNotEmpty &&
                              a.sessionDate.year == b.sessionDate.year &&
                              a.sessionDate.month == b.sessionDate.month &&
                              a.sessionDate.day == b.sessionDate.day &&
                              a.startTime.isBefore(b.endTime) &&
                              a.endTime.isAfter(b.startTime)) {
                            if (!conflicts.contains(a)) conflicts.add(a);
                            if (!conflicts.contains(b)) conflicts.add(b);
                          }
                        }
                      }
                      filteredSchedules = conflicts;
                    }

                    if (filteredSchedules.isEmpty) {
                       return _emptySection(Icons.schedule_rounded, 'No sessions found in this category');
                    }

                    return ListView.builder(
                      itemCount: filteredSchedules.length,
                      itemBuilder: (context, index) {
                         final schedule = filteredSchedules[index];
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

  Widget _subTabItem(String label, int index, {bool isWarning = false}) {
    final isSelected = _scheduleSubTab == index;
    return GestureDetector(
      onTap: () => setState(() => _scheduleSubTab = index),
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.saasGradient : null,
          color: isSelected ? null : AppColors.saasSidebarBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? Colors.transparent : AppColors.saasBorder),
          boxShadow: isSelected ? AppColors.saasShadow : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            color: isSelected ? Colors.white : AppColors.saasTextSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 13,
          ),
        ),
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
                color: AppColors.saasSidebarBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.schedule_rounded, color: AppColors.saasPrimary, size: 24),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    schedule.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.saasPrimary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.saasPrimary.withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            schedule.sessionType.toUpperCase(),
                            style: GoogleFonts.outfit(color: AppColors.saasPrimary, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatTime(schedule.startTime)} - ${_formatTime(schedule.endTime)}',
                          style: GoogleFonts.outfit(color: Colors.white38, fontSize: 13),
                        ),
                        if (schedule.hall.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.room_rounded, color: Colors.white24, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                schedule.hall,
                                style: GoogleFonts.outfit(color: Colors.white38, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            eventName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(color: Colors.white38, fontSize: 11),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Status Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getStatusColor(schedule.status).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _getStatusColor(schedule.status).withValues(alpha: 0.2)),
                          ),
                          child: Text(
                            schedule.status.toUpperCase(),
                            style: GoogleFonts.outfit(color: _getStatusColor(schedule.status), fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Attendance Count
                        StreamBuilder<int>(
                          stream: ref.read(adminRepositoryProvider).watchAttendanceCount(schedule.eventId, schedule.id),
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.people_outline_rounded, color: Colors.blueAccent, size: 10),
                                  const SizedBox(width: 4),
                                  Text(
                                    '$count Attended',
                                    style: GoogleFonts.outfit(color: Colors.blueAccent, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            );
                          }
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'edit') {
                  _showScheduleDialog(schedule: schedule);
                } else if (value == 'scan') {
                   _scanSessionAttendance(schedule);
                } else if (value == 'delete') {
                  ref.read(adminRepositoryProvider).deleteSchedule(schedule.eventId, schedule.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'scan', child: Text('Scan Attendance', style: TextStyle(color: Colors.lightBlueAccent))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showScheduleDialog({new_schedule.Schedule? schedule}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateScheduleScreen(
          schedule: schedule,
          preselectedEventId: null, // You might want to pass this if available
        ),
      ),
    );
  }

  void _scanSessionAttendance(new_schedule.Schedule session) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SessionScannerModal(session: session, gold: _gold),
    );
  }

  // --- 6. CHAT SECTION (Real-time Admin List View) ---
  Widget _buildChatSection(bool isNarrow) {
    final chatRepo = ref.watch(adminChatRepositoryProvider);
    final usersStream = ref.watch(userRepositoryProvider).getRealTimeMembers();
    
    return DefaultTabController(
      length: 4,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader('USER INQUIRIES', 'Communicate with platform users in real-time'),
            const SizedBox(height: 24),
            TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: AppColors.saasPrimary,
              labelColor: AppColors.saasPrimary,
              unselectedLabelColor: AppColors.saasTextSecondary,
              dividerColor: AppColors.saasBorder,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
              unselectedLabelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1),
              tabs: const [
                Tab(text: 'PARTICIPANTS'),
                Tab(text: 'ADMINS'),
                Tab(text: 'MANAGERS'),
                Tab(text: 'TEAM'),
              ],
            ),
            const SizedBox(height: 32),
            Expanded(
              child: StreamBuilder<List<Participant>>(
                stream: usersStream,
                builder: (context, userSnap) {
                  final users = userSnap.data ?? [];
                  
                  return StreamBuilder<List<Map<String, dynamic>>>(
                    stream: chatRepo.watchAllChats(),
                    builder: (context, chatSnap) {
                      if (!chatSnap.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.saasPrimary));
                      final chats = chatSnap.data!;
                      
                      return TabBarView(
                        children: [
                          _filteredChatList(chats, users, 'user'),
                          _filteredChatList(chats, users, 'admin'),
                          _filteredChatList(chats, users, 'organizer'),
                          _filteredChatList(chats, users, 'team'),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filteredChatList(List<Map<String, dynamic>> chats, List<Participant> users, String role) {
    final filtered = chats.where((chat) {
      final user = users.firstWhere((u) => u.id == chat['userId'], orElse: () => Participant(id: '', name: '', email: '', mobile: ''));
      // Default to 'user' for participants, 'organizer' for managers
      return user.role == role;
    }).toList();

    if (filtered.isEmpty) {
      String msg = 'No active chats';
      if (role == 'admin') msg = 'No admin inquiries';
      if (role == 'organizer') msg = 'No manager inquiries';
      if (role == 'team') msg = 'No team messages';
      return _emptySection(Icons.chat_bubble_outline_rounded, msg);
    }

    return StreamBuilder<List<Participant>>(
      stream: ref.watch(userRepositoryProvider).getRealTimeMembers(),
      builder: (context, userSnapshot) {
        final usersList = userSnapshot.data ?? [];
        return ListView.builder(
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final chat = filtered[index];
            final participant = usersList.firstWhere(
              (u) => u.id == chat['userId'],
              orElse: () => Participant(id: '', name: chat['userName'] ?? 'User', email: '', mobile: ''),
            );
            return _chatThreadItem(chat, participant.name);
          },
        );
      },
    );
  }

  Widget _chatThreadItem(Map<String, dynamic> chat, String resolvedName) {
    final bool hasUnread = chat['unreadByAdmin'] ?? false;
    final String userId = chat['userId'];
    
    return StatefulBuilder(
      builder: (context, setState) {
        bool isHovered = false;
        return MouseRegion(
          onEnter: (_) => setState(() => isHovered = true),
          onExit: (_) => setState(() => isHovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isHovered || hasUnread ? _gold.withValues(alpha: 0.5) : Colors.transparent,
                width: 2,
              ),
              boxShadow: isHovered ? [
                BoxShadow(
                  color: _gold.withValues(alpha: 0.1),
                  blurRadius: 15,
                  spreadRadius: 2,
                )
              ] : [],
            ),
            child: _GlassCard(
              padding: const EdgeInsets.all(4),
              child: ListTile(
                onTap: () => _openAdminChatRoom(userId, resolvedName),
                leading: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isHovered || hasUnread ? _gold : Colors.white12, 
                      width: 2,
                    ),
                  ),
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.05),
                    child: Text(
                      resolvedName.isNotEmpty ? resolvedName[0].toUpperCase() : 'U',
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                title: Text(
                  resolvedName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: isHovered || hasUnread ? FontWeight.w900 : FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                subtitle: Text(
                  chat['lastMessage'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    color: isHovered || hasUnread ? Colors.white60 : Colors.white38,
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
          ),
        );
      }
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

  // --- SYSTEM ACTIVITY / RECENT PARTICIPANTS ---
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
                          'New participant joined: ${m.name}', 
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

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'published': return Colors.green;
      case 'draft': return Colors.orange;
      case 'cancelled': return Colors.red;
      case 'completed': return Colors.blue;
      default: return Colors.white38;
    }
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
            _iconButton(Icons.mail_outline_rounded, () => _openAdminChatRoom(member.id, member.name)),
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
              _detailRow(Icons.event, 'Joined Events', '0 Events'),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _openAdminChatRoom(member.id, member.name);
                  },
                  icon: const Icon(Icons.chat_bubble_outline_rounded, size: 20),
                  label: const Text('MESSAGE USER'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
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
            return _chatBubble(msg, isMe, userId);
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
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF2A3942), // WhatsApp input background
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: controller,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                style: const TextStyle(color: Colors.white),
              ),
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

  Widget _chatBubble(Map<String, dynamic> msg, bool isMe, String userId) {
    final String text = msg['message'] ?? msg['text'] ?? '';
    final bool isEdited = msg['isEdited'] ?? false;
    final bool isDeleted = msg['isDeleted'] ?? false;
    final String id = msg['id'] ?? '';
    final timestamp = msg['timestamp'] as Timestamp?;

    return GestureDetector(
      onLongPress: isDeleted ? null : () => _showMessageOptions(msg, userId),
      onDoubleTap: isDeleted ? null : () => _showMessageOptions(msg, userId),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
          decoration: BoxDecoration(
            color: isMe ? const Color(0xFF005C4B) : const Color(0xFF202C33), // WhatsApp Dark colors
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(12),
              topRight: const Radius.circular(12),
              bottomLeft: isMe ? const Radius.circular(12) : const Radius.circular(0),
              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                text,
                style: TextStyle(
                  color: isDeleted ? Colors.white38 : Colors.white, 
                  fontSize: 15,
                  fontStyle: isDeleted ? FontStyle.italic : FontStyle.normal,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isEdited && !isDeleted)
                    Text(
                      'edited  ',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 10),
                    ),
                  Text(
                    timestamp != null ? DateFormat('HH:mm').format(timestamp.toDate()) : DateFormat('HH:mm').format(DateTime.now()), 
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> msg, String userId) {
    final bool isMe = msg['senderRole'] == 'admin';
    final String text = msg['message'] ?? msg['text'] ?? '';
    final String msgId = msg['id'] ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             if (isMe)
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.blueAccent),
                title: Text('Edit message', style: GoogleFonts.outfit(color: Colors.white)),
                onTap: () {
                  Navigator.pop(context);
                  _showEditMessageDialog(userId, msgId, text);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: Text('Delete for everyone', style: GoogleFonts.outfit(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                ref.read(adminChatRepositoryProvider).deleteMessage(userId, msgId);
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showEditMessageDialog(String userId, String msgId, String currentText) {
    final controller = TextEditingController(text: currentText);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.saasCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Message', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          maxLines: null,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                ref.read(adminChatRepositoryProvider).editMessage(userId, msgId, controller.text.trim());
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: _gold, foregroundColor: Colors.black),
            child: const Text('SAVE'),
          ),
        ],
      ),
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
        loading: () => _buildBrandingForm(BrandingInfo(appName: 'Event App'), isNarrow),
        error: (error, _) => _buildBrandingForm(BrandingInfo(appName: 'Event App'), isNarrow),
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
              ],
            ),
          ),
          const SizedBox(height: 48),
          Center(
            child: SizedBox(
              width: 220,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSavingBranding ? null : () async {
                  setState(() => _isSavingBranding = true);
                  try {
                    final adminRepo = ref.read(adminRepositoryProvider);
                    
                    String? logoUrl = branding.logoUrl;
                    String? logoPath = branding.logoPath;

                    // Helper function for compression and upload to Cloudinary
                    Future<Map<String, String?>> uploadImage(Uint8List bytes, String folder) async {
                      if (bytes.length > 2 * 1024 * 1024) throw 'Image size exceeds 2MB limit';
                      
                      debugPrint('☁️ Uploading to Cloudinary (folder: $folder)...');
                      final url = await adminRepo.uploadToCloudinary(
                        data: bytes, 
                        folder: 'branding/$folder',
                      ).timeout(const Duration(seconds: 45), onTimeout: () => throw 'Cloudinary upload ($folder) is taking too long.');
                      
                      return {'url': url, 'path': url};
                    }

                    if (_brandingLogoBytes != null) {
                      final res = await uploadImage(_brandingLogoBytes!, 'main');
                      logoUrl = res['url'];
                      logoPath = res['path'];
                    }

                    await adminRepo.saveBranding(branding.copyWith(
                      appName: _brandingNameController.text,
                      logoUrl: logoUrl,
                      logoPath: logoPath,
                    )).timeout(const Duration(seconds: 15), onTimeout: () => throw 'Branding save timed out.');

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
                  backgroundColor: AppColors.saasPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSavingBranding 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('SAVE BRANDING', style: GoogleFonts.outfit(fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
              ),
            ),
          ),
          const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: _isDeletingBranding ? null : () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          backgroundColor: AppColors.saasCardBg,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
    );
  }
  Widget _buildChoiceChip(String label, String value, String current, Function(String) onSelected) {
    final bool isSelected = current == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => onSelected(value),
      backgroundColor: Colors.white.withValues(alpha: 0.05),
      selectedColor: _gold,
      labelStyle: TextStyle(color: isSelected ? Colors.black : Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide.none,
      showCheckmark: false,
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint) {
    if (controller.text.isEmpty && hint != '#000000') controller.text = hint;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.2)),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildImagePicker({Uint8List? bytes, String? url, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: _isSavingBranding ? null : onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (bytes != null)
                Image.memory(bytes, fit: BoxFit.cover)
              else if (url != null)
                CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => const Icon(Icons.error),
                )
              else
                const Icon(Icons.add_photo_alternate_outlined, color: Colors.white24, size: 32),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.7)],
                  ),
                ),
              ),
              Positioned(
                bottom: 6,
                left: 0,
                right: 0,
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold, letterSpacing: 1),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteOnboardingScreen(OnboardingPageData screen) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.saasCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Screen?', style: TextStyle(color: Colors.white)),
        content: Text('Are you sure you want to delete "${screen.title}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), style: TextButton.styleFrom(foregroundColor: Colors.redAccent), child: const Text('Delete')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(adminRepositoryProvider).deleteOnboardingScreen(screen.id, screen.imagePath);
    }
  }

  void _showOnboardingDialog(OnboardingPageData? screen) {
    final titleController = TextEditingController(text: screen?.title);
    final descController = TextEditingController(text: screen?.description);
    Uint8List? imageBytes;
    XFile? pickedFile;
    bool isSavingLocal = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: AppColors.saasCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(screen == null ? 'Add Screen' : 'Edit Screen', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildImagePicker(
                  bytes: imageBytes,
                  url: screen?.imageUrl,
                  label: 'PICK IMAGE',
                  onTap: () async {
                    final picker = ImagePicker();
                    final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                    if (image != null) {
                      final bytes = await image.readAsBytes();
                      setStateDialog(() {
                        pickedFile = image;
                        imageBytes = bytes;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Title', labelStyle: TextStyle(color: Colors.white70)),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Description', labelStyle: TextStyle(color: Colors.white70)),
                  maxLines: 3,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSavingLocal ? null : () async {
                if (titleController.text.isEmpty) return;
                setStateDialog(() => isSavingLocal = true);
                try {
                  final adminRepo = ref.read(adminRepositoryProvider);
                  String? imageUrl = screen?.imageUrl;
                  String? imagePath = screen?.imagePath;

                  if (imageBytes != null) {
                    if (imageBytes!.length > 2 * 1024 * 1024) throw 'Image size exceeds 2MB limit';
                    
                    debugPrint('☁️ Uploading onboarding image to Cloudinary...');
                    imageUrl = await adminRepo.uploadToCloudinary(
                      data: imageBytes!,
                      folder: 'branding/onboarding',
                    ).timeout(const Duration(seconds: 45), onTimeout: () => throw 'Cloudinary upload timed out. Please check your connection.');
                    
                    imagePath = imageUrl; // Using URL as path for Cloudinary
                  }

                  await adminRepo.saveOnboardingScreen(OnboardingPageData(
                    id: screen?.id ?? '',
                    title: titleController.text,
                    description: descController.text,
                    imageUrl: imageUrl,
                    imagePath: imagePath,
                    order: screen?.order ?? 0,
                  )).timeout(const Duration(seconds: 15), onTimeout: () => throw 'Firestore save timed out.');

                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(screen == null ? 'Screen added!' : 'Screen updated!'), backgroundColor: Colors.green),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
                    setStateDialog(() => isSavingLocal = false);
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saasPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: isSavingLocal 
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                : const Text('Save Screen'),
            ),
          ],
        ),
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
          backgroundColor: AppColors.saasCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
  Widget _buildLiveFeedSection(bool isNarrow) {
    final adminRepo = ref.watch(adminRepositoryProvider);
    final eventsAsync = adminRepo.watchEvents();

    return StreamBuilder<List<CodingEvent>>(
      stream: eventsAsync,
      builder: (context, eventSnap) {
        if (!eventSnap.hasData) return const Center(child: CircularProgressIndicator());
        final events = eventSnap.data!;
        if (events.isEmpty) return _emptySection(Icons.live_tv_rounded, 'Create an event first to manage Live Feed');
        
        final activeEvent = events.first;

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: isNarrow ? 20 : 40, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'LIVE FEED HUB',
                style: GoogleFonts.outfit(
                  color: Colors.white30,
                  fontSize: 12,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w900,
                ),
              ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2, end: 0),
              const SizedBox(height: 12),
              Text(
                'Broadcast live moments and\nupdates to your attendees',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  height: 1.1,
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 100.ms).slideX(begin: -0.1, end: 0),
              
              const SizedBox(height: 48),
              
              Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: 'ADD VIDEO',
                      subtitle: 'Broadcast live recordings',
                      icon: Icons.videocam_rounded,
                      color: _gold,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddVideoFeedScreen(eventId: activeEvent.id))),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildActionCard(
                      title: 'ADD IMAGE',
                      subtitle: 'Share certificates & guests',
                      icon: Icons.add_photo_alternate_rounded,
                      color: Colors.blueAccent,
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => AddImageFeedScreen(eventId: activeEvent.id))),
                    ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.2, end: 0),
                  ),
                ],
              ),

              const SizedBox(height: 56),
              
              Text(
                'RECENT UPDATES',
                style: GoogleFonts.outfit(
                  color: Colors.white24,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              
              StreamBuilder<List<LiveFeedItem>>(
                stream: adminRepo.watchLiveFeedItems(activeEvent.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return Container(
                      height: 300,
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sensors_rounded, color: Colors.white.withValues(alpha: 0.05), size: 100),
                          const SizedBox(height: 24),
                          Text(
                            'Your live feed is empty',
                            style: GoogleFonts.outfit(color: Colors.white30, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Post your first update to engage with attendees',
                            style: GoogleFonts.inter(color: Colors.white10, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildLiveFeedItemRow(activeEvent.id, item);
                    },
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color.withValues(alpha: 0.1), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                color: Colors.white38,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }


  Widget _buildLiveFeedItemRow(String eventId, LiveFeedItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: _GlassCard(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
                image: (item.type == 'image' && item.contentUrl != null) 
                  ? DecorationImage(image: NetworkImage(item.contentUrl!), fit: BoxFit.cover)
                  : null,
              ),
              child: item.type == 'video' 
                ? const Icon(Icons.play_circle_outline_rounded, color: AppColors.primary, size: 30)
                : item.type == 'template'
                  ? const Icon(Icons.article_outlined, color: AppColors.primary, size: 30)
                  : (item.contentUrl == null ? const Icon(Icons.image_outlined, color: Colors.white24, size: 30) : null),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (item.type == 'video' ? Colors.redAccent : _gold).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.type.toUpperCase(),
                          style: TextStyle(color: item.type == 'video' ? Colors.redAccent : _gold, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (item.templateType != null)
                        Text(
                          item.templateType!.toUpperCase(),
                          style: const TextStyle(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    item.templateData['title'] ?? item.templateData['name'] ?? 'Interactive Update',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Posted ${TimeOfDay.fromDateTime(item.createdAt).format(context)}',
                    style: GoogleFonts.inter(color: Colors.white38, fontSize: 12),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
              onPressed: () => _confirmDeleteLiveFeed(eventId, item.id),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteLiveFeed(String eventId, String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.saasCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Feed Item?', style: TextStyle(color: Colors.white)),
        content: const Text('This update will be removed from the public live feed.', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(adminRepositoryProvider).deleteLiveFeedItem(eventId, itemId);
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _showLiveFeedDialog(String eventId, {String type = 'video'}) {
    // Basic implementation for now, will expand with templates
    String templateType = 'certificate';
    final controllers = <String, TextEditingController>{
      'title': TextEditingController(),
      'name': TextEditingController(),
      'message': TextEditingController(),
      'url': TextEditingController(),
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.saasCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Add ${type.toUpperCase()}', style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (type == 'video') ...[
                  TextField(
                    controller: controllers['url'],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Video URL (mp4 or YouTube)', labelStyle: TextStyle(color: Colors.white38)),
                  ),
                  TextField(
                    controller: controllers['title'],
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'Caption/Title', labelStyle: TextStyle(color: Colors.white38)),
                  ),
                ] else ...[
                  DropdownButtonFormField<String>(
                    value: templateType,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(color: Colors.white),
                    items: ['certificate', 'guest', 'invite', 'sponsor', 'intro'].map((t) => DropdownMenuItem(value: t, child: Text(t.toUpperCase()))).toList(),
                    onChanged: (val) => setDialogState(() => templateType = val!),
                    decoration: const InputDecoration(labelText: 'Select Template', labelStyle: TextStyle(color: Colors.white38)),
                  ),
                  const SizedBox(height: 16),
                  if (templateType == 'certificate') ...[
                    TextField(controller: controllers['name'], style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Awarded To', labelStyle: TextStyle(color: Colors.white38))),
                    TextField(controller: controllers['message'], style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Award Description', labelStyle: TextStyle(color: Colors.white38))),
                  ] else if (templateType == 'guest') ...[
                    TextField(controller: controllers['name'], style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Guest Name', labelStyle: TextStyle(color: Colors.white38))),
                    TextField(controller: controllers['message'], style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Designation', labelStyle: TextStyle(color: Colors.white38))),
                  ] else if (templateType == 'invite') ...[
                    TextField(controller: controllers['title'], style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Event Name', labelStyle: TextStyle(color: Colors.white38))),
                    TextField(controller: controllers['message'], style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Venue/Time', labelStyle: TextStyle(color: Colors.white38))),
                  ] else if (templateType == 'sponsor') ...[
                    TextField(controller: controllers['name'], style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Company Name', labelStyle: TextStyle(color: Colors.white38))),
                    TextField(controller: controllers['message'], style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Thank You Message', labelStyle: TextStyle(color: Colors.white38))),
                  ] else ...[
                    TextField(controller: controllers['title'], style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Intro Heading', labelStyle: TextStyle(color: Colors.white38))),
                    TextField(controller: controllers['message'], style: const TextStyle(color: Colors.white), decoration: const InputDecoration(labelText: 'Key Highlights', labelStyle: TextStyle(color: Colors.white38))),
                  ],
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final item = LiveFeedItem(
                  id: '',
                  eventId: eventId,
                  type: type,
                  contentUrl: controllers['url']?.text,
                  templateType: type == 'template' ? templateType : null,
                  templateData: {
                    'title': controllers['title']?.text,
                    'name': controllers['name']?.text,
                    'message': controllers['message']?.text,
                  },
                );
                await ref.read(adminRepositoryProvider).saveLiveFeedItem(item);
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: _gold),
              child: const Text('POST UPDATE', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

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
                      icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                      label: Text('SEED DEFAULT', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 0.5, fontSize: 11)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _gold,
                        side: BorderSide(color: _gold.withValues(alpha: 0.3)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: () => _showProfileItemDialog(),
                      icon: const Icon(Icons.add_rounded, size: 16),
                      label: Text('NEW TILE', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 0.5, color: Colors.black, fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _gold,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
                        icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                        label: Text('SEED DEFAULT', style: GoogleFonts.outfit(fontWeight: FontWeight.w700, letterSpacing: 0.5, fontSize: 11)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _gold,
                          side: BorderSide(color: _gold.withValues(alpha: 0.3)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                      _buildHeaderAction(
                        onPressed: () => _showProfileItemDialog(),
                        icon: Icons.add_rounded,
                        label: 'NEW TILE',
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
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppColors.saasPrimary));
                
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
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: AppColors.surface,
              onSelected: (value) {
                if (value == 'edit') {
                  _showProfileItemDialog(item: item);
                } else if (value == 'delete') {
                  _confirmDeleteProfileItem(item);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit', style: TextStyle(color: Colors.white))),
                const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.redAccent))),
              ],
            ),
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
          backgroundColor: AppColors.saasCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        backgroundColor: AppColors.saasCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      prefixIcon: Icon(icon, color: AppColors.saasPrimary, size: 20),
      labelStyle: const TextStyle(color: AppColors.saasTextSecondary),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.saasBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.saasPrimary)),
      filled: true,
      fillColor: AppColors.saasCardBg,
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
        color: AppColors.saasCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor ?? AppColors.saasBorder),
        boxShadow: AppColors.saasShadow,
      ),
      child: child,
    );
  }
}

class _SessionScannerModal extends ConsumerStatefulWidget {
  final new_schedule.Schedule session;
  final Color gold;
  const _SessionScannerModal({required this.session, required this.gold});

  @override
  ConsumerState<_SessionScannerModal> createState() => _SessionScannerModalState();
}

class _SessionScannerModalState extends ConsumerState<_SessionScannerModal> {
  final MobileScannerController controller = MobileScannerController();
  final TextEditingController _manualIdController = TextEditingController();
  bool _isProcessing = false;

  @override
  void dispose() {
    controller.dispose();
    _manualIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF121212),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 24),
              Text(
                'RECORD ATTENDANCE',
                style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18, letterSpacing: 2),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Text(
                  widget.session.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(color: widget.gold, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              const SizedBox(height: 40),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 32),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    border: Border.all(color: widget.gold.withValues(alpha: 0.3), width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(30),
                    child: MobileScanner(
                      controller: controller,
                      onDetect: (capture) {
                        if (_isProcessing) return;
                        final List<Barcode> barcodes = capture.barcodes;
                        if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
                          _processQRCode(barcodes.first.rawValue!);
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Manual Search Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Column(
                  children: [
                    Text(
                      'OR ENTER ID MANUALLY',
                      style: GoogleFonts.inter(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _manualIdController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'User ID or Phone',
                        hintStyle: const TextStyle(color: Colors.white24),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                        suffixIcon: IconButton(
                          icon: Icon(Icons.arrow_circle_right_rounded, color: widget.gold),
                          onPressed: () {
                            if (_manualIdController.text.isNotEmpty) {
                              _processQRCode(_manualIdController.text);
                            }
                          },
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                      onSubmitted: (val) {
                        if (val.isNotEmpty) _processQRCode(val);
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: ValueListenableBuilder(
                        valueListenable: controller,
                        builder: (context, state, child) {
                          switch (state.torchState) {
                            case TorchState.on:
                              return Icon(Icons.flash_on_rounded, color: widget.gold);
                            case TorchState.off:
                            default:
                              return const Icon(Icons.flash_off_rounded, color: Colors.white54);
                          }
                        },
                      ),
                      onPressed: () => controller.toggleTorch(),
                    ),
                    IconButton(
                      icon: const Icon(Icons.flip_camera_ios_rounded, color: Colors.white54),
                      onPressed: () => controller.switchCamera(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 60),
            ],
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  void _processQRCode(String rawValue) async {
    setState(() => _isProcessing = true);
    
    // QR Format expected: userId
    final userId = rawValue.trim();

    final adminId = FirebaseAuth.instance.currentUser?.uid ?? 'unknown_admin';
    
    try {
      // 1. Basic validation - Does user exist and are they registered?
      final repo = ref.read(adminRepositoryProvider);
      
      // We'll simulate a slightly more advanced validation here for the UI feedback
      // In a real scenario, repo.recordAttendance should throw specific errors
      
      await repo.recordAttendance(
        eventId: widget.session.eventId,
        scheduleId: widget.session.id,
        userId: userId,
        adminId: adminId,
      );
      
      _manualIdController.clear();
      _showResultOverlay(true, 'Attendee: $userId\nEntry Allowed ✅');
    } catch (e) {
      String errorMessage = e.toString();
      if (errorMessage.contains('already recorded') || errorMessage.contains('Duplicate')) {
        _showResultOverlay(false, 'ALREADY USED ❌\nThis ticket has already been scanned for this session.', isWarning: true);
      } else if (errorMessage.contains('not registered')) {
        _showResultOverlay(false, 'INVALID TICKET ❌\nUser is not registered for this event.');
      } else {
        _showResultOverlay(false, 'ENTRY DENIED ❌\n$errorMessage');
      }
    }
  }

  void _showResultOverlay(bool success, String message, {bool isWarning = false}) {
    if (!mounted) return;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                  color: success 
                      ? Colors.greenAccent.withValues(alpha: 0.3) 
                      : (isWarning ? Colors.orangeAccent.withValues(alpha: 0.3) : Colors.redAccent.withValues(alpha: 0.3)),
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    success 
                        ? Icons.check_circle_outline_rounded 
                        : (isWarning ? Icons.warning_amber_rounded : Icons.error_outline_rounded),
                    color: success 
                        ? Colors.greenAccent 
                        : (isWarning ? Colors.orangeAccent : Colors.redAccent),
                    size: 80,
                  ),
                  const SizedBox(height: 24),
                  Text(
                    success ? 'SUCCESS' : (isWarning ? 'ALREADY USED' : 'ERROR'),
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white38, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() => _isProcessing = false);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: success 
                            ? Colors.greenAccent 
                            : (isWarning ? Colors.orangeAccent : Colors.redAccent),
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
