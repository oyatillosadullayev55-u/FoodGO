import 'package:go_router/go_router.dart';

import '../../features/admin/admin_home_page.dart';
import '../../features/auth/data/user_profile.dart';
import '../widgets/role_guard.dart';
import 'app_router.dart';
import 'routes_common.dart';

/// "OsonGo Admin" ilovasi yo'llari.
List<RouteBase> adminRoutes() => [
  ...commonRoutes(),
  GoRoute(
    path: AppRoutes.adminHome,
    builder: (_, _) => const RoleGuard(
      allowed: {UserRole.admin},
      child: AdminHomePage(),
    ),
  ),
];
