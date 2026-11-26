import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/food_images.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/quantity_stepper.dart';
import '../../../core/widgets/ui.dart';
import '../../../models/product.dart';
import '../../../models/restaurant.dart';
import '../cart/cart_actions.dart';
import '../cart/cart_provider.dart';

class ProductTile extends ConsumerWidget {
  const ProductTile({
    super.key,
    required this.restaurant,
    required this.product,
  });

  final Restaurant restaurant;
  final Product product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final qty = ref.watch(cartProvider.select((c) => c.quantityOf(product.id)));
    final cart = ref.read(cartProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Opacity(
      opacity: product.isAvailable ? 1 : 0.45,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white10 : AppColors.borderLight,
            width: 0.8,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Taom rasmi
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 88,
                height: 88,
                child: AppImage(
                  // Magazin mahsulotiga taom rasmi qo'yilmaydi.
                  restaurant.isShop
                      ? product.imageUrl
                      : FoodImages.getProductImage(
                          product.name,
                          product.categoryName,
                          product.imageUrl,
                        ),
                  fallbackIcon: restaurant.isShop
                      ? Icons.inventory_2_rounded
                      : Icons.fastfood_rounded,
                ),
              ),
            ),
            const SizedBox(width: 14),
            // Taom tafsilotlari
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  if (product.description != null &&
                      product.description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      product.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.grey,
                        fontSize: 12.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Text(
                    formatSom(product.price),
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: isDark ? Colors.white : AppColors.dark,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Qo'shish yoki hisoblagich tugmasi
            if (!product.isAvailable || product.isSoldOut)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.greyLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Tugagan',
                  style: TextStyle(
                    color: AppColors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else if (qty == 0)
              InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: () =>
                    addProductToCart(context, ref, restaurant, product),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add, size: 18, color: AppColors.onPrimary),
                      SizedBox(width: 2),
                      Text(
                        'Qo\'shish',
                        style: TextStyle(
                          color: AppColors.onPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              QuantityStepper(
                quantity: qty,
                onMinus: () => cart.decrement(product.id),
                onPlus: () => cart.add(restaurant, product),
              ),
          ],
        ),
      ),
    );
  }
}
