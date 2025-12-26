import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../events/domain/event_models.dart';

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

  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<void> saveProfile(Participant user) async {
    await _usersCollection.doc(user.id).set({
      'name': user.name,
      'email': user.email,
      'mobile': user.mobile,
      'profileImage': user.profileImage,
      'profileCompletion': user.profileCompletion,
      'isComplete': user.profileCompletion >= 1.0,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          text: data['text'] ?? '',
          isMe: data['senderId'] == currentUserId,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
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
}
