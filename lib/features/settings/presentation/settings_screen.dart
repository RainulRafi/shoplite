import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_info.dart';
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

    Widget tile(String label, ThemeMode mode) => _ThemeTile(
      label: label,
      mode: mode,
      selected: settings.themeMode == mode,
      onTap: () => context.read<SettingsProvider>().setThemeMode(mode),
    );

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
            const _SectionLabel('APPEARANCE'),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                tile('Light', ThemeMode.light),
                const SizedBox(width: 10),
                tile('Dark', ThemeMode.dark),
                const SizedBox(width: 10),
                tile('System', ThemeMode.system),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              "System follows your phone's light or dark setting.",
              style: TextStyle(fontSize: 13, height: 1.4, color: c.faint),
            ),

            if (owner != null) ...[
              const SizedBox(height: 32),
              const _SectionLabel('YOUR DATA'),
              const SizedBox(height: 12),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Everything you save in this app lives on this phone. You can delete it '
                      'for this account at any time.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.45,
                        color: c.muted,
                      ),
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
                ),
              ),
            ],

            const SizedBox(height: 32),
            const _SectionLabel('ABOUT'),
            const SizedBox(height: 12),
            _Card(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppInfo.name,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: c.ink,
                      ),
                    ),
                  ),
                  Text(
                    'Version ${AppInfo.version}',
                    style: TextStyle(fontSize: 14, color: c.muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: context.colors.faint,
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: c.surface,
        border: Border.all(color: c.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: child,
    );
  }
}

class _ThemeTile extends StatelessWidget {
  final String label;
  final ThemeMode mode;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeTile({
    required this.label,
    required this.mode,
    required this.selected,
    required this.onTap,
  });

  Widget _preview() {
    switch (mode) {
      case ThemeMode.light:
        return const _MiniScreen(AppColors.light);
      case ThemeMode.dark:
        return const _MiniScreen(AppColors.dark);
      case ThemeMode.system:
        return const Row(
          children: [
            Expanded(child: _MiniScreen(AppColors.light)),
            Expanded(child: _MiniScreen(AppColors.dark)),
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        label: '$label theme',
        excludeSemantics: true,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(
                color: selected ? c.accentFg : c.border,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 64,
                    width: double.infinity,
                    child: _preview(),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: c.ink,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniScreen extends StatelessWidget {
  final AppColors palette;

  const _MiniScreen(this.palette);

  Widget _bar(Color color, double height) => Container(
    height: height,
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(3),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final p = palette;

    return Container(
      color: p.bg,
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FractionallySizedBox(widthFactor: 0.6, child: _bar(p.ink, 6)),
          const SizedBox(height: 5),
          FractionallySizedBox(widthFactor: 1, child: _bar(p.muted, 4)),
          const SizedBox(height: 3),
          FractionallySizedBox(widthFactor: 0.8, child: _bar(p.muted, 4)),
          const Spacer(),
          FractionallySizedBox(widthFactor: 0.5, child: _bar(p.accent, 10)),
        ],
      ),
    );
  }
}
