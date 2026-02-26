import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/auth/data/user_repository.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';

// ─── Analytics live stats provider ──────────────────────────────────────────
final _analyticsProvider = StreamProvider<Map<String, int>>((ref) {
  final fs = FirebaseFirestore.instance;
  return fs.collection('users').snapshots().asyncMap((userSnap) async {
    final totalUsers = userSnap.docs.length;
    final activeNow =
        userSnap.docs.where((d) => d.data()['isOnline'] == true).length;

    final ticketSnap = await fs
        .collectionGroup('tickets')
        .count()
        .get();
    final ticketsSold = ticketSnap.count ?? 0;

    return {
      'totalUsers': totalUsers,
      'activeNow': activeNow,
      'ticketsSold': ticketsSold,
    };
  });
});

// ─── Permission roles provider ────────────────────────────────────────────────
final _permissionsProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection('app_settings')
      .doc('permissions')
      .snapshots()
      .map((snap) => snap.data() ?? {});
});

// ─── Chat settings provider ───────────────────────────────────────────────────
final _chatSettingsProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection('app_settings')
      .doc('chat')
      .snapshots()
      .map((snap) => snap.data() ?? {
            'enableChat': true,
            'mediaSharing': true,
            'profanityFilter': true,
          });
});

// ─── Notification settings provider ──────────────────────────────────────────
final _notifSettingsProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection('app_settings')
      .doc('notifications')
      .snapshots()
      .map((snap) => snap.data() ?? {
            'pushEnabled': true,
            'emailEnabled': false,
          });
});

// ─── Security settings provider ───────────────────────────────────────────────
final _securitySettingsProvider =
    StreamProvider<Map<String, dynamic>>((ref) {
  return FirebaseFirestore.instance
      .collection('app_settings')
      .doc('security')
      .snapshots()
      .map((snap) => snap.data() ?? {
            'twoFactorEnabled': false,
            'sessionTimeout': '4',
          });
});

