import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import 'cart/cart_provider.dart';

class CustomerShell extends ConsumerWidget {
  const CustomerShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(cartProvider.select((c) => c.count));

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.storefront_outlined),
            selectedIcon: Icon(Icons.storefront_rounded),
            label: 'Asosiy',
          ),
          const NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Qidiruv',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: count,
              isLabelVisible: count > 0,
              backgroundColor: AppColors.primary,
              textColor: AppColors.dark,
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
              child: const Icon(Icons.shopping_basket_outlined),
            ),
            selectedIcon: Badge.count(
              count: count,
              isLabelVisible: count > 0,
              backgroundColor: AppColors.primary,
              textColor: AppColors.dark,
              textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 11),
              child: const Icon(Icons.shopping_basket_rounded),
            ),
            label: 'Savat',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Buyurtmalar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}