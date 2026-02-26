import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'package:tech_marathon_app/features/auth/data/auth_repository.dart';
import '../../../../features/home/presentation/providers/branding_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _lineController;

  @override
  void initState() {
    super.initState();
    _lineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _navigateToNext();
  }

  @override
  void dispose() {
    _lineController.dispose();
    super.dispose();
  }

  void _navigateToNext() async {
    await Future.delayed(const Duration(milliseconds: 3000));
    if (!mounted) return;

    final user = ref.read(authStateProvider).valueOrNull;
    
    if (user != null) {
      context.go('/home');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background Gradient (Softer)
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.splashGradient,
            ),
          ),
          
          // Animated Glowing Lines Painter
          AnimatedBuilder(
            animation: _lineController,
            builder: (context, child) {
              return CustomPaint(
                painter: GlowingLinesPainter(_lineController.value),
                size: Size.infinite,
              );
            },
          ),

          // Central Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo Reveal (Image-based)
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.2),
                        blurRadius: 40,
                        spreadRadius: 5,
                      ),
                    ],
                    color: Colors.white,
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Image.asset(
                    'assets/images/handshake_logo.png',
                    fit: BoxFit.contain,
                  ),
                )
                .animate()
                .fadeIn(duration: 800.ms)
                .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), curve: Curves.easeOutBack, duration: 1000.ms)
                .shimmer(delay: 1500.ms, duration: 1000.ms),

                const SizedBox(height: 48),

                // App Name
                const Text(
                  'EVENT MANAGEMENT',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 3,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(delay: 500.ms, duration: 800.ms)
                .slideY(begin: 0.5, end: 0, curve: Curves.easeOut),

                const SizedBox(height: 16),

                // Tagline
                Text(
                  'Where Ideas Meet Experience',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                    letterSpacing: 2,
                    fontWeight: FontWeight.w300,
                  ),
                )
                .animate()
                .fadeIn(delay: 1200.ms, duration: 800.ms),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class GlowingLinesPainter extends CustomPainter {
  final double animationValue;
  GlowingLinesPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.neonAccent.withOpacity(0.1)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final random = math.Random(42);
    for (int i = 0; i < 15; i++) {
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;
      final length = 100 + random.nextDouble() * 200;
      final angle = (random.nextDouble() * 360) * (math.pi / 180);

      final endX = startX + math.cos(angle + (animationValue * 0.2)) * length;
      final endY = startY + math.sin(angle + (animationValue * 0.2)) * length;

      canvas.drawLine(
        Offset(startX, startY),
        Offset(endX, endY),
        paint,
      );
      
      // Add a small node at the end
      canvas.drawCircle(
        Offset(endX, endY),
        2,
        Paint()..color = AppColors.neonAccent.withOpacity(0.2),
      );
    }
    
    // Abstract grid lines
    final gridPaint = Paint()
      ..color = AppColors.electricPurple.withOpacity(0.05)
      ..strokeWidth = 0.5;
      
    double spacing = 40;
    for (double i = 0; i < size.width; i += spacing) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), gridPaint);
    }
    for (double i = 0; i < size.height; i += spacing) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), gridPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

