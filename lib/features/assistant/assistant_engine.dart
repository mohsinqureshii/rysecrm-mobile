import '../../core/utils/formatters.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';

class AssistantReply {
  const AssistantReply(this.text, {this.suggestions = const []});

  final String text;
  final List<String> suggestions;
}

/// Deterministic on-device "AI" engine. Answers natural-language-ish
/// questions from live CRM data. In production this would call an LLM
/// with tool access to the CRM API; keeping it local makes the demo
/// fully offline and predictable.
class AssistantEngine {
  const AssistantEngine(this.store);

  final CrmStore store;

  static const defaultSuggestions = [
    'Summarize my pipeline',
    'Which deals are at risk?',
    'What should I do today?',
    'Rank my top leads',
    'Forecast this quarter',
  ];

  AssistantReply greeting(String firstName) => AssistantReply(
        'Hi $firstName! I\'m RYSE AI — your sales copilot. I can summarize '
        'your pipeline, flag deals at risk, prioritize leads, and plan your '
        'day. What would you like to know?',
        suggestions: defaultSuggestions,
      );

  AssistantReply answer(String rawQuery) {
    final query = rawQuery.toLowerCase();

    if (_matches(query, ['pipeline', 'summar'])) return _pipelineSummary();
    if (_matches(query, ['risk', 'stall', 'stuck', 'attention'])) {
      return _dealsAtRisk();
    }
    if (_matches(query, ['today', 'plan', 'do next', 'focus'])) {
      return _todayPlan();
    }
    if (_matches(query, ['lead', 'rank', 'prioriti', 'hottest'])) {
      return _topLeads();
    }
    if (_matches(query, ['forecast', 'quarter', 'quota', 'target'])) {
      return _forecast();
    }
    if (_matches(query, ['win rate', 'won', 'closed'])) return _winSummary();
    if (_matches(query, ['task', 'overdue', 'follow'])) return _taskSummary();
    if (_matches(query, ['hello', 'hi', 'hey', 'help', 'what can you'])) {
      return const AssistantReply(
        'I can help you stay on top of your book of business. Try one of '
        'these:',
        suggestions: defaultSuggestions,
      );
    }
    return const AssistantReply(
      'I didn\'t quite catch that. I\'m best at questions about your '
      'pipeline, deals, leads, forecast, and tasks — try one of these:',
      suggestions: defaultSuggestions,
    );
  }

  bool _matches(String query, List<String> keywords) =>
      keywords.any(query.contains);

  AssistantReply _pipelineSummary() {
    final open = store.openOpportunities;
    if (open.isEmpty) {
      return const AssistantReply(
        'Your pipeline is empty right now. Create an opportunity or convert '
        'a qualified lead to get started.',
        suggestions: ['Rank my top leads'],
      );
    }
    final byStage = store.pipelineByStage;
    final lines = StringBuffer()
      ..writeln(
        'You have ${open.length} open deals worth '
        '${Formatters.compactCurrency(store.pipelineValue)} '
        '(${Formatters.compactCurrency(store.weightedPipelineValue)} '
        'weighted by probability).\n',
      );
    for (final entry in byStage.entries) {
      if (entry.value.isEmpty) continue;
      final total =
          entry.value.fold<double>(0, (sum, o) => sum + o.amount);
      lines.writeln(
        '• ${entry.key.label}: ${entry.value.length} deal'
        '${entry.value.length == 1 ? '' : 's'} · '
        '${Formatters.compactCurrency(total)}',
      );
    }
    final biggest = [...open]..sort((a, b) => b.amount.compareTo(a.amount));
    lines.write(
      '\nBiggest open deal: ${biggest.first.name} '
      '(${Formatters.compactCurrency(biggest.first.amount)}).',
    );
    return AssistantReply(
      lines.toString(),
      suggestions: ['Which deals are at risk?', 'Forecast this quarter'],
    );
  }

  AssistantReply _dealsAtRisk() {
    final open = store.openOpportunities;
    final risky = open.where((o) {
      final daysToClose = o.closeDate.difference(DateTime.now()).inDays;
      return o.aiScore < 60 ||
          (daysToClose <= 10 && o.stage.index <= 3) ||
          Formatters.isOverdue(o.closeDate);
    }).toList()
      ..sort((a, b) => a.aiScore.compareTo(b.aiScore));

    if (risky.isEmpty) {
      return const AssistantReply(
        'Good news — nothing looks at risk right now. All open deals have '
        'healthy scores and realistic close dates. 🎉',
        suggestions: ['Summarize my pipeline', 'What should I do today?'],
      );
    }
    final lines = StringBuffer()
      ..writeln(
        '${risky.length} deal${risky.length == 1 ? '' : 's'} could use '
        'attention:\n',
      );
    for (final opp in risky.take(4)) {
      final reason = Formatters.isOverdue(opp.closeDate)
          ? 'close date has passed'
          : opp.aiScore < 60
              ? 'low score (${opp.aiScore}/100)'
              : 'closing soon while still in ${opp.stage.label}';
      lines.writeln(
        '• ${opp.name} — ${Formatters.compactCurrency(opp.amount)}, '
        '$reason.',
      );
    }
    lines.write(
      '\nSuggested next move: start with '
      '${risky.first.name} — '
      '${risky.first.nextStep.isEmpty ? 'book a call with the champion' : risky.first.nextStep.toLowerCase()}.',
    );
    return AssistantReply(
      lines.toString(),
      suggestions: ['What should I do today?', 'Summarize my pipeline'],
    );
  }

