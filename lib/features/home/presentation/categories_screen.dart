import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_message.dart';
import '../../products/domain/product_query.dart';
import '../../products/presentation/product_list_provider.dart';
import '../../shell/shell_tabs.dart';
import 'home_provider.dart';

class CategoriesScreen extends StatelessWidget {
  const CategoriesScreen({super.key});

  void _pick(BuildContext context, String slug) {
    final list = context.read<ProductListProvider>();
    final tabs = context.read<ShellTabs>();
    final navigator = Navigator.of(context);

    list.applyPreset(ProductQuery(category: slug));
    navigator.popUntil((route) => route.isFirst);
    tabs.go(ShellTab.shop);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final home = context.watch<HomeProvider>();
    final state = home.categories;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        centerTitle: false,
        title: Text(
          'Categories',
          style: TextStyle(
            color: c.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: switch (state.status) {
        SectionStatus.loading => Semantics(
          label: 'Loading categories',
          child: ListView(
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            children: [
              for (var i = 0; i < 8; i++)
                Container(
                  height: 20,
                  margin: const EdgeInsets.symmetric(vertical: 18),
                  decoration: BoxDecoration(
                    color: c.track,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
            ],
          ),
        ),
        SectionStatus.error => StateMessage(
          title: 'Could not load categories',
          body: state.error!.message,
          titleColor: c.danger,
          action: state.error!.isRetryable
              ? FilledButton(
                  onPressed: home.retryCategories,
                  style: FilledButton.styleFrom(
                    backgroundColor: c.accent,
                    foregroundColor: c.onAccent,
                    minimumSize: const Size(160, 48),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Try again'),
                )
              : null,
        ),
        SectionStatus.ready => ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          itemCount: state.data!.length,
          separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
          itemBuilder: (context, i) {
            final category = state.data![i];
            return InkWell(
              onTap: () => _pick(context, category.slug),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 56),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        category.name,
                        style: TextStyle(fontSize: 15, color: c.ink),
                      ),
                    ),
                    Icon(Icons.chevron_right, size: 22, color: c.subtle),
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
