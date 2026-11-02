import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'cart/cart_provider.dart';

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _destinations = <_Branch>[
    _Branch(Icons.storefront_outlined, Icons.storefront_rounded, 'Asosiy'),
    _Branch(Icons.search_rounded, Icons.search_rounded, 'Qidiruv'),
    _Branch(Icons.shopping_basket_outlined, Icons.shopping_basket_rounded,
        'Savat'),
    _Branch(Icons.receipt_long_outlined, Icons.receipt_long_rounded,
        'Buyurtmalar'),
    _Branch(Icons.person_outline_rounded, Icons.person_rounded, 'Profil'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider.select((c) => c.count));
    final isWide = MediaQuery.sizeOf(context).width >= 900;

    void onSelected(int i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        );

    return Scaffold(
      body: Column(
        children: [
          if (isWide)
            _WebHeader(
              currentIndex: navigationShell.currentIndex,
              cartCount: count,
              onSelected: onSelected,
            ),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : NavigationBar(
              selectedIndex: navigationShell.currentIndex,
              onDestinationSelected: onSelected,
              destinations: [
                for (var i = 0; i < _destinations.length; i++)
                  NavigationDestination(
                    icon: _destinations[i].iconData(count, selected: false),
                    selectedIcon:
                        _destinations[i].iconData(count, selected: true),
                    label: _destinations[i].label,
                  ),
              ],
            ),
    );
  }
}

class _Branch {
  const _Branch(this.icon, this.selectedIcon, this.label);

  final IconData icon;
  final IconData selectedIcon;
  final String label;

  Widget iconData(int cartCount, {required bool selected}) {
    final Widget child = Icon(selected ? selectedIcon : icon);
    if (label != 'Savat') return child;
    return Badge.count(
      count: cartCount,
      isLabelVisible: cartCount > 0,
      backgroundColor: AppColors.primary,
      textColor: AppColors.dark,
      textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
      child: child,
    );
  }
}

/// Katta ekranlar uchun yuqori navigatsiya paneli.
class _WebHeader extends StatelessWidget {
  const _WebHeader({
    required this.currentIndex,
    required this.cartCount,
    required this.onSelected,
  });

  final int currentIndex;
  final int cartCount;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.white10 : AppColors.borderLight,
          ),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SizedBox(
            height: 68,
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.delivery_dining_rounded,
                    color: AppColors.dark,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 10),
                const Text(
                  'FoodGo',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(width: 28),
                for (var i = 0; i < CustomerShell._destinations.length; i++)
                  _WebTab(
                    branch: CustomerShell._destinations[i],
                    cartCount: cartCount,
                    selected: currentIndex == i,
                    onTap: () => onSelected(i),
                  ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurfaceElevated : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.location_on_rounded,
                          size: 17, color: AppColors.dark),
                      SizedBox(width: 5),
                      Text(
                        'Toshkent',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 10),
                      Icon(Icons.bolt_rounded,
                          size: 16, color: AppColors.accentRed),
                      SizedBox(width: 2),
                      Text(
                        '25 daq',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                    ],
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

class _WebTab extends StatelessWidget {
  const _WebTab({
    required this.branch,
    required this.cartCount,
    required this.selected,
    required this.onTap,
  });

  final _Branch branch;
  final int cartCount;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: Material(
        color: selected
            ? AppColors.primary
            : (isDark ? AppColors.darkSurface : Colors.white),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            child: Row(
              children: [
                IconTheme(
                  data: IconThemeData(
                    size: 19,
                    color: selected ? AppColors.dark : AppColors.grey,
                  ),
                  child: branch.iconData(cartCount, selected: false),
                ),
                const SizedBox(width: 7),
                Text(
                  branch.label,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                    color: selected ? AppColors.dark : AppColors.grey,
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
