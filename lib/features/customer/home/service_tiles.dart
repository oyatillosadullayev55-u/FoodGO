import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/ui.dart';
import '../../../models/marketplace.dart';

/// Super Admin servis uchun tanlashi mumkin bo'lgan belgilar.
const serviceIcons = <String, (IconData, Color)>{
  'food': (Icons.restaurant_rounded, Color(0xFFEF2D46)),
  'master': (Icons.engineering_rounded, Color(0xFFF59E0B)),
  'shop': (Icons.shopping_cart_rounded, AppColors.primary),
  'product': (Icons.inventory_2_rounded, Color(0xFFC77B30)),
  'delivery': (Icons.delivery_dining_rounded, AppColors.primary),
  'apps': (Icons.grid_view_rounded, AppColors.primary),
  'cleaning': (Icons.cleaning_services_rounded, Color(0xFF0EA5A4)),
  'taxi': (Icons.local_taxi_rounded, Color(0xFFF59E0B)),
  'pharmacy': (Icons.local_pharmacy_rounded, Color(0xFF1F9D63)),
  'beauty': (Icons.content_cut_rounded, Color(0xFFDB2777)),
};

/// Bosh sahifadagi xizmat bo'limlari (3 ustun).
class ServiceGrid extends StatelessWidget {
  const ServiceGrid({super.key, required this.services});

  final List<ServiceModule> services;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final columns = c.maxWidth >= 640 ? 6 : 3;
        final width = (c.maxWidth - 10 * (columns - 1)) / columns;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final s in services)
              SizedBox(width: width, child: _Tile(service: s)),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.service});

  final ServiceModule service;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = serviceIcons[service.icon] ?? serviceIcons['apps']!;
    final route = service.route;
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
      onTap: () {
        if (route == null || !route.startsWith('/')) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${service.title} tez orada ishga tushadi')),
          );
        } else {
          context.push(route);
        }
      },
      child: Column(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              service.title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            service.subtitle == null ? '' : '(${service.subtitle})',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: AppColors.grey),
          ),
        ],
      ),
    );
  }
}
