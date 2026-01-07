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
      imageUrl: 'https://images.unsplash.com/photo-1555066931-4365d14bab8c',
      benefits: ['Lifetime Access', 'Certificate', '1-on-1 Mentorship'],
    ),
    CourseModel(
      id: '2',
      title: 'UI/UX Design for Tech',
      level: 'Intermediate',
      duration: '8 Weeks',
      price: 0,
      imageUrl: 'https://images.unsplash.com/photo-1561070791-2526d30994b5',
      benefits: ['Portfolio Projects', 'Figma Mastery', 'Design Sprints'],
    ),
    CourseModel(
      id: '3',
      title: 'Backend Scalability',
      level: 'Advanced',
      duration: '10 Weeks',
      price: 0,
      imageUrl: 'https://images.unsplash.com/photo-1558494949-ef010cbdcc4b',
      benefits: ['Microservices', 'Kubernetes', 'Redis'],
    ),
  ];
});

final upcomingEventsProvider = Provider<List<CodingEvent>>((ref) {
  return [
    CodingEvent(
      id: '1',
      name: 'Tech Marathon 2025',
      description: 'The ultimate code sprint.',
      date: DateTime(2025, 3, 15),
      location: 'Bangalore, India',
      imageUrl: 'https://images.unsplash.com/photo-1540575861501-7ad060e1c27b',
      speakerIds: ['John Doe', 'Jane Smith'],
      category: 'Hackathon',
    ),
  ];
});
