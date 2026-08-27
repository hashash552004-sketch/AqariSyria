import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/app_colors.dart';
import '../core/app_text_styles.dart';

/// Full-screen map with a draggable marker to pick a location.
/// Returns a [LatLng] on confirm (or the picked coordinates).
class LocationPickerScreen extends StatefulWidget {
  final LatLng? initial;
  final String hint;
  const LocationPickerScreen({super.key, this.initial, this.hint = 'حرّك الخريطة أو الدبوس لتحديد موقع العقار'});

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final MapController _mapController;
  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _center = widget.initial ?? const LatLng(34.8021, 38.9968); // Syria center
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() => _center = point);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('تحديد موقع العقار'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _center),
            child: Text('تم', style: AppTextStyles.titleMedium.copyWith(color: AppColors.primary)),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 12,
              onTap: _onMapTap,
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
                    point: _center,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.location_on_rounded, color: Colors.red, size: 40),
                  ),
                ],
              ),
            ],
          ),
          Positioned(
            bottom: 24,
            left: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.cards,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.pin_drop_rounded, color: AppColors.primary, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _center.toString(),
                          style: AppTextStyles.bodyMedium,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.hint,
                    style: AppTextStyles.caption,
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
