import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/auth_widgets.dart';

class AdminForgotPasswordScreen extends StatefulWidget {
  const AdminForgotPasswordScreen({super.key});

  @override
  State<AdminForgotPasswordScreen> createState() => _AdminForgotPasswordScreenState();
}

class _AdminForgotPasswordScreenState extends State<AdminForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleReset() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your admin email')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _auth.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Password reset link sent to $email'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Reset failed'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: AnimatedGradientBackground(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.codingRimPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_reset_rounded,
                  size: 80,
                  color: AppColors.codingRimPrimary,
                ),
              ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
              const SizedBox(height: 32),
              Text(
                'RESET ADMIN PASSWORD',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ).animate().fadeIn(delay: 400.ms),
              const SizedBox(height: 16),
              const Text(
                'Enter your registered administrator email address to receive a password reset link.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ).animate().fadeIn(delay: 600.ms),
              const SizedBox(height: 48),
              PremiumTextField(
                controller: _emailController,
                hintText: 'Admin Email',
                icon: Icons.alternate_email_rounded,
              ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
              const SizedBox(height: 32),
              PremiumGradientButton(
                text: _isLoading ? 'SENDING...' : 'SEND RESET LINK',
                onPressed: _handleReset,
              ).animate().fadeIn(delay: 1.seconds).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
            ],
          ),
        ),
      ),
    );
  }
}
