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
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.codingRimPrimary.withOpacity(0.8),
                      Colors.black87,
                    ],
                  ),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(60)),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.person_add_rounded,
                        size: 60,
                        color: AppColors.codingRimPrimary,
                      ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 16),
                      Text(
                        'ADMIN REGISTRATION',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 4,
                          color: AppColors.codingRimPrimary,
                        ),
                      ).animate().fadeIn(delay: 400.ms),
                      Text(
                        'Create Account',
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    PremiumTextField(
                      controller: _nameController,
                      hintText: 'Full Name',
                      icon: Icons.person_outline_rounded,
                    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _emailController,
                      hintText: 'Admin Email',
                      icon: Icons.alternate_email_rounded,
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: _obscurePassword,
                    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm Password',
                      icon: Icons.lock_clock_outlined,
                      isPassword: _obscurePassword,
                    ).animate().fadeIn(delay: 1.seconds).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 32),
                    
                    PremiumGradientButton(
                      text: _isLoading ? 'CREATING...' : 'CREATE ADMIN',
                      onPressed: _handleSignUp,
                    ).animate().fadeIn(delay: 1.1.seconds).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Already have an admin account? ",
                          style: TextStyle(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: const Text(
                            "Login",
                            style: TextStyle(
                              color: AppColors.codingRimPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1.2.seconds),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
