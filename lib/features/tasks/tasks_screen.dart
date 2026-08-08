import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../shell/record_nav.dart';
import '../shell/ryse_app_bar.dart';
import 'task_detail_screen.dart';

enum _TaskFilter { open, completed, all }

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  _TaskFilter _filter = _TaskFilter.open;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final tasks = store.tasks.where((task) {
      return switch (_filter) {
        _TaskFilter.open => !task.completed,
        _TaskFilter.completed => task.completed,
        _TaskFilter.all => true,
      };
    }).toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final overdue = <TaskItem>[];
    final dueToday = <TaskItem>[];
    final upcoming = <TaskItem>[];
    final done = <TaskItem>[];
    for (final task in tasks) {
      if (task.completed) {
        done.add(task);
        continue;
      }
      final day = DateTime(
        task.dueDate.year,
        task.dueDate.month,
        task.dueDate.day,
      );
      if (day.isBefore(today)) {
        overdue.add(task);
      } else if (day == today) {
        dueToday.add(task);
      } else {
        upcoming.add(task);
      }
    }

    return Scaffold(
      appBar: buildRyseAppBar(context, title: 'Tasks'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Row(
              children: [
                for (final (filter, label) in const [
                  (_TaskFilter.open, 'Open'),
                  (_TaskFilter.completed, 'Completed'),
                  (_TaskFilter.all, 'All'),
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
          Expanded(
            child: tasks.isEmpty
                ? const EmptyState(
                    icon: Icons.task_alt,
                    title: 'No tasks here',
                    message: 'Use the + button to add a call, email, or to-do.',
                  )
                : ListView(
                    padding: const EdgeInsets.only(bottom: 96),
                    children: [
                      if (overdue.isNotEmpty) ...[
                        _GroupHeader(
                          label: 'Overdue',
                          count: overdue.length,
                          color: AppColors.errorBright,
                        ),
                        for (final task in overdue) _TaskTile(task: task),
                      ],
                      if (dueToday.isNotEmpty) ...[
                        _GroupHeader(
                          label: 'Today',
                          count: dueToday.length,
                          color: AppColors.brand,
                        ),
                        for (final task in dueToday) _TaskTile(task: task),
                      ],
                      if (upcoming.isNotEmpty) ...[
                        _GroupHeader(
                          label: 'Upcoming',
                          count: upcoming.length,
                          color: AppColors.textSecondary,
                        ),
                        for (final task in upcoming) _TaskTile(task: task),
                      ],
                      if (done.isNotEmpty) ...[
                        _GroupHeader(
                          label: 'Completed',
                          count: done.length,
                          color: AppColors.success,
                        ),
                        for (final task in done) _TaskTile(task: task),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            '$label ($count)',
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});

  final TaskItem task;

  @override
  Widget build(BuildContext context) {
    final store = context.read<CrmStore>();
    final overdue = !task.completed && Formatters.isOverdue(task.dueDate);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Card(
        child: ListTile(
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => TaskDetailScreen(taskId: task.id),
            ),
          ),
          leading: Checkbox(
            value: task.completed,
            shape: const CircleBorder(),
            onChanged: (_) => store.toggleTask(task),
          ),
          title: Text(
            task.subject,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              decoration: task.completed ? TextDecoration.lineThrough : null,
              color: task.completed
                  ? AppColors.textTertiary
                  : AppColors.textPrimary,
            ),
          ),
          subtitle: Row(
            children: [
              Icon(
                task.type.icon,
                size: 13,
                color: AppColors.textTertiary,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  [
                    Formatters.dueLabel(task.dueDate),
                    if (task.relatedName.isNotEmpty) task.relatedName,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    color: overdue
                        ? AppColors.errorBright
                        : AppColors.textSecondary,
                    fontWeight: overdue ? FontWeight.w700 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
          trailing: task.priority == TaskPriority.high
              ? const Icon(
                  Icons.priority_high,
                  size: 18,
                  color: AppColors.errorBright,
                )
              : null,
          onLongPress: task.relatedType != null && task.relatedId != null
              ? () =>
                  openRecord(context, task.relatedType!, task.relatedId!)
              : null,
        ),
      ),
    );
  }
}
