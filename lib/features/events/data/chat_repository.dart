import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tech_marathon_app/features/events/domain/event_models.dart';

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(FirebaseFirestore.instance);
});

class ChatRepository {
  final FirebaseFirestore _firestore;

  ChatRepository(this._firestore);

  String _getChatId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  Stream<List<ChatMessage>> getMessages(String currentUserId, String otherUserId) {
    final chatId = _getChatId(currentUserId, otherUserId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return ChatMessage(
          text: data['text'] ?? data['messageText'] ?? '',
          isMe: data['senderId'] == currentUserId,
          timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
        );
      }).toList();
    });
  }

  Future<void> sendMessage(String senderId, String receiverId, String text) async {
    final chatId = _getChatId(senderId, receiverId);
    
    final chatDoc = _firestore.collection('chats').doc(chatId);
    
    // Create/Update chat metadata
    await chatDoc.set({
      'members': [senderId, receiverId],
      'lastMessage': text,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // Add message to subcollection
    await chatDoc.collection('messages').add({
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
      'isRead': false,
    });
  }

  Future<void> markAsRead(String currentUserId, String otherUserId) async {
    final chatId = _getChatId(currentUserId, otherUserId);
    final messages = await _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .where('receiverId', isEqualTo: currentUserId)
        .where('isRead', isEqualTo: false)
        .get();

    final batch = _firestore.batch();
    for (var doc in messages.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }
}
