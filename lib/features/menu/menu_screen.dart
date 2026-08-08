import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../../data/services/auth_provider.dart';
import '../accounts/accounts_screen.dart';
import '../calendar/calendar_screen.dart';
import '../contacts/contacts_screen.dart';
import '../leads/leads_screen.dart';
import '../opportunities/opportunities_screen.dart';
import '../reports/reports_screen.dart';
import '../settings/profile_screen.dart';
import '../shell/ryse_app_bar.dart';

/// Salesforce-style object navigator plus profile & app options.
class MenuScreen extends StatelessWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: buildRyseAppBar(context, title: 'Menu'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          // Profile header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                InitialsAvatar(name: user?.name ?? 'User', size: 54),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'User',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (user?.title.isNotEmpty ?? false) user!.title,
                          if (user?.company.isNotEmpty ?? false) user!.company,
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                OutlinedButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ProfileScreen(),
                    ),
                  ),
                  child: const Text('Profile'),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Records'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  _ObjectTile(
                    type: RecordType.lead,
                    count: store.leads.length,
                    onTap: () => _push(context, const LeadsScreen()),
                  ),
                  const Divider(indent: 66),
                  _ObjectTile(
                    type: RecordType.contact,
                    count: store.contacts.length,
                    onTap: () => _push(context, const ContactsScreen()),
                  ),
                  const Divider(indent: 66),
                  _ObjectTile(
                    type: RecordType.account,
                    count: store.accounts.length,
                    onTap: () => _push(context, const AccountsScreen()),
                  ),
                  const Divider(indent: 66),
                  _ObjectTile(
                    type: RecordType.opportunity,
                    count: store.opportunities.length,
                    onTap: () =>
                        _push(context, const OpportunitiesScreen()),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Insights'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.insights_outlined,
                      color: AppColors.report,
                    ),
                    title: const Text(
                      'Reports & Analytics',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Pipeline, win rate, sources, revenue',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textTertiary),
                    onTap: () => _push(context, const ReportsScreen()),
                  ),
                  const Divider(indent: 66),
                  ListTile(
                    leading: const Icon(
                      Icons.calendar_month_outlined,
                      color: AppColors.event,
                    ),
                    title: const Text(
                      'Calendar',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Agenda of tasks and meetings',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    trailing: const Icon(Icons.chevron_right,
                        size: 18, color: AppColors.textTertiary),
                    onTap: () => _push(context, const CalendarScreen()),
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader(title: 'Workspace'),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            child: Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.refresh,
                      color: AppColors.brand,
                    ),
                    title: const Text(
                      'Reset demo data',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: const Text(
                      'Restore the original sample records',
                      style: TextStyle(fontSize: 12.5),
                    ),
                    onTap: () => _confirmReset(context),
                  ),
                  const Divider(indent: 66),
                  ListTile(
                    leading: const Icon(
                      Icons.info_outline,
                      color: AppColors.brand,
                    ),
                    title: const Text(
                      'About RYSE CRM',
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onTap: () => showAboutDialog(
                      context: context,
                      applicationName: 'RYSE CRM',
                      applicationVersion: '1.0.0',
                      applicationLegalese:
                          'AI-driven sales CRM demo built with Flutter.',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  static void _confirmReset(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Reset demo data?'),
        content: const Text(
          'All your changes will be discarded and the original sample '
          'records restored.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              dialogContext.read<CrmStore>().resetDemoData();
              Navigator.of(dialogContext).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Demo data restored')),
              );
            },
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _ObjectTile extends StatelessWidget {
  const _ObjectTile({
    required this.type,
    required this.count,
    required this.onTap,
  });

  final RecordType type;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: RecordIcon(icon: type.icon, color: type.color, size: 40),
      title: Text(
        type.plural,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$count',
            style: const TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 6),
          const Icon(
            Icons.chevron_right,
            size: 18,
            color: AppColors.textTertiary,
          ),
        ],
      ),
    );
  }
}
