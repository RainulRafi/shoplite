import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'features/products/data/api_product_repository.dart';
import 'features/products/data/product_repository.dart';
import 'features/products/presentation/product_list_provider.dart';
import 'features/products/presentation/product_list_screen.dart';

void main() {
  final ProductRepository productRepository = ApiProductRepository(ApiClient());
  runApp(ShopLiteApp(productRepository: productRepository));
}

class ShopLiteApp extends StatelessWidget {
  final ProductRepository productRepository;

  const ShopLiteApp({super.key, required this.productRepository});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ProductRepository>.value(value: productRepository),
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
        home: const ProductListScreen(),
      ),
    );
  }
}
