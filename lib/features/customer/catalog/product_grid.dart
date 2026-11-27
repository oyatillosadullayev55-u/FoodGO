import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/ui.dart';
import '../../../repositories/marketplace_repository.dart';
import '../cart/cart_actions.dart';
import '../cart/cart_provider.dart';

/// Magazin mahsulotlari to'ri; har bir kartadan savatga qo'shiladi.
class ProductGrid extends StatelessWidget {
  const ProductGrid({super.key, required this.items});

  final List<StoreProduct> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const EmptyView(
        icon: Icons.inventory_2_outlined,
        title: "Mahsulot yo'q",
        message: "Bu bo'limda hozircha sotuvdagi mahsulot topilmadi.",
      );
    }
    return AdaptiveGrid(
      minItemWidth: 150,
      children: [for (final item in items) _ProductCard(item: item)],
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.item});

  final StoreProduct item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (:product, :store) = item;
    final qty = ref.watch(cartProvider.select((c) => c.quantityOf(product.id)));
    // Savatdagi miqdor ombor qoldig'idan oshmaydi.
    final canAdd = product.stock == null || qty < product.stock!;

    return SoftCard(
      padding: const EdgeInsets.all(10),
      onTap: () => context.push(AppRoutes.restaurantPath(store.id)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: AspectRatio(
              aspectRatio: 1.25,
              child: AppImage(product.imageUrl, width: double.infinity),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            product.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
          ),
          Text(
            product.isSoldOut ? 'Tugagan' : store.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              color: product.isSoldOut ? AppColors.error : AppColors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Expanded(
                child: Text(
                  product.unit == null || product.unit == 'dona'
                      ? formatSom(product.price)
                      : '${formatSom(product.price)}/${product.unit}',
                  maxLines: 2,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ),
              IconButton.filled(
                tooltip: "Savatga qo'shish",
                visualDensity: VisualDensity.compact,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: canAdd
                    ? () => addProductToCart(context, ref, store, product)
                    : null,
                icon: Badge.count(
                  count: qty,
                  isLabelVisible: qty > 0,
                  backgroundColor: AppColors.accentRed,
                  child: const Icon(Icons.add_rounded, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
