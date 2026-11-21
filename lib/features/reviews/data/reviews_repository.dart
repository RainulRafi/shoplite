import '../domain/my_review.dart';

abstract class ReviewsRepository {
  Future<List<MyReview>> loadMine(String ownerId);

  Future<void> save(String ownerId, MyReview review);

  Future<void> delete(String ownerId, int productId);
}
