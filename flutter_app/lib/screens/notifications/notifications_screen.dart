import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../models/notification.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/empty_state_widget.dart';
import '../../models/property.dart';
import '../property/property_detail_screen.dart';
import '../chat/chat_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTab = 0;

  static const _tabs = ['الكل', 'الرسائل', 'معاينة', 'نظام'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _selectedTab = _tabController.index);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = context.read<AuthService>().currentUser?.uid ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'الإشعارات',
        showBack: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: TextButton(
              onPressed: () {
                context.read<FirestoreService>().markAllNotificationsRead(userId);
              },
              child: Text(
                'تحديد الكل كمقروء',
                style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(child: _buildNotifications()),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
        ),
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: AppTextStyles.labelMedium,
        unselectedLabelStyle: AppTextStyles.labelMedium,
        dividerHeight: 0,
        tabs: List.generate(_tabs.length, (i) {
          final icons = [Icons.all_inclusive, Icons.chat_bubble_outline, Icons.calendar_today, Icons.settings];
          return Tab(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icons[i], size: 16),
                const SizedBox(width: 6),
                Text(_tabs[i]),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNotifications() {
    final userId = context.read<AuthService>().currentUser?.uid ?? '';

    return StreamBuilder<QuerySnapshot>(
      stream: context.read<FirestoreService>().streamUserNotifications(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.notifications_none,
            title: 'لا توجد إشعارات',
            subtitle: 'ستظهر هنا الإشعارات الخاصة بعقاراتك ورسائلك',
          );
        }

        var docs = snapshot.data!.docs;
        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;
          final aTime = (aData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          final bTime = (bData['createdAt'] as Timestamp?)?.toDate() ?? DateTime(2000);
          return bTime.compareTo(aTime);
        });

        final typeFilter = _typeForTab(_selectedTab);
        var filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          if (typeFilter != null && data['type'] != typeFilter) return false;
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return EmptyStateWidget(
            icon: Icons.notifications_off_outlined,
            title: 'لا توجد إشعارات في هذا التصنيف',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          itemCount: filtered.length,
          itemBuilder: (context, index) {
            final doc = filtered[index];
            final data = doc.data() as Map<String, dynamic>;
            final notification = AppNotification.fromFirestore(data, doc.id);
            return _buildNotificationCard(notification, data);
          },
        );
      },
    );
  }

  String? _typeForTab(int tab) {
    switch (tab) {
      case 1: return 'message';
      case 2: return 'visit_request';
      case 3: return 'system';
      default: return null;
    }
  }

  Widget _buildNotificationCard(AppNotification notification, Map<String, dynamic> rawData) {
    final isRead = notification.isRead;
    final icon = _iconForType(notification.type);
    final iconColor = _colorForType(notification.type);
    final timeStr = _timeAgo(notification.createdAt);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white, size: 28),
      ),
      onDismissed: (_) {
        context.read<FirestoreService>().deleteNotification(notification.id);
      },
      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            context.read<FirestoreService>().markNotificationRead(notification.id);
          }
          _navigateToNotification(notification);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isRead ? AppColors.cards : AppColors.primary.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            border: isRead ? null : Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.titleSmall.copyWith(
                              fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!isRead)
                          Container(
                            width: 10,
                            height: 10,
                            margin: const EdgeInsets.only(top: 4),
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: AppTextStyles.bodyMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(timeStr, style: AppTextStyles.caption),
                        const Spacer(),
                        _typeBadge(notification.type),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _typeBadge(String type) {
    final labels = {
      'message': 'رسالة',
      'property': 'عقار',
      'visit_request': 'معاينة',
      'system': 'نظام',
    };
    final colors = {
      'message': AppColors.success,
      'property': AppColors.primary,
      'visit_request': AppColors.warning,
      'system': AppColors.textSecondary,
    };
    final label = labels[type] ?? 'نظام';
    final color = colors[type] ?? AppColors.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }

  void _navigateToNotification(AppNotification notification) async {
    final targetId = notification.targetId;
    if (targetId == null || targetId.isEmpty) return;

    final nav = Navigator.of(context);
    switch (notification.type) {
      case 'message':
        nav.push(MaterialPageRoute(
          builder: (_) => ChatScreen(conversationId: targetId),
        ));
        break;
      case 'visit_request':
      case 'property':
        final firestore = context.read<FirestoreService>();
        final property = await firestore.getPropertyById(targetId);
        if (property != null && mounted) {
          nav.push(MaterialPageRoute(
            builder: (_) => PropertyDetailScreen(property: property),
          ));
        }
        break;
    }
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'message': return Icons.chat_bubble_outline;
      case 'property': return Icons.home_work_outlined;
      case 'visit_request': return Icons.calendar_today;
      default: return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'message': return AppColors.success;
      case 'property': return AppColors.primary;
      case 'visit_request': return AppColors.warning;
      default: return AppColors.textSecondary;
    }
  }

  String _timeAgo(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} يوم';
    if (diff.inDays < 30) return 'منذ ${(diff.inDays / 7).floor()} أسبوع';
    return 'منذ ${(diff.inDays / 30).floor()} شهر';
  }
}
