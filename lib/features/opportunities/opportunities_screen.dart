import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import 'opportunity_detail_screen.dart';
import 'opportunity_form_screen.dart';

enum _OppFilter { open, closingSoon, won, lost, all }

class OpportunitiesScreen extends StatefulWidget {
  const OpportunitiesScreen({super.key});

  @override
  State<OpportunitiesScreen> createState() => _OpportunitiesScreenState();
}

class _OpportunitiesScreenState extends State<OpportunitiesScreen> {
  String _query = '';
  _OppFilter _filter = _OppFilter.open;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final now = DateTime.now();
    final opportunities = store.opportunities.where((opp) {
      final matchesFilter = switch (_filter) {
        _OppFilter.open => opp.stage.isOpen,
        _OppFilter.closingSoon => opp.stage.isOpen &&
            opp.closeDate.difference(now).inDays <= 14,
        _OppFilter.won => opp.stage == OpportunityStage.closedWon,
        _OppFilter.lost => opp.stage == OpportunityStage.closedLost,
        _OppFilter.all => true,
      };
      if (!matchesFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final account = store.accountById(opp.accountId)?.name ?? '';
      return opp.name.toLowerCase().contains(q) ||
          account.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.closeDate.compareTo(b.closeDate));

    final totalValue =
        opportunities.fold<double>(0, (sum, o) => sum + o.amount);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RecordIcon(
              icon: RecordType.opportunity.icon,
              color: RecordType.opportunity.color,
              size: 30,
            ),
            const SizedBox(width: 10),
            Text('Opportunities (${opportunities.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'new-opp',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const OpportunityFormScreen(),
          ),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: ListSearchField(
              hint: 'Search opportunities…',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                for (final (filter, label) in const [
                  (_OppFilter.open, 'Open'),
                  (_OppFilter.closingSoon, 'Closing soon'),
                  (_OppFilter.won, 'Won'),
                  (_OppFilter.lost, 'Lost'),
                  (_OppFilter.all, 'All'),
                ]) ...[
                  AppFilterChip(
                    label: label,
                    selected: _filter == filter,
                    onSelected: (_) => setState(() => _filter = filter),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Total: ${Formatters.currency(totalValue)}',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: opportunities.isEmpty
                ? const EmptyState(
                    icon: Icons.emoji_events_outlined,
                    title: 'No opportunities found',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: opportunities.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) => _OpportunityCard(
                      opportunity: opportunities[index],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  const _OpportunityCard({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final account = store.accountById(opportunity.accountId);
    final stage = opportunity.stage;
    final stageColor = stage == OpportunityStage.closedWon
        ? AppColors.success
        : stage == OpportunityStage.closedLost
            ? AppColors.errorBright
            : AppColors.brand;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => OpportunityDetailScreen(
              opportunityId: opportunity.id,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  RecordIcon(
                    icon: RecordType.opportunity.icon,
                    color: RecordType.opportunity.color,
                    size: 40,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          opportunity.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            height: 1.25,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        if (account != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            account.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AiScoreBadge(score: opportunity.aiScore, size: 38),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  PillBadge(label: stage.label, color: stageColor),
                  const SizedBox(width: 8),
                  Text(
                    Formatters.compactCurrency(opportunity.amount),
                    style: const TextStyle(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.event_outlined,
                    size: 14,
                    color: AppColors.textTertiary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    Formatters.dateShort(opportunity.closeDate),
                    style: const TextStyle(
                      fontSize: 12.5,
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
