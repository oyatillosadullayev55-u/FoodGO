import 'package:latlong2/latlong.dart';

class Restaurant {
  const Restaurant({
    required this.id,
    required this.name,
    required this.rating,
    this.description,
    this.imageUrl,
    this.address,
    this.openTime,
    this.closeTime,
    this.lat,
    this.lng,
    this.isActive = true,
    this.ownerEmail,
    this.kind = 'restaurant',
    this.deliveryTime,
    this.ratingCount = 0,
    this.verificationStatus = 'approved',
  });

  final String id;
  final String name;
  final double rating;
  final String? description;
  final String? imageUrl;
  final String? address;
  final String? openTime;
  final String? closeTime;
  final double? lat;
  final double? lng;
  final bool isActive;
  final String? ownerEmail;

  /// 'restaurant' yoki 'shop'.
  final String kind;
  final String? deliveryTime;
  final int ratingCount;

  /// 'pending', 'approved' yoki 'rejected'.
  final String verificationStatus;

  bool get isShop => kind == 'shop';

  LatLng? get location =>
      (lat != null && lng != null) ? LatLng(lat!, lng!) : null;

  /// "09:00 - 23:00"
  String? get workingHours {
    if (openTime == null || closeTime == null) return null;
    return '${_hm(openTime!)} - ${_hm(closeTime!)}';
  }

  static String _hm(String t) => t.length >= 5 ? t.substring(0, 5) : t;

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id'] as String,
      name: map['name'] as String,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      address: map['address'] as String?,
      openTime: map['open_time'] as String?,
      closeTime: map['close_time'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      isActive: map['is_active'] as bool? ?? true,
      ownerEmail: map['owner_email'] as String?,
      kind: map['kind'] as String? ?? 'restaurant',
      deliveryTime: map['delivery_time'] as String?,
      ratingCount: (map['rating_count'] as num?)?.toInt() ?? 0,
      verificationStatus: map['verification_status'] as String? ?? 'approved',
    );
  }
}
