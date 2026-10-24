import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/widgets/empty_view.dart';
import '../../../core/widgets/quantity_stepper.dart';
import 'cart_provider.dart';

class CartPage extends ConsumerStatefulWidget {
  const CartPage({super.key});

  @override
  ConsumerState<CartPage> createState() => _CartPageState();
}

class _CartPageState extends ConsumerState<CartPage> {
  final _promoController = TextEditingController();
  bool _promoApplied = false;

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Savatni tozalaysizmi?'),
        content: const Text("Barcha taomlar savatdan o'chiriladi."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("Yo'q"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Tozalash'),
          ),
        ],
      ),
    );
    if (ok == true) ref.read(cartProvider.notifier).clear();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final notifier = ref.read(cartProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Savat')),
        body: const EmptyView(
          icon: Icons.shopping_basket_outlined,
          title: "Savatingiz bo'sh",
          message: "Restoranlardan mazali taomlarni tanlang va buyurtma bering.",
        ),
      );
    }

    final discount = _promoApplied ? (cart.subtotal * 0.1).round() : 0;
    final total = cart.subtotal + kDeliveryFee - discount;
    final cashback = (total * 0.05).round();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Savat', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [
          TextButton(
            onPressed: () => _confirmClear(context, ref),
            child: const Text(
              'Tozalash',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              children: [
                // Restoran ma'lumoti
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : AppColors.borderLight,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.storefront_rounded, color: AppColors.dark, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cart.restaurant?.name ?? 'Restoran',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                            ),
                            const Text(
                              'Yetkazish vaqti: 20–30 daqiqa',
                              style: TextStyle(color: AppColors.grey, fontSize: 12.5),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                // Yandex Plus keshbek banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2C2C30), Color(0xFF1E1E22)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.star_rounded, size: 16, color: AppColors.dark),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Yandex Plus keshbek',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              'Ushbu buyurtmadan +${formatSom(cashback)} hisobingizga tushadi',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Taomlar ro'yxati
                Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.white10 : AppColors.borderLight,
                      width: 0.8,
                    ),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      color: isDark ? Colors.white10 : AppColors.borderLight,
                    ),
                    itemBuilder: (context, i) {
                      final item = cart.items[i];
                      return Dismissible(
                        key: ValueKey(item.product.id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => notifier.remove(item.product.id),
                        background: Container(
                          color: AppColors.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.product.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      formatSom(item.total),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        color: isDark ? Colors.white : AppColors.dark,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              QuantityStepper(
                                quantity: item.quantity,
                                onMinus: () => notifier.decrement(item.product.id),
                                onPlus: () =>
                                    notifier.add(cart.restaurant!, item.product),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Promokod qatori (Yandex style)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white10 : AppColors.borderLight,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.confirmation_number_outlined, color: AppColors.grey, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _promoController,
                          decoration: const InputDecoration(
                            hintText: 'Promokod: GO20',
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          if (_promoController.text.trim().isNotEmpty) {
                            setState(() => _promoApplied = true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Promokod muvaffaqiyatli qo\'llandi (-10%)')),
                            );
                          }
                        },
                        child: Text(
                          _promoApplied ? 'Qo\'llandi ✓' : 'Qo\'llash',
                          style: TextStyle(
                            color: _promoApplied ? AppColors.success : AppColors.dark,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Pastki hisob-kitob va Tasdiqlash tugmasi
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _row('Taomlar summasi', formatSom(cart.subtotal)),
                  const SizedBox(height: 6),
                  _row('Yetkazib berish', formatSom(kDeliveryFee)),
                  if (_promoApplied) ...[
                    const SizedBox(height: 6),
                    _row('Chegirma (Promokod)', '-${formatSom(discount)}', color: AppColors.yandexRed),
                  ],
                  const Divider(height: 20),
                  _row('Jami to\'lov', formatSom(total), bold: true),
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: () => context.push(AppRoutes.customerCheckout),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.dark,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Buyurtma berish · ',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                        ),
                        Text(
                          formatSom(total),
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false, Color? color}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
      fontSize: bold ? 18 : 14.5,
      color: color,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}