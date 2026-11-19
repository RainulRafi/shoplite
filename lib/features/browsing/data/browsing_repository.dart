import '../domain/viewed_product.dart';

abstract class BrowsingRepository {
  Future<List<ViewedProduct>> loadViewed(String ownerId);

  Future<void> recordViewed(
    String ownerId,
    ViewedProduct item, {
    required int keep,
  });

  Future<void> clearViewed(String ownerId);

  Future<List<String>> loadSearches(String ownerId);

  Future<void> recordSearch(String ownerId, String term, {required int keep});

  Future<void> removeSearch(String ownerId, String term);

  Future<void> clearSearches(String ownerId);
}
