import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/utils/live_query.dart';
import '../models/food_category.dart';
import '../models/marketplace.dart';
import '../models/product.dart';
import '../models/restaurant.dart';

/// Do'kon mahsuloti va uning do'koni (savatga qo'shish uchun ikkalasi kerak).
typedef StoreProduct = ({Product product, Restaurant store});

/// super_app.sql qo'shgan jadvallar bilan ishlaydi.
class MarketplaceRepository {
  MarketplaceRepository(this._client);

  final SupabaseClient _client;

  String get _uid {
    final id = _client.auth.currentUser?.id;
    if (id == null) throw AuthException('Tizimga kirilmagan');
    return id;
  }

  static String _clean(String? query) =>
      (query ?? '').replaceAll(RegExp(r'[%_,()*]'), ' ').trim();

  // ----- Katalog -----

  Future<List<ServiceModule>> fetchServices() async {
    final data = await _client.from('services').select().order('sort_order', ascending: true);
    return data.map(ServiceModule.fromMap).toList();
  }

  Future<List<Promotion>> fetchPromotions() async {
    final data = await _client.from('promotions').select().order('sort_order', ascending: true);
    return data.map(Promotion.fromMap).toList();
  }

  Future<List<Region>> fetchRegions() async {
    final data = await _client
        .from('regions')
        .select()
        .order('sort_order', ascending: true)
        .order('name', ascending: true);
    return data.map(Region.fromMap).toList();
  }

  /// kind: 'food', 'shop' yoki 'master'.
  Future<List<FoodCategory>> fetchCategories(String kind) async {
    final data = await _client
        .from('categories')
        .select()
        .eq('kind', kind)
        .order('sort_order', ascending: true);
    return data.map(FoodCategory.fromMap).toList();
  }

  /// Barcha tasdiqlangan magazinlarning sotuvdagi mahsulotlari.
  Future<List<StoreProduct>> fetchShopProducts({String? categoryId}) async {
    var request = _client
        .from('products')
        .select('*, categories(name), restaurants!inner(*)')
        .eq('restaurants.kind', 'shop')
        .eq('is_available', true);
    if (categoryId != null) request = request.eq('category_id', categoryId);
    final data = await request.order('name', ascending: true).limit(100);
    return [
      for (final row in data)
        (
          product: Product.fromMap(row),
          store: Restaurant.fromMap(row['restaurants'] as Map<String, dynamic>),
        ),
    ];
  }

  // ----- Ustalar -----

  Future<List<Master>> fetchMasters({String? categoryId, String? query}) async {
    var request = _client
        .from('masters')
        .select('*, categories(name)')
        .eq('is_active', true)
        .eq('verification_status', 'approved');
    if (categoryId != null) request = request.eq('category_id', categoryId);
    final text = _clean(query);
    if (text.isNotEmpty) request = request.ilike('full_name', '%$text%');
    final data = await request.order('rating', ascending: false);
    return data.map(Master.fromMap).toList();
  }

  Future<Master> fetchMaster(String id) async {
    final data = await _client
        .from('masters')
        .select('*, categories(name)')
        .eq('id', id)
        .single();
    return Master.fromMap(data);
  }

  /// Joriy foydalanuvchining usta profili (bo'lmasa null).
  Future<Master?> fetchMyMaster() async {
    final data = await _client
        .from('masters')
        .select('*, categories(name)')
        .eq('user_id', _uid)
        .maybeSingle();
    return data == null ? null : Master.fromMap(data);
  }

