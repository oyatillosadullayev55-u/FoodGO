import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/error_mapper.dart';
import '../../models/food_category.dart';
import '../../models/marketplace.dart';
import '../../models/restaurant.dart';
import '../../repositories/marketplace_repository.dart';
import '../auth/providers/auth_providers.dart';
import '../customer/home/home_providers.dart';

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>(
  (ref) => MarketplaceRepository(ref.watch(supabaseProvider)),
);

/// super_app.sql hali ishga tushirilmagan bo'lsa ham bosh sahifa ishlaydi.
const kDefaultServices = <ServiceModule>[
  ServiceModule(
    code: 'food',
    title: 'Restoranlar',
    subtitle: 'Ovqat',
    icon: 'food',
    route: '/customer/home/restaurants',
  ),
  ServiceModule(
    code: 'master',
    title: 'Ustalar',
    subtitle: 'Xizmatlar',
    icon: 'master',
    route: '/customer/home/masters',
  ),
  ServiceModule(
    code: 'shop',
    title: 'Magazinlar',
    subtitle: "Do'konlar",
    icon: 'shop',
    route: '/customer/home/shops',
  ),
  ServiceModule(
    code: 'product',
    title: 'Mahsulotlar',
    subtitle: 'Buyurtma',
    icon: 'product',
    route: '/customer/home/products',
  ),
  ServiceModule(
    code: 'delivery',
    title: 'Yetkazib berish',
    subtitle: 'Kuryer',
    icon: 'delivery',
    route: '/customer/home/delivery',
  ),
  ServiceModule(
    code: 'other',
    title: 'Boshqa',
    subtitle: 'Xizmatlar',
    icon: 'apps',
    route: '/customer/home/services',
  ),
];

final servicesProvider = FutureProvider.autoDispose<List<ServiceModule>>((
  ref,
) async {
  try {
    return await ref.watch(marketplaceRepositoryProvider).fetchServices();
  } catch (e) {
    if (isMissingSchema(e)) return kDefaultServices;
    rethrow;
  }
});

final promotionsProvider = FutureProvider.autoDispose<List<Promotion>>(
  (ref) => ref.watch(marketplaceRepositoryProvider).fetchPromotions(),
);

final regionsProvider = FutureProvider.autoDispose<List<Region>>(
  (ref) => ref.watch(marketplaceRepositoryProvider).fetchRegions(),
);

final categoriesByKindProvider = FutureProvider.autoDispose
    .family<List<FoodCategory>, String>((ref, kind) async {
      final catalog = ref.watch(catalogRepositoryProvider);
      try {
        return await ref
            .watch(marketplaceRepositoryProvider)
            .fetchCategories(kind);
      } catch (e) {
        // Eski bazada kategoriya turi yo'q: hammasi taom kategoriyasi.
        if (kind == 'food' && isMissingSchema(e)) {
          return catalog.fetchCategories();
        }
        rethrow;
      }
    });

/// Restoran yoki magazinlar ro'yxati.
final storesProvider = FutureProvider.autoDispose
    .family<List<Restaurant>, ({String kind, String? categoryId})>(
      (ref, args) => ref
          .watch(catalogRepositoryProvider)
          .fetchRestaurants(kind: args.kind, categoryId: args.categoryId),
    );

final shopProductsProvider = FutureProvider.autoDispose
    .family<List<StoreProduct>, String?>(
      (ref, categoryId) => ref
          .watch(marketplaceRepositoryProvider)
          .fetchShopProducts(categoryId: categoryId),
    );

final mastersProvider = FutureProvider.autoDispose
    .family<List<Master>, String?>(
      (ref, categoryId) => ref
          .watch(marketplaceRepositoryProvider)
          .fetchMasters(categoryId: categoryId),
    );

final masterProvider = FutureProvider.autoDispose.family<Master, String>(
  (ref, id) => ref.watch(marketplaceRepositoryProvider).fetchMaster(id),
);

final masterReviewsProvider = FutureProvider.autoDispose
    .family<List<Review>, String>(
      (ref, id) =>
          ref.watch(marketplaceRepositoryProvider).fetchMasterReviews(id),
    );

final myServiceRequestsProvider =
    StreamProvider.autoDispose<List<ServiceRequest>>(
      (ref) => ref.watch(marketplaceRepositoryProvider).watchMyRequests(),
    );

final notificationsProvider =
    FutureProvider.autoDispose<List<AppNotification>>(
      (ref) => ref.watch(marketplaceRepositoryProvider).fetchNotifications(),
    );

/// Kuryer joylashuvi: har 10 soniyada yangilanadi.
final orderCourierProvider = StreamProvider.autoDispose
    .family<OrderCourier?, String>((ref, orderId) async* {
      final repo = ref.watch(marketplaceRepositoryProvider);
      var alive = true;
      ref.onDispose(() => alive = false);
      while (alive) {
        yield await repo.fetchOrderCourier(orderId);
        await Future<void>.delayed(const Duration(seconds: 10));
      }
    });

// ----- Qurilmada saqlanadigan tanlovlar -----

class _PrefString extends Notifier<String?> {
  _PrefString(this._key);

  final String _key;

  @override
  String? build() {
    _restore();
    return null;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    if (ref.mounted && state == null) state = prefs.getString(_key);
  }

  Future<void> set(String value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, value);
  }
}

/// Foydalanuvchi tanlagan shahar nomi.
final selectedRegionProvider = NotifierProvider<_PrefString, String?>(
  () => _PrefString('region_name'),
);

/// Xabarlar oxirgi marta ochilgan vaqt (ISO 8601).
final notificationsSeenProvider = NotifierProvider<_PrefString, String?>(
  () => _PrefString('notifications_seen_at'),
);

final unreadNotificationsProvider = Provider.autoDispose<int>((ref) {
  final list = ref.watch(notificationsProvider).asData?.value ?? const [];
  final seen = DateTime.tryParse(ref.watch(notificationsSeenProvider) ?? '');
  if (seen == null) return list.length;
  return list.where((n) => n.createdAt.isAfter(seen)).length;
});

class _Favorites extends Notifier<Set<String>> {
  static const _key = 'favorite_stores';

  @override
  Set<String> build() {
    _restore();
    return const {};
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_key);
    if (ref.mounted && saved != null) state = {...state, ...saved};
  }

  Future<void> toggle(String id) async {
    state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state.toList());
  }
}

final favoritesProvider = NotifierProvider<_Favorites, Set<String>>(
  _Favorites.new,
);
