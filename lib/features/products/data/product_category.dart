import '../../../core/utils/text_format.dart';

class ProductCategory {
  final String slug;
  final String name;

  const ProductCategory({required this.slug, required this.name});

  factory ProductCategory.fromJson(Object? json) {
    if (json is String) {
      return ProductCategory(slug: json, name: prettyCategory(json));
    }
    final map = json as Map<String, dynamic>;
    final slug = map['slug'] as String;
    final name = map['name'] as String?;
    return ProductCategory(
      slug: slug,
      name: (name == null || name.isEmpty) ? prettyCategory(slug) : name,
    );
  }
}
