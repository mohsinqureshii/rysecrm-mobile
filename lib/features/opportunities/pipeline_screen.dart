import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../shell/ryse_app_bar.dart';
import 'opportunities_screen.dart';
import 'opportunity_detail_screen.dart';
import 'stage_picker.dart';

/// Kanban view of open opportunities by stage. Cards can be dragged
/// between columns or moved with the stage picker.
class PipelineScreen extends StatelessWidget {
  const PipelineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final byStage = store.pipelineByStage;

    return Scaffold(
      appBar: buildRyseAppBar(
        context,
        title: 'Pipeline',
        extraActions: [
          IconButton(
            tooltip: 'All opportunities',
            icon: const Icon(Icons.view_list_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const OpportunitiesScreen(),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PipelineSummary(store: store),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              children: [
                for (final entry in byStage.entries)
                  _StageColumn(stage: entry.key, opportunities: entry.value),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineSummary extends StatelessWidget {
  const _PipelineSummary({required this.store});

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SummaryItem(
              label: 'Open Pipeline',
              value: Formatters.compactCurrency(store.pipelineValue),
            ),
          ),
          Container(width: 1, height: 34, color: AppColors.border),
          Expanded(
            child: _SummaryItem(
              label: 'Weighted',
              value: Formatters.compactCurrency(store.weightedPipelineValue),
            ),
          ),
          Container(width: 1, height: 34, color: AppColors.border),
          Expanded(
            child: _SummaryItem(
              label: 'Open Deals',
              value: '${store.openOpportunities.length}',
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  const _SummaryItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 11.5,
          ),
        ),
      ],
    );
  }
}

class _StageColumn extends StatelessWidget {
  const _StageColumn({required this.stage, required this.opportunities});

  final OpportunityStage stage;
  final List<Opportunity> opportunities;

  @override
  Widget build(BuildContext context) {
    final total =
        opportunities.fold<double>(0, (sum, o) => sum + o.amount);
    return DragTarget<Opportunity>(
      onWillAcceptWithDetails: (details) => details.data.stage != stage,
      onAcceptWithDetails: (details) {
        context.read<CrmStore>().setOpportunityStage(details.data, stage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${details.data.name} → ${stage.label}'),
          ),
        );
      },
      builder: (context, candidates, _) {
        final highlighted = candidates.isNotEmpty;
        return Container(
          width: 270,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: highlighted ? AppColors.cloud : AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: highlighted ? AppColors.brand : AppColors.border,
              width: highlighted ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        stage.label.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '${opportunities.length} · ${Formatters.compactCurrency(total)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: opportunities.isEmpty
                    ? Center(
                        child: Text(
                          highlighted ? 'Drop here' : 'No deals',
                          style: const TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(10, 2, 10, 12),
                        itemCount: opportunities.length,
                        separatorBuilder: (_, _) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, index) => _KanbanCard(
                          opportunity: opportunities[index],
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KanbanCard extends StatelessWidget {
  const _KanbanCard({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final card = _CardBody(opportunity: opportunity);
    return LongPressDraggable<Opportunity>(
      data: opportunity,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 250,
          child: Opacity(opacity: 0.92, child: card),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.35, child: card),
      child: card,
    );
  }
}

class _CardBody extends StatelessWidget {
  const _CardBody({required this.opportunity});

  final Opportunity opportunity;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final account = store.accountById(opportunity.accountId);
    final overdue = Formatters.isOverdue(opportunity.closeDate);

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
                  Expanded(
                    child: Text(
                      opportunity.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.25,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: () => showStagePicker(context, opportunity),
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.swap_vert,
                        size: 18,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ),
                ],
              ),
              if (account != null) ...[
                const SizedBox(height: 3),
                Text(
                  account.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    Formatters.compactCurrency(opportunity.amount),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.event_outlined,
                    size: 13,
                    color: overdue
                        ? AppColors.errorBright
                        : AppColors.textTertiary,
                  ),
                  const SizedBox(width: 3),
                  Text(
                    Formatters.dateShort(opportunity.closeDate),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight:
                          overdue ? FontWeight.w700 : FontWeight.w500,
                      color: overdue
                          ? AppColors.errorBright
                          : AppColors.textTertiary,
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
