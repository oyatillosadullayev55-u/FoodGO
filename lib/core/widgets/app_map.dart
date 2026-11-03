import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../theme/app_colors.dart';

/// Xaritadagi bitta nuqta (restoran, mijoz yoki kuryer).
class MapPoint {
  const MapPoint({
    required this.point,
    this.icon = Icons.location_on_rounded,
    this.color = AppColors.dark,
    this.label,
  });

  final LatLng point;
  final IconData icon;
  final Color color;
  final String? label;
}

/// Tashkent markazi — xarita uchun standart boshlang'ich nuqta.
const kTashkentCenter = LatLng(41.3111, 69.2797);

class AppMap extends StatelessWidget {
  const AppMap({
    super.key,
    this.points = const [],
    this.center,
    this.zoom = 14,
    this.height = 220,
    this.onTap,
    this.interactive = true,
    this.borderRadius = 18,
  });

  final List<MapPoint> points;
  final LatLng? center;
  final double zoom;
  final double height;
  final ValueChanged<LatLng>? onTap;
  final bool interactive;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final start = center ??
        (points.isNotEmpty ? points.first.point : kTashkentCenter);

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: FlutterMap(
          options: MapOptions(
            initialCenter: start,
            initialZoom: zoom,
            backgroundColor:
                isDark ? AppColors.darkSurfaceElevated : AppColors.greyLight,
            interactionOptions: InteractionOptions(
              flags: interactive
                  ? InteractiveFlag.all & ~InteractiveFlag.rotate
                  : InteractiveFlag.none,
            ),
            onTap: onTap == null ? null : (_, point) => onTap!(point),
          ),
          children: [
            TileLayer(
              urlTemplate:
                  'https://basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
              userAgentPackageName: 'uz.foodgo.app',
              maxZoom: 19,
            ),
            if (points.isNotEmpty)
              MarkerLayer(
                markers: [
                  for (final p in points)
                    Marker(
                      point: p.point,
                      width: 46,
                      height: 46,
                      child: _Pin(point: p),
                    ),
                ],
              ),
            RichAttributionWidget(
              alignment: AttributionAlignment.bottomLeft,
              attributions: const [
                TextSourceAttribution('OpenStreetMap contributors'),
                TextSourceAttribution('CARTO'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pin extends StatelessWidget {
  const _Pin({required this.point});

  final MapPoint point;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: point.color,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 3),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            point.icon,
            color: point.color == AppColors.primary
                ? AppColors.dark
                : Colors.white,
            size: 20,
          ),
        ),
      ],
    );
  }
}
