import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../accounts/account_detail_screen.dart';
import '../contacts/contact_detail_screen.dart';
import '../leads/lead_detail_screen.dart';
import '../opportunities/opportunity_detail_screen.dart';
import '../tasks/task_detail_screen.dart';

/// Push the detail screen for any record type/id (used by search,
/// notifications, and related lists).
void openRecord(BuildContext context, RecordType type, String id) {
  final store = context.read<CrmStore>();
  Widget? screen;
  switch (type) {
    case RecordType.lead:
      if (store.leadById(id) != null) screen = LeadDetailScreen(leadId: id);
    case RecordType.contact:
      if (store.contactById(id) != null) {
        screen = ContactDetailScreen(contactId: id);
      }
    case RecordType.account:
      if (store.accountById(id) != null) {
        screen = AccountDetailScreen(accountId: id);
      }
    case RecordType.opportunity:
      if (store.opportunityById(id) != null) {
        screen = OpportunityDetailScreen(opportunityId: id);
      }
    case RecordType.task:
      if (store.taskById(id) != null) screen = TaskDetailScreen(taskId: id);
  }
  if (screen == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('This record is no longer available.')),
    );
    return;
  }
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => screen!),
  );
}
