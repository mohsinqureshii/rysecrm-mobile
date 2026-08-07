import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../opportunities/opportunity_detail_screen.dart';
import '../shared/record_widgets.dart';
import '../shell/record_nav.dart';
import 'lead_form_screen.dart';

class LeadDetailScreen extends StatelessWidget {
  const LeadDetailScreen({super.key, required this.leadId});

  final String leadId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final lead = store.leadById(leadId);
    if (lead == null) {
      return const Scaffold(
        body: EmptyState(icon: Icons.person_off_outlined, title: 'Lead deleted'),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Lead'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LeadFormScreen(lead: lead),
                      ),
                    );
                  case 'delete':
                    _confirmDelete(context, lead);
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
            _LeadHeader(lead: lead),
            Expanded(
              child: TabBarView(
                children: [
                  _DetailsTab(lead: lead),
                  _RelatedTab(lead: lead),
                  ActivityTimeline(
                    activities:
                        store.activitiesForRecord(RecordType.lead, lead.id),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Lead lead) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete lead?'),
        content: Text('“${lead.name}” will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorBright),
            onPressed: () {
              dialogContext.read<CrmStore>().deleteLead(lead.id);
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

class _LeadHeader extends StatelessWidget {
  const _LeadHeader({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final converted = lead.status == LeadStatus.converted;
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Row(
              children: [
                InitialsAvatar(name: lead.name, size: 52),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lead.name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        [
                          if (lead.title.isNotEmpty) lead.title,
                          lead.company,
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          PillBadge(
                            label: lead.status.label,
                            color: lead.status.color,
                          ),
                          PillBadge(
                            label: lead.rating.label,
                            color: lead.rating.color,
                            icon: lead.rating == LeadRating.hot
                                ? Icons.local_fire_department
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    AiScoreBadge(score: lead.aiScore),
                    const SizedBox(height: 4),
                    const AiTag(label: 'SCORE'),
                  ],
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
                  relatedType: RecordType.lead,
                  relatedId: lead.id,
                  relatedName: lead.name,
                ),
              ),
              RecordAction(
                icon: Icons.mail_outline,
                label: 'Email',
                onTap: () => showLogInteractionSheet(
                  context,
                  relatedType: RecordType.lead,
                  relatedId: lead.id,
                  relatedName: lead.name,
                ),
              ),
              if (!converted)
                RecordAction(
                  icon: Icons.swap_horiz,
                  label: 'Convert',
                  emphasized: true,
                  onTap: () => _showConvertDialog(context, lead),
                ),
            ],
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _showConvertDialog(BuildContext context, Lead lead) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Convert lead'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Converting creates the following records, just like in '
              'Salesforce:',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 14),
            _ConvertRow(type: RecordType.contact, label: lead.name),
            const SizedBox(height: 8),
            _ConvertRow(
              type: RecordType.account,
              label: lead.company.isEmpty ? 'New account' : lead.company,
            ),
            const SizedBox(height: 8),
            _ConvertRow(
              type: RecordType.opportunity,
              label: '${lead.company.isEmpty ? lead.name : lead.company}'
                  ' — New Business',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final store = dialogContext.read<CrmStore>();
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              Navigator.of(dialogContext).pop();
              final result = await store.convertLead(lead);
              if (result == null) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      store.lastError ?? 'Could not convert this lead.',
                    ),
                  ),
                );
                return;
              }
              messenger.showSnackBar(
                SnackBar(
                  content:
                      Text('${lead.name} converted — opening opportunity'),
                ),
              );
              navigator.pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => OpportunityDetailScreen(
                    opportunityId: result.opportunity.id,
                  ),
                ),
              );
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }
}

class _ConvertRow extends StatelessWidget {
  const _ConvertRow({required this.type, required this.label});

  final RecordType type;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RecordIcon(icon: type.icon, color: type.color, size: 28),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 14, bottom: 96),
      children: [
        FieldCard(
          children: [
            DetailFieldRow(label: 'Name', value: lead.name),
            DetailFieldRow(label: 'Company', value: lead.company),
            DetailFieldRow(label: 'Title', value: lead.title),
            DetailFieldRow(label: 'Email', value: lead.email),
            DetailFieldRow(label: 'Phone', value: lead.phone),
          ],
        ),
        const SectionHeader(title: 'Qualification'),
        FieldCard(
          children: [
            DetailFieldRow(label: 'Status', value: lead.status.label),
            DetailFieldRow(label: 'Rating', value: lead.rating.label),
            DetailFieldRow(label: 'Lead Source', value: lead.source),
            DetailFieldRow(label: 'Industry', value: lead.industry),
            DetailFieldRow(
              label: 'Annual Revenue',
              value: lead.annualRevenue > 0
                  ? Formatters.currency(lead.annualRevenue)
                  : '',
            ),
          ],
        ),
        const SectionHeader(title: 'Location & Ownership'),
        FieldCard(
          children: [
            DetailFieldRow(
              label: 'Location',
              value: [
                if (lead.city.isNotEmpty) lead.city,
                if (lead.country.isNotEmpty) lead.country,
              ].join(', '),
            ),
            DetailFieldRow(label: 'Lead Owner', value: lead.ownerName),
            DetailFieldRow(
              label: 'Created',
              value: Formatters.date(lead.createdAt),
            ),
            DetailFieldRow(
              label: 'Last Updated',
              value: Formatters.relative(lead.updatedAt),
            ),
          ],
        ),
        if (lead.notes.isNotEmpty) ...[
          const SectionHeader(title: 'Notes'),
          FieldCard(
            children: [DetailFieldRow(label: 'Notes', value: lead.notes)],
          ),
        ],
      ],
    );
  }
}

class _RelatedTab extends StatelessWidget {
  const _RelatedTab({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final tasks = store.tasksForRecord(RecordType.lead, lead.id);
    if (tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.link,
        title: 'Nothing related yet',
        message: 'Tasks tied to this lead will show up here.',
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: [
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
                trailing: task.completed
                    ? const Icon(Icons.check_circle, color: AppColors.success)
                    : null,
              ),
            ),
          ),
      ],
    );
  }
}
