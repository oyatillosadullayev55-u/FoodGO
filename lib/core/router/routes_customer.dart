import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/onboarding_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/customer/cart/cart_page.dart';
import '../../features/customer/checkout/checkout_page.dart';
import '../../features/customer/customer_shell.dart';
import '../../features/customer/home/home_page.dart';
import '../../features/customer/orders/order_detail_page.dart';
import '../../features/customer/orders/orders_page.dart';
import '../../features/customer/profile/profile_page.dart';
import '../../features/customer/restaurants/restaurant_page.dart';
import '../../features/customer/search/search_page.dart';
import 'app_router.dart';
import 'routes_common.dart';

/// "OsonGo" (mijoz) ilovasi yo'llari.
List<RouteBase> customerRoutes() => [
  ...commonRoutes(),
  GoRoute(
    path: AppRoutes.onboarding,
    builder: (_, _) => const OnboardingPage(),
  ),
  GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterPage()),

  // ===== Mijoz: pastki navigatsiya =====
  StatefulShellRoute.indexedStack(
    builder: (context, state, shell) => CustomerShell(navigationShell: shell),
    branches: [
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.customerHome,
            builder: (_, _) => const HomePage(),
            routes: [
              GoRoute(
                path: 'restaurant/:id',
                builder: (_, state) =>
                    RestaurantPage(restaurantId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.customerSearch,
            builder: (_, _) => const SearchPage(),
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.customerCart,
            builder: (_, _) => const CartPage(),
            routes: [
              GoRoute(
                path: 'checkout',
                builder: (_, _) => const CheckoutPage(),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.customerOrders,
            builder: (_, _) => const OrdersPage(),
            routes: [
              GoRoute(
                path: ':id',
                builder: (_, state) =>
                    OrderDetailPage(orderId: state.pathParameters['id']!),
              ),
            ],
          ),
        ],
      ),
      StatefulShellBranch(
        routes: [
          GoRoute(
            path: AppRoutes.customerProfile,
            builder: (_, _) => const ProfilePage(),
          ),
        ],
      ),
    ],
  ),
];
