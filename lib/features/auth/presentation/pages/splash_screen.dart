import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigateToNext();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(seconds: 3));
    if (!mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    
    if (user != null) {
      // Per strict requirement: If user != null -> Event Home Screen ONLY
      // Admin Dashboard must NEVER open automatically on app start.
      context.go('/home');
    } else {
      // Not logged in
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: 200,
              width: 200,
              child: Lottie.network(
                'https://assets9.lottiefiles.com/packages/lf20_kyu7xb1v.json', // Tech/Rocket animation
                fit: BoxFit.contain,
              ),
            ).animate().scale(duration: 800.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 24),
            Text(
              'TECH MARATHON',
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    letterSpacing: 4,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
            ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }
}
