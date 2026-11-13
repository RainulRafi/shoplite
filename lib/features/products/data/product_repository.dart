import 'product.dart';
import 'product_page.dart';

abstract class ProductRepository {
  Future<ProductPage> fetchProducts({int limit = 20, int skip = 0});
  Future<Product> fetchProduct(int id);
}
