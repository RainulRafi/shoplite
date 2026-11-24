import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shoplite/core/network/api_exception.dart';
import 'package:shoplite/features/auth/presentation/auth_provider.dart';
import 'package:shoplite/features/browsing/presentation/browsing_provider.dart';
import 'package:shoplite/features/home/presentation/home_provider.dart';
import 'package:shoplite/features/home/presentation/home_screen.dart';
import 'package:shoplite/features/products/data/product_category.dart';
import 'package:shoplite/features/products/data/product_page.dart';
import 'package:shoplite/features/products/data/product_repository.dart';
import 'package:shoplite/features/profile/presentation/profile_provider.dart';
import 'package:shoplite/features/shell/shell_tabs.dart';

import '../../../helpers/auth_rig.dart';
import '../../../helpers/order_fixtures.dart';
import '../../../helpers/widget_harness.dart';

class MockProductRepository extends Mock implements ProductRepository {}

const _noInternet = ApiException(
  type: ApiErrorType.noConnection,
  message: 'No internet',
);

void _stub(
  MockProductRepository repo, {
  required bool dealsOk,
  required bool topOk,
  List<String> titles = const [],
}) {
  when(() => repo.fetchCategories()).thenAnswer(
    (_) async => const [ProductCategory(slug: 'beauty', name: 'Beauty')],
  );

  final page = ProductPage(
    products: [
      for (var i = 0; i < titles.length; i++)
        testProduct(
          i + 1,
          price: 20 + i.toDouble(),
          discount: 15,
          title: titles[i],
        ),
    ],
    total: titles.length,
    skip: 0,
    limit: 10,
  );

  when(
    () => repo.fetchTop(HomeRank.deals, limit: any(named: 'limit')),
  ).thenAnswer((_) => dealsOk ? Future.value(page) : Future.error(_noInternet));
  when(
    () => repo.fetchTop(HomeRank.topRated, limit: any(named: 'limit')),
  ).thenAnswer((_) => topOk ? Future.value(page) : Future.error(_noInternet));
}

Future<ShellTabs> _pumpHome(
  WidgetTester tester,
  MockProductRepository repo, {
  double textScale = 1.0,
}) async {
  useTallScreen(tester);
  final rig = AuthRig();
  await rig.auth.restore();
  final home = HomeProvider(repo);
  await home.load();
  final tabs = ShellTabs();

  await pumpScreen(
    tester,
    const HomeScreen(),
    textScale: textScale,
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: rig.auth),
      ChangeNotifierProvider<HomeProvider>.value(value: home),
      ChangeNotifierProvider<BrowsingProvider>.value(
        value: BrowsingProvider(FakeBrowsingRepository(), rig.auth),
      ),
      ChangeNotifierProvider<ProfileProvider>.value(
        value: ProfileProvider(MockProfileRepository(), rig.auth),
      ),
      ChangeNotifierProvider<ShellTabs>.value(value: tabs),
    ],
  );
  await tester.pump();
  return tabs;
}

void main() {
  late MockProductRepository repo;

  setUp(() => repo = MockProductRepository());

  testWidgets('one failing section does not break the others', (tester) async {
    _stub(repo, dealsOk: false, topOk: false);
    await _pumpHome(tester, repo);

    expect(find.text('Beauty'), findsOneWidget);
    expect(find.textContaining('Could not load this.'), findsNWidgets(2));
    expect(find.text('Retry'), findsNWidgets(2));
  });

  testWidgets('the offers come from the shop rules, not from typed numbers', (
    tester,
  ) async {
    _stub(repo, dealsOk: false, topOk: false);
    await _pumpHome(tester, repo);

    expect(find.text('Free shipping'), findsOneWidget);
    expect(
      find.text('On standard delivery for orders over \$50.00.'),
      findsOneWidget,
    );
    expect(find.text('SAVE10'), findsOneWidget);
  });

  testWidgets(
    'tapping the fake search box opens the shop and asks for the keyboard',
    (tester) async {
      _stub(repo, dealsOk: false, topOk: false);
      final tabs = await _pumpHome(tester, repo);

      await tester.tap(find.text('Search products'));
      await tester.pump();

      expect(tabs.current, ShellTab.shop);
      expect(tabs.searchFocusRequest, 1);
    },
  );

  for (final scale in [1.0, 1.3, 1.6]) {
    testWidgetsWithImages(
      'home does not overflow with the font at $scale times',
      (tester) async {
        _stub(
          repo,
          dealsOk: true,
          topOk: true,
          titles: const [
            'A rather long product title that has to wrap onto several lines',
            'Short',
            'Another long product title for the second card in the row',
          ],
        );
        await _pumpHome(tester, repo, textScale: scale);
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  }
}
