import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';
import '../../services/firestore_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/gradient_button.dart';

class ComparePropertiesScreen extends StatefulWidget {
  const ComparePropertiesScreen({super.key});

  @override
  State<ComparePropertiesScreen> createState() =>
      _ComparePropertiesScreenState();
}

class _ComparePropertiesScreenState extends State<ComparePropertiesScreen> {
  final List<Property> _properties = [];

  Future<void> _addProperty() async {
    final firestore = context.read<FirestoreService>();
    final properties = await firestore.streamProperties().first;
    if (!mounted) return;

    final available = properties
        .where((p) => !_properties.any((sp) => sp.id == p.id))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لا توجد عقارات إضافية للمقارنة'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selected = await showModalBottomSheet<Property>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _PropertyPickerSheet(properties: available),
    );

    if (selected != null && mounted) {
      setState(() => _properties.add(selected));
    }
  }

  void _removeProperty(int index) {
    setState(() => _properties.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'مقارنة العقارات',
        actions: [
          if (_properties.isNotEmpty && _properties.length < 4)
            TextButton(
              onPressed: _addProperty,
              child: Text(
                'إضافة',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                ),
              ),
            ),
        ],
      ),
      body: _properties.isEmpty ? _buildEmptyState() : _buildComparison(),
    );
  }

  Widget _buildEmptyState() {
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
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.compare_arrows,
                size: 48,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'قارن بين العقارات',
              style: AppTextStyles.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'أضف عقارين أو أكثر للمقارنة',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 200,
              child: GradientButton(
                text: 'إضافة عقار للمقارنة',
                onPressed: _addProperty,
                icon: Icons.add,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparison() {
    return SingleChildScrollView(
      padding: AppConstants.screenPadding,
      child: Column(
        children: [
          _buildPropertyHeaders(),
          const SizedBox(height: 20),
          _buildComparisonTable(),
        ],
      ),
    );
  }

  Widget _buildPropertyHeaders() {
    return SizedBox(
      height: 220,
      child: Row(
        children: [
          ..._properties.asMap().entries.map((entry) {
            final index = entry.key;
            final property = entry.value;
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index < _properties.length - 1 ? 8 : 0,
                  right: index > 0 ? 8 : 0,
                ),
                child: _PropertyHeaderCard(
                  property: property,
                  onRemove: () => _removeProperty(index),
                ),
              ),
            );
          }),
          if (_properties.length < 4)
            Expanded(
              child: _AddPropertyPlaceholder(onTap: _addProperty),
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonTable() {
    final attributes = _buildAttributes();
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: attributes.map((attr) {
          return _ComparisonRow(
            label: attr.label,
            icon: attr.icon,
            values: attr.values,
            bestIndex: attr.bestIndex,
            highlightType: attr.highlightType,
          );
        }).toList(),
      ),
    );
  }

  List<_AttributeGroup> _buildAttributes() {
    return [
      _AttributeGroup(
        label: 'السعر',
        icon: Icons.monetization_on_outlined,
        values:
            _properties.map((p) => '${p.price.toStringAsFixed(0)} ${AppConstants.currency}').toList(),
        bestIndex: _bestIndex((p) => p.price, lowest: true),
        highlightType: _HighlightType.price,
      ),
      _AttributeGroup(
        label: 'المساحة',
        icon: Icons.square_foot,
        values: _properties.map((p) => '${p.area.toStringAsFixed(0)} م²').toList(),
        bestIndex: _bestIndex((p) => p.area),
        highlightType: _HighlightType.positive,
      ),
      _AttributeGroup(
        label: 'الغرف',
        icon: Icons.bed_outlined,
        values: _properties.map((p) => '${p.rooms}').toList(),
        bestIndex: _bestIndex((p) => p.rooms.toDouble()),
        highlightType: _HighlightType.positive,
      ),
      _AttributeGroup(
        label: 'الحمامات',
        icon: Icons.bathtub_outlined,
        values: _properties.map((p) => '${p.bathrooms}').toList(),
        bestIndex: _bestIndex((p) => p.bathrooms.toDouble()),
        highlightType: _HighlightType.positive,
      ),
      _AttributeGroup(
        label: 'الطابق',
        icon: Icons.stairs_outlined,
        values: _properties.map((p) => '${p.floor}').toList(),
        bestIndex: null,
        highlightType: _HighlightType.none,
      ),
      _AttributeGroup(
        label: 'النوع',
        icon: Icons.home_outlined,
        values: _properties.map((p) => p.type).toList(),
        bestIndex: null,
        highlightType: _HighlightType.none,
      ),
      _AttributeGroup(
        label: 'المحافظة',
        icon: Icons.location_on_outlined,
        values: _properties.map((p) => p.governorate).toList(),
        bestIndex: null,
        highlightType: _HighlightType.none,
      ),
      _AttributeGroup(
        label: 'الخدمات',
        icon: Icons.miscellaneous_services_outlined,
        values: _properties.map((p) => '${_servicesCount(p)}').toList(),
        bestIndex: _bestIndex((p) => _servicesCount(p).toDouble()),
        highlightType: _HighlightType.positive,
      ),
    ];
  }

  int? _bestIndex(double Function(Property) getter, {bool lowest = false}) {
    if (_properties.isEmpty) return null;
    var best = 0;
    for (var i = 1; i < _properties.length; i++) {
      final better = lowest
          ? getter(_properties[i]) < getter(_properties[best])
          : getter(_properties[i]) > getter(_properties[best]);
      if (better) best = i;
    }
    return best;
  }

  int _servicesCount(Property p) {
    var count = 0;
    if (p.hasElevator) count++;
    if (p.hasParking) count++;
    if (p.hasAC) count++;
    if (p.hasHeating) count++;
    if (p.hasGarden) count++;
    if (p.hasPool) count++;
    if (p.hasBalcony) count++;
    if (p.hasInternet) count++;
    if (p.hasGas) count++;
    if (p.isFurnished) count++;
    return count;
  }
}

enum _HighlightType { none, positive, price }

class _AttributeGroup {
  final String label;
  final IconData icon;
  final List<String> values;
  final int? bestIndex;
  final _HighlightType highlightType;

  _AttributeGroup({
    required this.label,
    required this.icon,
    required this.values,
    this.bestIndex,
    this.highlightType = _HighlightType.none,
  });
}

class _ComparisonRow extends StatelessWidget {
  final String label;
  final IconData icon;
  final List<String> values;
  final int? bestIndex;
  final _HighlightType highlightType;

  const _ComparisonRow({
    required this.label,
    required this.icon,
    required this.values,
    this.bestIndex,
    this.highlightType = _HighlightType.none,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = AppColors.border;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(left: BorderSide(color: borderColor, width: 0.5)),
            ),
            child: Row(
              children: [
                Icon(icon, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 6),
                Text(label, style: AppTextStyles.labelMedium),
              ],
            ),
          ),
          ...values.asMap().entries.map((entry) {
            final isBest = entry.key == bestIndex;
            Color valueColor = AppColors.textPrimary;
            if (isBest && highlightType == _HighlightType.positive) {
              valueColor = AppColors.success;
            } else if (isBest && highlightType == _HighlightType.price) {
              valueColor = AppColors.success;
            }
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
                child: Text(
                  entry.value,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: valueColor,
                    fontWeight: isBest ? FontWeight.w700 : FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _PropertyHeaderCard extends StatelessWidget {
  final Property property;
  final VoidCallback onRemove;

  const _PropertyHeaderCard({
    required this.property,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cards,
        borderRadius: BorderRadius.circular(AppConstants.cardRadiusSmall),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.shimmerBase,
                    image: property.images.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(property.images.first),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: property.images.isEmpty
                      ? Icon(
                          Icons.home_work,
                          size: 32,
                          color: AppColors.textSecondary,
                        )
                      : null,
                ),
                Positioned(
                  top: 4,
                  left: 4,
                  child: GestureDetector(
                    onTap: onRemove,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: AppTextStyles.labelMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${property.price.toStringAsFixed(0)} ${AppConstants.currency}',
                    style: AppTextStyles.priceSmall.copyWith(fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddPropertyPlaceholder extends StatelessWidget {
  final VoidCallback onTap;

  const _AddPropertyPlaceholder({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cards,
          borderRadius: BorderRadius.circular(AppConstants.cardRadiusSmall),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.add, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              'إضافة عقار',
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PropertyPickerSheet extends StatelessWidget {
  final List<Property> properties;

  const _PropertyPickerSheet({required this.properties});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'اختر عقاراً للمقارنة',
              style: AppTextStyles.titleLarge,
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: ListView.separated(
              padding: AppConstants.screenPadding,
              itemCount: properties.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final property = properties[index];
                return _PropertyPickerItem(
                  property: property,
                  onTap: () => Navigator.pop(context, property),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PropertyPickerItem extends StatelessWidget {
  final Property property;
  final VoidCallback onTap;

  const _PropertyPickerItem({
    required this.property,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.cards,
          borderRadius: BorderRadius.circular(16),
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
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.shimmerBase,
                borderRadius: const BorderRadius.horizontal(
                  right: Radius.circular(16),
                ),
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    property.title,
                    style: AppTextStyles.titleSmall,
                    maxLines: 1,
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
                    style: AppTextStyles.priceSmall.copyWith(fontSize: 14),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Icon(Icons.add_circle_outline, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
