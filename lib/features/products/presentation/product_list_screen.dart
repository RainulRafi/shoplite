import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_colors.dart';
import 'product_list_provider.dart';
import 'widgets/product_skeleton_tile.dart';
import 'widgets/product_tile.dart';

class ProductListScreen extends StatelessWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Products',
          style: TextStyle(
            color: c.ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),

      body: Consumer<ProductListProvider>(
        builder: (context, provider, child) {
          switch (provider.status) {
            case LoadStatus.loading:
              return const _SkeletonList();

            case LoadStatus.error:
              return _ErrorView(error: provider.error!, onRetry: provider.load);

            case LoadStatus.success:
              if (provider.products.isEmpty) {
                return const _Message(
                  title: 'No products yet',
                  body: 'Check back a little later.',
                );
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                    child: Text(
                      'Showing ${provider.products.length} of ${provider.total} products',
                      style: TextStyle(fontSize: 13, color: c.faint),
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                      itemCount: provider.products.length,
                      separatorBuilder: (_, _) =>
                          Divider(height: 1, color: c.border),
                      itemBuilder: (_, index) =>
                          ProductTile(product: provider.products[index]),
                    ),
                  ),
                ],
              );
          }
        },
      ),
    );
  }
}

class _SkeletonList extends StatelessWidget {
  const _SkeletonList();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Semantics(
      label: 'Loading products',
      child: ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        itemCount: 8,
        separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
        itemBuilder: (_, _) => const ProductSkeletonTile(),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final ApiException error;
  final VoidCallback onRetry;

  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return _Message(
      title: 'Could not load products',
      body: error.message,
      titleColor: c.danger,
      action: error.isRetryable
          ? FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              child: const Text('Try again'),
            )
          : null,
    );
  }
}

class _Message extends StatelessWidget {
  final String title;
  final String body;
  final Color? titleColor;
  final Widget? action;

  const _Message({
    required this.title,
    required this.body,
    this.titleColor,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: titleColor ?? c.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
            ),
            if (action != null) ...[const SizedBox(height: 20), action!],
          ],
        ),
      ),
    );
  }
}
