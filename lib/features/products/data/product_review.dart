import 'package:flutter/foundation.dart';

@immutable
class ProductReview {
  final int rating;
  final String comment;
  final String reviewerName;
  final DateTime? date;

  const ProductReview({
    required this.rating,
    required this.comment,
    required this.reviewerName,
    this.date,
  });

  factory ProductReview.fromJson(Map<String, dynamic> json) {
    final raw = json['rating'] as num;
    final name = (json['reviewerName'] as String?)?.trim() ?? '';
    return ProductReview(
      rating: raw.round().clamp(1, 5).toInt(),
      comment: (json['comment'] as String?)?.trim() ?? '',
      reviewerName: name.isEmpty ? 'Anonymous' : name,
      date: DateTime.tryParse(json['date'] as String? ?? ''),
    );
  }
}
