import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neon_button.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';

class CourseDetailsScreen extends StatelessWidget {
  final CourseModel course;

  const CourseDetailsScreen({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.network(course.imageUrl, fit: BoxFit.cover),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildChip(course.level, AppColors.primary),
                      const SizedBox(width: 12),
                      _buildChip(course.duration, AppColors.secondary),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Text(
                    course.title,
                    style: Theme.of(context).textTheme.displayMedium,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Description',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Master the art of ${course.title} with industry-leading practices and hands-on projects. This course is designed to take you from fundamentals to advanced excellence.',
                    style: TextStyle(color: AppColors.textSecondary, height: 1.5),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'What you will get',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  ...course.benefits.map((benefit) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Text(benefit, style: const TextStyle(fontSize: 15)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 40),
                  NeonButton(
                    text: 'Enroll Now',
                    onPressed: () {},
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
      ),
    );
  }
}
