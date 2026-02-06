import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/data/auth_repository.dart';
import '../../features/events/presentation/pages/all_events_screen.dart';
import '../../features/home/domain/event_models.dart';

// Import pages

// Import pages
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/login_screen.dart';
import '../../features/auth/presentation/pages/signup_screen.dart';
import '../../features/auth/presentation/pages/onboarding_screen.dart';
import '../../features/auth/presentation/pages/admin_login_screen.dart';
import '../../features/auth/presentation/pages/admin_signup_screen.dart';
import '../../features/auth/presentation/pages/admin_forgot_password_screen.dart';
import '../widgets/main_scaffold.dart';
import '../../features/events/presentation/pages/event_login_screen.dart';
import '../../features/events/presentation/pages/event_overview_screen.dart';
import '../../features/events/presentation/pages/participants_screen.dart';
import '../../features/events/presentation/pages/payment_screen.dart';
// import '../../features/events/presentation/pages/event_chat_screen.dart';
import '../../features/events/presentation/pages/chat_screen.dart' as realtime_chat;
import '../../features/events/presentation/pages/event_profile_screen.dart';
import '../../features/events/presentation/pages/speakers_screen.dart';
import '../../features/events/presentation/pages/member_profile_screen.dart';
import '../../features/notifications/presentation/pages/notifications_screen.dart';
import '../../features/settings/presentation/pages/settings_screen.dart';

import '../../features/profile/presentation/pages/profile_screen.dart';
import '../../features/profile/presentation/pages/profile_completion_screen.dart';
import '../../features/profile/presentation/pages/my_schedule_screen.dart';
import '../../features/profile/presentation/pages/qr_pass_screen.dart';
import '../../features/profile/presentation/pages/past_events_screen.dart';
import '../../features/profile/presentation/pages/my_events_screen.dart';
import '../../features/profile/presentation/pages/my_courses_screen.dart';
import '../../features/profile/presentation/pages/certificates_screen.dart';
import '../../features/profile/presentation/pages/profile_settings_screen.dart';
import '../../features/profile/presentation/pages/my_offers_screen.dart';
import '../../features/profile/presentation/pages/saved_sponsors_screen.dart';
import '../../features/admin/presentation/pages/admin_dashboard_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: AuthRefreshListenable(ref),
    redirect: (context, state) {
      final user = ref.read(authStateProvider).valueOrNull;
      final isAuthRoute = state.matchedLocation == '/login' || 
                          state.matchedLocation == '/signup' ||
                          state.matchedLocation == '/onboarding' ||
                          state.matchedLocation == '/';
      final isAdminLoginRoute = state.matchedLocation == '/admin-login';

      // If not logged in and trying to access protected route -> login
      if (user == null) {
        return (isAuthRoute || isAdminLoginRoute) ? null : '/login';
      }

      // If logged in and on auth pages (except splash) -> home
      if (isAuthRoute && state.matchedLocation != '/') {
        return '/home';
      }

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
        path: '/admin-login',
        builder: (context, state) => const AdminLoginScreen(),
      ),
      GoRoute(
        path: '/admin-signup',
        builder: (context, state) => const AdminSignUpScreen(),
      ),
      GoRoute(
        path: '/admin-forgot-password',
        builder: (context, state) => const AdminForgotPasswordScreen(),
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
      GoRoute(
        path: '/admin',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/my-schedule',
        builder: (context, state) => const MyScheduleScreen(),
      ),
      GoRoute(
        path: '/qr-pass',
        builder: (context, state) => const QrPassScreen(),
      ),
      GoRoute(
        path: '/past-events',
        builder: (context, state) => const PastEventsScreen(),
      ),
      GoRoute(
        path: '/my-events',
        builder: (context, state) => const MyEventsScreen(),
      ),
      GoRoute(
        path: '/my-courses',
        builder: (context, state) => const MyCoursesScreen(),
      ),
      GoRoute(
        path: '/certificates',
        builder: (context, state) => const CertificatesScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) {
          final event = state.extra as CodingEvent;
          return PaymentScreen(event: event);
        },
      ),
      GoRoute(
        path: '/profile-settings',
        builder: (context, state) => const ProfileSettingsScreen(),
      ),
      GoRoute(
        path: '/my-offers',
        builder: (context, state) => const MyOffersScreen(),
      ),
      GoRoute(
        path: '/saved-sponsors',
        builder: (context, state) => const SavedSponsorsScreen(),
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
