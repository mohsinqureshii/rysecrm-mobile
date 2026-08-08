import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../contacts/contact_form_screen.dart';
import '../opportunities/opportunity_form_screen.dart';
import '../shared/record_widgets.dart';
import '../shell/record_nav.dart';
import 'account_form_screen.dart';

class AccountDetailScreen extends StatelessWidget {
  const AccountDetailScreen({super.key, required this.accountId});

  final String accountId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final account = store.accountById(accountId);
    if (account == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.domain_disabled_outlined,
          title: 'Account deleted',
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Account'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => AccountFormScreen(account: account),
                      ),
                    );
                  case 'delete':
                    _confirmDelete(context, account);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Details'),
              Tab(text: 'Related'),
              Tab(text: 'Activity'),
            ],
          ),
        ),
        body: Column(
          children: [
            _AccountHeader(account: account),
            Expanded(
              child: TabBarView(
                children: [
                  _DetailsTab(account: account),
                  _RelatedTab(account: account),
                  ActivityTimeline(
                    activities: store.activitiesForRecord(
                      RecordType.account,
                      account.id,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Account account) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete account?'),
        content: Text('“${account.name}” will be permanently removed. '
            'Related contacts and opportunities are kept.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorBright),
            onPressed: () {
              dialogContext.read<CrmStore>().deleteAccount(account.id);
              Navigator.of(dialogContext).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final openValue = store
        .opportunitiesForAccount(account.id)
        .where((o) => o.stage.isOpen)
        .fold<double>(0, (s, o) => s + o.amount);

    return Container(
      color: AppColors.surface,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                RecordIcon(
                  icon: RecordType.account.icon,
                  color: RecordType.account.color,
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (account.industry.isNotEmpty) account.industry,
                          account.type,
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      if (openValue > 0) ...[
                        const SizedBox(height: 6),
                        PillBadge(
                          label:
                              '${Formatters.compactCurrency(openValue)} open pipeline',
                          color: AppColors.brand,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          RecordActionBar(
            actions: [
              RecordAction(
                icon: Icons.phone_outlined,
                label: 'Log Call',
                onTap: () => showLogInteractionSheet(
                  context,
                  relatedType: RecordType.account,
                  relatedId: account.id,
                  relatedName: account.name,
                ),
              ),
              RecordAction(
                icon: Icons.person_add_alt_outlined,
                label: 'Contact',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        ContactFormScreen(initialAccountId: account.id),
                  ),
                ),
              ),
              RecordAction(
                icon: Icons.emoji_events_outlined,
                label: 'Deal',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) =>
                        OpportunityFormScreen(initialAccountId: account.id),
                  ),
                ),
              ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 14, bottom: 96),
      children: [
        FieldCard(
          children: [
            DetailFieldRow(label: 'Account Name', value: account.name),
            DetailFieldRow(label: 'Type', value: account.type),
            DetailFieldRow(label: 'Industry', value: account.industry),
            DetailFieldRow(label: 'Website', value: account.website),
            DetailFieldRow(label: 'Phone', value: account.phone),
          ],
        ),
        const SectionHeader(title: 'Company Profile'),
        FieldCard(
          children: [
            DetailFieldRow(
              label: 'Employees',
              value: account.employees > 0 ? '${account.employees}' : '',
            ),
            DetailFieldRow(
              label: 'Annual Revenue',
              value: account.annualRevenue > 0
                  ? Formatters.currency(account.annualRevenue)
                  : '',
            ),
            DetailFieldRow(
              label: 'Billing Location',
              value: [
                if (account.billingCity.isNotEmpty) account.billingCity,
                if (account.billingCountry.isNotEmpty) account.billingCountry,
              ].join(', '),
            ),
          ],
        ),
        const SectionHeader(title: 'Ownership'),
        FieldCard(
          children: [
            DetailFieldRow(label: 'Account Owner', value: account.ownerName),
            DetailFieldRow(
              label: 'Created',
              value: Formatters.date(account.createdAt),
            ),
            DetailFieldRow(
              label: 'Last Updated',
              value: Formatters.relative(account.updatedAt),
            ),
          ],
        ),
        if (account.notes.isNotEmpty) ...[
          const SectionHeader(title: 'Notes'),
          FieldCard(
            children: [DetailFieldRow(label: 'Notes', value: account.notes)],
          ),
        ],
      ],
    );
  }
}

class _RelatedTab extends StatelessWidget {
  const _RelatedTab({required this.account});

  final Account account;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final contacts = store.contactsForAccount(account.id);
    final opportunities = store.opportunitiesForAccount(account.id);

    if (contacts.isEmpty && opportunities.isEmpty) {
      return const EmptyState(
        icon: Icons.link,
        title: 'Nothing related yet',
        message: 'Contacts and opportunities at this account appear here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: [
        if (opportunities.isNotEmpty) ...[
          SectionHeader(
            title: 'Opportunities (${opportunities.length})',
            padding: const EdgeInsets.only(bottom: 10),
          ),
          for (final opp in opportunities)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  onTap: () =>
                      openRecord(context, RecordType.opportunity, opp.id),
                  leading: RecordIcon(
                    icon: RecordType.opportunity.icon,
                    color: RecordType.opportunity.color,
                    size: 38,
                  ),
                  title: Text(
                    opp.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${opp.stage.label} · ${Formatters.compactCurrency(opp.amount)}',
                  ),
                ),
              ),
            ),
        ],
        if (contacts.isNotEmpty) ...[
          SectionHeader(
            title: 'Contacts (${contacts.length})',
            padding: const EdgeInsets.only(top: 8, bottom: 10),
          ),
          for (final contact in contacts)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  onTap: () =>
                      openRecord(context, RecordType.contact, contact.id),
                  leading: InitialsAvatar(name: contact.name, size: 40),
                  title: Text(
                    contact.name,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    contact.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
