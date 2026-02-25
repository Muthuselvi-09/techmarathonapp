import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance);
});

final personalEventsStreamProvider = StreamProvider.family<List<PersonalEvent>, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).watchPersonalEvents(userId);
});

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

  CollectionReference get _usersCollection => _firestore.collection('users');

  Future<void> syncUser(String uid, {
    String? name,
    String? email,
    String? photoUrl,
    String? fcmToken,
    Map<String, dynamic>? location,
    bool? isOnline,
    String? role,
    String? mobile,
  }) async {
    final Map<String, dynamic> data = {
      'uid': uid,
      'lastActive': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (name != null) data['name'] = name;
    if (email != null) data['email'] = email;
    if (photoUrl != null) data['profileImage'] = photoUrl;
    if (fcmToken != null) data['fcmToken'] = fcmToken;
    if (location != null) data['location'] = location;
    if (isOnline != null) {
      data['isOnline'] = isOnline;
      data['lastSeen'] = FieldValue.serverTimestamp();
    }
    if (role != null) data['role'] = role;
    if (mobile != null) data['mobile'] = mobile;

    await _usersCollection.doc(uid).set(data, SetOptions(merge: true));
  }

  Future<void> updateLocation(String uid, Map<String, dynamic> location) async {
    await _usersCollection.doc(uid).update({
      'location': location,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateFcmToken(String uid, String token) async {
    await _usersCollection.doc(uid).update({
      'fcmToken': token,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
          role: data['role'] ?? 'user',
          joinedAt: (data['joinedAt'] as Timestamp?)?.toDate(),
          isOnline: data['isOnline'] ?? false,
          lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
        );
      }).toList();
    });
  }

  Stream<int> watchOnlineUsersCount() {
    return _usersCollection.where('isOnline', isEqualTo: true).snapshots().map((snapshot) => snapshot.docs.length);
  }

  Future<String> fetchUserRole(String uid) async {
    final doc = await _usersCollection.doc(uid).get();
    if (doc.exists) {
      final data = doc.data() as Map<String, dynamic>;
      return data['role'] ?? 'user';
    }
    return 'user';
  }

  Future<void> addMember(Participant member) async {
    final docRef = member.id.isEmpty ? _usersCollection.doc() : _usersCollection.doc(member.id);
    await docRef.set(member.toFirestore());
  }

  Future<void> updateMember(Participant member) async {
    await _usersCollection.doc(member.id).update(member.toFirestore());
  }

  Future<void> deleteMember(String id) async {
    await _usersCollection.doc(id).delete();
  }

  // Personal Events
  Future<void> savePersonalEvent(PersonalEvent event) async {
    final docRef = event.id.isEmpty 
        ? _usersCollection.doc(event.userId).collection('personalEvents').doc()
        : _usersCollection.doc(event.userId).collection('personalEvents').doc(event.id);
    
    final eventWithId = PersonalEvent(
      id: docRef.id,
      userId: event.userId,
      title: event.title,
      isAllDay: event.isAllDay,
      startDate: event.startDate,
      endDate: event.endDate,
      location: event.location,
      email: event.email,
      reminder: event.reminder,
      repeat: event.repeat,
      notes: event.notes,
      createdAt: event.createdAt,
    );

    await docRef.set(eventWithId.toFirestore());
  }

  Stream<List<PersonalEvent>> watchPersonalEvents(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('personalEvents')
        .orderBy('startDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => PersonalEvent.fromFirestore(doc.data())).toList();
    });
  }
}
