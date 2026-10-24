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
    this.note,
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
  final String? note;

  factory FoodOrder.fromMap(Map<String, dynamic> map) {
    final restaurant = map['restaurants'];
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
      restaurantName: restaurant is Map<String, dynamic>
          ? restaurant['name'] as String?
          : null,
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