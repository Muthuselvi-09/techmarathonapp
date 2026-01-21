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
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'day': day,
      'title': title,
      'description': description,
      'startTime': startTime,
      'endTime': endTime,
      'createdAt': createdAt ?? FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'isActive': isActive,

      'location': location,
      'mediaUrls': mediaUrls,
    };
  }
}
