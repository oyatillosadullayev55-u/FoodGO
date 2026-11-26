// Qolgan ekranlar va barcha asosiy dialoglar xatosiz ochilishi.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:osongo/core/router/app_router.dart';
import 'package:osongo/core/router/routes_customer.dart';
import 'package:osongo/features/admin/admin_home_page.dart';
import 'package:osongo/features/admin/admin_people_page.dart';
import 'package:osongo/features/admin/admin_providers.dart';
import 'package:osongo/features/auth/data/user_profile.dart';
import 'package:osongo/features/auth/providers/auth_providers.dart';
import 'package:osongo/features/customer/cart/cart_provider.dart';
import 'package:osongo/features/customer/home/home_providers.dart';
import 'package:osongo/features/customer/orders/orders_providers.dart';
import 'package:osongo/features/customer/restaurants/restaurant_providers.dart';
import 'package:osongo/features/delivery/delivery_providers.dart';
import 'package:osongo/features/marketplace/marketplace_providers.dart';
import 'package:osongo/features/master/master_home_page.dart';
import 'package:osongo/features/master/master_providers.dart';
import 'package:osongo/features/partner/documents_card.dart';
import 'package:osongo/features/restaurant/restaurant_home_page.dart';
import 'package:osongo/features/restaurant/restaurant_profile_page.dart';
import 'package:osongo/models/cart_item.dart';
import 'package:osongo/models/food_order.dart';
import 'package:osongo/models/marketplace.dart';
import 'package:osongo/repositories/staff_account_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/demo_data.dart';
import 'support/harness.dart';

