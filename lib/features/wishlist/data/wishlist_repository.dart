import '../domain/wishlist_item.dart';

abstract class WishlistRepository {
  Future<List<WishlistItem>> loadAll(String ownerId);

  Future<void> add(String ownerId, WishlistItem item);

  Future<void> remove(String ownerId, int productId);
}
