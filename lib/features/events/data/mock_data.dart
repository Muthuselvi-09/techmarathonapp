import 'package:tech_marathon_app/features/home/domain/event_models.dart';

class MockData {
  static final currentEvent = CodingEvent(
    id: 'tech_marathon_2025',
    name: 'Tech Marathon 2025',
    location: 'Silicon Valley Convention Center',
    date: DateTime(2025, 12, 28, 10, 0),
    description: 'The biggest tech marathon of the year.',
    imageUrl: 'https://images.unsplash.com/photo-1540575861501-7ad060e1c27b',
    speakerIds: ['sp1', 'sp2', 'sp3'],
    category: 'Technology',
    participantCount: 1250,
    sponsors: [
      Sponsor(
        id: 's1',
        name: 'Sarah Zhang',
        company: 'ZhaCommerce',
        jobPosition: 'Lead Architect',
        logoUrl: 'https://images.unsplash.com/photo-1438761681033-6461ffad8d80',
      ),
      Sponsor(
        id: 's2',
        name: 'Mike Ross',
        company: 'CloudFlow',
        jobPosition: 'Managing Director',
        logoUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e',
      ),
      Sponsor(
        id: 's3',
        name: 'Elena Gilbert',
        company: 'CodeStream',
        jobPosition: 'CEO',
        logoUrl: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2',
      ),
    ],
    speakers: [
      Speaker(
        id: 'sp1',
        name: 'Alex Rivera',
        topic: 'The Future of AI in Web',
        company: 'Coding Rim',
        photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d',
      ),
      Speaker(
        id: 'sp2',
        name: 'Jane Doe',
        topic: 'Modern Flutter Architectures',
        company: 'TechFlow',
        photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330',
      ),
      Speaker(
        id: 'sp3',
        name: 'John Smith',
        topic: 'Scaling Global Commerce',
        company: 'ZhaCommerce',
        photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e',
      ),
    ],
  );

  static final participants = [
    Participant(
      id: '1',
      name: 'Alex Johnson',
      email: 'alex.j@example.com',
      mobile: '+1 234 567 8900',
      profileImage: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6',
    ),
    Participant(
      id: '2',
      name: 'Sarah Williams',
      email: 'sarah.w@example.com',
      mobile: '+1 234 567 8901',
      profileImage: 'https://images.unsplash.com/photo-1517841905240-472988babdf9',
    ),
    Participant(
      id: '3',
      name: 'Michael Chen',
      email: 'm.chen@example.com',
      mobile: '+1 234 567 8902',
    ),
  ];

  static final mockMessages = [
    ChatMessage(text: 'Hey! Are you attending the AI keynote?', isMe: false, timestamp: DateTime.now().subtract(const Duration(minutes: 5))),
    ChatMessage(text: 'Yeah, definitely! See you there.', isMe: true, timestamp: DateTime.now().subtract(const Duration(minutes: 2))),
  ];
}
