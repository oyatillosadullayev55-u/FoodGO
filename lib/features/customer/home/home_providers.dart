import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/food_category.dart';
import '../../../models/restaurant.dart';
import '../../../repositories/catalog_repository.dart';
import '../../auth/providers/auth_providers.dart';

final catalogRepositoryProvider = Provider<CatalogRepository>(
      (ref) => CatalogRepository(ref.watch(supabaseProvider)),
);

class SelectedCategory extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedCategoryProvider =
NotifierProvider<SelectedCategory, String?>(SelectedCategory.new);

class RestaurantQuery extends Notifier<String> {
  @override
  String build() => '';

  void set(String value) => state = value;
}

final restaurantQueryProvider =
NotifierProvider<RestaurantQuery, String>(RestaurantQuery.new);

final categoriesProvider = FutureProvider.autoDispose<List<FoodCategory>>(
      (ref) => ref.watch(catalogRepositoryProvider).fetchCategories(),
);

final restaurantsProvider = FutureProvider.autoDispose<List<Restaurant>>((ref) {
  final category = ref.watch(selectedCategoryProvider);
  final query = ref.watch(restaurantQueryProvider);
  return ref
      .watch(catalogRepositoryProvider)
      .fetchRestaurants(categoryId: category, query: query);
});