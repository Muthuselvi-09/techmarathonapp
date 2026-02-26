import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminChatRepositoryProvider = Provider((ref) => AdminChatRepository());

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessage(
      id: docId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      message: map['message'] ?? map['text'] ?? '',
      createdAt: (map['timestamp'] as Timestamp?)?.toDate() ?? 
                 (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}

class AdminChatRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<Map<String, dynamic>>> watchAllChats() {
    return _firestore
        .collection('chats')
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> watchMessages(String userId) {
    return _firestore
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> sendMessageToAdmin(String userId, String message, {String? userName, String? email}) async {
    final batch = _firestore.batch();
    
    final messageRef = _firestore.collection('chats').doc(userId).collection('messages').doc();
    batch.set(messageRef, {
      'senderId': userId,
      'receiverId': 'admin',
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'senderRole': 'user',
      'senderName': userName ?? 'User',
      'senderEmail': email ?? '',
    });

    final chatRef = _firestore.collection('chats').doc(userId);
    batch.set(chatRef, {
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
      'userId': userId,
      'userName': userName ?? 'User', // Now using real name
      'userEmail': email ?? '',
      'unreadByAdmin': true, // Notification trigger
    }, SetOptions(merge: true));

    // Optional: Add to notifications collection for Admin
    final notifRef = _firestore.collection('admin_notifications').doc();
    batch.set(notifRef, {
      'type': 'message',
      'title': 'New Message from ${userName ?? 'User'}',
      'body': message,
      'timestamp': FieldValue.serverTimestamp(),
      'read': false,
      'relatedId': userId,
    });

    await batch.commit();
  }

  Future<void> replyToUser(String userId, String message) async {
    final batch = _firestore.batch();

    final messageRef = _firestore.collection('chats').doc(userId).collection('messages').doc();
    batch.set(messageRef, {
      'senderId': 'admin',
      'receiverId': userId,
      'message': message,
      'timestamp': FieldValue.serverTimestamp(),
      'senderRole': 'admin',
    });

    final chatRef = _firestore.collection('chats').doc(userId);
    batch.set(chatRef, {
      'lastMessage': message,
      'lastMessageTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await batch.commit();
  }

  Future<void> editMessage(String userId, String messageId, String newText) async {
    await _firestore
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .doc(messageId)
        .update({
      'message': newText,
      'isEdited': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteMessage(String userId, String messageId) async {
    // We mask the message instead of full deletion to preserve thread structure if needed
    // or just delete it if "Delete for Everyone" is intended
    await _firestore
        .collection('chats')
        .doc(userId)
        .collection('messages')
        .doc(messageId)
        .update({
      'message': '🚫 This message was deleted',
      'isDeleted': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}
