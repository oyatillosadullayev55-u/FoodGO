import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/food_order.dart';
import '../../models/product.dart';
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

final restaurantOrdersProvider =
    FutureProvider.autoDispose.family<List<FoodOrder>, String>(
  (ref, id) =>
      ref.watch(deliveryRepositoryProvider).fetchRestaurantOrders(id),
);

final availableOrdersProvider = FutureProvider.autoDispose<List<FoodOrder>>(
  (ref) => ref.watch(deliveryRepositoryProvider).fetchAvailableOrders(),
);

final courierOrdersProvider = FutureProvider.autoDispose<List<FoodOrder>>(
  (ref) => ref.watch(deliveryRepositoryProvider).fetchCourierOrders(),
);
