// Har bir asosiy ekran xatosiz (shu jumladan RenderFlex overflow'siz)
// chizilishini tekshiradi. Serverga ulanmaydi.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:osongo/core/router/app_router.dart';
import 'package:osongo/core/router/routes_customer.dart';
import 'package:osongo/features/admin/admin_home_page.dart';
import 'package:osongo/features/admin/admin_providers.dart';
import 'package:osongo/features/auth/data/user_profile.dart';
import 'package:osongo/features/auth/providers/auth_providers.dart';
import 'package:osongo/features/courier/courier_home_page.dart';
import 'package:osongo/features/courier/courier_location.dart';
import 'package:osongo/features/customer/orders/orders_providers.dart';
import 'package:osongo/features/delivery/delivery_providers.dart';
import 'package:osongo/features/marketplace/marketplace_providers.dart';
import 'package:osongo/features/master/master_home_page.dart';
import 'package:osongo/features/master/master_providers.dart';
import 'package:osongo/features/partner/documents_card.dart';
import 'package:osongo/features/restaurant/restaurant_home_page.dart';
import 'package:osongo/models/food_order.dart';
import 'package:osongo/models/marketplace.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'support/demo_data.dart';
import 'support/harness.dart';

const _orderId = 'a1b2c3d4-0000-4000-8000-000000000000';

/// Almashtirilmagan so'rov tashqariga chiqmasligi uchun mahalliy manzil.
final _offline = SupabaseClient(
  'http://127.0.0.1:1',
  'test',
  authOptions: const AuthClientOptions(autoRefreshToken: false),
);

List<Override> _common([UserProfile user = customer]) => [
  supabaseProvider.overrideWithValue(_offline),
  profileProvider.overrideWith((ref) => user),
  notificationsProvider.overrideWith((ref) => notifications),
  servicesProvider.overrideWith((ref) => kDefaultServices),
  promotionsProvider.overrideWith((ref) => <Promotion>[]),
  categoriesByKindProvider.overrideWith(
    (ref, kind) => switch (kind) {
      'shop' => shopCategories,
      'master' => masterCategories,
      _ => foodCategories,
    },
  ),
  storesProvider.overrideWith(
    (ref, args) => args.kind == 'shop' ? [shop] : restaurants,
  ),
  shopProductsProvider.overrideWith((ref, category) => shopProducts),
  mastersProvider.overrideWith((ref, category) => masters),
  masterProvider.overrideWith((ref, id) => masters.first),
  masterReviewsProvider.overrideWith(
    (ref, id) => [
      Review(
        rating: 5,
        createdAt: DateTime.now(),
        customerName: 'Dilnoza',
        comment: 'Tez va sifatli bajardi.',
      ),
    ],
  ),
  myServiceRequestsProvider.overrideWith(
    (ref) => Stream.value(serviceRequests),
  ),
  ordersProvider.overrideWith(
    (ref) => Stream.value([order('a1b2c3d4', OrderStatus.onTheWay)]),
  ),
  orderProvider.overrideWith(
    (ref, id) => order('a1b2c3d4', OrderStatus.onTheWay),
  ),
  orderStatusProvider.overrideWith(
    (ref, id) => Stream.value(OrderStatus.onTheWay),
  ),
  orderLinesProvider.overrideWith((ref, id) => orderLines),
  orderCourierProvider.overrideWith(
    (ref, id) => Stream.value(
      const OrderCourier(
        fullName: 'Azizbek',
        phone: '+998 90 123 45 67',
        lat: 40.3870,
        lng: 71.7860,
      ),
    ),
  ),
  myDocumentsProvider.overrideWith((ref) => <Map<String, dynamic>>[]),
];

