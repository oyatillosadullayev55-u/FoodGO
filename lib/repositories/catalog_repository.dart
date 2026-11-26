import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/food_category.dart';
import '../models/restaurant.dart';

class CatalogRepository {
  CatalogRepository(this._client);

  final SupabaseClient _client;

  Future<List<FoodCategory>> fetchCategories() async {
    final data = await _client.from('categories').select().order('sort_order', ascending: true);
    return data.map(FoodCategory.fromMap).toList();
  }

  /// Kategoriya tanlansa, shu kategoriyada taomi bor restoranlar chiqadi.
  /// [kind]: 'restaurant' yoki 'shop'; null bo'lsa hammasi.
  Future<List<Restaurant>> fetchRestaurants({
    String? categoryId,
    String? query,
    String? kind,
  }) async {
    try {
      return await _fetch(categoryId: categoryId, query: query, kind: kind);
    } on PostgrestException catch (e) {
      // super_app.sql ishga tushirilmagan bazada `kind` ustuni yo'q:
      // restoranlar avvalgidek ko'rinadi, magazinlar esa hali mavjud emas.
      if (kind == 'restaurant' && e.code == '42703') {
        return _fetch(categoryId: categoryId, query: query);
      }
      rethrow;
    }
  }

  Future<List<Restaurant>> _fetch({
    String? categoryId,
    String? query,
    String? kind,
  }) async {
    final columns = categoryId == null ? '*' : '*, products!inner(category_id)';
    var request = _client.from('restaurants').select(columns);

    if (kind != null) request = request.eq('kind', kind);

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
