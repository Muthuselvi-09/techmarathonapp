import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:tech_marathon_app/features/chat/data/chat_repository.dart';
import 'package:tech_marathon_app/features/auth/presentation/providers/auth_provider.dart';
import 'package:tech_marathon_app/features/profile/presentation/providers/profile_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tech_marathon_app/core/theme/app_colors.dart';

class AdminChatPage extends ConsumerStatefulWidget {
  final String userId;
  const AdminChatPage({super.key, required this.userId});

  @override
  ConsumerState<AdminChatPage> createState() => _AdminChatPageState();
}

class _AdminChatPageState extends ConsumerState<AdminChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(profileProvider).user; // Direct access, no valueOrNull
    final authUser = ref.read(authStateProvider).valueOrNull;

    final name = user?.name ?? authUser?.displayName ?? 'User';
    final email = user?.email ?? authUser?.email ?? '';

    ref.read(adminChatRepositoryProvider).sendMessageToAdmin(
      widget.userId,
      text,
      userName: name,
      email: email,
    );
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(gradient: AppColors.backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Text(
            'SYSTEM SUPPORT',
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w900,
              letterSpacing: 2,
              fontSize: 14,
              color: Colors.white,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: ref.watch(adminChatRepositoryProvider).watchMessages(widget.userId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.chat_bubble_outline_rounded, size: 64, color: AppColors.primary.withOpacity(0.2)),
                          const SizedBox(height: 16),
                          Text(
                            'Need help? Start a conversation with us!',
                            style: GoogleFonts.inter(color: Colors.white38),
                          ),
                        ],
                      ).animate().fadeIn(),
                    );
                  }

                  final messages = snapshot.data!;
                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(24),
                    reverse: true,
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final bool isMe = msg['senderRole'] == 'user';
                      return _chatBubble(msg['message'], isMe);
                    },
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.05))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _messageController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Ask us anything...',
                  hintStyle: TextStyle(color: Colors.white38),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.black, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatBubble(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20).copyWith(
            bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
            bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isMe ? Colors.black : Colors.white,
            fontSize: 14,
          ),
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}
