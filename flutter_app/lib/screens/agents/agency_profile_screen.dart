import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/property_card.dart';

class AgencyProfileScreen extends StatelessWidget {
  const AgencyProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'الملف التعريفي'),
      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          _buildHeader(),
          const SizedBox(height: 20),
          _buildStats(),
          const SizedBox(height: 20),
          _buildAbout(),
          const SizedBox(height: 24),
          Row(
            children: [
              Text('فريق العمل', style: AppTextStyles.headlineSmall),
              const Spacer(),
              Text('عرض الكل', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          _buildTeamList(),
          const SizedBox(height: 24),
          Text('عقارات المكتب', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 12),
          ...List.generate(_sampleProperties.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: PropertyCard(property: _sampleProperties[i]),
          )),
          const SizedBox(height: 24),
          _buildContactSection(),
          const SizedBox(height: 20),
        ],
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
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2), width: 2),
            ),
            child: Icon(Icons.business, size: 44, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          Text('مكتب بيت العمر العقاري', style: AppTextStyles.headlineMedium),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('منذ 2010', style: AppTextStyles.bodySmall),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(5, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 1),
                child: Icon(Icons.star, color: AppColors.warning, size: 20),
              )),
              const SizedBox(width: 8),
              Text('5.0', style: AppTextStyles.titleMedium.copyWith(color: AppColors.warning)),
              const SizedBox(width: 4),
              Text('(245 تقييم)', style: AppTextStyles.bodySmall),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          _statItem(Icons.home_work, '186', 'عقار'),
          Container(width: 1, height: 50, color: AppColors.border),
          _statItem(Icons.people, '342', 'عميل'),
          Container(width: 1, height: 50, color: AppColors.border),
          _statItem(Icons.star, '4.9', 'تقييم'),
        ],
      ),
    );
  }

  Widget _statItem(IconData icon, String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(height: 6),
          Text(value, style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
          const SizedBox(height: 2),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildAbout() {
    return Container(
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
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
          Text('عن المكتب', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'مكتب بيت العمر العقاري من أعرق المكاتب العقارية في سوريا. نقدم خدمات بيع وشراء وتأجير العقارات '
            'في جميع المحافظات السورية. لدينا فريق من الوكلاء المعتمدين ذوي الخبرة الطويلة في السوق العقاري.',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppColors.primary),
              const SizedBox(width: 6),
              Text('دمشق - المزة - شارع الخدمات', style: AppTextStyles.bodyMedium),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamList() {
    final team = [
      _TeamMember('أحمد الخطيب', 'وكيل معتمد'),
      _TeamMember('نور الأسعد', 'وكيل معتمد'),
      _TeamMember('سلمى حديد', 'وكيل معتمد'),
      _TeamMember('خالد ديب', 'وكيل عقاري'),
      _TeamMember('رنا القاسم', 'وكيل معتمد'),
    ];

    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: team.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final m = team[index];
          return Container(
            width: 140,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cards,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(m.name[0], style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(m.name, style: AppTextStyles.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(m.role, style: AppTextStyles.caption, maxLines: 1, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: AppConstants.cardPadding,
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
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
          Text('معلومات الاتصال', style: AppTextStyles.headlineSmall),
          const SizedBox(height: 16),
          _contactItem(Icons.phone, '0933 123 456'),
          const SizedBox(height: 12),
          _contactItem(Icons.email, 'info@baitelomr.com'),
          const SizedBox(height: 12),
          _contactItem(Icons.language, 'www.baitelomr.com'),
          const SizedBox(height: 12),
          _contactItem(Icons.location_on, 'دمشق - المزة - شارع الخدمات'),
        ],
      ),
    );
  }

  Widget _contactItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Text(text, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

class _TeamMember {
  final String name;
  final String role;
  const _TeamMember(this.name, this.role);
}

final List<Property> _sampleProperties = [];
