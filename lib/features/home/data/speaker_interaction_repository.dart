
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final speakerInteractionRepositoryProvider = Provider((ref) => SpeakerInteractionRepository(FirebaseFirestore.instance));

class SpeakerInteractionRepository {
  final FirebaseFirestore _firestore;

  SpeakerInteractionRepository(this._firestore);

  // --- Saved Speakers ---

  Stream<List<String>> watchSavedSpeakerIds(String userId) {
    return _firestore
        .collection('saved_speakers')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc['speakerId'] as String).toList());
  }

  Future<void> toggleSaveSpeaker(String userId, String speakerId, bool isCurrentlySaved) async {
    final collection = _firestore.collection('saved_speakers');
    if (isCurrentlySaved) {
      final snapshot = await collection
          .where('userId', isEqualTo: userId)
          .where('speakerId', isEqualTo: speakerId)
          .get();
      for (final doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } else {
      await collection.add({
        'userId': userId,
        'speakerId': speakerId,
        'savedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // --- Questions ---

  Future<void> submitQuestion(String userId, String speakerId, String question) async {
    await _firestore.collection('speaker_questions').add({
      'userId': userId,
      'speakerId': speakerId,
      'question': question,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- Ratings ---

  Future<void> submitRating(String userId, String speakerId, double rating, String feedback) async {
    // Upsert rating
    final collection = _firestore.collection('speaker_ratings');
    final snapshot = await collection
        .where('userId', isEqualTo: userId)
        .where('speakerId', isEqualTo: speakerId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      await snapshot.docs.first.reference.update({
        'rating': rating,
        'feedback': feedback,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await collection.add({
        'userId': userId,
        'speakerId': speakerId,
        'rating': rating,
        'feedback': feedback,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<Map<String, dynamic>?> getUserRating(String userId, String speakerId) async {
    final snapshot = await _firestore
        .collection('speaker_ratings')
        .where('userId', isEqualTo: userId)
        .where('speakerId', isEqualTo: speakerId)
        .get();
    
    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }
}
