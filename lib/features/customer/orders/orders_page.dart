import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/error_view.dart';
import '../../../models/food_order.dart';
import 'orders_providers.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    if (status == OrderStatus.delivered) {
      bg = AppColors.success.withValues(alpha: 0.12);
      fg = AppColors.success;
    } else if (status.isFailed) {
      bg = AppColors.error.withValues(alpha: 0.12);
      fg = AppColors.error;
    } else {
      bg = AppColors.primary;
      fg = AppColors.dark;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final fmt = DateFormat('dd MMMM, HH:mm');
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyurtmalar', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: orders.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryDark),
        ),
        error: (e, _) => ErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(ordersProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return const EmptyView(
              icon: Icons.receipt_long_rounded,
              title: "Buyurtmalar tarixi bo'sh",
              message: "Restoranlardan taom tanlang, birinchi buyurtmangiz shu yerda aks etadi.",
            );
          }
          return RefreshIndicator(
            color: AppColors.dark,
            backgroundColor: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(ordersProvider);
              try {
                await ref.read(ordersProvider.future);
              } catch (_) {}
            },
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: list.length,
              itemBuilder: (context, i) {
                final o = list[i];
                final isDelivered = o.status == OrderStatus.delivered;
                final isFailed = o.status.isFailed;

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : AppColors.borderLight,
                      width: 0.8,
                    ),
                    boxShadow: [
                      if (!isDark)
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                    ],
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => context.push(AppRoutes.orderPath(o.id)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDelivered
                                      ? AppColors.greyLight
                                      : (isFailed ? AppColors.error.withValues(alpha: 0.1) : AppColors.primary),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.storefront_rounded,
                                  color: isDelivered ? AppColors.dark : (isFailed ? AppColors.error : AppColors.dark),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      o.restaurantName ?? 'Restoran',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      fmt.format(o.createdAt),
                                      style: const TextStyle(color: AppColors.grey, fontSize: 12.5),
                                    ),
                                  ],
                                ),
                              ),
                              StatusChip(status: o.status),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Jami summa',
                                    style: TextStyle(color: AppColors.grey, fontSize: 12),
                                  ),
                                  Text(
                                    formatSom(o.total),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : AppColors.dark,
                                    ),
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  Text(
                                    'Batafsil',
                                    style: TextStyle(
                                      color: isDark ? Colors.white70 : AppColors.dark,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 13,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: AppColors.grey),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}