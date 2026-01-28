import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';

abstract class SpeakerDataSource {
  Stream<List<Speaker>> watchSpeakers(String eventId);
  Stream<List<Speaker>> watchAllSpeakers();
  Future<Speaker?> getSpeakerById(String id);
  Future<void> addSpeaker(Speaker speaker);
  Future<void> updateSpeaker(Speaker speaker);
  Future<void> deleteSpeaker(String id); // Global delete
  Future<void> addSpeakerToEvent(String eventId, String speakerId);
  Future<void> removeSpeakerFromEvent(String eventId, String speakerId);
}

class SpeakerDataSourceImpl implements SpeakerDataSource {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<List<Speaker>> watchSpeakers(String eventId) {
    return _firestore
        .collection('event_speaker_links')
        .where('eventId', isEqualTo: eventId)
        .snapshots()
        .asyncMap((snapshot) async {
      final speakerIds = snapshot.docs
          .map((doc) => doc.data()['speakerId'] as String)
          .toList();

      if (speakerIds.isEmpty) {
        return [];
      }

      // Firestore whereIn supports up to 10 items (or 30 in some regions), 
      // but for safety and simplicity handling batches if needed.
      // For now assuming < 30 speakers per event.
      List<Speaker> speakers = [];
      
      // Split into chunks of 10 to be safe with Firestore limits
      for (var i = 0; i < speakerIds.length; i += 10) {
        var end = (i + 10 < speakerIds.length) ? i + 10 : speakerIds.length;
        var chunk = speakerIds.sublist(i, end);
        
        final chunkSnapshot = await _firestore
            .collection('speakers')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();

        speakers.addAll(chunkSnapshot.docs
            .map((doc) => Speaker.fromMap(doc.data(), doc.id))
            .where((s) => s.isActive) // Filter locally if needed
            .toList());
      }
      return speakers;
    });
  }

  @override
  Stream<List<Speaker>> watchAllSpeakers() {
    return _firestore
        .collection('speakers')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) {
      final speakers = snapshot.docs
          .map((doc) => Speaker.fromMap(doc.data(), doc.id))
          .toList();
      
      // Sort in memory to avoid Firestore index requirement
      speakers.sort((a, b) => (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now()));
      return speakers;
    });
  }

  @override
  Future<Speaker?> getSpeakerById(String id) async {
    try {
      final doc = await _firestore.collection('speakers').doc(id).get();
      if (!doc.exists) return null;
      return Speaker.fromMap(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('Error getting speaker by id: $e');
      return null;
    }
  }

  @override
  Future<void> addSpeaker(Speaker speaker) async {
    String docId = speaker.id;
    if (docId.isEmpty) {
        docId = _firestore.collection('speakers').doc().id;
    }
    
    await _firestore
      .collection('speakers')
      .doc(docId)
      .set(speaker.toMap());
  }

  @override
  Future<void> updateSpeaker(Speaker speaker) async {
    await _firestore
        .collection('speakers')
        .doc(speaker.id)
        .update(speaker.toMap());
  }

  @override
  Future<void> deleteSpeaker(String id) async {
    // Soft delete globally
    await _firestore
        .collection('speakers')
        .doc(id)
        .update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> addSpeakerToEvent(String eventId, String speakerId) async {
    // Check if link exists to prevent duplicates
    final existing = await _firestore
        .collection('event_speaker_links')
        .where('eventId', isEqualTo: eventId)
        .where('speakerId', isEqualTo: speakerId)
        .get();

    if (existing.docs.isNotEmpty) return;

    await _firestore.collection('event_speaker_links').add({
      'eventId': eventId,
      'speakerId': speakerId,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> removeSpeakerFromEvent(String eventId, String speakerId) async {
    final snapshot = await _firestore
        .collection('event_speaker_links')
        .where('eventId', isEqualTo: eventId)
        .where('speakerId', isEqualTo: speakerId)
        .get();

    for (var doc in snapshot.docs) {
      await doc.reference.delete();
    }
  }
}
