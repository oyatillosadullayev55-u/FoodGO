import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product.dart';
import '../../../models/restaurant.dart';
import '../../../repositories/menu_repository.dart';
import '../../auth/providers/auth_providers.dart';

final menuRepositoryProvider = Provider<MenuRepository>(
      (ref) => MenuRepository(ref.watch(supabaseProvider)),
);

final restaurantProvider =
FutureProvider.autoDispose.family<Restaurant, String>(
      (ref, id) => ref.watch(menuRepositoryProvider).fetchRestaurant(id),
);

final productsProvider =
FutureProvider.autoDispose.family<List<Product>, String>(
      (ref, restaurantId) =>
      ref.watch(menuRepositoryProvider).fetchProducts(restaurantId),
);