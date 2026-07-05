import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_app_bar.dart';

class AdminPropertiesScreen extends StatefulWidget {
  const AdminPropertiesScreen({super.key});

  @override
  State<AdminPropertiesScreen> createState() => _AdminPropertiesScreenState();
}

class _AdminPropertiesScreenState extends State<AdminPropertiesScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String _searchQuery = '';

  static const _tabs = ['الكل', 'نشط', 'محظور', 'معلّق'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'إدارة العقارات'),
      body: Column(
        children: [
          Padding(
            padding: AppConstants.screenHorizontalPadding,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _searchController,
                textDirection: TextDirection.rtl,
                decoration: InputDecoration(
                  hintText: 'بحث بالعنوان أو المالك...',
                  hintStyle: TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: AppColors.textSecondary, size: 22),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.close, color: AppColors.textSecondary, size: 20),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: AppColors.cards,
              borderRadius: BorderRadius.circular(AppConstants.cardRadiusSmall),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              labelStyle: AppTextStyles.labelMedium,
              unselectedLabelStyle: AppTextStyles.labelMedium,
              indicator: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
              ),
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              tabs: _tabs.map((t) => Tab(text: t)).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) => _PropertiesList(
                searchQuery: _searchQuery,
                filter: tab,
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertiesList extends StatelessWidget {
  final String searchQuery;
  final String filter;

  const _PropertiesList({required this.searchQuery, required this.filter});

  @override
  Widget build(BuildContext context) {
    final firestore = FirestoreService();

    return StreamBuilder<List<Property>>(
      stream: firestore.streamProperties(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(child: Text('لا توجد عقارات', style: AppTextStyles.bodyMedium));
        }

        List<Property> properties = snapshot.data!;

        if (filter == 'نشط') {
          properties = properties.where((p) => p.isActive).toList();
        } else if (filter == 'محظور') {
          properties = properties.where((p) => !p.isActive).toList();
        } else if (filter == 'معلّق') {
          properties = properties.where((p) => !p.isActive).toList();
        }

        if (searchQuery.isNotEmpty) {
          properties = properties.where((p) =>
            p.title.toLowerCase().contains(searchQuery) ||
            p.ownerName.toLowerCase().contains(searchQuery)
          ).toList();
        }

        if (properties.isEmpty) {
          return Center(child: Text('لا توجد نتائج', style: AppTextStyles.bodyMedium));
        }

        return ListView.builder(
          padding: AppConstants.screenHorizontalPadding.copyWith(bottom: 20),
          itemCount: properties.length,
          itemBuilder: (context, index) => _PropertyAdminCard(
            property: properties[index],
            onDelete: () => _handleDelete(context, properties[index].id),
            onToggleActive: () => _handleToggleActive(context, properties[index]),
          ),
        );
      },
    );
  }

  Future<void> _handleDelete(BuildContext context, String propertyId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('تأكيد الحذف'),
        content: const Text('هل أنت متأكد من حذف هذا العقار؟'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('إلغاء')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await FirestoreService().deleteProperty(propertyId);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('تم حذف العقار'), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  Future<void> _handleToggleActive(BuildContext context, Property property) async {
    try {
      await FirestoreService().updateProperty(property.id, {'isActive': !property.isActive});
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(property.isActive ? 'تم تعطيل العقار' : 'تم تفعيل العقار'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }
}

class _PropertyAdminCard extends StatelessWidget {
  final Property property;
  final VoidCallback onDelete;
  final VoidCallback onToggleActive;

  const _PropertyAdminCard({
    required this.property,
    required this.onDelete,
    required this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadiusSmall),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          SizedBox(
            width: 100,
            height: 100,
            child: property.images.isNotEmpty
                ? CachedNetworkImage(
                    imageUrl: property.images.first,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(color: AppColors.shimmerBase),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.shimmerBase,
                      child: Icon(Icons.broken_image, color: AppColors.textSecondary),
                    ),
                  )
                : Container(
                    color: AppColors.shimmerBase,
                    child: Icon(Icons.home_work, size: 32, color: AppColors.textSecondary),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(property.title, style: AppTextStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 12, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(property.ownerName, style: AppTextStyles.bodySmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text('${property.price.toStringAsFixed(0)} ${AppConstants.currency}', style: AppTextStyles.priceSmall),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: property.isActive
                              ? AppColors.success.withValues(alpha: 0.1)
                              : AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          property.isActive ? 'نشط' : 'موقوف',
                          style: AppTextStyles.caption.copyWith(
                            color: property.isActive ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: onToggleActive,
                            icon: Icon(property.isActive ? Icons.block : Icons.check_circle, size: 14),
                            label: Text(property.isActive ? 'تعطيل' : 'تفعيل', style: AppTextStyles.labelSmall),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: property.isActive ? AppColors.warning : AppColors.success,
                              side: BorderSide(color: (property.isActive ? AppColors.warning : AppColors.success).withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SizedBox(
                          height: 32,
                          child: OutlinedButton.icon(
                            onPressed: onDelete,
                            icon: const Icon(Icons.delete_outline, size: 14),
                            label: Text('حذف', style: AppTextStyles.labelSmall),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              padding: const EdgeInsets.symmetric(horizontal: 6),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }
}
