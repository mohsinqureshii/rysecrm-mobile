import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/common.dart';
import '../../data/crm_store.dart';
import '../../data/models/models.dart';
import '../shell/record_nav.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<CrmStore>();
    final results = store.search(_query);
    final grouped = <RecordType, List<SearchResult>>{};
    for (final result in results) {
      grouped.putIfAbsent(result.type, () => []).add(result);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Search'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(64),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: ListSearchField(
              hint: 'Search leads, deals, accounts, people…',
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      body: _query.trim().isEmpty
          ? const EmptyState(
              icon: Icons.search,
              title: 'Search everything',
              message:
                  'Find any lead, contact, account, opportunity, or task.',
            )
          : results.isEmpty
              ? EmptyState(
                  icon: Icons.search_off,
                  title: 'No results for “$_query”',
                  message: 'Check the spelling or try a shorter term.',
                )
              : ListView(
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    for (final entry in grouped.entries) ...[
                      SectionHeader(
                        title:
                            '${entry.key.plural} (${entry.value.length})',
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          child: Column(
                            children: [
                              for (var i = 0; i < entry.value.length; i++) ...[
                                if (i > 0) const Divider(indent: 66),
                                _ResultTile(result: entry.value[i]),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({required this.result});

  final SearchResult result;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () => openRecord(context, result.type, result.id),
      leading: RecordIcon(
        icon: result.type.icon,
        color: result.type.color,
        size: 38,
      ),
      title: Text(
        result.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        result.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style:
            const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
      ),
      trailing: const Icon(
        Icons.chevron_right,
        size: 18,
        color: AppColors.textTertiary,
      ),
    );
  }
}
