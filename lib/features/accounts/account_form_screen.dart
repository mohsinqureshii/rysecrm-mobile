import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../../data/services/auth_provider.dart';
import '../leads/lead_form_screen.dart';
import '../shared/form_widgets.dart';

class AccountFormScreen extends StatefulWidget {
  const AccountFormScreen({super.key, this.account});

  final Account? account;

  bool get isEditing => account != null;

  @override
  State<AccountFormScreen> createState() => _AccountFormScreenState();
}

class _AccountFormScreenState extends State<AccountFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _name = TextEditingController(text: widget.account?.name);
  late final _website = TextEditingController(text: widget.account?.website);
  late final _phone = TextEditingController(text: widget.account?.phone);
  late final _city = TextEditingController(text: widget.account?.billingCity);
  late final _country =
      TextEditingController(text: widget.account?.billingCountry);
  late final _employees = TextEditingController(
    text: widget.account == null || widget.account!.employees == 0
        ? ''
        : '${widget.account!.employees}',
  );
  late final _revenue = TextEditingController(
    text: widget.account == null || widget.account!.annualRevenue == 0
        ? ''
        : widget.account!.annualRevenue.toStringAsFixed(0),
  );
  late final _notes = TextEditingController(text: widget.account?.notes);

  late String _industry = widget.account?.industry ?? '';
  late String _type = widget.account?.type ?? 'Prospect';

  @override
  void dispose() {
    for (final controller in [
      _name,
      _website,
      _phone,
      _city,
      _country,
      _employees,
      _revenue,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = context.read<CrmStore>();
    final owner = context.read<AuthProvider>().user?.name ?? '';
    final now = DateTime.now();
    final employees = int.tryParse(_employees.text.trim()) ?? 0;
    final revenue = double.tryParse(_revenue.text.replaceAll(',', '')) ?? 0;

    if (widget.isEditing) {
      store.updateAccount(widget.account!.copyWith(
        name: _name.text.trim(),
        industry: _industry,
        type: _type,
        website: _website.text.trim(),
        phone: _phone.text.trim(),
        billingCity: _city.text.trim(),
        billingCountry: _country.text.trim(),
        employees: employees,
        annualRevenue: revenue,
        notes: _notes.text.trim(),
        updatedAt: now,
      ));
    } else {
      store.addAccount(Account(
        id: store.newId(),
        name: _name.text.trim(),
        industry: _industry,
        type: _type,
        website: _website.text.trim(),
        phone: _phone.text.trim(),
        billingCity: _city.text.trim(),
        billingCountry: _country.text.trim(),
        employees: employees,
        annualRevenue: revenue,
        notes: _notes.text.trim(),
        ownerName: owner,
        createdAt: now,
        updatedAt: now,
      ));
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEditing ? 'Account updated' : 'Account created'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Account' : 'New Account'),
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
            const FormSectionLabel('About'),
            AppTextField(
              controller: _name,
              label: 'Account Name *',
              validator: requiredValidator,
              textCapitalization: TextCapitalization.words,
            ),
            AppDropdownField<String>(
              label: 'Type',
              value: _type,
              items: const ['Customer', 'Prospect', 'Partner'],
              labelOf: (s) => s,
              onChanged: (v) => setState(() => _type = v!),
            ),
            AppDropdownField<String>(
              label: 'Industry',
              value: _industry.isEmpty ? null : _industry,
              items: LeadFormScreen.industries,
              labelOf: (s) => s,
              onChanged: (v) => setState(() => _industry = v ?? ''),
            ),
            AppTextField(
              controller: _website,
              label: 'Website',
              keyboardType: TextInputType.url,
            ),
            AppTextField(
              controller: _phone,
              label: 'Phone',
              keyboardType: TextInputType.phone,
            ),
            const FormSectionLabel('Company Profile'),
            AppTextField(
              controller: _employees,
              label: 'Employees',
              keyboardType: TextInputType.number,
            ),
            AppTextField(
              controller: _revenue,
              label: 'Annual Revenue (USD)',
              keyboardType: TextInputType.number,
            ),
            const FormSectionLabel('Billing Address'),
            AppTextField(
              controller: _city,
              label: 'City',
              textCapitalization: TextCapitalization.words,
            ),
            AppTextField(
              controller: _country,
              label: 'Country',
              textCapitalization: TextCapitalization.words,
            ),
            const FormSectionLabel('Notes'),
            AppTextField(controller: _notes, label: 'Notes', maxLines: 4),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child:
                  Text(widget.isEditing ? 'Save Changes' : 'Create Account'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
