import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../../core/money/money.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/app_input.dart';
import '../../../home/presentation/home_provider.dart';
import '../../domain/product_query.dart';
import '../product_list_provider.dart';

Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => const _FilterSheet(),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet();

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late final TextEditingController _min;
  late final TextEditingController _max;
  late String? _category;
  late bool _inStock;
  late double _rating;
  String? _priceError;

  static const List<(String, double)> _ratingOptions = [
    ('Any', 0),
    ('3+', 3),
    ('4+', 4),
    ('4.5+', 4.5),
  ];

  @override
  void initState() {
    super.initState();

    final q = context.read<ProductListProvider>().query;
    _category = q.category;
    _inStock = q.filters.inStockOnly;
    _rating = q.filters.minRating;
    _min = TextEditingController(text: _dollarText(q.filters.minPrice));
    _max = TextEditingController(text: _dollarText(q.filters.maxPrice));
  }

  @override
  void dispose() {
    _min.dispose();
    _max.dispose();
    super.dispose();
  }

  String _dollarText(Money? m) {
    if (m == null) return '';
    return m.cents % 100 == 0
        ? '${m.cents ~/ 100}'
        : (m.cents / 100).toStringAsFixed(2);
  }

  void _reset() {
    setState(() {
      _category = null;
      _inStock = false;
      _rating = 0;
      _priceError = null;
      _min.clear();
      _max.clear();
    });
  }

  void _apply() {
    final minText = _min.text.trim();
    final maxText = _max.text.trim();
    final minValue = minText.isEmpty ? null : double.tryParse(minText);
    final maxValue = maxText.isEmpty ? null : double.tryParse(maxText);

    final invalid =
        (minText.isNotEmpty && (minValue == null || minValue < 0)) ||
        (maxText.isNotEmpty && (maxValue == null || maxValue < 0));
    if (invalid) {
      setState(
        () => _priceError = 'Enter prices as numbers, like 25 or 24.99.',
      );
      return;
    }
    if (minValue != null && maxValue != null && maxValue < minValue) {
      setState(() => _priceError = 'The maximum must be at least the minimum.');
      return;
    }

    context.read<ProductListProvider>().applyRefinements(
      category: _category,
      filters: ProductFilters(
        minPrice: minValue == null ? null : Money.fromDollars(minValue),
        maxPrice: maxValue == null ? null : Money.fromDollars(maxValue),
        inStockOnly: _inStock,
        minRating: _rating,
      ),
    );
    Navigator.pop(context);
  }

  Widget _label(String text, AppColors c) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 8),
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

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final home = context.watch<HomeProvider>();
    final categories = home.categories;

    Widget categoryField() {
      switch (categories.status) {
        case SectionStatus.loading:
          return Text(
            'Loading categories...',
            style: TextStyle(fontSize: 14, color: c.muted),
          );
        case SectionStatus.error:
          return Row(
            children: [
              Expanded(
                child: Text(
                  'Categories are not available right now.',
                  style: TextStyle(fontSize: 14, color: c.muted),
                ),
              ),
              TextButton(
                onPressed: home.retryCategories,
                style: TextButton.styleFrom(
                  foregroundColor: c.accentFg,
                  minimumSize: const Size(64, 48),
                ),
                child: const Text('Retry'),
              ),
            ],
          );
        case SectionStatus.ready:
          final list = categories.data!;
          return DropdownButtonFormField<String?>(
            initialValue: list.any((x) => x.slug == _category)
                ? _category
                : null,
            isExpanded: true,
            dropdownColor: c.surface,
            style: TextStyle(color: c.ink, fontSize: 15),
            icon: Icon(Icons.keyboard_arrow_down, color: c.subtle),
            decoration: appInputDecoration(context),
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All categories'),
              ),
              for (final x in list)
                DropdownMenuItem<String?>(value: x.slug, child: Text(x.name)),
            ],
            onChanged: (v) => setState(() => _category = v),
          );
      }
    }

    Widget ratingRow() => Row(
      children: [
        for (final option in _ratingOptions) ...[
          Expanded(
            child: Semantics(
              button: true,
              selected: _rating == option.$2,
              label: option.$2 == 0 ? 'Any rating' : '${option.$1} stars',
              child: GestureDetector(
                onTap: () => setState(() => _rating = option.$2),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _rating == option.$2 ? c.accent : c.surface,
                    border: Border.all(
                      color: _rating == option.$2 ? c.accent : c.border,
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    option.$1,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _rating == option.$2 ? c.onAccent : c.ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (option != _ratingOptions.last) const SizedBox(width: 8),
        ],
      ],
    );

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * 0.9,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Filters',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _reset,
                    style: TextButton.styleFrom(
                      foregroundColor: c.accentFg,
                      minimumSize: const Size(64, 48),
                    ),
                    child: const Text('Reset'),
                  ),
                ],
              ),

              _label('CATEGORY', c),
              categoryField(),

              _label('PRICE (AFTER DISCOUNTS)', c),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _min,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      style: TextStyle(color: c.ink, fontSize: 15),
                      onChanged: (_) => setState(() => _priceError = null),
                      decoration: appInputDecoration(
                        context,
                        hint: 'Min',
                      ).copyWith(prefixText: '\$ '),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _max,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                      ],
                      style: TextStyle(color: c.ink, fontSize: 15),
                      onChanged: (_) => setState(() => _priceError = null),
                      decoration: appInputDecoration(
                        context,
                        hint: 'Max',
                      ).copyWith(prefixText: '\$ '),
                    ),
                  ),
                ],
              ),
              if (_priceError != null) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    _priceError!,
                    style: TextStyle(fontSize: 13, color: c.danger),
                  ),
                ),
              ],

              _label('RATING', c),
              ratingRow(),

              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'In stock only',
                      style: TextStyle(fontSize: 15, color: c.ink),
                    ),
                  ),
                  Switch(
                    value: _inStock,
                    onChanged: (v) => setState(() => _inStock = v),
                    activeThumbColor: Colors.white,
                    activeTrackColor: c.accent,
                    inactiveThumbColor: c.subtle,
                    inactiveTrackColor: c.track,
                  ),
                ],
              ),

              const SizedBox(height: 16),
              FilledButton(
                onPressed: _apply,
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
                child: const Text('Show results'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
