import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_widgets.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      if (next is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });

    return Scaffold(
      body: AnimatedGradientBackground(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top 3D Asset Section
              Stack(
                children: [
                  Container(
                    height: MediaQuery.of(context).size.height * 0.4,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(60)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black26,
                          blurRadius: 40,
                          offset: Offset(0, 20),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(60)),
                      child: Image.network(
                        'https://images.unsplash.com/photo-1620641788421-7a1c342ea42e?q=80&w=1000&auto=format&fit=crop',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ).animate().fadeIn(duration: 1.seconds).slideY(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
                  
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(60)),
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 40,
                    left: 32,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1,
                          ),
                        ).animate().fadeIn(delay: 500.ms).slideX(begin: -0.2, end: 0),
                        const SizedBox(height: 8),
                        Text(
                          'Join our community today',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            color: Colors.white70,
                          ),
                        ).animate().fadeIn(delay: 700.ms),
                      ],
                    ),
                  ),
                  
                  Positioned(
                    top: 50,
                    left: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => context.pop(),
                    ).animate().fadeIn(delay: 1.seconds),
                  ),
                ],
              ),

              // Form Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                child: Column(
                  children: [
                    PremiumTextField(
                      controller: _nameController,
                      hintText: 'Full Name',
                      icon: Icons.person_outline_rounded,
                    ).animate().fadeIn(delay: 800.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _emailController,
                      hintText: 'Email Address',
                      icon: Icons.alternate_email_rounded,
                    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _passwordController,
                      hintText: 'Password',
                      icon: Icons.lock_outline_rounded,
                      isPassword: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: Colors.white60,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ).animate().fadeIn(delay: 1.seconds).slideY(begin: 0.1, end: 0),
                    const SizedBox(height: 16),
                    PremiumTextField(
                      controller: _confirmPasswordController,
                      hintText: 'Confirm Password',
                      icon: Icons.lock_reset_rounded,
                      isPassword: _obscurePassword,
                    ).animate().fadeIn(delay: 1.1.seconds).slideY(begin: 0.1, end: 0),
                    
                    const SizedBox(height: 32),
                    
                    PremiumGradientButton(
                      text: authState.isLoading ? 'CREATING...' : 'REGISTER',
                      onPressed: () async {
                        final email = _emailController.text.trim();
                        final password = _passwordController.text;
                        final confirm = _confirmPasswordController.text;
                        
                        if (email.isNotEmpty && password.isNotEmpty && password == confirm) {
                          await ref.read(authControllerProvider.notifier).signUp(email, password);
                        } else if (password != confirm) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Passwords don't match")),
                          );
                        }
                      },
                    ).animate().fadeIn(delay: 1.2.seconds).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),

                    const SizedBox(height: 32),
                    
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Already have an account? ",
                          style: GoogleFonts.inter(color: Colors.white70),
                        ),
                        GestureDetector(
                          onTap: () => context.pop(),
                          child: Text(
                            "Login",
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 1.4.seconds),
                    const SizedBox(height: 32),
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

