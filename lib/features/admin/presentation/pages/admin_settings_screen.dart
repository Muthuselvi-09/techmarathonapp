import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/auth/data/user_repository.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Color _gold = const Color(0xFFFFD700);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.saasMainBg,
      body: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: StreamBuilder<DocumentSnapshot>(
                  stream: _firestore.collection('app_settings').doc('general').snapshots(),
                  builder: (context, snapshot) {
                    final settings = snapshot.data?.data() as Map<String, dynamic>? ?? {};
                    return ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      children: [
                        _buildSectionHeader('GENERAL SETTINGS', Icons.settings_applications_rounded),
                        _buildGeneralSettings(settings),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('USER & ROLE MANAGEMENT', Icons.manage_accounts_rounded),
                        _buildUserManagement(),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('PERMISSIONS CONTROL', Icons.admin_panel_settings_rounded),
                        _buildPermissionsControl(),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('NOTIFICATION SETTINGS', Icons.notifications_active_rounded),
                        _buildNotificationSettings(),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('CHAT SETTINGS', Icons.chat_rounded),
                        _buildChatSettings(),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('BRANDING CONTROLS', Icons.palette_rounded),
                        _buildBrandingSettings(),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('SECURITY SETTINGS', Icons.security_rounded),
                        _buildSecuritySettings(),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('DATA MANAGEMENT', Icons.data_usage_rounded),
                        _buildDataManagement(),
                        const SizedBox(height: 32),
                        
                        _buildSectionHeader('ANALYTICS OVERVIEW', Icons.analytics_rounded),
                        _buildAnalyticsOverview(),
                        const SizedBox(height: 40),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Settings',
                style: GoogleFonts.outfit(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.saasTextPrimary,
                ),
              ),
              Text(
                'Configure your platform preferences',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: AppColors.saasTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.saasPrimary, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColors.saasPrimary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard({required List<Widget> children, bool hasPadding = true}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.saasCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.saasBorder),
        boxShadow: AppColors.saasShadow,
      ),
      padding: hasPadding ? const EdgeInsets.all(8) : EdgeInsets.zero,
      child: Column(children: children),
    );
  }

  // --- 1. GENERAL SETTINGS ---
  Widget _buildGeneralSettings(Map<String, dynamic> settings) {
    return _buildCard(
      children: [
        _buildSettingTile(
          title: 'App Name',
          subtitle: settings['appName'] ?? 'Tech Marathon',
          icon: Icons.edit_rounded,
          onTap: () => _showEditDialog('appName', 'Edit App Name', settings['appName'] ?? ''),
        ),
        _buildSettingTile(
          title: 'Event Status',
          subtitle: (settings['status'] ?? 'Upcoming').toUpperCase(),
          icon: Icons.event_available_rounded,
          onTap: () => _showPickerAction('status', 'Select Status', ['Upcoming', 'Live', 'Completed']),
        ),
        _buildSwitchTile(
          title: 'Maintenance Mode',
          value: settings['maintenanceMode'] ?? false,
          onChanged: (val) => _updateSetting('maintenanceMode', val),
        ),
        _buildSettingTile(
          title: 'Timezone',
          subtitle: settings['timezone'] ?? 'Asia/Kolkata',
          icon: Icons.access_time_rounded,
          onTap: () {},
        ),
        _buildSettingTile(
          title: 'Visibility',
          subtitle: settings['visibility'] ?? 'Public',
          icon: Icons.public_rounded,
          onTap: () => _showPickerAction('visibility', 'Set Visibility', ['Public', 'Private']),
        ),
      ],
    );
  }

  // --- 2. USER MANAGEMENT ---
  Widget _buildUserManagement() {
    return _buildCard(
      children: [
        _buildActionTile(
          title: 'View All Users',
          subtitle: 'Manage roles and permissions',
          icon: Icons.people_alt_rounded,
          onTap: () => _showUsersListDialog(),
        ),
        _buildActionTile(
          title: 'Add New Staff',
          subtitle: 'Invite admins or managers',
          icon: Icons.person_add_rounded,
          onTap: () {},
        ),
      ],
    );
  }

  // --- 3. PERMISSIONS CONTROL ---
  Widget _buildPermissionsControl() {
    return _buildCard(
      children: [
        _buildPermissionExpansion(
          'Manager Permissions',
          ['Can edit event', 'Can delete participants', 'Can view revenue'],
        ),
        _buildPermissionExpansion(
          'Member Permissions',
          ['Can send messages', 'Can view sponsors', 'Can rate speakers'],
        ),
      ],
    );
  }

  // --- 4. NOTIFICATION SETTINGS ---
  Widget _buildNotificationSettings() {
    return _buildCard(
      children: [
        _buildActionTile(
          title: 'Send Announcement',
          subtitle: 'Broadcast to all users',
          icon: Icons.campaign_rounded,
          onTap: () {},
        ),
        _buildSwitchTile(title: 'Push Notifications', value: true, onChanged: (v) {}),
        _buildSwitchTile(title: 'Email Notifications', value: false, onChanged: (v) {}),
      ],
    );
  }

  // --- 5. CHAT SETTINGS ---
  Widget _buildChatSettings() {
    return _buildCard(
      children: [
        _buildSwitchTile(title: 'Enable Chat', value: true, onChanged: (v) {}),
        _buildSwitchTile(title: 'Media Sharing', value: true, onChanged: (v) {}),
        _buildSwitchTile(title: 'Profanity Filter', value: true, onChanged: (v) {}),
        _buildActionTile(title: 'Clear Chat History', subtitle: 'Permanent action', icon: Icons.delete_sweep_rounded, onTap: () {}),
      ],
    );
  }

  // --- 6. BRANDING CONTROLS ---
  Widget _buildBrandingSettings() {
    return _buildCard(
      children: [
        _buildBrandingTile('Primary Color', AppColors.codingRimPrimary),
        _buildBrandingTile('Accent Color', _gold),
        _buildActionTile(title: 'Upload Logo', subtitle: 'Transparent PNG recommended', icon: Icons.upload_file_rounded, onTap: () {}),
        _buildSwitchTile(title: 'Force Dark Mode', value: true, onChanged: (v) {}),
      ],
    );
  }

  // --- 7. SECURITY SETTINGS ---
  Widget _buildSecuritySettings() {
    return _buildCard(
      children: [
        _buildActionTile(title: 'Force Logout All', subtitle: 'Emergency action', icon: Icons.logout_rounded, isSensitive: true, onTap: () {}),
        _buildSettingTile(title: 'Session Timeout', subtitle: '4 Hours', icon: Icons.timer_rounded, onTap: () {}),
        _buildSwitchTile(title: 'Two-Factor Auth', value: false, onChanged: (v) {}),
      ],
    );
  }

  // --- 8. DATA MANAGEMENT ---
  Widget _buildDataManagement() {
    return _buildCard(
      children: [
        _buildActionTile(title: 'Backup Database', subtitle: 'Last backup: 2h ago', icon: Icons.cloud_upload_rounded, onTap: () {}),
        _buildActionTile(title: 'Export Participants', subtitle: 'Download CSV file', icon: Icons.download_rounded, onTap: () {}),
        _buildActionTile(title: 'Reset Event Data', subtitle: 'Wipe all records', icon: Icons.refresh_rounded, isSensitive: true, onTap: () {}),
      ],
    );
  }

  // --- 9. ANALYTICS OVERVIEW ---
  Widget _buildAnalyticsOverview() {
    return _buildCard(
      children: [
        _buildStatTile('Total Users', '1,240', Icons.people_rounded),
        _buildStatTile('Active Now', '42', Icons.online_prediction_rounded),
        _buildStatTile('Tickets Sold', '856', Icons.confirmation_number_rounded),
      ],
    );
  }

  // --- HELPER WIDGETS ---

  Widget _buildSettingTile({required String title, required String subtitle, required IconData icon, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.saasTextSecondary, size: 20),
      title: Text(title, style: GoogleFonts.inter(color: AppColors.saasTextPrimary, fontSize: 14)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(subtitle, style: GoogleFonts.inter(color: AppColors.saasPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(width: 8),
          const Icon(Icons.chevron_right_rounded, color: AppColors.saasBorder),
        ],
      ),
    );
  }

  Widget _buildActionTile({required String title, required String subtitle, required IconData icon, bool isSensitive = false, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: isSensitive ? AppColors.saasDanger : AppColors.saasPrimary, size: 22),
      title: Text(title, style: GoogleFonts.inter(color: isSensitive ? AppColors.saasDanger : AppColors.saasTextPrimary, fontWeight: FontWeight.bold)),
      subtitle: Text(subtitle, style: GoogleFonts.inter(color: AppColors.saasTextSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.saasBorder),
    );
  }

  Widget _buildSwitchTile({required String title, required bool value, required ValueChanged<bool> onChanged}) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeColor: AppColors.saasPrimary,
      title: Text(title, style: GoogleFonts.inter(color: AppColors.saasTextPrimary, fontSize: 14)),
    );
  }

  Widget _buildPermissionExpansion(String title, List<String> permissions) {
    return ExpansionTile(
      leading: const Icon(Icons.shield_rounded, color: AppColors.saasPrimary),
      title: Text(title, style: GoogleFonts.inter(color: AppColors.saasTextPrimary, fontWeight: FontWeight.bold)),
      children: permissions.map((p) => CheckboxListTile(
        value: true,
        onChanged: (v) {},
        activeColor: AppColors.saasPrimary,
        title: Text(p, style: GoogleFonts.inter(color: AppColors.saasTextSecondary, fontSize: 13)),
      )).toList(),
    );
  }

  Widget _buildBrandingTile(String title, Color color) {
    return ListTile(
      title: Text(title, style: GoogleFonts.inter(color: Colors.white70, fontSize: 14)),
      trailing: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white24),
        ),
      ),
    );
  }

  Widget _buildStatTile(String title, String value, IconData icon) {
    return ListTile(
      leading: Icon(icon, color: AppColors.saasPrimary),
      title: Text(title, style: GoogleFonts.inter(color: AppColors.saasTextSecondary, fontSize: 13)),
      trailing: Text(value, style: GoogleFonts.outfit(color: AppColors.saasTextPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
    );
  }

  // --- ACTIONS ---

  Future<void> _updateSetting(String key, dynamic value) async {
    await _firestore.collection('app_settings').doc('general').set({key: value}, SetOptions(merge: true));
  }

  void _showEditDialog(String key, String title, String current) {
    final controller = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              _updateSetting(key, controller.text.trim());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showPickerAction(String key, String title, List<String> options) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: options.map((o) => ListTile(
          title: Text(o, style: const TextStyle(color: Colors.white)),
          onTap: () {
            _updateSetting(key, o);
            Navigator.pop(context);
          },
        )).toList(),
      ),
    );
  }

  void _showUsersListDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (_, sc) => Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(2))),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Text('Platform Users', style: GoogleFonts.outfit(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
              Expanded(
                child: StreamBuilder<List<Participant>>(
                  stream: ref.watch(userRepositoryProvider).getRealTimeMembers(),
                  builder: (context, snapshot) {
                    final users = snapshot.data ?? [];
                    return ListView.builder(
                      controller: sc,
                      itemCount: users.length,
                      itemBuilder: (context, i) {
                        final u = users[i];
                        return ListTile(
                          leading: CircleAvatar(child: Text(u.name[0])),
                          title: Text(u.name, style: const TextStyle(color: Colors.white)),
                          subtitle: Text(u.role ?? 'member', style: TextStyle(color: _gold.withValues(alpha: 0.5))),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert, color: Colors.white38),
                            onSelected: (role) => _updateUserRole(u.id, role),
                            itemBuilder: (context) => [
                              const PopupMenuItem(value: 'admin', child: Text('Make Admin')),
                              const PopupMenuItem(value: 'organizer', child: Text('Make Manager')),
                              const PopupMenuItem(value: 'user', child: Text('Make Member')),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateUserRole(String uid, String role) async {
    await _firestore.collection('users').doc(uid).update({'role': role});
  }
}
