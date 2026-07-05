import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';
import '../core/constants.dart';
import '../models/property.dart';
import '../screens/property/property_detail_screen.dart';

class PropertyCard extends StatelessWidget {
  final Property property;
  final VoidCallback? onFavorite;
  final VoidCallback? onCompare;

  const PropertyCard({super.key, required this.property, this.onFavorite, this.onCompare});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => PropertyDetailScreen(property: property),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
            transitionDuration: const Duration(milliseconds: 300),
          ),
        );
      },
      child: Hero(
        tag: 'property_${property.id}',
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.cards,
            borderRadius: BorderRadius.circular(AppConstants.cardRadius),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(),
              _buildDetails(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage() {
    final opType = property.operationType;
    final opLabel = opType == 'rent'
        ? 'إيجار'
        : opType == 'invest'
        ? 'استثمار'
        : 'بيع';
    final opColor = opType == 'rent' ? AppColors.success : opType == 'invest' ? AppColors.warning : AppColors.primary;

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 10,
          child: property.images.isNotEmpty
              ? CachedNetworkImage(
                imageUrl: property.images.first,
                fit: BoxFit.cover,
                placeholder:
                    (_, __) => Container(color: AppColors.shimmerBase),
                errorWidget:
                    (_, __, ___) => Container(
                      color: AppColors.shimmerBase,
                      child: Icon(
                        Icons.broken_image,
                        color: AppColors.textSecondary,
                      ),
                    ),
              )
              : Container(
                color: AppColors.shimmerBase,
                child: Icon(
                  Icons.home_work,
                  size: 48,
                  color: AppColors.textSecondary,
                ),
              ),
        ),
        Positioned(
          top: 12,
          right: 12,
          child: Column(
            children: [
              GestureDetector(
                onTap: onFavorite,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.glassWhite,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.glassBorder),
                  ),
                  child: Icon(
                    Icons.favorite_border,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
              if (onCompare != null) const SizedBox(height: 8),
              if (onCompare != null)
                GestureDetector(
                  onTap: onCompare,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.glassWhite,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.glassBorder),
                    ),
                    child: Icon(
                      Icons.compare_arrows,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (property.isFeatured)
          Positioned(
            top: 12,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.featuredBadge,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('مميز', style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
              )),
            ),
          ),
        if (property.isUrgent)
          Positioned(
            bottom: 56,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.urgentBadge,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('عاجل', style: AppTextStyles.labelSmall.copyWith(
                color: Colors.white,
              )),
            ),
          ),
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: opColor,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: opColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(opLabel, style: AppTextStyles.labelSmall.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            )),
          ),
        ),
        Positioned(
          bottom: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.visibility_rounded, size: 12, color: Colors.white),
                const SizedBox(width: 4),
                Text(
                  _formatViews(property.viewsCount),
                  style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetails() {
    return Padding(
      padding: AppConstants.cardPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  property.title,
                  style: AppTextStyles.titleMedium,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Icon(Icons.location_on, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${property.governorate}${property.region.isNotEmpty ? ', ${property.region}' : ''}',
                  style: AppTextStyles.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${property.price.toStringAsFixed(0)} ${AppConstants.currency}',
                  style: AppTextStyles.priceSmall.copyWith(fontSize: 14),
                ),
              ),
              const Spacer(),
              _iconText(Icons.bed_outlined, '${property.rooms}'),
              const SizedBox(width: 12),
              _iconText(Icons.bathtub_outlined, '${property.bathrooms}'),
              const SizedBox(width: 12),
              _iconText(Icons.square_foot, '${property.area.toInt()}'),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today, size: 12, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                property.createdAt != null
                    ? _formatDate(property.createdAt!)
                    : 'منذ قليل',
                style: AppTextStyles.caption,
              ),
              const Spacer(),
              Text(property.type, style: AppTextStyles.caption),
            ],
          ),
        ],
      ),
    );
  }

  Widget _iconText(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 3),
        Text(text, style: AppTextStyles.labelSmall),
      ],
    );
  }

  String _formatViews(int count) {
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}k';
    }
    return '$count';
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    if (diff.inDays < 30) return 'منذ ${(diff.inDays / 7).floor()} أسابيع';
    return 'منذ ${(diff.inDays / 30).floor()} شهر';
  }
}
