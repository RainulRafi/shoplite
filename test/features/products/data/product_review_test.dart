import 'package:flutter_test/flutter_test.dart';
import 'package:shoplite/features/products/data/product_review.dart';
import 'package:shoplite/features/reviews/domain/review_summary.dart';
import 'package:shoplite/features/reviews/domain/review_validators.dart';

void main() {
  group('a server review', () {
    test('reads every field', () {
      final r = ProductReview.fromJson({
        'rating': 4,
        'comment': ' Nice one ',
        'reviewerName': 'Eleanor',
        'reviewerEmail': 'e@x.test',
        'date': '2025-04-30T09:41:02.000Z',
      });

      expect(r.rating, 4);
      expect(r.comment, 'Nice one');
      expect(r.reviewerName, 'Eleanor');
      expect(r.date, DateTime.utc(2025, 4, 30, 9, 41, 2));
    });

    test('missing name, comment and date get safe defaults', () {
      final r = ProductReview.fromJson({'rating': 3});

      expect(r.reviewerName, 'Anonymous');
      expect(r.comment, '');
      expect(r.date, isNull);
    });

    test('a rating outside one to five is pulled into range, and a missing one is an error', () {
      expect(ProductReview.fromJson({'rating': 9}).rating, 5);
      expect(ProductReview.fromJson({'rating': 0}).rating, 1);
      expect(ProductReview.fromJson({'rating': 3.6}).rating, 4);
      expect(
        () => ProductReview.fromJson({'comment': 'x'}),
        throwsA(isA<TypeError>()),
      );
    });
  });

  group('summary', () {
    test('counts, average and stars', () {
      final s = ReviewSummary.fromRatings([5, 4, 4]);

      expect(s.count, 3);
      expect(s.averageText, '4.3');
      expect(s.byStars, {1: 0, 2: 0, 3: 0, 4: 2, 5: 1});
    });

    test('no reviews gives a dash and no division by zero', () {
      final s = ReviewSummary.fromRatings(const []);

      expect(s.count, 0);
      expect(s.averageText, '-');
      expect(s.average, 0);
    });

    test('out of range ratings are not counted', () {
      expect(ReviewSummary.fromRatings([5, 9, 0]).count, 1);
    });
  });

  group('validators', () {
    test('a rating of one to five is required', () {
      expect(ReviewValidators.rating(null), isNotNull);
      expect(ReviewValidators.rating(0), isNotNull);
      expect(ReviewValidators.rating(6), isNotNull);
      expect(ReviewValidators.rating(1), isNull);
      expect(ReviewValidators.rating(5), isNull);
    });

    test(
      'the comment must be ten to five hundred characters after trimming',
      () {
        expect(ReviewValidators.comment(null), isNotNull);
        expect(ReviewValidators.comment('too short'), isNotNull);
        expect(
          ReviewValidators.comment('   ten chars  '),
          isNotNull,
        ); // ছাঁটার পরে ৯
        expect(ReviewValidators.comment('long enough'), isNull);
        expect(ReviewValidators.comment('x' * 500), isNull);
        expect(ReviewValidators.comment('x' * 501), isNotNull);
      },
    );
  });
}
