import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/live_query.dart';
import '../models/food_order.dart';
import '../models/product.dart';
import '../models/product_category.dart';
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
        .order('name', ascending: true);
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
        .order('name', ascending: true);
    return (data as List).map((e) {
      return Product.fromMap(e as Map<String, dynamic>);
    }).toList();
  }

  Future<List<ProductCategory>> fetchCategories() async {
    final data = await _client.from('categories').select('id, name').order('name', ascending: true);
    return (data as List)
        .map((e) => ProductCategory.fromMap(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> updateRestaurant(String id, Map<String, dynamic> values) async {
    final rows = await _client.from('restaurants').update(values).eq('id', id).select('id');
    if ((rows as List).isEmpty) {
      throw Exception("Saqlab bo'lmadi: ruxsat yo'q");
    }
  }

  Future<void> addProduct({
    required String restaurantId,
    required String name,
    required int price,
    required String description,
    required String imageUrl,
    String? categoryId,
    int? stock,
    String? unit,
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
      // Faqat magazinlarda yuboriladi: ustunlar super_app.sql bilan qo'shiladi.
      'stock': ?stock,
      'unit': ?unit,
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
        .order('created_at', ascending: false)
        .limit(100);
    return (data as List).map((e) {
      return FoodOrder.fromMap(e as Map<String, dynamic>);
    }).toList();
  }

  /// [since] dan beri yetkazilgan buyurtmalar (daromad hisobi uchun).
  /// [column]: 'restaurant_id' yoki 'courier_id'.
  Future<List<FoodOrder>> fetchDelivered({
    required String column,
    required String value,
    required DateTime since,
  }) async {
    final data = await _client
        .from('orders')
        .select('*, restaurants(name,address,lat,lng)')
        .eq(column, value)
        .eq('status', OrderStatus.delivered.value)
        .gte('created_at', since.toUtc().toIso8601String())
        .order('created_at', ascending: false)
        .limit(1000);
    return data.map(FoodOrder.fromMap).toList();
  }

  /// Daromad oynasi boshlanishi: oy boshi yoki 14 kun oldin (qaysi ertaroq).
  static DateTime incomeSince(DateTime now) {
    final month = DateTime(now.year, now.month);
    final fortnight = DateTime(now.year, now.month, now.day - 13);
    return month.isBefore(fortnight) ? month : fortnight;
  }

  String? get currentUserId => _uid;

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

  Stream<List<FoodOrder>> watchRestaurantOrders(String restaurantId) => liveQuery(
        load: () => fetchRestaurantOrders(restaurantId),
        changes: () => _client
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq('restaurant_id', restaurantId),
        poll: const Duration(seconds: 30),
      );

  Stream<List<FoodOrder>> watchAvailableOrders() => liveQuery(
        load: fetchAvailableOrders,
        changes: () => _client.from('orders').stream(primaryKey: ['id']),
        poll: const Duration(seconds: 15),
      );

  Stream<List<FoodOrder>> watchCourierOrders() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return liveQuery(
      load: fetchCourierOrders,
      changes: () => _client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('courier_id', uid),
        poll: const Duration(seconds: 30),
      );
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
