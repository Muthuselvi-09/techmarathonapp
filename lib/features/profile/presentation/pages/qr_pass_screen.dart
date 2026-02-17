import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:flutter_animate/flutter_animate.dart';

class QrPassScreen extends ConsumerStatefulWidget {
  const QrPassScreen({super.key});

  @override
  ConsumerState<QrPassScreen> createState() => _QrPassScreenState();
}

class _QrPassScreenState extends ConsumerState<QrPassScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  final Color _gold = const Color(0xFFFFD700);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'QR HUB',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMyTicketsTab(user),
                _buildNetworkingTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
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
          color: _gold,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.black,
        unselectedLabelColor: Colors.white60,
        labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 13),
        tabs: const [
          Tab(text: 'MY TICKETS'),
          Tab(text: 'NETWORKING'),
        ],
      ),
    );
  }

  Widget _buildMyTicketsTab(User? user) {
    if (user == null) {
      return Center(
        child: Text('Please login to view your tickets', 
        style: GoogleFonts.outfit(color: Colors.white24)));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('entryPasses')
          .where('status', whereIn: ['ACTIVE', 'USED']) // Exclude CANCELLED tickets
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.codingRimPrimary));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }

        final passes = snapshot.data!.docs
            .map((doc) => EntryPass.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: passes.length,
          itemBuilder: (context, index) {
            return _ticketItem(passes[index]);
          },
        );
      },
    );
  }

  Widget _ticketItem(EntryPass pass) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('events').doc(pass.eventId).snapshots(),
      builder: (context, eventSnapshot) {
        if (!eventSnapshot.hasData || !eventSnapshot.data!.exists) {
          return const SizedBox.shrink();
        }

        final event = CodingEvent.fromFirestore(eventSnapshot.data!);
        final bool isUsed = pass.status == 'USED';

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        image: DecorationImage(
                          image: NetworkImage(event.imageUrl),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.name,
                            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            DateFormat('EEE, MMM d • hh:mm a').format(event.date),
                            style: GoogleFonts.outfit(color: _gold, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(pass.status),
                  ],
                ),
              ),
              
              const Divider(color: Colors.white10),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Column(
                  children: [
                    _qrView(pass, event.id),
                    const SizedBox(height: 20),
                    Text(
                      pass.userName.toUpperCase(),
                      style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 2),
                    ),
                    Text(
                      'PASS ID: ${pass.id.substring(pass.id.length - 8).toUpperCase()}',
                      style: GoogleFonts.outfit(color: Colors.white24, fontSize: 10),
                    ),
                  ],
                ),
              ),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: isUsed ? Colors.white.withValues(alpha: 0.02) : _gold.withValues(alpha: 0.05),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                ),
                child: Center(
                  child: Text(
                    isUsed ? 'ENTRY COMPLETED' : 'SHOW AT THE ENTRANCE',
                    style: GoogleFonts.outfit(
                      color: isUsed ? Colors.white24 : _gold,
                      fontWeight: FontWeight.w900,
                      fontSize: 11,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1);
      },
    );
  }

  Widget _qrView(EntryPass pass, String eventId) {
    final String qrData = '${pass.eventId}:${pass.userId}:${pass.id}';
    final bool isUsed = pass.status == 'USED';
    
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Opacity(
            opacity: isUsed ? 0.1 : 1.0,
            child: QrImageView(
              data: qrData,
              version: QrVersions.auto,
              size: 160.0,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
              dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
            ),
          ),
        ),
        if (isUsed)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white12),
            ),
            child: Text(
              'USED',
              style: GoogleFonts.outfit(color: Colors.white38, fontWeight: FontWeight.w900, letterSpacing: 2),
            ),
          ),
      ],
    );
  }

  Widget _statusBadge(String status) {
    final bool isUsed = status == 'USED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isUsed ? Colors.white10 : Colors.green.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: GoogleFonts.outfit(color: isUsed ? Colors.white24 : Colors.greenAccent, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNetworkingTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_alt_rounded, size: 60, color: _gold.withValues(alpha: 0.3)),
          const SizedBox(height: 24),
          Text(
            'NETWORKING MODE',
            style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Scan other participants to connect and exchange digital contact cards.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.white38, fontSize: 13),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Networking scan would go here
            },
            icon: const Icon(Icons.qr_code_scanner_rounded),
            label: const Text('SCAN OTHERS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _gold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.confirmation_num_outlined, size: 64, color: Colors.white10),
          const SizedBox(height: 16),
          Text('No Tickets Found', style: GoogleFonts.outfit(color: Colors.white24, fontSize: 18)),
          const SizedBox(height: 8),
          Text('Join an event to see your passes here', style: GoogleFonts.inter(color: Colors.white12, fontSize: 12)),
        ],
      ),
    );
  }
}
