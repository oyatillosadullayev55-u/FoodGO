import 'bootstrap.dart';
import 'core/config/app_flavor.dart';
import 'core/router/routes_admin.dart';

/// "OsonGo Admin": administrator ilovasi (xodim qo'shish va chiqarish).
///   flutter run --flavor admin -t lib/main_admin.dart
/// Kompyuterda veb-panel sifatida ham ishlaydi:
///   flutter run -d chrome -t lib/main_admin.dart
Future<void> main() => bootstrap(
  flavor: AppFlavor.admin,
  routes: adminRoutes(),
);
