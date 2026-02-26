import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';
import '../widgets/auth_widgets.dart';
import 'package:tech_marathon_app/features/auth/presentation/providers/auth_provider.dart';

class AdminLoginScreen extends ConsumerStatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  ConsumerState<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends ConsumerState<AdminLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter both email and password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Step 1: Authenticate with Firebase
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user?.uid;
      if (uid == null) throw Exception('Authentication failed.');

      // Step 2: Check 'admin login' collection first (primary admin store)
      final adminLoginDoc = await FirebaseFirestore.instance
          .collection('admin login')
          .doc(uid)
          .get();

      // Also check 'users' collection as fallback
      final usersDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      final roleFromAdminLogin = adminLoginDoc.data()?['role'] as String?;
      final roleFromUsers      = usersDoc.data()?['role'] as String?;
      final isAdmin = roleFromAdminLogin == 'admin' || roleFromUsers == 'admin';

      if (!isAdmin) {
        // Not an admin — sign them out immediately
        await FirebaseAuth.instance.signOut();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Access denied. This portal is for admins only.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Step 3: Confirmed admin — allow access
      ref.read(isAdminLoggedInProvider.notifier).state = true;

      if (mounted) {
        context.push('/admin');
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Authentication failed')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
            color: AppColors.saasPrimary.withValues(alpha: 0.2),
            size: 400,
            offset: const Offset(-100, -100),
            duration: 15.seconds,
          ),
          _DriftingOrb(
            color: Colors.blueAccent.withValues(alpha: 0.1),
            size: 300,
            offset: const Offset(300, 500),
            duration: 20.seconds,
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Brand Logo Area
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.03),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                      ),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        size: 64,
                        color: AppColors.saasPrimary,
                      ),
                    ).animate().fadeIn(duration: 800.ms).scale(begin: const Offset(0.8, 0.8)),
                    
                    const SizedBox(height: 32),
                    
                    Text(
                      'ADMIN PORTAL',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 6,
                        color: AppColors.saasPrimary,
                      ),
                    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 12),
                    
                    Text(
                      'Welcome Back',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
                    
                    const SizedBox(height: 48),
                    
                    // Glassmorphic Login Card
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
                            controller: _emailController,
                            hintText: 'Admin Email',
                            icon: Icons.alternate_email_rounded,
                          ),
                          const SizedBox(height: 20),
                          _SaasTextField(
                            controller: _passwordController,
                            hintText: 'Password',
                            icon: Icons.lock_outline_rounded,
                            isPassword: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: Colors.white38,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => context.push('/admin-forgot-password'),
                              child: Text(
                                'Forgot Password?',
                                style: GoogleFonts.inter(
                                  color: AppColors.saasTextSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          _SaasButton(
                            text: _isLoading ? 'SIGNING IN...' : 'LOGIN',
                            onPressed: _isLoading ? () {} : _handleLogin,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 32),
                    
                    // Footer
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "New Admin? ",
                          style: GoogleFonts.inter(color: AppColors.saasTextSecondary),
                        ),
                        GestureDetector(
                          onTap: () => context.push('/admin-signup'),
                          child: Text(
                            "Request Access",
                            style: GoogleFonts.inter(
                              color: AppColors.saasPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1.seconds),
                    
                    const SizedBox(height: 40),
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
