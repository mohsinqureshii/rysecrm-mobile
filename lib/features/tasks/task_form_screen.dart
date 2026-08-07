import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../../data/services/auth_provider.dart';
import '../shared/form_widgets.dart';

class TaskFormScreen extends StatefulWidget {
  const TaskFormScreen({super.key, this.task});

  final TaskItem? task;

  bool get isEditing => task != null;

  @override
  State<TaskFormScreen> createState() => _TaskFormScreenState();
}

/// A record a task can be related to ("Name" field in Salesforce).
class _RelatedOption {
  const _RelatedOption(this.type, this.id, this.label);

  final RecordType type;
  final String id;
  final String label;

  String get key => '${type.label}:$id';
}

class _TaskFormScreenState extends State<TaskFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _subject = TextEditingController(text: widget.task?.subject);
  late final _notes = TextEditingController(text: widget.task?.notes);

  late TaskType _type = widget.task?.type ?? TaskType.todo;
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.normal;
  late DateTime _dueDate = widget.task?.dueDate ??
      DateTime.now().add(const Duration(days: 1));
  late String? _relatedKey = widget.task?.relatedType != null &&
          widget.task?.relatedId != null
      ? '${widget.task!.relatedType!.label}:${widget.task!.relatedId!}'
      : null;

  @override
  void dispose() {
    _subject.dispose();
    _notes.dispose();
    super.dispose();
  }

  List<_RelatedOption> _relatedOptions(CrmStore store) => [
        for (final opp in store.opportunities)
          if (opp.stage.isOpen)
            _RelatedOption(RecordType.opportunity, opp.id, opp.name),
        for (final lead in store.leads)
          if (lead.status != LeadStatus.converted)
            _RelatedOption(
              RecordType.lead,
              lead.id,
              '${lead.name} (${lead.company})',
            ),
        for (final contact in store.contacts)
          _RelatedOption(RecordType.contact, contact.id, contact.name),
        for (final account in store.accounts)
          _RelatedOption(RecordType.account, account.id, account.name),
      ];

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = context.read<CrmStore>();
    final owner = context.read<AuthProvider>().user?.name ?? '';
    final now = DateTime.now();

    RecordType? relatedType;
    String? relatedId;
    String relatedName = '';
    if (_relatedKey != null) {
      final option = _relatedOptions(store)
          .where((o) => o.key == _relatedKey)
          .firstOrNull;
      if (option != null) {
        relatedType = option.type;
        relatedId = option.id;
        relatedName = option.label;
      }
    }

    if (widget.isEditing) {
      store.updateTask(widget.task!.copyWith(
        subject: _subject.text.trim(),
        type: _type,
        dueDate: _dueDate,
        priority: _priority,
        relatedType: relatedType,
        relatedId: relatedId,
        relatedName: relatedName,
        notes: _notes.text.trim(),
      ));
    } else {
      store.addTask(TaskItem(
        id: store.newId(),
        subject: _subject.text.trim(),
        type: _type,
        dueDate: _dueDate,
        priority: _priority,
        relatedType: relatedType,
        relatedId: relatedId,
        relatedName: relatedName,
        notes: _notes.text.trim(),
        ownerName: owner,
        createdAt: now,
      ));
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEditing ? 'Task updated' : 'Task created'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final options = _relatedOptions(store);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const FormSectionLabel('Task'),
            AppTextField(
              controller: _subject,
              label: 'Subject *',
              validator: requiredValidator,
              textCapitalization: TextCapitalization.sentences,
            ),
            AppDropdownField<TaskType>(
              label: 'Type',
              value: _type,
              items: TaskType.values,
              labelOf: (t) => t.label,
              onChanged: (v) => setState(() => _type = v!),
            ),
            AppDateField(
              label: 'Due Date',
              value: _dueDate,
              onChanged: (v) => setState(() => _dueDate = v),
            ),
            AppDropdownField<TaskPriority>(
              label: 'Priority',
              value: _priority,
              items: TaskPriority.values,
              labelOf: (p) => p.label,
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const FormSectionLabel('Related To'),
            AppDropdownField<String?>(
              label: 'Related Record',
              value: _relatedKey,
              items: [null, ...options.map((o) => o.key)],
              labelOf: (key) => key == null
                  ? 'Not related to a record'
                  : options
                      .firstWhere(
                        (o) => o.key == key,
                        orElse: () => _RelatedOption(
                          RecordType.task,
                          '',
                          'Unknown record',
                        ),
                      )
                      .label,
              onChanged: (v) => setState(() => _relatedKey = v),
            ),
            const FormSectionLabel('Notes'),
            AppTextField(controller: _notes, label: 'Notes', maxLines: 4),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text(widget.isEditing ? 'Save Changes' : 'Create Task'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
