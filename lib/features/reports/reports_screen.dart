import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../shell/ryse_app_bar.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    return Scaffold(
      appBar: buildRyseAppBar(context, title: 'Reports'),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          _KpiStrip(store: store),
          const SectionHeader(title: 'Pipeline by Stage'),
          _ChartCard(height: 220, child: _PipelineBars(store: store)),
          const SectionHeader(title: 'Win / Loss'),
          _ChartCard(height: 200, child: _WinLossDonut(store: store)),
          const SectionHeader(title: 'Leads by Source'),
          _ChartCard(height: 220, child: _LeadsBySource(store: store)),
          const SectionHeader(title: 'Revenue Trend (Won)'),
          _ChartCard(height: 220, child: _RevenueTrend(store: store)),
          const SectionHeader(title: 'Top Reps'),
          _RepLeaderboard(store: store),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.child, required this.height});

  final Widget child;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 18, 16, 12),
          child: SizedBox(height: height, child: child),
        ),
      ),
    );
  }
}

class _KpiStrip extends StatelessWidget {
  const _KpiStrip({required this.store});

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Row(
        children: [
          Expanded(
            child: KpiCard(
              label: 'Weighted Pipeline',
              value: Formatters.compactCurrency(store.weightedPipelineValue),
              caption: '${store.openOpportunities.length} open',
              icon: Icons.trending_up,
              color: AppColors.brand,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: KpiCard(
              label: 'Win Rate',
              value: '${(store.winRate * 100).toStringAsFixed(0)}%',
              caption: '${store.wonOpportunities.length} won',
              icon: Icons.emoji_events_outlined,
              color: AppColors.success,
            ),
          ),
        ],
      ),
    );
  }
}

class _PipelineBars extends StatelessWidget {
  const _PipelineBars({required this.store});

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    final byStage = store.pipelineByStage;
    final stages = byStage.keys.toList();
    final values = [
      for (final s in stages)
        byStage[s]!.fold<double>(0, (sum, o) => sum + o.amount),
    ];
    final maxV = values.fold<double>(0, (a, b) => a > b ? a : b);
    if (maxV == 0) return const _EmptyChart();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxV * 1.2,
        barTouchData: _barTooltip(),
        gridData: _grid(),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 34,
              getTitlesWidget: (v, _) => _axisLabel(
                v.toInt() >= 0 && v.toInt() < stages.length
                    ? stages[v.toInt()].label.split(' ').first
                    : '',
              ),
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < stages.length; i++)
            BarChartGroupData(x: i, barRods: [
              BarChartRodData(
                toY: values[i],
                width: 20,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(5),
                ),
                color: AppColors
                    .chartPalette[i % AppColors.chartPalette.length],
              ),
            ]),
        ],
      ),
    );
  }
}

class _WinLossDonut extends StatelessWidget {
  const _WinLossDonut({required this.store});

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    final won = store.wonOpportunities.length;
    final lost = store.opportunities
        .where((o) => o.stage == OpportunityStage.closedLost)
        .length;
    final open = store.openOpportunities.length;
    if (won + lost + open == 0) return const _EmptyChart();

    final data = [
      (label: 'Won', value: won, color: AppColors.success),
      (label: 'Lost', value: lost, color: AppColors.errorBright),
      (label: 'Open', value: open, color: AppColors.brand),
    ];

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 42,
              sections: [
                for (final d in data)
                  if (d.value > 0)
                    PieChartSectionData(
                      value: d.value.toDouble(),
                      color: d.color,
                      title: '${d.value}',
                      radius: 34,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final d in data)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: d.color,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${d.label} (${d.value})',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _LeadsBySource extends StatelessWidget {
  const _LeadsBySource({required this.store});

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    final counts = <String, int>{};
    for (final l in store.leads) {
      final key = l.source.isEmpty ? 'Other' : l.source;
      counts[key] = (counts[key] ?? 0) + 1;
    }
    if (counts.isEmpty) return const _EmptyChart();
    final entries = counts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxV = entries.first.value.toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < entries.length && i < 6; i++)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                SizedBox(
                  width: 74,
                  child: Text(
                    entries[i].key,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: entries[i].value / maxV,
                      minHeight: 16,
                      backgroundColor: AppColors.surfaceAlt,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors
                            .chartPalette[i % AppColors.chartPalette.length],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entries[i].value}',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _RevenueTrend extends StatelessWidget {
  const _RevenueTrend({required this.store});

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    // Sum won deal value by month for the last 6 months.
    final now = DateTime.now();
    final months = <DateTime>[
      for (var i = 5; i >= 0; i--) DateTime(now.year, now.month - i, 1),
    ];
    double totalFor(DateTime m) => store.wonOpportunities
        .where((o) =>
            o.closeDate.year == m.year && o.closeDate.month == m.month)
        .fold<double>(0, (sum, o) => sum + o.amount);
    final values = months.map(totalFor).toList();
    final maxV = values.fold<double>(0, (a, b) => a > b ? a : b);

    if (maxV == 0) return const _EmptyChart();

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxV * 1.25,
        gridData: _grid(),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(),
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= months.length) return const SizedBox.shrink();
                return _axisLabel(_monthAbbrev(months[i].month));
              },
            ),
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => AppColors.surfaceAlt,
            getTooltipItems: (spots) => [
              for (final s in spots)
                LineTooltipItem(
                  Formatters.compactCurrency(s.y),
                  const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < values.length; i++)
                FlSpot(i.toDouble(), values[i]),
            ],
            isCurved: true,
            barWidth: 3,
            color: AppColors.brand,
            dotData: const FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.brand.withValues(alpha: 0.28),
                  AppColors.brand.withValues(alpha: 0.0),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepLeaderboard extends StatelessWidget {
  const _RepLeaderboard({required this.store});

  final CrmStore store;

  @override
  Widget build(BuildContext context) {
    final totals = <String, double>{};
    for (final o in store.wonOpportunities) {
      final name = o.ownerName.isEmpty ? 'Unassigned' : o.ownerName;
      totals[name] = (totals[name] ?? 0) + o.amount;
    }
    if (totals.isEmpty) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        child: const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'No closed-won deals yet.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ),
      );
    }
    final ranked = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Column(
          children: [
            for (var i = 0; i < ranked.length; i++) ...[
              if (i > 0) const Divider(indent: 60),
              ListTile(
                leading: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.brand.withValues(alpha: 0.2),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandAccent,
                    ),
                  ),
                ),
                title: Text(
                  ranked[i].key,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: Text(
                  Formatters.compactCurrency(ranked[i].value),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyChart extends StatelessWidget {
  const _EmptyChart();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        'Not enough data yet',
        style: TextStyle(color: AppColors.textSecondary),
      ),
    );
  }
}

// ── shared chart helpers ──

FlGridData _grid() => FlGridData(
      show: true,
      drawVerticalLine: false,
      getDrawingHorizontalLine: (_) =>
          const FlLine(color: AppColors.border, strokeWidth: 1),
    );

BarTouchData _barTooltip() => BarTouchData(
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => AppColors.surfaceAlt,
        getTooltipItem: (group, _, rod, _) => BarTooltipItem(
          Formatters.compactCurrency(rod.toY),
          const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );

Widget _axisLabel(String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );

String _monthAbbrev(int month) => const [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ][(month - 1) % 12];
