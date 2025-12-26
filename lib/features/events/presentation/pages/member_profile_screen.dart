import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../domain/event_models.dart';

class MemberProfileScreen extends ConsumerWidget {
  final Participant member;

  const MemberProfileScreen({super.key, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          'MEMBER PROFILE',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.mainGradient,
              ),
              child: CircleAvatar(
                radius: 60,
                backgroundColor: AppColors.surface,
                backgroundImage: member.profileImage != null && member.profileImage!.isNotEmpty
                    ? NetworkImage(member.profileImage!)
                    : null,
                child: member.profileImage == null || member.profileImage!.isEmpty
                    ? const Icon(Icons.person, size: 60, color: AppColors.textDim)
                    : null,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              member.name,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              member.email,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppColors.textDim,
              ),
            ),
            if (member.mobile.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                member.mobile,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.textDim,
                ),
              ),
            ],
            const SizedBox(height: 48),
            _buildInfoCard(Icons.star_rounded, 'Role', 'Participant'),
            const SizedBox(height: 16),
            _buildInfoCard(Icons.check_circle_rounded, 'Status', 'Verified Member'),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: NeonButton(
                text: 'CHAT NOW',
                onPressed: () {
                  context.push('/chat', extra: member);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textDim,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
