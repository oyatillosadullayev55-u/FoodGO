import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../models/cart_item.dart';
import '../../../models/product.dart';
import '../../../models/restaurant.dart';

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
  @override
  CartState build() => const CartState();

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
    state = CartState(restaurant: restaurant, items: items);
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

  void clear() => state = const CartState();

  /// Boshqa restoran tanlanganda: eski savat tozalanib, yangisi boshlanadi.
  void replaceWith(Restaurant restaurant, Product product) {
    state = const CartState();
    add(restaurant, product);
  }

  void _save(List<CartItem> items) {
    state = items.isEmpty
        ? const CartState()
        : CartState(restaurant: state.restaurant, items: items);
  }
}

final cartProvider =
NotifierProvider<CartNotifier, CartState>(CartNotifier.new);