import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/domain/event_models.dart';
import '../../../../features/auth/presentation/widgets/auth_widgets.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _verifyAdminRole();
  }

  Future<void> _verifyAdminRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) context.go('/login');
      return;
    }

    try {
      final doc = await _firestore.collection('admins').doc(user.uid).get();
      if (!doc.exists) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Access Denied: Admin verification failed.')),
          );
          context.go('/home');
        }
      }
    } catch (e) {
      if (mounted) context.go('/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          title: Text(
            'User Management',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
          ),
          bottom: TabBar(
            indicatorColor: AppColors.codingRimPrimary,
            labelStyle: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'Users'),
              Tab(text: 'Organizers'),
            ],
          ),
        ),
        body: AnimatedGradientBackground(
          child: TabBarView(
            children: [
              _buildUserList('User'),
              _buildUserList('Organizer'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserList(String type) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: AppColors.codingRimPrimary));
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: Text('No participants found', style: const TextStyle(color: AppColors.textDim)));
        }

        final participants = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return Participant(
            id: doc.id,
            name: data['name'] ?? 'User',
            email: data['email'] ?? '',
            mobile: data['mobile'] ?? '',
            profileImage: data['profileImage'],
            profileCompletion: (data['profileCompletion'] ?? 0.0).toDouble(),
            role: data['role'] ?? 'user',
          );
        }).toList();

        final filteredList = type == 'Organizer' 
            ? participants.where((p) => p.role == 'organizer').toList()
            : participants.where((p) => p.role == 'user' || p.role == 'admin').toList();

        if (filteredList.isEmpty) {
          return Center(
            child: Text(
              'No ${type}s found',
              style: const TextStyle(color: AppColors.textDim),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: filteredList.length,
          itemBuilder: (context, index) {
            final participant = filteredList[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.05)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: CircleAvatar(
                  backgroundColor: AppColors.cardBg,
                  backgroundImage: participant.profileImage != null 
                      ? NetworkImage(participant.profileImage!) 
                      : null,
                  child: participant.profileImage == null 
                      ? const Icon(Icons.person_outline_rounded, color: AppColors.textSecondary)
                      : null,
                ),
                title: Text(
                  participant.name,
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                ),
                subtitle: Text(
                  participant.email,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                ),
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'chat') {
                      context.push('/chat', extra: participant);
                    } else if (value == 'delete') {
                      await _firestore.collection('users').doc(participant.id).delete();
                    } else if (value == 'block') {
                      await _firestore.collection('users').doc(participant.id).update({'isBlocked': true});
                    } else if (value == 'approve') {
                      await _firestore.collection('users').doc(participant.id).update({'role': 'organizer_approved'});
                    }
                  },
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textDim),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'chat',
                      child: Row(
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 20, color: AppColors.codingRimPrimary),
                          SizedBox(width: 8),
                          Text('Chat'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(value: 'block', child: Text('Block')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error))),
                    if (participant.role == 'organizer') const PopupMenuItem(value: 'approve', child: Text('Approve')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
