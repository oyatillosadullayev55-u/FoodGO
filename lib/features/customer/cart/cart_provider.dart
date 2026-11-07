import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/cart_item.dart';
import '../../../models/product.dart';
import '../../../models/restaurant.dart';
import '../../delivery/delivery_providers.dart';

class CartState {
  const CartState({this.restaurant, this.items = const []});

  final Restaurant? restaurant;
  final List<CartItem> items;

  bool get isEmpty => items.isEmpty;
  int get count => items.fold(0, (sum, i) => sum + i.quantity);
  int get subtotal => items.fold(0, (sum, i) => sum + i.total);

  int quantityOf(String productId) {
    for (final i in items) {
      if (i.product.id == productId) return i.quantity;
    }
    return 0;
  }
}

class CartNotifier extends Notifier<CartState> {
  static const _prefsKey = 'cart_v1';

  /// Tiklash tugaguncha saqlamaymiz, aks holda bo'sh holat eski savatni o'chirib yuboradi.
  bool _restored = false;

  @override
  CartState build() {
    Future.microtask(_restore);
    return const CartState();
  }

  /// Savat bo'sh yoki shu restoranniki bo'lsa, qo'shish mumkin.
  bool canAdd(Restaurant restaurant) =>
      state.isEmpty || state.restaurant?.id == restaurant.id;

  void add(Restaurant restaurant, Product product) {
    if (!product.isAvailable || !canAdd(restaurant)) return;

    final items = [...state.items];
    final index = items.indexWhere((e) => e.product.id == product.id);
    if (index >= 0) {
      if (items[index].quantity < kMaxItemQuantity) {
        items[index] =
            items[index].copyWith(quantity: items[index].quantity + 1);
      }
    } else {
      items.add(CartItem(product: product, quantity: 1));
    }
    _set(CartState(restaurant: restaurant, items: items));
  }

  void decrement(String productId) {
    final items = [...state.items];
    final index = items.indexWhere((e) => e.product.id == productId);
    if (index < 0) return;

    if (items[index].quantity <= 1) {
      items.removeAt(index);
    } else {
      items[index] = items[index].copyWith(quantity: items[index].quantity - 1);
    }
    _save(items);
  }

  void remove(String productId) {
    _save(state.items.where((e) => e.product.id != productId).toList());
  }

  void clear() => _set(const CartState());

  /// Boshqa restoran tanlanganda: eski savat tozalanib, yangisi boshlanadi.
  void replaceWith(Restaurant restaurant, Product product) {
    _set(const CartState());
    add(restaurant, product);
  }

  void _save(List<CartItem> items) {
    _set(
      items.isEmpty
          ? const CartState()
          : CartState(restaurant: state.restaurant, items: items),
    );
  }

  void _set(CartState next) {
    state = next;
    _persist(next);
  }

  Future<void> _persist(CartState s) async {
    if (!_restored) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final restaurant = s.restaurant;
      if (s.isEmpty || restaurant == null) {
        await prefs.remove(_prefsKey);
        return;
      }
      await prefs.setString(
        _prefsKey,
        jsonEncode({
          'restaurant_id': restaurant.id,
          'items': [
            for (final i in s.items)
              {'product_id': i.product.id, 'quantity': i.quantity},
          ],
        }),
      );
    } catch (e) {
      debugPrint('Savatni saqlashda xato: $e');
    }
  }

  Future<void> _restore() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw == null) return;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      final restaurantId = json['restaurant_id'] as String;
      final saved = <String, int>{
        for (final e in json['items'] as List)
          (e as Map)['product_id'] as String: (e['quantity'] as num).toInt(),
      };
      if (saved.isEmpty) {
        await prefs.remove(_prefsKey);
        return;
      }

      final repo = ref.read(deliveryRepositoryProvider);
      final restaurant = await repo.fetchRestaurant(restaurantId);
      final products = await repo.fetchProducts(restaurantId);

      // Foydalanuvchi tiklash tugamasidan oldin savat boshlagan bo'lsa, tegmaymiz
      if (!state.isEmpty) return;

      if (!restaurant.isActive) {
        await prefs.remove(_prefsKey);
        return;
      }

      final byId = {for (final p in products) p.id: p};
      final items = <CartItem>[];
      for (final e in saved.entries) {
        final p = byId[e.key];
        if (p == null || !p.isAvailable) continue;
        items.add(
          CartItem(
            product: p,
            quantity: e.value.clamp(1, kMaxItemQuantity).toInt(),
          ),
        );
      }

      if (items.isEmpty) {
        await prefs.remove(_prefsKey);
        return;
      }
      state = CartState(restaurant: restaurant, items: items);
    } catch (e) {
      // Tarmoq xatosi: saqlangan savatga tegmaymiz, keyingi o'zgarish uni yangilaydi
      debugPrint('Savatni tiklashda xato: $e');
    } finally {
      _restored = true;
      if (!state.isEmpty) _persist(state);
    }
  }
}

final cartProvider =
    NotifierProvider<CartNotifier, CartState>(CartNotifier.new);
