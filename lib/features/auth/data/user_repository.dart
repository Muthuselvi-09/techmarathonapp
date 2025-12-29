import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../events/domain/event_models.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<void> syncUser(String uid, {
    String? name,
    String? email,
    String? photoUrl,
    bool? isOnline,
  }) async {
    final Map<String, dynamic> data = {
      'uid': uid,
      'lastActive': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (photoUrl != null) data['profileImage'] = photoUrl;
    if (isOnline != null) {
      data['isOnline'] = isOnline;
      data['lastSeen'] = FieldValue.serverTimestamp();
    }

    await _usersCollection.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> updateOnlineStatus(String uid, bool isOnline) async {
    await _usersCollection.doc(uid).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
    });
  }

  Stream<List<Participant>> getRealTimeMembers() {
    return _usersCollection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return Participant(
          id: doc.id,
          name: data['name'] ?? 'User',
          email: data['email'] ?? '',
          mobile: data['mobile'] ?? '',
          profileImage: data['profileImage'],
          profileCompletion: (data['profileCompletion'] ?? 0.0).toDouble(),
        );
      }).toList();
    });
  }
}
