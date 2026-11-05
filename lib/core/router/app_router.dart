import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

import '../../features/admin/admin_home_page.dart';
import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/onboarding_page.dart';
import '../../features/auth/presentation/register_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/auth/presentation/role_gate_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import '../../features/auth/data/user_profile.dart';
import '../../features/courier/courier_home_page.dart';
import '../../features/customer/cart/cart_page.dart';
import '../../features/customer/checkout/checkout_page.dart';
import '../../features/customer/customer_shell.dart';
import '../../features/customer/home/home_page.dart';
import '../../features/customer/orders/order_detail_page.dart';
import '../../features/customer/orders/orders_page.dart';
import '../../features/customer/profile/profile_page.dart';
import '../../features/customer/restaurants/restaurant_page.dart';
import '../../features/customer/search/search_page.dart';
import '../../features/restaurant/restaurant_home_page.dart';
import '../widgets/role_guard.dart';

class AppRoutes {
  static const splash = '/';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const register = '/register';
  static const resetPassword = '/reset-password';
  static const gate = '/gate';

  static const customerHome = '/customer/home';
  static const customerSearch = '/customer/search';
  static const customerCart = '/customer/cart';
  static const customerCheckout = '/customer/cart/checkout';
  static const customerOrders = '/customer/orders';
  static const customerProfile = '/customer/profile';

  static String restaurantPath(String id) => '/customer/home/restaurant/$id';
  static String orderPath(String id) => '/customer/orders/$id';

  static const courierHome = '/courier';
  static const restaurantHome = '/restaurant';
  static const adminHome = '/admin';
}

final appRouter = GoRouter(
  initialLocation: kIsWeb ? AppRoutes.customerHome : AppRoutes.splash,
  routes: [
    GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
    GoRoute(
      path: AppRoutes.onboarding,
      builder: (_, _) => const OnboardingPage(),
    ),
    GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
    GoRoute(path: AppRoutes.register, builder: (_, _) => const RegisterPage()),
    GoRoute(
      path: AppRoutes.resetPassword,
      builder: (_, state) => ResetPasswordPage(
        initialEmail: state.uri.queryParameters['email'] ?? '',
      ),
    ),
    GoRoute(path: AppRoutes.gate, builder: (_, _) => const RoleGatePage()),

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

    // ===== Boshqa rollar (faqat tegishli rol kira oladi) =====
    GoRoute(
      path: AppRoutes.courierHome,
      builder: (_, _) => const RoleGuard(
        allowed: {UserRole.courier},
        child: CourierHomePage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.restaurantHome,
      builder: (_, _) => const RoleGuard(
        allowed: {UserRole.restaurant},
        child: RestaurantHomePage(),
      ),
    ),
    GoRoute(
      path: AppRoutes.adminHome,
      builder: (_, _) =>
          const RoleGuard(allowed: {UserRole.admin}, child: AdminHomePage()),
    ),
  ],
);
