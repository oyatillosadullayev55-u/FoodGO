import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_wordmark.dart';
import '../marketplace/marketplace_providers.dart';
import 'cart/cart_provider.dart';

/// Tarmoqlar tartibi routes_customer.dart bilan bir xil.
const _destinations = <(IconData, IconData, String)>[
  (Icons.home_outlined, Icons.home_rounded, 'Bosh sahifa'),
  (Icons.access_time_rounded, Icons.access_time_filled_rounded, 'Buyurtmalar'),
  (Icons.shopping_cart_outlined, Icons.shopping_cart_rounded, 'Savat'),
  (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Xabarlar'),
  (Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
];

const _cartIndex = 2;
const _messagesIndex = 3;

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider.select((c) => c.count));
    final unread = ref.watch(unreadNotificationsProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 900;
    final current = navigationShell.currentIndex;

    void onSelected(int i) =>
        navigationShell.goBranch(i, initialLocation: i == current);

    int badge(int i) => switch (i) {
      _cartIndex => cart,
      _messagesIndex => unread,
      _ => 0,
    };

    return Scaffold(
      body: Column(
        children: [
          if (isWide)
            _WebHeader(current: current, badge: badge, onSelected: onSelected),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : _BottomBar(current: current, badge: badge, onSelected: onSelected),
    );
  }
}

Widget _withBadge(int count, Widget child) => Badge.count(
  count: count,
  isLabelVisible: count > 0,
  backgroundColor: AppColors.accentRed,
  child: child,
);

/// Pastki menyu: o'rtada ko'tarilgan savat tugmasi.
class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.current,
    required this.badge,
    required this.onSelected,
  });

  final int current;
  final int Function(int) badge;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 66,
          child: Row(
            children: [
              for (var i = 0; i < _destinations.length; i++)
                Expanded(
                  child: i == _cartIndex
                      ? _CartButton(
                          count: badge(i),
                          selected: current == i,
                          onTap: () => onSelected(i),
                        )
                      : _NavItem(
                          destination: _destinations[i],
                          count: badge(i),
                          selected: current == i,
                          onTap: () => onSelected(i),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.destination,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final (IconData, IconData, String) destination;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, activeIcon, label) = destination;
    final color = selected ? AppColors.primary : AppColors.grey;
    return Semantics(
      selected: selected,
      button: true,
      child: InkResponse(
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _withBadge(
              count,
              Icon(selected ? activeIcon : icon, color: color, size: 25),
            ),
            const SizedBox(height: 3),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CartButton extends StatelessWidget {
  const _CartButton({
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        selected: selected,
        button: true,
        label: 'Savat',
        child: _withBadge(
          count,
          Material(
            color: selected ? AppColors.primaryDark : AppColors.primary,
            shape: const CircleBorder(),
            elevation: 6,
            shadowColor: AppColors.primary,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onTap,
              child: const SizedBox(
                width: 54,
                height: 54,
                child: Icon(Icons.shopping_cart_rounded, color: Colors.white),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Katta ekranlar uchun yuqori navigatsiya paneli.
class _WebHeader extends StatelessWidget {
  const _WebHeader({
    required this.current,
    required this.badge,
    required this.onSelected,
  });

  final int current;
  final int Function(int) badge;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                const BrandLogo(size: 40),
                const SizedBox(width: 10),
                const BrandWordmark(size: 22),
                const Spacer(),
                for (var i = 0; i < _destinations.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: TextButton.icon(
                      onPressed: () => onSelected(i),
                      style: TextButton.styleFrom(
                        backgroundColor: current == i ? AppColors.primary : null,
                        foregroundColor: current == i
                            ? Colors.white
                            : AppColors.grey,
                      ),
                      icon: _withBadge(
                        badge(i),
                        Icon(_destinations[i].$1, size: 19),
                      ),
                      label: Text(_destinations[i].$3),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
