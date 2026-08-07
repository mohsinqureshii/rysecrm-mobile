import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../shared/record_widgets.dart';
import '../shell/record_nav.dart';
import 'opportunity_form_screen.dart';
import 'stage_path.dart';
import 'stage_picker.dart';

class OpportunityDetailScreen extends StatelessWidget {
  const OpportunityDetailScreen({super.key, required this.opportunityId});

  final String opportunityId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final opportunity = store.opportunityById(opportunityId);
    if (opportunity == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.emoji_events_outlined,
          title: 'Opportunity deleted',
        ),
      );
    }

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Opportunity'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) =>
                            OpportunityFormScreen(opportunity: opportunity),
                      ),
                    );
                  case 'stage':
                    showStagePicker(context, opportunity);
                  case 'delete':
                    _confirmDelete(context, opportunity);
                }
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(value: 'stage', child: Text('Change stage')),
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
            _OpportunityHeader(opportunity: opportunity),
            Expanded(
              child: TabBarView(
                children: [
                  _DetailsTab(opportunity: opportunity),
                  _RelatedTab(opportunity: opportunity),
                  ActivityTimeline(
                    activities: store.activitiesForRecord(
                      RecordType.opportunity,
                      opportunity.id,
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

  void _confirmDelete(BuildContext context, Opportunity opportunity) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete opportunity?'),
        content: Text('“${opportunity.name}” will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorBright),
            onPressed: () {
              dialogContext.read<CrmStore>().deleteOpportunity(opportunity.id);
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

class _OpportunityHeader extends StatelessWidget {
  const _OpportunityHeader({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final account = store.accountById(opportunity.accountId);
    final stage = opportunity.stage;

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                RecordIcon(
                  icon: RecordType.opportunity.icon,
                  color: RecordType.opportunity.color,
                  size: 52,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        opportunity.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        [
                          if (account != null) account.name,
                          Formatters.currency(opportunity.amount),
                        ].join(' · '),
                        style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  children: [
                    AiScoreBadge(score: opportunity.aiScore),
                    const SizedBox(height: 4),
                    const AiTag(label: 'SCORE'),
                  ],
                ),
              ],
            ),
          ),
          // Salesforce-style sales path.
          StagePath(
            currentStage: stage,
            onStageSelected: (selected) {
              if (selected != stage) {
                store.setOpportunityStage(opportunity, selected);
              }
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: stage.isOpen
                      ? ElevatedButton.icon(
                          onPressed: () => _advanceStage(context, store),
                          icon: const Icon(Icons.check, size: 18),
                          label: Text(
                            stage == OpportunityStage.negotiation
                                ? 'Close Won'
                                : 'Mark Stage Complete',
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.symmetric(vertical: 11),
                          decoration: BoxDecoration(
                            color: stage == OpportunityStage.closedWon
                                ? AppColors.successLight
                                : AppColors.errorLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            stage == OpportunityStage.closedWon
                                ? '🏆 Closed Won'
                                : 'Closed Lost',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: stage == OpportunityStage.closedWon
                                  ? AppColors.success
                                  : AppColors.error,
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () =>
                      showLogInteractionSheet(
                        context,
                        relatedType: RecordType.opportunity,
                        relatedId: opportunity.id,
                        relatedName: opportunity.name,
                      ),
                  child: const Icon(Icons.add_ic_call_outlined, size: 20),
                ),
              ],
            ),
          ),
          const Divider(),
        ],
      ),
    );
  }

  void _advanceStage(BuildContext context, CrmStore store) {
    final stages = OpportunityStage.pathStages;
    final index = stages.indexOf(opportunity.stage);
    if (index == -1 || index >= stages.length - 1) return;
    final next = stages[index + 1];
    store.setOpportunityStage(opportunity, next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          next == OpportunityStage.closedWon
              ? '🎉 ${opportunity.name} closed won!'
              : 'Moved to ${next.label}',
        ),
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  const _DetailsTab({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final account = store.accountById(opportunity.accountId);
    final contact = store.contactById(opportunity.contactId);

    return ListView(
      padding: const EdgeInsets.only(top: 14, bottom: 96),
      children: [
        FieldCard(
          children: [
            DetailFieldRow(label: 'Opportunity Name', value: opportunity.name),
            DetailFieldRow(
              label: 'Account',
              value: account?.name ?? '',
              onTap: account == null
                  ? null
                  : () =>
                      openRecord(context, RecordType.account, account.id),
            ),
            DetailFieldRow(
              label: 'Primary Contact',
              value: contact?.name ?? '',
              onTap: contact == null
                  ? null
                  : () =>
                      openRecord(context, RecordType.contact, contact.id),
            ),
          ],
        ),
        const SectionHeader(title: 'Forecast'),
        FieldCard(
          children: [
            DetailFieldRow(
              label: 'Amount',
              value: Formatters.currency(opportunity.amount),
            ),
            DetailFieldRow(label: 'Stage', value: opportunity.stage.label),
            DetailFieldRow(
              label: 'Probability',
              value:
                  '${(opportunity.probability * 100).toStringAsFixed(0)}%',
            ),
            DetailFieldRow(
              label: 'Expected Revenue',
              value: Formatters.currency(opportunity.expectedRevenue),
            ),
            DetailFieldRow(
              label: 'Close Date',
              value: Formatters.date(opportunity.closeDate),
              valueColor: opportunity.stage.isOpen &&
                      Formatters.isOverdue(opportunity.closeDate)
                  ? AppColors.errorBright
                  : null,
            ),
          ],
        ),
        const SectionHeader(title: 'Sales Info'),
        FieldCard(
          children: [
            DetailFieldRow(label: 'Next Step', value: opportunity.nextStep),
            DetailFieldRow(label: 'Source', value: opportunity.source),
            DetailFieldRow(label: 'Owner', value: opportunity.ownerName),
            DetailFieldRow(
              label: 'Created',
              value: Formatters.date(opportunity.createdAt),
            ),
            DetailFieldRow(
              label: 'Last Updated',
              value: Formatters.relative(opportunity.updatedAt),
            ),
          ],
        ),
        if (opportunity.notes.isNotEmpty) ...[
          const SectionHeader(title: 'Notes'),
          FieldCard(
            children: [
              DetailFieldRow(label: 'Notes', value: opportunity.notes),
            ],
          ),
        ],
      ],
    );
  }
}

class _RelatedTab extends StatelessWidget {
  const _RelatedTab({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final tasks = store.tasksForRecord(RecordType.opportunity, opportunity.id);
    if (tasks.isEmpty) {
      return const EmptyState(
        icon: Icons.link,
        title: 'Nothing related yet',
        message: 'Tasks tied to this opportunity will show up here.',
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
