import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/food_order.dart';
import '../models/product.dart';
import '../models/restaurant.dart';

/// Restoran egasi va kuryer paneli uchun ma'lumotlar.
class DeliveryRepository {
  DeliveryRepository(this._client);

  final SupabaseClient _client;

  String? get _uid => _client.auth.currentUser?.id;
  String get _email => (_client.auth.currentUser?.email ?? '').toLowerCase();

  /// Joriy foydalanuvchi egasi bo'lgan restoranlar (owner_email bo'yicha).
  Future<List<Restaurant>> fetchMyRestaurants() async {
    final email = _email;
    if (email.isEmpty) return const [];
    final data = await _client
        .from('restaurants')
        .select()
        .eq('owner_email', email)
        .order('name');
    return (data as List).map((e) {
      return Restaurant.fromMap(e as Map<String, dynamic>);
    }).toList();
  }

  Future<Restaurant> fetchRestaurant(String id) async {
    final data = await _client
        .from('restaurants')
        .select()
        .eq('id', id)
        .single();
    return Restaurant.fromMap(data);
  }

  Future<List<Product>> fetchProducts(String restaurantId) async {
    final data = await _client
        .from('products')
        .select('*, categories(name)')
        .eq('restaurant_id', restaurantId)
        .order('name');
    return (data as List).map((e) {
      return Product.fromMap(e as Map<String, dynamic>);
    }).toList();
  }

  Future<void> addProduct({
    required String restaurantId,
    required String name,
    required int price,
    required String description,
    required String imageUrl,
    String? categoryId,
  }) async {
    var category = categoryId;
    if (category == null) {
      try {
        final rows = await _client.from('categories').select('id').limit(1);
        if ((rows as List).isNotEmpty) {
          category = rows.first['id'] as String;
        }
      } catch (_) {}
    }

    await _client.from('products').insert({
      'restaurant_id': restaurantId,
      'category_id': category,
      'name': name,
      'price': price,
      'description': description,
      'image_url': imageUrl,
      'is_available': true,
    });
  }

  Future<void> updateProduct(String id, Map<String, dynamic> values) async {
    await _client.from('products').update(values).eq('id', id);
  }

  Future<void> deleteProduct(String id) async {
    await _client.from('products').delete().eq('id', id);
  }

  Future<List<FoodOrder>> fetchRestaurantOrders(String restaurantId) async {
    final data = await _client
        .from('orders')
        .select('*, restaurants(name,address,lat,lng)')
        .eq('restaurant_id', restaurantId)
        .order('created_at', ascending: false);
    return (data as List).map((e) {
      return FoodOrder.fromMap(e as Map<String, dynamic>);
    }).toList();
  }

  /// Kuryerga tayyor, hali biriktirilmagan buyurtmalar.
  Future<List<FoodOrder>> fetchAvailableOrders() async {
    final data = await _client
        .from('orders')
        .select('*, restaurants(name,address,lat,lng)')
        .eq('status', OrderStatus.readyForPickup.value)
        .isFilter('courier_id', null)
        .order('created_at');
    return (data as List).map((e) {
      return FoodOrder.fromMap(e as Map<String, dynamic>);
    }).toList();
  }

  Future<List<FoodOrder>> fetchCourierOrders() async {
    final uid = _uid;
    if (uid == null) return const [];
    final data = await _client
        .from('orders')
        .select('*, restaurants(name,address,lat,lng)')
        .eq('courier_id', uid)
        .order('created_at', ascending: false);
    return (data as List).map((e) {
      return FoodOrder.fromMap(e as Map<String, dynamic>);
    }).toList();
  }

  Stream<List<FoodOrder>> watchRestaurantOrders(String restaurantId) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('restaurant_id', restaurantId)
        .asyncMap((_) => fetchRestaurantOrders(restaurantId));
  }

  Stream<List<FoodOrder>> watchAvailableOrders() {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .asyncMap((_) => fetchAvailableOrders());
  }

  Stream<List<FoodOrder>> watchCourierOrders() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('courier_id', uid)
        .asyncMap((_) => fetchCourierOrders());
  }

  Future<void> claimOrder(String orderId) async {
    await _client.rpc('claim_order', params: {'p_order_id': orderId});
  }

  Future<void> setStatus(String orderId, OrderStatus status) async {
    await _client.rpc(
      'set_order_status',
      params: {'p_order_id': orderId, 'p_new_status': status.value},
    );
  }
}
