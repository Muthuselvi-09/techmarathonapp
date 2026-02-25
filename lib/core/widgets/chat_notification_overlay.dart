import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tech_marathon_app/features/chat/data/chat_repository.dart';
import 'package:tech_marathon_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

class ChatNotificationOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const ChatNotificationOverlay({super.key, required this.child});

  @override
  ConsumerState<ChatNotificationOverlay> createState() => _ChatNotificationOverlayState();
}

class _ChatNotificationOverlayState extends ConsumerState<ChatNotificationOverlay> {
  @override
  void initState() {
    super.initState();
    _setupListeners();
  }

  void _setupListeners() {
    // We can't use ref.listen in initState easily, so we use ref.listen in build or a provider
  }

  void _showNotification(String title, String body, String userId, String userName) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {
              entry.remove();
              context.push('/chat', extra: Participant(
                id: userId,
                name: userName,
                email: '',
                mobile: '',
                profileCompletion: 1.0,
              ));
            },
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.codingRimPrimary.withValues(alpha: 0.3)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.codingRimPrimary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.chat_bubble_rounded, color: AppColors.codingRimPrimary, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          body,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white38, size: 20),
                    onPressed: () => entry.remove(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 4), () {
      if (entry.mounted) entry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Listen for User notifications (when admin replies)
    ref.listen(authStateProvider, (prev, next) {
      final user = next.value;
      if (user != null) {
         // This is just to ensure we have a user. The actual stream listener is below.
      }
    });

    // We can use a provider to watch for new messages
    // but for simplicity here we'll just check the chatRepo
    
    return widget.child;
  }
}
