/// Ekran testlari uchun soxta ma'lumotlar (1-rasmdagi namunalar).
library;

import 'package:osongo/features/auth/data/user_profile.dart';
import 'package:osongo/models/food_category.dart';
import 'package:osongo/models/food_order.dart';
import 'package:osongo/models/marketplace.dart';
import 'package:osongo/models/product.dart';
import 'package:osongo/models/restaurant.dart';
import 'package:osongo/repositories/marketplace_repository.dart';

const customer = UserProfile(
  id: 'customer-1',
  role: UserRole.customer,
  fullName: 'Oyatillo',
  phone: '+998901234567',
  email: 'customer@example.com',
);

const courierProfile = UserProfile(
  id: 'courier-1',
  role: UserRole.courier,
  fullName: 'Azizbek',
  phone: '+998901234567',
);

Restaurant store(
  String id,
  String name,
  String image, {
  double rating = 4.8,
  int count = 12500,
  String eta = '30–40 daqiqa',
  String kind = 'restaurant',
}) => Restaurant(
  id: id,
  name: name,
  rating: rating,
  ratingCount: count,
  deliveryTime: eta,
  imageUrl: 'assets/images/$image.webp',
  address: "Farg'ona, Mustaqillik ko'chasi 7",
  openTime: '09:00:00',
  closeTime: '23:00:00',
  kind: kind,
);

final restaurants = [
  store('r1', 'Burger House', 'burger'),
  store('r2', 'Pizza Time', 'pizza', rating: 4.7, count: 8900, eta: '25–35 daqiqa'),
  store('r3', 'Sushi Master', 'sushi', rating: 4.9, count: 640),
  store('r4', 'Salat Bar', 'salad', rating: 4.6, count: 210),
];

final shop = store('s1', 'TechnoMart', 'headphones', kind: 'shop');

StoreProduct _product(String id, String name, int price, String image, {int stock = 12}) => (
  product: Product(
    id: id,
    restaurantId: shop.id,
    name: name,
    price: price,
    isAvailable: true,
    imageUrl: 'assets/images/$image.webp',
    stock: stock,
    unit: 'dona',
  ),
  store: shop,
);

final shopProducts = [
  _product('p1', 'AirPods Pro', 1990000, 'airpods'),
  _product('p2', 'Smart Watch', 1499000, 'watch', stock: 3),
  _product('p3', 'Telefon', 5999000, 'phone', stock: 0),
  _product('p4', 'Noutbuk', 7999000, 'laptop'),
];

const foodCategories = [
  FoodCategory(id: 'c1', name: 'Fast Food'),
  FoodCategory(id: 'c2', name: 'Pizza'),
  FoodCategory(id: 'c3', name: 'Burger'),
];
const shopCategories = [
  FoodCategory(id: 'c4', name: 'Elektronika'),
  FoodCategory(id: 'c5', name: 'Kiyim'),
  FoodCategory(id: 'c6', name: 'Maishiy'),
];
const masterCategories = [
  FoodCategory(id: 'c7', name: 'Santexnik'),
  FoodCategory(id: 'c8', name: 'Elektrik'),
  FoodCategory(id: 'c9', name: "Ta'mir"),
];

Master _master(String id, String name, String photo, String job, double rating, int count, String eta) => Master(
  id: id,
  fullName: name,
  specialty: job,
  categoryId: 'c7',
  photoUrl: 'assets/images/$photo.webp',
  phone: '+998901234501',
  rating: rating,
  ratingCount: count,
  eta: eta,
  priceFrom: 80000,
  about: "Santexnika o'rnatish va ta'mirlash, 8 yillik tajriba.",
);

final masters = [
  _master('m1', 'Ali Usta', 'master_1', 'Santexnik', 4.9, 2100, '20–30 daqiqa'),
  _master('m2', 'Rustam Usta', 'master_2', "Ta'mir", 4.8, 856, '30–40 daqiqa'),
  _master('m3', 'Bekzod Usta', 'master_3', 'Elektrik', 4.9, 730, '20–35 daqiqa'),
];

FoodOrder order(
  String id,
  OrderStatus status, {
  Duration ago = const Duration(minutes: 2),
  int total = 86000,
}) => FoodOrder(
  id: '$id-0000-4000-8000-000000000000',
  status: status,
  addressText: "Farg'ona, Al-Farg'oniy ko'chasi 14, 25-xonadon",
  phone: '+998901234567',
  subtotal: total - 10000,
  deliveryFee: 10000,
  total: total,
  commission: (total - 10000) ~/ 10,
  createdAt: DateTime.now().subtract(ago),
  restaurantName: 'Burger House',
  restaurantAddress: "Mustaqillik ko'chasi 7",
  restaurantLat: 40.3842,
  restaurantLng: 71.7893,
  lat: 40.3911,
  lng: 71.7810,
);

const orderLines = [
  OrderLine(name: 'Klassik Burger', price: 38000, quantity: 2),
];

final notifications = [
  AppNotification(
    id: 'n1',
    title: "Buyurtmangiz yo'lda",
    body: 'Buyurtma #a1b2c3d4',
    createdAt: DateTime.now(),
  ),
];

final serviceRequests = [
  ServiceRequest(
    id: 'q1000000-0000',
    masterId: 'm1',
    serviceType: 'Kran almashtirish',
    status: ServiceStatus.fresh,
    addressText: "Farg'ona, Navoiy ko'chasi 5",
    phone: '+998901112233',
    createdAt: DateTime.now(),
    customerName: 'Dilnoza',
    masterName: 'Ali Usta',
    description: 'Oshxonada kran oqyapti.',
  ),
  ServiceRequest(
    id: 'q2000000-0000',
    masterId: 'm1',
    serviceType: 'Quvur tozalash',
    status: ServiceStatus.completed,
    addressText: "Farg'ona, Istiqlol 21",
    phone: '+998901112244',
    createdAt: DateTime.now(),
    price: 180000,
    commission: 21600,
    masterName: 'Ali Usta',
  ),
];

final adminAnalytics = <String, dynamic>{
  'users': 1284,
  'stores': 46,
  'masters': 73,
  'pending_partners': 5,
  'open_complaints': 2,
  'orders': 912,
  'delivered': 861,
  'cancelled': 34,
  'service_requests': 148,
  'revenue': 184500000,
  'commission': 17320000,
  'daily': [
    for (var i = 13; i >= 0; i--)
      {
        'day': DateTime.now()
            .subtract(Duration(days: i))
            .toIso8601String()
            .substring(0, 10),
        'orders': 40 + (i * 17) % 35,
        'revenue': 8000000 + (i * 2300000) % 9000000,
      },
  ],
  'top_stores': [
    {'name': 'Burger House', 'orders': 214, 'revenue': 38200000},
    {'name': 'TechnoMart', 'orders': 37, 'revenue': 31900000},
    {'name': 'Pizza Time', 'orders': 168, 'revenue': 27400000},
  ],
};
