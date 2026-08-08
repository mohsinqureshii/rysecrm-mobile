import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/widgets/common.dart';
import '../../core/widgets/ryse_logo.dart';
import '../../data/crm_store.dart';
import '../../data/services/auth_provider.dart';
import '../notifications/notifications_screen.dart';
import '../search/search_screen.dart';
import '../settings/profile_screen.dart';

/// Standard top app bar with global search, notifications, and profile.
///
/// When [showLogo] is true the title area shows the RYSE wordmark instead of
/// plain text (used on the Home tab).
AppBar buildRyseAppBar(
  BuildContext context, {
  required String title,
  bool showLogo = false,
  List<Widget> extraActions = const [],
  PreferredSizeWidget? bottom,
}) {
  final unread = context.select<CrmStore, int>(
    (s) => s.unreadNotificationCount,
  );
  final userName =
      context.select<AuthProvider, String>((a) => a.user?.name ?? 'User');

  return AppBar(
    titleSpacing: showLogo ? 16 : null,
    title: showLogo ? const RyseWordmark(fontSize: 24) : Text(title),
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
