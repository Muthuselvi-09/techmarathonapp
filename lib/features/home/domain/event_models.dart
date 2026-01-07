import 'package:cloud_firestore/cloud_firestore.dart';

class CodingEvent {
  final String id;
  final String name;
  final String description;
  final DateTime date;
  final String location;
  final double? latitude;
  final double? longitude;
  final String imageUrl;
  final List<String> speakerIds;
  final String category;
  final List<Speaker> speakers; // Added to match MockData
  final List<Sponsor> sponsors; // Added to match MockData
  final int participantCount; // Added to match MockData

  CodingEvent({
    required this.id,
    required this.name,
    required this.description,
    required this.date,
    required this.location,
    this.latitude,
    this.longitude,
    required this.imageUrl,
    required this.speakerIds,
    required this.category,
    this.speakers = const [],
    this.sponsors = const [],
    this.participantCount = 0,
  });

  factory CodingEvent.fromMap(Map<String, dynamic> data, String id) {
    return CodingEvent(
      id: id,
      name: data['title'] ?? data['name'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['locationName'] ?? data['location'] ?? '',
      latitude: (data['location'] is Map ? (data['location']['lat'] ?? 0.0).toDouble() : 0.0),
      longitude: (data['location'] is Map ? (data['location']['lng'] ?? 0.0).toDouble() : 0.0),
      imageUrl: data['imageUrl'] ?? '',
      speakerIds: List<String>.from(data['speakerIds'] ?? []),
      category: data['category'] ?? '',
    );
  }

  factory CodingEvent.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CodingEvent.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'date': Timestamp.fromDate(date),
      'locationName': location,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'imageUrl': imageUrl,
      'speakerIds': speakerIds,
      'category': category,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();
}

class Participant {
  final String id;
  final String name;
  final String email;
  final String mobile;
  final String? profileImage;
  final double profileCompletion;
  final double? latitude;
  final double? longitude;
  final String role; // 'user', 'organizer', 'admin'
  final DateTime? joinedAt;
  final bool isOnline;
  final DateTime? lastActive;

  Participant({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    this.profileImage,
    this.profileCompletion = 0.5,
    this.latitude,
    this.longitude,
    this.role = 'user',
    this.joinedAt,
    this.isOnline = false,
    this.lastActive,
  });

  factory Participant.fromMap(Map<String, dynamic> data, String id) {
    return Participant(
      id: id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      mobile: data['mobile'] ?? '',
      profileImage: data['profileImage'],
      profileCompletion: (data['profileCompletion'] ?? 0.5).toDouble(),
      latitude: (data['location'] is Map ? (data['location']['lat'] ?? 0.0).toDouble() : 0.0),
      longitude: (data['location'] is Map ? (data['location']['lng'] ?? 0.0).toDouble() : 0.0),
      role: data['role'] ?? 'user',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
      isOnline: data['isOnline'] ?? false,
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
    );
  }

  factory Participant.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Participant.fromMap(data, doc.id);
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'mobile': mobile,
      'profileImage': profileImage,
      'profileCompletion': profileCompletion,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'role': role,
      'joinedAt': joinedAt != null ? Timestamp.fromDate(joinedAt!) : null,
      'isOnline': isOnline,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
    };
  }
}

class Sponsor {
  final String id;
  final String name;
  final String company;
  final String jobPosition;
  final String logoUrl;
  final String? description;
  final double? latitude;
  final double? longitude;

  Sponsor({
    required this.id,
    required this.name,
    required this.company,
    required this.jobPosition,
    required this.logoUrl,
    this.description,
    this.latitude,
    this.longitude,
  });

  factory Sponsor.fromMap(Map<String, dynamic> data, String id) {
    return Sponsor(
      id: id,
      name: data['name'] ?? '',
      company: data['company'] ?? '',
      jobPosition: data['jobPosition'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      description: data['description'],
      latitude: (data['location'] is Map ? (data['location']['lat'] ?? 0.0).toDouble() : 0.0),
      longitude: (data['location'] is Map ? (data['location']['lng'] ?? 0.0).toDouble() : 0.0),
    );
  }

  factory Sponsor.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Sponsor.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'company': company,
      'jobPosition': jobPosition,
      'logoUrl': logoUrl,
      'description': description,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
    };
  }

  Map<String, dynamic> toFirestore() => toMap();
}

class Speaker {
  final String id;
  final String name;
  final String topic;
  final String company;
  final String photoUrl;
  final String? bio;
  final double? latitude;
  final double? longitude;

  Speaker({
    required this.id,
    required this.name,
    required this.topic,
    required this.company,
    required this.photoUrl,
    this.bio,
    this.latitude,
    this.longitude,
  });

  factory Speaker.fromMap(Map<String, dynamic> data, String id) {
    return Speaker(
      id: id,
      name: data['name'] ?? '',
      topic: data['topic'] ?? '',
      company: data['company'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      bio: data['bio'],
      latitude: (data['location'] is Map ? (data['location']['lat'] ?? 0.0).toDouble() : 0.0),
      longitude: (data['location'] is Map ? (data['location']['lng'] ?? 0.0).toDouble() : 0.0),
    );
  }

  factory Speaker.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Speaker.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'topic': topic,
      'company': company,
      'photoUrl': photoUrl,
      'bio': bio,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
    };
  }

  Map<String, dynamic> toFirestore() => toMap();
}

class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
  });

  factory ChatMessage.fromFirestore(DocumentSnapshot doc, String currentUserId) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return ChatMessage(
      text: data['text'] ?? data['messageText'] ?? '',
      isMe: data['senderId'] == currentUserId,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class CourseModel {
  final String id;
  final String title;
  final String level;
  final String duration;
  final double price;
  final String imageUrl;
  final List<String> benefits;

  CourseModel({
    required this.id,
    required this.title,
    required this.level,
    required this.duration,
    required this.price,
    required this.imageUrl,
    required this.benefits,
  });

  factory CourseModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CourseModel(
      id: doc.id,
      title: data['title'] ?? '',
      level: data['level'] ?? '',
      duration: data['duration'] ?? '',
      price: (data['price'] ?? 0.0).toDouble(),
      imageUrl: data['imageUrl'] ?? '',
      benefits: List<String>.from(data['benefits'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'level': level,
      'duration': duration,
      'price': price,
      'imageUrl': imageUrl,
      'benefits': benefits,
    };
  }
}