final _offline = SupabaseClient(
  'http://127.0.0.1:1',
  'test',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

class _FilledCart extends CartNotifier {
  @override
  CartState build() => CartState(
    restaurant: restaurants.first,
    items: [CartItem(product: shopProducts.first.product, quantity: 2)],
  );
}

List<Override> _overrides() => [
  supabaseProvider.overrideWithValue(_offline),
  profileProvider.overrideWith((ref) => customer),
  notificationsProvider.overrideWith((ref) => notifications),
  cartProvider.overrideWith(_FilledCart.new),
  restaurantProvider.overrideWith((ref, id) => restaurants.first),
  productsProvider.overrideWith(
    (ref, id) => [for (final p in shopProducts) p.product],
  ),
  restaurantsProvider.overrideWith((ref) => restaurants),
  categoriesByKindProvider.overrideWith((ref, kind) => foodCategories),
  masterProvider.overrideWith((ref, id) => masters.first),
  masterReviewsProvider.overrideWith((ref, id) => <Review>[]),
  myDocumentsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
  myServiceRequestsProvider.overrideWith(
    (ref) => Stream.value(serviceRequests),
  ),
  ordersProvider.overrideWith((ref) => Stream.value(<FoodOrder>[])),
  myRestaurantsProvider.overrideWith((ref) => [shop]),
  restaurantOrdersProvider.overrideWith(
    (ref, id) => Stream.value([order('a1b2c3d4', OrderStatus.pending)]),
  ),
  restaurantProductsProvider.overrideWith(
    (ref, id) => [shopProducts.first.product],
  ),
  orderLinesProvider.overrideWith((ref, id) => orderLines),
  myMasterProvider.overrideWith((ref) => masters.first),
  masterRequestsProvider.overrideWith(
    (ref, id) => Stream.value([
      ServiceRequest(
        id: 'q3000000-0000',
        masterId: 'm1',
        serviceType: 'Rozetka',
        status: ServiceStatus.inProgress,
        addressText: "Farg'ona",
        phone: '+998901112233',
        createdAt: DateTime.now(),
      ),
    ]),
  ),
  staffListProvider.overrideWith(
    (ref) => const [
      StaffMember(id: 's', role: 'restaurant', fullName: 'Sardor'),
    ],
  ),
  adminTableProvider.overrideWith(
    (ref, query) => switch (query.table) {
      'masters' => [
        {
          'id': 'm',
          'full_name': 'Yangi Usta',
          'verification_status': 'pending',
        },
      ],
      'complaints' => [
        {
          'id': 'z',
          'subject': 'Kechikdi',
          'body': 'Kech keldi',
          'status': 'open',
          'created_at': '2026-11-26T10:00:00Z',
          'refund_amount': 0,
        },
      ],
      _ => <Map<String, dynamic>>[],
    },
  ),
];

Future<void> _expectClean(WidgetTester tester) async {
  await settle(tester);
  expect(tester.takeException(), isNull);
}

void main() {
  setUpAll(() async {
    await loadFonts();
    mockMapCacheDirectory();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final routes = <String, String>{
    'restaurant': AppRoutes.restaurantPath('r1'),
    'search': AppRoutes.customerSearch,
    'cart': AppRoutes.customerCart,
    'checkout': AppRoutes.customerCheckout,
    'profile': AppRoutes.customerProfile,
    'login': AppRoutes.login,
    'register': AppRoutes.register,
    'onboarding': AppRoutes.onboarding,
  };

  for (final entry in routes.entries) {
    for (final (suffix, size) in const [
      ('', phone),
      ('_small', Size(320, 640)),
    ]) {
      testWidgets('ekran: ${entry.key}$suffix', (tester) async {
        await pumpScreen(
          tester,
          size: size,
          overrides: _overrides(),
          routes: customerRoutes(),
          route: entry.value,
        );
        expect(tester.takeException(), isNull);
        if (suffix.isEmpty) await capture(tester, 'extra_${entry.key}');
        await closeScreen(tester);
      });
    }
  }

  testWidgets("do'kon ma'lumotlarini tahrirlash sahifasi", (tester) async {
    await pumpScreen(
      tester,
      overrides: _overrides(),
      home: RestaurantProfilePage(restaurant: shop),
    );
    expect(tester.takeException(), isNull);
    await closeScreen(tester);
  });

  testWidgets('magazin: mahsulot oynasi va buyurtma tafsiloti', (
    tester,
  ) async {
    await pumpScreen(
      tester,
      overrides: _overrides(),
      home: const RestaurantHomePage(),
    );
    await tester.tap(find.textContaining('#a1b2c3d4'));
    await _expectClean(tester);
    await tester.tapAt(const Offset(10, 10));
    await _expectClean(tester);

    await tester.tap(find.byTooltip('Rad etish'));
    await _expectClean(tester);
    await tester.tap(find.text("Yo'q"));
    await _expectClean(tester);

    await tester.tap(find.text('Mahsulotlar').last);
    await settle(tester);
    await tester.tap(find.text("Mahsulot qo'shish"));
    await _expectClean(tester);
    expect(find.text("Ombor qoldig'i"), findsOneWidget);
    await tester.tap(find.text('Saqlash'));
    await _expectClean(tester);
    expect(find.text("Nomi va narxini to'g'ri kiriting"), findsOneWidget);
    await closeScreen(tester);
  });

  testWidgets("usta: yakunlashda narx so'raladi", (tester) async {
    await pumpScreen(
      tester,
      overrides: _overrides(),
      home: const MasterHomePage(),
    );
    await tester.tap(find.text('Jarayonda (1)'));
    await settle(tester);
    await tester.tap(find.text('Yakunlash'));
    await _expectClean(tester);
    expect(find.text('Ish narxi'), findsOneWidget);
    await closeScreen(tester);
  });

  testWidgets("mijoz: mehmon bo'lmagan holda usta chaqirish formasi", (
    tester,
  ) async {
    await pumpScreen(
      tester,
      overrides: _overrides(),
      routes: customerRoutes(),
      route: AppRoutes.masterPath('m1'),
    );
    await tester.tap(find.text('Ustani chaqirish'));
    await _expectClean(tester);
    await tester.tap(find.text("So'rov yuborish"));
    await _expectClean(tester);
    expect(find.text("Manzilni to'liq kiriting"), findsOneWidget);
    await closeScreen(tester);
  });

  testWidgets('mijoz: shikoyat va baholash oynalari', (tester) async {
    await pumpScreen(
      tester,
      overrides: _overrides(),
      routes: customerRoutes(),
      route: AppRoutes.customerOrders,
    );
    await tester.tap(find.text('Xizmatlar'));
    await settle(tester);
    await tester.tap(find.text('Baholash'));
    await _expectClean(tester);
    await tester.tap(find.text('Bekor qilish').last);
    await settle(tester);
    await tester.tap(find.text('Shikoyat').first);
    await _expectClean(tester);
    await tester.tap(find.text('Yuborish'));
    await _expectClean(tester);
    expect(find.text('Mavzu va tafsilotni yozing'), findsOneWidget);
    await closeScreen(tester);
  });

  testWidgets('admin: xodim yaratish va chiqarish oynalari', (tester) async {
    await pumpScreen(
      tester,
      size: desktop,
      overrides: _overrides(),
      home: const AdminHomePage(initial: AdminSection.staff),
    );
    await tester.tap(find.byTooltip('Chiqarish'));
    await _expectClean(tester);
    await tester.tap(find.text('Bekor qilish'));
    await settle(tester);
    await tester.tap(find.text('Yangi xodim'));
    await _expectClean(tester);
    await tester.tap(find.text(UserRole.restaurant.label));
    await settle(tester);
    await tester.tap(find.text('Usta').last);
    await _expectClean(tester);
    await closeScreen(tester);
  });

  testWidgets('admin: komissiya va nizo oynalari', (tester) async {
    await pumpScreen(
      tester,
      size: desktop,
      overrides: _overrides(),
      home: const AdminHomePage(initial: AdminSection.verification),
    );
    await tester.tap(find.text('Ustalar'));
    await settle(tester);
    await tester.tap(find.text('Komissiya: umumiy'));
    await _expectClean(tester);
    await tester.tap(find.text('Bekor qilish'));
    await settle(tester);
    await closeScreen(tester);

    await pumpScreen(
      tester,
      size: desktop,
      overrides: _overrides(),
      home: const AdminHomePage(initial: AdminSection.disputes),
    );
    await tester.tap(find.text('Qaror qabul qilish'));
    await _expectClean(tester);
    await tester.tap(find.text('Hal qilindi').last);
    await _expectClean(tester);
    expect(find.text('Qaror matnini yozing'), findsOneWidget);
    await closeScreen(tester);
  });
}