void main() {
  setUpAll(() async {
    await loadFonts();
    mockMapCacheDirectory();
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));

  final customerScreens = <String, String>{
    'customer_home': AppRoutes.customerHome,
    'customer_restaurants': AppRoutes.restaurants,
    'customer_shops': AppRoutes.shops,
    'customer_products': AppRoutes.products,
    'customer_masters': AppRoutes.masters,
    'customer_master': AppRoutes.masterPath('m1'),
    'customer_services': AppRoutes.services,
    'customer_delivery': AppRoutes.delivery,
    'customer_orders': AppRoutes.customerOrders,
    'customer_tracking': AppRoutes.orderPath(_orderId),
    'customer_messages': AppRoutes.customerMessages,
  };

  for (final entry in customerScreens.entries) {
    for (final (suffix, size) in const [
      ('', phone),
      ('_small', Size(320, 640)),
    ]) {
      testWidgets('mijoz: ${entry.key}$suffix', (tester) async {
        await pumpScreen(
          tester,
          size: size,
          overrides: _common(),
          routes: customerRoutes(),
          route: entry.value,
        );
        expect(tester.takeException(), isNull);
        if (suffix.isEmpty) await capture(tester, entry.key);
        await closeScreen(tester);
      });
    }
  }

  testWidgets("bosh sahifada 6 ta bo'lim va markaziy savat bor", (
    tester,
  ) async {
    await pumpScreen(
      tester,
      overrides: _common(),
      routes: customerRoutes(),
      route: AppRoutes.customerHome,
    );
    for (final service in kDefaultServices) {
      expect(find.text(service.title), findsOneWidget);
    }
    await tester.tap(find.text('Ustalar'));
    await settle(tester);
    expect(find.text('Ali Usta'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await closeScreen(tester);
  });

  List<Override> storeOverrides({bool isShop = false}) => [
    ..._common(),
    myRestaurantsProvider.overrideWith(
      (ref) => [isShop ? shop : restaurants.first],
    ),
    restaurantOrdersProvider.overrideWith(
      (ref, id) => Stream.value([
        order('a1b2c3d4', OrderStatus.pending),
        order('b2c3d4e5', OrderStatus.pending, ago: const Duration(minutes: 12)),
        order('c3d4e5f6', OrderStatus.preparing, ago: const Duration(minutes: 6)),
        order('d4e5f6a7', OrderStatus.onTheWay, ago: const Duration(minutes: 25)),
      ]),
    ),
    restaurantProductsProvider.overrideWith(
      (ref, id) => [for (final p in shopProducts) p.product],
    ),
    storeIncomeProvider.overrideWith(
      (ref, id) => [
        for (var i = 0; i < 9; i++)
          order(
            'e${i}f6a7b8',
            OrderStatus.delivered,
            ago: Duration(days: i),
            total: 70000 + i * 13000,
          ),
      ],
    ),
  ];

  for (final (name, size) in const [('phone', phone), ('desktop', desktop)]) {
    testWidgets('restoran paneli ($name): barcha tablar', (tester) async {
      await pumpScreen(
        tester,
        size: size,
        overrides: storeOverrides(),
        home: const RestaurantHomePage(),
      );
      expect(tester.takeException(), isNull);
      await capture(tester, 'restaurant_orders_$name');
      for (final tab in ['Menyu', 'Daromad', 'Profil']) {
        await tester.tap(find.text(tab).last);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: tab);
        if (name == 'phone') await capture(tester, 'restaurant_$tab');
      }
      await closeScreen(tester);
    });
  }

  testWidgets("magazin paneli: ombor qoldig'i ko'rinadi", (tester) async {
    await pumpScreen(
      tester,
      overrides: storeOverrides(isShop: true),
      home: const RestaurantHomePage(),
    );
    await tester.tap(find.text('Mahsulotlar').last);
    await settle(tester);
    expect(find.text('Omborda: 3 dona'), findsOneWidget);
    expect(find.text("2 ta mahsulot qoldig'i kam yoki tugagan"), findsOneWidget);
    expect(tester.takeException(), isNull);
    await capture(tester, 'shop_products');
    await closeScreen(tester);
  });

  testWidgets('usta paneli: barcha tablar', (tester) async {
    await pumpScreen(
      tester,
      overrides: [
        ..._common(),
        myMasterProvider.overrideWith((ref) => masters.first),
        masterRequestsProvider.overrideWith(
          (ref, id) => Stream.value(serviceRequests),
        ),
      ],
      home: const MasterHomePage(),
    );
    expect(find.text('Qabul qilish'), findsOneWidget);
    await capture(tester, 'master_requests');
    for (final tab in ['Daromad', 'Baholar', 'Profil']) {
      await tester.tap(find.text(tab).last);
      await settle(tester);
      expect(tester.takeException(), isNull, reason: tab);
      if (tab == 'Daromad') await capture(tester, 'master_income');
    }
    await closeScreen(tester);
  });

  for (final active in [false, true]) {
    testWidgets('kuryer paneli (faol buyurtma: $active)', (tester) async {
      await pumpScreen(
        tester,
        overrides: [
          ..._common(courierProfile),
          courierPositionProvider.overrideWith(
            (ref) => Stream.value(const LatLng(40.3860, 71.7870)),
          ),
          courierOrdersProvider.overrideWith(
            (ref) => Stream.value([
              if (active) order('a1b2c3d4', OrderStatus.onTheWay),
            ]),
          ),
          availableOrdersProvider.overrideWith(
            (ref) => Stream.value([
              order('b2c3d4e5', OrderStatus.readyForPickup),
            ]),
          ),
          courierIncomeProvider.overrideWith(
            (ref) => [order('c3d4e5f6', OrderStatus.delivered)],
          ),
        ],
        home: const CourierHomePage(),
      );
      // Faol buyurtmada joylashuv yuborishga urinish xatosi yutiladi.
      expect(tester.takeException(), isNull);
      await capture(tester, active ? 'courier_active' : 'courier_new');
      for (final tab in ['Daromad', 'Profil']) {
        await tester.tap(find.text(tab).last);
        await settle(tester);
        expect(tester.takeException(), isNull, reason: tab);
      }
      await closeScreen(tester);
    });
  }

  List<Override> adminOverrides() => [
    ..._common(),
    adminAnalyticsProvider.overrideWith((ref, days) => adminAnalytics),
    adminFraudProvider.overrideWith(
      (ref) => [
        {
          'signal': 'order_burst',
          'severity': 'high',
          'subject_id': 'x',
          'subject': 'Foydalanuvchi',
          'detail': "1 soat ichida ko'p buyurtma",
          'hits': 7,
        },
      ],
    ),
    adminUsersProvider.overrideWith(
      (ref, args) => [
        {
          'id': 'u1',
          'full_name': 'Dilnoza Karimova',
          'email': 'dilnoza@example.com',
          'phone': '+998901112233',
          'role': 'customer',
          'is_blocked': false,
        },
      ],
    ),
    adminTableProvider.overrideWith((ref, query) => _adminRows(query.table)),
  ];

  for (final section in AdminSection.values) {
    for (final (name, size) in const [('phone', phone), ('desktop', desktop)]) {
      testWidgets('admin: ${section.name} ($name)', (tester) async {
        // Xodimlar sahifasi o'z provayderidan o'qiydi: serversiz xato
        // ko'rinishi ham yiqilmasdan chizilishi kerak.
        await pumpScreen(
          tester,
          size: size,
          overrides: adminOverrides(),
          home: AdminHomePage(initial: section),
        );
        expect(tester.takeException(), isNull);
        if (name == 'desktop' ||
            section == AdminSection.verification) {
          await capture(tester, 'admin_${section.name}_$name');
        }
        await closeScreen(tester);
      });
    }
  }

  testWidgets("admin: tahrirlash oynasi majburiy maydonni tekshiradi", (
    tester,
  ) async {
    await pumpScreen(
      tester,
      size: desktop,
      overrides: adminOverrides(),
      home: const AdminHomePage(initial: AdminSection.regions),
    );
    await tester.tap(find.text('Yangi hudud'));
    await settle(tester);
    await tester.tap(find.text('Saqlash'));
    await settle(tester);
    expect(find.text('Nomi kiritilishi shart'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await closeScreen(tester);
  });
}

List<Map<String, dynamic>> _adminRows(String table) {
  const now = '2026-11-26T10:00:00Z';
  return switch (table) {
    'restaurants' => [
      {
        'id': 's1',
        'name': 'Yangi Magazin',
        'kind': 'shop',
        'owner_email': 'shop@example.com',
        'address': "Farg'ona",
        'verification_status': 'pending',
        'commission_percent': null,
      },
    ],
    'masters' => <Map<String, dynamic>>[],
    'services' => [
      for (final s in kDefaultServices)
        {
          'id': s.code,
          'code': s.code,
          'title': s.title,
          'route': s.route,
          'is_active': true,
        },
    ],
    'categories' => [
      {'id': 'c', 'name': 'Burger', 'kind': 'food', 'icon': null},
    ],
    'commission_rules' => [
      {'id': 'k', 'service_code': 'food', 'percent': 10},
    ],
    'subscription_plans' => [
      {
        'id': 'p',
        'title': 'Magazin Pro',
        'price': 299000,
        'period_days': 30,
        'audience': 'shop',
        'is_active': true,
      },
    ],
    'subscriptions' => [
      {
        'id': 'o',
        'starts_at': '2026-11-01',
        'ends_at': '2026-12-01',
        'status': 'active',
        'user_id': '12345678-abcd',
      },
    ],
    'promotions' => [
      {
        'id': 'a',
        'title': 'Dam olish kunlari chegirma',
        'starts_at': '2026-11-01',
        'ends_at': null,
        'discount_percent': 15,
        'is_active': false,
      },
    ],
    'notifications' => [
      {'id': 'n', 'title': 'Yangilik', 'body': 'Matn', 'audience': 'all'},
    ],
    'regions' => [
      {'id': 'r', 'name': "Farg'ona", 'kind': 'shahar'},
    ],
    'transactions' => [
      {
        'id': 't1',
        'kind': 'commission',
        'amount': 1732000,
        'status': 'done',
        'note': 'Buyurtma komissiyasi',
      },
      {'id': 't2', 'kind': 'refund', 'amount': 45000, 'status': 'pending'},
    ],
    'complaints' => [
      {
        'id': 'z',
        'subject': 'Buyurtma kechikdi',
        'body': 'Taom 1 soat kech yetib keldi.',
        'status': 'open',
        'created_at': now,
        'order_id': 'a1b2c3d4-0000',
        'refund_amount': 0,
      },
    ],
    _ => <Map<String, dynamic>>[],
  };
}
