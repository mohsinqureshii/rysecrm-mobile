import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';

/// Bottom sheet to move an opportunity to another stage
/// (including Closed Won / Closed Lost).
Future<void> showStagePicker(BuildContext context, Opportunity opportunity) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 6),
            child: Text(
              'Move “${opportunity.name}” to…',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          for (final stage in OpportunityStage.values)
            ListTile(
              dense: true,
              leading: Icon(
                stage == OpportunityStage.closedWon
                    ? Icons.emoji_events
                    : stage == OpportunityStage.closedLost
                        ? Icons.cancel_outlined
                        : Icons.flag_outlined,
                color: stage == opportunity.stage
                    ? AppColors.brand
                    : stage == OpportunityStage.closedWon
                        ? AppColors.success
                        : stage == OpportunityStage.closedLost
                            ? AppColors.errorBright
                            : AppColors.textTertiary,
              ),
              title: Text(
                stage.label,
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight: stage == opportunity.stage
                      ? FontWeight.w800
                      : FontWeight.w500,
                  color: stage == opportunity.stage
                      ? AppColors.brand
                      : AppColors.textPrimary,
                ),
              ),
              trailing: stage == opportunity.stage
                  ? const Icon(Icons.check, color: AppColors.brand, size: 18)
                  : Text(
                      '${(stage.defaultProbability * 100).toStringAsFixed(0)}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textTertiary,
                      ),
                    ),
              onTap: () {
                Navigator.of(sheetContext).pop();
                if (stage != opportunity.stage) {
                  context
                      .read<CrmStore>()
                      .setOpportunityStage(opportunity, stage);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        stage == OpportunityStage.closedWon
                            ? '🎉 ${opportunity.name} marked Closed Won'
                            : '${opportunity.name} moved to ${stage.label}',
                      ),
                    ),
                  );
                }
              },
            ),
          const SizedBox(height: 6),
        ],
      ),
    ),
  );
}
