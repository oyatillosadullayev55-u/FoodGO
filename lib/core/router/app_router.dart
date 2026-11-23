import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';

import '../config/app_flavor.dart';

/// Barcha ilovalar uchun umumiy yo'llar nomlari.
/// Sahifalarning o'zi har bir ilovaning routes_*.dart faylida bog'lanadi,
/// shunda ilova faqat o'ziga kerakli kodni o'z ichiga oladi.
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

/// Joriy ilovaning routeri. [initRouter] ishga tushishda bir marta chaqiriladi.
late GoRouter appRouter;

void initRouter(AppFlavor flavor, List<RouteBase> routes) {
  appRouter = GoRouter(
    // Veb-mijoz katalogni darhol ko'rsatadi, qolganlar splash orqali.
    initialLocation: (kIsWeb && flavor == AppFlavor.customer)
        ? AppRoutes.customerHome
        : AppRoutes.splash,
    routes: routes,
  );
}
