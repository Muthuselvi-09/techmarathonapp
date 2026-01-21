import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

class FoodCourseScreen extends StatelessWidget {
  const FoodCourseScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'FOOD & COURSES',
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('MEAL TIMINGS'),
            const SizedBox(height: 16),
            _buildMealCard(
              meal: 'Breakfast',
              time: '8:00 AM - 9:00 AM',
              location: 'Ground Floor Cafeteria',
              items: 'Continental breakfast, Fresh juice, Coffee & Tea',
            ),
            const SizedBox(height: 12),
            _buildMealCard(
              meal: 'Lunch',
              time: '12:30 PM - 2:00 PM',
              location: 'Main Hall Dining Area',
              items: 'Buffet lunch, Vegetarian & Non-veg options, Desserts',
            ),
            const SizedBox(height: 12),
            _buildMealCard(
              meal: 'Snacks',
              time: '4:00 PM - 4:30 PM',
              location: 'Lounge Area - 2nd Floor',
              items: 'Evening snacks, Beverages, Fresh fruits',
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('FOOD COUNTER INFO'),
            const SizedBox(height: 16),
            _buildInfoCard(
              icon: Icons.restaurant,
              title: 'Counter Locations',
              content: 'Main counter on Ground Floor, Express counter on 2nd Floor',
            ),
            const SizedBox(height: 12),
            _buildInfoCard(
              icon: Icons.local_dining,
              title: 'Dietary Options',
              content: 'Vegetarian, Vegan, and Gluten-free options available',
            ),
            const SizedBox(height: 32),
            _buildSectionHeader('COURSE SESSIONS'),
            const SizedBox(height: 16),
            _buildCourseSession(
              time: '10:00 AM - 11:30 AM',
              title: 'AI & Machine Learning Fundamentals',
              speaker: 'Dr. Sarah Johnson',
              room: 'Workshop Room 1',
            ),
            const SizedBox(height: 12),
            _buildCourseSession(
              time: '11:45 AM - 1:15 PM',
              title: 'Cloud Architecture Best Practices',
              speaker: 'Michael Chen',
              room: 'Workshop Room 2',
            ),
            const SizedBox(height: 12),
            _buildCourseSession(
              time: '2:30 PM - 4:00 PM',
              title: 'Modern Mobile Development',
              speaker: 'Emily Rodriguez',
              room: 'Workshop Room 3',
            ),
            const SizedBox(height: 12),
            _buildCourseSession(
              time: '4:30 PM - 6:00 PM',
              title: 'Cybersecurity Essentials',
              speaker: 'James Wilson',
              room: 'Workshop Room 1',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontWeight: FontWeight.w900,
        fontSize: 12,
        letterSpacing: 2,
        color: AppColors.textDim,
      ),
    );
  }

  Widget _buildMealCard({
    required String meal,
    required String time,
    required String location,
    required String items,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.restaurant_menu, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.textDim, size: 16),
              const SizedBox(width: 8),
              Text(
                location,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            items,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({required IconData icon, required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  content,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseSession({
    required String time,
    required String title,
    required String speaker,
    required String room,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  // ignore: deprecated_member_use
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  time,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.textDim, size: 16),
              const SizedBox(width: 8),
              Text(
                speaker,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.meeting_room, color: AppColors.textDim, size: 16),
              const SizedBox(width: 8),
              Text(
                room,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
