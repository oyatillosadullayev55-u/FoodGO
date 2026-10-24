import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/product.dart';
import '../models/restaurant.dart';

class MenuRepository {
  MenuRepository(this._client);

  final SupabaseClient _client;

  Future<Restaurant> fetchRestaurant(String id) async {
    final data =
    await _client.from('restaurants').select().eq('id', id).single();
    return Restaurant.fromMap(data);
  }

  Future<List<Product>> fetchProducts(String restaurantId) async {
    final data = await _client
        .from('products')
        .select('*, categories(name)')
        .eq('restaurant_id', restaurantId)
        .order('name');
    return data.map(Product.fromMap).toList();
  }
}