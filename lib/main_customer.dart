import 'bootstrap.dart';
import 'core/config/app_flavor.dart';
import 'core/router/routes_customer.dart';

/// "OsonGo": mijozlar ilovasi.
///   flutter run --flavor customer -t lib/main_customer.dart
Future<void> main() => bootstrap(
  flavor: AppFlavor.customer,
  routes: customerRoutes(),
);
