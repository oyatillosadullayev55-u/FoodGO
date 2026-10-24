import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/money.dart';
import '../../../core/utils/validators.dart';
import '../../../core/widgets/empty_view.dart';
import '../../auth/providers/auth_providers.dart';
import '../cart/cart_provider.dart';
import '../orders/orders_providers.dart';

class CheckoutPage extends ConsumerStatefulWidget {
  const CheckoutPage({super.key});

  @override
  ConsumerState<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends ConsumerState<CheckoutPage> {
  final _formKey = GlobalKey<FormState>();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _note = TextEditingController();
  bool _loading = false;
  bool _leaveAtDoor = false;
  int _selectedPaymentMethod = 0; // 0: Naqd pul, 1: Yandex Pay, 2: Karta

  late final String _idempotencyKey = _newKey();

  static String _newKey() {
    final r = Random.secure();
    return '${DateTime.now().microsecondsSinceEpoch}-${r.nextInt(1 << 31)}';
  }

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider).maybeWhen(
      data: (p) => p,
      orElse: () => null,
    );
    if (profile?.phone != null) _phone.text = profile!.phone!;
    if (_address.text.isEmpty) {
      _address.text = 'Toshkent sh., Amir Temur shoh ko\'chasi, 25-uy, 14-xonadon';
    }
  }

  @override
  void dispose() {
    _address.dispose();
    _phone.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;

    final cart = ref.read(cartProvider);
    final restaurant = cart.restaurant;
    if (cart.isEmpty || restaurant == null) return;

    setState(() => _loading = true);
    try {
      final fullNote = [
        if (_leaveAtDoor) "Eshik oldida qoldiring (qo'ng'iroq qilmang)",
        if (_note.text.trim().isNotEmpty) _note.text.trim(),
      ].join(' · ');

      final orderId = await ref.read(ordersRepositoryProvider).createOrder(
        restaurantId: restaurant.id,
        items: cart.items,
        address: _address.text.trim(),
        phone: Validators.cleanPhone(_phone.text),
        note: fullNote.isEmpty ? null : fullNote,
        idempotencyKey: _idempotencyKey,
      );
      ref.read(cartProvider.notifier).clear();
      ref.invalidate(ordersProvider);
      if (mounted) context.go(AppRoutes.orderPath(orderId));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(friendlyError(e))));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (cart.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Buyurtma rasmiylashtirish')),
        body: const EmptyView(
          icon: Icons.shopping_basket_outlined,
          title: "Savatingiz bo'sh",
        ),
      );
    }

    final total = cart.subtotal + kDeliveryFee;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Buyurtma rasmiylashtirish',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          children: [
            // 1. Yetkazib berish vaqti (Yandex uslubida)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white10 : AppColors.borderLight,
                  width: 0.8,
                ),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.yandexRed, size: 24),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tezkor yetkazish: 20–30 daqiqa',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5),
                        ),
                        Text(
                          'Yandex Go kuryeri eng qisqa vaqtda yetkazadi',
                          style: TextStyle(color: AppColors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // 2. Manzil
            _title(context, 'Yetkazib berish manzili'),
            TextFormField(
              controller: _address,
              minLines: 2,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: "Ko'cha, uy, xonadon, pod'ezd, qavat",
                prefixIcon: Icon(Icons.location_on_rounded, color: AppColors.dark),
              ),
              validator: (v) => (v ?? '').trim().length < 5
                  ? "Manzilni to'liq kiriting"
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                hintText: 'Telefon raqami (+998...)',
                prefixIcon: Icon(Icons.phone_rounded, color: AppColors.dark),
              ),
              validator: Validators.phone,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _note,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'Kuryer uchun izoh (mo\'ljal, domofon kodi)',
                prefixIcon: Icon(Icons.comment_rounded, color: AppColors.dark),
              ),
            ),
            const SizedBox(height: 14),

            // Eshik oldida qoldirish (Yandex contactless switch)
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
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _leaveAtDoor,
                activeThumbColor: AppColors.primary,
                activeTrackColor: AppColors.dark,
                onChanged: (val) => setState(() => _leaveAtDoor = val),
                title: const Text(
                  'Eshik oldida qoldirish',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                subtitle: const Text(
                  'Kuryer taomni eshik oldiga qo\'yadi va qo\'ng\'iroq qiladi',
                  style: TextStyle(fontSize: 12, color: AppColors.grey),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 3. To'lov usuli
            _title(context, "To'lov usuli"),
            _PaymentOption(
              icon: Icons.payments_rounded,
              title: "Naqd pul orqali",
              subtitle: "Kuryer yetkazganda to'lanadi",
              isSelected: _selectedPaymentMethod == 0,
              onTap: () => setState(() => _selectedPaymentMethod = 0),
            ),
            const SizedBox(height: 10),
            _PaymentOption(
              icon: Icons.account_balance_wallet_rounded,
              title: "Yandex Pay",
              subtitle: "Tezkor to'lov · +10% Plus ballari",
              isSelected: _selectedPaymentMethod == 1,
              tag: 'TAVSIYA',
              onTap: () => setState(() => _selectedPaymentMethod = 1),
            ),
            const SizedBox(height: 10),
            _PaymentOption(
              icon: Icons.credit_card_rounded,
              title: "Bank kartasi (Uzcard / Humo)",
              subtitle: "Ilovada biriktirilgan karta",
              isSelected: _selectedPaymentMethod == 2,
              onTap: () => setState(() => _selectedPaymentMethod = 2),
            ),
            const SizedBox(height: 22),

            // 4. Buyurtma tafsilotlari
            _title(context, 'Buyurtma tarkibi'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.white10 : AppColors.borderLight,
                  width: 0.8,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.storefront_rounded, size: 18, color: AppColors.dark),
                      const SizedBox(width: 6),
                      Text(
                        cart.restaurant?.name ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  for (final i in cart.items)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              '${i.quantity} × ${i.product.name}',
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text(
                            formatSom(i.total),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  const Divider(height: 20),
                  _row('Taomlar summasi', formatSom(cart.subtotal)),
                  const SizedBox(height: 6),
                  _row('Yetkazib berish xizmati', formatSom(kDeliveryFee)),
                  const Divider(height: 20),
                  _row('Jami to\'lov', formatSom(total), bold: true),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: ElevatedButton(
            onPressed: _loading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.dark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            child: _loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: AppColors.dark,
                    ),
                  )
                : Text('Buyurtma berish · ${formatSom(total)}'),
          ),
        ),
      ),
    );
  }

  Widget _title(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleMedium
            ?.copyWith(fontWeight: FontWeight.w800, fontSize: 17),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(
      fontWeight: bold ? FontWeight.w900 : FontWeight.w500,
      fontSize: bold ? 17 : 14,
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  const _PaymentOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.tag,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkSurface : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.dark : (isDark ? Colors.white10 : AppColors.borderLight),
            width: isSelected ? 2 : 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.greyLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.dark, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                      ),
                      if (tag != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag!,
                            style: const TextStyle(
                              color: AppColors.dark,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(color: AppColors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppColors.dark : AppColors.grey,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}