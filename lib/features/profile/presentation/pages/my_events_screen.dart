import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';

class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({super.key});

  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen> {
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
    if (userId == null) return;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null && data['registeredEvents'] != null) {
        if (mounted) {
          setState(() {
            _registeredEventIds = Set<String>.from(data['registeredEvents']);
            _isLoading = false;
          });
        }
      } else {
        if (mounted) setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _registerForEvent(String eventId, String eventName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set({
        'registeredEvents': FieldValue.arrayUnion([eventId]),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() {
          _registeredEventIds.add(eventId);
        });
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully registered for $eventName'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Watch all events from repository instead of just one if we want "Available Events"
    final currentEventAsync = ref.watch(currentEventStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'MY EVENTS',
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
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : currentEventAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
              data: (activeEvent) {
                if (activeEvent == null) {
                  return const Center(child: Text('No active events available', style: TextStyle(color: Colors.white54)));
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AVAILABLE EVENTS',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 2,
                          color: AppColors.textDim,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildEventCard(
                        eventId: activeEvent.id,
                        eventName: activeEvent.name,
                        eventDate: '${activeEvent.date.day}/${activeEvent.date.month}/${activeEvent.date.year}',
                        location: activeEvent.location,
                      ),
                      const SizedBox(height: 32),
                      if (_registeredEventIds.isNotEmpty) ...[
                        Text(
                          'MY REGISTERED EVENTS',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 2,
                            color: AppColors.textDim,
                          ),
                        ),
                        const SizedBox(height: 16),
                        // For now we only show the card if it matches the current active event or is in the list
                        if (_registeredEventIds.contains(activeEvent.id))
                          _buildRegisteredEventCard(
                            eventId: activeEvent.id,
                            eventName: activeEvent.name,
                            eventDate: '${activeEvent.date.day}/${activeEvent.date.month}/${activeEvent.date.year}',
                            location: activeEvent.location,
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEventCard({
    required String eventId,
    required String eventName,
    required String eventDate,
    required String location,
  }) {
    final isRegistered = _registeredEventIds.contains(eventId);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eventName,
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                eventDate,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isRegistered ? null : () => _registerForEvent(eventId, eventName),
              style: ElevatedButton.styleFrom(
                backgroundColor: isRegistered ? AppColors.textDim : AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isRegistered ? 'Registered' : 'Register (Free)',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRegisteredEventCard({
    required String eventId,
    required String eventName,
    required String eventDate,
    required String location,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  eventName,
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Registered',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                eventDate,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
