import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../shell/record_nav.dart';
import '../shell/ryse_app_bar.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _selected;
  late DateTime _weekStart;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _weekStart = _selected.subtract(Duration(days: _selected.weekday - 1));
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final days = [for (var i = 0; i < 7; i++) _weekStart.add(Duration(days: i))];

    final tasksForDay = store.tasks
        .where((t) => _sameDay(t.dueDate, _selected))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final upcomingMeetings = store.tasks
        .where((t) =>
            !t.completed &&
            t.type == TaskType.meeting &&
            t.dueDate.isAfter(DateTime.now()))
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    return Scaffold(
      appBar: buildRyseAppBar(
        context,
        title: 'Calendar',
        extraActions: [
          IconButton(
            tooltip: 'Today',
            icon: const Icon(Icons.today_outlined),
            onPressed: () {
              final now = DateTime.now();
              setState(() {
                _selected = DateTime(now.year, now.month, now.day);
                _weekStart =
                    _selected.subtract(Duration(days: _selected.weekday - 1));
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          _WeekBar(
            days: days,
            selected: _selected,
            countFor: (d) =>
                store.tasks.where((t) => _sameDay(t.dueDate, d)).length,
            onPrev: () => setState(
              () => _weekStart = _weekStart.subtract(const Duration(days: 7)),
            ),
            onNext: () => setState(
              () => _weekStart = _weekStart.add(const Duration(days: 7)),
            ),
            onSelect: (d) => setState(() => _selected = d),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                SectionHeader(
                  title: DateFormat('EEEE, MMM d').format(_selected),
                ),
                if (tasksForDay.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Card(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Icon(Icons.event_available_outlined,
                                color: AppColors.textTertiary),
                            SizedBox(width: 12),
                            Text(
                              'Nothing scheduled for this day.',
                              style:
                                  TextStyle(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  for (final t in tasksForDay) _AgendaTile(task: t),
                if (upcomingMeetings.isNotEmpty) ...[
                  const SectionHeader(title: 'Upcoming Meetings'),
                  for (final m in upcomingMeetings.take(5))
                    _AgendaTile(task: m, showDate: true),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekBar extends StatelessWidget {
  const _WeekBar({
    required this.days,
    required this.selected,
    required this.countFor,
    required this.onPrev,
    required this.onNext,
    required this.onSelect,
  });

  final List<DateTime> days;
  final DateTime selected;
  final int Function(DateTime) countFor;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final ValueChanged<DateTime> onSelect;

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Container(
      color: AppColors.header,
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: onPrev,
              ),
              Expanded(
                child: Text(
                  DateFormat('MMMM yyyy').format(days[3]),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: onNext,
              ),
            ],
          ),
          Row(
            children: [
              for (final d in days)
                Expanded(
                  child: GestureDetector(
                    onTap: () => onSelect(d),
                    child: _DayCell(
                      day: d,
                      selected: _sameDay(d, selected),
                      isToday: _sameDay(d, now),
                      count: countFor(d),
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

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.day,
    required this.selected,
    required this.isToday,
    required this.count,
  });

  final DateTime day;
  final bool selected;
  final bool isToday;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.brand : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        border: isToday && !selected
            ? Border.all(color: AppColors.brand)
            : null,
      ),
      child: Column(
        children: [
          Text(
            DateFormat('E').format(day).substring(0, 1),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: selected ? Colors.white70 : AppColors.textTertiary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: selected ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: count > 0
                  ? (selected ? Colors.white : AppColors.brandAccent)
                  : Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaTile extends StatelessWidget {
  const _AgendaTile({required this.task, this.showDate = false});

  final TaskItem task;
  final bool showDate;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          onTap: () => openRecord(context, RecordType.task, task.id),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(task.type.icon, color: AppColors.brandAccent, size: 20),
          ),
          title: Text(
            task.subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              decoration:
                  task.completed ? TextDecoration.lineThrough : null,
              color: task.completed
                  ? AppColors.textTertiary
                  : AppColors.textPrimary,
            ),
          ),
          subtitle: Text(
            [
              showDate
                  ? Formatters.dueLabel(task.dueDate)
                  : Formatters.time(task.dueDate),
              if (task.relatedName.isNotEmpty) task.relatedName,
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          trailing: task.completed
              ? const Icon(Icons.check_circle, color: AppColors.success)
              : Text(
                  task.type.label,
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: AppColors.textTertiary,
                  ),
                ),
        ),
      ),
    );
  }
}
