import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../widgets/custom_app_bar.dart';

class PropertyStatisticsScreen extends StatelessWidget {
  final Property property;

  const PropertyStatisticsScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'إحصائيات العقار'),
      body: SingleChildScrollView(
        padding: AppConstants.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 20),
            _buildStatCards(),
            const SizedBox(height: 24),
            _buildSectionTitle('المشاهدات (آخر 7 أيام)'),
            const SizedBox(height: 16),
            _buildChart(),
            const SizedBox(height: 24),
            _buildSectionTitle('النشاط الأخير'),
            const SizedBox(height: 16),
            _buildRecentActivity(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.shimmerBase,
              borderRadius: BorderRadius.circular(12),
              image: property.images.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(property.images.first),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: property.images.isEmpty
                ? Icon(Icons.home_work, color: AppColors.textSecondary)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  property.title,
                  style: AppTextStyles.titleMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${property.governorate} • ${property.type}',
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '${property.price.toStringAsFixed(0)} ${AppConstants.currency}',
                  style: AppTextStyles.priceSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.visibility_outlined,
                label: 'عدد المشاهدات',
                value: '${property.viewsCount}',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.favorite_outline,
                label: 'المفضلة',
                value: '٤٢',
                color: AppColors.error,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                icon: Icons.share_outlined,
                label: 'مشاركة',
                value: '١٨',
                color: AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                icon: Icons.calendar_month_outlined,
                label: 'أيام النشر',
                value: _daysSincePublished(),
                color: AppColors.warning,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _daysSincePublished() {
    if (property.createdAt == null) return '٠';
    final days = DateTime.now().difference(property.createdAt!).inDays;
    return '$days';
  }

  Widget _buildSectionTitle(String title) {
    return Text(title, style: AppTextStyles.titleMedium);
  }

  Widget _buildChart() {
    final bars = [
      ('السبت', 0.3),
      ('الأحد', 0.5),
      ('الاثنين', 0.7),
      ('الثلاثاء', 0.4),
      ('الأربعاء', 0.8),
      ('الخميس', 0.6),
      ('الجمعة', 0.9),
    ];

    return Container(
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('المشاهدات', style: AppTextStyles.labelMedium),
              Text(
                'إجمالي ${property.viewsCount}',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars.map((bar) {
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          height: 140 * bar.$2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.primary,
                                AppColors.secondary.withValues(alpha: 0.7),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          bar.$1,
                          style: AppTextStyles.caption.copyWith(fontSize: 9),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivity() {
    final activities = [
      _ActivityData(
        icon: Icons.visibility_outlined,
        title: 'مشاهدة العقار',
        subtitle: 'تمت مشاهدة العقار من قبل مستخدم',
        time: 'منذ ساعة',
        color: AppColors.primary,
      ),
      _ActivityData(
        icon: Icons.favorite_outline,
        title: 'إضافة إلى المفضلة',
        subtitle: 'تمت إضافة العقار إلى المفضلة',
        time: 'منذ ٣ ساعات',
        color: AppColors.error,
      ),
      _ActivityData(
        icon: Icons.share_outlined,
        title: 'مشاركة',
        subtitle: 'تمت مشاركة العقار عبر واتساب',
        time: 'منذ يوم',
        color: AppColors.success,
      ),
      _ActivityData(
        icon: Icons.visibility_outlined,
        title: 'مشاهدة العقار',
        subtitle: 'تمت مشاهدة العقار من قبل مستخدم',
        time: 'منذ يومين',
        color: AppColors.primary,
      ),
      _ActivityData(
        icon: Icons.favorite_outline,
        title: 'إزالة من المفضلة',
        subtitle: 'تمت إزالة العقار من المفضلة',
        time: 'منذ ٣ أيام',
        color: AppColors.textSecondary,
      ),
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: activities.map((activity) {
          return _ActivityItem(data: activity);
        }).toList(),
      ),
    );
  }
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
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
          const SizedBox(height: 12),
          Text(
            value,
            style: AppTextStyles.displaySmall.copyWith(
              fontSize: 22,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}

class _ActivityData {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;
  final Color color;

  _ActivityData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.color,
  });
}

class _ActivityItem extends StatelessWidget {
  final _ActivityData data;

  const _ActivityItem({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.border, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data.title, style: AppTextStyles.labelMedium),
                const SizedBox(height: 2),
                Text(data.subtitle, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Text(data.time, style: AppTextStyles.caption),
        ],
      ),
    );
  }
}
