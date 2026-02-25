import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../../../core/theme/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  double _scrollProgress = 0.0;
  int _currentPage = 0;

  final List<OnboardingData> _pages = [
    OnboardingData(
      title: "Discover Events Around You",
      description: "Explore tech talks, workshops, concerts and more.",
      type: OnboardingType.discover,
    ),
    OnboardingData(
      title: "Book & Manage Seamlessly",
      description: "Easy registration, ticketing, and schedule tracking.",
      type: OnboardingType.booking,
    ),
    OnboardingData(
      title: "Connect & Grow",
      description: "Meet speakers, network with attendees, build opportunities.",
      type: OnboardingType.connect,
    ),
    OnboardingData(
      title: "Your Event Universe Starts Here",
      description: "Step into a smarter way to experience events.",
      type: OnboardingType.universe,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.hasClients) {
        setState(() {
          _scrollProgress = _pageController.page ?? 0.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background with Spotlights
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFF0F0804),
                    Color(0xFF1A120B),
                    Color(0xFF0F0804),
                  ],
                ),
              ),
            ),
          ),
          
          // Spotlight behind illustration
          Center(
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Page View
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return OnboardingPage(
                data: _pages[index],
                index: index,
                scrollProgress: _scrollProgress,
              );
            },
          ),

          // Top Header (Skip)
          Positioned(
            top: 60,
            right: 24,
            child: TextButton(
              onPressed: () => context.go('/login'),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.1,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms),

          // Bottom Controls
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Column(
              children: [
                // Progress Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 400),
                      margin: const EdgeInsets.symmetric(horizontal: 6),
                      height: 4,
                      width: _currentPage == index ? 32 : 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index 
                            ? AppColors.primary 
                            : Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: _currentPage == index ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                          )
                        ] : null,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Action Buttons (Next & Back)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      // Back Button
                      if (_currentPage > 0)
                        Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: _IconButton(
                            icon: Icons.arrow_back_ios_new_rounded,
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutQuart,
                              );
                            },
                          ),
                        ).animate().fadeIn().scale(),
                      
                      // Next / Get Started Button
                      Expanded(
                        child: _PremiumButton(
                          text: _currentPage == _pages.length - 1 ? 'Get Started' : 'Next',
                          onPressed: () {
                            if (_currentPage < _pages.length - 1) {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 600),
                                curve: Curves.easeOutQuart,
                              );
                            } else {
                              context.go('/login');
                            }
                          },
                          isLast: _currentPage == _pages.length - 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum OnboardingType { discover, booking, connect, universe }

class OnboardingData {
  final String title;
  final String description;
  final OnboardingType type;

  OnboardingData({
    required this.title,
    required this.description,
    required this.type,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;
  final int index;
  final double scrollProgress;

  const OnboardingPage({
    super.key,
    required this.data,
    required this.index,
    required this.scrollProgress,
  });

  @override
  Widget build(BuildContext context) {
    // Parallax factor
    final offset = (scrollProgress - index);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Detailed Vector Illustration (Custom Painted)
          SizedBox(
            height: 300,
            width: 300,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Glow Particles
                ...List.generate(5, (i) {
                  final random = math.Random(i);
                  return Positioned(
                    left: random.nextDouble() * 300,
                    top: random.nextDouble() * 300,
                    child: Container(
                      width: 4,
                      height: 4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary.withOpacity(0.3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                    ),
                  ).animate(onPlay: (c) => c.repeat())
                   .moveY(begin: 0, end: -40, duration: (2000 + random.nextInt(2000)).ms)
                   .fadeOut(duration: 1000.ms);
                }),
                
                // Background Layer (Parallax slow)
                Transform.translate(
                  offset: Offset(offset * 40, 0),
                  child: CustomPaint(
                    painter: IllustrationPainter(data.type, true),
                    size: const Size(300, 300),
                  ),
                ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 3.seconds, delay: index.seconds),
                
                // Front Layer (Parallax fast)
                Transform.translate(
                  offset: Offset(offset * 80, 0),
                  child: CustomPaint(
                    painter: IllustrationPainter(data.type, false),
                    size: const Size(300, 300),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 64),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700, // Slightly more weight
              color: Colors.white,
              letterSpacing: 1.2,
              height: 1.2,
            ),
          ).animate(key: ValueKey(data.title))
           .fadeIn(duration: 600.ms, curve: Curves.easeOut)
           .slideY(begin: 0.2, end: 0, curve: Curves.easeOut),

          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.7), // Reduced opacity for hierarchy
              height: 1.5,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.5,
            ),
          ).animate(key: ValueKey(data.description))
           .fadeIn(delay: 200.ms, duration: 600.ms)
           .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }
}

class _PremiumButton extends StatefulWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLast;

  const _PremiumButton({
    required this.text,
    required this.onPressed,
    required this.isLast,
  });

  @override
  State<_PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<_PremiumButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          height: 48, // Reduced from 56
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFD4AF37), Color(0xFFB8860B)], // Gold to Warm Amber
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16), // Increased border radius
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFD4AF37).withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Center(
            child: Text(
              widget.text,
              style: const TextStyle(
                color: Colors.black, // High contrast
                fontSize: 16, // Reduced from 18
                fontWeight: FontWeight.w700,
                letterSpacing: 1.1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _IconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 48, // Reduced from 56
        width: 48,  // Reduced from 56
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1)),
        ),
        child: Icon(icon, color: Colors.white, size: 20), // Reduced size slightly
      ),
    );
  }
}

