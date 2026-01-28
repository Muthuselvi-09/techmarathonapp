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
  final List<Speaker> speakers;
  final List<Sponsor> sponsors;
  final int participantCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

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
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory CodingEvent.fromMap(Map<String, dynamic> data, String id) {
    return CodingEvent(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['locationName'] ?? '',
      latitude: (data['location'] is Map ? (data['location']['lat'] ?? 0.0).toDouble() : 0.0),
      longitude: (data['location'] is Map ? (data['location']['lng'] ?? 0.0).toDouble() : 0.0),
      imageUrl: data['imageUrl'] ?? '',
      speakerIds: List<String>.from(data['speakerIds'] ?? []),
      category: data['category'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
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
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
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
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

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
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
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
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
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
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
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
  final String tier;
  final String websiteUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  final String eventId;

  Sponsor({
    required this.id,
    this.eventId = '',
    required this.name,
    required this.company,
    this.jobPosition = '',
    required this.tier,
    required this.logoUrl,
    required this.websiteUrl,
    this.description,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory Sponsor.fromMap(Map<String, dynamic> data, String id) {
    return Sponsor(
      id: id,
      eventId: data['eventId'] ?? '',
      name: data['name'] ?? '',
      company: data['company'] ?? '',
      jobPosition: data['jobPosition'] ?? '',
      tier: data['tier'] ?? '',
      logoUrl: data['logoUrl'] ?? '',
      websiteUrl: data['websiteUrl'] ?? '',
      description: data['description'],
      latitude: (data['location'] is Map ? (data['location']['lat'] ?? 0.0).toDouble() : 0.0),
      longitude: (data['location'] is Map ? (data['location']['lng'] ?? 0.0).toDouble() : 0.0),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  factory Sponsor.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Sponsor.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'company': company,
      'jobPosition': jobPosition,
      'tier': tier,
      'logoUrl': logoUrl,
      'websiteUrl': websiteUrl,
      'description': description,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  Sponsor copyWith({
    String? id,
    String? eventId,
    String? name,
    String? company,
    String? jobPosition,
    String? tier,
    String? logoUrl,
    String? websiteUrl,
    String? description,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Sponsor(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      company: company ?? this.company,
      jobPosition: jobPosition ?? this.jobPosition,
      tier: tier ?? this.tier,
      logoUrl: logoUrl ?? this.logoUrl,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      description: description ?? this.description,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class Speaker {
  final String id;
  final String name;
  final String topic;
  final String company;
  final String imageUrl;
  final String? bio;
  final String role;
  final String linkedinUrl;
  final double? latitude;
  final double? longitude;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  String get photoUrl => imageUrl;

  final String eventId;

  Speaker({
    required this.id,
    this.eventId = '',
    required this.name,
    this.topic = '',
    this.company = '',
    required this.imageUrl,
    this.bio,
    required this.role,
    required this.linkedinUrl,
    this.latitude,
    this.longitude,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory Speaker.fromMap(Map<String, dynamic> data, String id) {
    return Speaker(
      id: id,
      eventId: data['eventId'] ?? '',
      name: data['name'] ?? '',
      topic: data['topic'] ?? '',
      company: data['company'] ?? '',
      imageUrl: data['imageUrl'] ?? data['photoUrl'] ?? '',
      bio: data['bio'],
      role: data['role'] ?? '',
      linkedinUrl: data['linkedinUrl'] ?? data['linkedInUrl'] ?? '',
      latitude: (data['location'] is Map ? (data['location']['lat'] ?? 0.0).toDouble() : 0.0),
      longitude: (data['location'] is Map ? (data['location']['lng'] ?? 0.0).toDouble() : 0.0),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  factory Speaker.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Speaker.fromMap(data, doc.id);
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'name': name,
      'topic': topic,
      'company': company,
      'imageUrl': imageUrl,
      'bio': bio,
      'role': role,
      'linkedinUrl': linkedinUrl,
      'location': {
        'lat': latitude,
        'lng': longitude,
      },
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toFirestore() => toMap();

  Speaker copyWith({
    String? id,
    String? eventId,
    String? name,
    String? topic,
    String? company,
    String? imageUrl,
    String? bio,
    String? role,
    String? linkedinUrl,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return Speaker(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      name: name ?? this.name,
      topic: topic ?? this.topic,
      company: company ?? this.company,
      imageUrl: imageUrl ?? this.imageUrl,
      bio: bio ?? this.bio,
      role: role ?? this.role,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

class EventSpeakerLink {
  final String id;
  final String eventId;
  final String speakerId;
  final bool isFeatured;
  final int displayOrder;
  final DateTime? createdAt;

  EventSpeakerLink({
    required this.id,
    required this.eventId,
    required this.speakerId,
    this.isFeatured = false,
    this.displayOrder = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'speakerId': speakerId,
      'isFeatured': isFeatured,
      'displayOrder': displayOrder,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory EventSpeakerLink.fromMap(Map<String, dynamic> data, String id) {
    return EventSpeakerLink(
      id: id,
      eventId: data['eventId'] ?? '',
      speakerId: data['speakerId'] ?? '',
      isFeatured: data['isFeatured'] ?? false,
      displayOrder: data['displayOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}

class EventSponsorLink {
  final String id;
  final String eventId;
  final String sponsorId;
  final String tier;
  final int displayOrder;
  final DateTime? createdAt;

  EventSponsorLink({
    required this.id,
    required this.eventId,
    required this.sponsorId,
    this.tier = '',
    this.displayOrder = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'sponsorId': sponsorId,
      'tier': tier,
      'displayOrder': displayOrder,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
    };
  }

  factory EventSponsorLink.fromMap(Map<String, dynamic> data, String id) {
    return EventSponsorLink(
      id: id,
      eventId: data['eventId'] ?? '',
      sponsorId: data['sponsorId'] ?? '',
      tier: data['tier'] ?? '',
      displayOrder: data['displayOrder'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
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

class BrandingInfo {
  final String companyName;
  final String? companyLogoUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BrandingInfo({
    required this.companyName,
    this.companyLogoUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory BrandingInfo.fromMap(Map<String, dynamic> data) {
    return BrandingInfo(
      companyName: data['companyName'] ?? 'Event App',
      companyLogoUrl: data['companyLogoUrl'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyName': companyName,
      'companyLogoUrl': companyLogoUrl,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
