import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/state/data_status.dart';
import '../../auth/presentation/auth_owner.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/reviews_repository.dart';
import '../domain/my_review.dart';
import '../domain/review_validators.dart';

enum ReviewResult { saved, invalid, notSignedIn, failed }

class MyReviewsProvider extends ChangeNotifier {
  final ReviewsRepository _repository;
  final AuthProvider _auth;

  MyReviewsProvider(this._repository, this._auth) {
    _auth.addListener(_onAuthChanged);
    _onAuthChanged();
  }

  String? _owner;
  int _generation = 0;
  DataStatus _status = DataStatus.ready;
  List<MyReview> _reviews = const [];
  bool _disposed = false;

  DataStatus get status => _status;
  List<MyReview> get reviews => _reviews;

  MyReview? forProduct(int productId) {
    for (final r in _reviews) {
      if (r.productId == productId) return r;
    }
    return null;
  }

  void _onAuthChanged() {
    final next = _auth.userOwner;
    if (next == _owner) return;
    _owner = next;
    unawaited(_loadFor(next));
  }

  Future<void> _loadFor(String? owner) async {
    final generation = ++_generation;

    _reviews = const [];
    _status = owner == null ? DataStatus.ready : DataStatus.loading;
    _notify();
    if (owner == null) return;

    try {
      final list = await _repository.loadMine(owner);
      if (generation != _generation) return;
      _reviews = list;
      _status = DataStatus.ready;
    } on Exception catch (e) {
      if (generation != _generation) return;
      if (kDebugMode) debugPrint('Could not load your reviews: $e');
      _status = DataStatus.error;
    }
    _notify();
  }

  void retry() {
    if (_status != DataStatus.error) return;
    unawaited(_loadFor(_owner));
  }

  Future<ReviewResult> save({
    required int productId,
    required String productTitle,
    required String thumbnail,
    required int? rating,
    required String comment,
  }) async {
    final owner = _owner;
    if (owner == null) return ReviewResult.notSignedIn;
    if (ReviewValidators.rating(rating) != null ||
        ReviewValidators.comment(comment) != null) {
      return ReviewResult.invalid;
    }

    final now = DateTime.now();
    final review = MyReview(
      productId: productId,
      productTitle: productTitle,
      thumbnail: thumbnail,
      rating: rating!,
      comment: comment.trim(),
      createdAt: forProduct(productId)?.createdAt ?? now,
      updatedAt: now,
    );

    try {
      await _repository.save(owner, review);
      await _reload(owner);
      return ReviewResult.saved;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Could not save the review: $e');
      return ReviewResult.failed;
    }
  }

  Future<bool> delete(int productId) async {
    final owner = _owner;
    if (owner == null) return false;
    try {
      await _repository.delete(owner, productId);
      await _reload(owner);
      return true;
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Could not delete the review: $e');
      return false;
    }
  }

  Future<void> _reload(String owner) async {
    final list = await _repository.loadMine(owner);
    if (owner != _owner) return;
    _reviews = list;
    _notify();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _auth.removeListener(_onAuthChanged);
    super.dispose();
  }
}
