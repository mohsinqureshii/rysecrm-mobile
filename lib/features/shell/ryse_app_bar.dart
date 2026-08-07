import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/services/auth_provider.dart';
import '../notifications/notifications_screen.dart';
import '../search/search_screen.dart';
import '../settings/profile_screen.dart';

/// Standard top app bar with global search, notifications, and profile.
AppBar buildRyseAppBar(
  BuildContext context, {
  required String title,
  List<Widget> extraActions = const [],
  PreferredSizeWidget? bottom,
}) {
  final unread = context.select<CrmStore, int>(
    (s) => s.unreadNotificationCount,
  );
  final userName =
      context.select<AuthProvider, String>((a) => a.user?.name ?? 'User');

  return AppBar(
    title: Text(title),
    bottom: bottom,
    actions: [
      ...extraActions,
      IconButton(
        tooltip: 'Search',
        icon: const Icon(Icons.search),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
        ),
      ),
      IconButton(
        tooltip: 'Notifications',
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text('$unread'),
          child: const Icon(Icons.notifications_outlined),
        ),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const NotificationsScreen(),
          ),
        ),
      ),
      Padding(
        padding: const EdgeInsets.only(right: 12, left: 4),
        child: Center(
          child: GestureDetector(
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const ProfileScreen()),
            ),
            child: InitialsAvatar(name: userName, size: 32),
          ),
        ),
      ),
    ],
  );
}
