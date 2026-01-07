import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../features/auth/presentation/widgets/auth_widgets.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class AdminBookingManagementScreen extends StatefulWidget {
  const AdminBookingManagementScreen({super.key});

  @override
  State<AdminBookingManagementScreen> createState() => _AdminBookingManagementScreenState();
}

class _AdminBookingManagementScreenState extends State<AdminBookingManagementScreen> {
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
          'Ticket & Booking Control',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        ),
      ),
      body: AnimatedGradientBackground(
        child: Column(
          children: [
            _buildBookingSummary(),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: 5,
                itemBuilder: (context, index) {
                  return _buildBookingCard(context, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingSummary() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          _buildSummaryItem('Active', '856', AppColors.primary),
          const SizedBox(width: 12),
          _buildSummaryItem('Pending', '12', AppColors.warning),
          const SizedBox(width: 12),
          _buildSummaryItem('Refunds', '4', AppColors.error),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                color: AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: const CircleAvatar(
              backgroundColor: AppColors.cardBg,
              child: Icon(Icons.confirmation_num_rounded, color: AppColors.primary),
            ),
            title: Text(
              'Booking #TXN12345$index',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            subtitle: Text(
              'User: John Doe | Event: Tech Marathon',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
            trailing: Text(
              '₹499',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('View Ticket', style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    foregroundColor: AppColors.error,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    elevation: 0,
                  ),
                  child: const Text('Refund', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