class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isSavingAnnouncement = false;

  // ─── Firestore helpers ────────────────────────────────────────────────────

  Future<void> _updateSetting(String doc, String key, dynamic value) async {
    await _firestore
        .collection('app_settings')
        .doc(doc)
        .set({key: value}, SetOptions(merge: true));
  }

  // ─── Build ────────────────────────────────────────────────────────────────

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
                stream: _firestore
                    .collection('app_settings')
                    .doc('general')
                    .snapshots(),
                builder: (context, snap) {
                  final settings =
                      snap.data?.data() as Map<String, dynamic>? ?? {};
                  return ListView(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    children: [
                      _sectionHeader(
                          'GENERAL SETTINGS', Icons.settings_applications_rounded),
                      _buildGeneralSettings(settings),
                      const SizedBox(height: 32),

                      _sectionHeader(
                          'USER & ROLE MANAGEMENT', Icons.manage_accounts_rounded),
                      _buildUserManagement(),
                      const SizedBox(height: 32),

                      _sectionHeader(
                          'PERMISSIONS CONTROL', Icons.admin_panel_settings_rounded),
                      _buildPermissionsControl(),
                      const SizedBox(height: 32),

                      _sectionHeader(
                          'NOTIFICATION SETTINGS', Icons.notifications_active_rounded),
                      _buildNotificationSettings(),
                      const SizedBox(height: 32),

                      _sectionHeader('CHAT SETTINGS', Icons.chat_rounded),
                      _buildChatSettings(),
                      const SizedBox(height: 32),

                      _sectionHeader('BRANDING CONTROLS', Icons.palette_rounded),
                      _buildBrandingSettings(settings),
                      const SizedBox(height: 32),

                      _sectionHeader('SECURITY SETTINGS', Icons.security_rounded),
                      _buildSecuritySettings(),
                      const SizedBox(height: 32),

                      _sectionHeader('DATA MANAGEMENT', Icons.data_usage_rounded),
                      _buildDataManagement(),
                      const SizedBox(height: 32),

                      _sectionHeader(
                          'ANALYTICS OVERVIEW', Icons.analytics_rounded),
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

  // ─── Header ───────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(
                color: AppColors.saasBorder.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Admin Settings',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.saasTextPrimary,
                ),
              ),
              Text(
                'Control every aspect of the platform',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.saasTextSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Section header ───────────────────────────────────────────────────────

  Widget _sectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.saasPrimary, size: 20),
          const SizedBox(width: 10),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: AppColors.saasPrimary,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Card wrapper ─────────────────────────────────────────────────────────

  Widget _card({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.saasCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.saasBorder),
        boxShadow: AppColors.saasShadow,
      ),
      padding: const EdgeInsets.all(8),
      child: Column(children: children),
    );
  }

  // ─── 1. GENERAL SETTINGS ─────────────────────────────────────────────────

  Widget _buildGeneralSettings(Map<String, dynamic> settings) {
    return _card(children: [
      _tile(
        title: 'App Name',
        trailing: Text(settings['appName'] ?? 'Tech Marathon',
            style: _trailingStyle),
        icon: Icons.edit_rounded,
        onTap: () =>
            _editDialog('appName', 'Edit App Name', settings['appName'] ?? ''),
      ),
      _divider(),
      _tile(
        title: 'Event Status',
        trailing: _statusBadge(settings['status'] ?? 'Upcoming'),
        icon: Icons.event_available_rounded,
        onTap: () => _picker('status', 'Select Event Status',
            ['Upcoming', 'Live', 'Completed', 'Cancelled']),
      ),
      _divider(),
      _tile(
        title: 'Visibility',
        trailing: Text(settings['visibility'] ?? 'Public',
            style: _trailingStyle),
        icon: Icons.public_rounded,
        onTap: () => _picker('visibility', 'Set Visibility', ['Public', 'Private']),
      ),
      _divider(),
      _tile(
        title: 'Timezone',
        trailing: Text(settings['timezone'] ?? 'Asia/Kolkata',
            style: _trailingStyle),
        icon: Icons.access_time_rounded,
        onTap: () => _picker('timezone', 'Select Timezone', [
          'Asia/Kolkata',
          'UTC',
          'America/New_York',
          'Europe/London',
          'Asia/Singapore',
        ]),
      ),
      _divider(),
      _switchRow(
        title: 'Maintenance Mode',
        subtitle: 'Disables user access to the app',
        value: settings['maintenanceMode'] ?? false,
        onChanged: (v) async {
          await _firestore
              .collection('app_settings')
              .doc('general')
              .set({'maintenanceMode': v}, SetOptions(merge: true));
        },
        isDestructive: true,
      ),
    ]);
  }

  // ─── 2. USER & ROLE MANAGEMENT ────────────────────────────────────────────

  Widget _buildUserManagement() {
    return StreamBuilder<List<Participant>>(
      stream: ref.watch(userRepositoryProvider).getRealTimeMembers(),
      builder: (ctx, snap) {
        final users = snap.data ?? [];
        final adminCount = users.where((u) => u.role == 'admin').length;
        final memberCount = users.where((u) => u.role == 'user').length;
        final managerCount =
            users.where((u) => u.role == 'organizer').length;
        return _card(children: [
          _statRow(
              'Total Users', '${users.length}', Icons.people_alt_rounded,
              color: AppColors.saasInfo),
          _divider(),
          _statRow('Admins', '$adminCount', Icons.shield_rounded,
              color: AppColors.saasPrimary),
          _divider(),
          _statRow('Managers', '$managerCount', Icons.supervised_user_circle_rounded,
              color: AppColors.saasSuccess),
          _divider(),
          _statRow('Members', '$memberCount', Icons.person_rounded,
              color: AppColors.saasTextSecondary),
          _divider(),
          _actionTile(
            title: 'Manage All Users',
            subtitle: 'View, search & update roles',
            icon: Icons.manage_accounts_rounded,
            onTap: () => _showUsersSheet(users),
          ),
          _divider(),
          _actionTile(
            title: 'Export Users List',
            subtitle: 'Share user data as CSV',
            icon: Icons.upload_file_rounded,
            onTap: () => _exportUsersCSV(users),
          ),
        ]);
      },
    );
  }

  // ─── 3. PERMISSIONS CONTROL ───────────────────────────────────────────────

  Widget _buildPermissionsControl() {
    final permAsync = ref.watch(_permissionsProvider);
    return permAsync.when(
      loading: () => _loadingCard(),
      error: (e, _) => _errorCard(e.toString()),
      data: (perms) => _card(children: [
        _permissionExpansion(
          role: 'manager',
          title: 'Manager Permissions',
          icon: Icons.supervised_user_circle_rounded,
          permissions: {
            'canEditEvent': 'Can Edit Events',
            'canDeleteParticipants': 'Can Delete Participants',
            'canViewRevenue': 'Can View Revenue',
            'canSendAnnouncements': 'Can Send Announcements',
            'canScanEntry': 'Can Scan Entry QR',
          },
          current: Map<String, bool>.from(perms['manager'] ?? {}),
        ),
        _divider(),
        _permissionExpansion(
          role: 'member',
          title: 'Member Permissions',
          icon: Icons.person_rounded,
          permissions: {
            'canSendMessages': 'Can Send Messages',
            'canViewSponsors': 'Can View Sponsors',
            'canRateSpeakers': 'Can Rate Speakers',
            'canDownloadTickets': 'Can Download Tickets',
            'canViewLiveFeed': 'Can View Live Feed',
          },
          current: Map<String, bool>.from(perms['member'] ?? {}),
        ),
      ]),
    );
  }

  Widget _permissionExpansion({
    required String role,
    required String title,
    required IconData icon,
    required Map<String, String> permissions,
    required Map<String, bool> current,
  }) {
    return ExpansionTile(
      leading: Icon(icon, color: AppColors.saasPrimary),
      title: Text(title,
          style: GoogleFonts.inter(
              color: AppColors.saasTextPrimary, fontWeight: FontWeight.bold)),
      children: permissions.entries
          .map(
            (e) => SwitchListTile(
              title: Text(e.value,
                  style: GoogleFonts.inter(
                      color: AppColors.saasTextSecondary, fontSize: 13)),
              value: current[e.key] ?? true,
              activeThumbColor: AppColors.saasPrimary,
              onChanged: (val) async {
                await _firestore
                    .collection('app_settings')
                    .doc('permissions')
                    .set({role: {e.key: val}}, SetOptions(merge: true));
              },
            ),
          )
          .toList(),
    );
  }

  // ─── 4. NOTIFICATION SETTINGS ─────────────────────────────────────────────

  Widget _buildNotificationSettings() {
    final nAsync = ref.watch(_notifSettingsProvider);
    return nAsync.when(
      loading: () => _loadingCard(),
      error: (e, _) => _errorCard(e.toString()),
      data: (n) => _card(children: [
        _switchRow(
          title: 'Push Notifications',
          subtitle: 'Firebase Cloud Messaging',
          value: n['pushEnabled'] ?? true,
          onChanged: (v) => _updateSetting('notifications', 'pushEnabled', v),
        ),
        _divider(),
        _switchRow(
          title: 'Email Notifications',
          subtitle: 'Send event alerts via email',
          value: n['emailEnabled'] ?? false,
          onChanged: (v) =>
              _updateSetting('notifications', 'emailEnabled', v),
        ),
        _divider(),
        _actionTile(
          title: 'Send Announcement',
          subtitle: 'Broadcast a message to ALL users',
          icon: Icons.campaign_rounded,
          onTap: () => _showAnnouncementDialog(),
        ),
      ]),
    );
  }

  // ─── 5. CHAT SETTINGS ─────────────────────────────────────────────────────

  Widget _buildChatSettings() {
    final cAsync = ref.watch(_chatSettingsProvider);
    return cAsync.when(
      loading: () => _loadingCard(),
      error: (e, _) => _errorCard(e.toString()),
      data: (c) => _card(children: [
        _switchRow(
          title: 'Enable Chat',
          subtitle: 'Allow users to contact support',
          value: c['enableChat'] ?? true,
          onChanged: (v) => _updateSetting('chat', 'enableChat', v),
        ),
        _divider(),
        _switchRow(
          title: 'Media Sharing',
          subtitle: 'Allow image/file attachments',
          value: c['mediaSharing'] ?? true,
          onChanged: (v) => _updateSetting('chat', 'mediaSharing', v),
        ),
        _divider(),
        _switchRow(
          title: 'Profanity Filter',
          subtitle: 'Auto-moderate offensive content',
          value: c['profanityFilter'] ?? true,
          onChanged: (v) => _updateSetting('chat', 'profanityFilter', v),
        ),
        _divider(),
        _actionTile(
          title: 'Clear All Chat History',
          subtitle: 'Permanently delete all messages',
          icon: Icons.delete_sweep_rounded,
          isDestructive: true,
          onTap: () => _confirmAction(
            'Clear Chat History',
            'This will permanently delete ALL chat messages. This cannot be undone.',
            () => _clearAllChats(),
          ),
        ),
      ]),
    );
  }

  // ─── 6. BRANDING CONTROLS ─────────────────────────────────────────────────

  Widget _buildBrandingSettings(Map<String, dynamic> settings) {
    return _card(children: [
      _tile(
        title: 'Platform Name',
        trailing: Text(settings['platformName'] ?? 'Tech Marathon',
            style: _trailingStyle),
        icon: Icons.badge_rounded,
        onTap: () => _editDialog(
            'platformName', 'Platform Display Name',
            settings['platformName'] ?? 'Tech Marathon'),
      ),
      _divider(),
      _tile(
        title: 'Tagline',
        trailing: Flexible(
          child: Text(
            settings['tagline'] ?? 'Celebrate. Connect. Create.',
            style: _trailingStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        icon: Icons.text_fields_rounded,
        onTap: () => _editDialog('tagline', 'Platform Tagline',
            settings['tagline'] ?? ''),
      ),
      _divider(),
      _tile(
        title: 'Contact Email',
        trailing: Text(settings['contactEmail'] ?? 'admin@techmarathon.in',
            style: _trailingStyle),
        icon: Icons.email_rounded,
        onTap: () => _editDialog('contactEmail', 'Support Contact Email',
            settings['contactEmail'] ?? ''),
      ),
      _divider(),
      _tile(
        title: 'Support Phone',
        trailing: Text(settings['supportPhone'] ?? '+91 00000 00000',
            style: _trailingStyle),
        icon: Icons.phone_rounded,
        onTap: () => _editDialog('supportPhone', 'Support Phone Number',
            settings['supportPhone'] ?? ''),
      ),
      _divider(),
      _tile(
        title: 'App Version',
        trailing: Text(settings['version'] ?? '1.0.0', style: _trailingStyle),
        icon: Icons.system_update_rounded,
        onTap: () =>
            _editDialog('version', 'App Version', settings['version'] ?? '1.0.0'),
      ),
    ]);
  }

  // ─── 7. SECURITY SETTINGS ─────────────────────────────────────────────────

  Widget _buildSecuritySettings() {
    final sAsync = ref.watch(_securitySettingsProvider);
    return sAsync.when(
      loading: () => _loadingCard(),
      error: (e, _) => _errorCard(e.toString()),
      data: (sec) => _card(children: [
        _switchRow(
          title: 'Two-Factor Auth',
          subtitle: 'Require OTP for admin login',
          value: sec['twoFactorEnabled'] ?? false,
          onChanged: (v) =>
              _updateSetting('security', 'twoFactorEnabled', v),
        ),
        _divider(),
        _tile(
          title: 'Session Timeout',
          trailing: Text(
            '${sec['sessionTimeout'] ?? '4'} Hours',
            style: _trailingStyle,
          ),
          icon: Icons.timer_rounded,
          onTap: () => _picker('security:sessionTimeout', 'Session Timeout', [
            '1', '2', '4', '8', '12', '24',
          ], doc: 'security', key: 'sessionTimeout'),
        ),
        _divider(),
        _actionTile(
          title: 'Force Logout All Users',
          subtitle: 'Invalidates all active sessions',
          icon: Icons.logout_rounded,
          isDestructive: true,
          onTap: () => _confirmAction(
            'Force Logout All',
            'This will sign out every user from the app immediately.',
            () => _forceLogoutAll(),
          ),
        ),
        _divider(),
        _actionTile(
          title: 'Change Admin Password',
          subtitle: 'Update your account password',
          icon: Icons.lock_reset_rounded,
          onTap: () => _changeAdminPassword(),
        ),
      ]),
    );
  }

  // ─── 8. DATA MANAGEMENT ───────────────────────────────────────────────────

  Widget _buildDataManagement() {
    return _card(children: [
      _actionTile(
        title: 'Backup All Data',
        subtitle: 'Export full Firestore data as JSON',
        icon: Icons.cloud_upload_rounded,
        onTap: () => _backupData(),
      ),
      _divider(),
      _actionTile(
        title: 'Export Participants CSV',
        subtitle: 'Download/share participants list',
        icon: Icons.download_rounded,
        onTap: () async {
          final snap =
              await ref.read(userRepositoryProvider).getRealTimeMembers().first;
          _exportUsersCSV(snap);
        },
      ),
      _divider(),
      StreamBuilder<QuerySnapshot>(
        stream: _firestore.collection('tickets').snapshots(),
        builder: (ctx, snap) {
          final count = snap.data?.docs.length ?? 0;
          return _actionTile(
            title: 'Export Tickets ($count)',
            subtitle: 'Download all ticket records as CSV',
            icon: Icons.confirmation_number_rounded,
            onTap: () => _exportTicketsCSV(snap.data?.docs ?? []),
          );
        },
      ),
      _divider(),
      _actionTile(
        title: 'Reset Event Data',
        subtitle: 'Wipe all records — irreversible',
        icon: Icons.refresh_rounded,
        isDestructive: true,
        onTap: () => _confirmAction(
          'Reset Event Data',
          'This will delete ALL events, tickets, schedules and speakers. This CANNOT be undone.',
          () => _resetEventData(),
        ),
      ),
    ]);
  }

  // ─── 9. ANALYTICS OVERVIEW ────────────────────────────────────────────────

  Widget _buildAnalyticsOverview() {
    final aAsync = ref.watch(_analyticsProvider);
    return aAsync.when(
      loading: () => _loadingCard(),
      error: (e, _) => _errorCard(e.toString()),
      data: (stats) => _card(children: [
        _statRow(
          'Total Users',
          NumberFormat.compact().format(stats['totalUsers'] ?? 0),
          Icons.people_rounded,
          color: AppColors.saasInfo,
        ),
        _divider(),
        _statRow(
          'Active Now',
          '${stats['activeNow'] ?? 0}',
          Icons.online_prediction_rounded,
          color: AppColors.saasSuccess,
        ),
        _divider(),
        _statRow(
          'Tickets Sold',
          NumberFormat.compact().format(stats['ticketsSold'] ?? 0),
          Icons.confirmation_number_rounded,
          color: AppColors.saasPrimary,
        ),
        _divider(),
        // Live revenue from Firestore
        StreamBuilder<AggregateQuerySnapshot>(
          stream: Stream.fromFuture(
            FirebaseFirestore.instance
                .collectionGroup('tickets')
                .where('isPaid', isEqualTo: true)
                .count()
                .get(),
          ),
          builder: (ctx, snap) {
            return _statRow(
              'Paid Tickets',
              snap.hasData
                  ? NumberFormat.compact().format(snap.data!.count)
                  : '...',
              Icons.credit_card_rounded,
              color: const Color(0xFFF59E0B),
            );
          },
        ),
      ]),
    );
  }

  // ─── Reusable tiles ───────────────────────────────────────────────────────

  TextStyle get _trailingStyle => GoogleFonts.inter(
        color: AppColors.saasPrimary,
        fontWeight: FontWeight.bold,
        fontSize: 13,
      );

  Widget _divider() => Divider(
      height: 1, color: AppColors.saasBorder.withValues(alpha: 0.4),
      indent: 16, endIndent: 16);

  Widget _tile({
    required String title,
    required Widget trailing,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.saasTextSecondary, size: 20),
      title: Text(title,
          style: GoogleFonts.inter(
              color: AppColors.saasTextPrimary, fontSize: 14)),
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        trailing,
        const SizedBox(width: 6),
        const Icon(Icons.chevron_right_rounded,
            color: AppColors.saasBorder, size: 18),
      ]),
    );
  }

  Widget _actionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    final color =
        isDestructive ? AppColors.saasDanger : AppColors.saasPrimary;
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: color, size: 22),
      title: Text(title,
          style: GoogleFonts.inter(
              color: isDestructive
                  ? AppColors.saasDanger
                  : AppColors.saasTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 14)),
      subtitle: Text(subtitle,
          style: GoogleFonts.inter(
              color: AppColors.saasTextSecondary, fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded,
          color: AppColors.saasBorder, size: 18),
    );
  }

  Widget _switchRow({
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
    String? subtitle,
    bool isDestructive = false,
  }) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      activeThumbColor:
          isDestructive ? AppColors.saasDanger : AppColors.saasPrimary,
      title: Text(title,
          style: GoogleFonts.inter(
              color: AppColors.saasTextPrimary, fontSize: 14)),
      subtitle: subtitle != null
          ? Text(subtitle,
              style: GoogleFonts.inter(
                  color: AppColors.saasTextSecondary, fontSize: 12))
          : null,
    );
  }

  Widget _statRow(String label, String value, IconData icon,
      {Color color = AppColors.saasPrimary}) {
    return ListTile(
      leading: Icon(icon, color: color, size: 22),
      title: Text(label,
          style: GoogleFonts.inter(
              color: AppColors.saasTextSecondary, fontSize: 13)),
      trailing: Text(value,
          style: GoogleFonts.outfit(
              color: AppColors.saasTextPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 22)),
    );
  }

  Widget _statusBadge(String status) {
    final Map<String, Color> colors = {
      'Live': AppColors.saasSuccess,
      'Upcoming': AppColors.saasInfo,
      'Completed': AppColors.saasTextSecondary,
      'Cancelled': AppColors.saasDanger,
    };
    final c = colors[status] ?? AppColors.saasPrimary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: c.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: c.withValues(alpha: 0.3))),
      child: Text(status,
          style: GoogleFonts.outfit(
              color: c, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _loadingCard() => _card(children: [
        const Padding(
          padding: EdgeInsets.all(20),
          child: Center(
              child: CircularProgressIndicator(color: AppColors.saasPrimary)),
        )
      ]);

  Widget _errorCard(String msg) => _card(children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Error: $msg',
              style: const TextStyle(color: AppColors.saasDanger)),
        )
      ]);

  // ─── Dialogs ──────────────────────────────────────────────────────────────

  void _editDialog(String key, String title, String current,
      {String doc = 'general'}) {
    final ctrl = TextEditingController(text: current);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.saasCardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.saasBorder.withValues(alpha: 0.2),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.saasTextSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saasPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              _firestore.collection('app_settings').doc(doc).set(
                  {key: ctrl.text.trim()}, SetOptions(merge: true));
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _picker(String id, String title, List<String> options,
      {String doc = 'general', String? key}) {
    final parts = id.split(':');
    final actualDoc = parts.length > 1 ? parts[0] : doc;
    final actualKey = key ?? (parts.length > 1 ? parts[1] : id);

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.saasCardBg,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(title,
                style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
          ),
          ...options.map(
            (o) => ListTile(
              title: Text(o,
                  style:
                      const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.chevron_right_rounded,
                  color: Colors.white24),
              onTap: () {
                _firestore
                    .collection('app_settings')
                    .doc(actualDoc)
                    .set({actualKey: o}, SetOptions(merge: true));
                Navigator.pop(ctx);
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void _confirmAction(String title, String message, Future<void> Function() action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.saasCardBg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(title,
            style: GoogleFonts.outfit(
                color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(message,
            style: GoogleFonts.inter(
                color: AppColors.saasTextSecondary, fontSize: 14)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel',
                  style:
                      TextStyle(color: AppColors.saasTextSecondary))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saasDanger,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () async {
              Navigator.pop(ctx);
              await action();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$title completed',
                        style: GoogleFonts.inter(color: Colors.white)),
                    backgroundColor: AppColors.saasSuccess,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _showAnnouncementDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, ss) => AlertDialog(
          backgroundColor: AppColors.saasCardBg,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Send Announcement',
              style: GoogleFonts.outfit(
                  color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'This message will appear as a notification for all users.',
                  style: GoogleFonts.inter(
                      color: AppColors.saasTextSecondary, fontSize: 12)),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl,
                maxLines: 4,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type your announcement here…',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: AppColors.saasBorder.withValues(alpha: 0.2),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel',
                    style:
                        TextStyle(color: AppColors.saasTextSecondary))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saasPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              onPressed: _isSavingAnnouncement
                  ? null
                  : () async {
                      if (ctrl.text.trim().isEmpty) return;
                      ss(() => _isSavingAnnouncement = true);
                      await _firestore.collection('announcements').add({
                        'message': ctrl.text.trim(),
                        'createdAt': FieldValue.serverTimestamp(),
                        'sentBy': _auth.currentUser?.email ?? 'Admin',
                        'isRead': false,
                      });
                      ss(() => _isSavingAnnouncement = false);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Announcement sent!',
                                style: GoogleFonts.inter(color: Colors.white)),
                            backgroundColor: AppColors.saasSuccess,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    },
              child: _isSavingAnnouncement
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child:
                          CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Broadcast'),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Users management sheet ───────────────────────────────────────────────

  void _showUsersSheet(List<Participant> users) {
    final searchCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        builder: (_, sc) => StatefulBuilder(
          builder: (ctx, ss) {
            final query = searchCtrl.text.toLowerCase();
            final filtered = users
                .where((u) =>
                    u.name.toLowerCase().contains(query) ||
                    u.email.toLowerCase().contains(query))
                .toList();
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(children: [
                const SizedBox(height: 12),
                Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                        color: Colors.white12,
                        borderRadius: BorderRadius.circular(2))),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Platform Users',
                          style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white)),
                      const SizedBox(height: 12),
                      TextField(
                        controller: searchCtrl,
                        onChanged: (_) => ss(() {}),
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Search users…',
                          hintStyle: const TextStyle(color: Colors.white38),
                          prefixIcon: const Icon(Icons.search,
                              color: Colors.white38),
                          filled: true,
                          fillColor:
                              AppColors.saasBorder.withValues(alpha: 0.2),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    controller: sc,
                    itemCount: filtered.length,
                    itemBuilder: (ctx, i) {
                      final u = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.saasPrimary.withValues(alpha: 0.2),
                          child: Text(
                            u.name.isNotEmpty ? u.name[0].toUpperCase() : 'U',
                            style: const TextStyle(
                                color: AppColors.saasPrimary,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(u.name,
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w600)),
                        subtitle: Text(u.email,
                            style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.4),
                                fontSize: 12)),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert,
                              color: Colors.white38),
                          color: AppColors.saasCardBg,
                          onSelected: (role) async {
                            await _firestore
                                .collection('users')
                                .doc(u.id)
                                .update({'role': role});
                          },
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'admin',
                              child: Row(children: [
                                const Icon(Icons.shield_rounded,
                                    color: AppColors.saasPrimary, size: 16),
                                const SizedBox(width: 8),
                                Text('Make Admin',
                                    style: GoogleFonts.inter(
                                        color: Colors.white)),
                              ]),
                            ),
                            PopupMenuItem(
                              value: 'organizer',
                              child: Row(children: [
                                const Icon(Icons.supervised_user_circle_rounded,
                                    color: AppColors.saasSuccess, size: 16),
                                const SizedBox(width: 8),
                                Text('Make Manager',
                                    style: GoogleFonts.inter(
                                        color: Colors.white)),
                              ]),
                            ),
                            PopupMenuItem(
                              value: 'user',
                              child: Row(children: [
                                const Icon(Icons.person_rounded,
                                    color: AppColors.saasTextSecondary, size: 16),
                                const SizedBox(width: 8),
                                Text('Make Member',
                                    style: GoogleFonts.inter(
                                        color: Colors.white)),
                              ]),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ]),
            );
          },
        ),
      ),
    );
  }

  // ─── Backend actions ──────────────────────────────────────────────────────

  Future<void> _clearAllChats() async {
    final batch = _firestore.batch();
    final chats = await _firestore.collection('chats').get();
    for (final chat in chats.docs) {
      final messages = await chat.reference.collection('messages').get();
      for (final msg in messages.docs) {
        batch.delete(msg.reference);
      }
      batch.delete(chat.reference);
    }
    await batch.commit();
  }

  Future<void> _forceLogoutAll() async {
    // Write a global force-logout timestamp. App reads this on startup.
    await _firestore
        .collection('app_settings')
        .doc('security')
        .set({'forceLogoutAt': FieldValue.serverTimestamp()},
            SetOptions(merge: true));
    // Mark all users as offline
    final users = await _firestore.collection('users').get();
    final batch = _firestore.batch();
    for (final u in users.docs) {
      batch.update(u.reference, {'isOnline': false});
    }
    await batch.commit();
  }

  Future<void> _resetEventData() async {
    final collections = ['events', 'schedules', 'speakers', 'sponsors', 'tickets'];
    for (final col in collections) {
      final docs = await _firestore.collection(col).get();
      final batch = _firestore.batch();
      for (final d in docs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();
    }
  }

  Future<void> _exportUsersCSV(List<Participant> users) async {
    final rows = <String>['Name,Email,Role,Mobile,Online'];
    for (final u in users) {
      rows.add(
          '"${u.name}","${u.email}","${u.role}","${u.mobile}","${u.isOnline}"');
    }
    final csv = rows.join('\n');
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('CSV copied to clipboard'),
            backgroundColor: AppColors.saasSuccess,
          ),
        );
      }
    } else {
      await Share.share(csv, subject: 'Participants Export');
    }
  }

  Future<void> _exportTicketsCSV(List<QueryDocumentSnapshot> docs) async {
    final rows = <String>['TicketID,UserID,EventID,IsPaid,Amount'];
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      rows.add(
          '"${d.id}","${data['userId'] ?? ''}","${data['eventId'] ?? ''}","${data['isPaid'] ?? false}","${data['amount'] ?? 0}"');
    }
    final csv = rows.join('\n');
    if (kIsWeb) {
      await Clipboard.setData(ClipboardData(text: csv));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ticket CSV copied to clipboard'),
            backgroundColor: AppColors.saasSuccess,
          ),
        );
      }
    } else {
      await Share.share(csv, subject: 'Tickets Export');
    }
  }

  Future<void> _backupData() async {
    // Fetch key collections and encode to JSON for sharing
    final Map<String, dynamic> backup = {};
    for (final col in ['events', 'users', 'schedules']) {
      final snap = await _firestore.collection(col).get();
      backup[col] = snap.docs.map((d) => d.data()).toList();
    }
    final json = const JsonEncoder.withIndent('  ').convert(backup);
    await Share.share(json,
        subject: 'Platform Backup ${DateFormat('yyyyMMdd').format(DateTime.now())}');
  }

  Future<void> _changeAdminPassword() async {
    final user = _auth.currentUser;
    if (user?.email == null) return;
    await _auth.sendPasswordResetEmail(email: user!.email!);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'Password reset email sent to ${user.email}',
              style: GoogleFonts.inter(color: Colors.white)),
          backgroundColor: AppColors.saasSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }
}
