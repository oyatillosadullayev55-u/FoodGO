import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/earnings.dart';
import '../../core/utils/money.dart';
import '../../core/utils/route_estimate.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/order_lines_view.dart';
import '../../core/widgets/ui.dart';
import '../../models/food_order.dart';
import '../auth/providers/auth_providers.dart';
import '../delivery/delivery_providers.dart';
import '../marketplace/marketplace_providers.dart';
import '../partner/documents_card.dart';
import '../partner/earnings_view.dart';
import '../partner/notifications_button.dart';
import '../partner/partner_scaffold.dart';
import 'courier_location.dart';
import 'courier_map.dart';

class CourierHomePage extends ConsumerStatefulWidget {
  const CourierHomePage({super.key});

  @override
  ConsumerState<CourierHomePage> createState() => _CourierHomePageState();
}

class _CourierHomePageState extends ConsumerState<CourierHomePage> {
  static const _activeStatuses = {
    OrderStatus.courierAssigned,
    OrderStatus.pickedUp,
    OrderStatus.onTheWay,
  };

  String? _busyOrderId;
  Set<String> _seenIds = {};
  bool _firstLoad = true;
  bool _hasActive = false;

  Future<void> _run(String orderId, Future<void> Function() action) async {
    setState(() => _busyOrderId = orderId);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        ref.invalidate(availableOrdersProvider);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _busyOrderId = null);
    }
  }

  Future<void> _claim(FoodOrder o) =>
      _run(o.id, () => ref.read(deliveryRepositoryProvider).claimOrder(o.id));

  Future<void> _setStatus(FoodOrder o, OrderStatus s) => _run(o.id, () async {
    await ref.read(deliveryRepositoryProvider).setStatus(o.id, s);
    if (s == OrderStatus.delivered) ref.invalidate(courierIncomeProvider);
  });

  /// Faol buyurtma paytida joylashuv mijozga ko'rinishi uchun yuboriladi.
  Future<void> _shareLocation(LatLng position) async {
    try {
      await ref
          .read(marketplaceRepositoryProvider)
          .upsertCourierLocation(position.latitude, position.longitude);
    } catch (e) {
      // Tarmoq xatosi yetkazishni to'xtatmaydi, keyingi nuqta yuboriladi.
      debugPrint('Joylashuv yuborilmadi: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(courierPositionProvider);
    final myPos = me.asData?.value;
    final mine = ref.watch(courierOrdersProvider);
    final available = ref.watch(availableOrdersProvider);

    final active = (mine.asData?.value ?? const <FoodOrder>[])
        .where((o) => _activeStatuses.contains(o.status))
        .toList();
    final current = active.isEmpty ? null : active.last;
    _hasActive = current != null;

    ref.listen(courierPositionProvider, (_, next) {
      final position = next.asData?.value;
      if (position != null && _hasActive) _shareLocation(position);
    });
    ref.listen(courierOrdersProvider, (prev, next) {
      bool busy(AsyncValue<List<FoodOrder>>? v) =>
          v?.asData?.value.any((o) => _activeStatuses.contains(o.status)) ??
          false;
      final position = ref.read(courierPositionProvider).asData?.value;
      // Buyurtma olingan zahoti birinchi nuqtani yuboramiz.
      if (!busy(prev) && busy(next) && position != null) {
        _shareLocation(position);
      }
    });

    ref.listen<AsyncValue<List<FoodOrder>>>(availableOrdersProvider, (prev, next) {
      final list = next.asData?.value;
      if (list == null) return;
      final ids = list.map((o) => o.id).toSet();
      if (!_firstLoad && !_hasActive && ids.difference(_seenIds).isNotEmpty) {
        HapticFeedback.heavyImpact();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Yangi buyurtma tushdi!')),
        );
      }
      _seenIds = ids;
      _firstLoad = false;
    });

    final LatLng? target = current == null
        ? null
        : (current.status == OrderStatus.courierAssigned
            ? current.restaurantLocation
            : current.destination);

    final Widget panel;
    if (current != null) {
      panel = _ActivePanel(
        order: current,
        me: myPos,
        busy: _busyOrderId == current.id,
        onNext: (s) => _setStatus(current, s),
      );
    } else {
      panel = available.when(
        loading: () => const _Sheet(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
        error: (e, _) => _Sheet(
          child: ErrorView(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(availableOrdersProvider),
          ),
        ),
        data: (orders) => orders.isEmpty
            ? const _WaitingPanel()
            : _AvailablePanel(
                orders: orders,
                me: myPos,
                busyOrderId: _busyOrderId,
                onClaim: _claim,
              ),
      );
    }

    final tasks = Column(
      children: [
        if (me.hasError)
          _LocationBanner(
            error: me.error!,
            onRetry: () => ref.invalidate(courierPositionProvider),
          ),
        const _TodayHeader(),
        Expanded(
          child: CourierMap(
            me: myPos,
            restaurant: current?.restaurantLocation,
            customer: current?.destination,
            target: target,
          ),
        ),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.45,
          ),
          child: panel,
        ),
      ],
    );

    return PartnerScaffold(
      title: 'Kuryer',
      actions: const [NotificationsButton()],
      tabs: [
        (
          icon: Icons.delivery_dining_rounded,
          label: 'Vazifalar',
          badge: current == null
              ? (available.asData?.value.length ?? 0)
              : 0,
          view: tasks,
        ),
        (
          icon: Icons.bar_chart_rounded,
          label: 'Daromad',
          badge: 0,
          view: const _IncomeTab(),
        ),
        (
          icon: Icons.person_rounded,
          label: 'Profil',
          badge: 0,
          view: const _ProfileTab(),
        ),
      ],
    );
  }
}

