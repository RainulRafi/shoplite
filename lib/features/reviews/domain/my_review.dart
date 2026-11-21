import 'package:flutter/foundation.dart';

@immutable
class MyReview {
  final int productId;
  final String productTitle;
  final String thumbnail;
  final int rating;
  final String comment;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MyReview({
    required this.productId,
    required this.productTitle,
    required this.thumbnail,
    required this.rating,
    required this.comment,
    required this.createdAt,
    required this.updatedAt,
  });
}
