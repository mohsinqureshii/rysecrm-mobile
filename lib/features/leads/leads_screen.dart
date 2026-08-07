import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import 'lead_detail_screen.dart';
import 'lead_form_screen.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  String _query = '';
  LeadStatus? _statusFilter;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    var leads = store.leads.where((lead) {
      if (_statusFilter != null && lead.status != _statusFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return lead.name.toLowerCase().contains(q) ||
          lead.company.toLowerCase().contains(q) ||
          lead.email.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => b.aiScore.compareTo(a.aiScore));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RecordIcon(
              icon: RecordType.lead.icon,
              color: RecordType.lead.color,
              size: 30,
            ),
            const SizedBox(width: 10),
            Text('Leads (${leads.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'new-lead',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const LeadFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: ListSearchField(
              hint: 'Search leads…',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: _statusFilter == null,
                  onSelected: (_) => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 8),
                for (final status in LeadStatus.values) ...[
                  FilterChip(
                    label: Text(status.label),
                    selected: _statusFilter == status,
                    onSelected: (_) => setState(
                      () => _statusFilter =
                          _statusFilter == status ? null : status,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: leads.isEmpty
                ? EmptyState(
                    icon: RecordType.lead.icon,
                    title: 'No leads found',
                    message: _query.isEmpty && _statusFilter == null
                        ? 'Create your first lead to start filling the funnel.'
                        : 'Try a different search or filter.',
                    actionLabel:
                        _query.isEmpty && _statusFilter == null ? 'New Lead' : null,
                    onAction: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const LeadFormScreen(),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: leads.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) =>
                        _LeadCard(lead: leads[index]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _LeadCard extends StatelessWidget {
  const _LeadCard({required this.lead});

  final Lead lead;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => LeadDetailScreen(leadId: lead.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              InitialsAvatar(name: lead.name, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lead.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [
                        if (lead.title.isNotEmpty) lead.title,
                        lead.company,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        PillBadge(
                          label: lead.status.label,
                          color: lead.status.color,
                        ),
                        const SizedBox(width: 6),
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
                  AiScoreBadge(score: lead.aiScore, size: 40),
                  const SizedBox(height: 3),
                  const Text(
                    'AI score',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
