import 'package:flutter/foundation.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/state/data_status.dart';
import '../../products/data/product_repository.dart';
import '../../products/data/product_review.dart';
import '../domain/review_summary.dart';

class ProductReviewsProvider extends ChangeNotifier {
  final ProductRepository _repository;
  final int productId;

  ProductReviewsProvider(this._repository, this.productId);

  DataStatus _status = DataStatus.loading;
  List<ProductReview> _reviews = const [];
  ApiException? _error;
  bool _loading = false;
  bool _disposed = false;

  DataStatus get status => _status;
  List<ProductReview> get reviews => _reviews;
  ApiException? get error => _error;

  ReviewSummary get summary =>
      ReviewSummary.fromRatings(_reviews.map((r) => r.rating));

  Future<void> load() async {
    if (_loading) return;
    _status = DataStatus.loading;
    _error = null;
    _notify();

    try {
      _reviews = await _repository.fetchReviews(productId);
      _status = DataStatus.ready;
    } on ApiException catch (e) {
      _error = e;
      _status = DataStatus.error;
    } finally {
      _loading = false;
    }
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
