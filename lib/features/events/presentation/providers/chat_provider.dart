import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import 'package:tech_marathon_app/features/events/data/chat_repository.dart';
import 'package:tech_marathon_app/features/auth/data/auth_repository.dart';

final activeMessagesProvider = StreamProvider.family<List<ChatMessage>, String>((ref, otherUserId) {
  final authRepository = ref.watch(authRepositoryProvider);
  final currentUserId = authRepository.currentUser?.uid;
  
  if (currentUserId == null) return const Stream.empty();
  
  return ref.watch(chatRepositoryProvider).getMessages(currentUserId, otherUserId);
});

final chatControllerProvider = Provider<ChatController>((ref) {
  return ChatController(ref.watch(chatRepositoryProvider), ref);
});

class ChatController {
  final ChatRepository _repository;
  final Ref _ref;

  ChatController(this._repository, this._ref);

  Future<void> sendMessage(String otherUserId, String text) async {
    final senderId = _ref.read(authRepositoryProvider).currentUser?.uid;
    if (senderId == null) return;
    
    await _repository.sendMessage(senderId, otherUserId, text);
  }

  Future<void> markAsRead(String otherUserId) async {
    final currentUserId = _ref.read(authRepositoryProvider).currentUser?.uid;
    if (currentUserId == null) return;
    
    await _repository.markAsRead(currentUserId, otherUserId);
  }
}
