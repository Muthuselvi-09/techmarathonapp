import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(FirebaseFirestore.instance, FirebaseStorage.instance);
});

class ProfileRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfileRepository(this._firestore, this._storage);

  FirebaseFirestore getFirestoreInstance() => _firestore;

  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<void> saveProfile(Participant user) async {
    final Map<String, dynamic> data = {
      'name': user.name,
      'email': user.email,
      'mobile': user.mobile,
      'profileImage': user.profileImage,
      'profileCompletion': user.profileCompletion,
      'isComplete': user.profileCompletion >= 1.0,
      'role': user.role,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (user.joinedAt == null) {
      data['joinedAt'] = FieldValue.serverTimestamp();
    }

    await _usersCollection.doc(user.id).set(data, SetOptions(merge: true));
  }

  Future<Participant?> getProfile(String userId) async {
    final doc = await _usersCollection.doc(userId).get();
    if (!doc.exists) return null;

    final data = doc.data() as Map<String, dynamic>;
    return Participant(
      id: userId,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      mobile: data['mobile'] ?? '',
      profileImage: data['profileImage'],
      profileCompletion: (data['profileCompletion'] ?? 0.0).toDouble(),
      role: data['role'] ?? 'user',
      joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
    );
  }

  Stream<int> getTotalParticipantsCount() {
    return _usersCollection.snapshots().map((snapshot) => snapshot.docs.length);
  }

  Stream<int> getCompletedProfilesCount() {
    return _usersCollection
        .where('isComplete', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  Stream<List<Participant>> getParticipants() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Participant(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          mobile: data['mobile'] ?? '',
          profileImage: data['profileImage'],
          profileCompletion: (data['profileCompletion'] ?? 0.0).toDouble(),
          role: data['role'] ?? 'user',
          joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }

  Future<String> uploadProfileImage(String userId, XFile imageFile) async {
    final ref = _storage.ref().child('profile_images').child('$userId.jpg');
    final data = await imageFile.readAsBytes();
    await ref.putData(data, SettableMetadata(contentType: 'image/jpeg'));
    return await ref.getDownloadURL();
  }

  // Chat Methods
  String _getChatId(String userId1, String userId2) {
    // Sort IDs to ensure consistency
    final ids = [userId1, userId2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<ChatMessage>> getMessages(String currentUserId, String otherUserId) {
    final chatId = _getChatId(currentUserId, otherUserId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          text: data['text'] ?? '',
          isMe: data['senderId'] == currentUserId,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
      
      // Sort in-memory by timestamp descending
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    });
  }

  Future<void> sendMessage(String currentUserId, String otherUserId, String text) async {
    final chatId = _getChatId(currentUserId, otherUserId);
    await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .add({
      'text': text,
      'senderId': currentUserId,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- 1. Ticket Tracking & 2. Personal Agenda ---
  
  Future<void> registerEvent(String userId, String eventId) async {
    await _usersCollection.doc(userId).collection('registered_events').doc(eventId).set({
      'eventId': eventId,
      'registeredAt': FieldValue.serverTimestamp(),
      'hasCertificate': false,
    });

    // Also increment participant count for the event (optional but good for UI)
    await _firestore.collection('events').doc(eventId).update({
      'participantCount': FieldValue.increment(1),
    });
  }

  Stream<bool> isUserRegistered(String userId, String eventId) {
    return _usersCollection
        .doc(userId)
        .collection('registered_events')
        .doc(eventId)
        .snapshots()
        .map((doc) => doc.exists);
  }

  Stream<List<String>> getRegisteredEventIds(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('registered_events')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  Future<void> toggleStarSession(String userId, String sessionId) async {
    final docRef = _usersCollection.doc(userId).collection('starred_sessions').doc(sessionId);
    final doc = await docRef.get();
    
    if (doc.exists) {
      await docRef.delete();
    } else {
      await docRef.set({
        'sessionId': sessionId,
        'starredAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Stream<List<String>> getStarredSessionIds(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('starred_sessions')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // --- 4. Sponsor Interaction Tracking ---
  
  Future<void> trackSponsorInteraction(String userId, String sponsorId, String type) async {
    await _firestore.collection('sponsor_interactions').add({
      'userId': userId,
      'sponsorId': sponsorId,
      'type': type, // e.g., 'claim_offer', 'visit_booth'
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- 5. Session Feedback ---

  Future<void> submitSessionFeedback({
    required String userId,
    required String sessionId,
    required int rating,
    required String comment,
  }) async {
    await _firestore.collection('session_feedback').add({
      'userId': userId,
      'sessionId': sessionId,
      'rating': rating,
      'comment': comment,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // --- 7. Certificates ---

  Future<void> issueCertificate(String userId, String eventId) async {
    await _usersCollection
        .doc(userId)
        .collection('registered_events')
        .doc(eventId)
        .update({'hasCertificate': true});
  }
}
