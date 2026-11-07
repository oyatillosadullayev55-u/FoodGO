import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/customer/orders/orders_providers.dart';
import '../errors/error_mapper.dart';
import '../theme/app_colors.dart';
import '../utils/money.dart';

/// Buyurtma tarkibi: "2 × Lavash". Restoran va kuryer kartalarida ishlatiladi.
class OrderLinesView extends ConsumerWidget {
  const OrderLinesView({super.key, required this.orderId});

  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lines = ref.watch(orderLinesProvider(orderId));

    return lines.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(minHeight: 2),
      ),
      error: (e, _) => Row(
        children: [
          Expanded(
            child: Text(
              friendlyError(e),
              style: const TextStyle(color: AppColors.error, fontSize: 12.5),
            ),
          ),
          TextButton(
            onPressed: () => ref.invalidate(orderLinesProvider(orderId)),
            child: const Text('Qayta'),
          ),
        ],
      ),
      data: (list) {
        if (list.isEmpty) {
          return Row(
            children: [
              const Expanded(
                child: Text(
                  "Taomlar ro'yxati topilmadi",
                  style: TextStyle(color: AppColors.error, fontSize: 12.5),
                ),
              ),
              TextButton(
                onPressed: () => ref.invalidate(orderLinesProvider(orderId)),
                child: const Text('Qayta'),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Buyurtma tarkibi',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 13,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 6),
            for (final l in list)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${l.quantity}×',
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: AppColors.dark,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14.5,
                        ),
                      ),
                    ),
                    Text(
                      formatSom(l.total),
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
