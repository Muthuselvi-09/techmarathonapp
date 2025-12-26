import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/events/presentation/pages/all_events_screen.dart';
import '../../features/events/domain/event_models.dart';

// Import pages

// Import pages
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/auth/presentation/pages/onboarding_screen.dart';
import '../widgets/main_scaffold.dart';
import '../../features/events/presentation/pages/event_login_screen.dart';
import '../../features/events/presentation/pages/event_overview_screen.dart';
import '../../features/events/presentation/pages/participants_screen.dart';
import '../../features/events/presentation/pages/event_chat_screen.dart';
import '../../features/events/presentation/pages/chat_screen.dart' as realtime_chat;
import '../../features/events/presentation/pages/event_profile_screen.dart';
import '../../features/events/presentation/pages/speakers_screen.dart';
import '../../features/events/presentation/pages/member_profile_screen.dart';
import '../../features/notifications/presentation/pages/notifications_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';

import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/profile/presentation/pages/profile_completion_screen.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isProfileComplete = ref.watch(profileProvider.select((s) => s.isComplete));

  return GoRouter(
    initialLocation: '/',
    refreshListenable: AuthRefreshListenable(ref),
    redirect: (context, state) {
      final user = authState.valueOrNull;
      final isAuthRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/signup' ||
                          state.matchedLocation == '/onboarding' ||
                          state.matchedLocation == '/';
      
      // If not logged in and trying to access protected route -> login
      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      // If logged in and on auth pages -> home
      if (isAuthRoute) {
        return '/home';
      }
      
      // Profile completion check removed to allow Home access
      // if (isProtectedCore && !isProfileComplete) {
      //   return '/profile-completion';
      // }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile-completion',
        builder: (context, state) => const ProfileCompletionScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainScaffold(),
      ),
      GoRoute(
        path: '/participants',
        builder: (context, state) => const ParticipantsScreen(),
      ),
      GoRoute(
        path: '/speakers',
        builder: (context, state) => const SpeakersScreen(),
      ),
      GoRoute(
        path: '/profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/profile-edit',
        builder: (context, state) => const ProfileCompletionScreen(),
      ),
      GoRoute(
        path: '/events',
        builder: (context, state) => const AllEventsScreen(),
      ),
      GoRoute(
        path: '/chat',
        builder: (context, state) {
           final otherUser = state.extra as Participant;
           return realtime_chat.ChatScreen(otherUser: otherUser);
        },
      ),
      GoRoute(
        path: '/member-profile',
        builder: (context, state) {
           final member = state.extra as Participant;
           return MemberProfileScreen(member: member);
        },
      ),
      GoRoute(
        path: '/event-login',
        builder: (context, state) => const EventLoginScreen(),
      ),
      GoRoute(
        path: '/event-home',
        builder: (context, state) => const EventOverviewScreen(),
      ),
      GoRoute(
        path: '/event-profile',
        builder: (context, state) => const EventProfileScreen(),
      ),
    ],
  );
});

class AuthRefreshListenable extends ChangeNotifier {
  AuthRefreshListenable(Ref ref) {
    ref.listen(authStateProvider, (previous, next) {
      if (previous?.value?.uid != next.value?.uid) {
        notifyListeners();
      }
    });
  }
}
