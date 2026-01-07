import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../features/auth/presentation/widgets/auth_widgets.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class AdminReportsScreen extends StatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  State<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends State<AdminReportsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _verifyAdminRole();
  }

  Future<void> _verifyAdminRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Access Denied: Admin verification failed.')),
          );
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Reports & Analytics',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedGradientBackground(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMetricSection(),
              const SizedBox(height: 32),
              _buildChartPlaceholder('Revenue Growth (Last 30 Days)'),
              const SizedBox(height: 32),
              _buildChartPlaceholder('User Registration Trend'),
              const SizedBox(height: 32),
              _buildTopPerformers(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricSection() {
    return Column(
      children: [
        Row(
          children: [
            _buildMetricCard('Total Users', '1,284', Icons.people_rounded, AppColors.zhaCommercePrimary),
            const SizedBox(width: 16),
            _buildMetricCard('Total Events', '42', Icons.event_rounded, AppColors.codingRimPrimary),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _buildMetricCard('Total Bookings', '2,401', Icons.confirmation_num_rounded, AppColors.accent),
            const SizedBox(width: 16),
            _buildMetricCard('Total Revenue', '₹1.2L', Icons.account_balance_wallet_rounded, AppColors.codingRimSecondary),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartPlaceholder(String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          ),
          child: Center(
            child: Icon(
              Icons.bar_chart_rounded,
              size: 80,
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTopPerformers() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Performing Events',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: 3,
          itemBuilder: (context, index) {
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: AppColors.cardBg,
                    child: Text('${index + 1}', style: const TextStyle(color: AppColors.primary)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Event Name $index', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Bookings: ${500 - (index * 100)}', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
                      ],
                    ),
                  ),
                  Text('₹${50 - (index * 10)}K', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary)),
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}
