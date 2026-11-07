import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../core/theme/app_colors.dart';

class CourierMap extends StatefulWidget {
  const CourierMap({super.key, this.me, this.restaurant, this.customer, this.target});

  final LatLng? me;
  final LatLng? restaurant;
  final LatLng? customer;

  /// Hozir borilayotgan nuqta (restoran yoki mijoz)
  final LatLng? target;

  @override
  State<CourierMap> createState() => _CourierMapState();
}

class _CourierMapState extends State<CourierMap> {
  static const _tashkent = LatLng(41.3111, 69.2797);

  final _controller = MapController();
  bool _ready = false;
  bool _follow = true;

  @override
  void didUpdateWidget(CourierMap old) {
    super.didUpdateWidget(old);
    if (old.target != widget.target) _follow = true;
    if (_follow) WidgetsBinding.instance.addPostFrameCallback((_) => _recenter());
  }

  void _recenter() {
    if (!_ready || !mounted) return;
    final me = widget.me;
    final target = widget.target;
    try {
      if (me != null && target != null) {
        _controller.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([me, target]),
            padding: const EdgeInsets.all(56),
            maxZoom: 17,
          ),
        );
      } else if (me != null) {
        _controller.move(me, 15);
      }
    } catch (_) {}
  }

  Marker _pin(LatLng p, IconData icon, Color color) => Marker(
        point: p,
        width: 44,
        height: 44,
        child: Icon(icon, size: 38, color: color),
      );

  @override
  Widget build(BuildContext context) {
    final me = widget.me;
    final target = widget.target;

    return Stack(
      children: [
        FlutterMap(
          mapController: _controller,
          options: MapOptions(
            initialCenter: me ?? target ?? _tashkent,
            initialZoom: 14,
            onMapReady: () {
              _ready = true;
              _recenter();
            },
            onPositionChanged: (camera, hasGesture) {
              if (hasGesture && _follow) setState(() => _follow = false);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'uz.foodgo.app',
            ),
            if (me != null && target != null)
              PolylineLayer(
                polylines: [Polyline(points: [me, target], strokeWidth: 4, color: AppColors.dark)],
              ),
            MarkerLayer(
              markers: [
                if (widget.restaurant != null)
                  _pin(widget.restaurant!, Icons.storefront_rounded, AppColors.primaryDark),
                if (widget.customer != null)
                  _pin(widget.customer!, Icons.home_rounded, AppColors.accentPurple),
                if (me != null)
                  Marker(
                    point: me,
                    width: 26,
                    height: 26,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: const [BoxShadow(blurRadius: 6, color: Colors.black26)],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: 'courier-recenter',
            backgroundColor: Colors.white,
            onPressed: () {
              setState(() => _follow = true);
              _recenter();
            },
            child: Icon(
              Icons.my_location_rounded,
              color: _follow ? AppColors.primaryDark : AppColors.grey,
            ),
          ),
        ),
      ],
    );
  }
}
