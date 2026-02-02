import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user?.email == null) return;

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset email sent to ${user.email}'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.message}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        context.go('/'); // Navigate to Auth Check / Login
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Logout failed: $e')),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'PRIVACY & SECURITY',
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
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildActionTile(
              icon: Icons.lock_reset,
              title: 'Change Password',
              subtitle: 'Send a password reset link to your email',
              onTap: _isLoading ? null : _resetPassword,
            ),
            const SizedBox(height: 16),
            _buildActionTile(
              icon: Icons.logout,
              title: 'Logout',
              subtitle: 'Sign out of your account on this device',
              isDestructive: true,
              onTap: _isLoading ? null : _logout,
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 32),
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback? onTap,
    bool isDestructive = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDestructive
                ? AppColors.error.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isDestructive ? AppColors.error : AppColors.primary,
          ),
        ),
        title: Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: isDestructive ? AppColors.error : AppColors.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        onTap: onTap,
      ),
    );
  }
}
