import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/cart_item.dart';
import '../models/food_order.dart';

class OrdersRepository {
  OrdersRepository(this._client);

  final SupabaseClient _client;

  /// Narxni server o'zi hisoblaydi. Biz faqat taom id va miqdorini yuboramiz.
  Future<String> createOrder({
    required String restaurantId,
    required List<CartItem> items,
    required String address,
    required String phone,
    String? note,
    required String idempotencyKey,
  }) async {
    final result = await _client.rpc('create_order', params: {
      'p_restaurant_id': restaurantId,
      'p_items': [
        for (final i in items)
          {'product_id': i.product.id, 'quantity': i.quantity},
      ],
      'p_address_text': address,
      'p_lat': null,
      'p_lng': null,
      'p_phone': phone,
      'p_note': (note == null || note.trim().isEmpty) ? null : note.trim(),
      'p_payment_method': 'cash',
      'p_idempotency_key': idempotencyKey,
    });
    return result as String;
  }

  Future<List<FoodOrder>> fetchOrders() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) throw AuthException('Tizimga kirilmagan');
    final data = await _client
        .from('orders')
        .select('*, restaurants(name)')
        .eq('customer_id', uid)
        .order('created_at', ascending: false);
    return data.map(FoodOrder.fromMap).toList();
  }

  Future<FoodOrder> fetchOrder(String id) async {
    final data = await _client
        .from('orders')
        .select('*, restaurants(name)')
        .eq('id', id)
        .single();
    return FoodOrder.fromMap(data);
  }

  Future<List<OrderLine>> fetchLines(String orderId) async {
    final data =
    await _client.from('order_items').select().eq('order_id', orderId);
    return data.map(OrderLine.fromMap).toList();
  }

  /// Holat o'zgarsa, darrov yangilanib turadi (Realtime).
  Stream<OrderStatus> watchStatus(String id) {
    return _client
        .from('orders')
        .stream(primaryKey: ['id'])
        .eq('id', id)
        .where((rows) => rows.isNotEmpty)
        .map((rows) => OrderStatus.fromString(rows.first['status'] as String?));
  }

  Future<void> cancelOrder(String id) async {
    await _client.rpc('set_order_status', params: {
      'p_order_id': id,
      'p_new_status': 'cancelled',
    });
  }
}