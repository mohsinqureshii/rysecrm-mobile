import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../accounts/account_form_screen.dart';
import '../contacts/contact_form_screen.dart';
import '../leads/lead_form_screen.dart';
import '../opportunities/opportunity_form_screen.dart';
import '../tasks/task_form_screen.dart';

/// Global "+" sheet: create any record type from anywhere.
void showCreateSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      void push(Widget screen) {
        Navigator.of(sheetContext).pop();
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => screen),
        );
      }

      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderStrong,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Create new',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
              _CreateTile(
                type: RecordType.lead,
                subtitle: 'Someone who may become a customer',
                onTap: () => push(const LeadFormScreen()),
              ),
              _CreateTile(
                type: RecordType.contact,
                subtitle: 'A person at an account',
                onTap: () => push(const ContactFormScreen()),
              ),
              _CreateTile(
                type: RecordType.account,
                subtitle: 'A company or organization',
                onTap: () => push(const AccountFormScreen()),
              ),
              _CreateTile(
                type: RecordType.opportunity,
                subtitle: 'A deal in your pipeline',
                onTap: () => push(const OpportunityFormScreen()),
              ),
              _CreateTile(
                type: RecordType.task,
                subtitle: 'A call, email, meeting, or to-do',
                onTap: () => push(const TaskFormScreen()),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

class _CreateTile extends StatelessWidget {
  const _CreateTile({
    required this.type,
    required this.subtitle,
    required this.onTap,
  });

  final RecordType type;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: RecordIcon(icon: type.icon, color: type.color, size: 40),
      title: Text(
        type.label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppColors.textTertiary),
    );
  }
}
