import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/utils/phone.dart';
import '../../core/widgets/app_map.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/order_lines_view.dart';
import '../../core/widgets/ui.dart';
import '../../models/food_order.dart';
import '../delivery/delivery_providers.dart';

/// Taxtadagi ustunlar.
enum BoardColumn {
  fresh('Yangi', {OrderStatus.pending}),
  processing('Jarayonda', {OrderStatus.accepted, OrderStatus.preparing}),
  dispatch('Topshirishda', {
    OrderStatus.readyForPickup,
    OrderStatus.courierAssigned,
    OrderStatus.pickedUp,
    OrderStatus.onTheWay,
  });

  const BoardColumn(this.title, this.statuses);

  final String title;
  final Set<OrderStatus> statuses;

  List<FoodOrder> pick(List<FoodOrder> orders) {
    final list = orders.where((o) => statuses.contains(o.status)).toList();
    // Eng uzoq kutayotgan buyurtma tepada.
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }
}

/// Kutish vaqtiga qarab tugma rangi: yashil → sariq → qizil.
Color urgencyColor(Duration waiting) {
  if (waiting.inMinutes >= 10) return AppColors.error;
  if (waiting.inMinutes >= 4) return AppColors.warning;
  return AppColors.success;
}

String waitingText(Duration d) {
  if (d.inMinutes < 1) return 'hozirgina';
  if (d.inMinutes < 60) return '${d.inMinutes} daq oldin';
  if (d.inHours < 24) return '${d.inHours} soat oldin';
  return '${d.inDays} kun oldin';
}

/// Restoran va magazin uchun buyurtmalar taxtasi.
class OrderBoard extends ConsumerStatefulWidget {
  const OrderBoard({super.key, required this.restaurantId, required this.isShop});

  final String restaurantId;
  final bool isShop;

  @override
  ConsumerState<OrderBoard> createState() => _OrderBoardState();
}

class _OrderBoardState extends ConsumerState<OrderBoard> {
  late final Timer _clock;
  final _busy = <String>{};

  @override
  void initState() {
    super.initState();
    // "N daqiqa oldin" yozuvlari va ranglar yangilanib turadi.
    _clock = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clock.cancel();
    super.dispose();
  }

  Future<void> _setStatus(FoodOrder order, OrderStatus status) async {
    if (status == OrderStatus.rejected) {
      final sure = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Buyurtmani rad etasizmi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Yo'q"),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: TextButton.styleFrom(foregroundColor: AppColors.error),
              child: const Text('Rad etish'),
            ),
          ],
        ),
      );
      if (sure != true || !mounted) return;
    }
    setState(() => _busy.add(order.id));
    try {
      await ref.read(deliveryRepositoryProvider).setStatus(order.id, status);
      ref.invalidate(restaurantOrdersProvider(widget.restaurantId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy.remove(order.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = restaurantOrdersProvider(widget.restaurantId);
    return ref
        .watch(provider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(provider),
          ),
          data: _board,
        );
  }

  Widget _board(List<FoodOrder> orders) {
    final now = DateTime.now();
    Widget list(BoardColumn column, List<FoodOrder> items) => items.isEmpty
        ? const Center(
            child: Text(
              "Buyurtma yo'q",
              style: TextStyle(color: AppColors.grey),
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            itemBuilder: (_, i) => _OrderCard(
              key: ValueKey(items[i].id),
              order: items[i],
              waiting: now.difference(items[i].createdAt),
              busy: _busy.contains(items[i].id),
              isShop: widget.isShop,
              onStatus: (s) => _setStatus(items[i], s),
            ),
          );

    final columns = {for (final c in BoardColumn.values) c: c.pick(orders)};

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= 800) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final e in columns.entries)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSurfaceElevated
                            : AppColors.primarySoft.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
                            child: Row(
                              children: [
                                Text(
                                  e.key.title.toUpperCase(),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AppColors.primary,
                                  child: Text(
                                    '${e.value.length}',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(child: list(e.key, e.value)),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        }
        return DefaultTabController(
          length: columns.length,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  for (final e in columns.entries)
                    Tab(text: '${e.key.title} (${e.value.length})'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    for (final e in columns.entries) list(e.key, e.value),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    super.key,
    required this.order,
    required this.waiting,
    required this.busy,
    required this.isShop,
    required this.onStatus,
  });

  final FoodOrder order;
  final Duration waiting;
  final bool busy;
  final bool isShop;
  final void Function(OrderStatus) onStatus;

  @override
  Widget build(BuildContext context) {
    final o = order;
    final (String, OrderStatus)? next = switch (o.status) {
      OrderStatus.pending => ('Qabul qilish', OrderStatus.accepted),
      OrderStatus.accepted => (
        isShop ? "Yig'ishni boshlash" : 'Tayyorlashni boshlash',
        OrderStatus.preparing,
      ),
      OrderStatus.preparing => ('Kuryerga tayyor', OrderStatus.readyForPickup),
      _ => null,
    };

    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      onTap: () => _showDetails(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '#${o.id.substring(0, 8)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
              Text(
                waitingText(waiting),
                style: const TextStyle(fontSize: 12, color: AppColors.grey),
              ),
            ],
          ),
          const SizedBox(height: 6),
          OrderLinesView(orderId: o.id),
          const SizedBox(height: 6),
          Text(
            formatSom(o.total),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (o.note != null && o.note!.trim().isNotEmpty)
            Text(
              'Izoh: ${o.note}',
              style: const TextStyle(fontSize: 12, color: AppColors.warning),
            ),
          const SizedBox(height: 8),
          if (next == null)
            StatusPill(o.status.label, color: AppColors.primary)
          else
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: busy ? null : () => onStatus(next.$2),
                    style: FilledButton.styleFrom(
                      backgroundColor: o.status == OrderStatus.pending
                          ? urgencyColor(waiting)
                          : AppColors.primary,
                    ),
                    child: busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(next.$1, textAlign: TextAlign.center),
                  ),
                ),
                if (o.status == OrderStatus.pending) ...[
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    tooltip: 'Rad etish',
                    onPressed: busy
                        ? null
                        : () => onStatus(OrderStatus.rejected),
                    style: IconButton.styleFrom(
                      foregroundColor: AppColors.error,
                    ),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  void _showDetails(BuildContext context) {
    final o = order;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (ctx) => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Buyurtma #${o.id.substring(0, 8)}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            Text(
              DateFormat('dd.MM.yyyy HH:mm').format(o.createdAt),
              style: const TextStyle(color: AppColors.grey),
            ),
            const SizedBox(height: 10),
            StatusPill(o.status.label, color: AppColors.primary),
            const SizedBox(height: 12),
            OrderLinesView(orderId: o.id),
            const Divider(height: 24),
            Text('Jami: ${formatSom(o.total)}'),
            const SizedBox(height: 8),
            Text('Manzil: ${o.addressText}'),
            if (o.note != null && o.note!.isNotEmpty) Text('Izoh: ${o.note}'),
            TextButton.icon(
              onPressed: () => callPhone(context, o.phone),
              icon: const Icon(Icons.phone_rounded),
              label: Text(o.phone),
            ),
            if (o.destination != null)
              AppMap(
                points: [
                  if (o.restaurantLocation != null)
                    MapPoint(
                      point: o.restaurantLocation!,
                      icon: Icons.storefront_rounded,
                      color: AppColors.primary,
                    ),
                  MapPoint(
                    point: o.destination!,
                    icon: Icons.home_rounded,
                    color: AppColors.accentRed,
                  ),
                ],
                zoom: 13,
                height: 180,
                interactive: false,
              ),
          ],
        ),
      ),
    );
  }
}
