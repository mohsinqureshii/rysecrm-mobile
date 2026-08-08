import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import 'account_detail_screen.dart';
import 'account_form_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  String _query = '';
  String? _typeFilter;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final accounts = store.accounts.where((account) {
      if (_typeFilter != null && account.type != _typeFilter) return false;
      if (_query.isEmpty) return true;
      final q = _query.toLowerCase();
      return account.name.toLowerCase().contains(q) ||
          account.industry.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            RecordIcon(
              icon: RecordType.account.icon,
              color: RecordType.account.color,
              size: 30,
            ),
            const SizedBox(width: 10),
            Text('Accounts (${accounts.length})'),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'new-account',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const AccountFormScreen()),
        ),
        child: const Icon(Icons.add),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: ListSearchField(
              hint: 'Search accounts…',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          SizedBox(
            height: 48,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              children: [
                for (final type in [null, 'Customer', 'Prospect', 'Partner']) ...[
                  AppFilterChip(
                    label: type ?? 'All',
                    selected: _typeFilter == type,
                    onSelected: (_) => setState(() => _typeFilter = type),
                  ),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Expanded(
            child: accounts.isEmpty
                ? const EmptyState(
                    icon: Icons.business_outlined,
                    title: 'No accounts found',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: accounts.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final account = accounts[index];
                      final openValue = store
                          .opportunitiesForAccount(account.id)
                          .where((o) => o.stage.isOpen)
                          .fold<double>(0, (s, o) => s + o.amount);
                      return Card(
                        child: ListTile(
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => AccountDetailScreen(
                                accountId: account.id,
                              ),
                            ),
                          ),
                          leading: RecordIcon(
                            icon: RecordType.account.icon,
                            color: RecordType.account.color,
                            size: 44,
                          ),
                          title: Text(
                            account.name,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            [
                              if (account.industry.isNotEmpty)
                                account.industry,
                              account.type,
                            ].join(' · '),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          trailing: openValue > 0
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      Formatters.compactCurrency(openValue),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const Text(
                                      'open pipeline',
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        color: AppColors.textTertiary,
                                      ),
                                    ),
                                  ],
                                )
                              : const Icon(
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
