import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/presentation/providers/event_stream_providers.dart';
import '../../../home/presentation/pages/event_info_screen.dart';

class AllEventsScreen extends ConsumerWidget {
  const AllEventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allEventsAsync = ref.watch(allEventsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'ALL EVENTS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              // If we're on the dashboard but it's not a push (part of IndexedStack)
              // We should navigate to home. However, AllEventsScreen is often used
              // inside MainScaffold where its index is managed.
              // If it's part of the IndexedStack, we shouldn't show the back button or it should switch index.
              context.go('/home');
            }
          },
        ),
      ),
      body: allEventsAsync.when(
        data: (events) {
          if (events.isEmpty) {
            return const Center(
              child: Text(
                'No events found',
                style: TextStyle(color: AppColors.textDim),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(24),
            itemCount: events.length,
            itemBuilder: (context, index) {
              final event = events[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventInfoScreen(eventId: event.id),
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  height: 120,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 100,
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
                          child: event.imageUrl.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: event.imageUrl,
                                  fit: BoxFit.cover,
                                  placeholder: (_, _) => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  errorWidget: (_, _, _) => const Center(
                                    child: Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 40),
                                  ),
                                )
                              : const Center(
                                  child: Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 40),
                                ),
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                event.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_formatDate(event.date)}',
                                style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              Text(
                                event.location,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: AppColors.textDim, fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Simple format matching the user request "Dec 29 | 2:00 PM"
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final month = months[date.month - 1];
    final hour = date.hour > 12 ? date.hour - 12 : (date.hour == 0 ? 12 : date.hour);
    final ampm = date.hour >= 12 ? 'PM' : 'AM';
    final minute = date.minute.toString().padLeft(2, '0');
    return '$month ${date.day} | $hour:$minute $ampm';
  }
}

