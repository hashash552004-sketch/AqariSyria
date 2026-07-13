import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/firestore_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/property_card.dart';
import '../../widgets/custom_app_bar.dart';
import '../chat/chat_screen.dart';
import '../compare/compare_properties_screen.dart';
import '../../services/compare_service.dart';
import 'full_gallery_screen.dart';
import 'interactive_map_screen.dart';

class PropertyDetailScreen extends StatefulWidget {
  final Property property;
  const PropertyDetailScreen({super.key, required this.property});

  @override
  State<PropertyDetailScreen> createState() => _PropertyDetailScreenState();
}

class _PropertyDetailScreenState extends State<PropertyDetailScreen> {
  final PageController _pageController = PageController();
  final ScrollController _scrollController = ScrollController();
  int _currentImageIndex = 0;
  bool _descriptionExpanded = false;
  double _scrollOffset = 0;
  String? _userId;
  bool _isFavorite = false;


  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      setState(() => _scrollOffset = _scrollController.offset);
    });
    _loadFavoriteStatus();
  }

  Future<void> _loadFavoriteStatus() async {
    final auth = context.read<AuthService>();
    final user = auth.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final firestore = context.read<FirestoreService>();
    final appUser = await firestore.getUser(uid);
    if (appUser != null && mounted) {
      setState(() {
        _userId = uid;
        _isFavorite = appUser.favorites.contains(widget.property.id);
      });
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  bool get _appBarSolid => _scrollOffset > 200;

  @override
  Widget build(BuildContext context) {
    final p = widget.property;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 320,
                  pinned: true,
                  backgroundColor: _appBarSolid ? AppColors.background : Colors.transparent,
                  elevation: _appBarSolid ? 1 : 0,
                  leading: _buildBackButton(),
                  actions: [
                    _buildIconButton(
                      _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      _toggleFavorite,
                      color: _isFavorite ? AppColors.error : null,
                    ),
                    _buildIconButton(
                      Icons.compare_arrows_rounded,
                      _addToCompare,
                      color: CompareService.isInCompare(widget.property.id) ? AppColors.primary : null,
                    ),
                    _buildIconButton(Icons.ios_share_rounded, () => _shareProperty(context, p)),
                    _buildIconButton(Icons.flag_outlined, () => _showReportDialog(context, p)),
                  ],
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildImageCarousel(p),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildPriceAndTitle(p),
                        const SizedBox(height: 8),
                        _buildLocation(p),
                        const SizedBox(height: 12),
                        _buildBadges(p),
                        const SizedBox(height: 20),
                        _buildDivider(),
                        _buildQuickStats(p),
                        _buildDivider(),
                        _buildDescription(p),
                        _buildDivider(),
                        _buildAmenities(p),
                        _buildDivider(),
                        _buildLocationDetails(p),
                        _buildDivider(),
                        _buildOwnerInfo(p),
                        _buildDivider(),
                        _buildSimilarProperties(p),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomBar(p),
        ],
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _appBarSolid ? AppColors.background : AppColors.glassWhite,
          borderRadius: BorderRadius.circular(14),
          border: _appBarSolid
              ? Border.all(color: AppColors.border)
              : Border.all(color: AppColors.glassBorder),
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: _appBarSolid ? AppColors.textPrimary : Colors.white,
            size: 18,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback onTap, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: _appBarSolid ? AppColors.background : AppColors.glassWhite,
          borderRadius: BorderRadius.circular(14),
          border: _appBarSolid
              ? Border.all(color: AppColors.border)
              : Border.all(color: AppColors.glassBorder),
        ),
        child: IconButton(
          icon: Icon(
            icon,
            color: color ?? (_appBarSolid ? AppColors.textPrimary : Colors.white),
            size: 20,
          ),
          onPressed: onTap,
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (_userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('سجل دخول أولاً'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final firestore = context.read<FirestoreService>();
    await firestore.toggleFavorite(_userId!, widget.property.id);
    setState(() => _isFavorite = !_isFavorite);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFavorite ? 'تمت الإضافة للمفضلة' : 'تمت الإزالة من المفضلة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _addToCompare() {
    final p = widget.property;
    CompareService.toggle(p.id, p);
    final isIn = CompareService.isInCompare(p.id);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isIn ? 'تمت الإضافة للمقارنة' : 'تمت الإزالة من المقارنة'),
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (mounted) setState(() {});
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ComparePropertiesScreen()),
    );
  }

  Widget _buildImageCarousel(Property property) {
    final hasImages = property.images.isNotEmpty;
    final images = hasImages ? property.images : <String>[];

    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          Hero(
            tag: 'property_${property.id}',
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentImageIndex = index),
              itemCount: hasImages ? images.length : 1,
              itemBuilder: (context, index) {
                if (!hasImages) {
                  return Container(
                    color: AppColors.shimmerBase,
                    child: Center(
                      child: Icon(Icons.home_work, size: 64, color: AppColors.textSecondary.withValues(alpha: 0.5)),
                    ),
                  );
                }
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => FullGalleryScreen(
                        images: images,
                        initialIndex: index,
                      ),
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: images[index],
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(color: AppColors.shimmerBase),
                    errorWidget: (_, __, ___) => Container(
                      color: AppColors.shimmerBase,
                      child: Icon(Icons.broken_image, color: AppColors.textSecondary),
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    images.length > 5 ? 5 : images.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentImageIndex == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentImageIndex == i ? Colors.white : Colors.white.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (hasImages)
            Positioned(
              bottom: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullGalleryScreen(
                      images: images,
                      initialIndex: _currentImageIndex,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.grid_view_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        '${_currentImageIndex + 1} / ${images.length}',
                        style: AppTextStyles.labelSmall.copyWith(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPriceAndTitle(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${property.price.toStringAsFixed(0)}',
              style: AppTextStyles.price,
            ),
            const SizedBox(width: 6),
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(AppConstants.currency, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
            ),
            const Spacer(),
            if (property.isUrgent)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.urgentBadge,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('عاجل', style: AppTextStyles.labelSmall.copyWith(color: Colors.white)),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(property.title, style: AppTextStyles.headlineSmall),
      ],
    );
  }

  Widget _buildLocation(Property property) {
    return Row(
      children: [
        Icon(Icons.location_on_rounded, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '${property.governorate}${property.region.isNotEmpty ? '، ${property.region}' : ''}${property.neighborhood.isNotEmpty ? '، ${property.neighborhood}' : ''}',
            style: AppTextStyles.bodyMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBadges(Property property) {
    final opLabel = property.operationType == 'rent'
        ? 'إيجار'
        : property.operationType == 'invest'
        ? 'استثمار'
        : 'بيع';
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _badge(property.type, AppColors.primary),
        _badge(opLabel, property.operationType == 'rent' ? AppColors.success : AppColors.primary),
        if (property.isSold) _badge('تم البيع', AppColors.error),
        if (property.isFeatured) _badge('مميز', AppColors.featuredBadge),
      ],
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: AppTextStyles.labelSmall.copyWith(color: color)),
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Container(height: 1, color: AppColors.border),
    );
  }

  Widget _buildQuickStats(Property property) {
    final hasDeedType = property.deedType.isNotEmpty;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _statItem(Icons.bed_outlined, 'غرف', '${property.rooms}'),
            _statItem(Icons.bathtub_outlined, 'حمامات', '${property.bathrooms}'),
            _statItem(Icons.square_foot, 'المساحة', '${property.area.toInt()} م²'),
            _statItem(Icons.stairs, 'الطابق', property.floor > 0 ? '${property.floor}' : 'أرضي'),
          ],
        ),
        if (hasDeedType) ...[
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'نوع الطابو: ${property.deedType}',
                      style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _statItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: AppColors.primary, size: 24),
        ),
        const SizedBox(height: 6),
        Text(value, style: AppTextStyles.titleSmall),
        Text(label, style: AppTextStyles.caption),
      ],
    );
  }

  Widget _buildDescription(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text('الوصف', style: AppTextStyles.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        AnimatedCrossFade(
          firstChild: Text(
            property.description,
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary, height: 1.7),
            maxLines: _descriptionExpanded ? null : 3,
            overflow: _descriptionExpanded ? null : TextOverflow.ellipsis,
          ),
          secondChild: const SizedBox.shrink(),
          crossFadeState: CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
        if (property.description.length > 100)
          GestureDetector(
            onTap: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  Text(
                    _descriptionExpanded ? 'عرض أقل' : 'عرض المزيد',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    _descriptionExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildAmenities(Property property) {
    final amenities = <MapEntry<String, bool>>[
      MapEntry('مصعد', property.hasElevator),
      MapEntry('موقف سيارة', property.hasParking),
      MapEntry('تكييف', property.hasAC),
      MapEntry('تدفئة', property.hasHeating),
      MapEntry('حديقة', property.hasGarden),
      MapEntry('مسبح', property.hasPool),
      MapEntry('شرفة', property.hasBalcony),
      MapEntry('إنترنت', property.hasInternet),
      MapEntry('غاز', property.hasGas),
      MapEntry('مفروش', property.isFurnished),
    ];

    final amenityIcons = <String, IconData>{
      'مصعد': Icons.elevator_rounded,
      'موقف سيارة': Icons.local_parking_rounded,
      'تكييف': Icons.ac_unit_rounded,
      'تدفئة': Icons.fireplace_rounded,
      'حديقة': Icons.park_rounded,
      'مسبح': Icons.pool_rounded,
      'شرفة': Icons.balcony_rounded,
      'إنترنت': Icons.wifi_rounded,
      'غاز': Icons.local_fire_department_rounded,
      'مفروش': Icons.chair_rounded,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text('الخدمات والمرافق', style: AppTextStyles.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: amenities.map((entry) {
            final icon = amenityIcons[entry.key] ?? Icons.check_circle_rounded;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: entry.value
                    ? AppColors.success.withValues(alpha: 0.08)
                    : AppColors.error.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: entry.value
                      ? AppColors.success.withValues(alpha: 0.2)
                      : AppColors.error.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: entry.value ? AppColors.success : AppColors.error,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    entry.key,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: entry.value ? AppColors.textPrimary : AppColors.textSecondary,
                      fontWeight: entry.value ? FontWeight.w500 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildLocationDetails(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 20,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Text('الموقع', style: AppTextStyles.titleLarge),
              ],
            ),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => InteractiveMapScreen(property: property)),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('عرض على الخريطة', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                    const SizedBox(width: 4),
                    Icon(Icons.map_rounded, size: 14, color: AppColors.primary),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cards,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _locationRow('المحافظة', property.governorate),
              if (property.region.isNotEmpty) ...[
                const SizedBox(height: 8),
                _locationRow('المنطقة', property.region),
              ],
              if (property.neighborhood.isNotEmpty) ...[
                const SizedBox(height: 8),
                _locationRow('الحي', property.neighborhood),
              ],
              if (property.detailedAddress.isNotEmpty) ...[
                const SizedBox(height: 8),
                _locationRow('العنوان', property.detailedAddress),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _locationRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(label, style: AppTextStyles.bodySmall),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
        ),
      ],
    );
  }

  Widget _buildOwnerInfo(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text('معلومات المالك', style: AppTextStyles.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cards,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    property.ownerName.isNotEmpty ? property.ownerName[0].toUpperCase() : '?',
                    style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(property.ownerName.isNotEmpty ? property.ownerName : 'مالك العقار',
                        style: AppTextStyles.titleMedium),
                    if (property.ownerPhone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.phone_rounded, size: 12, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(property.ownerPhone, style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ],
                    const SizedBox(height: 6),
                    GestureDetector(
                      onTap: () => _showOwnerProperties(property),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.home_work_rounded, size: 14, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text('عرض العقارات', style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (property.ownerPhone.isNotEmpty)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    GestureDetector(
                      onTap: () => _launchUrl('tel:${property.ownerPhone}'),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.phone_rounded, color: AppColors.primary, size: 20),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<DocumentSnapshot>(
                      future: context.read<FirestoreService>().getUserDoc(property.ownerId),
                      builder: (context, snap) {
                        final data = snap.data?.data() as Map<String, dynamic>?;
                        final ownerWhatsapp = data?['whatsapp']?.toString().isNotEmpty == true
                            ? data!['whatsapp'].toString()
                            : property.ownerPhone;
                        return GestureDetector(
                          onTap: () => _launchUrl('https://wa.me/$ownerWhatsapp'),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.success.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.chat_bubble_rounded, color: AppColors.success, size: 20),
                          ),
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _showOwnerProperties(Property property) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _OwnerPropertiesScreen(ownerId: property.ownerId, ownerName: property.ownerName),
      ),
    );
  }

  Widget _buildSimilarProperties(Property property) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 20,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text('عقارات مشابهة', style: AppTextStyles.titleLarge),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: StreamBuilder<List<Property>>(
            stream: context.read<FirestoreService>().streamProperties(
              type: property.type,
              operationType: property.operationType,
            ),
            builder: (context, snapshot) {
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const SizedBox.shrink();
              }
              final similar = snapshot.data!
                  .where((p) => p.id != property.id)
                  .take(5)
                  .toList();
              if (similar.isEmpty) return const SizedBox.shrink();
              return ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.only(left: 4),
                itemCount: similar.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: 220,
                    child: PropertyCard(property: similar[index]),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBar(Property property) {
    final firestore = context.read<FirestoreService>();
    final auth = context.read<AuthService>();
    final isOwner = auth.currentUser?.uid == property.ownerId;

    return FutureBuilder<DocumentSnapshot>(
      future: firestore.getUserDoc(property.ownerId),
      builder: (context, snap) {
        final data = snap.data?.data() as Map<String, dynamic>?;
        final ownerPhone = data?['phone']?.toString() ?? property.ownerPhone;
        final ownerWhatsapp = data?['whatsapp']?.toString().isNotEmpty == true
            ? data!['whatsapp'].toString()
            : ownerPhone;

        return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.cards,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (isOwner)
            GestureDetector(
              onTap: () async {
                await firestore.updateProperty(property.id, {
                  'isSold': !property.isSold,
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(property.isSold ? 'تم إلغاء البيع' : 'تم تعليم العقار كمباع'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: Container(
                height: 52,
                margin: const EdgeInsets.only(left: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: property.isSold ? AppColors.warning : AppColors.error,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(Icons.sell_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 6),
                    Text(
                      property.isSold ? 'إلغاء البيع' : 'تم البيع',
                      style: AppTextStyles.button,
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: GestureDetector(
              onTap: () => _launchUrl('https://wa.me/$ownerWhatsapp'),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF25D366),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('واتساب', style: AppTextStyles.button),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _launchUrl('tel:$ownerPhone'),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.phone_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('اتصال', style: AppTextStyles.button),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: GestureDetector(
              onTap: () => _startChat(context, property),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [const Color(0xFF7B68EE), const Color(0xFF9B59B6)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7B68EE).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text('مراسلة', style: AppTextStyles.button),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
        },
    );
  }

  void _shareProperty(BuildContext context, Property p) {
    final text =
        '${p.title}\n${p.price.toStringAsFixed(0)} ${AppConstants.currency}\n\nللتسعير والتفاصيل: https://baitalomr.app/property/${p.id}';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم نسخ الرابط'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showReportDialog(BuildContext context, Property p) {
    final auth = context.read<AuthService>();
    final firestore = context.read<FirestoreService>();
    final reasons = [
      'إعلان مزيف',
      'معلومات خاطئة',
      'احتيال',
      'إعلان مكرر',
      'أخرى',
    ];

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('الإبلاغ عن الإعلان'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: reasons.map((reason) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: ListTile(
                title: Text(reason),
                onTap: () async {
                  Navigator.pop(dialogCtx);
                  final userId = auth.currentUser?.uid ?? '';
                  if (userId.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('سجل دخول أولاً'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  await firestore.reportProperty(p.id, userId, reason);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم الإبلاغ، شكراً لك'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('إلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _startChat(BuildContext context, Property p) async {
    try {
      final auth = context.read<AuthService>();
      final firestore = context.read<FirestoreService>();
      final user = auth.currentUser;
      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('سجل دخول أولاً للمراسلة'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      final currentUserId = user.uid;
      if (currentUserId == p.ownerId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('لا يمكنك مراسلة نفسك'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final userName = user.displayName ?? user.email ?? 'مستخدم';
      final convId = await firestore.createConversation(
        p.id,
        p.title,
        p.ownerId,
        p.ownerName.isNotEmpty ? p.ownerName : 'مالك العقار',
        currentUserId,
        userName,
      );

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ChatScreen(
              conversationId: convId,
              propertyTitle: p.title,
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لا يمكن فتح الرابط'), behavior: SnackBarBehavior.floating),
      );
    }
  }
}

class _OwnerPropertiesScreen extends StatelessWidget {
  final String ownerId;
  final String ownerName;

  const _OwnerPropertiesScreen({required this.ownerId, required this.ownerName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'عقارات $ownerName'),
      body: StreamBuilder<List<Property>>(
        stream: context.read<FirestoreService>().streamProperties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text('لا توجد عقارات', style: AppTextStyles.bodyMedium),
            );
          }
          final ownerProps = snapshot.data!
              .where((p) => p.ownerId == ownerId)
              .toList();
          if (ownerProps.isEmpty) {
            return Center(
              child: Text('لا توجد عقارات لهذا المالك', style: AppTextStyles.bodyMedium),
            );
          }
          return ListView.builder(
            padding: AppConstants.screenPadding,
            itemCount: ownerProps.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: PropertyCard(property: ownerProps[index]),
              );
            },
          );
        },
      ),
    );
  }
}
