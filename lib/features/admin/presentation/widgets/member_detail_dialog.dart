import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/domain/event_models.dart';

class MemberDetailDialog extends StatelessWidget {
  final Participant member;

  const MemberDetailDialog({super.key, required this.member});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Member Details',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: Colors.white54),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Profile Image
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: member.profileImage != null && member.profileImage!.isNotEmpty
                      ? NetworkImage(member.profileImage!)
                      : null,
                  backgroundColor: AppColors.codingRimPrimary.withValues(alpha: 0.2),
                  child: member.profileImage == null || member.profileImage!.isEmpty
                      ? const Icon(Icons.person, size: 50, color: AppColors.codingRimPrimary)
                      : null,
                ),
                // Online/Offline Indicator
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: member.isOnline ? const Color(0xFF00FF94) : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 3),
                    ),
                    child: const SizedBox(width: 12, height: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Name
            Text(
              member.name,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: member.isOnline 
                    ? const Color(0xFF00FF94).withValues(alpha: 0.2) 
                    : Colors.grey.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                member.isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: member.isOnline ? const Color(0xFF00FF94) : Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Details Section
            _buildDetailRow(Icons.email_outlined, 'Email', member.email),
            const SizedBox(height: 12),
            _buildDetailRow(Icons.phone_outlined, 'Mobile', member.mobile),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.calendar_today_outlined,
              'Joined',
              member.joinedAt != null 
                  ? DateFormat('MMM dd, yyyy').format(member.joinedAt!)
                  : 'N/A',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.access_time_outlined,
              'Last Active',
              member.lastActive != null 
                  ? DateFormat('MMM dd, yyyy HH:mm').format(member.lastActive!)
                  : 'N/A',
            ),
            const SizedBox(height: 12),
            _buildDetailRow(
              Icons.badge_outlined,
              'Role',
              member.role.toUpperCase(),
            ),
            const SizedBox(height: 12),

            // Profile Completion
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile Completion',
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${(member.profileCompletion * 100).toInt()}%',
                      style: GoogleFonts.inter(
                        color: AppColors.codingRimPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: member.profileCompletion,
                    backgroundColor: Colors.white10,
                    valueColor: const AlwaysStoppedAnimation(AppColors.codingRimPrimary),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Close Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.codingRimPrimary,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Close',
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.codingRimPrimary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.codingRimPrimary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: Colors.white54,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
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
