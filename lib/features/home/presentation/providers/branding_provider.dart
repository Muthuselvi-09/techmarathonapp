import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../domain/event_models.dart';
import '../../../../features/admin/data/admin_repository.dart';

final brandingProvider = StreamProvider<BrandingInfo>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.watchBranding().handleError((error) {
    debugPrint('⚠️ Branding Stream Error: $error');
    return BrandingInfo(appName: 'Event App');
  });
});

final onboardingScreensProvider = StreamProvider<List<OnboardingPageData>>((ref) {
  final repo = ref.watch(adminRepositoryProvider);
  return repo.watchOnboardingScreens().handleError((error) {
    debugPrint('⚠️ Onboarding Stream Error: $error');
    return <OnboardingPageData>[];
  });
});
