import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../../data/services/auth_provider.dart';
import '../leads/lead_capture_screen.dart';
import '../leads/leads_screen.dart';
import '../opportunities/opportunities_screen.dart';
import '../opportunities/opportunity_form_screen.dart';
import '../tasks/task_form_screen.dart';
import '../shell/record_nav.dart';
import '../shell/ryse_app_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final user = context.watch<AuthProvider>().user;

    if (!store.isLoaded) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: buildRyseAppBar(context, title: 'RYSE', showLogo: true),
      body: RefreshIndicator(
        onRefresh: () =>
            Future<void>.delayed(const Duration(milliseconds: 600)),
        child: ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [
            _GreetingHeader(userName: user?.name ?? 'there'),
            const _QuickActions(),
            _KpiGrid(store: store),
            const SectionHeader(title: 'RYSE AI Insights'),
            _AiInsightsCarousel(store: store),
            SectionHeader(
              title: 'Pipeline by Stage',
              actionLabel: 'View all',
              onAction: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const OpportunitiesScreen(),
                ),
              ),
            ),
            _PipelineChartCard(store: store),
            SectionHeader(
              title: "Today's Tasks",
              actionLabel: store.tasksDueToday.isEmpty ? null : 'See tasks',
            ),
            _TodayTasks(store: store),
            const SectionHeader(title: 'Recent Activity'),
            _ActivityFeed(store: store),
          ],
        ),
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader({required this.userName});

  final String userName;

  String get _greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = userName.split(' ').first;
    return Container(
      color: AppColors.header,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            Formatters.date(DateTime.now()).toUpperCase(),
            style: const TextStyle(
              color: AppColors.textTertiary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$_greeting, $firstName',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
        ],
      ),
    );
  }
}

