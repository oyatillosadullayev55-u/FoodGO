import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/food_order.dart';
import '../../models/restaurant.dart';
import '../../repositories/admin_repository.dart';
import '../auth/data/user_profile.dart';
import '../auth/providers/auth_providers.dart';

final adminRepositoryProvider = Provider<AdminRepository>(
  (ref) => AdminRepository(ref.watch(supabaseProvider)),
);

final adminRestaurantsProvider = FutureProvider.autoDispose<List<Restaurant>>(
  (ref) => ref.watch(adminRepositoryProvider).fetchRestaurants(),
);

final adminUsersProvider = FutureProvider.autoDispose<List<UserProfile>>(
  (ref) => ref.watch(adminRepositoryProvider).fetchUsers(),
);

final adminOrdersProvider = FutureProvider.autoDispose<List<FoodOrder>>(
  (ref) => ref.watch(adminRepositoryProvider).fetchOrders(),
);

final adminStatsProvider =
    Provider.autoDispose<({int users, int activeOrders})>((ref) {
      final users = ref.watch(adminUsersProvider).asData?.value.length ?? 0;
      final orders =
          ref.watch(adminOrdersProvider).asData?.value ?? const <FoodOrder>[];
      final active = orders.where((o) => o.status.isActive).length;
      return (users: users, activeOrders: active);
    });