class IllustrationPainter extends CustomPainter {
  final OnboardingType type;
  final bool isBackground;

  IllustrationPainter(this.type, this.isBackground);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()..style = PaintingStyle.fill;
    
    switch (type) {
      case OnboardingType.discover:
        _drawDiscover(canvas, size, center, paint);
        break;
      case OnboardingType.booking:
        _drawBooking(canvas, size, center, paint);
        break;
      case OnboardingType.connect:
        _drawConnect(canvas, size, center, paint);
        break;
      case OnboardingType.universe:
        _drawUniverse(canvas, size, center, paint);
        break;
    }
  }

  void _drawDiscover(Canvas canvas, Size size, Offset center, Paint paint) {
    if (isBackground) {
      // Draw map background
      paint.color = AppColors.primary.withOpacity(0.1);
      canvas.drawCircle(center, 80, paint);
      
      final linePaint = Paint()
        ..color = AppColors.primary.withOpacity(0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      canvas.drawCircle(center, 100, linePaint);
      canvas.drawCircle(center, 120, linePaint);
    } else {
      // Draw map pin/marker
      paint.color = AppColors.primary;
      final path = Path();
      path.moveTo(center.dx, center.dy + 30);
      path.quadraticBezierTo(center.dx - 25, center.dy - 10, center.dx, center.dy - 30);
      path.quadraticBezierTo(center.dx + 25, center.dy - 10, center.dx, center.dy + 30);
      canvas.drawPath(path, paint);
      
      paint.color = Colors.white;
      canvas.drawCircle(center.translate(0, -10), 8, paint);
    }
  }

  void _drawBooking(Canvas canvas, Size size, Offset center, Paint paint) {
    if (isBackground) {
      paint.color = AppColors.primary.withOpacity(0.1);
      final rect = RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: 140, height: 90), const Radius.circular(12));
      canvas.drawRRect(rect, paint);
    } else {
      paint.color = Colors.white;
      final rect = RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: 100, height: 60), const Radius.circular(8));
      canvas.drawRRect(rect, paint);
      
      // Ticket holes
      paint.color = const Color(0xFF1A120B);
      canvas.drawCircle(center.translate(-50, 0), 10, paint);
      canvas.drawCircle(center.translate(50, 0), 10, paint);
      
      // Lines
      final linePaint = Paint()..color = AppColors.primary.withOpacity(0.5)..strokeWidth = 2;
      canvas.drawLine(center.translate(-20, -10), center.translate(20, -10), linePaint);
      canvas.drawLine(center.translate(-20, 10), center.translate(20, 10), linePaint);
    }
  }

  void _drawConnect(Canvas canvas, Size size, Offset center, Paint paint) {
    if (isBackground) {
      paint.color = AppColors.primary.withOpacity(0.1);
      canvas.drawCircle(center.translate(-30, 0), 60, paint);
      canvas.drawCircle(center.translate(30, 0), 60, paint);
    } else {
      paint.color = Colors.white;
      // Person 1
      canvas.drawCircle(center.translate(-30, -15), 15, paint);
      canvas.drawArc(Rect.fromCenter(center: center.translate(-30, 20), width: 50, height: 40), math.pi, math.pi, true, paint);
      
      // Person 2
      paint.color = AppColors.primary;
      canvas.drawCircle(center.translate(30, -15), 15, paint);
      canvas.drawArc(Rect.fromCenter(center: center.translate(30, 20), width: 50, height: 40), math.pi, math.pi, true, paint);
    }
  }

  void _drawUniverse(Canvas canvas, Size size, Offset center, Paint paint) {
    if (isBackground) {
      paint.color = AppColors.primary.withOpacity(0.1);
      for(int i=0; i<8; i++) {
        final angle = (i * 45) * math.pi / 180;
        canvas.drawCircle(center.translate(math.cos(angle) * 80, math.sin(angle) * 80), 10, paint);
      }
    } else {
      paint.color = Colors.white;
      final path = Path();
      // Star shape
      for(int i=0; i<5; i++) {
        final angle = (i * 72 - 90) * math.pi / 180;
        final outer = center.translate(math.cos(angle) * 40, math.sin(angle) * 40);
        final innerAngle = (i * 72 + 36 - 90) * math.pi / 180;
        final inner = center.translate(math.cos(innerAngle) * 15, math.sin(innerAngle) * 15);
        if(i == 0) path.moveTo(outer.dx, outer.dy);
        else path.lineTo(outer.dx, outer.dy);
        path.lineTo(inner.dx, inner.dy);
      }
      path.close();
      canvas.drawPath(path, paint);
      
      // Orbital ring
      final ringPaint = Paint()
        ..color = AppColors.primary
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawArc(Rect.fromCenter(center: center, width: 120, height: 40), 0, 2*math.pi, false, ringPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

