import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';

final featuredCoursesProvider = Provider<List<CourseModel>>((ref) {
  return [
    CourseModel(
      id: '1',
      title: 'Full Stack App Development',
      level: 'Advanced',
      duration: '12 Weeks',
      price: 0,
      imageUrl: '',
      benefits: ['Lifetime Access', 'Certificate', '1-on-1 Mentorship'],
    ),
    CourseModel(
      id: '2',
      title: 'UI/UX Design for Tech',
      level: 'Intermediate',
      duration: '8 Weeks',
      price: 0,
      imageUrl: '',
      benefits: ['Portfolio Projects', 'Figma Mastery', 'Design Sprints'],
    ),
    CourseModel(
      id: '3',
      title: 'Backend Scalability',
      level: 'Advanced',
      duration: '10 Weeks',
      price: 0,
      imageUrl: '',
      benefits: ['Microservices', 'Kubernetes', 'Redis'],
    ),
  ];
});