  AssistantReply _todayPlan() {
    final lines = StringBuffer('Here\'s your plan for today:\n');
    final overdue = store.overdueTasks;
    final today = store.tasksDueToday;
    if (overdue.isNotEmpty) {
      lines.writeln(
        '\n1. Clear ${overdue.length} overdue '
        'task${overdue.length == 1 ? '' : 's'} — oldest: '
        '"${overdue.first.subject}".',
      );
    }
    if (today.isNotEmpty) {
      lines.writeln(
        '${overdue.isEmpty ? '\n1.' : '2.'} Complete today\'s '
        '${today.length} task${today.length == 1 ? '' : 's'}: '
        '${today.map((t) => '"${t.subject}"').take(3).join(', ')}.',
      );
    }
    final closing = store.openOpportunities
        .where((o) => o.closeDate.difference(DateTime.now()).inDays <= 14)
        .toList()
      ..sort((a, b) => a.closeDate.compareTo(b.closeDate));
    if (closing.isNotEmpty) {
      lines.writeln(
        '${(overdue.isEmpty && today.isEmpty) ? '\n1.' : '3.'} Push deals '
        'closing in the next two weeks: '
        '${closing.map((o) => o.name).take(3).join('; ')}.',
      );
    }
    final hotLead = store.leads
        .where((l) =>
            l.rating == LeadRating.hot && l.status != LeadStatus.converted)
        .toList()
      ..sort((a, b) => b.aiScore.compareTo(a.aiScore));
    if (hotLead.isNotEmpty) {
      lines.write(
        '\nAnd if you have spare time, ${hotLead.first.name} at '
        '${hotLead.first.company} is your hottest lead '
        '(${hotLead.first.aiScore}/100).',
      );
    }
    if (overdue.isEmpty && today.isEmpty && closing.isEmpty) {
      return const AssistantReply(
        'Light day! No tasks due and nothing closing imminently. A good '
        'time to prospect — check your lead list for fresh names.',
        suggestions: ['Rank my top leads'],
      );
    }
    return AssistantReply(
      lines.toString(),
      suggestions: ['Which deals are at risk?', 'Rank my top leads'],
    );
  }

  AssistantReply _topLeads() {
    final leads = store.leads
        .where((l) =>
            l.status != LeadStatus.converted &&
            l.status != LeadStatus.unqualified)
        .toList()
      ..sort((a, b) => b.aiScore.compareTo(a.aiScore));
    if (leads.isEmpty) {
      return const AssistantReply(
        'No active leads right now. Create one from the + button or import '
        'from your next event.',
      );
    }
    final lines = StringBuffer('Your leads, ranked by RYSE AI score:\n\n');
    for (final (index, lead) in leads.take(5).indexed) {
      lines.writeln(
        '${index + 1}. ${lead.name} — ${lead.company} · '
        '${lead.aiScore}/100 (${lead.rating.label}, ${lead.status.label})',
      );
    }
    lines.write(
      '\nStart at the top: ${leads.first.name} came in via '
      '${leads.first.source.toLowerCase()} and is rated '
      '${leads.first.rating.label.toLowerCase()}.',
    );
    return AssistantReply(
      lines.toString(),
      suggestions: ['What should I do today?', 'Summarize my pipeline'],
    );
  }

  AssistantReply _forecast() {
    final won = store.wonValueThisQuarter;
    final weighted = store.weightedPipelineValue;
    final projected = won + weighted;
    return AssistantReply(
      'Quarter to date you\'ve closed ${Formatters.compactCurrency(won)}. '
      'Your open pipeline is worth '
      '${Formatters.compactCurrency(store.pipelineValue)}, or '
      '${Formatters.compactCurrency(weighted)} probability-weighted.\n\n'
      'Projected quarter finish: '
      '${Formatters.compactCurrency(projected)} '
      '(closed + weighted pipeline). Win rate so far: '
      '${(store.winRate * 100).toStringAsFixed(0)}%.',
      suggestions: ['Which deals are at risk?', 'Summarize my pipeline'],
    );
  }

  AssistantReply _winSummary() {
    final won = store.wonOpportunities;
    if (won.isEmpty) {
      return const AssistantReply(
        'No closed-won deals yet — let\'s change that. Which deal is '
        'closest to the finish line?',
        suggestions: ['Summarize my pipeline'],
      );
    }
    final total = won.fold<double>(0, (sum, o) => sum + o.amount);
    final latest = [...won]
      ..sort((a, b) => b.closeDate.compareTo(a.closeDate));
    return AssistantReply(
      'You\'ve won ${won.length} deals worth '
      '${Formatters.compactCurrency(total)} all-time. Most recent: '
      '${latest.first.name} '
      '(${Formatters.compactCurrency(latest.first.amount)}) on '
      '${Formatters.date(latest.first.closeDate)}. Win rate: '
      '${(store.winRate * 100).toStringAsFixed(0)}%.',
      suggestions: ['Forecast this quarter'],
    );
  }

  AssistantReply _taskSummary() {
    final overdue = store.overdueTasks;
    final today = store.tasksDueToday;
    final open = store.openTaskCount;
    return AssistantReply(
      'You have $open open tasks: ${overdue.length} overdue and '
      '${today.length} due today.'
      '${overdue.isNotEmpty ? '\n\nOldest overdue: "${overdue.first.subject}" (${Formatters.dueLabel(overdue.first.dueDate)}).' : ''}',
      suggestions: ['What should I do today?'],
    );
  }
}
