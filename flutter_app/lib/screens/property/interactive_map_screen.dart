import 'package:flutter/material.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';

class InteractiveMapScreen extends StatelessWidget {
  final Property property;
  const InteractiveMapScreen({super.key, required this.property});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('الموقع على الخريطة'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.map_rounded,
                      color: AppColors.primary,
                      size: 40,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'خريطة الموقع',
                    style: AppTextStyles.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سيتم عرض الموقع على الخريطة هنا',
                    style: AppTextStyles.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.my_location, color: AppColors.primary, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          '${property.governorate}، ${property.region.isNotEmpty ? property.region : property.governorate}',
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.cards,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('تفاصيل العنوان', style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                _infoRow('المحافظة', property.governorate),
                if (property.region.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow('المنطقة', property.region),
                ],
                if (property.neighborhood.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow('الحي', property.neighborhood),
                ],
                if (property.detailedAddress.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _infoRow('العنوان التفصيلي', property.detailedAddress),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 90,
          child: Text(label, style: AppTextStyles.bodySmall),
        ),
        Expanded(
          child: Text(value, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textPrimary)),
        ),
      ],
    );
  }
}
