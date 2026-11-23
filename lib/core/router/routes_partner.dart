import 'package:go_router/go_router.dart';

import '../../features/auth/data/user_profile.dart';
import '../../features/courier/courier_home_page.dart';
import '../../features/restaurant/restaurant_home_page.dart';
import '../widgets/role_guard.dart';
import 'app_router.dart';
import 'routes_common.dart';

/// "OsonGo Hamkor" (restoran va kuryer) ilovasi yo'llari.
List<RouteBase> partnerRoutes() => [
  ...commonRoutes(),
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
];
