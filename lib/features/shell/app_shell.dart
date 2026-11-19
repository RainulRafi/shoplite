import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../auth/presentation/account_screen.dart';
import '../cart/presentation/cart_provider.dart';
import '../cart/presentation/cart_screen.dart';
import '../home/presentation/home_screen.dart';
import '../products/presentation/product_list_screen.dart';
import 'shell_tabs.dart';

class AppShell extends StatelessWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final tabs = context.watch<ShellTabs>();

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      body: IndexedStack(
        index: tabs.current.index,
        children: const [
          HomeScreen(),
          ProductListScreen(),
          CartScreen(),
          AccountScreen(),
        ],
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: BottomNavigationBar(
                currentIndex: tabs.current.index,
                onTap: (i) => tabs.go(ShellTab.values[i]),
                backgroundColor: c.surface,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: c.accentFg,
                unselectedItemColor: c.faint,
                selectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                unselectedLabelStyle: const TextStyle(fontSize: 12),
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.home_outlined),
                    activeIcon: Icon(Icons.home),
                    label: 'Home',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.storefront_outlined),
                    activeIcon: Icon(Icons.storefront),
                    label: 'Shop',
                  ),
                  BottomNavigationBarItem(
                    icon: _CartIcon(active: false),
                    activeIcon: _CartIcon(active: true),
                    label: 'Cart',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Account',
                  ),
                ],
              ),
            ),
    );
  }
}

class _CartIcon extends StatelessWidget {
  final bool active;

  const _CartIcon({required this.active});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final count = context.select<CartProvider, int>((cart) => cart.itemCount);

    return Badge(
      isLabelVisible: count > 0,
      label: Text(count > 99 ? '99+' : '$count'),
      backgroundColor: c.accent,
      textColor: c.onAccent,
      child: Icon(active ? Icons.shopping_cart : Icons.shopping_cart_outlined),
    );
  }
}
