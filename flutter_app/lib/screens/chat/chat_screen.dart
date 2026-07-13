import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/chat.dart';
import '../../core/snackbar_helper.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String? propertyTitle;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.propertyTitle,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();
  bool _sending = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels <= 40) {
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTyping() {
    _typingTimer?.cancel();
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid ?? '';
    context.read<FirestoreService>().setTyping(widget.conversationId, uid);
    _typingTimer = Timer(const Duration(seconds: 2), () {});
  }

  Future<void> _pickImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    setState(() => _sending = true);
    try {
      final auth = context.read<AuthService>();
      final uid = auth.currentUser?.uid ?? '';
      final name = auth.currentUser?.displayName ?? 'مستخدم';
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child(widget.conversationId)
          .child('${DateTime.now().millisecondsSinceEpoch}.jpg');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();
      await context.read<FirestoreService>().sendImageMessage(widget.conversationId, uid, name, url);
    } catch (e) {
      if (mounted) showSnackBar(context, 'فشل إرسال الصورة', backgroundColor: AppColors.error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final auth = context.read<AuthService>();
      final firestore = context.read<FirestoreService>();
      final senderId = auth.currentUser?.uid ?? '';
      final senderName = auth.currentUser?.displayName ?? auth.currentUser?.email ?? 'مستخدم';
      await firestore.sendMessage(widget.conversationId, senderId, senderName, text);
      _messageController.clear();
      _scrollToBottom();
    } catch (e) {
      if (mounted) showSnackBar(context, 'فشل إرسال الرسالة', backgroundColor: AppColors.error);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final currentUserId = auth.currentUser?.uid ?? '';
    final firestore = context.read<FirestoreService>();

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (currentUserId.isNotEmpty) firestore.updateLastSeen(currentUserId);
        if (!didPop) Navigator.of(context).pop();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(widget.propertyTitle ?? 'المحادثة'),
          centerTitle: true,
          backgroundColor: AppColors.cards,
          elevation: 0.5,
          titleTextStyle: AppTextStyles.titleMedium,
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: firestore.streamMessages(widget.conversationId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final messages = snapshot.data ?? [];
                  if (messages.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.08),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(Icons.chat_bubble_outline, size: 40, color: AppColors.primary),
                          ),
                          const SizedBox(height: 16),
                          Text('ابدأ المحادثة', style: AppTextStyles.titleLarge),
                          const SizedBox(height: 6),
                          Text('أرسل أول رسالة الآن', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    );
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUserId;
                      final showDate = index == 0 || _isNewDay(messages[index - 1].timestamp, msg.timestamp);
                      return Column(
                        children: [
                          if (showDate) _buildDateSeparator(msg.timestamp),
                          _buildMessageBubble(msg, isMe, index == messages.length - 1),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            StreamBuilder<bool>(
              stream: firestore.streamTyping(widget.conversationId, currentUserId),
              builder: (context, snap) {
                if (snap.data != true) return const SizedBox.shrink();
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                      ),
                      const SizedBox(width: 8),
                      Text('يكتب...', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                    ],
                  ),
                );
              },
            ),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  bool _isNewDay(DateTime a, DateTime b) {
    return a.day != b.day || a.month != b.month || a.year != b.year;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    String label;
    if (diff.inDays == 0) label = 'اليوم';
    else if (diff.inDays == 1) label = 'أمس';
    else label = DateFormat('d MMMM y', 'ar').format(date);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.cards,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, bool isLast) {
    final timeStr = DateFormat('HH:mm').format(msg.timestamp);

    if (msg.type == 'system') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.textSecondary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(msg.message, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              if (!isMe) const SizedBox(width: 8),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
                  padding: msg.type == 'image' ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.cards,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    border: isMe ? null : Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (msg.type == 'image' && msg.imageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: CachedNetworkImage(
                            imageUrl: msg.imageUrl!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              height: 180, color: AppColors.shimmerBase,
                              child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              height: 180, color: AppColors.shimmerBase,
                              child: const Icon(Icons.broken_image, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      if (msg.type == 'text')
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text(
                            msg.message,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: isMe ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                      if (msg.type == 'image')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
                          child: Text(msg.message, style: AppTextStyles.caption.copyWith(
                            color: isMe ? Colors.white70 : AppColors.textSecondary, fontSize: 10,
                          )),
                        ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(timeStr, style: AppTextStyles.caption.copyWith(
                            color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                            fontSize: 9,
                          )),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            Icon(
                              msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                              size: 12,
                              color: msg.isRead
                                  ? const Color(0xFF4FC3F7)
                                  : Colors.white.withValues(alpha: 0.7),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe) const SizedBox(width: 8),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(left: 8, right: 8, top: 8, bottom: MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(
        color: AppColors.cards,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.image_outlined, color: AppColors.primary, size: 22),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: (_) => _onTyping(),
              decoration: InputDecoration(
                hintText: 'اكتب رسالتك...',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              maxLines: 4,
              minLines: 1,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _sendMessage,
            child: Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
