import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../auth/presentation/account_screen.dart';
import '../products/presentation/product_list_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [ProductListScreen(), AccountScreen()],
      ),
      bottomNavigationBar: keyboardOpen
          ? null
          : DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: c.border)),
              ),
              child: BottomNavigationBar(
                currentIndex: _index,
                onTap: (i) => setState(() => _index = i),
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
                    icon: Icon(Icons.storefront_outlined),
                    activeIcon: Icon(Icons.storefront),
                    label: 'Shop',
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
