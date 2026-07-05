import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../widgets/gradient_button.dart';
import '../../widgets/property_card.dart';

class AgentProfileScreen extends StatelessWidget {
  const AgentProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(child: _buildProfileContent()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Text('عقارات الوكيل', style: AppTextStyles.headlineSmall),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: PropertyCard(property: _sampleProperties[index]),
                ),
                childCount: _sampleProperties.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
              child: Text('التقييمات', style: AppTextStyles.headlineSmall),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildReviewCard(_sampleReviews[index]),
                ),
                childCount: _sampleReviews.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 220,
      pinned: true,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.6)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            Positioned(
              top: 60,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: Colors.white.withValues(alpha: 0.3),
                    child: Text('أ', style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    )),
                  ),
                  const SizedBox(height: 12),
                  Text('أحمد الخطيب', style: AppTextStyles.displaySmall.copyWith(color: Colors.white)),

                ],
              ),
            ),
          ],
        ),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ...List.generate(5, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Icon(
                    i < 4 ? Icons.star : Icons.star_half,
                    color: AppColors.warning,
                    size: 22,
                  ),
                )),
                const SizedBox(width: 8),
                Text('4.9', style: AppTextStyles.titleLarge.copyWith(color: AppColors.warning)),
                const SizedBox(width: 4),
                Text('(126 تقييم)', style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.border), bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _buildStatItem('48', 'عقار'),
                Container(width: 1, height: 40, color: AppColors.border),
                _buildStatItem('92', 'عميل'),
                Container(width: 1, height: 40, color: AppColors.border),
                _buildStatItem('4.9', 'تقييم'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: GradientButton(
                    text: 'اتصال',
                    icon: Icons.phone,
                    onPressed: () {},
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GradientButton(
                    text: 'واتساب',
                    icon: Icons.chat,
                    gradientColors: [const Color(0xFF25D366), const Color(0xFF128C7E)],
                    onPressed: () {},
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(value, style: AppTextStyles.titleLarge.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(label, style: AppTextStyles.caption),
        ],
      ),
    );
  }

  Widget _buildReviewCard(_SampleReview r) {
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
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(r.name[0], style: AppTextStyles.titleSmall.copyWith(color: AppColors.primary)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: AppTextStyles.labelLarge),
                    const SizedBox(height: 2),
                    Row(
                      children: List.generate(5, (i) => Icon(
                        i < r.rating ? Icons.star : Icons.star_border,
                        color: AppColors.warning, size: 14,
                      )),
                    ),
                  ],
                ),
              ),
              Text(r.date, style: AppTextStyles.caption),
            ],
          ),
          const SizedBox(height: 8),
          Text(r.text, style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }
}

final List<Property> _sampleProperties = [];

final List<_SampleReview> _sampleReviews = [];

class _SampleReview {
  final String name;
  final int rating;
  final String date;
  final String text;
  const _SampleReview({required this.name, required this.rating, required this.date, required this.text});
}