/// Bugungi daromad (yetkazib berish haqlari yig'indisi).
class _TodayHeader extends ConsumerWidget {
  const _TodayHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(courierIncomeProvider).asData?.value;
    if (orders == null) return const SizedBox.shrink();
    final summary = EarningsSummary.from(
      [for (final o in orders) (at: o.createdAt, amount: o.deliveryFee)],
      now: DateTime.now(),
    );
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(gradient: AppColors.brandGradient),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bugungi daromad',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                Text(
                  formatSom(summary.today),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${summary.todayCount} ta yetkazildi',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _IncomeTab extends ConsumerWidget {
  const _IncomeTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(courierIncomeProvider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(courierIncomeProvider),
          ),
          data: (orders) => EarningsView(
            countLabel: 'ta yetkazish',
            onRefresh: () => ref.refresh(courierIncomeProvider.future),
            entries: [
              for (final o in orders)
                (
                  title: o.restaurantName ?? 'Buyurtma',
                  subtitle: o.addressText,
                  at: o.createdAt,
                  amount: o.deliveryFee,
                ),
            ],
          ),
        );
  }
}

class _ProfileTab extends ConsumerWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(profileProvider).asData?.value;
    return ContentFrame(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SoftCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.person_rounded, color: Colors.white),
              ),
              title: Text(profile?.fullName ?? 'Kuryer'),
              subtitle: Text(profile?.phone ?? profile?.email ?? ''),
            ),
          ),
          const SizedBox(height: 14),
          const DocumentsCard(),
          const SizedBox(height: 14),
          TextButton.icon(
            onPressed: () => signOut(context, ref),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Hisobdan chiqish'),
          ),
        ],
      ),
    );
  }
}

class _Sheet extends StatelessWidget {
  const _Sheet({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SizedBox(
      width: double.infinity,
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        elevation: 10,
        shadowColor: Colors.black38,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: child,
          ),
        ),
      ),
    );
  }
}

class _WaitingPanel extends StatelessWidget {
  const _WaitingPanel();

