import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';

/// Read-only map showing a single property location marker.
/// Tapping opens a full-screen interactive viewer.
class LocationMapView extends StatelessWidget {
  final double latitude;
  final double longitude;
  final double height;
  final String? title;
  const LocationMapView({
    super.key,
    required this.latitude,
    required this.longitude,
    this.height = 220,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);
    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.drag | InteractiveFlag.pinchZoom,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.aqari_syria',
                maxNativeZoom: 19,
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 44,
                    height: 44,
                    child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 44),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.cards.withValues(alpha: 0.92),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    title ?? 'موقع العقار على الخريطة',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.textPrimary),
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
