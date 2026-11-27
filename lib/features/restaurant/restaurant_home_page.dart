import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_map.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/ui.dart';
import '../../models/food_order.dart';
import '../../models/restaurant.dart';
import '../delivery/delivery_providers.dart';
import '../partner/documents_card.dart';
import '../partner/earnings_view.dart';
import '../partner/notifications_button.dart';
import '../partner/partner_scaffold.dart';
import 'menu_view.dart';
import 'order_board.dart';
import 'restaurant_profile_page.dart';

/// Restoran va magazin paneli (do'kon turiga qarab moslashadi).
class RestaurantHomePage extends ConsumerStatefulWidget {
  const RestaurantHomePage({super.key});

  @override
  ConsumerState<RestaurantHomePage> createState() => _RestaurantHomePageState();
}

class _RestaurantHomePageState extends ConsumerState<RestaurantHomePage> {
  String? _storeId;

  void _refresh() {
    ref.invalidate(myRestaurantsProvider);
    final id = _storeId;
    if (id != null) {
      ref.invalidate(restaurantProductsProvider(id));
      ref.invalidate(restaurantOrdersProvider(id));
      ref.invalidate(storeIncomeProvider(id));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ref
        .watch(myRestaurantsProvider)
        .when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Scaffold(
            appBar: AppBar(actions: const [SignOutButton()]),
            body: ErrorView(message: friendlyError(e), onRetry: _refresh),
          ),
          data: (stores) {
            if (stores.isEmpty) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Hamkor paneli'),
                  actions: const [SignOutButton()],
                ),
                body: const EmptyView(
                  icon: Icons.storefront_outlined,
                  title: "Sizga biriktirilgan do'kon yo'q",
                  message:
                      'Administrator do\'kon yaratganda egasi sifatida '
                      "hisobingiz emailini ko'rsatishi kerak.",
                ),
              );
            }
            final store = stores.firstWhere(
              (r) => r.id == _storeId,
              orElse: () => stores.first,
            );
            _storeId = store.id;
            return _panel(store, stores);
          },
        );
  }

  Widget _panel(Restaurant store, List<Restaurant> stores) {
    final pending =
        ref
            .watch(restaurantOrdersProvider(store.id))
            .asData
            ?.value
            .where((o) => o.status == OrderStatus.pending)
            .length ??
        0;

    return PartnerScaffold(
      // Boshqa do'kon tanlansa, ichki holatlar qaytadan quriladi.
      key: ValueKey(store.id),
      title: store.name,
      banner: VerificationBanner.of(store.verificationStatus),
      actions: [
        if (stores.length > 1)
          PopupMenuButton<String>(
            tooltip: "Do'konni tanlash",
            icon: const Icon(Icons.swap_horiz_rounded),
            onSelected: (id) => setState(() => _storeId = id),
            itemBuilder: (_) => [
              for (final s in stores)
                PopupMenuItem(value: s.id, child: Text(s.name)),
            ],
          ),
        const NotificationsButton(),
        IconButton(
          tooltip: 'Yangilash',
          onPressed: _refresh,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
      tabs: [
        (
          icon: Icons.receipt_long_rounded,
          label: 'Buyurtmalar',
          badge: pending,
          view: OrderBoard(restaurantId: store.id, isShop: store.isShop),
        ),
        (
          icon: store.isShop
              ? Icons.inventory_2_rounded
              : Icons.restaurant_menu_rounded,
          label: store.isShop ? 'Mahsulotlar' : 'Menyu',
          badge: 0,
          view: MenuView(store: store),
        ),
        (
          icon: Icons.bar_chart_rounded,
          label: 'Daromad',
          badge: 0,
          view: _IncomeTab(storeId: store.id),
        ),
        (
          icon: Icons.store_rounded,
          label: 'Profil',
          badge: 0,
          view: _ProfileTab(store: store),
        ),
      ],
    );
  }
}

class _IncomeTab extends ConsumerWidget {
  const _IncomeTab({required this.storeId});

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = storeIncomeProvider(storeId);
    return ref
        .watch(provider)
        .when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ErrorView(
            message: friendlyError(e),
            onRetry: () => ref.invalidate(provider),
          ),
          data: (orders) {
            final now = DateTime.now();
            return EarningsView(
              onRefresh: () => ref.refresh(provider.future),
              commission: orders
                  .where(
                    (o) =>
                        o.createdAt.year == now.year &&
                        o.createdAt.month == now.month,
                  )
                  .fold(0, (sum, o) => sum + o.commission),
              entries: [
                for (final o in orders)
                  (
                    title: 'Buyurtma #${o.id.substring(0, 8)}',
                    subtitle: o.addressText,
                    at: o.createdAt,
                    // Yetkazib berish haqi do'kon daromadiga kirmaydi.
                    amount: o.subtotal,
                  ),
              ],
            );
          },
        );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({required this.store});

  final Restaurant store;

  @override
  Widget build(BuildContext context) {
    return ContentFrame(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SoftCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        store.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    StatusPill(
                      store.isActive ? 'Ochiq' : 'Yopiq',
                      color: store.isActive
                          ? AppColors.success
                          : AppColors.error,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(store.address ?? "Manzil ko'rsatilmagan"),
                if (store.workingHours != null)
                  Text('Ish vaqti: ${store.workingHours}'),
                const SizedBox(height: 6),
                RatingLine(store.rating, count: store.ratingCount),
                if (store.location != null) ...[
                  const SizedBox(height: 10),
                  AppMap(
                    points: [
                      MapPoint(
                        point: store.location!,
                        icon: Icons.storefront_rounded,
                        color: AppColors.primary,
                      ),
                    ],
                    height: 160,
                    interactive: false,
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RestaurantProfilePage(restaurant: store),
                    ),
                  ),
                  icon: const Icon(Icons.edit_rounded),
                  label: const Text("Ma'lumotlarni tahrirlash"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const DocumentsCard(),
          const SizedBox(height: 14),
          const _SignOutTile(),
        ],
      ),
    );
  }
}

class _SignOutTile extends ConsumerWidget {
  const _SignOutTile();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return TextButton.icon(
      onPressed: () => signOut(context, ref),
      style: TextButton.styleFrom(foregroundColor: AppColors.error),
      icon: const Icon(Icons.logout_rounded),
      label: const Text('Hisobdan chiqish'),
    );
  }
}
