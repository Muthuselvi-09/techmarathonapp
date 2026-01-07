import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import 'package:tech_marathon_app/features/home/domain/event_models.dart';
import '../../../profile/presentation/providers/profile_provider.dart';
import '../../../profile/data/profile_repository.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final Participant otherUser;
  const ChatScreen({super.key, required this.otherUser});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    
    final currentUser = ref.read(profileProvider).user;
    if (currentUser == null) return;

    ref.read(profileRepositoryProvider).sendMessage(
      currentUser.id,
      widget.otherUser.id,
      _messageController.text.trim(),
    );
    
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          children: [
            const CircleAvatar(
              radius: 16,
              backgroundImage: NetworkImage('https://images.unsplash.com/photo-1539571696357-5a69c17a67c6'),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.otherUser.name,
                  style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'Online',
                  style: TextStyle(fontSize: 10, color: AppColors.accent),
                ),
              ],
            ),
          ],
        ),
      ),
       body: Column(
        children: [
          Expanded(
            child: Consumer(
              builder: (context, ref, child) {
                final messagesAsync = ref.watch(chatMessagesProvider(widget.otherUser.id));
                
                return messagesAsync.when(
                  data: (messages) => ListView.builder(
                    padding: const EdgeInsets.all(20),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final m = messages[index]; // Already reversed from query but ListView reverse=true needs careful handling. 
                      // Wait, query is descending (newest first). reverse=true means index 0 is at bottom.
                      // If query returns [newest, older, oldest], listview reverse puts newest at bottom. CORRECT.
                      return _buildMessageBubble(m);
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Center(child: Text('Error loading messages', style: TextStyle(color: Colors.white))),
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage m) {
    return Align(
      alignment: m.isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: m.isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(m.isMe ? 16 : 0),
            bottomRight: Radius.circular(m.isMe ? 0 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: m.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              m.text,
              style: TextStyle(
                color: m.isMe ? Colors.black : Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${m.timestamp.hour}:${m.timestamp.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                fontSize: 8,
                color: m.isMe ? Colors.black54 : AppColors.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: TextStyle(color: AppColors.textDim),
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                gradient: AppColors.mainGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
