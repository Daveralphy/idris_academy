import 'package:flutter/material.dart';
import 'package:idris_academy/models/notification_model.dart';
import 'package:idris_academy/services/user_service.dart';
import 'package:provider/provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  void _showNotificationDialog(BuildContext context, NotificationModel notification) {
    final userService = Provider.of<UserService>(context, listen: false);
    // Mark as read when opened
    if (!notification.isRead) {
      userService.markNotificationAsRead(notification.id);
    }

    // Customize title for messages to include the sender
    final String dialogTitle = notification.type == NotificationType.message
        ? 'Message from ${notification.sender ?? 'System'}'
        : notification.title;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogTitle),
        content: SingleChildScrollView(child: Text(notification.body)),
        actions: [
          TextButton(
            child: const Text('Close'),
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    // Use a consumer to get the latest list of notifications and react to changes
    return Consumer<UserService>(
      builder: (context, userService, child) {
        final notifications = userService.getNotifications();

        return Column(
          children: [
            // Action button at the top
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: notifications.any((n) => !n.isRead)
                      ? () => userService.markAllNotificationsAsRead()
                      : null, // Disable if all are read
                  child: const Text('Mark all as read'),
                ),
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_off_outlined, size: 80, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          const Text('You have no notifications yet.', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          const SizedBox(height: 8),
                          const Text('New updates and messages will appear here.', style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.separated(
                      itemCount: notifications.length,
                      separatorBuilder: (context, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final notification = notifications[index];
                        return _buildNotificationTile(context, notification, userService);
                      },
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotificationTile(BuildContext context, NotificationModel notification, UserService userService) {
    final colorScheme = Theme.of(context).colorScheme;
    final isUnread = !notification.isRead;

    return Material(
      // ignore: deprecated_member_use
      color: isUnread ? colorScheme.surface.withOpacity(0.5) : Colors.transparent,
      child: ListTile(
        onTap: () => _showNotificationDialog(context, notification),
        onLongPress: () => _showLongPressMenu(context, notification, userService),
        leading: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              _getIconForType(notification.type),
              size: 36,
              color: colorScheme.primary,
            ),
            if (isUnread)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
                  ),
                ),
              ),
          ],
        ),
        title: Text(notification.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(notification.body),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(notification.timestamp),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
        isThreeLine: true,
      ),
    );
  }

  void _showLongPressMenu(BuildContext context, NotificationModel notification, UserService userService) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              // Only show "Mark as unread" if the notification is already read
              if (notification.isRead)
                ListTile(
                  leading: const Icon(Icons.mark_email_unread_outlined),
                  title: const Text('Mark as unread'),
                  onTap: () {
                    userService.markNotificationAsUnread(notification.id);
                    Navigator.pop(context); // Close the bottom sheet
                  },
                ),
              ListTile(
                leading: const Icon(Icons.cancel_outlined),
                title: const Text('Cancel'),
                onTap: () => Navigator.pop(context),
              ),
            ],
          ),
        );
      },
    );
  }

  IconData _getIconForType(NotificationType type) {
    switch (type) {
      case NotificationType.courseUpdate:
        return Icons.school_outlined;
      case NotificationType.message:
        return Icons.mail_outline;
      case NotificationType.announcement:
        return Icons.campaign_outlined;
    }
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays >= 1) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours >= 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes >= 1) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}