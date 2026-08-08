import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';

/// Result of parsing a natural-language quick-add string into a task.
class QuickAddResult {
  const QuickAddResult({
    required this.subject,
    required this.type,
    required this.dueDate,
    required this.priority,
  });

  final String subject;
  final TaskType type;
  final DateTime dueDate;
  final TaskPriority priority;
}

const _weekdays = {
  'monday': DateTime.monday,
  'mon': DateTime.monday,
  'tuesday': DateTime.tuesday,
  'tue': DateTime.tuesday,
  'tues': DateTime.tuesday,
  'wednesday': DateTime.wednesday,
  'wed': DateTime.wednesday,
  'thursday': DateTime.thursday,
  'thu': DateTime.thursday,
  'thurs': DateTime.thursday,
  'friday': DateTime.friday,
  'fri': DateTime.friday,
  'saturday': DateTime.saturday,
  'sat': DateTime.saturday,
  'sunday': DateTime.sunday,
  'sun': DateTime.sunday,
};

/// Parse a phrase like "Call Acme tomorrow 3pm about renewal" into a task.
/// Pure and deterministic given [now] — unit-testable.
QuickAddResult parseQuickAdd(String input, {required DateTime now}) {
  final text = input.trim();
  final lower = text.toLowerCase();

  // Type
  var type = TaskType.todo;
  if (RegExp(r'\b(call|ring|phone|dial)\b').hasMatch(lower)) {
    type = TaskType.call;
  } else if (RegExp(r'\b(email|e-mail|mail|send|follow[ -]?up)\b')
      .hasMatch(lower)) {
    type = TaskType.email;
  } else if (RegExp(r'\bdemo\b').hasMatch(lower)) {
    type = TaskType.demo;
  } else if (RegExp(r'\b(meet|meeting|lunch|coffee|call with|sync|catch[ -]?up)\b')
      .hasMatch(lower)) {
    type = TaskType.meeting;
  }

  // Priority
  var priority = TaskPriority.normal;
  if (RegExp(r'\b(urgent|asap|important|high[ -]priority)\b').hasMatch(lower) ||
      text.contains('!!')) {
    priority = TaskPriority.high;
  }

  // Date + time
  var day = DateTime(now.year, now.month, now.day);
  final matchedTokens = <String>[];

  if (RegExp(r'\btomorrow\b|\btmrw\b').hasMatch(lower)) {
    day = day.add(const Duration(days: 1));
    matchedTokens.add('tomorrow');
  } else if (RegExp(r'\bnext week\b').hasMatch(lower)) {
    day = day.add(const Duration(days: 7));
    matchedTokens.add('next week');
  } else if (RegExp(r'\btoday\b|\btonight\b').hasMatch(lower)) {
    matchedTokens.add('today');
  } else {
    for (final entry in _weekdays.entries) {
      if (RegExp('\\b${entry.key}\\b').hasMatch(lower)) {
        var d = day;
        // Next occurrence of that weekday (at least 1 day out).
        do {
          d = d.add(const Duration(days: 1));
        } while (d.weekday != entry.value);
        day = d;
        matchedTokens.add(entry.key);
        break;
      }
    }
  }

  // Time like "3pm", "3:30pm", "15:00"
  var hour = 9;
  var minute = 0;
  final timeMatch =
      RegExp(r'\b(\d{1,2})(?::(\d{2}))?\s*(am|pm)\b', caseSensitive: false)
          .firstMatch(lower);
  if (timeMatch != null) {
    hour = int.parse(timeMatch.group(1)!);
    minute = timeMatch.group(2) == null ? 0 : int.parse(timeMatch.group(2)!);
    final ampm = timeMatch.group(3)!.toLowerCase();
    if (ampm == 'pm' && hour != 12) hour += 12;
    if (ampm == 'am' && hour == 12) hour = 0;
    matchedTokens.add(timeMatch.group(0)!);
  } else {
    final match24 = RegExp(r'\b(\d{1,2}):(\d{2})\b').firstMatch(lower);
    if (match24 != null) {
      hour = int.parse(match24.group(1)!).clamp(0, 23);
      minute = int.parse(match24.group(2)!).clamp(0, 59);
      matchedTokens.add(match24.group(0)!);
    }
  }

  final due = DateTime(day.year, day.month, day.day, hour, minute);

  // Subject: strip recognised date/time tokens and filler words.
  var subject = text;
  for (final token in matchedTokens) {
    subject = subject.replaceAll(
      RegExp(RegExp.escape(token), caseSensitive: false),
      '',
    );
  }
  subject = subject
      .replaceAll(RegExp(r'\b(at|on|by|next)\b', caseSensitive: false), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
  if (subject.isEmpty) subject = text.trim();
  subject = subject[0].toUpperCase() + subject.substring(1);

  return QuickAddResult(
    subject: subject,
    type: type,
    dueDate: due,
    priority: priority,
  );
}

/// Try to match a record the phrase refers to (by name substring).
({RecordType type, String id, String name})? _matchRecord(
  CrmStore store,
  String input,
) {
  final lower = input.toLowerCase();
  for (final a in store.accounts) {
    if (a.name.isNotEmpty && lower.contains(a.name.toLowerCase())) {
      return (type: RecordType.account, id: a.id, name: a.name);
    }
  }
  for (final o in store.opportunities) {
    if (o.name.isNotEmpty && lower.contains(o.name.toLowerCase())) {
      return (type: RecordType.opportunity, id: o.id, name: o.name);
    }
  }
  for (final c in store.contacts) {
    if (c.name.isNotEmpty && lower.contains(c.name.toLowerCase())) {
      return (type: RecordType.contact, id: c.id, name: c.name);
    }
  }
  for (final l in store.leads) {
    if (l.name.isNotEmpty && lower.contains(l.name.toLowerCase())) {
      return (type: RecordType.lead, id: l.id, name: l.name);
    }
  }
  return null;
}

/// Natural-language quick-add sheet: type a phrase, see the parsed task, save.
void showQuickAddSheet(BuildContext context) {
  final controller = TextEditingController();

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
          final store = sheetContext.read<CrmStore>();
          final raw = controller.text.trim();
          final parsed =
              raw.isEmpty ? null : parseQuickAdd(raw, now: DateTime.now());
          final match = raw.isEmpty ? null : _matchRecord(store, raw);

          return Padding(
            padding: EdgeInsets.only(
              left: 20,
              right: 20,
              top: 20,
              bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, size: 20, color: AppColors.brand),
                    const SizedBox(width: 8),
                    const Text(
                      'Quick add',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    Text(
                      'Type it, we\'ll schedule it',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textTertiary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: controller,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setSheetState(() {}),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Call Acme Corp tomorrow 3pm about renewal',
                  ),
                ),
                const SizedBox(height: 12),
                if (parsed != null) _Preview(parsed: parsed, match: match?.name),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: parsed == null
                        ? null
                        : () {
                            final now = DateTime.now();
                            store.addTask(TaskItem(
                              id: store.newId(),
                              subject: parsed.subject,
                              type: parsed.type,
                              dueDate: parsed.dueDate,
                              priority: parsed.priority,
                              relatedType: match?.type,
                              relatedId: match?.id,
                              relatedName: match?.name ?? '',
                              ownerName: store.currentUserName,
                              createdAt: now,
                            ));
                            Navigator.of(sheetContext).pop();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Task added · '
                                    '${Formatters.dueLabel(parsed.dueDate)}'),
                              ),
                            );
                          },
                    icon: const Icon(Icons.add_task, size: 18),
                    label: const Text('Add task'),
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _Preview extends StatelessWidget {
  const _Preview({required this.parsed, this.match});

  final QuickAddResult parsed;
  final String? match;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(parsed.type.icon, size: 20, color: AppColors.brand),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  parsed.subject,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    parsed.type.label,
                    Formatters.dueLabel(parsed.dueDate),
                    Formatters.time(parsed.dueDate),
                    if (parsed.priority == TaskPriority.high) 'High priority',
                    if (match != null) 'on $match',
                  ].join(' · '),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
