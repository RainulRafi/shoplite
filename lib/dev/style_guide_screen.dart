import 'package:flutter/material.dart';

import '../core/config/app_config.dart';
import '../core/theme/app_colors.dart';

class StyleGuideScreen extends StatelessWidget {
  const StyleGuideScreen({super.key});

  // Small section heading ("COLOURS", "TYPE"...)
  Widget _section(String text, AppColors c) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
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
  }

  // A color swatch: a colored square and its name
  Widget _swatch(String name, Color color, AppColors c) {
    return SizedBox(
      width: 96,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 6),
          Text(name, style: TextStyle(fontSize: 12, color: c.muted)),
        ],
      ),
    );
  }

  // ============================================
  // Skeleton: Static blocks shaped like the real card while loading.
  // A spinner leaves the screen blank and doesn't show what's coming.
  // No animation here, just placeholder shapes.
  // ============================================
  Widget _skeletonCard(AppColors c) {
    Widget block(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: c.track,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            decoration: BoxDecoration(
              color: c.track,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          block(double.infinity, 14),
          const SizedBox(height: 8),
          block(120, 14),
          const SizedBox(height: 12),
          block(70, 16),
        ],
      ),
    );
  }

  // Product card example. Always show image, name, rating, and price in this order.
  Widget _productCard(AppColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 110,
            width: double.infinity,
            decoration: BoxDecoration(
              color: c.field,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.image_outlined, color: c.subtle, size: 32),
          ),
          const SizedBox(height: 12),
          Text(
            'Wireless earbuds with charging case',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              height: 1.3,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 4),
          Text('4.6 rating', style: TextStyle(fontSize: 13, color: c.faint)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '\$24.99',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '\$29.99',
                style: TextStyle(
                  fontSize: 13,
                  color: c.faint,
                  decoration: TextDecoration.lineThrough,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '17% off',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: c.highlight,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          'Style guide',
          style: TextStyle(color: c.ink, fontWeight: FontWeight.w700),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
        children: [
          _section('COLOURS', c),
          Wrap(
            spacing: 12,
            runSpacing: 16,
            children: [
              _swatch('bg', c.bg, c),
              _swatch('surface', c.surface, c),
              _swatch('border', c.border, c),
              _swatch('field', c.field, c),
              _swatch('ink', c.ink, c),
              _swatch('muted', c.muted, c),
              _swatch('faint', c.faint, c),
              _swatch('accent', c.accent, c),
              _swatch('accentFg', c.accentFg, c),
              _swatch('highlight', c.highlight, c),
              _swatch('danger', c.danger, c),
              _swatch('success', c.success, c),
            ],
          ),

          _section('TYPE', c),
          Text(
            'Page title',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Product name',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: c.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Body text is set at fifteen pixels with generous line spacing, '
            'so a short description stays easy to read on a small screen.',
            style: TextStyle(fontSize: 15, height: 1.45, color: c.ink),
          ),
          const SizedBox(height: 10),
          Text(
            'Caption and secondary detail',
            style: TextStyle(fontSize: 13, color: c.muted),
          ),

          _section('BUTTONS', c),
          FilledButton(
            onPressed: () {},
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
            child: const Text('Add to cart'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {},
            style: TextButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              foregroundColor: c.accentFg,
              textStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            child: const Text('Save for later'),
          ),

          _section('INPUT', c),
          TextField(
            style: TextStyle(color: c.ink),
            decoration: InputDecoration(
              hintText: 'Search products',
              hintStyle: TextStyle(color: c.subtle),
              filled: true,
              fillColor: c.field,
              prefixIcon: Icon(Icons.search, color: c.subtle),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          _section('PRODUCT CARD', c),
          _productCard(c),

          _section('LOADING', c),
          _skeletonCard(c),

          _section('ERROR', c),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Could not load products',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.danger,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Check your connection and try again.',
                  style: TextStyle(fontSize: 14, height: 1.4, color: c.muted),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {},
                  style: TextButton.styleFrom(
                    foregroundColor: c.accentFg,
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(48, 48),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),

          _section('EMPTY', c),
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  'No products match "lamp"',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Try a different word or clear the search.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: c.muted),
                ),
              ],
            ),
          ),

          _section('CONFIG', c),
          // Ticket 0.1 proof: AppConfig is being read correctly.
          Text(
            AppConfig.baseUrl,
            style: TextStyle(fontSize: 13, color: c.faint),
          ),
        ],
      ),
    );
  }
}
