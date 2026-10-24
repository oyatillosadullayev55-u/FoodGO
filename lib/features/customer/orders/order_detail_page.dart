import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/error_view.dart';
import '../../../models/food_order.dart';
import 'orders_page.dart';
import 'orders_providers.dart';

const _flow = [
  OrderStatus.pending,
  OrderStatus.accepted,
  OrderStatus.preparing,
  OrderStatus.readyForPickup,
  OrderStatus.courierAssigned,
  OrderStatus.pickedUp,
  OrderStatus.onTheWay,
  OrderStatus.delivered,
];

class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buyurtmani bekor qilasizmi?'),
        content: const Text('Buyurtma bekor qilinsa, restoranga xabar yuboriladi.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Yo'q"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Bekor qilish'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ref.read(ordersRepositoryProvider).cancelOrder(orderId);
      ref.invalidate(orderProvider(orderId));
      ref.invalidate(ordersProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider(orderId));
    final lines = ref.watch(orderLinesProvider(orderId));
    final live = ref.watch(orderStatusProvider(orderId)).maybeWhen(
      data: (s) => s,
      orElse: () => null,
    );
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buyurtma holati', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: order.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryDark),
        ),
        error: (e, _) => ErrorView(
          message: friendlyError(e),
          onRetry: () => ref.invalidate(orderProvider(orderId)),
        ),
        data: (o) {
          final status = live ?? o.status;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
            children: [
              // 1. Yandex Go Live Kuzatuv Kartasi
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: isDark ? Colors.white10 : AppColors.borderLight,
                    width: 0.8,
                  ),
                  boxShadow: [
                    if (!isDark)
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                o.restaurantName ?? 'Restoran',
                                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Buyurtma raqami: #${o.id.substring(0, 8)}',
                                style: const TextStyle(color: AppColors.grey, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        StatusChip(status: status),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (status.isFailed)
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.cancel_rounded, color: AppColors.error),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                status.label,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // Yandex uslubidagi vizual bosqichlar
                      _YandexStatusTracker(current: status),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 2. Kuryer ma'lumotlari (agar tayinlangan bo'lsa)
              if (status == OrderStatus.courierAssigned ||
                  status == OrderStatus.pickedUp ||
                  status == OrderStatus.onTheWay)
                Container(
                  margin: const EdgeInsets.only(bottom: 18),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? Colors.white10 : AppColors.borderLight,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(Icons.delivery_dining_rounded, color: AppColors.dark, size: 28),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Yandex Go Kuryer',
                              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Taomni tezkor yetkazib bermoqda',
                              style: TextStyle(color: AppColors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      IconButton.filled(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.dark,
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Kuryer bilan bog\'lanish')),
                          );
                        },
                        icon: const Icon(Icons.phone_rounded, size: 20),
                      ),
                    ],
                  ),
                ),

              // 3. Taomlar ro'yxati
              _section(context, 'Buyurtma tarkibi'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white10 : AppColors.borderLight,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    lines.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(12),
                        child: Center(
                          child: CircularProgressIndicator(color: AppColors.primaryDark),
                        ),
                      ),
                      error: (e, _) => Text(friendlyError(e)),
                      data: (list) => Column(
                        children: [
                          for (final l in list)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${l.quantity} × ${l.name}',
                                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    formatSom(l.total),
                                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    _row('Taomlar summasi', formatSom(o.subtotal)),
                    const SizedBox(height: 6),
                    _row('Yetkazib berish', formatSom(o.deliveryFee)),
                    const Divider(height: 20),
                    _row('Jami to\'lov', formatSom(o.total), bold: true),
                  ],
                ),
              ),
              const SizedBox(height: 18),

              // 4. Manzil va Ma'lumotlar
              _section(context, 'Yetkazish ma\'lumotlari'),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.white10 : AppColors.borderLight,
                    width: 0.8,
                  ),
                ),
                child: Column(
                  children: [
                    _info(Icons.location_on_rounded, o.addressText),
                    const SizedBox(height: 10),
                    _info(Icons.phone_rounded, o.phone),
                    if (o.note != null && o.note!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      _info(Icons.comment_rounded, o.note!),
                    ],
                  ],
                ),
              ),

              if (status.isCancellable) ...[
                const SizedBox(height: 22),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(52),
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error, width: 1.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _cancel(context, ref),
                  child: const Text('Buyurtmani bekor qilish', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _section(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800, fontSize: 17),
      ),
    );
  }

  Widget _info(IconData icon, String text) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primarySoft,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.dark),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
          ),
        ),
      ],
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
      fontSize: bold ? 17 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}

// ===== Yandex Uslubidagi Status Tracker =====
class _YandexStatusTracker extends StatelessWidget {
  const _YandexStatusTracker({required this.current});

  final OrderStatus current;

  @override
  Widget build(BuildContext context) {
    final currentIndex = _flow.indexOf(current);

    return Column(
      children: [
        for (var i = 0; i < _flow.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: i <= currentIndex ? AppColors.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: i <= currentIndex ? AppColors.primary : AppColors.grey.withValues(alpha: 0.4),
                      width: 2,
                    ),
                  ),
                  child: i <= currentIndex
                      ? const Icon(Icons.check, size: 14, color: AppColors.dark)
                      : null,
                ),
                const SizedBox(width: 12),
                Text(
                  _flow[i].label,
                  style: TextStyle(
                    fontWeight: i == currentIndex ? FontWeight.w900 : FontWeight.w600,
                    color: i <= currentIndex ? AppColors.dark : AppColors.grey,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}