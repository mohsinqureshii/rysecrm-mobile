import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/services/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Container(
            color: AppColors.header,
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 28),
            child: Column(
              children: [
                InitialsAvatar(name: user?.name ?? 'User', size: 76),
                const SizedBox(height: 12),
                Text(
                  user?.name ?? 'User',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (user?.title.isNotEmpty ?? false) user!.title,
                    if (user?.company.isNotEmpty ?? false) user!.company,
                  ].join(' · '),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 13.5,
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Account'),
          FieldCard(
            children: [
              DetailFieldRow(label: 'Email', value: user?.email ?? ''),
              DetailFieldRow(label: 'Role', value: user?.title ?? ''),
              DetailFieldRow(label: 'Organization', value: user?.company ?? ''),
            ],
          ),
          const SectionHeader(title: 'Session'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: ListTile(
                leading:
                    const Icon(Icons.logout, color: AppColors.errorBright),
                title: const Text(
                  'Log out',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.errorBright,
                  ),
                ),
                subtitle: const Text(
                  'Your local data stays on this device',
                  style: TextStyle(fontSize: 12.5),
                ),
                onTap: () => _confirmSignOut(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Log out?'),
        content: const Text('You can sign back in with the same credentials.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorBright,
            ),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              // Pop everything so the root gate can show the login screen.
              Navigator.of(context).popUntil((route) => route.isFirst);
              context.read<AuthProvider>().signOut();
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}
