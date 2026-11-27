import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/food_order.dart';
import '../../models/product.dart';
import '../../models/product_category.dart';
import '../../models/restaurant.dart';
import '../../repositories/delivery_repository.dart';
import '../auth/providers/auth_providers.dart';

final deliveryRepositoryProvider = Provider<DeliveryRepository>(
  (ref) => DeliveryRepository(ref.watch(supabaseProvider)),
);

final myRestaurantsProvider = FutureProvider.autoDispose<List<Restaurant>>(
  (ref) => ref.watch(deliveryRepositoryProvider).fetchMyRestaurants(),
);

final restaurantProductsProvider =
    FutureProvider.autoDispose.family<List<Product>, String>(
  (ref, id) => ref.watch(deliveryRepositoryProvider).fetchProducts(id),
);

final categoriesProvider = FutureProvider.autoDispose<List<ProductCategory>>(
  (ref) => ref.watch(deliveryRepositoryProvider).fetchCategories(),
);

final restaurantOrdersProvider = StreamProvider.autoDispose
    .family<List<FoodOrder>, String>((ref, restaurantId) {
  return ref.watch(deliveryRepositoryProvider).watchRestaurantOrders(restaurantId);
});

final storeIncomeProvider = FutureProvider.autoDispose
    .family<List<FoodOrder>, String>((ref, restaurantId) {
      return ref
          .watch(deliveryRepositoryProvider)
          .fetchDelivered(
            column: 'restaurant_id',
            value: restaurantId,
            since: DeliveryRepository.incomeSince(DateTime.now()),
          );
    });

final courierIncomeProvider = FutureProvider.autoDispose<List<FoodOrder>>((
  ref,
) {
  final repo = ref.watch(deliveryRepositoryProvider);
  final uid = repo.currentUserId;
  if (uid == null) return Future.value(const []);
  return repo.fetchDelivered(
    column: 'courier_id',
    value: uid,
    since: DeliveryRepository.incomeSince(DateTime.now()),
  );
});

final availableOrdersProvider = StreamProvider.autoDispose<List<FoodOrder>>(
  (ref) => ref.watch(deliveryRepositoryProvider).watchAvailableOrders(),
);

final courierOrdersProvider = StreamProvider.autoDispose<List<FoodOrder>>(
  (ref) => ref.watch(deliveryRepositoryProvider).watchCourierOrders(),
);
