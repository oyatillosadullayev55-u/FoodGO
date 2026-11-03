import 'package:supabase_flutter/supabase_flutter.dart';

import '../features/auth/data/user_profile.dart';
import '../models/food_order.dart';
import '../models/restaurant.dart';

/// Administrator paneli uchun ma'lumotlar.
class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  Future<List<Restaurant>> fetchRestaurants() async {
    final data = await _client.from('restaurants').select().order('name');
    return (data as List).map((e) {
      return Restaurant.fromMap(e as Map<String, dynamic>);
    }).toList();
  }

  Future<void> createRestaurant({
    required String name,
    required String description,
    required String address,
    required String ownerEmail,
    required double lat,
    required double lng,
    required String imageUrl,
    bool isActive = true,
  }) async {
    await _client.from('restaurants').insert({
      'name': name,
      'description': description,
      'address': address,
      'owner_email': ownerEmail.toLowerCase(),
      'lat': lat,
      'lng': lng,
      'image_url': imageUrl,
      'rating': 4.8,
      'open_time': '09:00:00',
      'close_time': '23:00:00',
      'is_active': isActive,
    });
    await promoteOwner(ownerEmail);
  }

  Future<void> updateRestaurant(
    String id, {
    required String name,
    required String description,
    required String address,
    required String ownerEmail,
    required double lat,
    required double lng,
    required String imageUrl,
    required bool isActive,
  }) async {
    await _client
        .from('restaurants')
        .update({
          'name': name,
          'description': description,
          'address': address,
          'owner_email': ownerEmail.toLowerCase(),
          'lat': lat,
          'lng': lng,
          'image_url': imageUrl,
          'is_active': isActive,
        })
        .eq('id', id);
    await promoteOwner(ownerEmail);
  }

  Future<void> deleteRestaurant(String id) async {
    await _client.from('restaurants').delete().eq('id', id);
  }

  Future<void> setRestaurantActive(String id, bool isActive) async {
    await _client
        .from('restaurants')
        .update({'is_active': isActive})
        .eq('id', id);
  }

  /// Restoran egasi allaqachon ro'yxatdan o'tgan bo'lsa, roli avtomatik
  /// "restaurant" ga o'tadi. Hisob hali yo'q bo'lsa — hech narsa bo'lmaydi.
  Future<void> promoteOwner(String email) async {
    final target = email.trim().toLowerCase();
    if (target.isEmpty) return;
    try {
      final rows = await _client
          .from('profiles')
          .select('id, role')
          .eq('email', target)
          .limit(1);
      if ((rows as List).isEmpty) return;
      final Map<String, dynamic> row = rows.first;
      if (row['role'] != 'admin' && row['role'] != 'restaurant') {
        await _client
            .from('profiles')
            .update({'role': 'restaurant'})
            .eq('id', row['id']);
      }
    } catch (_) {
      // Rol o'zgartirish muvaffaqiyatsiz bo'lsa, admin keyin qo'lda o'zgartiradi.
    }
  }

  Future<List<UserProfile>> fetchUsers() async {
    final data = await _client.from('profiles').select();
    return (data as List).map((e) {
      return UserProfile.fromMap(e as Map<String, dynamic>);
    }).toList();
  }

  Future<void> updateUserRole(String userId, UserRole role) async {
    await _client.from('profiles').update({'role': role.name}).eq('id', userId);
  }

  Future<List<FoodOrder>> fetchOrders() async {
    final data = await _client
        .from('orders')
        .select('*, restaurants(name,address,lat,lng)')
        .order('created_at', ascending: false);
    return (data as List).map((e) {
      return FoodOrder.fromMap(e as Map<String, dynamic>);
    }).toList();
  }
}
