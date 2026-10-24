class FoodCategory {
  const FoodCategory({required this.id, required this.name, this.icon});

  final String id;
  final String name;
  final String? icon;

  factory FoodCategory.fromMap(Map<String, dynamic> map) {
    return FoodCategory(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String?,
    );
  }
}