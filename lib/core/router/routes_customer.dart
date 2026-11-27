import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/onboarding_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/customer/cart/cart_page.dart';
import '../../features/customer/catalog/products_page.dart';
import '../../features/customer/catalog/restaurants_page.dart';
import '../../features/customer/catalog/services_page.dart';
import '../../features/customer/catalog/shops_page.dart';
import '../../features/customer/checkout/checkout_page.dart';
import '../../features/customer/customer_shell.dart';
import '../../features/customer/delivery/delivery_page.dart';
import '../../features/customer/home/home_page.dart';
import '../../features/customer/masters/master_detail_page.dart';
import '../../features/customer/masters/masters_page.dart';
import '../../features/customer/messages/messages_page.dart';
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
  // Tarmoqlar tartibi customer_shell.dart dagi menyu bilan bir xil.
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
              GoRoute(
                path: 'restaurants',
                builder: (_, _) => const RestaurantsPage(),
              ),
              GoRoute(path: 'shops', builder: (_, _) => const ShopsPage()),
              GoRoute(
                path: 'products',
                builder: (_, _) => const ProductsPage(),
              ),
              GoRoute(
                path: 'masters',
                builder: (_, _) => const MastersPage(),
                routes: [
                  GoRoute(
                    path: ':id',
                    builder: (_, state) =>
                        MasterDetailPage(masterId: state.pathParameters['id']!),
                  ),
                ],
              ),
              GoRoute(
                path: 'delivery',
                builder: (_, _) => const DeliveryPage(),
              ),
              GoRoute(
                path: 'services',
                builder: (_, _) => const ServicesPage(),
              ),
            ],
          ),
          GoRoute(
            path: AppRoutes.customerSearch,
            builder: (_, _) => const SearchPage(),
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
            path: AppRoutes.customerMessages,
            builder: (_, _) => const MessagesPage(),
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
