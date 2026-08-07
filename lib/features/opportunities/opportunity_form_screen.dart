import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../../data/services/auth_provider.dart';
import '../shared/form_widgets.dart';

class OpportunityFormScreen extends StatefulWidget {
  const OpportunityFormScreen({
    super.key,
    this.opportunity,
    this.initialAccountId,
  });

  final Opportunity? opportunity;
  final String? initialAccountId;

  bool get isEditing => opportunity != null;

  @override
  State<OpportunityFormScreen> createState() => _OpportunityFormScreenState();
}

class _OpportunityFormScreenState extends State<OpportunityFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.opportunity?.name);
  late final _amount = TextEditingController(
    text: widget.opportunity == null || widget.opportunity!.amount == 0
        ? ''
        : widget.opportunity!.amount.toStringAsFixed(0),
  );
  late final _nextStep =
      TextEditingController(text: widget.opportunity?.nextStep);
  late final _notes = TextEditingController(text: widget.opportunity?.notes);

  late String? _accountId =
      widget.opportunity?.accountId ?? widget.initialAccountId;
  late String? _contactId = widget.opportunity?.contactId;
  late OpportunityStage _stage =
      widget.opportunity?.stage ?? OpportunityStage.prospecting;
  late String _source = widget.opportunity?.source ?? 'Web';
  late DateTime _closeDate = widget.opportunity?.closeDate ??
      DateTime.now().add(const Duration(days: 30));

  static const sources = [
    'Web',
    'Inbound',
    'Outbound',
    'Referral',
    'Partner',
    'Event',
    'Existing Customer',
    'Other',
  ];

  @override
  void dispose() {
    for (final controller in [_name, _amount, _nextStep, _notes]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = context.read<CrmStore>();
    final owner = context.read<AuthProvider>().user?.name ?? '';
    final amount = double.tryParse(_amount.text.replaceAll(',', '')) ?? 0;
    final now = DateTime.now();

    if (widget.isEditing) {
      store.updateOpportunity(widget.opportunity!.copyWith(
        name: _name.text.trim(),
        accountId: _accountId,
        contactId: _contactId,
        amount: amount,
        stage: _stage,
        probability: _stage == widget.opportunity!.stage
            ? widget.opportunity!.probability
            : _stage.defaultProbability,
        closeDate: _closeDate,
        source: _source,
        nextStep: _nextStep.text.trim(),
        notes: _notes.text.trim(),
        updatedAt: now,
      ));
    } else {
      store.addOpportunity(Opportunity(
        id: store.newId(),
        name: _name.text.trim(),
        accountId: _accountId,
        contactId: _contactId,
        amount: amount,
        stage: _stage,
        probability: _stage.defaultProbability,
        closeDate: _closeDate,
        source: _source,
        nextStep: _nextStep.text.trim(),
        notes: _notes.text.trim(),
        ownerName: owner,
        aiScore: 50 + (amount > 100000 ? 10 : 0),
        createdAt: now,
        updatedAt: now,
      ));
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          widget.isEditing ? 'Opportunity updated' : 'Opportunity created',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final accounts = store.accounts;
    final contacts = _accountId == null
        ? store.contacts
        : store.contactsForAccount(_accountId!);

    return Scaffold(
      appBar: AppBar(
        title:
            Text(widget.isEditing ? 'Edit Opportunity' : 'New Opportunity'),
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
            const FormSectionLabel('Deal'),
            AppTextField(
              controller: _name,
              label: 'Opportunity Name *',
              validator: requiredValidator,
              textCapitalization: TextCapitalization.sentences,
            ),
            AppDropdownField<String?>(
              label: 'Account',
              value: _accountId,
              items: [null, ...accounts.map((a) => a.id)],
              labelOf: (id) => id == null
                  ? 'No account'
                  : accounts.firstWhere((a) => a.id == id).name,
              onChanged: (v) => setState(() {
                _accountId = v;
                // Reset contact if it doesn't belong to the new account.
                if (v != null &&
                    _contactId != null &&
                    store.contactById(_contactId)?.accountId != v) {
                  _contactId = null;
                }
              }),
            ),
            AppDropdownField<String?>(
              label: 'Primary Contact',
              value: _contactId,
              items: [null, ...contacts.map((c) => c.id)],
              labelOf: (id) => id == null
                  ? 'No contact'
                  : store.contactById(id)?.name ?? 'Unknown',
              onChanged: (v) => setState(() => _contactId = v),
            ),
            AppTextField(
              controller: _amount,
              label: 'Amount (USD) *',
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Enter the deal amount';
                }
                if (double.tryParse(v.replaceAll(',', '')) == null) {
                  return 'Enter a valid number';
                }
                return null;
              },
            ),
            const FormSectionLabel('Forecast'),
            AppDropdownField<OpportunityStage>(
              label: 'Stage',
              value: _stage,
              items: OpportunityStage.values,
              labelOf: (s) => s.label,
              onChanged: (v) => setState(() => _stage = v!),
            ),
            AppDateField(
              label: 'Close Date',
              value: _closeDate,
              onChanged: (v) => setState(() => _closeDate = v),
            ),
            AppDropdownField<String>(
              label: 'Source',
              value: _source,
              items: sources,
              labelOf: (s) => s,
              onChanged: (v) => setState(() => _source = v!),
            ),
            AppTextField(controller: _nextStep, label: 'Next Step'),
            const FormSectionLabel('Notes'),
            AppTextField(controller: _notes, label: 'Notes', maxLines: 4),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child: Text(
                widget.isEditing ? 'Save Changes' : 'Create Opportunity',
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
