import 'package:cloud_firestore/cloud_firestore.dart';

class Schedule {
  final String id;
  final String eventId;
  final int day;
  final String title;
  final String description;
  final DateTime startTime;
  final DateTime endTime;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  final String location;
  final List<String> mediaUrls;

  // New Fields
  final String sessionType; // workshop, keynote, panel, break
  final int? capacity;
  final String hall;
  final DateTime sessionDate;
  final String status; // draft, published, cancelled, completed
  final String visibility; // all, vip, members
  final List<String> speakerIds;

  Schedule({
    required this.id,
    required this.eventId,
    required this.day,
    required this.title,
    required this.description,
    required this.startTime,
    required this.endTime,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    required this.location,
    required this.mediaUrls,
    
    // Default values for new fields to avoid breaking existing data immediately
    this.sessionType = 'keynote',
    this.capacity,
    this.hall = '',
    required this.sessionDate,
    this.status = 'published',
    this.visibility = 'all',
    this.speakerIds = const [],
  });

  factory Schedule.fromMap(Map<String, dynamic> map, String documentId) {
    return Schedule(
      id: documentId,
      eventId: map['eventId'] ?? '',
      day: map['day'] ?? 0,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      startTime: (map['startTime'] as Timestamp).toDate(),
      endTime: (map['endTime'] as Timestamp).toDate(),
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
      isActive: map['isActive'] ?? true,
      location: map['location'] ?? '',
      mediaUrls: List<String>.from(map['mediaUrls'] ?? []),
      
      sessionType: map['sessionType'] ?? 'keynote',
      capacity: map['capacity'],
      hall: map['hall'] ?? '',
      sessionDate: (map['sessionDate'] as Timestamp?)?.toDate() ?? (map['startTime'] as Timestamp).toDate(),
      status: map['status'] ?? 'published',
      visibility: map['visibility'] ?? 'all',
      speakerIds: List<String>.from(map['speakerIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'day': day,
      'title': title,
      'description': description,
      'startTime': Timestamp.fromDate(startTime),
      'endTime': Timestamp.fromDate(endTime),
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'isActive': isActive,
      'location': location,
      'mediaUrls': mediaUrls,
      'sessionType': sessionType,
      'capacity': capacity,
      'hall': hall,
      'sessionDate': Timestamp.fromDate(sessionDate),
      'status': status,
      'visibility': visibility,
      'speakerIds': speakerIds,
      'searchName': title.toLowerCase(),
    };
  }

  Schedule copyWith({
    String? id,
    String? eventId,
    int? day,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    String? location,
    List<String>? mediaUrls,
    String? sessionType,
    int? capacity,
    String? hall,
    DateTime? sessionDate,
    String? status,
    String? visibility,
    List<String>? speakerIds,
  }) {
    return Schedule(
      id: id ?? this.id,
      eventId: eventId ?? this.eventId,
      day: day ?? this.day,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      location: location ?? this.location,
      mediaUrls: mediaUrls ?? this.mediaUrls,
      sessionType: sessionType ?? this.sessionType,
      capacity: capacity ?? this.capacity,
      hall: hall ?? this.hall,
      sessionDate: sessionDate ?? this.sessionDate,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      speakerIds: speakerIds ?? this.speakerIds,
    );
  }
}

