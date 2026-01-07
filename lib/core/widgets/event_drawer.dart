import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../theme/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import 'event_widgets.dart';
import '../../features/chat/presentation/pages/admin_chat_page.dart';

class EventDrawer extends ConsumerWidget {
  const EventDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Drawer(
      backgroundColor: Colors.transparent, // Transparent to show gradient
      child: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.backgroundGradient,
        ),
        child: Column(
          children: [
            DrawerHeader(
              padding: EdgeInsets.zero,
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.transparent)), // Clean header integration
                color: Colors.transparent, // Let gradient show through
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                decoration: BoxDecoration(
                  border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
                ),
                child: const Center(
                  child: BrandHeader(),
                ),
              ),
            ),
            _buildNavItem(context, Icons.home_outlined, 'Home', '/home', useGo: true),
            _buildNavItem(context, Icons.event_available_outlined, 'Events', '/events'), 
            _buildNavItem(context, Icons.campaign_outlined, 'Speakers', '/speakers'),
            _buildNavItem(context, Icons.person_outline_rounded, 'Profile', '/profile'),
            _buildNavItem(context, Icons.notifications_none_rounded, 'Notifications', '/notifications'),
            ListTile(
              leading: const Icon(Icons.support_agent_rounded, color: AppColors.codingRimPrimary),
              title: const Text(
                'System Support',
                style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
              ),
              onTap: () {
                context.pop();
                final user = ref.read(authStateProvider).valueOrNull;
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => AdminChatPage(userId: user?.uid ?? 'anonymous_admin'),
                  ),
                );
              },
            ),
            _buildNavItem(context, Icons.settings_outlined, 'Settings', '/settings'),
            const Spacer(),
            Container(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: Colors.white.withOpacity(0.05))),
              ),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(
                  'Logout',
                  style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  context.pop();
                  ref.read(authControllerProvider.notifier).logout();
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String title, String route, {bool useGo = false}) {
    return ListTile(
      leading: Icon(icon, color: AppColors.codingRimPrimary), // Gold Icon
      title: Text(
        title,
        style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      ),
      onTap: () {
        context.pop(); // Close drawer
        if (useGo) {
          context.go(route);
        } else {
          context.push(route);
        }
      },
    );
  }
}
