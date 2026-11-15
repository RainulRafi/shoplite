import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/state_message.dart';
import '../data/user_profile.dart';
import 'auth_provider.dart';
import 'require_login.dart';

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
      ],
    );
  }
}

class _SignedInView extends StatelessWidget {
  const _SignedInView();

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user == null) {
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
              _Avatar(user: user),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: c.ink,
                      ),
                    ),
                    if (user.email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 14, color: c.muted),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Divider(height: 1, color: c.border),
          _InfoRow(label: 'Username', value: user.username),
          Divider(height: 1, color: c.border),
          if (user.email.isNotEmpty) ...[
            _InfoRow(label: 'Email', value: user.email),
            Divider(height: 1, color: c.border),
          ],
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

class _Avatar extends StatelessWidget {
  final UserProfile user;

  const _Avatar({required this.user});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Semantics(
      label: 'Profile picture of ${user.fullName}',
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
              user.initials,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: c.accentFg,
              ),
            ),
            if (user.image.isNotEmpty)
              ClipOval(
                child: Image.network(
                  user.image,
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(label, style: TextStyle(fontSize: 14, color: c.muted)),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 14, height: 1.4, color: c.ink),
            ),
          ),
        ],
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