  Future<void> updateMaster(String id, Map<String, dynamic> values) async {
    final rows = await _client
        .from('masters')
        .update(values)
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) throw Exception("Saqlab bo'lmadi: ruxsat yo'q");
  }

  Future<List<Review>> fetchMasterReviews(String masterId) async {
    final data = await _client
        .from('reviews')
        .select()
        .eq('master_id', masterId)
        .order('created_at', ascending: false)
        .limit(50);
    return data.map(Review.fromMap).toList();
  }

  // ----- Xizmat buyurtmalari -----

  Future<String> createServiceRequest({
    required String masterId,
    required String serviceType,
    required String address,
    required String phone,
    String? description,
    DateTime? scheduledAt,
  }) async {
    final id = await _client.rpc(
      'create_service_request',
      params: {
        'p_master_id': masterId,
        'p_service_type': serviceType,
        'p_address_text': address,
        'p_phone': phone,
        'p_description': description,
        'p_scheduled_at': scheduledAt?.toUtc().toIso8601String(),
      },
    );
    return id as String;
  }

  Future<List<ServiceRequest>> _requests(String column, String value) async {
    final data = await _client
        .from('service_requests')
        .select('*, masters(full_name, phone)')
        .eq(column, value)
        .order('created_at', ascending: false)
        .limit(100);
    return data.map(ServiceRequest.fromMap).toList();
  }

  Stream<List<ServiceRequest>> _watchRequests(String column, String value) =>
      liveQuery(
        load: () => _requests(column, value),
        changes: () => _client
            .from('service_requests')
            .stream(primaryKey: ['id'])
            .eq(column, value),
        poll: const Duration(seconds: 20),
      );

  Stream<List<ServiceRequest>> watchMyRequests() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return Stream.error(AuthException('Tizimga kirilmagan'));
    return _watchRequests('customer_id', uid);
  }

  Stream<List<ServiceRequest>> watchMasterRequests(String masterId) =>
      _watchRequests('master_id', masterId);

  Future<void> setServiceStatus(
    String requestId,
    ServiceStatus status, {
    int? price,
  }) => _client.rpc(
    'set_service_status',
    params: {
      'p_request_id': requestId,
      'p_status': status.value,
      'p_price': price,
    },
  );

  // ----- Baho, shikoyat, xabar -----

  Future<void> submitReview({
    required int rating,
    String? comment,
    String? orderId,
    String? serviceRequestId,
  }) => _client.rpc(
    'submit_review',
    params: {
      'p_rating': rating,
      'p_comment': comment,
      'p_order_id': orderId,
      'p_service_request_id': serviceRequestId,
    },
  );

  Future<void> createComplaint({
    required String subject,
    required String body,
    String? orderId,
    String? serviceRequestId,
  }) => _client.from('complaints').insert({
    'user_id': _uid,
    'subject': subject.trim(),
    'body': body.trim(),
    'order_id': orderId,
    'service_request_id': serviceRequestId,
  });

  /// Ruxsatlar (RLS) faqat o'ziga tegishli xabarlarni qaytaradi.
  Future<List<AppNotification>> fetchNotifications() async {
    if (_client.auth.currentUser == null) return const [];
    final data = await _client
        .from('notifications')
        .select()
        .order('created_at', ascending: false)
        .limit(60);
    return data.map(AppNotification.fromMap).toList();
  }

  // ----- Kuryer -----

  Future<OrderCourier?> fetchOrderCourier(String orderId) async {
    final data = await _client.rpc(
      'get_order_courier',
      params: {'p_order_id': orderId},
    );
    final rows = data as List;
    if (rows.isEmpty) return null;
    return OrderCourier.fromMap(Map<String, dynamic>.from(rows.first as Map));
  }

  Future<void> upsertCourierLocation(double lat, double lng) =>
      _client.from('courier_locations').upsert({
        'courier_id': _uid,
        'lat': lat,
        'lng': lng,
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

  // ----- Hujjatlar -----

  /// Hujjat yopiq bucket'ga, foydalanuvchining o'z papkasiga yuklanadi.
  Future<void> uploadDocument({
    required String docType,
    required String fileName,
    required Uint8List bytes,
  }) async {
    final safe = fileName.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
    final path = '$_uid/${DateTime.now().millisecondsSinceEpoch}_$safe';
    await _client.storage.from('partner-docs').uploadBinary(path, bytes);
    await _client.from('partner_documents').insert({
      'user_id': _uid,
      'doc_type': docType,
      'file_path': path,
    });
  }

  Future<List<Map<String, dynamic>>> fetchMyDocuments() => _client
      .from('partner_documents')
      .select()
      .eq('user_id', _uid)
      .order('created_at', ascending: false);
}
