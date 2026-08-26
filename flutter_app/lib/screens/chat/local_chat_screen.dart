import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart' as intl;
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/local_chat_service.dart';
import '../../services/auth_service.dart';

class LocalChatScreen extends StatefulWidget {
  final String conversationId;
  final String propertyTitle;
  final String otherUserName;

  const LocalChatScreen({
    super.key,
    required this.conversationId,
    required this.propertyTitle,
    required this.otherUserName,
  });

  @override
  State<LocalChatScreen> createState() => _LocalChatScreenState();
}

class _LocalChatScreenState extends State<LocalChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final LocalChatService _chatService = LocalChatService();
  List<Map<String, dynamic>> _messages = [];
  bool _sending = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) => _loadMessages());
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    final msgs = await _chatService.getMessages(widget.conversationId);
    if (!mounted) return;
    setState(() => _messages = msgs);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final user = context.read<AuthService>().currentUser;
      final uid = user?.uid ?? '';
      final name = user?.displayName ?? user?.email ?? 'مستخدم';
      await _chatService.sendMessage(
        conversationId: widget.conversationId,
        senderId: uid,
        senderName: name,
        message: text,
      );
      _controller.clear();
      _focusNode.requestFocus();
      await _loadMessages();
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = context.read<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cards,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(widget.propertyTitle, style: AppTextStyles.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(widget.otherUserName, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final msg = _messages[index];
                      final isMe = msg['senderId'] == currentUid;
                      final showTime = index == 0 ||
                          _messages[index - 1]['senderId'] != msg['senderId'];
                      return _buildBubble(msg, isMe, showTime);
                    },
                  ),
          ),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline_rounded, size: 56, color: AppColors.textSecondary.withValues(alpha: 0.4)),
          const SizedBox(height: 12),
          Text('ابدأ المحادثة', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          Text('أرسل رسالة لـ ${widget.otherUserName}', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg, bool isMe, bool showSender) {
    final time = DateTime.tryParse(msg['timestamp'] ?? '') ?? DateTime.now();
    final timeStr = intl.DateFormat('HH:mm', 'ar').format(time);

    return Align(
      alignment: isMe ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.78),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            if (showSender && !isMe)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(msg['senderName'] ?? '', style: AppTextStyles.caption.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe ? AppColors.primary : AppColors.cards,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 4 : 18),
                  bottomRight: Radius.circular(isMe ? 18 : 4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    msg['message'] ?? '',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: isMe ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeStr,
                        style: AppTextStyles.caption.copyWith(
                          color: isMe ? Colors.white.withValues(alpha: 0.7) : AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all_rounded,
                          size: 14,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: AppColors.cards,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                maxLines: 4,
                minLines: 1,
                style: AppTextStyles.bodyMedium,
                decoration: InputDecoration(
                  hintText: 'اكتب رسالة...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                ),
                onSubmitted: (_) => _send(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sending ? null : _send,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _controller.text.trim().isEmpty
                    ? null
                    : const LinearGradient(colors: [AppColors.primary, AppColors.secondary]),
                color: _controller.text.trim().isEmpty ? AppColors.textSecondary.withValues(alpha: 0.2) : null,
                shape: BoxShape.circle,
              ),
              child: _sending
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(
                      Icons.send_rounded,
                      color: _controller.text.trim().isEmpty ? AppColors.textSecondary : Colors.white,
                      size: 20,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
