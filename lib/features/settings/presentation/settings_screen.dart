import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/presentation/auth_owner.dart';
import '../../auth/presentation/auth_provider.dart';
import '../data/account_data_repository.dart';
import 'settings_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _busy = false;

  Future<void> _deleteData(String owner) async {
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            final c = dialogContext.colors;
            return AlertDialog(
              backgroundColor: c.surface,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: c.border),
              ),
              title: Text(
                'Delete my data?',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: c.ink,
                ),
              ),
              content: Text(
                'This removes your cart, addresses, wishlist, orders, reviews, history '
                'and profile changes from this phone, then signs you out. It cannot be '
                'undone. Your account on the demo server is not affected.',
                style: TextStyle(fontSize: 14, height: 1.45, color: c.muted),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: Text(
                    'Cancel',
                    style: TextStyle(
                      color: c.muted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: Text(
                    'Delete my data',
                    style: TextStyle(
                      color: c.danger,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        ) ??
        false;
    if (!confirmed || !mounted) return;

    final repo = context.read<AccountDataRepository>();
    final auth = context.read<AuthProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    setState(() => _busy = true);
    try {
      await repo.eraseOwner(owner);
      await auth.signOut();
      navigator.pop();
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Your data was deleted from this phone and you were signed out.',
            ),
          ),
        );
    } on Exception catch (e) {
      if (kDebugMode) debugPrint('Could not delete the data: $e');
      if (mounted) setState(() => _busy = false);
      messenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Could not delete your data. Nothing was changed.'),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final settings = context.watch<SettingsProvider>();
    final owner = context.watch<AuthProvider>().userOwner;

    Widget label(String text) => Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: c.faint,
      ),
    );

    Widget option(String text, ThemeMode mode) {
      final selected = settings.themeMode == mode;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: text,
          child: GestureDetector(
            onTap: () => context.read<SettingsProvider>().setThemeMode(mode),
            child: Container(
              height: 48,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? c.accent : c.surface,
                border: Border.all(color: selected ? c.accent : c.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? c.onAccent : c.ink,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return PopScope(
      canPop: !_busy,
      child: Scaffold(
        backgroundColor: c.bg,
        appBar: AppBar(
          backgroundColor: c.bg,
          elevation: 0,
          scrolledUnderElevation: 0,
          iconTheme: IconThemeData(color: c.ink),
          centerTitle: false,
          title: Text(
            'Settings',
            style: TextStyle(
              color: c.ink,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            label('APPEARANCE'),
            const SizedBox(height: 10),
            Row(
              children: [
                option('Light', ThemeMode.light),
                const SizedBox(width: 8),
                option('Dark', ThemeMode.dark),
                const SizedBox(width: 8),
                option('System', ThemeMode.system),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              "System follows your phone's light or dark setting.",
              style: TextStyle(fontSize: 13, height: 1.4, color: c.faint),
            ),

            if (owner != null) ...[
              const SizedBox(height: 32),
              label('YOUR DATA'),
              const SizedBox(height: 10),
              Text(
                'Everything you save in this app lives on this phone. You can delete it '
                'for this account at any time.',
                style: TextStyle(fontSize: 14, height: 1.45, color: c.muted),
              ),
              const SizedBox(height: 14),
              OutlinedButton(
                onPressed: _busy ? null : () => _deleteData(owner),
                style: OutlinedButton.styleFrom(
                  foregroundColor: c.danger,
                  side: BorderSide(color: c.border),
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                child: Text(_busy ? 'Deleting...' : 'Delete my data'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
