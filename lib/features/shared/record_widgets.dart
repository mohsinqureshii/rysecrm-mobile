import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';

/// Vertical timeline of activity entries for a record.
class ActivityTimeline extends StatelessWidget {
  const ActivityTimeline({super.key, required this.activities});

  final List<ActivityLog> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const EmptyState(
        icon: Icons.history,
        title: 'No activity yet',
        message: 'Calls, emails, and updates on this record will appear here.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: activities.length,
      itemBuilder: (context, index) {
        final activity = activities[index];
        final isLast = index == activities.length - 1;
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.cloud,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      activity.kind.icon,
                      size: 17,
                      color: AppColors.brand,
                    ),
                  ),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 2,
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        color: AppColors.border,
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        activity.title,
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if (activity.detail.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          activity.detail,
                          style: const TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text(
                        '${Formatters.relative(activity.timestamp)}'
                        '${activity.userName.isEmpty ? '' : ' · ${activity.userName}'}',
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
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

/// Bottom sheet for logging a call / email / meeting / note on a record.
Future<void> showLogInteractionSheet(
  BuildContext context, {
  required RecordType relatedType,
  required String relatedId,
  required String relatedName,
}) {
  final controller = TextEditingController();
  var kind = ActivityKind.call;

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setSheetState) {
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
                Text(
                  'Log activity · $relatedName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  children: [
                    for (final option in [
                      ActivityKind.call,
                      ActivityKind.email,
                      ActivityKind.meeting,
                      ActivityKind.note,
                    ])
                      ChoiceChip(
                        label: Text(option.label),
                        avatar: Icon(
                          option.icon,
                          size: 16,
                          color: kind == option
                              ? AppColors.brand
                              : AppColors.textTertiary,
                        ),
                        selected: kind == option,
                        onSelected: (_) =>
                            setSheetState(() => kind = option),
                      ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  autofocus: true,
                  decoration: const InputDecoration(
                    hintText: 'What happened? (e.g. "Discussed pricing…")',
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      final note = controller.text.trim();
                      if (note.isEmpty) return;
                      sheetContext.read<CrmStore>().logInteraction(
                            kind: kind,
                            title: '${kind.label}: $relatedName',
                            detail: note,
                            relatedType: relatedType,
                            relatedId: relatedId,
                            relatedName: relatedName,
                          );
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${kind.label} logged'),
                        ),
                      );
                    },
                    child: const Text('Save'),
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

/// Row of quick actions shown under a record header (Call, Email, …).
class RecordActionBar extends StatelessWidget {
  const RecordActionBar({super.key, required this.actions});

  final List<RecordAction> actions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          for (var i = 0; i < actions.length; i++) ...[
            if (i > 0) const SizedBox(width: 10),
            Expanded(
              child: _ActionButton(action: actions[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class RecordAction {
  const RecordAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.emphasized = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool emphasized;
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.action});

  final RecordAction action;

  @override
  Widget build(BuildContext context) {
    final color = action.emphasized ? Colors.white : AppColors.brand;
    return Material(
      color: action.emphasized ? AppColors.brand : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: action.emphasized
                ? null
                : Border.all(color: AppColors.borderStrong),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(action.icon, size: 20, color: color),
              const SizedBox(height: 4),
              Text(
                action.label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
