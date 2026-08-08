import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../shared/record_widgets.dart';
import '../shell/record_nav.dart';
import 'contact_form_screen.dart';

class ContactDetailScreen extends StatelessWidget {
  const ContactDetailScreen({super.key, required this.contactId});

  final String contactId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final contact = store.contactById(contactId);
    if (contact == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.person_off_outlined,
          title: 'Contact deleted',
        ),
      );
    }
    final account = store.accountById(contact.accountId);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Contact'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ContactFormScreen(contact: contact),
                      ),
                    );
                  case 'delete':
                    _confirmDelete(context, contact);
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
            Container(
              color: AppColors.surface,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        InitialsAvatar(name: contact.name, size: 52),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                contact.name,
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                [
                                  if (contact.title.isNotEmpty) contact.title,
                                  if (account != null) account.name,
                                ].join(' · '),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  color: AppColors.textSecondary,
                                ),
                              ),
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
                          relatedType: RecordType.contact,
                          relatedId: contact.id,
                          relatedName: contact.name,
                        ),
                      ),
                      RecordAction(
                        icon: Icons.mail_outline,
                        label: 'Email',
                        onTap: () => showLogInteractionSheet(
                          context,
                          relatedType: RecordType.contact,
                          relatedId: contact.id,
                          relatedName: contact.name,
                        ),
                      ),
                      RecordAction(
                        icon: Icons.edit_outlined,
                        label: 'Edit',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                ContactFormScreen(contact: contact),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  ListView(
                    padding: const EdgeInsets.only(top: 14, bottom: 96),
                    children: [
                      FieldCard(
                        children: [
                          DetailFieldRow(label: 'Name', value: contact.name),
                          DetailFieldRow(
                            label: 'Account',
                            value: account?.name ?? '',
                            onTap: account == null
                                ? null
                                : () => openRecord(
                                      context,
                                      RecordType.account,
                                      account.id,
                                    ),
                          ),
                          DetailFieldRow(label: 'Title', value: contact.title),
                          DetailFieldRow(
                            label: 'Department',
                            value: contact.department,
                          ),
                        ],
                      ),
                      const SectionHeader(title: 'Contact Info'),
                      FieldCard(
                        children: [
                          DetailFieldRow(label: 'Email', value: contact.email),
                          DetailFieldRow(label: 'Phone', value: contact.phone),
                          DetailFieldRow(
                            label: 'Mobile',
                            value: contact.mobile,
                          ),
                        ],
                      ),
                      const SectionHeader(title: 'Ownership'),
                      FieldCard(
                        children: [
                          DetailFieldRow(
                            label: 'Contact Owner',
                            value: contact.ownerName,
                          ),
                          DetailFieldRow(
                            label: 'Created',
                            value: Formatters.date(contact.createdAt),
                          ),
                        ],
                      ),
                      if (contact.notes.isNotEmpty) ...[
                        const SectionHeader(title: 'Notes'),
                        FieldCard(
                          children: [
                            DetailFieldRow(
                              label: 'Notes',
                              value: contact.notes,
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  _RelatedTab(contact: contact),
                  ActivityTimeline(
                    activities: store.activitiesForRecord(
                      RecordType.contact,
                      contact.id,
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

  void _confirmDelete(BuildContext context, Contact contact) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete contact?'),
        content: Text('“${contact.name}” will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorBright),
            onPressed: () {
              dialogContext.read<CrmStore>().deleteContact(contact.id);
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

class _RelatedTab extends StatelessWidget {
  const _RelatedTab({required this.contact});

  final Contact contact;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final opportunities = store.opportunitiesForContact(contact.id);
    final tasks = store.tasksForRecord(RecordType.contact, contact.id);

    if (opportunities.isEmpty && tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.link,
        title: 'Nothing related yet',
        message: 'Opportunities and tasks tied to this contact appear here.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: [
        if (opportunities.isNotEmpty) ...[
          const SectionHeader(
            title: 'Opportunities',
            padding: EdgeInsets.only(bottom: 10),
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
        if (tasks.isNotEmpty) ...[
          const SectionHeader(
            title: 'Tasks',
            padding: EdgeInsets.only(top: 8, bottom: 10),
          ),
          for (final task in tasks)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Card(
                child: ListTile(
                  onTap: () => openRecord(context, RecordType.task, task.id),
                  leading: Icon(task.type.icon, color: AppColors.task),
                  title: Text(
                    task.subject,
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(Formatters.dueLabel(task.dueDate)),
                ),
              ),
            ),
        ],
      ],
    );
  }
}
