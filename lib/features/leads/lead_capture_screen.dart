import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../../data/services/auth_provider.dart';
import '../shared/form_widgets.dart';
import 'lead_form_screen.dart';
import 'lead_scan.dart';

/// Fast, focused lead-capture flow reachable from the home screen. New leads
/// are written through [CrmStore.addLead], which syncs to the live backend
/// whenever the app is connected to a Jeeym workspace (otherwise saved locally
/// and synced on next connect).
class LeadCaptureScreen extends StatefulWidget {
  const LeadCaptureScreen({super.key});

  @override
  State<LeadCaptureScreen> createState() => _LeadCaptureScreenState();
}

class _LeadCaptureScreenState extends State<LeadCaptureScreen> {
  final _formKey = GlobalKey<FormState>();

  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _company = TextEditingController();
  final _title = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _website = TextEditingController();
  final _revenue = TextEditingController();
  final _city = TextEditingController();
  final _country = TextEditingController();
  final _notes = TextEditingController();

  String _source = 'Web';
  String _industry = '';
  LeadStatus _status = LeadStatus.newLead;
  LeadRating _rating = LeadRating.warm;
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
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
      c.dispose();
    }
    super.dispose();
  }

  /// Fill the form from a parsed scan/QR result and tell the user what landed.
  void _applyParsed(ParsedLead parsed, String source) {
    if (parsed.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Couldn't read a contact from that $source.")),
      );
      return;
    }
    setState(() {
      if (parsed.firstName.isNotEmpty) _firstName.text = parsed.firstName;
      if (parsed.lastName.isNotEmpty) _lastName.text = parsed.lastName;
      if (parsed.company.isNotEmpty) _company.text = parsed.company;
      if (parsed.title.isNotEmpty) _title.text = parsed.title;
      if (parsed.email.isNotEmpty) _email.text = parsed.email;
      if (parsed.phone.isNotEmpty) _phone.text = parsed.phone;
      if (parsed.website.isNotEmpty) _website.text = parsed.website;
      if (parsed.city.isNotEmpty) _city.text = parsed.city;
      if (parsed.country.isNotEmpty) _country.text = parsed.country;
      if (_source == 'Web') _source = 'Event';
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Scanned — review the details and save.')),
    );
  }

  Future<void> _scanCard() async {
    final text = await _pasteDialog(
      title: 'Scan business card',
      hint: 'Paste the card text (on device, the camera reads it for you):\n\n'
          'Jordan Lee\nVP of Sales\nAcme Technologies\n'
          'jordan@acme.com\n+1 415 555 0199',
    );
    if (text == null || text.trim().isEmpty) return;
    _applyParsed(parseBusinessCard(text), 'card');
  }

  Future<void> _scanQr() async {
    final text = await _pasteDialog(
      title: 'Scan QR / vCard',
      hint: 'Paste a QR or vCard payload (on device, point the camera at it):\n\n'
          'BEGIN:VCARD\nFN:Jordan Lee\nORG:Acme\nEMAIL:jordan@acme.com\n'
          'END:VCARD',
    );
    if (text == null || text.trim().isEmpty) return;
    _applyParsed(parseVCard(text), 'code');
  }

  Future<String?> _pasteDialog({required String title, required String hint}) {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          maxLines: 6,
          autofocus: true,
          decoration: InputDecoration(hintText: hint),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text),
            child: const Text('Parse'),
          ),
        ],
      ),
    );
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

  Future<void> _capture() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final store = context.read<CrmStore>();
    final auth = context.read<AuthProvider>();
    final owner = auth.user?.name ?? '';
    final revenue = double.tryParse(_revenue.text.replaceAll(',', '')) ?? 0;
    final now = DateTime.now();

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

    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          auth.serverMode
              ? 'Lead captured · synced to Jeeym'
              : 'Lead captured · saved on device',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final live = context.watch<AuthProvider>().serverMode;
    return Scaffold(
      appBar: AppBar(title: const Text('Capture Lead')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SyncBadge(live: live),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _scanCard,
                    icon: const Icon(Icons.document_scanner_outlined, size: 18),
                    label: const Text('Scan card'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _scanQr,
                    icon: const Icon(Icons.qr_code_scanner, size: 18),
                    label: const Text('Scan QR'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const FormSectionLabel('Contact'),
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _firstName,
                    label: 'First Name *',
                    validator: requiredValidator,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _lastName,
                    label: 'Last Name *',
                    validator: requiredValidator,
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            AppTextField(
              controller: _company,
              label: 'Company *',
              validator: requiredValidator,
              textCapitalization: TextCapitalization.words,
            ),
            AppTextField(controller: _title, label: 'Job Title'),
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
            const _FieldLabel('Rating'),
            _RatingSelector(
              value: _rating,
              onChanged: (r) => setState(() => _rating = r),
            ),
            const SizedBox(height: 14),
            AppDropdownField<String>(
              label: 'Lead Source',
              value: _source,
              items: LeadFormScreen.sources,
              labelOf: (s) => s,
              onChanged: (v) => setState(() => _source = v!),
            ),
            AppDropdownField<LeadStatus>(
              label: 'Status',
              value: _status,
              items: LeadStatus.values,
              labelOf: (s) => s.label,
              onChanged: (v) => setState(() => _status = v!),
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
            Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _city,
                    label: 'City',
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AppTextField(
                    controller: _country,
                    label: 'Country',
                    textCapitalization: TextCapitalization.words,
                  ),
                ),
              ],
            ),
            const FormSectionLabel('Notes'),
            AppTextField(controller: _notes, label: 'Notes', maxLines: 4),
            const SizedBox(height: 22),
            ElevatedButton.icon(
              onPressed: _saving ? null : _capture,
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1, size: 20),
              label: const Text('Capture Lead'),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.live});

  final bool live;

  @override
  Widget build(BuildContext context) {
    final color = live ? AppColors.success : AppColors.textSecondary;
    final bg = live ? AppColors.successLight : AppColors.surfaceAlt;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: live ? AppColors.success.withValues(alpha: 0.3) : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Icon(live ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
              size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              live
                  ? 'Live — new leads sync to your Jeeym workspace.'
                  : 'Offline — saved on device and synced when you connect Jeeym.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.3,
                color: live ? AppColors.success : AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 2),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _RatingSelector extends StatelessWidget {
  const _RatingSelector({required this.value, required this.onChanged});

  final LeadRating value;
  final ValueChanged<LeadRating> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final r in LeadRating.values) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(r),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: value == r
                      ? r.color.withValues(alpha: 0.14)
                      : AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: value == r ? r.color : AppColors.border,
                    width: value == r ? 1.6 : 1,
                  ),
                ),
                alignment: Alignment.center,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (r == LeadRating.hot)
                      Icon(Icons.local_fire_department,
                          size: 16, color: r.color),
                    if (r == LeadRating.hot) const SizedBox(width: 4),
                    Text(
                      r.label,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: value == r ? r.color : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (r != LeadRating.values.last) const SizedBox(width: 10),
        ],
      ],
    );
  }
}
