import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/animated_widgets.dart';
import '../../models/chat.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  List<Map<String, dynamic>> _searchResults = [];
  bool _searching = false;
  Timer? _debounce;
  bool _showSearch = false;
  late AnimationController _headerController;
  late AnimationController _listController;
  bool _isStaff = false;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _listController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
    _loadRole();
  }

  Future<void> _loadRole() async {
    final auth = context.read<AuthService>();
    final fs = context.read<FirestoreService>();
    final uid = auth.currentUser?.uid;
    if (uid == null) return;
    final user = await fs.getUser(uid);
    if (mounted) {
      setState(() {
        _isStaff = user?.permissions['respond_customers'] == true;
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    _headerController.dispose();
    _listController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.trim().isEmpty) {
        setState(() => _searchResults = []);
        return;
      }
      _searchUsers(query.trim());
    });
  }

  Future<void> _searchUsers(String query) async {
    setState(() => _searching = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isGreaterThanOrEqualTo: query)
          .where('username', isLessThanOrEqualTo: '$query\uf8ff')
          .limit(20)
          .get();
      if (mounted) {
        setState(() {
          _searchResults = snapshot.docs
              .map((doc) => {'uid': doc.id, ...doc.data()})
              .toList();
          _searching = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _searching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final userId = auth.currentUser?.uid;
    final firestore = context.read<FirestoreService>();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildAnimatedHeader(),
          _buildSearchBar(),
          Expanded(
            child: _showSearch
                ? _buildSearchResults(userId)
                : userId == null
                    ? _buildNotLoggedIn()
                    : _buildConversationsList(firestore, userId),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedHeader() {
    return FadeTransition(
      opacity: CurvedAnimation(parent: _headerController, curve: Curves.easeOut),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, -0.3),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: _headerController, curve: Curves.easeOutCubic)),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary, AppColors.secondary, AppColors.accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(32),
              bottomRight: Radius.circular(32),
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'الرسائل',
                            style: AppTextStyles.headlineMedium.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'تحدث مع أصحاب العقارات',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: Colors.white.withValues(alpha: 0.8),
                            ),
                          ),
                        ],
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _showSearch = !_showSearch;
                            if (_showSearch) {
                              _searchFocus.requestFocus();
                            } else {
                              _searchController.clear();
                              _searchResults = [];
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _showSearch
                                ? Colors.white.withValues(alpha: 0.3)
                                : Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: Icon(
                            _showSearch ? Icons.close_rounded : Icons.search_rounded,
                            color: Colors.white,
                            size: 22,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: _showSearch
          ? FadeInSlide(
              delay: 0,
              offset: const Offset(0, -15),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.cards,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    focusNode: _searchFocus,
                    style: AppTextStyles.bodyMedium.copyWith(fontSize: 15),
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'أدخل اسم المستخدم...',
                      hintStyle: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                      ),
                      prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded, color: AppColors.textSecondary, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchResults = []);
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildNotLoggedIn() {
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
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.secondary.withValues(alpha: 0.1),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_rounded,
                size: 48,
                color: AppColors.primary.withValues(alpha: 0.5),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeInSlide(
            delay: 300,
            child: Text(
              'سجل دخول لعرض المحادثات',
              style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 8),
          FadeInSlide(
            delay: 400,
            child: Text(
              'بإمكانك التواصل مع أصحاب العقارات',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationsList(FirestoreService firestore, String userId) {
    return StreamBuilder<List<Conversation>>(
      stream: firestore.streamConversations(userId, isStaff: _isStaff),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoading();
        }
        final conversations = snapshot.data ?? [];
        if (conversations.isEmpty) {
          return _buildEmptyState();
        }
        return ListView.builder(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          itemCount: conversations.length,
          itemBuilder: (context, index) {
            final conv = conversations[index];
            String otherName;
            if (conv.isSupport) {
              otherName = 'خدمة العملاء';
            } else {
              final isOwner = conv.ownerId == userId;
              otherName = isOwner ? conv.interestedUserName : conv.ownerName;
            }
            return FadeTransition(
              opacity: CurvedAnimation(
                parent: _listController,
                curve: Interval(
                  (index * 0.08).clamp(0.0, 0.8),
                  ((index * 0.08) + 0.3).clamp(0.1, 1.0),
                  curve: Curves.easeOut,
                ),
              ),
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.4, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: _listController,
                  curve: Interval(
                    (index * 0.08).clamp(0.0, 0.8),
                    ((index * 0.08) + 0.3).clamp(0.1, 1.0),
                    curve: Curves.easeOutCubic,
                  ),
                )),
                child: _buildConversationCard(conv, otherName, index),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoading() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: FadeInSlide(
            delay: index * 80,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const SkeletonCard(width: 52, height: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SkeletonText(width: 160, height: 14),
                        const SizedBox(height: 8),
                        const SkeletonText(width: 120, height: 10),
                        const SizedBox(height: 8),
                        const SkeletonText(width: 200, height: 10),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleIn(
            duration: const Duration(milliseconds: 800),
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.secondary.withValues(alpha: 0.08),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chat_bubble_outline_rounded,
                size: 52,
                color: AppColors.primary.withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FadeInSlide(
            delay: 300,
            child: Text(
              'لا توجد محادثات',
              style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 8),
          FadeInSlide(
            delay: 400,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'ابحث عن مستخدمين لبدء محادثة جديدة',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(height: 28),
          FadeInSlide(
            delay: 550,
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _showSearch = true;
                });
                Future.delayed(const Duration(milliseconds: 300), () {
                  _searchFocus.requestFocus();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'ابحث عن مستخدم',
                      style: AppTextStyles.labelLarge.copyWith(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationCard(Conversation conv, String otherName, int index) {
    final timeStr = _formatTime(conv.lastMessageTime);
    final hasUnread = conv.unreadCount > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ChatScreen(
                conversationId: conv.id,
                propertyTitle: conv.propertyTitle,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: hasUnread
                ? AppColors.primary.withValues(alpha: 0.04)
                : AppColors.cards,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: hasUnread
                  ? AppColors.primary.withValues(alpha: 0.2)
                  : AppColors.border.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: conv.isSupport
                        ? [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)]
                        : [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: conv.isSupport
                      ? const Icon(Icons.support_agent_rounded, color: Colors.white, size: 22)
                      : Text(
                          otherName.isNotEmpty ? otherName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      otherName,
                      style: AppTextStyles.titleSmall.copyWith(
                        fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 15,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      conv.lastMessage.isNotEmpty
                          ? conv.lastMessage
                          : 'ابدأ المحادثة',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: hasUnread
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                        fontWeight: hasUnread ? FontWeight.w500 : FontWeight.w400,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    timeStr,
                    style: AppTextStyles.caption.copyWith(
                      color: hasUnread ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w400,
                      fontSize: 11,
                    ),
                  ),
                  if (hasUnread) ...[
                    const SizedBox(height: 6),
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, AppColors.secondary],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${conv.unreadCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchResults(String? currentUserId) {
    if (_searching) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_searchResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_search_rounded, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text('لا توجد نتائج', style: AppTextStyles.titleMedium.copyWith(color: AppColors.textSecondary)),
          ],
        ),
      );
    }
    return ListView.builder(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      itemCount: _searchResults.length,
      itemBuilder: (context, index) {
        final userData = _searchResults[index];
        final uid = userData['uid'] as String;
        final fullName = userData['fullName']?.toString() ?? '';
        final username = userData['username']?.toString() ?? '';
        final profileImage = userData['profileImage']?.toString();
        if (uid == currentUserId) return const SizedBox.shrink();
        return FadeInSlide(
          delay: index * 60,
          child: _buildUserCard(uid, fullName, username, profileImage),
        );
      },
    );
  }

  Widget _buildUserCard(String uid, String fullName, String username, String? profileImage) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () async {
          final auth = context.read<AuthService>();
          final currentUser = auth.currentUser;
          if (currentUser == null) return;
          final firestore = context.read<FirestoreService>();
          final convId = 'direct_${uid}_${currentUser.uid}';
          final existingConv = await FirebaseFirestore.instance.collection('conversations').doc(convId).get();
          if (!existingConv.exists) {
            await firestore.createDirectConversation(
              convId, uid, fullName, currentUser.uid,
              currentUser.displayName ?? currentUser.email ?? 'مستخدم',
            );
          }
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatScreen(
                  conversationId: convId,
                  propertyTitle: 'محادثة مع $fullName',
                ),
              ),
            );
          }
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cards,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border.withValues(alpha: 0.4)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '@$username',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  ],
                ),
              ),
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.chat_bubble_outline_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inHours < 1) return '${diff.inMinutes} د';
    if (diff.inDays < 1) return DateFormat('HH:mm').format(dt);
    if (diff.inDays < 7) return DateFormat('E', 'ar').format(dt);
    return DateFormat('dd/MM').format(dt);
  }
}
