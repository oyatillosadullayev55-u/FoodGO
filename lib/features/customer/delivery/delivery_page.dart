import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/async_value_view.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/ui.dart';
import '../../../models/food_order.dart';
import '../orders/orders_providers.dart';

/// Yo'ldagi buyurtmalar: bosilsa jonli kuzatuv ochiladi.
class DeliveryPage extends ConsumerWidget {
  const DeliveryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yetkazib berish')),
      body: ContentFrame(
        child: AsyncValueView<List<FoodOrder>>(
          value: ref.watch(ordersProvider),
          onRetry: () => ref.invalidate(ordersProvider),
          builder: (all) {
            final active = all.where((o) => o.status.isActive).toList();
            if (active.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const EmptyView(
                      icon: Icons.delivery_dining_rounded,
                      title: "Yo'ldagi buyurtma yo'q",
                      message:
                          'Buyurtma bering, kuryerni shu yerda kuzatasiz.',
                    ),
                    FilledButton(
                      onPressed: () => context.push(AppRoutes.restaurants),
                      child: const Text('Buyurtma berish'),
                    ),
                  ],
                ),
              );
            }
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final o in active)
                  SoftCard(
                    margin: const EdgeInsets.only(bottom: 12),
                    onTap: () => context.push(AppRoutes.orderPath(o.id)),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primarySoft,
                          child: Icon(
                            Icons.delivery_dining_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.restaurantName ?? 'Buyurtma',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                o.status.label,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                              Text(
                                o.addressText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded),
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
