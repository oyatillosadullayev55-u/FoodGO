class ProductCategory {
  const ProductCategory({required this.id, required this.name});
  final String id;
  final String name;

  factory ProductCategory.fromMap(Map<String, dynamic> m) =>
      ProductCategory(id: m['id'] as String, name: m['name'] as String);
}
