class Product {
  const Product({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.price,
    required this.isAvailable,
    this.description,
    this.imageUrl,
    this.categoryName,
  });

  final String id;
  final String restaurantId;
  final String name;
  final int price;
  final bool isAvailable;
  final String? description;
  final String? imageUrl;
  final String? categoryName;

  factory Product.fromMap(Map<String, dynamic> map) {
    final category = map['categories'];
    return Product(
      id: map['id'] as String,
      restaurantId: map['restaurant_id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toInt(),
      isAvailable: map['is_available'] as bool? ?? true,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      categoryName:
      category is Map<String, dynamic> ? category['name'] as String? : null,
    );
  }
}