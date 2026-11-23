// Standart kirish nuqtasi: mijozlar ilovasi ("OsonGo").
// Boshqa ilovalar: lib/main_partner.dart va lib/main_admin.dart.
import 'bootstrap.dart';
import 'core/config/app_flavor.dart';
import 'core/router/routes_customer.dart';

Future<void> main() => bootstrap(
  flavor: AppFlavor.customer,
  routes: customerRoutes(),
);
