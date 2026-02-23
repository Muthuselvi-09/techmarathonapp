import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../../../../features/profile/presentation/providers/profile_provider.dart';
import '../../../../features/home/presentation/providers/branding_provider.dart';
import '../../../../features/home/domain/event_models.dart';

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
    await Future.delayed(const Duration(seconds: 4)); // Slightly longer to appreciate animation
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
    final brandingAsync = ref.watch(brandingProvider);

    return brandingAsync.when(
      data: (branding) => Scaffold(
        body: Container(
          decoration: _buildBackgroundDecoration(branding),
          child: _buildSplashContent(branding),
        ),
      ),
      loading: () => Scaffold(backgroundColor: AppColors.background, body: _buildDefaultSplash()),
      error: (_, __) => Scaffold(backgroundColor: AppColors.background, body: _buildDefaultSplash()),
    );
  }

  BoxDecoration _buildBackgroundDecoration(BrandingInfo branding) {
    if (branding.splashBackgroundType == 'color') {
      return BoxDecoration(
        color: _parseHexColor(branding.splashGradientStart ?? '#121212'),
      );
    } else if (branding.splashBackgroundType == 'image' && branding.splashImageUrl != null) {
      return BoxDecoration(
        image: DecorationImage(
          image: CachedNetworkImageProvider(branding.splashImageUrl!),
          fit: BoxFit.cover,
        ),
      );
    } else {
      // Default to gradient
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _parseHexColor(branding.splashGradientStart ?? '#121212'),
            _parseHexColor(branding.splashGradientEnd ?? '#000000'),
          ],
        ),
      );
    }
  }

  Color _parseHexColor(String hex) {
    try {
      final buffer = StringBuffer();
      if (hex.length == 6 || hex.length == 7) buffer.write('ff');
      buffer.write(hex.replaceFirst('#', ''));
      return Color(int.parse(buffer.toString(), radix: 16));
    } catch (e) {
      return Colors.black;
    }
  }

  Widget _buildSplashContent(BrandingInfo branding) {
    final splashText = branding.splashText ?? 'TECH MARATHON';
    final logoUrl = branding.splashLogoUrl ?? branding.logoUrl;
    final animationType = branding.splashAnimationType;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedAsset(logoUrl, animationType),
          const SizedBox(height: 32),
          Text(
            splashText,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  letterSpacing: 4,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontSize: 28,
                ),
          ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildDefaultSplash() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            width: 200,
            child: Lottie.network(
              'https://assets9.lottiefiles.com/packages/lf20_kyu7xb1v.json',
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
    );
  }

  Widget _buildAnimatedAsset(String? imageUrl, String animationType) {

    Widget child;
    if (imageUrl != null && imageUrl.isNotEmpty) {
      child = Container(
        height: 180,
        width: 180,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(image: NetworkImage(imageUrl), fit: BoxFit.contain),
        ),
      );
    } else {
      child = SizedBox(
        height: 200,
        width: 200,
        child: Lottie.network(
          'https://assets9.lottiefiles.com/packages/lf20_kyu7xb1v.json',
          fit: BoxFit.contain,
        ),
      );
    }

    // Apply Admin-configured animation
    var anim = child.animate();
    switch (animationType) {
      case 'fade':
        return anim.fadeIn(duration: 800.ms);
      case 'slide':
        return anim.slideX(begin: -0.5, end: 0, duration: 800.ms).fadeIn();
      case 'rotate':
        return anim.rotate(begin: 0.5, end: 0, duration: 800.ms).scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1)).fadeIn();
      case 'scale':
      default:
        return anim.scale(duration: 800.ms, curve: Curves.easeOutBack).fadeIn();
    }
  }
}

