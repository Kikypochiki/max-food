import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:max_food/features/listings/models/notification_model.dart';
import 'package:max_food/features/listings/presentation/providers/alert_providers.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F8F3),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2A8F3A),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          notificationsAsync.maybeWhen(
            data: (notifications) {
              final hasUnread = notifications.any((n) => !n.isRead);
              if (!hasUnread) return const SizedBox.shrink();

              return TextButton.icon(
                onPressed: () async {
                  try {
                    await ref
                        .read(notificationsControllerProvider.notifier)
                        .markAllAsRead();
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update notifications: $e')),
                    );
                  }
                },
                icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
                label: const Text(
                  'Mark all read',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 64,
                      color: Color(0xFF667A6C),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'All quiet here!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D4F2A),
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'You have no notifications yet. Subscriptions to categories or farmers will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF667A6C),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final notification = notifications[index];
              return _NotificationItemRow(
                notification: notification,
                timeAgo: _formatRelativeTime(notification.createdAt.toLocal()),
                onTap: () async {
                  // Mark as read
                  if (!notification.isRead) {
                    await ref
                        .read(notificationsControllerProvider.notifier)
                        .markAsRead(notification.id);
                  }

                  if (!context.mounted) return;

                  // Direct navigation based on notification data payload
                  final data = notification.data;
                  if (notification.type == 'new_listing' && data != null) {
                    final listingId = data['listing_id']?.toString();
                    if (listingId != null) {
                      context.push('/listings/$listingId');
                    }
                  } else if (notification.type == 'new_message' && data != null) {
                    final roomId = data['room_id']?.toString();
                    if (roomId != null) {
                      context.push('/chat/room/$roomId');
                    }
                  }
                },
              );
            },
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2A8F3A)),
        ),
        error: (err, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              'Failed to load notifications:\n$err',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ),
    );
  }
}

class _NotificationItemRow extends StatelessWidget {
  const _NotificationItemRow({
    required this.notification,
    required this.timeAgo,
    required this.onTap,
  });

  final NotificationModel notification;
  final String timeAgo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final iconColor = isUnread ? const Color(0xFF2A8F3A) : const Color(0xFF667A6C);
    final icon = notification.type == 'new_message'
        ? Icons.chat_bubble_outline
        : Icons.notifications_active_outlined;

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isUnread ? const Color(0xFFE7F4E9) : Colors.transparent,
          border: const Border(
            bottom: BorderSide(color: Color(0xFFD8E8DA), width: 0.8),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Notification Icon
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isUnread ? const Color(0xFFC2E2C8) : const Color(0xFFE8ECE9),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            // Message Contents
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: isUnread ? FontWeight.w800 : FontWeight.w600,
                            color: const Color(0xFF1D4F2A),
                          ),
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: isUnread ? const Color(0xFF2A8F3A) : const Color(0xFF8A9A8F),
                          fontWeight: isUnread ? FontWeight.w700 : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.body,
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.35,
                      color: isUnread ? const Color(0xFF223A27) : const Color(0xFF55665A),
                      fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                  ),
                ],
              ),
            ),
            if (isUnread) ...[
              const SizedBox(width: 10),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 6),
                decoration: const BoxDecoration(
                  color: Color(0xFF2A8F3A),
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
