import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/app_colors.dart';
import '../../core/app_text_styles.dart';
import '../../core/constants.dart';
import '../../models/property.dart';

class InteractiveMapScreen extends StatelessWidget {
  final Property property;
  const InteractiveMapScreen({super.key, required this.property});

  Future<void> _openInMaps() async {
    final query = Uri.encodeComponent(
      '${property.governorate}, ${property.region}, ${property.neighborhood}, ${property.detailedAddress}'
          .replaceAll(RegExp(r',\s*,'), ',')
          .replaceAll(RegExp(r'^,\s*'), '')
          .replaceAll(RegExp(r',\s*$'), ''),
    );
    final url = 'https://www.google.com/maps/search/?api=1&query=$query';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    }
  }

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
            child: GestureDetector(
              onTap: _openInMaps,
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
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
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFFE8F5E9),
                            const Color(0xFFC8E6C9),
                            const Color(0xFFA5D6A7),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: CustomPaint(
                        painter: _MapGridPainter(),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: const Icon(Icons.map_rounded, color: Colors.white, size: 36),
                          ),
                          const SizedBox(height: 16),
                          Text('اضغط لفتح الخريطة', style: AppTextStyles.titleLarge.copyWith(color: AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          Text('سيتم فتح الموقع في Google Maps', style: AppTextStyles.bodyMedium),
                        ],
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 20,
                      child: Row(
                        children: [
                          Icon(Icons.my_location, color: AppColors.primary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            '${property.governorate}${property.region.isNotEmpty ? '، ${property.region}' : ''}',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
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
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _openInMaps,
                    icon: const Icon(Icons.directions),
                    label: const Text('الحصول على اتجاهات'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
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

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.15)
      ..strokeWidth = 0.5;

    const gridSize = 40.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
