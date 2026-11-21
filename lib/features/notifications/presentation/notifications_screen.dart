import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_format.dart';
import '../../../core/widgets/state_message.dart';
import '../../orders/presentation/order_detail_screen.dart';
import '../domain/app_notification.dart';
import 'notifications_provider.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _open(BuildContext context, AppNotification n) {
    context.read<NotificationsProvider>().markRead(n.key);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: n.orderId)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final provider = context.watch<NotificationsProvider>();
    final items = provider.items;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: c.bg,
      appBar: AppBar(
        backgroundColor: c.bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: c.ink),
        centerTitle: false,
        title: Text(
          'Notifications',
          style: TextStyle(
            color: c.ink,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          if (provider.unreadCount > 0)
            TextButton(
              onPressed: provider.markAllRead,
              style: TextButton.styleFrom(
                foregroundColor: c.accentFg,
                minimumSize: const Size(64, 48),
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              child: const Text('Mark all read'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: items.isEmpty
          ? const StateMessage(
              title: 'No notifications yet',
              body: 'Updates about your orders show up here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              itemCount: items.length,
              separatorBuilder: (_, _) => Divider(height: 1, color: c.border),
              itemBuilder: (context, i) {
                final n = items[i];
                return Semantics(
                  button: true,
                  label: '${n.read ? '' : 'Unread. '}${n.title}. ${n.body}',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: () => _open(context, n),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 16,
                            child: n.read
                                ? null
                                : Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: c.accentFg,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                          ),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  n.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: n.read
                                        ? FontWeight.w500
                                        : FontWeight.w700,
                                    color: c.ink,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  n.body,
                                  style: TextStyle(
                                    fontSize: 14,
                                    height: 1.4,
                                    color: c.muted,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  formatRelative(n.at, now),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: c.faint,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
