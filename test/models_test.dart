import 'package:flutter_test/flutter_test.dart';
import 'package:foodgo/models/food_order.dart';
import 'package:foodgo/models/restaurant.dart';

Map<String, dynamic> _orderMap({Object? restaurants}) => {
      'id': 'o1',
      'status': 'on_the_way',
      'address_text': 'Toshkent, Amir Temur 1',
      'phone': '+998901234567',
      'note': null,
      'subtotal': 50000.0, // Supabase num ba'zan double qaytaradi
      'delivery_fee': 10000,
      'total': 60000,
      'created_at': '2026-11-07T10:00:00Z',
      'courier_id': 'c1',
      'lat': 41.31,
      'lng': 69.24,
      'restaurants': restaurants,
    };

void main() {
  group('OrderStatus', () {
    test('value bo\'yicha topadi', () {
      expect(OrderStatus.fromString('ready_for_pickup'),
          OrderStatus.readyForPickup);
    });

    test('noma\'lum yoki null qiymat pending ga tushadi', () {
      expect(OrderStatus.fromString('???'), OrderStatus.pending);
      expect(OrderStatus.fromString(null), OrderStatus.pending);
    });

    test('faqat pending va accepted bekor qilinadi', () {
      for (final s in OrderStatus.values) {
        final expected =
            s == OrderStatus.pending || s == OrderStatus.accepted;
        expect(s.isCancellable, expected, reason: s.value);
      }
    });

    test('isActive: yakunlangan va muvaffaqiyatsizlar faol emas', () {
      expect(OrderStatus.onTheWay.isActive, isTrue);
      expect(OrderStatus.delivered.isActive, isFalse);
      expect(OrderStatus.cancelled.isActive, isFalse);
      expect(OrderStatus.rejected.isActive, isFalse);
    });
  });

  group('FoodOrder.fromMap', () {
    test('restoran va manzil maydonlarini o\'qiydi', () {
      final o = FoodOrder.fromMap(_orderMap(restaurants: {
        'name': 'Osh Markazi',
        'address': 'Chilonzor',
        'lat': 41.28,
        'lng': 69.20,
      }));

      expect(o.status, OrderStatus.onTheWay);
      expect(o.subtotal, 50000);
      expect(o.restaurantName, 'Osh Markazi');
      expect(o.restaurantLocation?.latitude, 41.28);
      expect(o.destination?.longitude, 69.24);
      expect(o.note, isNull);
    });

    test('restoran ma\'lumoti yo\'q bo\'lsa ham yiqilmaydi', () {
      final o = FoodOrder.fromMap(_orderMap());
      expect(o.restaurantName, isNull);
      expect(o.restaurantLocation, isNull);
    });

    test('koordinata bo\'lmasa destination null', () {
      final m = _orderMap()
        ..['lat'] = null
        ..['lng'] = null;
      expect(FoodOrder.fromMap(m).destination, isNull);
    });
  });

  group('OrderLine', () {
    test('snapshot maydonlari va jami summa', () {
      final l = OrderLine.fromMap({
        'name_snapshot': 'Lavash',
        'price_snapshot': 25000,
        'quantity': 3,
      });
      expect(l.name, 'Lavash');
      expect(l.total, 75000);
    });
  });

  group('Restaurant', () {
    test('workingHours sekundlarni qirqadi', () {
      final r = Restaurant.fromMap({
        'id': 'r1',
        'name': 'Test',
        'open_time': '09:00:00',
        'close_time': '23:30:00',
      });
      expect(r.workingHours, '09:00 - 23:30');
    });

    test('ish vaqti to\'liq bo\'lmasa null, is_active standart true', () {
      final r = Restaurant.fromMap({
        'id': 'r1',
        'name': 'Test',
        'open_time': '09:00:00',
      });
      expect(r.workingHours, isNull);
      expect(r.isActive, isTrue);
      expect(r.location, isNull);
      expect(r.rating, 0);
    });
  });
}
