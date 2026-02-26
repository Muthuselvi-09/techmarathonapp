import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/auth_widgets.dart';

class AdminSignUpScreen extends StatefulWidget {
  const AdminSignUpScreen({super.key});

  @override
  State<AdminSignUpScreen> createState() => _AdminSignUpScreenState();
}

class _AdminSignUpScreenState extends State<AdminSignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user != null) {
        // Update display name
        await user.updateDisplayName(name);

        // Sync to Firestore admins collection
        await _firestore.collection('admins').doc(user.uid).set({
          'name': name,
          'email': email,
          'role': 'admin',
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          // Direct navigation to admin dashboard
          context.pushReplacement('/admin');
        }
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Registration failed'), backgroundColor: AppColors.error),
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
            color: AppColors.saasPrimary.withValues(alpha: 0.15),
            size: 350,
            offset: const Offset(-50, 400),
            duration: 18.seconds,
          ),
          _DriftingOrb(
            color: Colors.deepPurpleAccent.withValues(alpha: 0.1),
            size: 450,
            offset: const Offset(250, -100),
            duration: 22.seconds,
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    // Header Area
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_outlined,
                        size: 56,
                        color: AppColors.saasPrimary,
                      ),
                    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
                    
                    const SizedBox(height: 24),
                    
                    Text(
                      'ADMIN REGISTRATION',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 4,
                        color: AppColors.saasPrimary,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      'Create New Admin',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 40),
                    
                    // Glassmorphic Form Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(32),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _SaasTextField(
                            controller: _nameController,
                            hintText: 'Full Name',
                            icon: Icons.person_outline_rounded,
                          ).animate().fadeIn(delay: 500.ms).slideX(begin: 0.1, end: 0),
                          const SizedBox(height: 16),
                          _SaasTextField(
                            controller: _emailController,
                            hintText: 'Admin Email',
                            icon: Icons.alternate_email_rounded,
                          ).animate().fadeIn(delay: 600.ms).slideX(begin: 0.1, end: 0),
                          const SizedBox(height: 16),
                          _SaasTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: _obscurePassword,
                          ).animate().fadeIn(delay: 700.ms).slideX(begin: 0.1, end: 0),
                          const SizedBox(height: 16),
                          _SaasTextField(
                            controller: _confirmPasswordController,
                            hintText: 'Confirm Password',
                            icon: Icons.lock_clock_outlined,
                            isPassword: _obscurePassword,
                          ).animate().fadeIn(delay: 800.ms).slideX(begin: 0.1, end: 0),
                          
                          const SizedBox(height: 32),
                          
                          _SaasButton(
                            text: _isLoading ? 'CREATING...' : 'SIGN UP',
                            onPressed: _isLoading ? () {} : _handleSignUp,
                          ).animate().fadeIn(delay: 900.ms),
                        ],
                      ),
                    ).animate().fadeIn(delay: 450.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 32),
                    
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already part of the team? ",
                          style: GoogleFonts.inter(color: AppColors.saasTextSecondary),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Text(
                            "Login",
                            style: GoogleFonts.inter(
                              color: AppColors.saasPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1.1.seconds),
                    
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
          
          // Back Button
          Positioned(
            top: 16,
            left: 16,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => context.pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Reuse internal widgets from Login for consistency 
// (In a real app, these would be in a shared file, but keeping them local for now as requested)

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
