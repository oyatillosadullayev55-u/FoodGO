import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/product.dart';
import '../../../models/restaurant.dart';
import 'cart_provider.dart';

Future<void> addProductToCart(
    BuildContext context,
    WidgetRef ref,
    Restaurant restaurant,
    Product product,
    ) async {
  final cart = ref.read(cartProvider.notifier);

  if (cart.canAdd(restaurant)) {
    cart.add(restaurant, product);
    return;
  }

  final replace = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Savatni almashtirasizmi?'),
      content: const Text(
        "Savatda boshqa restoran taomlari bor. Bir buyurtmada faqat bitta "
            "restorandan taom olish mumkin. Eski savatni tozalab, yangisini "
            "boshlaymizmi?",
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Bekor qilish'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Tozalash va qo\'shish'),
        ),
      ],
    ),
  );

  if (replace == true) {
    cart.replaceWith(restaurant, product);
  }
}