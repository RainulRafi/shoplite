import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/state/data_status.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/star_rating.dart';
import '../../../core/widgets/state_message.dart';
import '../../products/presentation/widgets/product_image.dart';
import '../../products/presentation/widgets/product_skeleton_tile.dart';
import 'my_reviews_provider.dart';
import 'reviews_screen.dart';

class MyReviewsScreen extends StatelessWidget {
  const MyReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final provider = context.watch<MyReviewsProvider>();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        centerTitle: false,
        title: Text(
          'My reviews',
          style: TextStyle(
            color: c.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: switch (provider.status) {
        DataStatus.loading => Semantics(
          label: 'Loading your reviews',
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            children: const [ProductSkeletonTile(), ProductSkeletonTile()],
          ),
        ),
        DataStatus.error => StateMessage(
          title: 'Could not load your reviews',
          body: 'Something went wrong reading them from this phone.',
          titleColor: c.danger,
          action: FilledButton(
            onPressed: provider.retry,
            style: FilledButton.styleFrom(
              backgroundColor: c.accent,
              foregroundColor: c.onAccent,
              minimumSize: const Size(160, 48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Try again'),
          ),
        ),
        DataStatus.ready =>
          provider.reviews.isEmpty
              ? const StateMessage(
                  title: 'No reviews yet',
                  body: 'Reviews you write on a product page show up here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: provider.reviews.length,
                  separatorBuilder: (_, _) =>
                      Divider(height: 1, color: c.border),
                  itemBuilder: (context, i) {
                    final r = provider.reviews[i];
                    return InkWell(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ReviewsScreen(
                            productId: r.productId,
                            productTitle: r.productTitle,
                            thumbnail: r.thumbnail,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ProductImage(
                              url: r.thumbnail,
                              label: r.productTitle,
                              size: 56,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    r.productTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: c.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      StarRating(rating: r.rating),
                                      const SizedBox(width: 8),
                                      Text(
                                        formatDate(r.updatedAt),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: c.faint,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    r.comment,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      height: 1.4,
                                      color: c.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
      },
    );
  }
}
