import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/food_order.dart';
import '../../../repositories/orders_repository.dart';
import '../../auth/providers/auth_providers.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>(
      (ref) => OrdersRepository(ref.watch(supabaseProvider)),
);

final ordersProvider = FutureProvider.autoDispose<List<FoodOrder>>(
      (ref) => ref.watch(ordersRepositoryProvider).fetchOrders(),
);

final orderProvider = FutureProvider.autoDispose.family<FoodOrder, String>(
      (ref, id) => ref.watch(ordersRepositoryProvider).fetchOrder(id),
);

final orderLinesProvider =
FutureProvider.autoDispose.family<List<OrderLine>, String>(
      (ref, id) => ref.watch(ordersRepositoryProvider).fetchLines(id),
);

final orderStatusProvider =
StreamProvider.autoDispose.family<OrderStatus, String>(
      (ref, id) => ref.watch(ordersRepositoryProvider).watchStatus(id),
);