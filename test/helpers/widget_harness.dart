import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:network_image_mock/network_image_mock.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shoplite/core/theme/app_theme.dart';
import 'package:shoplite/features/addresses/data/address_repository.dart';
import 'package:shoplite/features/browsing/data/browsing_repository.dart';
import 'package:shoplite/features/browsing/domain/viewed_product.dart';
import 'package:shoplite/features/profile/data/profile_repository.dart';
import 'package:shoplite/features/reviews/data/reviews_repository.dart';
import 'package:shoplite/features/settings/data/account_data_repository.dart';
import 'package:shoplite/features/settings/data/settings_repository.dart';

class MockAddressRepository extends Mock implements AddressRepository {}

class MockProfileRepository extends Mock implements ProfileRepository {}

class MockReviewsRepository extends Mock implements ReviewsRepository {}

class MockAccountDataRepository extends Mock implements AccountDataRepository {}

class FakeSettingsRepository implements SettingsRepository {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;
}

class FakeBrowsingRepository implements BrowsingRepository {
  final Map<String, List<ViewedProduct>> viewed = {};
  final Map<String, List<String>> searches = {};

  @override
  Future<List<ViewedProduct>> loadViewed(String ownerId) async =>
      List.of(viewed[ownerId] ?? const <ViewedProduct>[]);

  @override
  Future<void> recordViewed(
    String ownerId,
    ViewedProduct item, {
    required int keep,
  }) async {
    final old = viewed[ownerId] ?? const <ViewedProduct>[];
    viewed[ownerId] = [
      item,
      ...old.where((v) => v.productId != item.productId),
    ].take(keep).toList();
  }

  @override
  Future<void> clearViewed(String ownerId) async => viewed.remove(ownerId);

  @override
  Future<List<String>> loadSearches(String ownerId) async =>
      List.of(searches[ownerId] ?? const <String>[]);

  @override
  Future<void> recordSearch(
    String ownerId,
    String term, {
    required int keep,
  }) async {
    final old = searches[ownerId] ?? const <String>[];
    searches[ownerId] = [
      term,
      ...old.where((s) => s.toLowerCase() != term.toLowerCase()),
    ].take(keep).toList();
  }

  @override
  Future<void> removeSearch(String ownerId, String term) async =>
      searches[ownerId]?.removeWhere(
        (s) => s.toLowerCase() == term.toLowerCase(),
      );

  @override
  Future<void> clearSearches(String ownerId) async => searches.remove(ownerId);
}

Widget _app({required Widget home, required double textScale}) {
  return MaterialApp(
    theme: buildAppTheme(Brightness.light),
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(textScale)),
      child: child!,
    ),
    home: home,
  );
}

Future<void> pumpScreen(
  WidgetTester tester,
  Widget screen, {
  List<SingleChildWidget> providers = const [],
  double textScale = 1.0,
}) async {
  final app = _app(home: screen, textScale: textScale);
  await tester.pumpWidget(
    providers.isEmpty ? app : MultiProvider(providers: providers, child: app),
  );
  await tester.pump();
}

Future<void> pumpPushed(
  WidgetTester tester,
  Widget screen, {
  List<SingleChildWidget> providers = const [],
  double textScale = 1.0,
}) async {
  final root = Builder(
    builder: (context) => Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () =>
              Navigator.of(context)
                  .push(MaterialPageRoute<void>(builder: (_) => screen)),
          child: const Text('open test screen'),
        ),
      ),
    ),
  );
  await pumpScreen(tester, root, providers: providers, textScale: textScale);
  await tester.tap(find.text('open test screen'));
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
}

void useTallScreen(
  WidgetTester tester, {
  double width = 800,
  double height = 3000,
}) {
  tester.view.physicalSize = Size(width, height);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void testWidgetsWithImages(
  String description,
  Future<void> Function(WidgetTester tester) body,
) {
  testWidgets(description, (tester) async {
    await mockNetworkImagesFor(() => body(tester));
  });
}
