import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/error_mapper.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/food_images.dart';
import '../../core/utils/money.dart';
import '../../core/widgets/content_frame.dart';
import '../../core/widgets/empty_view.dart';
import '../../core/widgets/error_view.dart';
import '../../core/widgets/image_picker_field.dart';
import '../../core/widgets/ui.dart';
import '../../models/product.dart';
import '../../models/restaurant.dart';
import '../delivery/delivery_providers.dart';
import '../marketplace/marketplace_providers.dart';

/// Ombor qoldig'i shu sondan kam bo'lsa ogohlantiriladi.
const lowStockLimit = 5;

/// Restoran menyusi yoki magazin mahsulotlari (ombor bilan).
class MenuView extends ConsumerWidget {
  const MenuView({super.key, required this.store});

  final Restaurant store;

  Future<void> _edit(BuildContext context, WidgetRef ref, [Product? p]) async {
    final saved = await showDialog<bool>(
      context: context,
      builder: (_) => _ProductEditorDialog(store: store, product: p),
    );
    if (saved == true) ref.invalidate(restaurantProductsProvider(store.id));
  }

  Future<void> _run(
    BuildContext context,
    WidgetRef ref,
    Future<void> Function() action,
  ) async {
    try {
      await action();
      ref.invalidate(restaurantProductsProvider(store.id));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, Product p) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("O'chirish"),
        content: Text("'${p.name}' o'chirilsinmi?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Yo'q"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text("O'chirish"),
          ),
        ],
      ),
    );
    if (sure != true || !context.mounted) return;
    await _run(
      context,
      ref,
      () => ref.read(deliveryRepositoryProvider).deleteProduct(p.id),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = restaurantProductsProvider(store.id);
    final noun = store.isShop ? 'Mahsulot' : 'Taom';

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add_product',
        onPressed: () => _edit(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: Text("$noun qo'shish"),
      ),
      body: ContentFrame(
        maxWidth: 900,
        child: RefreshIndicator(
          onRefresh: () => ref.refresh(provider.future),
          child: ref
              .watch(provider)
              .when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => ErrorView(
                  message: friendlyError(e),
                  onRetry: () => ref.invalidate(provider),
                ),
                data: (products) {
                  final low = products
                      .where(
                        (p) => p.stock != null && p.stock! <= lowStockLimit,
                      )
                      .length;
                  return ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
                    children: [
                      if (low > 0)
                        SoftCard(
                          margin: const EdgeInsets.only(bottom: 12),
                          color: AppColors.warning.withValues(alpha: 0.14),
                          child: Text(
                            "$low ta mahsulot qoldig'i kam yoki tugagan",
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                        ),
                      if (products.isEmpty)
                        EmptyView(
                          icon: store.isShop
                              ? Icons.inventory_2_outlined
                              : Icons.fastfood_rounded,
                          title: '$noun hali qo\'shilmagan',
                        ),
                      for (final p in products)
                        _ProductRow(
                          product: p,
                          showStock: store.isShop,
                          onEdit: () => _edit(context, ref, p),
                          onDelete: () => _delete(context, ref, p),
                          onAvailable: (v) => _run(
                            context,
                            ref,
                            () => ref
                                .read(deliveryRepositoryProvider)
                                .updateProduct(p.id, {'is_available': v}),
                          ),
                        ),
                    ],
                  );
                },
              ),
        ),
      ),
    );
  }
}

class _ProductRow extends StatelessWidget {
  const _ProductRow({
    required this.product,
    required this.showStock,
    required this.onEdit,
    required this.onDelete,
    required this.onAvailable,
  });

  final Product product;
  final bool showStock;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onAvailable;

