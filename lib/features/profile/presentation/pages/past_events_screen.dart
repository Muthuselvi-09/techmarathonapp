import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';
import 'package:tech_marathon_app/features/profile/data/profile_repository.dart';

class PastEventsScreen extends ConsumerStatefulWidget {
  const PastEventsScreen({super.key});

  @override
  ConsumerState<PastEventsScreen> createState() => _PastEventsScreenState();
}

class _PastEventsScreenState extends ConsumerState<PastEventsScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  Set<String> _registeredEventIds = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRegisteredEvents();
  }

  Future<void> _loadRegisteredEvents() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null && data['registeredEvents'] != null) {
        setState(() {
          _registeredEventIds = Set<String>.from(data['registeredEvents']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allEventsAsync = ref.watch(allEventsStreamProvider);
    final userId = _auth.currentUser?.uid;

    if (userId == null) return const Center(child: Text('Please login to view past events'));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'PAST EVENTS',
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
      ),
      body: StreamBuilder<List<String>>(
        stream: ref.watch(profileRepositoryProvider).getRegisteredEventIds(userId),
        builder: (context, registeredSnapshot) {
          if (!registeredSnapshot.hasData) return const Center(child: CircularProgressIndicator());
          final registeredIds = registeredSnapshot.data!;

          return allEventsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
            data: (events) {
              final now = DateTime.now();
              final pastEvents = events.where((event) {
                return event.date.isBefore(now) && registeredIds.contains(event.id);
              }).toList();

              pastEvents.sort((a, b) => b.date.compareTo(a.date));

              if (pastEvents.isEmpty) return _buildEmptyState();

              return ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: pastEvents.length,
                itemBuilder: (context, index) {
                  final event = pastEvents[index];
                  return _buildPastEventCard(
                    eventName: event.name,
                    eventDate: DateFormat('dd/MM/yyyy').format(event.date),
                    location: event.location,
                    imageUrl: event.imageUrl,
                    isFree: event.isFree,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_rounded,
            size: 80,
            color: AppColors.textDim.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No past events',
            style: GoogleFonts.outfit(
              fontSize: 18,
              color: AppColors.textDim,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 48),
            child: Text(
              'Events you\'ve attended will appear here',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textDim.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPastEventCard({
    required String eventName,
    required String eventDate,
    required String location,
    required String imageUrl,
    required bool isFree,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Row(
        children: [
          // Event Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: imageUrl.isNotEmpty
                ? Image.network(
                    imageUrl,
                    width: 100,
                    height: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 100,
                      height: 120,
                      color: AppColors.textDim.withValues(alpha: 0.1),
                      child: const Icon(Icons.event, color: AppColors.textDim),
                    ),
                  )
                : Container(
                    width: 100,
                    height: 120,
                    color: AppColors.textDim.withValues(alpha: 0.1),
                    child: const Icon(Icons.event, color: AppColors.textDim),
                  ),
          ),
          // Event Details
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          eventName,
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'ATTENDED',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Text(
                        eventDate,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 14, color: AppColors.primary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          location,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isFree ? 'Free Entry' : 'Paid Entry',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
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
}
