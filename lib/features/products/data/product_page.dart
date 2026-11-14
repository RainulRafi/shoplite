import 'product.dart';

class ProductPage {
  final List<Product> products;
  final int total;
  final int skip;
  final int limit;

  const ProductPage({
    required this.products,
    required this.total,
    required this.skip,
    required this.limit,
  });

  factory ProductPage.fromJson(Map<String, dynamic> json) {
    final raw = json['products'] as List<dynamic>;

    return ProductPage(
      products: raw
          .map((item) => Product.fromJson(item as Map<String, dynamic>))
          .toList(),

      total: (json['total'] as num?)?.toInt() ?? raw.length,
      skip: (json['skip'] as num?)?.toInt() ?? 0,
      limit: (json['limit'] as num?)?.toInt() ?? raw.length,
    );
  }

  bool get hasMore => skip + products.length < total;
}
