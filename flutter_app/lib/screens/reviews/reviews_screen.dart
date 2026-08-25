import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/review.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../core/snackbar_helper.dart';
import '../../widgets/custom_app_bar.dart';

class ReviewsScreen extends StatefulWidget {
  final String propertyId;
  final String propertyTitle;

  const ReviewsScreen({
    super.key,
    required this.propertyId,
    this.propertyTitle = '',
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  String _selectedFilter = 'الكل';
  final List<String> _filters = ['الكل', 'الأحدث', 'الأعلى تقييماً'];

  List<Review> _applyFilter(List<Review> reviews) {
    switch (_selectedFilter) {
      case 'الأحدث':
        return [...reviews]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case 'الأعلى تقييماً':
        return [...reviews]..sort((a, b) => b.rating.compareTo(a.rating));
      default:
        return reviews;
    }
  }

  Future<void> _openReviewEditor({Review? existing}) async {
    final auth = context.read<AuthService>();
    if (auth.currentUser == null) {
      showSnackBar(context, 'يجب تسجيل الدخول لإضافة تقييم',
          backgroundColor: AppColors.error);
      return;
    }
    int rating = existing?.rating ?? 5;
    final commentController = TextEditingController(text: existing?.comment ?? '');

    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(existing == null ? 'إضافة تقييم' : 'تعديل تقييمك',
                    style: AppTextStyles.titleLarge),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    return IconButton(
                      onPressed: () => setSheetState(() => rating = i + 1),
                      icon: Icon(
                        i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                        color: AppColors.warning,
                        size: 38,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: commentController,
                  maxLines: 4,
                  maxLength: 500,
                  decoration: InputDecoration(
                    hintText: 'شاركنا تجربتك مع هذا العقار...',
                    filled: true,
                    fillColor: AppColors.cards,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () => Navigator.pop(sheetContext, true),
                    child: Text(existing == null ? 'نشر التقييم' : 'حفظ التعديل'),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );

    if (saved != true) return;
    if (!mounted) return;
    final user = auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final name = user.displayName ?? 'مستخدم';
    try {
      await context.read<FirestoreService>().submitReview(
            propertyId: widget.propertyId,
            userId: uid,
            userName: name,
            rating: rating,
            comment: commentController.text.trim(),
          );
      if (mounted) showSnackBar(context, 'شكراً لك، تم حفظ تقييمك');
    } catch (e) {
      if (!mounted) return;
      showSnackBar(context, 'تعذر حفظ التقييم: $e',
          backgroundColor: AppColors.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(title: widget.propertyTitle.isEmpty
          ? 'التقييمات'
          : 'تقييمات: ${widget.propertyTitle}'),
      body: StreamBuilder<List<Review>>(
        stream:
            context.read<FirestoreService>().streamPropertyReviews(widget.propertyId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final reviews = snapshot.data ?? [];
          final avg = reviews.isEmpty
              ? 0.0
              : reviews.map((r) => r.rating).reduce((a, b) => a + b) / reviews.length;
          final distribution = <int, int>{};
          for (final r in reviews) {
            distribution[r.rating] = (distribution[r.rating] ?? 0) + 1;
          }

          return ListView(
            padding: AppConstants.screenPadding,
            children: [
              _buildOverallRating(avg, reviews.length),
              const SizedBox(height: 24),
              _buildRatingBars(distribution, reviews.length),
              const SizedBox(height: 24),
              _buildFilterChips(),
              const SizedBox(height: 16),
              if (_applyFilter(reviews).isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Column(
                    children: [
                      Icon(Icons.rate_review_outlined,
                          size: 56, color: AppColors.textSecondary),
                      const SizedBox(height: 12),
                      Text('لا توجد تقييمات بعد',
                          style: AppTextStyles.titleMedium),
                      const SizedBox(height: 6),
                      Text('كن أول من يقيّم هذا العقار',
                          style: AppTextStyles.bodyMedium
                              .copyWith(color: AppColors.textSecondary)),
                    ],
                  ),
                )
              else
                ..._applyFilter(reviews).map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildReviewCard(r),
                    )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: reviews.any((r) =>
                          r.userId == context.read<AuthService>().currentUser?.uid)
                      ? () => _openReviewEditor(
                          existing: reviews.firstWhere((r) =>
                              r.userId ==
                              context.read<AuthService>().currentUser!.uid))
                      : () => _openReviewEditor(),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(reviews.any((r) =>
                          r.userId == context.read<AuthService>().currentUser?.uid)
                      ? 'تعديل تقييمك'
                      : 'إضافة تقييم'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildOverallRating(double avg, int count) {
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
          Text(count == 0 ? '-' : avg.toStringAsFixed(1),
              style: TextStyle(
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
                i < avg.round() ? Icons.star : Icons.star_border,
                color: AppColors.warning,
                size: 28,
              ),
            )),
          ),
          const SizedBox(height: 8),
          Text(count == 0 ? 'لا توجد تقييمات' : 'من أصل $count تقييم',
              style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildRatingBars(Map<int, int> distribution, int total) {
    final bars = [5, 4, 3, 2, 1]
        .map((stars) => (
              stars: stars,
              percentage: total == 0 ? 0.0 : (distribution[stars] ?? 0) / total,
            ))
        .toList();

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
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.warning),
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

  Widget _buildReviewCard(Review review) {
    final currentUid = context.read<AuthService>().currentUser?.uid;
    final isMine = review.userId == currentUid;
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
                  review.userName.isNotEmpty ? review.userName[0] : 'م',
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(review.userName, style: AppTextStyles.titleSmall),
                        ),
                        if (isMine)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('تقييمك',
                                style: AppTextStyles.caption.copyWith(color: AppColors.primary)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) => Icon(
                          i < review.rating ? Icons.star : Icons.star_border,
                          color: AppColors.warning,
                          size: 16,
                        )),
                        const SizedBox(width: 8),
                        Text(_formatDate(review.createdAt), style: AppTextStyles.caption),
                      ],
                    ),
                  ],
                ),
              ),
              if (isMine)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                  tooltip: 'حذف تقييمي',
                  onPressed: () => _confirmDelete(review),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(review.comment.isEmpty ? 'بدون تعليق' : review.comment,
              style: AppTextStyles.bodyMedium),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }

  Future<void> _confirmDelete(Review review) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('حذف التقييم'),
        content: const Text('هل تريد حذف تقييمك لهذا العقار؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await context.read<FirestoreService>().deleteReview(widget.propertyId, review.id);
      if (mounted) showSnackBar(context, 'تم حذف تقييمك');
    } catch (_) {
      if (mounted) {
        showSnackBar(context, 'تعذر الحذف', backgroundColor: AppColors.error);
      }
    }
  }
}
