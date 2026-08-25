import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_button.dart';
import '../search/search_screen.dart';

class SavedSearch {
  final String id;
  final String query;
  final String propertyType;
  final String operationType;
  final String governorate;
  final double? minPrice;
  final double? maxPrice;
  final double? minArea;
  final double? maxArea;
  final int? rooms;
  final int? bathrooms;
  final int? floor;
  final List<String> amenities;
  final DateTime createdAt;

  SavedSearch({
    required this.id,
    required this.query,
    this.propertyType = '',
    this.operationType = '',
    this.governorate = '',
    this.minPrice,
    this.maxPrice,
    this.minArea,
    this.maxArea,
    this.rooms,
    this.bathrooms,
    this.floor,
    this.amenities = const [],
    required this.createdAt,
  });

  factory SavedSearch.fromFirestore(Map<String, dynamic> data, String id) {
    return SavedSearch(
      id: id,
      query: data['query']?.toString() ?? '',
      propertyType: data['propertyType']?.toString() ?? '',
      operationType: data['operationType']?.toString() ?? '',
      governorate: data['governorate']?.toString() ?? '',
      minPrice: (data['minPrice'] as num?)?.toDouble(),
      maxPrice: (data['maxPrice'] as num?)?.toDouble(),
      minArea: (data['minArea'] as num?)?.toDouble(),
      maxArea: (data['maxArea'] as num?)?.toDouble(),
      rooms: (data['rooms'] as num?)?.toInt(),
      bathrooms: (data['bathrooms'] as num?)?.toInt(),
      floor: (data['floor'] as num?)?.toInt(),
      amenities: (data['amenities'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get filtersSummary {
    final parts = <String>[];
    if (propertyType.isNotEmpty) parts.add(propertyType);
    if (operationType.isNotEmpty) parts.add(operationType);
    if (governorate.isNotEmpty) parts.add(governorate);
    if (minPrice != null || maxPrice != null) {
      final priceParts = <String>[];
      if (minPrice != null) priceParts.add('من ${_formatNum(minPrice!)}');
      if (maxPrice != null) priceParts.add('إلى ${_formatNum(maxPrice!)}');
      parts.add(priceParts.join(' '));
    }
    if (rooms != null) parts.add('$rooms غرف');
    if (bathrooms != null) parts.add('$bathrooms حمام');
    if (floor != null) parts.add('الطابق $floor');
    if (minArea != null || maxArea != null) {
      final areaParts = <String>[];
      if (minArea != null && minArea! > 0) areaParts.add('من ${minArea!.toStringAsFixed(0)}م²');
      if (maxArea != null && maxArea! < 1000) areaParts.add('إلى ${maxArea!.toStringAsFixed(0)}م²');
      if (areaParts.isNotEmpty) parts.add(areaParts.join(' '));
    }
    if (amenities.isNotEmpty) {
      final labels = amenities.map((a) => _amenityLabel(a)).toList();
      parts.add(labels.join(', '));
    }
    return parts.isNotEmpty ? parts.join(' • ') : 'جميع العقارات';
  }

  static String _amenityLabel(String key) {
    switch (key) {
      case 'hasElevator': return 'مصعد';
      case 'hasParking': return 'موقف';
      case 'hasAC': return 'تكييف';
      case 'hasHeating': return 'تدفئة';
      case 'hasGarden': return 'حديقة';
      case 'hasPool': return 'مسبح';
      case 'hasBalcony': return 'شرفة';
      case 'hasInternet': return 'إنترنت';
      case 'hasGas': return 'غاز';
      case 'isFurnished': return 'مفروش';
      default: return key;
    }
  }

  static String _formatNum(double n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(0)}K';
    return n.toStringAsFixed(0);
  }
}

class SavedSearchesScreen extends StatelessWidget {
  const SavedSearchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final uid = auth.currentUser?.uid;

    return Scaffold(
      appBar: const CustomAppBar(title: 'عمليات البحث المحفوظة'),
      body: uid == null
          ? const Center(child: Text('يرجى تسجيل الدخول'))
          : _buildBody(context, uid),
    );
  }

  Widget _buildBody(BuildContext context, String uid) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('savedSearches')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const _EmptySearches();
        }
        final searches = snapshot.data!.docs.map((doc) {
          return SavedSearch.fromFirestore(
            doc.data() as Map<String, dynamic>,
            doc.id,
          );
        }).toList();

        return ListView.builder(
          padding: AppConstants.screenPadding,
          itemCount: searches.length,
          itemBuilder: (context, index) {
            final search = searches[index];
            return _SearchCard(
              search: search,
              onDelete: () => _deleteSearch(context, uid, search.id),
              onView: () => _viewResults(context, search),
            );
          },
        );
      },
    );
  }

  void _viewResults(BuildContext context, SavedSearch search) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SearchScreen(
          initialQuery: search.query,
          initialType:
              search.propertyType.isEmpty ? null : search.propertyType,
          initialOperation:
              search.operationType.isEmpty ? null : search.operationType,
          initialGovernorate:
              search.governorate.isEmpty ? null : search.governorate,
          initialMinPrice: search.minPrice,
          initialMaxPrice: search.maxPrice,
          initialMinArea: search.minArea,
          initialMaxArea: search.maxArea,
          initialRooms: search.rooms,
          initialBathrooms: search.bathrooms,
          initialFloor: search.floor,
          initialAmenities: search.amenities,
        ),
      ),
    );
  }

  Future<void> _deleteSearch(
      BuildContext context, String uid, String searchId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('حذف البحث'),
        content: const Text('هل أنت متأكد من حذف هذا البحث المحفوظ؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('savedSearches')
          .doc(searchId)
          .delete();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e')),
        );
      }
    }
  }
}

class _SearchCard extends StatelessWidget {
  final SavedSearch search;
  final VoidCallback onDelete;
  final VoidCallback onView;

  const _SearchCard({
    required this.search,
    required this.onDelete,
    required this.onView,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: AppConstants.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.search,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        search.query.isNotEmpty
                            ? search.query
                            : 'بحث عام',
                        style: AppTextStyles.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        search.filtersSummary,
                        style: AppTextStyles.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    Icons.close,
                    color: AppColors.textSecondary,
                    size: 20,
                  ),
                  onPressed: onDelete,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 12,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDate(search.createdAt),
                  style: AppTextStyles.caption,
                ),
                const Spacer(),
                SizedBox(
                  height: 36,
                  child: GradientButton(
                    text: 'مشاهدة النتائج',
                    onPressed: onView,
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inDays == 0) return 'اليوم';
    if (diff.inDays == 1) return 'أمس';
    if (diff.inDays < 7) return 'منذ ${diff.inDays} أيام';
    if (diff.inDays < 30) return 'منذ ${(diff.inDays / 7).floor()} أسابيع';
    if (diff.inDays < 365) return 'منذ ${(diff.inDays / 30).floor()} شهر';
    return 'منذ ${(diff.inDays / 365).floor()} سنة';
  }
}

class _EmptySearches extends StatelessWidget {
  const _EmptySearches();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppConstants.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.bookmark_border,
                size: 48,
                color: AppColors.warning,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'لا توجد عمليات بحث محفوظة',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'احفظ عمليات البحث لتعود إليها لاحقاً',
              style: AppTextStyles.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
