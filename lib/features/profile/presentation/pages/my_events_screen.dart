import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/home/presentation/providers/event_stream_providers.dart';
import 'package:tech_marathon_app/features/profile/data/profile_repository.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:tech_marathon_app/features/admin/data/admin_repository.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';

class MyEventsScreen extends ConsumerStatefulWidget {
  const MyEventsScreen({super.key});

  @override
  ConsumerState<MyEventsScreen> createState() => _MyEventsScreenState();
}

class _MyEventsScreenState extends ConsumerState<MyEventsScreen> {
// Local state removed, using StreamBuilder exclusively

  @override
  Widget build(BuildContext context) {
    final allEventsAsync = ref.watch(allEventsStreamProvider);
    final userId = FirebaseAuth.instance.currentUser?.uid;

    if (userId == null) return const Center(child: Text('Please login to view events'));

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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
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
              final ongoingEvents = events.where((e) => !e.date.isBefore(DateTime.now().subtract(const Duration(days: 1)))).toList();
              final registeredEvents = events.where((e) => registeredIds.contains(e.id)).toList();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (ongoingEvents.any((e) => !registeredIds.contains(e.id))) ...[
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
                      ...ongoingEvents.where((e) => !registeredIds.contains(e.id)).map((e) => _buildEventCard(
                            eventId: e.id,
                            eventName: e.name,
                            eventDate: DateFormat('dd/MM/yyyy').format(e.date),
                            location: e.location,
                            isRegistered: false,
                            userId: userId,
                          )),
                      const SizedBox(height: 32),
                    ],
                    if (registeredEvents.isNotEmpty) ...[
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
                      ...registeredEvents.map((e) => _buildRegisteredEventCard(
                            eventId: e.id,
                            eventName: e.name,
                            eventDate: DateFormat('dd/MM/yyyy').format(e.date),
                            location: e.location,
                            imageUrl: e.imageUrl,
                            isFree: e.isFree,
                          )),
                    ] else ...[
                      Center(
                        child: Text(
                          'You haven\'t registered for any events yet',
                          style: GoogleFonts.inter(color: Colors.white38),
                        ),
                      ),
                    ],
                  ],
                ),
              );
            },
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
    required bool isRegistered,
    required String userId,
  }) {

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
              onPressed: isRegistered ? null : () async {
                final user = FirebaseAuth.instance.currentUser;
                await ref.read(profileRepositoryProvider).registerEvent(userId, eventId, userName: user?.displayName);
              },
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
    required String imageUrl,
    required bool isFree,
  }) {
    return GestureDetector(
      onTap: () => _showTicketModal(
        eventId: eventId,
        eventName: eventName,
        eventDate: eventDate,
        location: location,
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      height: 120,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 120,
                      width: double.infinity,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(Icons.event, color: AppColors.primary),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
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
                          color: isFree ? Colors.green.withValues(alpha: 0.1) : AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          isFree ? 'FREE' : 'PAID',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isFree ? Colors.green : AppColors.primary,
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
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'TAP TO VIEW TICKET',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
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

  void _showTicketModal({
    required String eventId,
    required String eventName,
    required String eventDate,
    required String location,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userName = user?.displayName ?? 'Valued Member';
      final userId = user?.uid ?? 'USER-ID';

      // Fetch all entry passes for this event
      final passes = await ref.read(adminRepositoryProvider).getUserEntryPasses(userId, eventId);
      
      if (passes.isEmpty) {
        // PROACTIVELY FIX: If registered but no tickets exist (legacy data), create one
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (dialogContext) => const Center(child: CircularProgressIndicator()),
          );
          
          try {
            // Pass full userName if available
            await ref.read(adminRepositoryProvider).createEntryPass(eventId, userId, userName);
            
            if (mounted) {
              // Use root navigator to pop the dialog only
              Navigator.of(context, rootNavigator: true).pop(); 
              
              // Allow state to update
              await Future.delayed(const Duration(milliseconds: 500));
              
              // Refresh passes
              final newPasses = await ref.read(adminRepositoryProvider).getUserEntryPasses(userId, eventId);
              if (newPasses.isNotEmpty && mounted) {
                _showTicketModal(
                  eventId: eventId, 
                  eventName: eventName, 
                  eventDate: eventDate, 
                  location: location,
                );
                return;
              }
            }
          } catch (e) {
            debugPrint('❌ Ticket recovery failed: $e');
            if (mounted) {
               Navigator.of(context, rootNavigator: true).pop();
            }
          }
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No tickets found. Please contact support.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        isScrollControlled: true,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.all(32),
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 32),
              Text(
                'YOUR EVENT TICKET${passes.length > 1 ? 'S' : ''}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: PageView.builder(
                  itemCount: passes.length,
                  itemBuilder: (context, index) {
                    final pass = passes[index];
                    return _buildTicketPage(
                      pass: pass,
                      eventName: eventName,
                      eventDate: eventDate,
                      userName: userName,
                      userId: userId,
                    );
                  },
                ),
              ),
              if (passes.length > 1) ...[
                const SizedBox(height: 16),
                // Page indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    passes.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('SAVE TO DEVICE'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error in _showTicketModal: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error displaying ticket: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _buildTicketPage({
    required EntryPass pass,
    required String eventName,
    required String eventDate,
    required String userName,
    required String userId,
  }) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          if (pass.totalTickets > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Ticket ${pass.ticketNumber} of ${pass.totalTickets}',
                    style: GoogleFonts.inter(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  // Show action buttons only for ACTIVE tickets
                  if (pass.status == 'ACTIVE')
                    Row(
                      children: [
                        // Share button
                        IconButton(
                          onPressed: () => _shareTicket(pass, eventName, eventDate),
                          icon: const Icon(Icons.share_rounded, color: AppColors.primary, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Cancel button
                        IconButton(
                          onPressed: () => _cancelTicket(pass, eventName),
                          icon: const Icon(Icons.cancel_rounded, color: Colors.red, size: 20),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.red.withValues(alpha: 0.1),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
            ),
            child: Column(
              children: [
                Text(
                  eventName.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  eventDate,
                  style: GoogleFonts.inter(color: AppColors.primary, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.white10),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ATTENDEE', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        Text(userName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('CHECK-IN STATUS', style: TextStyle(color: Colors.white38, fontSize: 10)),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: pass.status == 'USED' 
                                    ? Colors.green 
                                    : pass.status == 'CANCELLED'
                                    ? Colors.red
                                    : Colors.orange,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              pass.status == 'USED' 
                                  ? 'CHECKED IN' 
                                  : pass.status == 'CANCELLED'
                                  ? 'CANCELLED'
                                  : 'PENDING',
                              style: TextStyle(
                                color: pass.status == 'USED' 
                                    ? Colors.green 
                                    : pass.status == 'CANCELLED'
                                    ? Colors.red
                                    : Colors.orange,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: QrImageView(
                    data: pass.id,
                    version: QrVersions.auto,
                    size: 150.0,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'ID: ${pass.id.substring(pass.id.length - 8).toUpperCase()}',
                  style: GoogleFonts.robotoMono(
                    color: AppColors.textDim,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 24),
                _buildTermsSection(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _shareTicket(EntryPass pass, String eventName, String eventDate) {
    final shareText = '''
🎟️ EVENT TICKET

Event: $eventName
Date: $eventDate
Ticket: ${pass.ticketNumber} of ${pass.totalTickets}
Status: ${pass.status}

Ticket ID: ${pass.id}
QR Code: ${pass.id}

⚠️ Important: Each ticket has a unique ID and QR code. This ticket can only be used once for entry. Share this with someone if you cannot attend.
    ''';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.share_rounded, color: AppColors.primary),
            const SizedBox(width: 12),
            Text('Share Ticket', style: GoogleFonts.outfit(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share this ticket with a friend or family member who can attend on your behalf.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.security_rounded, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Each ticket has a unique QR code. No scam possible!',
                      style: GoogleFonts.inter(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Future: Implement actual share functionality with share_plus package
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Ticket details copied: $shareText'),
                  backgroundColor: Colors.green,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copy Details'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  void _cancelTicket(EntryPass pass, String eventName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.cancel_rounded, color: Colors.red),
            const SizedBox(width: 12),
            Text('Cancel Ticket?', style: GoogleFonts.outfit(color: Colors.white)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to cancel this ticket for $eventName?',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.info_outline_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Refund Information',
                        style: GoogleFonts.inter(
                          color: Colors.red,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '• Ticket will be cancelled immediately\n• Your seat will be released\n• Refund will be processed to original payment method\n• This action cannot be undone',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Ticket'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final userId = FirebaseAuth.instance.currentUser?.uid;
                if (userId != null) {
                  await ref.read(adminRepositoryProvider).cancelTicket(userId, pass.id, pass.eventId);
                  if (context.mounted) {
                    Navigator.pop(context); // Close dialog
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Ticket cancelled successfully! Refund will be processed.'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error cancelling ticket: $e'), backgroundColor: Colors.red),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Ticket'),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TERMS OF ENTRY',
          style: GoogleFonts.outfit(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary, letterSpacing: 1),
        ),
        const SizedBox(height: 8),
        Text(
          '• Please arrive 15 mins before the event start time.\n• Carry a valid ID for verification.\n• Entry is non-transferable.',
          style: GoogleFonts.inter(fontSize: 10, color: Colors.white54, height: 1.5),
        ),
      ],
    );
  }
}
