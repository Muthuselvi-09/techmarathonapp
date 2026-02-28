import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ParticipantsScreen extends ConsumerWidget {
  const ParticipantsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync = ref.watch(participantsStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'PARTICIPANTS',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: participantsAsync.when(
        data: (participants) => ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: participants.length,
          itemBuilder: (context, index) {
            final p = participants[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: p.profileImage != null && p.profileImage!.isNotEmpty 
                        ? NetworkImage(p.profileImage!) 
                        : null,
                    backgroundColor: AppColors.background,
                    child: p.profileImage == null || p.profileImage!.isEmpty 
                        ? const Icon(Icons.person, color: AppColors.primary) 
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name.isEmpty ? 'Unknown User' : p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          p.email,
                          style: const TextStyle(color: AppColors.textDim, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      TextButton(
                        onPressed: () => context.push('/member-profile', extra: p),
                        child: const Text('VIEW PROFILE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                      if (ref.watch(authStateProvider).valueOrNull?.uid != p.id && 
                          ref.watch(authStateProvider).valueOrNull?.email != p.email)
                        ElevatedButton(
                          onPressed: () => context.push('/chat', extra: p),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                            foregroundColor: AppColors.primary,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('CHAT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.white))),
      ),
    );
  }
}
