import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/storage/secure_token_store.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/api_auth_repository.dart';
import 'features/auth/presentation/auth_provider.dart';
import 'features/products/data/api_product_repository.dart';
import 'features/products/data/product_repository.dart';
import 'features/products/presentation/product_list_provider.dart';
import 'features/shell/app_shell.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final tokenStore = SecureTokenStore();

  late final AuthProvider authProvider;
  final api = ApiClient(
    tokenStore: tokenStore,
    onSessionExpired: () => authProvider.handleSessionExpired(),
  );

  final ProductRepository productRepository = ApiProductRepository(api);
  authProvider = AuthProvider(ApiAuthRepository(api), tokenStore);

  unawaited(authProvider.restore());

  runApp(
    ShopLiteApp(
      productRepository: productRepository,
      authProvider: authProvider,
    ),
  );
}

class ShopLiteApp extends StatelessWidget {
  final ProductRepository productRepository;
  final AuthProvider authProvider;

  const ShopLiteApp({
    super.key,
    required this.productRepository,
    required this.authProvider,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProductRepository>.value(value: productRepository),

        ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ChangeNotifierProvider(
          create: (context) =>
              ProductListProvider(context.read<ProductRepository>())..load(),
        ),
      ],
      child: MaterialApp(
        title: 'ShopLite',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(Brightness.light),
        darkTheme: buildAppTheme(Brightness.dark),
        themeMode: ThemeMode.system,
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
      ),
    );
  }
}
