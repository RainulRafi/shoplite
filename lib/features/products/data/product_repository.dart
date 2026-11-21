import 'product.dart';
import 'product_category.dart';
import 'product_page.dart';
import 'product_review.dart';

enum HomeRank { deals, topRated }

abstract class ProductRepository {
  Future<ProductPage> fetchProducts({
    int limit = 20,
    int skip = 0,
    String? query,
  });

  Future<Product> fetchProduct(int id);

  Future<List<ProductCategory>> fetchCategories();

  Future<ProductPage> fetchByCategory(String slug);

  Future<ProductPage> fetchTop(HomeRank rank, {int limit = 10});

  Future<List<ProductReview>> fetchReviews(int productId);
}
