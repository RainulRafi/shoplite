import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/product_query.dart';
import '../product_list_provider.dart';

Future<void> showSortSheet(BuildContext context) {
  final provider = context.read<ProductListProvider>();
  final current = provider.query.sort;

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: context.colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) {
      final c = sheetContext.colors;

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sort by',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              const SizedBox(height: 8),
              for (final sort in ProductSort.values)
                Semantics(
                  button: true,
                  selected: sort == current,
                  child: InkWell(
                    onTap: () {
                      provider.setSort(sort);
                      Navigator.pop(sheetContext);
                    },
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: 52),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              sort.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: sort == current
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: sort == current ? c.accentFg : c.ink,
                              ),
                            ),
                          ),
                          if (sort == current)
                            Icon(Icons.check, size: 20, color: c.accentFg),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
