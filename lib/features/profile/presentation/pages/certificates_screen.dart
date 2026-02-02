import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';

class CertificatesScreen extends ConsumerStatefulWidget {
  const CertificatesScreen({super.key});

  @override
  ConsumerState<CertificatesScreen> createState() => _CertificatesScreenState();
}

class _CertificatesScreenState extends ConsumerState<CertificatesScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  List<Map<String, String>> _certificates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCertificates();
  }

  Future<void> _loadCertificates() async {
    final userId = _auth.currentUser?.uid;
    final userName = _auth.currentUser?.displayName ?? 'User';
    
    if (userId == null) return;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      
      List<Map<String, String>> certs = [];
      
      // Add certificates for registered events
      if (data != null && data['registeredEvents'] != null) {
        final events = List<String>.from(data['registeredEvents']);
        for (var eventId in events) {
          certs.add({
            'id': 'cert_event_$eventId',
            'type': 'Event Participation',
            'name': 'Tech Marathon 2025',
            'userName': userName,
            'date': 'January 15, 2025',
          });
        }
      }
      
      // Add certificates for joined courses
      if (data != null && data['joinedCourses'] != null) {
        final courses = List<String>.from(data['joinedCourses']);
        final courseNames = {
          'course_001': 'AI & Machine Learning Fundamentals',
          'course_002': 'Cloud Architecture Best Practices',
          'course_003': 'Modern Mobile Development',
        };
        
        for (var courseId in courses) {
          certs.add({
            'id': 'cert_course_$courseId',
            'type': 'Course Completion',
            'name': courseNames[courseId] ?? 'Course',
            'userName': userName,
            'date': DateTime.now().toString().substring(0, 10),
          });
        }
      }
      
      setState(() {
        _certificates = certs;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _downloadCertificate(Map<String, String> cert) {
    // Basic download simulation - in production, this would generate a PDF
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Certificate for "${cert['name']}" will be downloaded'),
        backgroundColor: AppColors.primary,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.black,
          onPressed: () {},
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'CERTIFICATES',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            fontSize: 16,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _certificates.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.card_membership_outlined,
                        size: 80,
                        color: AppColors.textDim.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No certificates yet',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          color: AppColors.textDim,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Complete events or courses to earn certificates',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: AppColors.textDim.withValues(alpha: 0.7),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: _certificates.length,
                  itemBuilder: (context, index) {
                    final cert = _certificates[index];
                    return _buildCertificateCard(cert);
                  },
                ),
    );
  }

  Widget _buildCertificateCard(Map<String, String> cert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.surface,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.workspace_premium,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cert['type']!,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      cert['name']!,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.person, color: AppColors.textDim, size: 16),
              const SizedBox(width: 8),
              Text(
                cert['userName']!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: AppColors.textDim, size: 16),
              const SizedBox(width: 8),
              Text(
                'Completed: ${cert['date']}',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _downloadCertificate(cert),
              icon: const Icon(Icons.download, size: 18),
              label: Text(
                'Download Certificate',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
