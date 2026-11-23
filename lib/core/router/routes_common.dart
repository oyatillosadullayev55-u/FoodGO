import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_page.dart';
import '../../features/auth/presentation/reset_password_page.dart';
import '../../features/auth/presentation/role_gate_page.dart';
import '../../features/auth/presentation/splash_page.dart';
import 'app_router.dart';

/// Uch ilovaga ham kerak bo'ladigan yo'llar.
List<RouteBase> commonRoutes() => [
  GoRoute(path: AppRoutes.splash, builder: (_, _) => const SplashPage()),
  GoRoute(path: AppRoutes.login, builder: (_, _) => const LoginPage()),
  GoRoute(
    path: AppRoutes.resetPassword,
    builder: (_, state) => ResetPasswordPage(
      initialEmail: state.uri.queryParameters['email'] ?? '',
    ),
  ),
  GoRoute(path: AppRoutes.gate, builder: (_, _) => const RoleGatePage()),
];
