import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'dev/style_guide_screen.dart';

void main() {
  runApp(const ShopLiteApp());
}

class ShopLiteApp extends StatelessWidget {
  const ShopLiteApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShopLite',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(Brightness.light),
      darkTheme: buildAppTheme(Brightness.dark),

      // ThemeMode.system follows the phone's own dark/light setting.
      // A separate toggle could be added to Settings later; it isn't needed now.
      themeMode: ThemeMode.system,

      // In dark mode, the status bar clock and battery icons blend in unless they are light.
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
      home: const StyleGuideScreen(),
    );
  }
}
