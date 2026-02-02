import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme/app_colors.dart';

class MyCoursesScreen extends ConsumerStatefulWidget {
  const MyCoursesScreen({super.key});

  @override
  ConsumerState<MyCoursesScreen> createState() => _MyCoursesScreenState();
}

class _MyCoursesScreenState extends ConsumerState<MyCoursesScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  Set<String> _joinedCourseIds = {};
  bool _isLoading = true;

  final List<Map<String, String>> _availableCourses = [
    {
      'id': 'course_001',
      'name': 'AI & Machine Learning Fundamentals',
      'instructor': 'Dr. Sarah Johnson',
      'duration': '8 weeks',
    },
    {
      'id': 'course_002',
      'name': 'Cloud Architecture Best Practices',
      'instructor': 'Michael Chen',
      'duration': '6 weeks',
    },
    {
      'id': 'course_003',
      'name': 'Modern Mobile Development',
      'instructor': 'Emily Rodriguez',
      'duration': '10 weeks',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadJoinedCourses();
  }

  Future<void> _loadJoinedCourses() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      final doc = await _firestore.collection('users').doc(userId).get();
      final data = doc.data();
      if (data != null && data['joinedCourses'] != null) {
        setState(() {
          _joinedCourseIds = Set<String>.from(data['joinedCourses']);
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinCourse(String courseId, String courseName) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) return;

    try {
      await _firestore.collection('users').doc(userId).set({
        'joinedCourses': FieldValue.arrayUnion([courseId]),
      }, SetOptions(merge: true));

      setState(() {
        _joinedCourseIds.add(courseId);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully joined $courseName'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join course: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'MY COURSES',
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
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AVAILABLE COURSES',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w900,
                      fontSize: 12,
                      letterSpacing: 2,
                      color: AppColors.textDim,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ..._availableCourses.map((course) => _buildCourseCard(course)),
                  const SizedBox(height: 32),
                  if (_joinedCourseIds.isNotEmpty) ...[
                    Text(
                      'MY JOINED COURSES',
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w900,
                        fontSize: 12,
                        letterSpacing: 2,
                        color: AppColors.textDim,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ..._availableCourses
                        .where((course) => _joinedCourseIds.contains(course['id']))
                        .map((course) => _buildJoinedCourseCard(course)),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildCourseCard(Map<String, String> course) {
    final isJoined = _joinedCourseIds.contains(course['id']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            course['name']!,
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                course['instructor']!,
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
              const Icon(Icons.access_time, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                course['duration']!,
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
            child: ElevatedButton(
              onPressed: isJoined ? null : () => _joinCourse(course['id']!, course['name']!),
              style: ElevatedButton.styleFrom(
                backgroundColor: isJoined ? AppColors.textDim : AppColors.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isJoined ? 'Joined' : 'Join Course (Free)',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinedCourseCard(Map<String, String> course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  course['name']!,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'In Progress',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.person_outline, color: AppColors.primary, size: 16),
              const SizedBox(width: 8),
              Text(
                course['instructor']!,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
