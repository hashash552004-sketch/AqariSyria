import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/auth_service.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_app_bar.dart';

/// Comprehensive personal statistics built on REAL Firestore data.
class MyStatsScreen extends StatelessWidget {
  const MyStatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final uid = auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'الإحصائيات'),
      body: uid == null
          ? Center(
              child: Text('يرجى تسجيل الدخول', style: AppTextStyles.titleMedium),
            )
          : SingleChildScrollView(
              padding: AppConstants.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ---------- Properties ----------
                  StreamBuilder<List<Property>>(
                    stream: firestore.streamPropertiesByOwner(uid),
                    builder: (context, snap) {
                      final props = snap.data ?? const <Property>[];
                      final totalViews =
                          props.fold<int>(0, (s, p) => s + p.viewsCount);
                      final featured =
                          props.where((p) => p.isFeatured).length;
                      final sold = props.where((p) => p.isSold).length;
                      final totalReviews =
                          props.fold<int>(0, (s, p) => s + p.reviewsCount);
                      double avgRating = 0;
                      final rated =
                          props.where((p) => p.reviewsCount > 0).toList();
                      if (rated.isNotEmpty) {
                        avgRating = rated
                                .fold<double>(
                                    0, (s, p) => s + p.rating * p.reviewsCount) /
                            props
                                .fold<int>(
                                    0, (s, p) => s + p.reviewsCount)
                                .clamp(1, 1 << 31);
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _sectionTitle('عقاراتي', Icons.home_work_rounded),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.home_work_rounded,
                                  label: 'إجمالي العقارات',
                                  value: '${props.length}',
                                  color: AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.visibility_rounded,
                                  label: 'إجمالي المشاهدات',
                                  value: '$totalViews',
                                  color: AppColors.secondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.star_rounded,
                                  label: 'عقارات مميزة',
                                  value: '$featured',
                                  color: AppColors.warning,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.sell_rounded,
                                  label: 'تم بيعها',
                                  value: '$sold',
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: AppConstants.cardPadding,
                            decoration: BoxDecoration(
                              color: AppColors.cards,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.cardRadiusSmall),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star_rounded,
                                    color: AppColors.warning, size: 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        totalReviews > 0
                                            ? avgRating.toStringAsFixed(1)
                                            : '—',
                                        style: AppTextStyles.headlineMedium,
                                      ),
                                      Text(
                                        'متوسط التقييم من $totalReviews تقييم',
                                        style: AppTextStyles.caption,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (props.isNotEmpty) ...[
                            const SizedBox(height: 16),
                            _buildTopProperties(props),
                          ],
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ---------- Visit requests ----------
                  _sectionTitle('طلبات المعاينة', Icons.event_available_rounded),
                  const SizedBox(height: 12),
                  StreamBuilder<List<Map<String, dynamic>>>(
                    stream: firestore.streamVisitRequests(uid),
                    builder: (context, inSnap) {
                      return StreamBuilder<List<Map<String, dynamic>>>(
                        stream: firestore.streamMyVisitRequests(uid),
                        builder: (context, outSnap) {
                          final incoming = inSnap.data ?? const [];
                          final outgoing = outSnap.data ?? const [];
                          final pendIn = incoming
                              .where((r) => r['status'] == 'pending')
                              .length;
                          final accOut = outgoing
                              .where((r) => r['status'] == 'accepted')
                              .length;
                          final rejOut = outgoing
                              .where((r) =>
                                  r['status'] == 'rejected' ||
                                  r['status'] == 'cancelled')
                              .length;

                          return Container(
                            padding: AppConstants.cardPadding,
                            decoration: BoxDecoration(
                              color: AppColors.cards,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.cardRadius),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                _StatRow(
                                  label: 'طلبات واردة على عقاراتك',
                                  value: '${incoming.length}',
                                  color: AppColors.primary,
                                ),
                                const Divider(height: 18),
                                _StatRow(
                                  label: 'بانتظار ردك',
                                  value: '$pendIn',
                                  color: AppColors.warning,
                                ),
                                const Divider(height: 18),
                                _StatRow(
                                  label: 'طلبات أرسلتها',
                                  value: '${outgoing.length}',
                                  color: AppColors.secondary,
                                ),
                                const Divider(height: 18),
                                _StatRow(
                                  label: 'طلبات مقبولة لك',
                                  value: '$accOut',
                                  color: AppColors.success,
                                ),
                                const Divider(height: 18),
                                _StatRow(
                                  label: 'طلبات مرفوضة/ملغاة لك',
                                  value: '$rejOut',
                                  color: AppColors.error,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),

                  // ---------- Activity ----------
                  _sectionTitle('نشاطك', Icons.insights_rounded),
                  const SizedBox(height: 12),
                  StreamBuilder<ConversationCount>(
                    stream: _conversationCount(firestore, uid),
                    builder: (context, convSnap) {
                      return StreamBuilder<DocumentSnapshot>(
                        stream: firestore.streamUserDoc(uid),
                        builder: (context, userSnap) {
                          final convCount = convSnap.data?.count ?? 0;
                          final unread = convSnap.data?.unread ?? 0;
                          final userData = userSnap.data?.data()
                              as Map<String, dynamic>?;
                          final favCount =
                              (userData?['favorites'] as List?)?.length ?? 0;
                          final recent =
                              (userData?['recentlyViewed'] as List?)?.length ??
                                  0;

                          return Container(
                            padding: AppConstants.cardPadding,
                            decoration: BoxDecoration(
                              color: AppColors.cards,
                              borderRadius:
                                  BorderRadius.circular(AppConstants.cardRadius),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              children: [
                                _StatRow(
                                  label: 'محادثاتي',
                                  value: '$convCount',
                                  color: AppColors.primary,
                                ),
                                const Divider(height: 18),
                                _StatRow(
                                  label: 'رسائل غير مقروءة',
                                  value: '$unread',
                                  color: AppColors.error,
                                ),
                                const Divider(height: 18),
                                _StatRow(
                                  label: 'عقارات في مفضلتي',
                                  value: '$favCount',
                                  color: AppColors.error,
                                ),
                                const Divider(height: 18),
                                _StatRow(
                                  label: 'شوهدت مؤخراً',
                                  value: '$recent',
                                  color: AppColors.secondary,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Stream<ConversationCount> _conversationCount(
      FirestoreService firestore, String uid) {
    return firestore.streamConversations(uid).map((list) {
      final unreadTotal = list.fold<int>(0, (s, c) => s + c.unreadCount);
      return ConversationCount(list.length, unreadTotal);
    });
  }

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(title, style: AppTextStyles.titleLarge),
      ],
    );
  }

  Widget _buildTopProperties(List<Property> props) {
    final sorted = [...props]..sort((a, b) => b.viewsCount.compareTo(a.viewsCount));
    final top = sorted.take(3).toList();
    return Container(
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('الأكثر مشاهدة', style: AppTextStyles.titleMedium),
          const SizedBox(height: 12),
          ...top.map((p) {
            final maxViews = sorted.first.viewsCount.clamp(1, 1 << 31);
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(p.title,
                            style: AppTextStyles.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                      ),
                      const SizedBox(width: 8),
                      Text('${p.viewsCount} مشاهدة',
                          style: AppTextStyles.caption
                              .copyWith(color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: p.viewsCount / maxViews,
                      minHeight: 5,
                      backgroundColor: AppColors.shimmerBase,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class ConversationCount {
  final int count;
  final int unread;
  const ConversationCount(this.count, this.unread);
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadiusSmall),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: AppTextStyles.displaySmall.copyWith(
                fontSize: 22,
                color: color,
              )),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        Text(value,
            style: AppTextStyles.titleMedium.copyWith(color: color)),
      ],
    );
  }
}
