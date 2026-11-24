import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shoplite/features/auth/presentation/auth_provider.dart';
import 'package:shoplite/features/browsing/presentation/browsing_provider.dart';
import 'package:shoplite/features/home/presentation/home_provider.dart';
import 'package:shoplite/features/products/data/product.dart';
import 'package:shoplite/features/products/data/product_page.dart';
import 'package:shoplite/features/products/data/product_repository.dart';
import 'package:shoplite/features/products/domain/product_query.dart';
import 'package:shoplite/features/products/presentation/product_list_provider.dart';
import 'package:shoplite/features/products/presentation/product_list_screen.dart';
import 'package:shoplite/features/shell/shell_tabs.dart';

import '../../../helpers/auth_rig.dart';
import '../../../helpers/order_fixtures.dart';
import '../../../helpers/widget_harness.dart';

class MockProductRepository extends Mock implements ProductRepository {}

class _Env {
  final ProductListProvider list;
  final BrowsingProvider browsing;

  _Env(this.list, this.browsing);
}

void _stubServer(MockProductRepository repo) {
  when(
    () => repo.fetchProducts(
      limit: any(named: 'limit'),
      skip: any(named: 'skip'),
      query: any(named: 'query'),
    ),
  ).thenAnswer((invocation) async {
    final query = invocation.namedArguments[#query] as String?;
    final products = query == null
        ? [testProduct(1), testProduct(2)]
        : <Product>[];
    return ProductPage(
      products: products,
      total: products.length,
      skip: 0,
      limit: 20,
    );
  });
}

Future<_Env> _pumpShop(
  WidgetTester tester,
  MockProductRepository repo, {
  Map<String, List<String>> searches = const {},
}) async {
  useTallScreen(tester);
  _stubServer(repo);

  final rig = AuthRig();
  await rig.auth.restore();
  final fake = FakeBrowsingRepository()..searches.addAll(searches);
  final browsing = BrowsingProvider(fake, rig.auth);
  final list = ProductListProvider(
    repo,
    debounce: const Duration(milliseconds: 20),
  );
  await list.load();

  await pumpScreen(
    tester,
    const ProductListScreen(),
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: rig.auth),
      ChangeNotifierProvider<ProductListProvider>.value(value: list),
      ChangeNotifierProvider<BrowsingProvider>.value(value: browsing),
      ChangeNotifierProvider<HomeProvider>.value(value: HomeProvider(repo)),
      ChangeNotifierProvider<ShellTabs>.value(value: ShellTabs()),
    ],
  );
  await tester.pump();
  await tester.pump();
  return _Env(list, browsing);
}

void main() {
  late MockProductRepository repo;

  setUp(() => repo = MockProductRepository());

  testWidgetsWithImages('a search with no matches says so and can be cleared', (
    tester,
  ) async {
    await _pumpShop(tester, repo);
    expect(find.text('Showing 2 of 2 products'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'zzzz');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();
    await tester.pump();

    expect(find.text('No results for "zzzz"'), findsOneWidget);
    expect(find.text('Clear search'), findsOneWidget);

    await tester.tap(find.text('Clear search'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Showing 2 of 2 products'), findsOneWidget);
  });

  testWidgetsWithImages(
    'focusing the empty search box lists recent searches that can be reused',
    (tester) async {
      final env = await _pumpShop(
        tester,
        repo,
        searches: {
          'guest': ['phone', 'laptop'],
        },
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      expect(find.text('RECENT SEARCHES'), findsOneWidget);
      expect(find.text('phone'), findsOneWidget);

      await tester.tap(find.text('laptop'));
      await tester.pump();
      await tester.pump();

      expect(find.text('No results for "laptop"'), findsOneWidget);
      expect(env.browsing.searches.first, 'laptop');
    },
  );

  testWidgetsWithImages(
    'the sort sheet changes the sort and the button says so',
    (tester) async {
      final env = await _pumpShop(tester, repo);

      await tester.tap(find.text('Sort: Relevance'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Sort by'), findsOneWidget);

      await tester.tap(find.text('Top rated'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();

      expect(env.list.query.sort, ProductSort.topRated);
      expect(find.text('Sort: Top rated'), findsOneWidget);
    },
  );
}
