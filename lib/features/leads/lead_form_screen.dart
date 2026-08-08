import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../../data/services/auth_provider.dart';
import '../shared/form_widgets.dart';

class LeadFormScreen extends StatefulWidget {
  const LeadFormScreen({super.key, this.lead});

  final Lead? lead;

  bool get isEditing => lead != null;

  static const industries = [
    'Technology',
    'Financial Services',
    'Healthcare',
    'Manufacturing',
    'Retail',
    'Energy',
    'Transportation',
    'Media',
    'Education',
    'Real Estate',
    'Insurance',
    'Consumer Goods',
    'Hospitality',
    'Other',
  ];

  static const sources = [
    'Web',
    'Referral',
    'Event',
    'Trade Show',
    'Webinar',
    'Cold Call',
    'Partner',
    'Other',
  ];

  @override
  State<LeadFormScreen> createState() => _LeadFormScreenState();
}

class _LeadFormScreenState extends State<LeadFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final _firstName = TextEditingController(text: widget.lead?.firstName);
  late final _lastName = TextEditingController(text: widget.lead?.lastName);
  late final _company = TextEditingController(text: widget.lead?.company);
  late final _title = TextEditingController(text: widget.lead?.title);
  late final _email = TextEditingController(text: widget.lead?.email);
  late final _phone = TextEditingController(text: widget.lead?.phone);
  late final _website = TextEditingController(text: widget.lead?.website);
  late final _revenue = TextEditingController(
    text: widget.lead == null || widget.lead!.annualRevenue == 0
        ? ''
        : widget.lead!.annualRevenue.toStringAsFixed(0),
  );
  late final _city = TextEditingController(text: widget.lead?.city);
  late final _country = TextEditingController(text: widget.lead?.country);
  late final _notes = TextEditingController(text: widget.lead?.notes);

  late String _industry = widget.lead?.industry ?? '';
  late String _source = widget.lead?.source ?? 'Web';
  late LeadStatus _status = widget.lead?.status ?? LeadStatus.newLead;
  late LeadRating _rating = widget.lead?.rating ?? LeadRating.warm;

  @override
  void dispose() {
    for (final controller in [
      _firstName,
      _lastName,
      _company,
      _title,
      _email,
      _phone,
      _website,
      _revenue,
      _city,
      _country,
      _notes,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  int _estimateScore(double revenue) {
    var score = 40;
    score += switch (_rating) {
      LeadRating.hot => 30,
      LeadRating.warm => 12,
      LeadRating.cold => -10,
    };
    if (revenue > 50000000) {
      score += 15;
    } else if (revenue > 10000000) {
      score += 8;
    }
    if (_source == 'Referral' || _source == 'Partner') score += 10;
    return score.clamp(5, 99);
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final store = context.read<CrmStore>();
    final owner = context.read<AuthProvider>().user?.name ?? '';
    final revenue = double.tryParse(_revenue.text.replaceAll(',', '')) ?? 0;
    final now = DateTime.now();

    if (widget.isEditing) {
      store.updateLead(widget.lead!.copyWith(
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        company: _company.text.trim(),
        title: _title.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        website: _website.text.trim(),
        industry: _industry,
        source: _source,
        status: _status,
        rating: _rating,
        annualRevenue: revenue,
        city: _city.text.trim(),
        country: _country.text.trim(),
        notes: _notes.text.trim(),
        updatedAt: now,
      ));
    } else {
      store.addLead(Lead(
        id: store.newId(),
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        company: _company.text.trim(),
        title: _title.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        website: _website.text.trim(),
        industry: _industry,
        source: _source,
        status: _status,
        rating: _rating,
        annualRevenue: revenue,
        city: _city.text.trim(),
        country: _country.text.trim(),
        notes: _notes.text.trim(),
        ownerName: owner,
        aiScore: _estimateScore(revenue),
        createdAt: now,
        updatedAt: now,
      ));
    }
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(widget.isEditing ? 'Lead updated' : 'Lead created'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Edit Lead' : 'New Lead'),
        actions: [
          TextButton(
            onPressed: _save,
            child: const Text(
              'Save',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
            AppTextField(
              controller: _company,
              label: 'Company *',
              validator: requiredValidator,
              textCapitalization: TextCapitalization.words,
            ),
            AppTextField(controller: _title, label: 'Title'),
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
              controller: _website,
              label: 'Website',
              keyboardType: TextInputType.url,
            ),
            const FormSectionLabel('Qualification'),
            AppDropdownField<LeadStatus>(
              label: 'Status',
              value: _status,
              items: LeadStatus.values,
              labelOf: (s) => s.label,
              onChanged: (v) => setState(() => _status = v!),
            ),
            AppDropdownField<LeadRating>(
              label: 'Rating',
              value: _rating,
              items: LeadRating.values,
              labelOf: (r) => r.label,
              onChanged: (v) => setState(() => _rating = v!),
            ),
            AppDropdownField<String>(
              label: 'Lead Source',
              value: _source,
              items: LeadFormScreen.sources,
              labelOf: (s) => s,
              onChanged: (v) => setState(() => _source = v!),
            ),
            AppDropdownField<String>(
              label: 'Industry',
              value: _industry.isEmpty ? null : _industry,
              items: LeadFormScreen.industries,
              labelOf: (s) => s,
              onChanged: (v) => setState(() => _industry = v ?? ''),
            ),
            AppTextField(
              controller: _revenue,
              label: 'Annual Revenue (USD)',
              keyboardType: TextInputType.number,
            ),
            const FormSectionLabel('Location'),
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
              child: Text(widget.isEditing ? 'Save Changes' : 'Create Lead'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
