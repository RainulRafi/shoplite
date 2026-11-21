import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../help/presentation/about_screen.dart';
import '../../help/presentation/help_screen.dart';
import '../../notifications/presentation/notifications_provider.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../reviews/presentation/my_reviews_provider.dart';
import '../../reviews/presentation/my_reviews_screen.dart';

// ============================================
// Account-এর নতুন মেনু-সারি। লগইন করা ব্যবহারকারী: বিজ্ঞপ্তি, আমার রিভিউ, Help, About। অতিথি:
// শুধু Help আর About। প্রতিটা সারির নিচে Divider (উপরের সারি Divider দিয়ে শেষ হয়)
// ============================================
class AccountMoreMenu extends StatelessWidget {
  final bool signedIn;

  const AccountMoreMenu({super.key, required this.signedIn});

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;

    // select: শুধু এই সংখ্যা বদলালে মেনু আবার আঁকা হয়
    final unread = signedIn
        ? context.select<NotificationsProvider, int>((n) => n.unreadCount)
        : 0;
    final reviewCount = signedIn
        ? context.select<MyReviewsProvider, int>((r) => r.reviews.length)
        : 0;

    return Column(
      children: [
        if (signedIn) ...[
          _Row(
            icon: Icons.notifications_none,
            title: 'Notifications',
            trailing: unread == 0 ? null : '$unread new',
            onTap: () => _push(context, const NotificationsScreen()),
          ),
          Divider(height: 1, color: c.border),
          _Row(
            icon: Icons.rate_review_outlined,
            title: 'My reviews',
            trailing: reviewCount == 0 ? null : '$reviewCount',
            onTap: () => _push(context, const MyReviewsScreen()),
          ),
          Divider(height: 1, color: c.border),
        ],
        _Row(
          icon: Icons.help_outline,
          title: 'Help',
          onTap: () => _push(context, const HelpScreen()),
        ),
        Divider(height: 1, color: c.border),
        _Row(
          icon: Icons.info_outline,
          title: 'About and legal',
          onTap: () => _push(context, const AboutScreen()),
        ),
        Divider(height: 1, color: c.border),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback onTap;

  const _Row({
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
