import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/common_widgets.dart';
import '../providers/profile_provider.dart';
import 'package:go_router/go_router.dart';
import '../../../admin/data/admin_repository.dart';
import '../../../home/domain/event_models.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
// Removed unused imports

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider).user;
    
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('PROFILE'), 
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            context.pop();
          },
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
            onPressed: () => context.push('/profile-edit'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            CircleAvatar(
              radius: 60,
              backgroundColor: AppColors.surface,
              backgroundImage: user?.profileImage != null && user!.profileImage!.isNotEmpty
                  ? NetworkImage(user.profileImage!)
                  : null,
              child: (user?.profileImage == null || user!.profileImage!.isEmpty)
                  ? const Icon(Icons.person_rounded, size: 60, color: AppColors.primary)
                  : null,
            ),
            const SizedBox(height: 24),
            Text(
              user?.name ?? 'Guest User',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              user?.email ?? '',
              style: const TextStyle(color: AppColors.textDim),
            ),
            const SizedBox(height: 40),
            StreamBuilder<List<ProfileItem>>(
              stream: ref.watch(adminRepositoryProvider).watchProfileItems(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ));
                }
                
                final items = snapshot.data!.where((i) => i.isEnabled).toList();
                
                if (items.isEmpty) {
                   return const Center(child: Text('No options available', style: TextStyle(color: Colors.white38)));
                }

                return Column(
                  children: items.map((item) => _buildProfileTile(
                    IconData(item.iconCodePoint, fontFamily: 'MaterialIcons'),
                    item.title,
                    onTap: () {
                      if (item.route == 'settings_action' || item.route == '/profile-settings') {
                        context.push('/profile-settings');
                      } else if (item.route.startsWith('/')) {
                        context.push(item.route);
                      } else if (item.route == 'events') {
                        context.push('/my-events');
                      } else if (item.route == '/my-offers') {
                        context.push('/my-offers');
                      } else if (item.route == '/saved-sponsors') {
                        context.push('/saved-sponsors');
                      }
                    },
                  )).toList(),
                );
              },
            ),
            const SizedBox(height: 40),
            TextButton(
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
              },
              child: const Text('Logout', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileTile(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: onTap,
        child: GlassCard(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textDim),
            ],
          ),
        ),
      ),
    );
  }
}
