/// Super-app modellari: servislar, ustalar, xizmat buyurtmalari va h.k.
library;

DateTime _date(Object? v) => DateTime.parse(v! as String).toLocal();
double? _double(Object? v) => (v as num?)?.toDouble();
int? _int(Object? v) => (v as num?)?.toInt();

String? _joined(Object? relation, String key) =>
    relation is Map<String, dynamic> ? relation[key] as String? : null;

/// Bosh sahifadagi bo'lim (Super Admin boshqaradi).
class ServiceModule {
  const ServiceModule({
    required this.code,
    required this.title,
    this.subtitle,
    this.icon = 'apps',
    this.route,
  });

  final String code;
  final String title;
  final String? subtitle;
  final String icon;
  final String? route;

  factory ServiceModule.fromMap(Map<String, dynamic> m) => ServiceModule(
    code: m['code'] as String,
    title: m['title'] as String,
    subtitle: m['subtitle'] as String?,
    icon: m['icon'] as String? ?? 'apps',
    route: m['route'] as String?,
  );
}

class Promotion {
  const Promotion({
    required this.id,
    required this.title,
    this.subtitle,
    this.serviceCode,
    this.imageUrl,
    this.discountPercent,
  });

  final String id;
  final String title;
  final String? subtitle;
  final String? serviceCode;
  final String? imageUrl;
  final int? discountPercent;

  factory Promotion.fromMap(Map<String, dynamic> m) => Promotion(
    id: m['id'] as String,
    title: m['title'] as String,
    subtitle: m['subtitle'] as String?,
    serviceCode: m['service_code'] as String?,
    imageUrl: m['image_url'] as String?,
    discountPercent: _int(m['discount_percent']),
  );
}

class Region {
  const Region({required this.id, required this.name, required this.kind});

  final String id;
  final String name;
  final String kind;

  factory Region.fromMap(Map<String, dynamic> m) => Region(
    id: m['id'] as String,
    name: m['name'] as String,
    kind: m['kind'] as String? ?? 'viloyat',
  );
}

class Master {
  const Master({
    required this.id,
    required this.fullName,
    this.userId,
    this.categoryId,
    this.specialty,
    this.phone,
    this.photoUrl,
    this.about,
    this.priceFrom,
    this.eta,
    this.rating = 0,
    this.ratingCount = 0,
    this.isActive = true,
    this.verificationStatus = 'approved',
  });

  final String id;
  final String fullName;
  final String? userId;
  final String? categoryId;
  final String? specialty;
  final String? phone;
  final String? photoUrl;
  final String? about;
  final int? priceFrom;
  final String? eta;
  final double rating;
  final int ratingCount;
  final bool isActive;
  final String verificationStatus;

  factory Master.fromMap(Map<String, dynamic> m) => Master(
    id: m['id'] as String,
    fullName: m['full_name'] as String,
    userId: m['user_id'] as String?,
    categoryId: m['category_id'] as String?,
    specialty: _joined(m['categories'], 'name'),
    phone: m['phone'] as String?,
    photoUrl: m['photo_url'] as String?,
    about: m['about'] as String?,
    priceFrom: _int(m['price_from']),
    eta: m['eta'] as String?,
    rating: _double(m['rating']) ?? 0,
    ratingCount: _int(m['rating_count']) ?? 0,
    isActive: m['is_active'] as bool? ?? true,
    verificationStatus: m['verification_status'] as String? ?? 'pending',
  );
}

enum ServiceStatus {
  fresh('new', 'Yangi'),
  accepted('accepted', 'Qabul qilindi'),
  onTheWay('on_the_way', "Usta yo'lda"),
  inProgress('in_progress', 'Ish jarayonida'),
  completed('completed', 'Yakunlandi'),
  rejected('rejected', 'Rad etildi'),
  cancelled('cancelled', 'Bekor qilindi');

  const ServiceStatus(this.value, this.label);

  final String value;
  final String label;

  static ServiceStatus fromString(String? v) => ServiceStatus.values.firstWhere(
    (s) => s.value == v,
    orElse: () => ServiceStatus.fresh,
  );

  bool get isFinished =>
      this == completed || this == rejected || this == cancelled;

  bool get customerCanCancel => this == fresh || this == accepted;

  /// Usta shu holatdan qaysi holatlarga o'tkaza oladi.
  /// Server (set_service_status) bilan bir xil bo'lishi shart.
  List<ServiceStatus> get masterNext => switch (this) {
    fresh => const [accepted, rejected],
    accepted => const [onTheWay, inProgress, cancelled],
    onTheWay => const [inProgress, cancelled],
    inProgress => const [completed],
    _ => const [],
  };
}

class ServiceRequest {
  const ServiceRequest({
    required this.id,
    required this.masterId,
    required this.serviceType,
    required this.status,
    required this.addressText,
    required this.phone,
    required this.createdAt,
    this.customerName,
    this.masterName,
    this.masterPhone,
    this.description,
    this.lat,
    this.lng,
    this.scheduledAt,
    this.price,
    this.commission = 0,
  });

  final String id;
  final String masterId;
  final String serviceType;
  final ServiceStatus status;
  final String addressText;
  final String phone;
  final DateTime createdAt;
  final String? customerName;
  final String? masterName;
  final String? masterPhone;
  final String? description;
  final double? lat;
  final double? lng;
  final DateTime? scheduledAt;
  final int? price;
  final int commission;

  factory ServiceRequest.fromMap(Map<String, dynamic> m) => ServiceRequest(
    id: m['id'] as String,
    masterId: m['master_id'] as String,
    serviceType: m['service_type'] as String,
    status: ServiceStatus.fromString(m['status'] as String?),
    addressText: m['address_text'] as String,
    phone: m['phone'] as String,
    createdAt: _date(m['created_at']),
    customerName: m['customer_name'] as String?,
    masterName: _joined(m['masters'], 'full_name'),
    masterPhone: _joined(m['masters'], 'phone'),
    description: m['description'] as String?,
    lat: _double(m['lat']),
    lng: _double(m['lng']),
    scheduledAt: m['scheduled_at'] == null ? null : _date(m['scheduled_at']),
    price: _int(m['price']),
    commission: _int(m['commission_amount']) ?? 0,
  );
}

class Review {
  const Review({
    required this.rating,
    required this.createdAt,
    this.customerName,
    this.comment,
  });

  final int rating;
  final DateTime createdAt;
  final String? customerName;
  final String? comment;

  factory Review.fromMap(Map<String, dynamic> m) => Review(
    rating: _int(m['rating']) ?? 0,
    createdAt: _date(m['created_at']),
    customerName: m['customer_name'] as String?,
    comment: m['comment'] as String?,
  );
}

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final DateTime createdAt;

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
    id: m['id'] as String,
    title: m['title'] as String,
    body: m['body'] as String,
    createdAt: _date(m['created_at']),
  );
}

/// Buyurtmani olib ketayotgan kuryer (get_order_courier RPC natijasi).
class OrderCourier {
  const OrderCourier({this.fullName, this.phone, this.lat, this.lng});

  final String? fullName;
  final String? phone;
  final double? lat;
  final double? lng;

  factory OrderCourier.fromMap(Map<String, dynamic> m) => OrderCourier(
    fullName: m['full_name'] as String?,
    phone: m['phone'] as String?,
    lat: _double(m['lat']),
    lng: _double(m['lng']),
  );
}
