import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../../data/services/auth_provider.dart';
import '../shared/form_widgets.dart';

class ContactFormScreen extends StatefulWidget {
  const ContactFormScreen({super.key, this.contact, this.initialAccountId});

  final Contact? contact;
  final String? initialAccountId;

  bool get isEditing => contact != null;

  @override
  State<ContactFormScreen> createState() => _ContactFormScreenState();
}

class _ContactFormScreenState extends State<ContactFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _firstName =
      TextEditingController(text: widget.contact?.firstName);
  late final _lastName = TextEditingController(text: widget.contact?.lastName);
  late final _title = TextEditingController(text: widget.contact?.title);
  late final _department =
      TextEditingController(text: widget.contact?.department);
  late final _email = TextEditingController(text: widget.contact?.email);
  late final _phone = TextEditingController(text: widget.contact?.phone);
  late final _mobile = TextEditingController(text: widget.contact?.mobile);
  late final _notes = TextEditingController(text: widget.contact?.notes);

  late String? _accountId =
      widget.contact?.accountId ?? widget.initialAccountId;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _title,
      _department,
      _email,
      _phone,
      _mobile,
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

    if (widget.isEditing) {
      store.updateContact(widget.contact!.copyWith(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        accountId: _accountId,
        title: _title.text.trim(),
        department: _department.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        mobile: _mobile.text.trim(),
        notes: _notes.text.trim(),
        updatedAt: now,
      ));
    } else {
      store.addContact(Contact(
        id: store.newId(),
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        accountId: _accountId,
        title: _title.text.trim(),
        department: _department.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        mobile: _mobile.text.trim(),
        notes: _notes.text.trim(),
        ownerName: owner,
        createdAt: now,
        updatedAt: now,
      ));
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEditing ? 'Contact updated' : 'Contact created'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accounts = context.watch<CrmStore>().accounts;
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Contact' : 'New Contact'),
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
              controller: _firstName,
              label: 'First Name *',
              validator: requiredValidator,
              textCapitalization: TextCapitalization.words,
            ),
            AppTextField(
              controller: _lastName,
              label: 'Last Name *',
              validator: requiredValidator,
              textCapitalization: TextCapitalization.words,
            ),
            AppDropdownField<String?>(
              label: 'Account',
              value: _accountId,
              items: [null, ...accounts.map((a) => a.id)],
              labelOf: (id) => id == null
                  ? 'No account'
                  : accounts.firstWhere((a) => a.id == id).name,
              onChanged: (v) => setState(() => _accountId = v),
            ),
            AppTextField(controller: _title, label: 'Title'),
            AppTextField(controller: _department, label: 'Department'),
            const FormSectionLabel('Contact Info'),
            AppTextField(
              controller: _email,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              validator: optionalEmailValidator,
            ),
            AppTextField(
              controller: _phone,
              label: 'Phone',
              keyboardType: TextInputType.phone,
            ),
            AppTextField(
              controller: _mobile,
              label: 'Mobile',
              keyboardType: TextInputType.phone,
            ),
            const FormSectionLabel('Notes'),
            AppTextField(controller: _notes, label: 'Notes', maxLines: 4),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _save,
              child:
                  Text(widget.isEditing ? 'Save Changes' : 'Create Contact'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