/// Home quick actions — the prominent "Capture Lead" plus fast create paths.
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  void _push(BuildContext context, Widget screen) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Column(
        children: [
          // Primary: capture a lead.
          Material(
            color: AppColors.ink,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _push(context, const LeadCaptureScreen()),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.person_add_alt_1,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Capture Lead',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Add a new lead in seconds',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward,
                        color: Colors.white, size: 20),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _QuickChip(
                icon: Icons.handshake_outlined,
                label: 'New Deal',
                color: AppColors.opportunity,
                onTap: () => _push(context, const OpportunityFormScreen()),
              ),
              const SizedBox(width: 12),
              _QuickChip(
                icon: Icons.add_task,
                label: 'Add Task',
                color: AppColors.task,
                onTap: () => _push(context, const TaskFormScreen()),
              ),
              const SizedBox(width: 12),
              _QuickChip(
                icon: Icons.people_alt_outlined,
                label: 'Leads',
                color: AppColors.lead,
                onTap: () => _push(context, const LeadsScreen()),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickChip extends StatelessWidget {
  const _QuickChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.store});

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    final dueToday = store.tasksDueToday.length;
    final overdue = store.overdueTasks.length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  label: 'Open Pipeline',
                  value: Formatters.compactCurrency(store.pipelineValue),
                  caption: '${store.openOpportunities.length} open deals',
                  icon: Icons.filter_alt_outlined,
                  color: AppColors.brand,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const OpportunitiesScreen(),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  label: 'Won This Quarter',
                  value: Formatters.compactCurrency(store.wonValueThisQuarter),
                  caption:
                      'Win rate ${(store.winRate * 100).toStringAsFixed(0)}%',
                  icon: Icons.emoji_events_outlined,
                  color: AppColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: KpiCard(
                  label: 'Tasks Due Today',
                  value: '$dueToday',
                  caption: overdue > 0 ? '$overdue overdue' : 'None overdue',
                  icon: Icons.task_alt,
                  color: overdue > 0 ? AppColors.errorBright : AppColors.task,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: KpiCard(
                  label: 'Hot Leads',
                  value: '${store.hotLeadCount}',
                  caption: '${store.leads.length} total leads',
                  icon: Icons.local_fire_department_outlined,
                  color: AppColors.lead,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const LeadsScreen(),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AiInsight {
  const _AiInsight({
    required this.icon,
    required this.title,
    required this.body,
    this.recordType,
    this.recordId,
  });

  final IconData icon;
  final String title;
  final String body;
  final RecordType? recordType;
  final String? recordId;
}

class _AiInsightsCarousel extends StatelessWidget {
  const _AiInsightsCarousel({required this.store});

  final CrmStore store;

  List<_AiInsight> _buildInsights() {
    final insights = <_AiInsight>[];

    // Deal at risk: open deal with lowest AI score.
    final open = [...store.openOpportunities]
      ..sort((a, b) => a.aiScore.compareTo(b.aiScore));
    if (open.isNotEmpty) {
      final risk = open.first;
      insights.add(_AiInsight(
        icon: Icons.warning_amber_outlined,
        title: 'Deal needs attention',
        body: '${risk.name} is scored ${risk.aiScore}/100. '
            'Re-engage before the ${Formatters.dateShort(risk.closeDate)} '
            'close date.',
        recordType: RecordType.opportunity,
        recordId: risk.id,
      ));
    }

    // Best deal to push: highest score closing soonest.
    final winnable = [...store.openOpportunities]
      ..sort((a, b) => b.aiScore.compareTo(a.aiScore));
    if (winnable.isNotEmpty) {
      final best = winnable.first;
      insights.add(_AiInsight(
        icon: Icons.trending_up,
        title: 'Most likely to close',
        body: '${best.name} (${Formatters.compactCurrency(best.amount)}) has '
            'a ${best.aiScore}/100 score. ${best.nextStep.isEmpty ? '' : 'Next: ${best.nextStep}.'}',
        recordType: RecordType.opportunity,
        recordId: best.id,
      ));
    }

    // Hottest unworked lead.
    final hotLeads = store.leads
        .where((l) =>
            l.status != LeadStatus.converted &&
            l.status != LeadStatus.unqualified)
        .toList()
      ..sort((a, b) => b.aiScore.compareTo(a.aiScore));
    if (hotLeads.isNotEmpty) {
      final lead = hotLeads.first;
      insights.add(_AiInsight(
        icon: Icons.local_fire_department_outlined,
        title: 'Top-scored lead',
        body: '${lead.name} at ${lead.company} scored ${lead.aiScore}/100 — '
            'reach out while the interest is fresh.',
        recordType: RecordType.lead,
        recordId: lead.id,
      ));
    }

    if (store.overdueTasks.isNotEmpty) {
      insights.add(_AiInsight(
        icon: Icons.schedule_outlined,
        title: 'Overdue follow-ups',
        body: 'You have ${store.overdueTasks.length} overdue '
            'task${store.overdueTasks.length == 1 ? '' : 's'}. Clearing them '
            'keeps deals moving.',
      ));
    }
    return insights;
  }

  @override
  Widget build(BuildContext context) {
    final insights = _buildInsights();
    if (insights.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: insights.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final insight = insights[index];
          return SizedBox(
            width: 290,
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.aiGradient.first.withValues(alpha: 0.08),
                    AppColors.aiGradient.last.withValues(alpha: 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.ai.withValues(alpha: 0.25),
                ),
              ),
              child: InkWell(
                onTap: insight.recordType != null && insight.recordId != null
                    ? () => openRecord(
                          context,
                          insight.recordType!,
                          insight.recordId!,
                        )
                    : null,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(insight.icon, size: 18, color: AppColors.ai),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            insight.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const AiTag(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Text(
                        insight.body,
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          height: 1.35,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PipelineChartCard extends StatelessWidget {
  const _PipelineChartCard({required this.store});

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    final byStage = store.pipelineByStage;
    final stages = byStage.keys.toList();
    final maxValue = byStage.values
        .map((opps) => opps.fold<double>(0, (s, o) => s + o.amount))
        .fold<double>(0, (a, b) => a > b ? a : b);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 20, 16, 8),
          child: SizedBox(
            height: 200,
            child: maxValue == 0
                ? const Center(
                    child: Text(
                      'No open pipeline yet',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  )
                : BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxValue * 1.2,
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipColor: (_) => AppColors.surfaceAlt,
                          getTooltipItem: (group, _, rod, _) =>
                              BarTooltipItem(
                            Formatters.compactCurrency(rod.toY),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(),
                        topTitles: const AxisTitles(),
                        rightTitles: const AxisTitles(),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 34,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index < 0 || index >= stages.length) {
                                return const SizedBox.shrink();
                              }
                              final label = stages[index]
                                  .label
                                  .split(' ')
                                  .first;
                              return Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: AppColors.border,
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: [
                        for (var i = 0; i < stages.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: byStage[stages[i]]!.fold<double>(
                                  0,
                                  (s, o) => s + o.amount,
                                ),
                                width: 22,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(5),
                                ),
                                color: AppColors
                                    .chartPalette[i % AppColors.chartPalette.length],
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _TodayTasks extends StatelessWidget {
  const _TodayTasks({required this.store});

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    final tasks = [...store.overdueTasks, ...store.tasksDueToday];
    if (tasks.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Icon(Icons.celebration_outlined,
                    color: AppColors.success),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "You're all caught up — no tasks due today.",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary.withValues(alpha: 0.9),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(
          children: [
            for (var i = 0; i < tasks.length; i++) ...[
              if (i > 0) const Divider(indent: 56),
              _TaskRow(task: tasks[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  const _TaskRow({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final store = context.read<CrmStore>();
    final overdue = Formatters.isOverdue(task.dueDate);
    return ListTile(
      onTap: () => openRecord(context, RecordType.task, task.id),
      leading: Checkbox(
        value: task.completed,
        shape: const CircleBorder(),
        onChanged: (_) => store.toggleTask(task),
      ),
      title: Text(
        task.subject,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        [
          Formatters.dueLabel(task.dueDate),
          if (task.relatedName.isNotEmpty) task.relatedName,
        ].join(' · '),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12.5,
          color: overdue ? AppColors.errorBright : AppColors.textSecondary,
          fontWeight: overdue ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      trailing: Icon(task.type.icon, size: 18, color: AppColors.textTertiary),
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.store});

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    final activities = store.activities.take(6).toList();
    if (activities.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: Text(
            'No activity yet',
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
      );
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(
          children: [
            for (var i = 0; i < activities.length; i++) ...[
              if (i > 0) const Divider(indent: 56),
              _ActivityRow(activity: activities[i]),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final ActivityLog activity;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: activity.relatedType != null && activity.relatedId != null
          ? () =>
              openRecord(context, activity.relatedType!, activity.relatedId!)
          : null,
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.cloud,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(activity.kind.icon, size: 18, color: AppColors.brand),
      ),
      title: Text(
        activity.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        Formatters.relative(activity.timestamp),
        style: const TextStyle(fontSize: 12, color: AppColors.textTertiary),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: AppColors.textTertiary,
      ),
    );
  }
}
