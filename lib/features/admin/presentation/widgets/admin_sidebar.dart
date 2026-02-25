import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';

class AdminSidebar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;
  final VoidCallback? onBack;

  const AdminSidebar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: AppColors.saasSidebarBg,
        border: Border(
          right: BorderSide(
            color: AppColors.saasBorder,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: Column(
                children: [
                  _navItem(0, 'Overview', Icons.dashboard_outlined),
                  _navItem(1, 'Events', Icons.event_note_outlined),
                  _navItem(2, 'Participants', Icons.people_outline_rounded),
                  _navItem(3, 'Speakers', Icons.mic_none_rounded),
                  _navItem(4, 'Sponsors', Icons.business_outlined),
                  _navItem(5, 'Schedules', Icons.schedule_rounded),
                  _navItem(6, 'Chat', Icons.chat_bubble_outline_rounded),
                  _navItem(7, 'Branding', Icons.color_lens_outlined),
                  _navItem(8, 'Live Feed', Icons.sensors_rounded),
                  _navItem(9, 'Profile', Icons.person_outline_rounded),
                  const SizedBox(height: 40),
                  _buildBackButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: AppColors.saasGradient.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.saasPrimary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.saasPrimary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'ADMIN PANEL',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              color: AppColors.saasPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _navItem(int index, String label, IconData icon) {
    bool isSelected = currentIndex == index;
    return GestureDetector(
      onTap: () => onTabSelected(index),
      child: AnimatedContainer(
        duration: 300.ms,
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: isSelected ? AppColors.saasGradient : null,
          color: isSelected ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected 
            ? [
                BoxShadow(
                  color: AppColors.saasPrimary.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 4),
                )
              ] 
            : [],
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.saasTextSecondary,
              size: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  color: isSelected ? Colors.white : AppColors.saasTextSecondary,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (index * 50).ms).slideX(begin: -0.1, end: 0);
  }

  Widget _buildBackButton() {
    return InkWell(
      onTap: onBack,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white10),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.logout_rounded, color: Colors.white54, size: 20),
            const SizedBox(width: 16),
            Text(
              'Exit Admin',
              style: GoogleFonts.outfit(
                color: Colors.white54,
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
