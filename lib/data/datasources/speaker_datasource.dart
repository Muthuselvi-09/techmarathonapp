import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';

abstract class SpeakerDataSource {
  Stream<List<Speaker>> watchSpeakers(String eventId);
  Future<Speaker?> getSpeakerById(String id);
  Future<void> addSpeaker(Speaker speaker);
  Future<void> updateSpeaker(Speaker speaker);
  Future<void> deleteSpeaker(String eventId, String id);
}

class SpeakerDataSourceImpl implements SpeakerDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Speaker>> watchSpeakers(String eventId) {
    // SINGLE SOURCE OF TRUTH: Firestore Stream
    // Removed orderBy to avoid composite index requirement
    return _firestore
        .collection('events')
        .doc(eventId)
        .collection('speakers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final speakers = snapshot.docs
          .map((doc) => Speaker.fromMap(doc.data(), doc.id))
          .toList();
      // Sort in-memory by createdAt if needed
      speakers.sort((a, b) {
        if (a.createdAt == null && b.createdAt == null) return 0;
        if (a.createdAt == null) return 1;
        if (b.createdAt == null) return -1;
        return b.createdAt!.compareTo(a.createdAt!);
      });
      return speakers;
    });
  }

  @override
  Future<Speaker?> getSpeakerById(String id) async {
    try {
      final doc = await _firestore.collectionGroup('speakers')
        .where(FieldPath.documentId, isEqualTo: id)
        .limit(1)
        .get();
      if (doc.docs.isEmpty) return null;
      return Speaker.fromMap(doc.docs.first.data(), doc.docs.first.id);
    } catch (e) {
      debugPrint('Error getting speaker by id: $e');
      return null;
    }
  }

  @override
  Future<void> addSpeaker(Speaker speaker) async {
    String docId = speaker.id;
    if (docId.isEmpty) {
        docId = _firestore
            .collection('events')
            .doc(speaker.eventId)
            .collection('speakers')
            .doc().id;
    }
    
    await _firestore
      .collection('events')
      .doc(speaker.eventId)
      .collection('speakers')
      .doc(docId)
      .set(speaker.toMap());
  }

  @override
  Future<void> updateSpeaker(Speaker speaker) async {
    await _firestore
        .collection('events')
        .doc(speaker.eventId)
        .collection('speakers')
        .doc(speaker.id)
        .update(speaker.toMap());
  }

  @override
  Future<void> deleteSpeaker(String eventId, String id) async {
    await _firestore
        .collection('events')
        .doc(eventId)
        .collection('speakers')
        .doc(id)
        .update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
