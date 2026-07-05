import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_button.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  String _selectedFilter = 'الكل';
  final List<String> _filters = ['الكل', 'الأحدث', 'الأعلى تقييماً'];

  final List<_ReviewData> _reviews = [
    _ReviewData(
      name: 'أحمد المحمد',
      avatar: null,
      rating: 5,
      date: '2024-12-15',
      text: 'تعاملت معهم لشراء فيلا في دمشق، كانوا محترفين جداً وساعدوني في اختيار أفضل عقار. أنصح بالتعامل معهم.',
      likes: 24,
    ),
    _ReviewData(
      name: 'سارة الحسن',
      avatar: null,
      rating: 4,
      date: '2024-11-20',
      text: 'خدمة ممتازة وفريق متعاون. العقار كان مطابقاً للوصف تماماً. أنصح بالتعامل معهم.',
      likes: 18,
    ),
    _ReviewData(
      name: 'خالد عمر',
      avatar: null,
      rating: 5,
      date: '2024-10-05',
      text: 'أفضل مكتب عقاري تعاملت معه. الصدق والأمانة هما عنوان عملهم. سهلوا عليّ عملية شراء منزلي الأول.',
      likes: 31,
    ),
    _ReviewData(
      name: 'نور البيطار',
      avatar: null,
      rating: 3,
      date: '2024-09-12',
      text: 'تجربة جيدة بشكل عام، لكن التأخير في الرد على الاستفسارات كان مزعجاً بعض الشيء.',
      likes: 7,
    ),
    _ReviewData(
      name: 'محمود ديب',
      avatar: null,
      rating: 5,
      date: '2024-08-28',
      text: 'احترافية عالية وتعامل راقي. قاموا بتأجير شقتي في وقت قياسي وبأفضل سعر. شكراً لكم.',
      likes: 15,
    ),
    _ReviewData(
      name: 'ليلى جابر',
      avatar: null,
      rating: 4,
      date: '2024-07-14',
      text: 'فريق ممتاز ومكتب منظم. يوجد مجال لتحسين عملية التواصل لكن بشكل عام تجربة رائعة.',
      likes: 11,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: 'التقييمات'),
      body: ListView(
        padding: AppConstants.screenPadding,
        children: [
          _buildOverallRating(),
          const SizedBox(height: 24),
          _buildRatingBars(),
          const SizedBox(height: 24),
          _buildFilterChips(),
          const SizedBox(height: 16),
          ..._reviews.map((r) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildReviewCard(r),
          )),
          const SizedBox(height: 16),
          GradientButton(
            text: 'إضافة تقييم',
            icon: Icons.add,
            width: double.infinity,
            onPressed: () {},
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOverallRating() {
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
          const Text('4.3', style: TextStyle(
            fontSize: 56,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
            height: 1.1,
          )),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Icon(
                i < 4 ? Icons.star : Icons.star_half,
                color: AppColors.warning,
                size: 28,
              ),
            )),
          ),
          const SizedBox(height: 8),
          Text('من أصل 126 تقييم', style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildRatingBars() {
    final bars = [
      _RatingBarData(stars: 5, percentage: 0.55),
      _RatingBarData(stars: 4, percentage: 0.25),
      _RatingBarData(stars: 3, percentage: 0.12),
      _RatingBarData(stars: 2, percentage: 0.05),
      _RatingBarData(stars: 1, percentage: 0.03),
    ];

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
        children: bars.map((bar) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              SizedBox(
                width: 70,
                child: Text('${bar.stars} نجوم', style: AppTextStyles.labelMedium),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: bar.percentage,
                    backgroundColor: AppColors.shimmerBase,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.warning),
                    minHeight: 10,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                width: 40,
                child: Text(
                  '${(bar.percentage * 100).toInt()}%',
                  style: AppTextStyles.bodySmall,
                  textAlign: TextAlign.left,
                ),
              ),
            ],
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _filters.map((f) => Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () => setState(() => _selectedFilter = f),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedFilter == f ? AppColors.primary : AppColors.cards,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _selectedFilter == f ? AppColors.primary : AppColors.border,
                ),
                boxShadow: _selectedFilter == f ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ] : null,
              ),
              child: Text(
                f,
                style: AppTextStyles.labelMedium.copyWith(
                  color: _selectedFilter == f ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildReviewCard(_ReviewData review) {
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
                radius: 24,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  review.name[0],
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review.name, style: AppTextStyles.titleSmall),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          color: AppColors.warning,
                          size: 16,
                        )),
                        const SizedBox(width: 8),
                        Text(review.date, style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.text, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.thumb_up_alt_outlined, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text('${review.likes}', style: AppTextStyles.caption),
              const Spacer(),
              Text('مفيد', style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewData {
  final String name;
  final String? avatar;
  final int rating;
  final String date;
  final String text;
  final int likes;
  const _ReviewData({
    required this.name,
    this.avatar,
    required this.rating,
    required this.date,
    required this.text,
    required this.likes,
  });
}

class _RatingBarData {
  final int stars;
  final double percentage;
  const _RatingBarData({required this.stars, required this.percentage});
}
