import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:osongo/core/config/app_flavor.dart';
import 'package:osongo/core/errors/error_mapper.dart';
import 'package:osongo/core/router/app_router.dart';
import 'package:osongo/core/router/routes_customer.dart';
import 'package:osongo/core/router/routes_partner.dart';
import 'package:osongo/core/theme/app_colors.dart';
import 'package:osongo/core/utils/earnings.dart';
import 'package:osongo/core/utils/food_images.dart';
import 'package:osongo/core/widgets/role_guard.dart';
import 'package:osongo/features/admin/resource/admin_resource.dart';
import 'package:osongo/features/auth/data/user_profile.dart';
import 'package:osongo/features/customer/cart/cart_provider.dart';
import 'package:osongo/features/customer/home/service_tiles.dart';
import 'package:osongo/features/marketplace/marketplace_providers.dart';
import 'package:osongo/features/restaurant/order_board.dart';
import 'package:osongo/models/food_order.dart';
import 'package:osongo/models/marketplace.dart';
import 'package:osongo/models/product.dart';
import 'package:osongo/models/restaurant.dart';
import 'package:osongo/repositories/delivery_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Daromad', () {
    final now = DateTime(2026, 3, 5, 15);
    final summary = EarningsSummary.from(
      [
        (at: DateTime(2026, 3, 5, 9), amount: 100),
        (at: DateTime(2026, 3, 5, 14), amount: 50),
        (at: DateTime(2026, 3, 1), amount: 10),
        (at: DateTime(2026, 2, 28), amount: 7),
        (at: DateTime(2025, 3, 5), amount: 1000),
      ],
      now: now,
      days: 7,
    );

    test("bugun, shu oy va jami alohida hisoblanadi", () {
      expect((summary.today, summary.todayCount), (150, 2));
      expect((summary.month, summary.monthCount), (160, 3));
      expect((summary.total, summary.totalCount), (1167, 5));
    });

    test("diagramma oy chegarasidan o'tadi va bugun oxirida turadi", () {
      expect(summary.daily, hasLength(7));
      expect(summary.daily.first.day, DateTime(2026, 2, 27));
      expect(summary.daily[1].amount, 7);
      expect(summary.daily.last, (day: DateTime(2026, 3, 5), amount: 150));
    });

    test("so'rov oynasi oy boshi va 14 kundan ertarog'ini oladi", () {
      expect(
        DeliveryRepository.incomeSince(DateTime(2026, 3, 5)),
        DateTime(2026, 2, 20),
      );
      expect(
        DeliveryRepository.incomeSince(DateTime(2026, 3, 25)),
        DateTime(2026, 3),
      );
    });
  });

  group('Holatlar', () {
    test("usta o'tishlari serverdagi set_service_status bilan bir xil", () {
      final next = {
        for (final s in ServiceStatus.values)
          s.value: [for (final n in s.masterNext) n.value],
      };
      expect(next, {
        'new': ['accepted', 'rejected'],
        'accepted': ['on_the_way', 'in_progress', 'cancelled'],
        'on_the_way': ['in_progress', 'cancelled'],
        'in_progress': ['completed'],
        'completed': <String>[],
        'rejected': <String>[],
        'cancelled': <String>[],
      });
    });

    test('kuzatuv bosqichi orqaga qaytmaydi', () {
      const flow = [
        OrderStatus.pending,
        OrderStatus.accepted,
        OrderStatus.preparing,
        OrderStatus.readyForPickup,
        OrderStatus.courierAssigned,
        OrderStatus.pickedUp,
        OrderStatus.onTheWay,
        OrderStatus.delivered,
      ];
      expect(
        [for (final s in flow) s.trackingStep],
        [0, 0, 0, 1, 1, 2, 2, 3],
      );
    });

    test("taxta: har faol holat bitta ustunda, tugaganlari yo'q", () {
      for (final status in OrderStatus.values) {
        final columns = BoardColumn.values.where(
          (c) => c.statuses.contains(status),
        );
        expect(columns.length, status.isActive ? 1 : 0, reason: status.value);
      }
    });

    test("kutish vaqti rangi va yozuvi", () {
      expect(urgencyColor(const Duration(minutes: 3)), AppColors.success);
      expect(urgencyColor(const Duration(minutes: 4)), AppColors.warning);
      expect(urgencyColor(const Duration(minutes: 10)), AppColors.error);
      expect(waitingText(const Duration(seconds: 20)), 'hozirgina');
      expect(waitingText(const Duration(minutes: 75)), '1 soat oldin');
    });
  });

  group("Ombor qoldig'i", () {
    const store = Restaurant(id: 's', name: 'Magazin', rating: 5, kind: 'shop');
    Product product(int? stock) => Product(
      id: 'p',
      restaurantId: 's',
      name: 'Soat',
      price: 10,
      isAvailable: true,
      stock: stock,
    );

    /// Saqlangan savatni tiklash tugagach qaytadi.
    Future<ProviderContainer> container() async {
      SharedPreferences.setMockInitialValues({});
      final c = ProviderContainer();
      addTearDown(c.dispose);
      c.read(cartProvider);
      await pumpEventQueue();
      return c;
    }

    test("savatdagi miqdor qoldiqdan oshmaydi", () async {
      final c = await container();
      for (var i = 0; i < 5; i++) {
        c.read(cartProvider.notifier).add(store, product(2));
      }
      expect(c.read(cartProvider).count, 2);
    });

    test("tugagan mahsulot savatga qo'shilmaydi", () async {
      final c = await container();
      c.read(cartProvider.notifier).add(store, product(0));
      expect(c.read(cartProvider).isEmpty, isTrue);
    });

    test("qoldiq yuritilmasa umumiy cheklov ishlaydi", () {
      expect(product(null).maxQuantity(50), 50);
      expect(product(80).maxQuantity(50), 50);
    });
  });

  group('Rollar va yo\'llar', () {
    UserProfile p(UserRole r) => UserProfile(id: 'x', role: r);

    test('har rol o\'z paneliga boradi', () {
      expect(
        {for (final r in UserRole.values) r: homeRouteFor(p(r))},
        {
          UserRole.customer: AppRoutes.customerHome,
          UserRole.courier: AppRoutes.courierHome,
          UserRole.restaurant: AppRoutes.restaurantHome,
          UserRole.shop: AppRoutes.restaurantHome,
          UserRole.master: AppRoutes.masterHome,
          UserRole.admin: AppRoutes.adminHome,
        },
      );
    });

    test('magazin va usta hamkor ilovasiga kiradi', () {
      expect(AppFlavor.partner.accepts(p(UserRole.shop)), isTrue);
      expect(AppFlavor.partner.accepts(p(UserRole.master)), isTrue);
      expect(AppFlavor.customer.accepts(p(UserRole.master)), isFalse);
    });

    bool matches(List<RouteBase> routes, String path) {
      final router = GoRouter(routes: routes, initialLocation: path);
      addTearDown(router.dispose);
      return !router.configuration.findMatch(Uri.parse(path)).isError;
    }

    test("bosh sahifadagi har bo'limning sahifasi bor", () {
      for (final s in kDefaultServices) {
        expect(matches(customerRoutes(), s.route!), isTrue, reason: s.route);
        expect(serviceIcons, contains(s.icon));
      }
    });

    test('hamkor panellari ro\'yxatdan o\'tgan', () {
      for (final path in [
        AppRoutes.restaurantHome,
        AppRoutes.masterHome,
        AppRoutes.courierHome,
      ]) {
        expect(matches(partnerRoutes(), path), isTrue, reason: path);
      }
    });
  });

  group('Admin forma maydonlari', () {
    const percent = ResourceField(
      'percent',
      'Foiz',
      type: FieldType.decimal,
      required: true,
      min: 0,
      max: 100,
    );
    const date = ResourceField('ends_at', 'Tugashi', type: FieldType.date);

    test('son chegaralari va vergul', () {
      expect(percent.validate(''), isNotNull);
      expect(percent.validate('abc'), isNotNull);
      expect(percent.validate('101'), isNotNull);
      expect(percent.validate('7,5'), isNull);
      expect(percent.parse('7,5'), 7.5);
    });

    test("mavjud bo'lmagan sana rad etiladi", () {
      expect(date.validate('2026-02-31'), isNotNull);
      expect(date.validate('31.12.2026'), isNotNull);
      expect(date.validate('2026-12-31'), isNull);
      expect(date.validate(''), isNull);
      expect(date.parse('  '), isNull);
    });
  });

  group('Eski baza bilan moslik', () {
    test("yangi ustunlarsiz do'kon restoran hisoblanadi", () {
      final r = Restaurant.fromMap({'id': '1', 'name': 'Osh'});
      expect((r.kind, r.verificationStatus, r.ratingCount), (
        'restaurant',
        'approved',
        0,
      ));
    });

    test('migratsiya qilinmagan baza xatosi tushunarli yoziladi', () {
      const error = PostgrestException(message: 'x', code: 'PGRST205');
      expect(isMissingSchema(error), isTrue);
      expect(friendlyError(error), contains('super_app.sql'));
      expect(
        isMissingSchema(const PostgrestException(message: 'x', code: 'P0001')),
        isFalse,
      );
    });

    test('ilova ichidagi rasm internet rasmiga almashtirilmaydi', () {
      const path = 'assets/images/apple.webp';
      expect(FoodImages.getRestaurantImage('Dehqon', path), path);
      expect(FoodImages.getProductImage('Olma', null, path), path);
    });
  });
}
