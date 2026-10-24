import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/food_category.dart';
import '../models/restaurant.dart';

class CatalogRepository {
  CatalogRepository(this._client);

  final SupabaseClient _client;

  Future<List<FoodCategory>> fetchCategories() async {
    final data = await _client.from('categories').select().order('sort_order');
    return data.map(FoodCategory.fromMap).toList();
  }

  /// Kategoriya tanlansa, shu kategoriyada taomi bor restoranlar chiqadi.
  Future<List<Restaurant>> fetchRestaurants({
    String? categoryId,
    String? query,
  }) async {
    final columns = categoryId == null ? '*' : '*, products!inner(category_id)';
    var request = _client.from('restaurants').select(columns);

    if (categoryId != null) {
      request = request.eq('products.category_id', categoryId);
    }

    final text = (query ?? '').replaceAll(RegExp(r'[%_,()*]'), ' ').trim();
    if (text.isNotEmpty) {
      request = request.ilike('name', '%$text%');
    }

    final data = await request.order('rating', ascending: false);
    return data.map(Restaurant.fromMap).toList();
  }
}