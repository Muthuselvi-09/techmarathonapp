import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';
import 'package:tech_marathon_app/features/profile/data/profile_repository.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QrPassScreen extends ConsumerStatefulWidget {
  const QrPassScreen({super.key});

  @override
  ConsumerState<QrPassScreen> createState() => _QrPassScreenState();
}

class _QrPassScreenState extends ConsumerState<QrPassScreen> with TickerProviderStateMixin {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  int _currentIndex = 0;
  final PageController _pageController = PageController();
  late TabController _tabController;
  late AnimationController _scannerAnimationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _scannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    _tabController.dispose();
    _scannerAnimationController.dispose();
    super.dispose();
  }

  String _generateQrData(String eventId) {
    final userId = _auth.currentUser?.uid ?? 'unknown';
    // Strictly formatted as UserID|EventID as requested
    return '$userId|$eventId';
  }

  @override
  Widget build(BuildContext context) {
    final allEventsAsync = ref.watch(allEventsStreamProvider);
    final userId = _auth.currentUser?.uid;
    final userName = _auth.currentUser?.displayName ?? 'Attendee';

    if (userId == null) return const Center(child: Text('Please login to view QR passes'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'QR HUB',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: const Color(0xFF00CED1), // Match central button teal
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: Colors.black,
              unselectedLabelColor: Colors.white60,
              labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
              tabs: const [
                Tab(text: 'MY PASS'),
                Tab(text: 'SCAN QR'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyPassTab(userId, userName, allEventsAsync),
                _buildScanTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMyPassTab(String userId, String userName, AsyncValue<List<CodingEvent>> allEventsAsync) {
    return StreamBuilder<List<String>>(
      stream: ref.watch(profileRepositoryProvider).getRegisteredEventIds(userId),
      builder: (context, registeredSnapshot) {
        if (!registeredSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        final registeredIds = registeredSnapshot.data!;

        if (registeredIds.isEmpty) return _buildEmptyState();

        return allEventsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
          data: (events) {
            final registeredEvents = events.where((e) => registeredIds.contains(e.id)).toList();

            if (registeredEvents.isEmpty) return _buildEmptyState();

            return Column(
              children: [
                const SizedBox(height: 16),
                if (registeredEvents.length > 1)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SELECT EVENT',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDim,
                            letterSpacing: 1,
                          ),
                        ),
                        Row(
                          children: List.generate(
                            registeredEvents.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: _currentIndex == index ? 24 : 8,
                              height: 6,
                              decoration: BoxDecoration(
                                color: _currentIndex == index
                                    ? const Color(0xFF00CED1)
                                    : AppColors.textDim.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: registeredEvents.length,
                    onPageChanged: (index) => setState(() => _currentIndex = index),
                    itemBuilder: (context, index) {
                      final event = registeredEvents[index];
                      return _buildQrCard(
                        eventId: event.id,
                        eventName: event.name,
                        eventDate: DateFormat('dd/MM/yyyy').format(event.date),
                        eventLocation: event.location,
                        userName: userName,
                        userId: userId,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'SWIPE FOR OTHER PASSES',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: AppColors.textDim,
                    letterSpacing: 1,
                  ),
                ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                  .fadeIn(duration: 1.seconds),
                const SizedBox(height: 48),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildScanTab() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'SCAN REGISTRATION CODE',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Align the QR code within the frame to verify',
            style: GoogleFonts.inter(fontSize: 12, color: AppColors.textDim),
          ),
          const Spacer(),
          // Scanner Frame
          Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 2),
                ),
              ),
              // Scanner Corners
              ..._buildScannerCorners(),
              // Scanning Line
              AnimatedBuilder(
                animation: _scannerAnimationController,
                builder: (context, child) {
                  return Positioned(
                    top: 20 + (_scannerAnimationController.value * 240),
                    child: Container(
                      width: 220,
                      height: 3,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            const Color(0xFF00CED1),
                            Colors.transparent,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00CED1).withValues(alpha: 0.5),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const Icon(Icons.qr_code_2_rounded, size: 100, color: Colors.white10),
            ],
          ),
          const Spacer(),
          _buildInfoNote('Scan other members or event staff QR to network instantly.'),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  List<Widget> _buildScannerCorners() {
    const double size = 40;
    const double thickness = 4;
    final Color color = const Color(0xFF00CED1);
    
    return [
      // Top Left
      Positioned(
        top: 0, left: 0,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: color, width: thickness),
                left: BorderSide(color: color, width: thickness)
            ),
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20)),
          ),
        ),
      ),
      // Top Right
      Positioned(
        top: 0, right: 0,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            border: Border(
                top: BorderSide(color: color, width: thickness),
                right: BorderSide(color: color, width: thickness)
            ),
            borderRadius: const BorderRadius.only(topRight: Radius.circular(20)),
          ),
        ),
      ),
      // Bottom Left
      Positioned(
        bottom: 0, left: 0,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: color, width: thickness),
                left: BorderSide(color: color, width: thickness)
            ),
            borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20)),
          ),
        ),
      ),
      // Bottom Right
      Positioned(
        bottom: 0, right: 0,
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            border: Border(
                bottom: BorderSide(color: color, width: thickness),
                right: BorderSide(color: color, width: thickness)
            ),
            borderRadius: const BorderRadius.only(bottomRight: Radius.circular(20)),
          ),
        ),
      ),
    ];
  }

  Widget _buildInfoNote(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, size: 16, color: Color(0xFF00CED1)),
          const SizedBox(width: 12),
          Expanded(child: Text(text, style: TextStyle(color: AppColors.textDim, fontSize: 11))),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_2_rounded,
            size: 80,
            color: AppColors.textDim.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'No Active Passes',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Your entry passes will appear here once you register for an event.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textDim.withValues(alpha: 0.5),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrCard({
    required String eventId,
    required String eventName,
    required String eventDate,
    required String eventLocation,
    required String userName,
    required String userId,
  }) {
    final qrData = _generateQrData(eventId);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with event name
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF00CED1), const Color(0xFF00CED1).withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eventName.toUpperCase(),
                        style: GoogleFonts.outfit(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ADMIT ONE',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.black.withValues(alpha: 0.6),
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.confirmation_num_rounded, color: Colors.black, size: 24),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTicketDetail('ATTENDEE', userName),
                      _buildTicketDetail('DATE', eventDate),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildTicketDetail('VENUE', eventLocation.split(',')[0]),
                      _buildTicketDetail('ID', userId.substring(0, 8).toUpperCase()),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // QR Container - Modernized shape
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 15,
                        ),
                      ],
                    ),
                    child: QrImageView(
                      data: qrData,
                      version: QrVersions.auto,
                      size: 150,
                      gapless: true,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'PRESENT AT THE GATE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textDim,
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketDetail(String label, String value) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: AppColors.textDim,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
