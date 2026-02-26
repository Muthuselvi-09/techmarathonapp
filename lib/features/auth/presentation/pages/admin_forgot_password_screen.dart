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
      backgroundColor: AppColors.saasMainBg,
      body: Stack(
        children: [
          // Background Animated Orbs
          _DriftingOrb(
            color: AppColors.saasPrimary.withValues(alpha: 0.1),
            size: 400,
            offset: const Offset(200, 300),
            duration: 20.seconds,
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        size: 64,
                        color: AppColors.saasPrimary,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      'PASSWORD RECOVERY',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppColors.saasPrimary,
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      'Reset Admin Access',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      'Enter your administrator email to receive a secure password reset link.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppColors.saasTextSecondary, fontSize: 14),
                    ).animate().fadeIn(delay: 600.ms),
                    
                    const SizedBox(height: 48),
                    
                    // Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Column(
                        children: [
                          _SaasTextField(
                            controller: _emailController,
                            hintText: 'Admin Email',
                            icon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: 32),
                          _SaasButton(
                            text: _isLoading ? 'SENDING...' : 'SEND RESET LINK',
                            onPressed: _isLoading ? () {} : _handleReset,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 32),
                    
                    TextButton(
                      onPressed: () => context.pop(),
                      child: Text(
                        'Back to Login',
                        style: GoogleFonts.inter(
                          color: AppColors.saasTextSecondary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ).animate().fadeIn(delay: 1.seconds),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Internal widgets for theme consistency
class _DriftingOrb extends StatelessWidget {
  final Color color;
  final double size;
  final Offset offset;
  final Duration duration;

  const _DriftingOrb({
    required this.color,
    required this.size,
    required this.offset,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: offset.dx,
      top: offset.dy,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
          ),
        ),
      ).animate(onPlay: (controller) => controller.repeat(reverse: true))
       .move(begin: const Offset(-20, -20), end: const Offset(20, 20), duration: duration, curve: Curves.easeInOut),
    );
  }
}

class _SaasTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool isPassword;
  final Widget? suffixIcon;

  const _SaasTextField({
    required this.controller,
    required this.hintText,
    required this.icon,
    this.isPassword = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: GoogleFonts.inter(color: Colors.white),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.saasPrimary, size: 20),
          suffixIcon: suffixIcon,
          hintText: hintText,
          hintStyle: GoogleFonts.inter(color: Colors.white38, fontSize: 14),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}

class _SaasButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const _SaasButton({required this.text, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: AppColors.saasGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.saasPrimary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ),
      ),
    ).animate().shimmer(duration: 2.seconds, color: Colors.white24);
  }
}
