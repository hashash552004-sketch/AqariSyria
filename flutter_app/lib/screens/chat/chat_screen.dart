import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../models/chat.dart';
import '../../core/snackbar_helper.dart';
import '../../widgets/animated_widgets.dart';

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

class _ChatScreenState extends State<ChatScreen>
    with TickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ImagePicker _picker = ImagePicker();
  bool _sending = false;
  Timer? _typingTimer;
  DateTime? _lastTypingWrite;
  int _messageLimit = 50;
  bool _loadingMore = false;
  double _preserveBottomOffset = -1;
  int _lastMsgCount = -1;
  late AnimationController _sendButtonController;
  late AnimationController _inputBarController;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _sendButtonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _inputBarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _messageController.addListener(() {
      final hasText = _messageController.text.trim().isNotEmpty;
      if (hasText) {
        _sendButtonController.forward();
      } else {
        _sendButtonController.reverse();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
  }

  void _markRead() {
    final uid = context.read<AuthService>().currentUser?.uid ?? '';
    if (uid.isNotEmpty) {
      context.read<FirestoreService>().markConversationRead(widget.conversationId, uid);
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
      if (uid.isNotEmpty) {
        FirestoreService().clearTyping(widget.conversationId, uid);
      }
    } catch (_) {}
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    _sendButtonController.dispose();
    _inputBarController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients || _loadingMore) return;
    if (_scrollController.position.pixels <= 60 && _messageLimit < 500) {
      _preserveBottomOffset =
          _scrollController.position.maxScrollExtent - _scrollController.position.pixels;
      setState(() {
        _loadingMore = true;
        _messageLimit += 50;
      });
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  void _onTyping() {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid ?? '';
    if (uid.isEmpty) return;
    final now = DateTime.now();
    if (_lastTypingWrite == null ||
        now.difference(_lastTypingWrite!).inMilliseconds > 2000) {
      _lastTypingWrite = now;
      context.read<FirestoreService>().setTyping(widget.conversationId, uid);
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 4), () {
      context.read<FirestoreService>().clearTyping(widget.conversationId, uid);
      _lastTypingWrite = null;
    });
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
      if (!mounted) return;
      await context.read<FirestoreService>().sendImageMessage(widget.conversationId, uid, name, url);
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'فشل إرسال الصورة', backgroundColor: AppColors.error);
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
      _focusNode.requestFocus();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'فشل إرسال الرسالة', backgroundColor: AppColors.error);
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
        appBar: _buildAppBar(),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<ChatMessage>>(
                stream: firestore.streamMessages(widget.conversationId, limit: _messageLimit),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  final messages = snapshot.data ?? [];
                  final hasIncomingUnread = messages.any(
                    (m) => m.senderId != currentUserId && !m.isRead,
                  );
                  if (hasIncomingUnread) {
                    WidgetsBinding.instance.addPostFrameCallback((_) => _markRead());
                  }
                  if (messages.isEmpty) {
                    _lastMsgCount = 0;
                    return _buildEmptyChat();
                  }

                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (!mounted || !_scrollController.hasClients) return;
                    if (_preserveBottomOffset >= 0) {
                      final newMax = _scrollController.position.maxScrollExtent;
                      _scrollController.jumpTo(
                        (newMax - _preserveBottomOffset).clamp(0.0, newMax),
                      );
                      _preserveBottomOffset = -1;
                      _loadingMore = false;
                    } else if (messages.length != _lastMsgCount) {
                      _lastMsgCount = messages.length;
                      _scrollToBottom();
                    }
                  });

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                    physics: const BouncingScrollPhysics(),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final msg = messages[index];
                      final isMe = msg.senderId == currentUserId;
                      final showDate = index == 0 ||
                          _isNewDay(messages[index - 1].timestamp, msg.timestamp);
                      final showTail = index == messages.length - 1 ||
                          messages[index + 1].senderId != msg.senderId;
                      return Column(
                        children: [
                          if (showDate) _buildDateSeparator(msg.timestamp),
                          _buildMessageBubble(msg, isMe, showTail, index),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _buildTypingIndicator(firestore, currentUserId),
            _buildInputBar(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: AppColors.cards,
      leadingWidth: 40,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.textPrimary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.propertyTitle ?? 'المحادثة',
            style: AppTextStyles.titleMedium.copyWith(fontSize: 15),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleIn(
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary.withValues(alpha: 0.1), AppColors.secondary.withValues(alpha: 0.1)],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_rounded,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.6),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeInSlide(
            delay: 300,
            child: Text(
              'ابدأ المحادثة',
              style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          FadeInSlide(
            delay: 450,
            child: Text(
              'أرسل أول رسالة الآن',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const SizedBox(height: 24),
          FadeInSlide(
            delay: 600,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _EmptyChatTip(icon: Icons.photo_rounded, label: 'صورة'),
                const SizedBox(width: 24),
                _EmptyChatTip(icon: Icons.text_fields_rounded, label: 'نص'),
                const SizedBox(width: 24),
                _EmptyChatTip(icon: Icons.emoji_emotions_rounded, label: 'إيموجي'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(FirestoreService firestore, String currentUserId) {
    return StreamBuilder<bool>(
      stream: firestore.streamTyping(widget.conversationId, currentUserId),
      builder: (context, snap) {
        if (snap.data != true) return const SizedBox.shrink();
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cards,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: const TypingDots(color: AppColors.primary),
              ),
              const SizedBox(width: 8),
              Text(
                'يكتب...',
                style: AppTextStyles.caption.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _isNewDay(DateTime a, DateTime b) {
    return a.day != b.day || a.month != b.month || a.year != b.year;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    String label;
    if (diff.inDays == 0) {
      label = 'اليوم';
    } else if (diff.inDays == 1) {
      label = 'أمس';
    } else {
      label = DateFormat('d MMMM y', 'ar').format(date);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.cards,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
          ),
          child: Text(
            label,
            style: AppTextStyles.caption.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg, bool isMe, bool isTail, int index) {
    final timeStr = DateFormat('HH:mm').format(msg.timestamp);

    if (msg.type == 'system') {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              msg.message,
              style: AppTextStyles.caption.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isMe && isTail) ...[
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primary.withValues(alpha: 0.7), AppColors.secondary.withValues(alpha: 0.7)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.person, size: 16, color: Colors.white),
                ),
                const SizedBox(width: 6),
              ],
              if (!isMe && !isTail) const SizedBox(width: 34),
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  padding: msg.type == 'image'
                      ? EdgeInsets.zero
                      : const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: isMe
                        ? LinearGradient(
                            colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.9)],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          )
                        : null,
                    color: isMe ? null : AppColors.cards,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(isMe ? 18 : (isTail ? 18 : 6)),
                      topRight: Radius.circular(isMe ? (isTail ? 18 : 6) : 18),
                      bottomLeft: Radius.circular(isMe ? 4 : 18),
                      bottomRight: Radius.circular(isMe ? 18 : 4),
                    ),
                    border: isMe ? null : Border.all(
                      color: AppColors.border.withValues(alpha: 0.5),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isMe ? AppColors.primary : Colors.black).withValues(alpha: isMe ? 0.15 : 0.04),
                        blurRadius: isMe ? 8 : 4,
                        offset: Offset(0, isMe ? 3 : 2),
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
                            width: 240,
                            placeholder: (_, __) => Container(
                              height: 180,
                              width: 240,
                              color: AppColors.shimmerBase,
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              height: 180,
                              width: 240,
                              color: AppColors.shimmerBase,
                              child: Icon(Icons.broken_image, color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                      if (msg.type == 'text')
                        Text(
                          msg.message,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: isMe ? Colors.white : AppColors.textPrimary,
                            fontSize: 14,
                          ),
                        ),
                      if (msg.type == 'image')
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
                          child: Text(
                            msg.message,
                            style: AppTextStyles.caption.copyWith(
                              color: isMe ? Colors.white70 : AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ),
                      const SizedBox(height: 2),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            timeStr,
                            style: AppTextStyles.caption.copyWith(
                              color: isMe
                                  ? Colors.white.withValues(alpha: 0.6)
                                  : AppColors.textSecondary,
                              fontSize: 9,
                            ),
                          ),
                          if (isMe) ...[
                            const SizedBox(width: 4),
                            AnimatedSwitcher(
                              duration: const Duration(milliseconds: 300),
                              child: Icon(
                                msg.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                                key: ValueKey(msg.isRead),
                                size: 14,
                                color: msg.isRead
                                    ? const Color(0xFF4FC3F7)
                                    : Colors.white.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              if (isMe && !isTail) const SizedBox(width: 0),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _inputBarController, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _inputBarController, curve: Curves.easeOutCubic)),
        child: Container(
          padding: EdgeInsets.only(
            left: 10,
            right: 10,
            top: 10,
            bottom: MediaQuery.of(context).padding.bottom + 10,
          ),
          decoration: BoxDecoration(
            color: AppColors.cards,
            border: Border(
              top: BorderSide(color: AppColors.border.withValues(alpha: 0.3)),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.add_photo_alternate_rounded, color: AppColors.primary, size: 22),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TextField(
                    controller: _messageController,
                    focusNode: _focusNode,
                    onChanged: (_) => _onTyping(),
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 14,
                    ),
                    decoration: InputDecoration(
                      hintText: 'اكتب رسالتك...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                      ),
                      filled: true,
                      fillColor: Colors.transparent,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(18),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    maxLines: 4,
                    minLines: 1,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ScaleTransition(
                scale: CurvedAnimation(
                  parent: _sendButtonController,
                  curve: Curves.elasticOut,
                ),
                child: GestureDetector(
                  onTap: _sending ? null : _sendMessage,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: _messageController.text.trim().isNotEmpty
                          ? const LinearGradient(
                              colors: [AppColors.primary, AppColors.secondary],
                            )
                          : null,
                      color: _messageController.text.trim().isNotEmpty ? null : AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _messageController.text.trim().isNotEmpty
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: _sending
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Icon(
                              Icons.send_rounded,
                              color: _messageController.text.trim().isNotEmpty
                                  ? Colors.white
                                  : AppColors.primary,
                              size: 20,
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyChatTip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _EmptyChatTip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(height: 6),
        Text(label, style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w500)),
      ],
    );
  }
}
