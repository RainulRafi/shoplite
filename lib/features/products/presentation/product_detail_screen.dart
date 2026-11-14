import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/price_format.dart';
import '../../../core/utils/text_format.dart';
import '../data/product.dart';
import '../data/product_repository.dart';
import 'product_detail_provider.dart';
import 'widgets/product_image.dart';
import 'widgets/stock_note.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;

  const ProductDetailScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          ProductDetailProvider(ctx.read<ProductRepository>(), product)
            ..refresh(),
      child: const _DetailView(),
    );
  }
}

class _DetailView extends StatelessWidget {
  const _DetailView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final provider = context.watch<ProductDetailProvider>();
    final product = provider.product;

    final meta = [
      product.brand ?? '',
      prettyCategory(product.category),
    ].where((part) => part.isNotEmpty).join('  ·  ');

    final images = product.images.isNotEmpty
        ? product.images
        : (product.thumbnail.isNotEmpty ? [product.thumbnail] : <String>[]);

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        centerTitle: false,
        title: Text(
          'Details',
          style: TextStyle(
            color: c.ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: provider.refreshing
              ? LinearProgressIndicator(
                  minHeight: 2,
                  color: c.accentFg,
                  backgroundColor: c.track,
                )
              : const SizedBox(height: 2),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          if (provider.refreshError != null) ...[
            _RefreshNotice(
              error: provider.refreshError!,
              onRetry: provider.refresh,
            ),
            const SizedBox(height: 16),
          ],

          _Gallery(images: images, title: product.title),
          const SizedBox(height: 20),

          Text(
            product.title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              height: 1.25,
              color: c.ink,
            ),
          ),
          if (meta.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(meta, style: TextStyle(fontSize: 14, color: c.muted)),
          ],
          const SizedBox(height: 16),

          _PriceRow(product: product),
          if (product.rating > 0) ...[
            const SizedBox(height: 6),
            Text(
              'Rated ${product.rating.toStringAsFixed(1)} out of 5',
              style: TextStyle(fontSize: 13, color: c.faint),
            ),
          ],
          StockNote(product: product, showInStock: true),

          if (product.description.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'ABOUT THIS PRODUCT',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.5,
                color: c.faint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              product.description,
              style: TextStyle(fontSize: 15, height: 1.5, color: c.ink),
            ),
          ],

          _InfoRows(product: product),
        ],
      ),
    );
  }
}

class _Gallery extends StatefulWidget {
  final List<String> images;
  final String title;

  const _Gallery({required this.images, required this.title});

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final urls = widget.images.isEmpty ? const [''] : widget.images;
    final shown = _index < urls.length ? _index : 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth < 340 ? constraints.maxWidth : 340.0;

        return Column(
          children: [
            SizedBox(
              height: side,
              child: PageView.builder(
                itemCount: urls.length,
                onPageChanged: (i) => setState(() => _index = i),
                itemBuilder: (_, i) => Center(
                  child: ProductImage(
                    url: urls[i],
                    label: '${widget.title}, photo ${i + 1} of ${urls.length}',
                    size: side,
                  ),
                ),
              ),
            ),
            if (urls.length > 1) ...[
              const SizedBox(height: 8),
              Text(
                '${shown + 1} of ${urls.length}',
                style: TextStyle(fontSize: 13, color: c.faint),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _PriceRow extends StatelessWidget {
  final Product product;

  const _PriceRow({required this.product});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Wrap(
      spacing: 10,
      crossAxisAlignment: WrapCrossAlignment.end,
      children: [
        Text(
          formatPrice(
            product.hasDiscount ? product.discountedPrice : product.price,
          ),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: c.ink,
          ),
        ),
        if (product.hasDiscount) ...[
          Text(
            formatPrice(product.price),
            style: TextStyle(
              fontSize: 15,
              color: c.faint,
              decoration: TextDecoration.lineThrough,
            ),
          ),
          Text(
            '${product.discountPercentage.round()}% off',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: c.highlight,
            ),
          ),
        ],
      ],
    );
  }
}

class _InfoRows extends StatelessWidget {
  final Product product;

  const _InfoRows({required this.product});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final rows = <(String, String)>[
      if (product.shippingInformation != null)
        ('Shipping', product.shippingInformation!),
      if (product.warrantyInformation != null)
        ('Warranty', product.warrantyInformation!),
      if (product.returnPolicy != null) ('Returns', product.returnPolicy!),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          Divider(height: 1, color: c.border),
          for (final row in rows) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 96,
                    child: Text(
                      row.$1,
                      style: TextStyle(fontSize: 14, color: c.muted),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.$2,
                      style: TextStyle(fontSize: 14, height: 1.4, color: c.ink),
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: c.border),
          ],
        ],
      ),
    );
  }
}

class _RefreshNotice extends StatelessWidget {
  final ApiException error;
  final VoidCallback onRetry;

  const _RefreshNotice({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Showing the details we already have. ${error.message}',
              style: TextStyle(fontSize: 13, height: 1.4, color: c.muted),
            ),
          ),

          if (error.isRetryable)
            TextButton(
              onPressed: onRetry,
              style: TextButton.styleFrom(
                foregroundColor: c.accentFg,
                minimumSize: const Size(64, 48),
              ),
              child: const Text('Retry'),
            ),
        ],
      ),
    );
  }
}
