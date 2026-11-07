import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/app_map.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/order_lines_view.dart';
import '../../models/food_order.dart';
import '../auth/providers/auth_providers.dart';
import '../delivery/delivery_providers.dart';

class CourierHomePage extends ConsumerStatefulWidget {
  const CourierHomePage({super.key});

  @override
  ConsumerState<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends ConsumerState<CourierHomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs = TabController(length: 2, vsync: this);
  String? _busyOrderId;

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _refreshAll() {
    ref.invalidate(availableOrdersProvider);
    ref.invalidate(courierOrdersProvider);
  }

  Future<bool> _run(String orderId, Future<void> Function() action) async {
    setState(() => _busyOrderId = orderId);
    try {
      await action();
      return true;
    } catch (e) {
      if (mounted) {
        ref.invalidate(availableOrdersProvider);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
      return false;
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Future<void> _claim(FoodOrder order) async {
    final ok = await _run(
      order.id,
      () => ref.read(deliveryRepositoryProvider).claimOrder(order.id),
    );
    if (ok && mounted) _tabs.animateTo(1);
  }

  Future<void> _setStatus(FoodOrder order, OrderStatus status) => _run(
        order.id,
        () => ref.read(deliveryRepositoryProvider).setStatus(order.id, status),
      );

  Future<void> _signOut() async {
    await ref.read(pushServiceProvider).unregister();
    await ref.read(authRepositoryProvider).signOut();
    ref.invalidate(profileProvider);
    if (mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kuryer paneli',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [
          IconButton(
            tooltip: 'Yangilash',
            onPressed: _refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Chiqish',
            onPressed: _signOut,
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Yangi buyurtmalar', icon: Icon(Icons.inbox_rounded)),
            Tab(
              text: 'Mening yetkazmalarim',
              icon: Icon(Icons.delivery_dining_rounded),
            ),
          ],
        ),
      ),
      body: ContentFrame(
        maxWidth: 900,
        child: TabBarView(
          controller: _tabs,
          children: [
            _AvailableTab(
              busyOrderId: _busyOrderId,
              onRefresh: _refreshAll,
              onClaim: _claim,
            ),
            _MyDeliveriesTab(
              busyOrderId: _busyOrderId,
              onRefresh: _refreshAll,
              onStatus: _setStatus,
            ),
          ],
        ),
      ),
    );
  }
}

class _AvailableTab extends ConsumerWidget {
  const _AvailableTab({
    required this.busyOrderId,
    required this.onRefresh,
    required this.onClaim,
  });

  final String? busyOrderId;
  final VoidCallback onRefresh;
  final Future<void> Function(FoodOrder) onClaim;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(availableOrdersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        await ref.read(availableOrdersProvider.future);
      },
      child: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            ErrorView(message: friendlyError(e), onRetry: onRefresh),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 60),
                EmptyView(
                  icon: Icons.inbox_rounded,
                  title: 'Hozircha tayyor buyurtma yo\'q',
                  message: 'Restoran buyurtmani tayyor deb belgilagach, u shu yerda paydo bo\'ladi.',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final order = items[index];
              return _OrderCard(
                order: order,
                busy: busyOrderId == order.id,
                actionLabel: 'Buyurtmani olish',
                actionIcon: Icons.pan_tool_alt_rounded,
                onAction: () => onClaim(order),
              );
            },
          );
        },
      ),
    );
  }
}

class _MyDeliveriesTab extends ConsumerWidget {
  const _MyDeliveriesTab({
    required this.busyOrderId,
    required this.onRefresh,
    required this.onStatus,
  });

  final String? busyOrderId;
  final VoidCallback onRefresh;
  final Future<void> Function(FoodOrder, OrderStatus) onStatus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(courierOrdersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        onRefresh();
        await ref.read(courierOrdersProvider.future);
      },
      child: orders.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            ErrorView(message: friendlyError(e), onRetry: onRefresh),
        data: (items) {
          if (items.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 60),
                EmptyView(
                  icon: Icons.delivery_dining_rounded,
                  title: 'Sizda hali yetkazma yo\'q',
                  message: 'Yangi buyurtmalar bo\'limidan buyurtma oling.',
                ),
              ],
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final order = items[index];
              final next = switch (order.status) {
                OrderStatus.courierAssigned => OrderStatus.pickedUp,
                OrderStatus.pickedUp => OrderStatus.onTheWay,
                OrderStatus.onTheWay => OrderStatus.delivered,
                _ => null,
              };
              return _OrderCard(
                order: order,
                busy: busyOrderId == order.id,
                showLines: true,
                actionLabel: switch (next) {
                  OrderStatus.pickedUp => 'Olib ketdim',
                  OrderStatus.onTheWay => 'Yo\'lga chiqdim',
                  OrderStatus.delivered => 'Yetkazib berdim',
                  _ => null,
                },
                actionIcon: switch (next) {
                  OrderStatus.pickedUp => Icons.shopping_bag_rounded,
                  OrderStatus.onTheWay => Icons.two_wheeler_rounded,
                  OrderStatus.delivered => Icons.check_circle_rounded,
                  _ => null,
                },
                onAction: next == null ? null : () => onStatus(order, next),
              );
            },
          );
        },
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.busy,
    this.showLines = false,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
  });

  final FoodOrder order;
  final bool busy;
  final bool showLines;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final points = <MapPoint>[
      if (order.restaurantLocation != null)
        MapPoint(
          point: order.restaurantLocation!,
          icon: Icons.storefront_rounded,
          color: AppColors.primary,
          label: order.restaurantName,
        ),
      if (order.destination != null)
        MapPoint(
          point: order.destination!,
          icon: Icons.home_rounded,
          color: AppColors.dark,
        ),
    ];
    final date = DateFormat('dd.MM.yyyy HH:mm').format(order.createdAt);

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.restaurantName ?? 'Restoran',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                _StatusChip(status: order.status),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              date,
              style: const TextStyle(color: AppColors.grey, fontSize: 12),
            ),
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.storefront_rounded,
              text: order.restaurantAddress ?? 'Restoran manzili',
            ),
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.home_rounded, text: order.addressText),
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.phone_rounded, text: order.phone),
            if (order.note != null && order.note!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              _InfoRow(icon: Icons.sticky_note_2_outlined, text: order.note!),
            ],
            if (showLines) ...[
              const SizedBox(height: 12),
              OrderLinesView(orderId: order.id),
            ],
            if (points.isNotEmpty) ...[
              const SizedBox(height: 12),
              AppMap(points: points, height: 190, interactive: false),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Naqd: ${formatSom(order.total)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
                if (actionLabel != null)
                  ElevatedButton.icon(
                    onPressed: busy ? null : onAction,
                    icon: busy
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(actionIcon, size: 18),
                    label: Text(actionLabel!),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.dark,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.grey),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13.5))),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      OrderStatus.delivered => AppColors.success,
      OrderStatus.cancelled || OrderStatus.rejected => AppColors.error,
      OrderStatus.readyForPickup => AppColors.primaryDark,
      _ => AppColors.accentPurple,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 11.5,
        ),
      ),
    );
  }
}
