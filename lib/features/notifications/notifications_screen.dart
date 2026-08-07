import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../shell/record_nav.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final notifications = store.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (store.unreadNotificationCount > 0)
            TextButton(
              onPressed: store.markAllNotificationsRead,
              child: const Text(
                'Mark all read',
                style: TextStyle(color: Colors.white),
              ),
            ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications',
              message: 'Deal updates and AI alerts will land here.',
            )
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: notifications.length,
              separatorBuilder: (_, _) => const Divider(indent: 72),
              itemBuilder: (context, index) {
                final notification = notifications[index];
                return ListTile(
                  tileColor: notification.read
                      ? null
                      : AppColors.cloud.withValues(alpha: 0.5),
                  onTap: () {
                    store.markNotificationRead(notification.id);
                    if (notification.relatedType != null &&
                        notification.relatedId != null) {
                      openRecord(
                        context,
                        notification.relatedType!,
                        notification.relatedId!,
                      );
                    }
                  },
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: notification.read
                          ? AppColors.background
                          : AppColors.cloud,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      notification.icon,
                      size: 20,
                      color: notification.read
                          ? AppColors.textTertiary
                          : AppColors.brand,
                    ),
                  ),
                  title: Text(
                    notification.title,
                    style: TextStyle(
                      fontSize: 14.5,
                      fontWeight: notification.read
                          ? FontWeight.w600
                          : FontWeight.w800,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notification.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.3,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Formatters.relative(notification.timestamp),
                          style: const TextStyle(
                            fontSize: 11.5,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: notification.read
                      ? null
                      : Container(
                          width: 9,
                          height: 9,
                          decoration: const BoxDecoration(
                            color: AppColors.brand,
                            shape: BoxShape.circle,
                          ),
                        ),
                );
              },
            ),
    );
  }
}
