import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo/core/constants/app_constants.dart';
import 'package:foodgo/features/customer/cart/cart_provider.dart';
import 'package:foodgo/features/delivery/delivery_providers.dart';
import 'package:foodgo/models/product.dart';
import 'package:foodgo/models/restaurant.dart';
import 'package:foodgo/repositories/delivery_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

Restaurant _rest(String id, {bool active = true}) =>
    Restaurant(id: id, name: 'Rest $id', rating: 4.5, isActive: active);

Product _prod(
  String id, {
  String restaurantId = 'r1',
  int price = 10000,
  bool available = true,
}) =>
    Product(
      id: id,
      restaurantId: restaurantId,
      name: 'Taom $id',
      price: price,
      isAvailable: available,
    );

class _FakeRepo implements DeliveryRepository {
  _FakeRepo({required this.restaurant, required this.products});

  final Restaurant restaurant;
  final List<Product> products;

  @override
  Future<Restaurant> fetchRestaurant(String id) async => restaurant;

  @override
  Future<List<Product>> fetchProducts(String restaurantId) async => products;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _OfflineRepo implements DeliveryRepository {
  @override
  Future<Restaurant> fetchRestaurant(String id) async =>
      throw Exception('tarmoq yo\'q');

  @override
  Future<List<Product>> fetchProducts(String restaurantId) async =>
      throw Exception('tarmoq yo\'q');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<ProviderContainer> _container({
  Map<String, Object> prefs = const {},
  DeliveryRepository? repo,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final c = ProviderContainer(
    overrides: [
      if (repo != null) deliveryRepositoryProvider.overrideWithValue(repo),
    ],
  );
  addTearDown(c.dispose);
  c.read(cartProvider); // build() va tiklashni boshlaydi
  await pumpEventQueue(); // tiklash tugashini kutamiz
  return c;
}

String _savedCart(String restaurantId, Map<String, int> items) => jsonEncode({
      'restaurant_id': restaurantId,
      'items': [
        for (final e in items.entries)
          {'product_id': e.key, 'quantity': e.value},
      ],
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Savat logikasi', () {
    test('bir xil taom qo\'shilsa miqdor oshadi, summa to\'g\'ri', () async {
      final c = await _container();
      final cart = c.read(cartProvider.notifier);

      cart.add(_rest('r1'), _prod('p1', price: 12000));
      cart.add(_rest('r1'), _prod('p1', price: 12000));
      cart.add(_rest('r1'), _prod('p2', price: 5000));

      final s = c.read(cartProvider);
      expect(s.items.length, 2);
      expect(s.quantityOf('p1'), 2);
      expect(s.count, 3);
      expect(s.subtotal, 2 * 12000 + 5000);
    });

    test('miqdor kMaxItemQuantity dan oshmaydi', () async {
      final c = await _container();
      final cart = c.read(cartProvider.notifier);

      for (var i = 0; i < kMaxItemQuantity + 5; i++) {
        cart.add(_rest('r1'), _prod('p1'));
      }
      expect(c.read(cartProvider).quantityOf('p1'), kMaxItemQuantity);
    });

    test('mavjud bo\'lmagan taom qo\'shilmaydi', () async {
      final c = await _container();
      c.read(cartProvider.notifier).add(_rest('r1'), _prod('p1', available: false));
      expect(c.read(cartProvider).isEmpty, isTrue);
    });

    test('boshqa restoran taomi qo\'shilmaydi, replaceWith savatni almashtiradi',
        () async {
      final c = await _container();
      final cart = c.read(cartProvider.notifier);

      cart.add(_rest('r1'), _prod('p1'));
      expect(cart.canAdd(_rest('r2')), isFalse);

      cart.add(_rest('r2'), _prod('x1', restaurantId: 'r2'));
      expect(c.read(cartProvider).restaurant?.id, 'r1');
      expect(c.read(cartProvider).quantityOf('x1'), 0);

      cart.replaceWith(_rest('r2'), _prod('x1', restaurantId: 'r2'));
      expect(c.read(cartProvider).restaurant?.id, 'r2');
      expect(c.read(cartProvider).count, 1);
    });

    test('decrement 1 dan kam bo\'lsa taomni olib tashlaydi, oxirgisi savatni tozalaydi',
        () async {
      final c = await _container();
      final cart = c.read(cartProvider.notifier);

      cart.add(_rest('r1'), _prod('p1'));
      cart.add(_rest('r1'), _prod('p1'));
      cart.decrement('p1');
      expect(c.read(cartProvider).quantityOf('p1'), 1);

      cart.decrement('p1');
      expect(c.read(cartProvider).isEmpty, isTrue);
      expect(c.read(cartProvider).restaurant, isNull);
    });

    test('remove taomni o\'chiradi', () async {
      final c = await _container();
      final cart = c.read(cartProvider.notifier);

      cart.add(_rest('r1'), _prod('p1'));
      cart.add(_rest('r1'), _prod('p2'));
      cart.remove('p1');

      expect(c.read(cartProvider).items.map((i) => i.product.id), ['p2']);
    });
  });

  group('Savatni saqlash', () {
    test('faqat id va miqdor saqlanadi, narx saqlanmaydi', () async {
      final c = await _container();
      c.read(cartProvider.notifier)
        ..add(_rest('r1'), _prod('p1', price: 99999))
        ..add(_rest('r1'), _prod('p1', price: 99999));
      await pumpEventQueue();

      final raw = (await SharedPreferences.getInstance()).getString('cart_v1');
      expect(raw, isNotNull);
      expect(raw, isNot(contains('99999')));

      final json = jsonDecode(raw!) as Map<String, dynamic>;
      expect(json['restaurant_id'], 'r1');
      expect(json['items'], [
        {'product_id': 'p1', 'quantity': 2},
      ]);
    });

    test('clear() saqlangan savatni ham o\'chiradi', () async {
      final c = await _container();
      final cart = c.read(cartProvider.notifier);
      cart.add(_rest('r1'), _prod('p1'));
      await pumpEventQueue();

      cart.clear();
      await pumpEventQueue();

      expect((await SharedPreferences.getInstance()).getString('cart_v1'), isNull);
    });

    test('tiklashda faqat mavjud taomlar qaytadi, miqdor chegaralanadi',
        () async {
      final c = await _container(
        prefs: {
          'cart_v1': _savedCart('r1', {
            'p1': kMaxItemQuantity + 50, // juda katta miqdor
            'p2': 1, // endi mavjud emas
            'p3': 1, // o'chirilgan
          }),
        },
        repo: _FakeRepo(
          restaurant: _rest('r1'),
          products: [_prod('p1'), _prod('p2', available: false)],
        ),
      );

      final s = c.read(cartProvider);
      expect(s.restaurant?.id, 'r1');
      expect(s.items.length, 1);
      expect(s.quantityOf('p1'), kMaxItemQuantity);
    });

    test('restoran yopilgan bo\'lsa savat tiklanmaydi va tozalanadi', () async {
      final c = await _container(
        prefs: {
          'cart_v1': _savedCart('r1', {'p1': 1}),
        },
        repo: _FakeRepo(
          restaurant: _rest('r1', active: false),
          products: [_prod('p1')],
        ),
      );

      expect(c.read(cartProvider).isEmpty, isTrue);
      expect((await SharedPreferences.getInstance()).getString('cart_v1'), isNull);
    });

    test('tarmoq xatosida savat bo\'sh ochiladi, lekin saqlangani o\'chmaydi',
        () async {
      final c = await _container(
        prefs: {
          'cart_v1': _savedCart('r1', {'p1': 2}),
        },
        repo: _OfflineRepo(),
      );

      expect(c.read(cartProvider).isEmpty, isTrue);
      expect(
        (await SharedPreferences.getInstance()).getString('cart_v1'),
        isNotNull,
      );
    });
  });
}
