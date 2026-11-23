import 'bootstrap.dart';
import 'core/config/app_flavor.dart';
import 'core/router/routes_partner.dart';

/// "OsonGo Hamkor": restoran egalari va kuryerlar ilovasi.
///   flutter run --flavor partner -t lib/main_partner.dart
Future<void> main() => bootstrap(
  flavor: AppFlavor.partner,
  routes: partnerRoutes(),
);
