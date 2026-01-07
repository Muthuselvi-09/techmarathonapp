import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotificationRepository {
  final FirebaseFirestore _firestore;

  NotificationRepository(this._firestore);

  Future<void> sendBroadcast(String title, String message) async {
    await _firestore.collection('notifications').add({
      'title': title,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'type': 'broadcast',
    });
  }
}

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(FirebaseFirestore.instance);
});
