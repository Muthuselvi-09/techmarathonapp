import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../home/domain/event_models.dart';
import '../../../../features/auth/presentation/widgets/auth_widgets.dart';

class AdminEventManagementScreen extends StatefulWidget {
  const AdminEventManagementScreen({super.key});

  @override
  State<AdminEventManagementScreen> createState() => _AdminEventManagementScreenState();
}

class _AdminEventManagementScreenState extends State<AdminEventManagementScreen> {
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

  void _showEventDialog([CodingEvent? event]) {
    final nameController = TextEditingController(text: event?.name ?? '');
    final locationController = TextEditingController(text: event?.location ?? '');
    final descriptionController = TextEditingController(text: event?.description ?? '');
    final imageController = TextEditingController(text: event?.imageUrl ?? '');
    final categoryController = TextEditingController(text: event?.category ?? 'Tech');

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                event == null ? 'Create New Event' : 'Edit Event',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              PremiumTextField(
                controller: nameController,
                hintText: 'Event Name',
                icon: Icons.event_note_rounded,
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: locationController,
                hintText: 'Location Name',
                icon: Icons.location_on_rounded,
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: descriptionController,
                hintText: 'Description',
                icon: Icons.description_rounded,
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: imageController,
                hintText: 'Image URL',
                icon: Icons.image_rounded,
              ),
              const SizedBox(height: 16),
              PremiumTextField(
                controller: categoryController,
                hintText: 'Category',
                icon: Icons.category_rounded,
              ),
              const SizedBox(height: 32),
              PremiumGradientButton(
                text: event == null ? 'CREATE EVENT' : 'UPDATE EVENT',
                onPressed: () async {
                  if (nameController.text.isNotEmpty && locationController.text.isNotEmpty) {
                    final data = {
                      'name': nameController.text.trim(),
                      'location': locationController.text.trim(),
                      'description': descriptionController.text.trim(),
                      'imageUrl': imageController.text.trim(),
                      'category': categoryController.text.trim(),
                      'date': event?.date ?? DateTime.now(),
                      'speakerIds': event?.speakerIds ?? [],
                    };

                    if (event == null) {
                      await _firestore.collection('events').add(data);
                    } else {
                      await _firestore.collection('events').doc(event.id).update(data);
                    }
                    if (context.mounted) Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Event Management',
          style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            onPressed: () => _showEventDialog(),
            icon: const Icon(Icons.add_rounded, color: AppColors.codingRimPrimary),
          ),
        ],
      ),
      body: AnimatedGradientBackground(
        child: StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('events').orderBy('date', descending: false).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.codingRimPrimary));
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: AppColors.error)));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No events found', style: TextStyle(color: AppColors.textDim)));
            }

            final events = snapshot.data!.docs.map((doc) => CodingEvent.fromFirestore(doc)).toList();

            return ListView.builder(
              padding: const EdgeInsets.all(24),
              itemCount: events.length,
              itemBuilder: (context, index) {
                return _buildEventCard(events[index]);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildEventCard(CodingEvent event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(event.imageUrl.isNotEmpty ? event.imageUrl : 'https://images.unsplash.com/photo-1540575861501-7ad0582371f.jpeg'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            title: Text(
              event.name,
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            subtitle: Text(
              'Location: ${event.location}',
              style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _buildSmallAction('Edit', Icons.edit_rounded, Colors.blue, () => _showEventDialog(event)),
                const SizedBox(width: 8),
                _buildSmallAction('Delete', Icons.delete_outline_rounded, AppColors.error, () async {
                  await _firestore.collection('events').doc(event.id).delete();
                }),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSmallAction(String label, IconData icon, Color color, VoidCallback onTap) {
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 16, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontSize: 12),
      ),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        padding: const EdgeInsets.symmetric(horizontal: 12),
      ),
    );
  }
}
