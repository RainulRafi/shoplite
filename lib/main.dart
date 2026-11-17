import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/database/app_database.dart';
import 'core/network/api_client.dart';
import 'core/storage/secure_token_store.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/addresses/data/address_repository.dart';
import 'features/addresses/data/sqlite_address_repository.dart';
import 'features/addresses/presentation/address_provider.dart';
import 'features/auth/data/api_auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/cart/data/cart_repository.dart';
import 'features/cart/data/sqlite_cart_repository.dart';
import 'features/cart/presentation/cart_provider.dart';
import 'features/orders/data/order_repository.dart';
import 'features/orders/data/sqlite_order_repository.dart';
import 'features/orders/presentation/orders_provider.dart';
import 'features/products/data/api_product_repository.dart';
import 'features/products/data/product_repository.dart';
import 'features/products/presentation/product_list_provider.dart';
import 'features/profile/data/profile_repository.dart';
import 'features/profile/data/sqlite_profile_repository.dart';
import 'features/profile/presentation/profile_provider.dart';
import 'features/settings/data/sqlite_settings_repository.dart';
import 'features/settings/presentation/settings_provider.dart';
import 'features/shell/app_shell.dart';
import 'features/shell/shell_tabs.dart';
import 'features/wishlist/data/sqlite_wishlist_repository.dart';
import 'features/wishlist/data/wishlist_repository.dart';
import 'features/wishlist/presentation/wishlist_provider.dart';

class AppDependencies {
  final ProductRepository products;
  final CartRepository carts;
  final AddressRepository addresses;
  final WishlistRepository wishlist;
  final ProfileRepository profile;
  final OrderRepository orders;
  final AuthProvider auth;
  final SettingsProvider settings;

  const AppDependencies({
    required this.products,
    required this.carts,
    required this.addresses,
    required this.wishlist,
    required this.profile,
    required this.orders,
    required this.auth,
    required this.settings,
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStore = SecureTokenStore();

  late final AuthProvider authProvider;
  final api = ApiClient(
    tokenStore: tokenStore,
    onSessionExpired: () => authProvider.handleSessionExpired(),
  );
  authProvider = AuthProvider(ApiAuthRepository(api), tokenStore);

  final settings = SettingsProvider(
    SqliteSettingsRepository(() => AppDatabase.instance.database),
  );
  await settings.load();

  unawaited(authProvider.restore());

  runApp(
    ShopLiteApp(
      deps: AppDependencies(
        products: ApiProductRepository(api),
        carts: SqliteCartRepository(() => AppDatabase.instance.database),
        addresses: SqliteAddressRepository(() => AppDatabase.instance.database),
        wishlist: SqliteWishlistRepository(() => AppDatabase.instance.database),
        profile: SqliteProfileRepository(() => AppDatabase.instance.database),
        orders: SqliteOrderRepository(() => AppDatabase.instance.database),
        auth: authProvider,
        settings: settings,
      ),
    ),
  );
}

class ShopLiteApp extends StatelessWidget {
  final AppDependencies deps;

  const ShopLiteApp({super.key, required this.deps});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProductRepository>.value(value: deps.products),

        Provider<OrderRepository>.value(value: deps.orders),
        ChangeNotifierProvider<AuthProvider>.value(value: deps.auth),
        ChangeNotifierProvider<SettingsProvider>.value(value: deps.settings),
        ChangeNotifierProvider(create: (_) => ShellTabs()),
        ChangeNotifierProvider(
          create: (context) =>
              ProductListProvider(context.read<ProductRepository>())..load(),
        ),

        ChangeNotifierProvider(
          lazy: false,
          create: (context) =>
              CartProvider(deps.carts, context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) =>
              AddressProvider(deps.addresses, context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) =>
              WishlistProvider(deps.wishlist, context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) =>
              ProfileProvider(deps.profile, context.read<AuthProvider>()),
        ),
        ChangeNotifierProvider(
          lazy: false,
          create: (context) =>
              OrdersProvider(deps.orders, context.read<AuthProvider>()),
        ),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, child) {
          return MaterialApp(
            title: 'ShopLite',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(Brightness.light),
            darkTheme: buildAppTheme(Brightness.dark),
            themeMode: settings.themeMode,
            builder: (context, child) {
              final isDark = Theme.of(context).brightness == Brightness.dark;
              final colors = isDark ? AppColors.dark : AppColors.light;
              return AnnotatedRegion<SystemUiOverlayStyle>(
                value: SystemUiOverlayStyle(
                  statusBarColor: Colors.transparent,
                  statusBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                  systemNavigationBarColor: colors.surface,
                  systemNavigationBarIconBrightness: isDark
                      ? Brightness.light
                      : Brightness.dark,
                ),
                child: child!,
              );
            },
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