  @override
  Widget build(BuildContext context) {
    final p = product;
    final url = p.imageUrl ?? '';
    final stock = p.stock;
    return SoftCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(10),
      onTap: onEdit,
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AppImage(
              url.startsWith('assets/') || showStock
                  ? url
                  : FoodImages.getProductImage(p.name, p.categoryName, url),
              width: 56,
              height: 56,
              fallbackIcon: showStock
                  ? Icons.inventory_2_rounded
                  : Icons.fastfood_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(formatSom(p.price)),
                if (showStock)
                  Text(
                    stock == null
                        ? 'Qoldiq yuritilmaydi'
                        : 'Omborda: $stock ${p.unit ?? 'dona'}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: stock != null && stock <= lowStockLimit
                          ? AppColors.error
                          : AppColors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Tooltip(
            message: p.isAvailable ? 'Sotuvda' : "Sotuvda yo'q",
            child: Switch(value: p.isAvailable, onChanged: onAvailable),
          ),
          IconButton(
            tooltip: "O'chirish",
            icon: const Icon(
              Icons.delete_outline_rounded,
              color: AppColors.error,
            ),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

class _ProductEditorDialog extends ConsumerStatefulWidget {
  const _ProductEditorDialog({required this.store, this.product});

  final Restaurant store;
  final Product? product;

  @override
  ConsumerState<_ProductEditorDialog> createState() =>
      _ProductEditorDialogState();
}

class _ProductEditorDialogState extends ConsumerState<_ProductEditorDialog> {
  late final _name = TextEditingController(text: widget.product?.name ?? '');
  late final _price = TextEditingController(
    text: widget.product?.price.toString() ?? '',
  );
  late final _description = TextEditingController(
    text: widget.product?.description ?? '',
  );
  late final _stock = TextEditingController(
    text: widget.product?.stock?.toString() ?? '',
  );
  late final _unit = TextEditingController(
    text: widget.product?.unit ?? 'dona',
  );
  late String _image = widget.product?.imageUrl ?? '';
  late String? _category = widget.product?.categoryId;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final c in [_name, _price, _description, _stock, _unit]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final price = int.tryParse(_price.text.trim()) ?? 0;
    final stock = int.tryParse(_stock.text.trim());
    if (name.isEmpty || price <= 0) {
      setState(() => _error = "Nomi va narxini to'g'ri kiriting");
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repo = ref.read(deliveryRepositoryProvider);
      final shop = widget.store.isShop;
      final image = _image.isNotEmpty || shop
          ? _image
          : FoodImages.getProductImage(name, null, null);
      final unit = _unit.text.trim().isEmpty ? 'dona' : _unit.text.trim();
      final existing = widget.product;
      if (existing == null) {
        await repo.addProduct(
          restaurantId: widget.store.id,
          name: name,
          price: price,
          description: _description.text.trim(),
          imageUrl: image,
          categoryId: _category,
          stock: shop ? stock : null,
          unit: shop ? unit : null,
        );
      } else {
        await repo.updateProduct(existing.id, {
          'name': name,
          'price': price,
          'description': _description.text.trim(),
          'image_url': image,
          'category_id': ?_category,
          if (shop) 'stock': stock,
          if (shop) 'unit': unit,
        });
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = friendlyError(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shop = widget.store.isShop;
    final categories =
        ref
            .watch(categoriesByKindProvider(shop ? 'shop' : 'food'))
            .asData
            ?.value ??
        const [];
    final noun = shop ? 'Mahsulot' : 'Taom';

    return AlertDialog(
      title: Text(
        widget.product == null ? "Yangi ${noun.toLowerCase()}" : 'Tahrirlash',
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(labelText: '$noun nomi'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(labelText: "Narxi (so'm)"),
              ),
              if (categories.isNotEmpty) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: categories.any((c) => c.id == _category)
                      ? _category
                      : null,
                  decoration: const InputDecoration(labelText: 'Kategoriya'),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(value: c.id, child: Text(c.name)),
                  ],
                  onChanged: (v) => _category = v,
                ),
              ],
              if (shop) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: TextField(
                        controller: _stock,
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: "Ombor qoldig'i",
                          helperText: "Bo'sh: cheklanmagan",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _unit,
                        decoration: const InputDecoration(
                          labelText: 'Birlik',
                          helperText: 'dona, kg',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              TextField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Tavsif (ixtiyoriy)',
                ),
              ),
              const SizedBox(height: 12),
              ImagePickerField(
                restaurantId: widget.store.id,
                initialUrl: _image,
                onChanged: (url) => _image = url,
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: const TextStyle(color: AppColors.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Saqlash'),
        ),
      ],
    );
  }
}