  @override
  Widget build(BuildContext context) {
    return const _Sheet(
      child: Column(
        children: [
          Icon(Icons.hourglass_top_rounded, size: 34, color: AppColors.primaryDark),
          SizedBox(height: 8),
          Text('Buyurtma kutilmoqda', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
          SizedBox(height: 4),
          Text(
            'Restoran buyurtmani tayyor qilishi bilan shu yerda paydo bo\'ladi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20, color: AppColors.primaryDark),
        const SizedBox(width: 6),
        Text(text, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
      ],
    );
  }
}

class _AvailablePanel extends StatelessWidget {
  const _AvailablePanel({
    required this.orders,
    required this.me,
    required this.busyOrderId,
    required this.onClaim,
  });

  final List<FoodOrder> orders;
  final LatLng? me;
  final String? busyOrderId;
  final Future<void> Function(FoodOrder) onClaim;

  double _distance(FoodOrder o) {
    final r = o.restaurantLocation;
    if (me == null || r == null) return double.infinity;
    return RouteEstimate.between(me!, r).meters;
  }

  @override
  Widget build(BuildContext context) {
    final sorted = [...orders];
    if (me != null) sorted.sort((a, b) => _distance(a).compareTo(_distance(b)));

    return _Sheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Yangi buyurtmalar (${sorted.length})',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
          ),
          const SizedBox(height: 10),
          for (final o in sorted) ...[
            _AvailableCard(
              order: o,
              me: me,
              busy: busyOrderId == o.id,
              onClaim: () => onClaim(o),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _AvailableCard extends StatelessWidget {
  const _AvailableCard({
    required this.order,
    required this.me,
    required this.busy,
    required this.onClaim,
  });

  final FoodOrder order;
  final LatLng? me;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final r = order.restaurantLocation;
    final c = order.destination;
    final toRest = (me != null && r != null) ? RouteEstimate.between(me!, r) : null;
    final trip = (r != null && c != null) ? RouteEstimate.between(r, c) : null;
    final total = (toRest != null && trip != null) ? toRest + trip : null;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            order.restaurantName ?? 'Restoran',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          if (order.restaurantAddress != null)
            Text(
              order.restaurantAddress!,
              style: const TextStyle(color: AppColors.grey, fontSize: 12.5),
            ),
          const SizedBox(height: 8),
          if (toRest != null)
            Text('Restoranga: ${toRest.distanceText} · ~${toRest.timeText}',
                style: const TextStyle(fontSize: 13.5)),
          if (trip != null)
            Text('Mijozgacha: ${trip.distanceText} · ~${trip.timeText}',
                style: const TextStyle(fontSize: 13.5)),
          if (total != null)
            Text(
              'Jami: ${total.distanceText} · ~${total.timeText}',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
            ),
          if (c == null)
            const Text(
              'Mijoz joylashuvi xaritada belgilanmagan',
              style: TextStyle(color: AppColors.error, fontSize: 12.5),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Naqd: ${formatSom(order.total)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
                ),
              ),
              FilledButton(
                onPressed: busy ? null : onClaim,
                child: busy
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Qabul qilish'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivePanel extends StatelessWidget {
  const _ActivePanel({
    required this.order,
    required this.me,
    required this.busy,
    required this.onNext,
  });

  final FoodOrder order;
  final LatLng? me;
  final bool busy;
  final void Function(OrderStatus) onNext;

  @override
  Widget build(BuildContext context) {
    final toRestaurant = order.status == OrderStatus.courierAssigned;
    final target = toRestaurant ? order.restaurantLocation : order.destination;

    final next = switch (order.status) {
      OrderStatus.courierAssigned => OrderStatus.pickedUp,
      OrderStatus.pickedUp => OrderStatus.onTheWay,
      _ => OrderStatus.delivered,
    };
    final label = switch (next) {
      OrderStatus.pickedUp => 'Olib ketdim',
      OrderStatus.onTheWay => "Yo'lga chiqdim",
      _ => 'Yetkazib berdim',
    };

    final toTarget = (me != null && target != null) ? RouteEstimate.between(me!, target) : null;
    final afterPickup = (toRestaurant && order.restaurantLocation != null && order.destination != null)
        ? RouteEstimate.between(order.restaurantLocation!, order.destination!)
        : null;

    return _Sheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            toRestaurant ? 'Restoranga boring' : 'Mijozga yetkazing',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            toRestaurant ? (order.restaurantName ?? 'Restoran') : 'Mijoz',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 19),
          ),
          Text(
            toRestaurant ? (order.restaurantAddress ?? '') : order.addressText,
            style: const TextStyle(color: AppColors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),
          if (toTarget != null)
            Wrap(
              spacing: 20,
              runSpacing: 6,
              children: [
                _Metric(icon: Icons.straighten_rounded, text: toTarget.distanceText),
                _Metric(icon: Icons.schedule_rounded, text: '~${toTarget.timeText}'),
              ],
            )
          else
            Text(
              me == null
                  ? 'Joylashuvingiz aniqlanmoqda...'
                  : 'Manzil xaritada belgilanmagan',
              style: const TextStyle(color: AppColors.grey),
            ),
          if (afterPickup != null) ...[
            const SizedBox(height: 6),
            Text(
              'Keyin mijozgacha: ${afterPickup.distanceText} · ~${afterPickup.timeText}',
              style: const TextStyle(color: AppColors.grey, fontSize: 13),
            ),
          ],
          if (!toRestaurant) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone_rounded, size: 16, color: AppColors.grey),
                const SizedBox(width: 6),
                SelectableText(order.phone, style: const TextStyle(fontSize: 14)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Mijozdan naqd: ${formatSom(order.total)}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
          ),
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text(
                'Buyurtma tarkibi',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              children: [OrderLinesView(orderId: order.id)],
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : () => onNext(next),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(label, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _LocationBanner extends StatelessWidget {
  const _LocationBanner({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final p = error is LocationProblem ? error as LocationProblem : null;

    return Material(
      color: AppColors.error.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.location_off_rounded, color: AppColors.error, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                p?.message ?? "Joylashuvni aniqlab bo'lmadi",
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
            if (p?.serviceOff == true)
              TextButton(
                onPressed: Geolocator.openLocationSettings,
                child: const Text('GPS'),
              ),
            if (p?.canOpenSettings == true)
              TextButton(
                onPressed: Geolocator.openAppSettings,
                child: const Text('Sozlamalar'),
              ),
            IconButton(
              tooltip: 'Qayta urinish',
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
            ),
          ],
        ),
      ),
    );
  }
}
