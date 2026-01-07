import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';

import '../../../../features/auth/presentation/widgets/auth_widgets.dart';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';

class AdminModerationScreen extends StatefulWidget {
  const AdminModerationScreen({super.key});

  @override
  State<AdminModerationScreen> createState() => _AdminModerationScreenState();
}

class _AdminModerationScreenState extends State<AdminModerationScreen> {
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
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'Content Moderation',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.codingRimPrimary,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Event Review'),
              Tab(text: 'User Feedback'),
            ],
          ),
        ),
        body: AnimatedGradientBackground(
          child: TabBarView(
            children: [
              _buildEventModerationList(),
              _buildFeedbackModerationList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEventModerationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 3,
      itemBuilder: (context, index) {
        return _buildModerationCard(
          context,
          'Pending Event Approval',
          'Workshop on Cloud Native by OrganizerX',
          Icons.event_note_rounded,
          AppColors.codingRimPrimary,
        );
      },
    );
  }

  Widget _buildFeedbackModerationList() {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 4,
      itemBuilder: (context, index) {
        return _buildModerationCard(
          context,
          'User Report',
          'Inappropriate comment on Techathon 2025',
          Icons.report_problem_rounded,
          AppColors.error,
        );
      },
    );
  }

  Widget _buildModerationCard(BuildContext context, String title, String description, IconData icon, Color color) {
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
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color),
            ),
            title: Text(
              title,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            subtitle: Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {},
                  child: const Text('Dismiss', style: TextStyle(color: AppColors.textDim)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success.withValues(alpha: 0.1),
                    foregroundColor: AppColors.success,
                    elevation: 0,
                  ),
                  child: const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error.withValues(alpha: 0.1),
                    foregroundColor: AppColors.error,
                    elevation: 0,
                  ),
                  child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.bold)),
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
