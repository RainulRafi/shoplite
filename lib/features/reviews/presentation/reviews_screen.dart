import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/data_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/star_rating.dart';
import '../../auth/presentation/require_login.dart';
import '../../products/data/product_repository.dart';
import '../domain/my_review.dart';
import 'my_reviews_provider.dart';
import 'product_reviews_provider.dart';
import 'review_form_screen.dart';

// ============================================
// একটা পণ্যের রিভিউ: নিজেরটা (থাকলে) আর সার্ভারের সবার। productId, নাম, ছবি নেয়, পুরো
// Product না: Account-এর "My reviews" থেকেও এটাই খোলে, সেখানে শুধু এই তিনটাই জানা
// ============================================
class ReviewsScreen extends StatelessWidget {
  final int productId;
  final String productTitle;
  final String thumbnail;

  const ReviewsScreen({
    super.key,
    required this.productId,
    required this.productTitle,
    required this.thumbnail,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          ProductReviewsProvider(ctx.read<ProductRepository>(), productId)
            ..load(),
      child: _ReviewsView(
        productId: productId,
        productTitle: productTitle,
        thumbnail: thumbnail,
      ),
    );
  }
}

class _ReviewsView extends StatelessWidget {
  final int productId;
  final String productTitle;
  final String thumbnail;

  const _ReviewsView({
    required this.productId,
    required this.productTitle,
    required this.thumbnail,
  });

  // Login লাগে। Login হলে ফর্ম খোলে, সংরক্ষণ হলে বার্তা
  Future<void> _write(BuildContext context) async {
    final signedIn = await requireLogin(
      context,
      reason: 'Sign in to write a review.',
    );
    if (!signedIn || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => ReviewFormScreen(
          productId: productId,
          productTitle: productTitle,
          thumbnail: thumbnail,
        ),
      ),
    );
    if (saved == true) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Review saved.')));
    }
  }

  Future<void> _delete(BuildContext context) async {
    final provider = context.read<MyReviewsProvider>();
    final messenger = ScaffoldMessenger.of(context);

    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final c = dialogContext.colors;
            return AlertDialog(
              backgroundColor: c.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: c.border),
              ),
              title: Text(
                'Delete your review?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              content: Text(
                'This cannot be undone.',
                style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: c.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(
                    'Delete',
                    style: TextStyle(
                      color: c.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed) return;

    final ok = await provider.delete(productId);
    messenger
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(
            ok ? 'Review deleted.' : 'Could not delete the review.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final server = context.watch<ProductReviewsProvider>();
    final mine = context.watch<MyReviewsProvider>().forProduct(productId);

    Widget title(String text) => Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 10),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 1.5,
          color: c.faint,
        ),
      ),
    );

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        centerTitle: false,
        title: Text(
          'Reviews',
          style: TextStyle(
            color: c.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
        children: [
          Text(
            productTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 15, height: 1.3, color: c.muted),
          ),

          title('YOUR REVIEW'),
          if (mine == null)
            FilledButton(
              onPressed: () => _write(context),
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              child: const Text('Write a review'),
            )
          else
            _MyReviewCard(
              review: mine,
              onEdit: () => _write(context),
              onDelete: () => _delete(context),
            ),

          title('CUSTOMER REVIEWS'),
          ..._serverSection(context, server),

          const SizedBox(height: 24),
          Text(
            'Customer reviews come from the demo server. Your own review is saved '
            'on this phone only and other shoppers cannot see it.',
            style: TextStyle(fontSize: 13, height: 1.4, color: c.faint),
          ),
        ],
      ),
    );
  }

  List<Widget> _serverSection(
    BuildContext context,
    ProductReviewsProvider server,
  ) {
    final c = context.colors;

    switch (server.status) {
      case DataStatus.loading:
        return [
          Semantics(
            label: 'Loading reviews',
            child: Column(
              children: [
                for (var i = 0; i < 3; i++)
                  Container(
                    height: 64,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: c.track,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
              ],
            ),
          ),
        ];

      case DataStatus.error:
        return [
          Text(
            'Could not load reviews. ${server.error?.message ?? ''}',
            style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
          ),
          if (server.error?.isRetryable ?? false)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: server.load,
                style: TextButton.styleFrom(
                  foregroundColor: c.accentFg,
                  minimumSize: const Size(96, 48),
                ),
                child: const Text('Try again'),
              ),
            ),
        ];

      case DataStatus.ready:
        if (server.reviews.isEmpty) {
          return [
            Text(
              'No reviews yet.',
              style: TextStyle(fontSize: 14, color: c.muted),
            ),
          ];
        }
        return [
          _SummaryBlock(provider: server),
          const SizedBox(height: 8),
          for (final r in server.reviews) ...[
            Divider(height: 1, color: c.border),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      StarRating(rating: r.rating),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          r.reviewerName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: c.ink,
                          ),
                        ),
                      ),
                      if (r.date != null)
                        Text(
                          formatDate(r.date!.toLocal()),
                          style: TextStyle(fontSize: 12, color: c.faint),
                        ),
                    ],
                  ),
                  if (r.comment.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      r.comment,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: c.muted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ];
    }
  }
}

// গড় আর "কত তারায় কয়টা"-র দণ্ড
class _SummaryBlock extends StatelessWidget {
  final ProductReviewsProvider provider;

  const _SummaryBlock({required this.provider});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final s = provider.summary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              s.averageText,
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: c.ink,
              ),
            ),
            Text('out of 5', style: TextStyle(fontSize: 13, color: c.muted)),
            const SizedBox(height: 4),
            Text(
              '${s.count} ${s.count == 1 ? 'review' : 'reviews'}',
              style: TextStyle(fontSize: 13, color: c.muted),
            ),
          ],
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            children: [
              for (var stars = 5; stars >= 1; stars--)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 52,
                        child: Text(
                          '$stars stars',
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: s.count == 0
                                ? 0
                                : s.byStars[stars]! / s.count,
                            minHeight: 6,
                            color: c.accentFg,
                            backgroundColor: c.track,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 28,
                        child: Text(
                          '${s.byStars[stars]}',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontSize: 12, color: c.muted),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MyReviewCard extends StatelessWidget {
  final MyReview review;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MyReviewCard({
    required this.review,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StarRating(rating: review.rating, size: 18),
              const SizedBox(width: 10),
              Text(
                formatDate(review.updatedAt),
                style: TextStyle(fontSize: 12, color: c.faint),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Text(
              review.comment,
              style: TextStyle(fontSize: 14, height: 1.45, color: c.ink),
            ),
          ),
          const SizedBox(height: 4),
          Wrap(
            children: [
              TextButton(
                onPressed: onEdit,
                style: TextButton.styleFrom(
                  foregroundColor: c.accentFg,
                  minimumSize: const Size(64, 48),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                child: const Text('Edit'),
              ),
              TextButton(
                onPressed: onDelete,
                style: TextButton.styleFrom(
                  foregroundColor: c.danger,
                  minimumSize: const Size(64, 48),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
