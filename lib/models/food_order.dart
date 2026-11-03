import 'package:latlong2/latlong.dart';

enum OrderStatus {
  pending('pending', 'Yangi'),
  accepted('accepted', 'Tasdiqlandi'),
  preparing('preparing', 'Tayyorlanmoqda'),
  readyForPickup('ready_for_pickup', 'Tayyor, kuryer kutilmoqda'),
  courierAssigned('courier_assigned', 'Kuryer tayinlandi'),
  pickedUp('picked_up', 'Kuryer olib ketdi'),
  onTheWay('on_the_way', "Kuryer yo'lda"),
  delivered('delivered', 'Yetkazildi'),
  cancelled('cancelled', 'Bekor qilindi'),
  rejected('rejected', 'Rad etildi');

  const OrderStatus(this.value, this.label);

  final String value;
  final String label;

  static OrderStatus fromString(String? v) => OrderStatus.values.firstWhere(
        (s) => s.value == v,
    orElse: () => OrderStatus.pending,
  );

  bool get isCancellable =>
      this == OrderStatus.pending || this == OrderStatus.accepted;

  bool get isFailed =>
      this == OrderStatus.cancelled || this == OrderStatus.rejected;

  bool get isActive => this != OrderStatus.delivered && !isFailed;
}

class FoodOrder {
  const FoodOrder({
    required this.id,
    required this.status,
    required this.addressText,
    required this.phone,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    this.restaurantName,
    this.restaurantAddress,
    this.restaurantLat,
    this.restaurantLng,
    this.note,
    this.courierId,
    this.lat,
    this.lng,
  });

  final String id;
  final OrderStatus status;
  final String addressText;
  final String phone;
  final int subtotal;
  final int deliveryFee;
  final int total;
  final DateTime createdAt;
  final String? restaurantName;
  final String? restaurantAddress;
  final double? restaurantLat;
  final double? restaurantLng;
  final String? note;
  final String? courierId;
  final double? lat;
  final double? lng;

  LatLng? get restaurantLocation =>
      (restaurantLat != null && restaurantLng != null)
          ? LatLng(restaurantLat!, restaurantLng!)
          : null;

  LatLng? get destination =>
      (lat != null && lng != null) ? LatLng(lat!, lng!) : null;

  factory FoodOrder.fromMap(Map<String, dynamic> map) {
    final restaurant = map['restaurants'];
    final r = restaurant is Map<String, dynamic> ? restaurant : null;
    return FoodOrder(
      id: map['id'] as String,
      status: OrderStatus.fromString(map['status'] as String?),
      addressText: map['address_text'] as String,
      phone: map['phone'] as String,
      note: map['note'] as String?,
      subtotal: (map['subtotal'] as num).toInt(),
      deliveryFee: (map['delivery_fee'] as num).toInt(),
      total: (map['total'] as num).toInt(),
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      restaurantName: r?['name'] as String?,
      restaurantAddress: r?['address'] as String?,
      restaurantLat: (r?['lat'] as num?)?.toDouble(),
      restaurantLng: (r?['lng'] as num?)?.toDouble(),
      courierId: map['courier_id'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
    );
  }
}

class OrderLine {
  const OrderLine({
    required this.name,
    required this.price,
    required this.quantity,
  });

  final String name;
  final int price;
  final int quantity;

  int get total => price * quantity;

  factory OrderLine.fromMap(Map<String, dynamic> map) {
    return OrderLine(
      name: map['name_snapshot'] as String,
      price: (map['price_snapshot'] as num).toInt(),
      quantity: (map['quantity'] as num).toInt(),
    );
  }
}
