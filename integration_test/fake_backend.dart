import 'package:shoplite/core/storage/token_store.dart';
import 'package:shoplite/features/auth/data/auth_repository.dart';
import 'package:shoplite/features/auth/data/auth_session.dart';
import 'package:shoplite/features/auth/data/user_profile.dart';
import 'package:shoplite/features/products/data/product.dart';
import 'package:shoplite/features/products/data/product_category.dart';
import 'package:shoplite/features/products/data/product_page.dart';
import 'package:shoplite/features/products/data/product_repository.dart';
import 'package:shoplite/features/products/data/product_review.dart';

const testTokens = AuthTokens(accessToken: 'A', refreshToken: 'R');

const _user = UserProfile(
  id: 1,
  username: 'emilys',
  firstName: 'Emily',
  lastName: 'Johnson',
  email: 'emily@x.test',
);

class FakeAuthRepository implements AuthRepository {
  @override
  Future<AuthSession> login({
    required String username,
    required String password,
  }) async => const AuthSession(tokens: testTokens, user: _user);

  @override
  Future<UserProfile> fetchProfile() async => _user;
}

class FakeBackend implements ProductRepository {
  final List<Product> products = [
    const Product(
      id: 1,
      title: 'Walnut Desk',
      price: 120,
      rating: 4.6,
      stock: 3,
      category: 'furniture',
      thumbnail: 'https://x.test/1.png',
    ),
    const Product(
      id: 2,
      title: 'Desk Lamp',
      price: 25,
      discountPercentage: 10,
      rating: 4.2,
      stock: 8,
      category: 'furniture',
      thumbnail: 'https://x.test/2.png',
    ),
    const Product(
      id: 3,
      title: 'Notebook Set',
      price: 9,
      rating: 3.9,
      stock: 20,
      category: 'stationery',
      thumbnail: 'https://x.test/3.png',
    ),
  ];

  ProductPage _page(List<Product> list, {int skip = 0, int limit = 0}) {
    final end = limit == 0 ? list.length : (skip + limit).clamp(0, list.length);
    final start = skip.clamp(0, list.length);
    return ProductPage(
      products: list.sublist(start, end),
      total: list.length,
      skip: skip,
      limit: limit,
    );
  }

  @override
  Future<ProductPage> fetchProducts({
    int limit = 20,
    int skip = 0,
    String? query,
  }) async {
    final text = (query ?? '').toLowerCase();
    final source = text.isEmpty
        ? products
        : products.where((p) => p.title.toLowerCase().contains(text)).toList();
    return _page(source, skip: skip, limit: limit);
  }

  @override
  Future<Product> fetchProduct(int id) async =>
      products.firstWhere((p) => p.id == id);

  @override
  Future<List<ProductCategory>> fetchCategories() async => const [
    ProductCategory(slug: 'furniture', name: 'Furniture'),
    ProductCategory(slug: 'stationery', name: 'Stationery'),
  ];

  @override
  Future<ProductPage> fetchByCategory(String slug) async =>
      _page(products.where((p) => p.category == slug).toList());

  @override
  Future<ProductPage> fetchTop(HomeRank rank, {int limit = 10}) async =>
      _page(products);

  @override
  Future<List<ProductReview>> fetchReviews(int productId) async => const [];
}
