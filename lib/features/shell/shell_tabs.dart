import 'package:flutter/foundation.dart';

enum ShellTab { home, shop, cart, account }

class ShellTabs extends ChangeNotifier {
  ShellTab _current = ShellTab.home;
  int _searchFocusRequest = 0;

  ShellTab get current => _current;

  int get searchFocusRequest => _searchFocusRequest;

  void go(ShellTab tab) {
    if (tab == _current) return;
    _current = tab;
    notifyListeners();
  }

  void openShopWithSearch() {
    _current = ShellTab.shop;
    _searchFocusRequest++;
    notifyListeners();
  }
}
