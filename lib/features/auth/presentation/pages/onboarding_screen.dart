import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neon_button.dart';
import '../../../home/presentation/providers/branding_provider.dart';
import '../../../../features/home/domain/event_models.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingData> _defaultData = [
    OnboardingData(
      title: 'Welcome to Tech Marathon',
      description: 'The ultimate event for developers and tech enthusiasts.',
      icon: Icons.rocket_launch_rounded,
    ),
    OnboardingData(
      title: 'Learn from Leaders',
      description: 'Gain insights from industry experts and scale your skills.',
      icon: Icons.school_rounded,
    ),
    OnboardingData(
      title: 'Global Community',
      description: 'Connect with a diverse network of developers and founders.',
      icon: Icons.public_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final brandingAsync = ref.watch(brandingProvider);
    final onboardingAsync = ref.watch(onboardingScreensProvider);

    return Scaffold(
      body: onboardingAsync.when(
        data: (screens) => _buildOnboardingContent(screens, brandingAsync.valueOrNull),
        loading: () => _buildOnboardingContent([], null),
        error: (_, __) => _buildOnboardingContent([], null),
      ),
    );
  }

  Widget _buildOnboardingContent(List<OnboardingPageData> screens, BrandingInfo? branding) {
    final List<OnboardingData> pages = screens.isNotEmpty
        ? screens
            .map((p) => OnboardingData(
                  title: p.title,
                  description: p.description,
                  imageUrl: p.imageUrl,
                ))
            .toList()
        : _defaultData;

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemCount: pages.length,
          itemBuilder: (context, index) {
            return OnboardingPage(data: pages[index]);
          },
        ),
        Positioned(
          bottom: 40,
          left: 20,
          right: 20,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.primary : AppColors.textDim,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              NeonButton(
                text: _currentPage == pages.length - 1 ? 'Get Started' : 'Next',
                onPressed: () {
                  if (_currentPage < pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    context.go('/login');
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class OnboardingData {
  final String title;
  final String description;
  final IconData? icon;
  final String? imageUrl;

  OnboardingData({
    required this.title,
    required this.description,
    this.icon,
    this.imageUrl,
  });
}

class OnboardingPage extends StatelessWidget {
  final OnboardingData data;

  const OnboardingPage({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (data.imageUrl != null)
            CachedNetworkImage(
              imageUrl: data.imageUrl!,
              height: 200,
              fit: BoxFit.contain,
              placeholder: (_, __) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
            )
          else
            Icon(
              data.icon ?? Icons.rocket_launch_rounded,
              size: 150,
              color: AppColors.primary,
            ),
          const SizedBox(height: 40),
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
              fontSize: 24,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            data.description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

