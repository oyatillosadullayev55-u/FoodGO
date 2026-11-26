import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/phone.dart';
import '../../../core/utils/route_estimate.dart';
import '../../../core/widgets/app_map.dart';
import '../../../core/widgets/content_frame.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/ui.dart';
import '../../../models/food_order.dart';
import '../../../models/marketplace.dart';
import '../../marketplace/marketplace_providers.dart';
import '../support/feedback_dialogs.dart';
import 'orders_providers.dart';

/// Buyurtmani jonli kuzatish: xarita, kuryer va bosqichlar.
class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId});

  final String orderId;

  Future<void> _cancel(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Buyurtmani bekor qilasizmi?'),
        content: const Text(
          'Buyurtma bekor qilinsa, sotuvchiga xabar yuboriladi.',
        ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider(orderId));
    final lines = ref.watch(orderLinesProvider(orderId));
    final live = ref
        .watch(orderStatusProvider(orderId))
        .maybeWhen(data: (s) => s, orElse: () => null);

    return Scaffold(
      appBar: AppBar(title: const Text('Yetkazib berish')),
      body: ContentFrame(
        maxWidth: 820,
        child: order.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(orderProvider(orderId)),
          ),
          data: (o) {
            final status = live ?? o.status;
            // Kuryer faqat tayinlangandan keyin so'raladi.
            final hasCourier = const {
              OrderStatus.courierAssigned,
              OrderStatus.pickedUp,
              OrderStatus.onTheWay,
            }.contains(status);
            final courier = hasCourier
                ? ref.watch(orderCourierProvider(orderId)).asData?.value
                : null;

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                _TrackingMap(order: o, courier: courier),
                _StatusCard(order: o, status: status, courier: courier),
                const SizedBox(height: 18),
                const SectionHeader('Buyurtma tarkibi'),
                const SizedBox(height: 8),
                SoftCard(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              o.restaurantName ?? "Do'kon",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          Text(
                            '#${o.id.substring(0, 8)}',
                            style: const TextStyle(
                              color: AppColors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      lines.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(),
                        ),
                        error: (e, _) => Text(friendlyError(e)),
                        data: (list) => Column(
                          children: [
                            for (final l in list)
                              _PriceRow(
                                '${l.quantity} × ${l.name}',
                                formatSom(l.total),
                              ),
                          ],
                        ),
                      ),
                      const Divider(height: 24),
                      _PriceRow('Mahsulotlar summasi', formatSom(o.subtotal)),
                      _PriceRow('Yetkazib berish', formatSom(o.deliveryFee)),
                      const Divider(height: 20),
                      _PriceRow("Jami to'lov", formatSom(o.total), bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                const SectionHeader("Yetkazish ma'lumotlari"),
                const SizedBox(height: 8),
                SoftCard(
                  child: Column(
                    children: [
                      _InfoRow(Icons.location_on_rounded, o.addressText),
                      _InfoRow(Icons.phone_rounded, o.phone),
                      if (o.note != null && o.note!.isNotEmpty)
                        _InfoRow(Icons.comment_rounded, o.note!),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                if (status == OrderStatus.delivered)
                  ElevatedButton.icon(
                    onPressed: () => showReviewDialog(context, orderId: o.id),
                    icon: const Icon(Icons.star_rounded),
                    label: const Text('Baholash'),
                  ),
                if (status.isCancellable)
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    onPressed: () => _cancel(context, ref),
                    child: const Text('Buyurtmani bekor qilish'),
                  ),
                TextButton.icon(
                  onPressed: () => showComplaintDialog(context, orderId: o.id),
                  icon: const Icon(Icons.report_problem_outlined, size: 18),
                  label: const Text('Muammo haqida xabar berish'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

LatLng? _courierPoint(OrderCourier? c) =>
    (c?.lat != null && c?.lng != null) ? LatLng(c!.lat!, c.lng!) : null;

class _TrackingMap extends StatelessWidget {
  const _TrackingMap({required this.order, required this.courier});

  final FoodOrder order;
  final OrderCourier? courier;

  @override
  Widget build(BuildContext context) {
    final from = _courierPoint(courier) ?? order.restaurantLocation;
    final to = order.destination;
    if (from == null && to == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: AppMap(
        // Kuryer joylashuvi paydo bo'lsa, xarita qayta markazlanadi.
        key: ValueKey(_courierPoint(courier) != null),
        center: (from != null && to != null)
            ? LatLng(
                (from.latitude + to.latitude) / 2,
                (from.longitude + to.longitude) / 2,
              )
            : from ?? to,
        zoom: 13,
        height: 250,
        route: [?from, ?to],
        points: [
          if (from != null)
            MapPoint(
              point: from,
              icon: _courierPoint(courier) != null
                  ? Icons.delivery_dining_rounded
                  : Icons.storefront_rounded,
              color: AppColors.primary,
            ),
          if (to != null)
            MapPoint(
              point: to,
              icon: Icons.home_rounded,
              color: AppColors.accentRed,
            ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.order,
    required this.status,
    required this.courier,
  });

  final FoodOrder order;
  final OrderStatus status;
  final OrderCourier? courier;

  @override
  Widget build(BuildContext context) {
    final at = _courierPoint(courier);
    // Taxminiy vaqt faqat kuryer taomni olib ketgach ma'noga ega.
    final onWay =
        status == OrderStatus.pickedUp || status == OrderStatus.onTheWay;
    final eta = (onWay && at != null && order.destination != null)
        ? RouteEstimate.between(at, order.destination!)
        : null;

    return SoftCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: status.isFailed
                    ? AppColors.error.withValues(alpha: 0.12)
                    : AppColors.primarySoft,
                child: Icon(
                  status.isFailed
                      ? Icons.cancel_rounded
                      : Icons.delivery_dining_rounded,
                  color: status.isFailed ? AppColors.error : AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      status.headline,
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    if (eta != null)
                      Text(
                        'Taxminiy yetib borish vaqti: ~${eta.timeText}',
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.grey,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (courier != null) ...[
            const Divider(height: 24),
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.person_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        courier!.fullName ?? 'Kuryer',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      if (courier!.phone != null)
                        Text(
                          courier!.phone!,
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.grey,
                          ),
                        ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: "Kuryerga qo'ng'iroq",
                  onPressed: () => callPhone(context, courier!.phone),
                  icon: const Icon(Icons.phone_rounded),
                ),
              ],
            ),
          ],
          if (!status.isFailed) ...[
            const SizedBox(height: 16),
            TrackingSteps(step: status.trackingStep),
          ],
        ],
      ),
    );
  }
}

/// Gorizontal bosqichlar: Buyurtma → Tayyor → Yo'lda → Yetkazildi.
class TrackingSteps extends StatelessWidget {
  const TrackingSteps({super.key, required this.step});

  static const labels = ['Buyurtma', 'Tayyor', "Yo'lda", 'Yetkazildi'];

  final int step;

  @override
  Widget build(BuildContext context) {
    Widget line(bool visible, bool done) => Expanded(
      child: Container(
        height: 3,
        color: !visible
            ? Colors.transparent
            : (done ? AppColors.primary : AppColors.borderLight),
      ),
    );

    return Row(
      children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: Semantics(
              label: '${labels[i]}${i <= step ? ', bajarildi' : ''}',
              excludeSemantics: true,
              child: Column(
                children: [
                  Row(
                    children: [
                      line(i > 0, i <= step),
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i <= step
                              ? AppColors.primary
                              : AppColors.borderLight,
                        ),
                        child: i <= step
                            ? const Icon(
                                Icons.check_rounded,
                                size: 14,
                                color: Colors.white,
                              )
                            : null,
                      ),
                      line(i < labels.length - 1, i < step),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: i == step
                            ? FontWeight.w900
                            : FontWeight.w600,
                        color: i <= step ? null : AppColors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(this.label, this.value, {this.bold = false});

  final String label;
  final String value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
      fontSize: bold ? 16 : 13.5,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          const SizedBox(width: 12),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.text);

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 19, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
