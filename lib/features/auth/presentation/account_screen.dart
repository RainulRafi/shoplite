import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_message.dart';
import '../../addresses/presentation/address_provider.dart';
import '../../addresses/presentation/addresses_screen.dart';
import '../../profile/domain/profile_data.dart';
import '../../profile/presentation/edit_profile_screen.dart';
import '../../profile/presentation/profile_provider.dart';
import '../../wishlist/presentation/wishlist_provider.dart';
import '../../wishlist/presentation/wishlist_screen.dart';
import 'auth_provider.dart';
import 'require_login.dart';
import '../../orders/presentation/orders_provider.dart';
import '../../orders/presentation/orders_screen.dart';
import 'account_more_menu.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: Text(
          'Account',
          style: TextStyle(
            color: c.ink,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: Consumer<AuthProvider>(
        builder: (context, auth, child) {
          switch (auth.status) {
            case AuthStatus.unknown:
              return const SizedBox.shrink();
            case AuthStatus.signedOut:
              return const _GuestView();
            case AuthStatus.signedIn:
              return const _SignedInView();
          }
        },
      ),
    );
  }
}

void _openSettings(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => Scaffold(
        appBar: AppBar(title: const Text('Settings')),
        body: const SizedBox.shrink(),
      ),
    ),
  );
}

class _GuestView extends StatelessWidget {
  const _GuestView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthProvider>();

    return Column(
      children: [
        if (auth.notice != null)
          Container(
            margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
            decoration: BoxDecoration(
              color: c.surface,
              border: Border.all(color: c.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    auth.notice!,
                    style: TextStyle(fontSize: 14, height: 1.4, color: c.ink),
                  ),
                ),
                IconButton(
                  tooltip: 'Dismiss',
                  icon: Icon(Icons.close, size: 20, color: c.subtle),
                  onPressed: auth.dismissNotice,
                ),
              ],
            ),
          ),
        Expanded(
          child: StateMessage(
            title: 'You are browsing as a guest',
            body:
                'Browsing and searching never need an account. '
                'Sign in to view your account.',
            action: FilledButton(
              onPressed: () => requireLogin(
                context,
                reason: 'Sign in to view your account.',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: c.accent,
                foregroundColor: c.onAccent,
                minimumSize: const Size(160, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              child: const Text('Sign in'),
            ),
          ),
        ),
        Divider(height: 1, color: c.border),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              const AccountMoreMenu(signedIn: false),
              _MenuRow(
                icon: Icons.settings_outlined,
                title: 'Settings',
                onTap: () => _openSettings(context),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _SignedInView extends StatelessWidget {
  const _SignedInView();

  Future<void> _editProfile(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const EditProfileScreen(),
      ),
    );
    if (saved == true) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Profile saved.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthProvider>();
    final profile = context.watch<ProfileProvider>().effective;
    final addresses = context.watch<AddressProvider>();
    final wishlist = context.watch<WishlistProvider>();
    final orders = context.watch<OrdersProvider>();

    if (profile == null) {
      final error = auth.profileError;
      if (error == null) return const _ProfileSkeleton();

      return StateMessage(
        title: 'Could not load your profile',
        body: error.message,
        titleColor: c.danger,
        action: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error.isRetryable)
              FilledButton(
                onPressed: auth.loadProfile,
                style: FilledButton.styleFrom(
                  backgroundColor: c.accent,
                  foregroundColor: c.onAccent,
                  minimumSize: const Size(160, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                child: const Text('Try again'),
              ),
            TextButton(
              onPressed: auth.signOut,
              style: TextButton.styleFrom(
                foregroundColor: c.accentFg,
                minimumSize: const Size(160, 48),
              ),
              child: const Text('Sign out'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: c.accentFg,
      backgroundColor: c.surface,
      onRefresh: () async {
        await auth.loadProfile();
        final error = auth.profileError;
        if (error != null && context.mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(error.message)));
        }
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          Row(
            children: [
              _Avatar(profile: profile),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    if (profile.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: c.muted),
                      ),
                    ],
                    if (profile.phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.phone,
                        style: TextStyle(fontSize: 14, color: c.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Divider(height: 1, color: c.border),
          _MenuRow(
            icon: Icons.edit_outlined,
            title: 'Edit profile',
            onTap: () => _editProfile(context),
          ),
          Divider(height: 1, color: c.border),

          _MenuRow(
            icon: Icons.receipt_long_outlined,
            title: 'My orders',
            trailing: orders.orders.isEmpty ? null : '${orders.orders.length}',
            onTap: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const OrdersScreen())),
          ),
          Divider(height: 1, color: c.border),

          _MenuRow(
            icon: Icons.location_on_outlined,
            title: 'Addresses',
            trailing: addresses.addresses.isEmpty
                ? null
                : '${addresses.addresses.length}',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const AddressesScreen())),
          ),
          Divider(height: 1, color: c.border),
          _MenuRow(
            icon: Icons.favorite_border,
            title: 'Wishlist',
            trailing: wishlist.count == 0 ? null : '${wishlist.count}',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const WishlistScreen())),
          ),
          Divider(height: 1, color: c.border),
          const AccountMoreMenu(signedIn: true),
          _MenuRow(
            icon: Icons.settings_outlined,
            title: 'Settings',
            onTap: () => _openSettings(context),
          ),
          Divider(height: 1, color: c.border),
          const SizedBox(height: 28),
          OutlinedButton(
            onPressed: auth.signOut,
            style: OutlinedButton.styleFrom(
              foregroundColor: c.ink,
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
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _MenuRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          children: [
            Icon(icon, size: 22, color: c.muted),
            const SizedBox(width: 16),
            Expanded(
              child: Text(title, style: TextStyle(fontSize: 15, color: c.ink)),
            ),
            if (trailing != null) ...[
              Text(trailing!, style: TextStyle(fontSize: 14, color: c.faint)),
              const SizedBox(width: 8),
            ],
            Icon(Icons.chevron_right, size: 22, color: c.subtle),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final EffectiveProfile profile;

  const _Avatar({required this.profile});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Semantics(
      label: 'Profile picture of ${profile.fullName}',
      excludeSemantics: true,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: c.field,
          shape: BoxShape.circle,
          border: Border.all(color: c.border),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              profile.initials,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: c.accentFg,
              ),
            ),
            if (profile.image.isNotEmpty)
              ClipOval(
                child: Image.network(
                  profile.image,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => const SizedBox.shrink(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    Widget block(double width, double height) => Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: c.track,
        borderRadius: BorderRadius.circular(6),
      ),
    );

    return Semantics(
      label: 'Loading your profile',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(color: c.track, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  block(160, 18),
                  const SizedBox(height: 10),
                  block(120, 14),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
