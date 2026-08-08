import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../shell/record_nav.dart';
import 'task_form_screen.dart';

class TaskDetailScreen extends StatelessWidget {
  const TaskDetailScreen({super.key, required this.taskId});

  final String taskId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final task = store.taskById(taskId);
    if (task == null) {
      return const Scaffold(
        body: EmptyState(icon: Icons.task_alt, title: 'Task deleted'),
      );
    }
    final overdue = !task.completed && Formatters.isOverdue(task.dueDate);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Task'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit':
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TaskFormScreen(task: task),
                    ),
                  );
                case 'delete':
                  _confirmDelete(context, task);
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 40),
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RecordIcon(
                      icon: task.type.icon,
                      color: RecordType.task.color,
                      size: 46,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.subject,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              height: 1.25,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              PillBadge(
                                label: task.type.label,
                                color: AppColors.task,
                              ),
                              PillBadge(
                                label: '${task.priority.label} priority',
                                color: task.priority.color,
                              ),
                              if (task.completed)
                                const PillBadge(
                                  label: 'Completed',
                                  color: AppColors.success,
                                  icon: Icons.check,
                                )
                              else if (overdue)
                                const PillBadge(
                                  label: 'Overdue',
                                  color: AppColors.errorBright,
                                  icon: Icons.warning_amber_outlined,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: task.completed
                        ? ElevatedButton.styleFrom(
                            backgroundColor: AppColors.background,
                            foregroundColor: AppColors.textSecondary,
                          )
                        : null,
                    onPressed: () {
                      store.toggleTask(task);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            task.completed
                                ? 'Task reopened'
                                : 'Task completed 🎉',
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      task.completed ? Icons.undo : Icons.check,
                      size: 18,
                    ),
                    label: Text(
                      task.completed ? 'Reopen Task' : 'Mark Complete',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader(title: 'Details'),
          FieldCard(
            children: [
              DetailFieldRow(
                label: 'Due Date',
                value:
                    '${Formatters.date(task.dueDate)} · ${Formatters.dueLabel(task.dueDate)}',
                valueColor: overdue ? AppColors.errorBright : null,
              ),
              DetailFieldRow(
                label: 'Related To',
                value: task.relatedName,
                onTap: task.relatedType != null && task.relatedId != null
                    ? () => openRecord(
                          context,
                          task.relatedType!,
                          task.relatedId!,
                        )
                    : null,
              ),
              DetailFieldRow(label: 'Assigned To', value: task.ownerName),
              DetailFieldRow(
                label: 'Created',
                value: Formatters.date(task.createdAt),
              ),
              if (task.completedAt != null)
                DetailFieldRow(
                  label: 'Completed',
                  value: Formatters.relative(task.completedAt!),
                ),
            ],
          ),
          if (task.notes.isNotEmpty) ...[
            const SectionHeader(title: 'Notes'),
            FieldCard(
              children: [DetailFieldRow(label: 'Notes', value: task.notes)],
            ),
          ],
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, TaskItem task) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text('Delete task?'),
        content: Text('“${task.subject}” will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppColors.errorBright),
            onPressed: () {
              dialogContext.read<CrmStore>().deleteTask(task.id);
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
