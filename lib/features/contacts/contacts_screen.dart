import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import 'contact_detail_screen.dart';
import 'contact_form_screen.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final contacts = store.contacts.where((contact) {
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      final account = store.accountById(contact.accountId)?.name ?? '';
      return contact.name.toLowerCase().contains(q) ||
          contact.email.toLowerCase().contains(q) ||
          account.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.lastName.toLowerCase().compareTo(b.lastName.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RecordIcon(
              icon: RecordType.contact.icon,
              color: RecordType.contact.color,
              size: 30,
            ),
            const SizedBox(width: 10),
            Text('Contacts (${contacts.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'new-contact',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ContactFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: ListSearchField(
              hint: 'Search contacts…',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: contacts.isEmpty
                ? const EmptyState(
                    icon: Icons.person_outline,
                    title: 'No contacts found',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                    itemCount: contacts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      final account = store.accountById(contact.accountId);
                      return Card(
                        child: ListTile(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ContactDetailScreen(
                                contactId: contact.id,
                              ),
                            ),
                          ),
                          leading: InitialsAvatar(name: contact.name, size: 44),
                          title: Text(
                            contact.name,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (contact.title.isNotEmpty) contact.title,
                              if (account != null) account.name,
                            ].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
