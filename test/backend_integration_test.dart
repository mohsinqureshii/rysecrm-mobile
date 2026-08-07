@Tags(['integration'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:ryse_crm/data/api/api_client.dart';
import 'package:ryse_crm/data/api/remote_mappers.dart';
import 'package:ryse_crm/data/api/ryse_api.dart';
import 'package:ryse_crm/data/models/models.dart';

/// Live end-to-end test against a running techbanq_crm backend.
///
/// It is skipped unless the server URL and credentials are supplied at compile
/// time, so a normal `flutter test` (and CI) stays green without a backend:
///
///   flutter test test/backend_integration_test.dart \
///     --dart-define=RYSE_API_URL=http://localhost:3000 \
///     --dart-define=RYSE_TEST_EMAIL=maq@techbanq.net \
///     --dart-define=RYSE_TEST_PASSWORD='...'
void main() {
  const url = String.fromEnvironment('RYSE_API_URL');
  const email = String.fromEnvironment('RYSE_TEST_EMAIL');
  const password = String.fromEnvironment('RYSE_TEST_PASSWORD');

  final configured = url.isNotEmpty && email.isNotEmpty && password.isNotEmpty;

  group('Backend integration', () {
    late RyseApi api;

    setUpAll(() {
      api = RyseApi(ApiClient(baseUrl: url));
    });

    test('authenticates and returns the current user', () async {
      final user = await api.login(email, password);
      expect(user['email'], isNotNull);
      final me = await api.me();
      expect(me, isNotNull);
    });

    test('loads pipeline stages', () async {
      final stages = await api.pipelineStages();
      expect(stages, isNotEmpty);
    });

    test('creates and lists an account', () async {
      final account = Account(
        id: 'x',
        name: 'Integration Test Co ${DateTime.now().millisecondsSinceEpoch}',
        type: 'Prospect',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final created =
          await api.accountCreate(RemoteMappers.accountCreateInput(account));
      expect(created['id'], isNotNull);

      final rows = await api.accountsList();
      final mapped = rows.map(RemoteMappers.account).toList();
      expect(mapped.any((a) => a.name == account.name), isTrue);
    });

    test('creates a lead and maps it back', () async {
      final now = DateTime.now();
      final lead = Lead(
        id: 'x',
        firstName: 'Inte',
        lastName: 'Gration',
        company: 'Testco ${now.millisecondsSinceEpoch}',
        email: 'inte.${now.millisecondsSinceEpoch}@example.com',
        source: 'Web',
        rating: LeadRating.warm,
        status: LeadStatus.newLead,
        createdAt: now,
        updatedAt: now,
      );
      final created =
          await api.leadCreate(RemoteMappers.leadCreateInput(lead));
      expect(created['id'], isNotNull);

      final rows = await api.leadsList();
      expect(rows.map(RemoteMappers.lead).any((l) => l.company == lead.company),
          isTrue);
    });

    test('creates an opportunity against a stage', () async {
      final stages = await api.pipelineStages();
      final accounts = await api.accountsList();
      expect(accounts, isNotEmpty, reason: 'need an account to attach a deal');
      final accountId = accounts.first['id'];
      final stageId = stages.first['id'];

      final created = await api.opportunityCreate({
        'name': 'Integration Deal ${DateTime.now().millisecondsSinceEpoch}',
        'accountId': accountId,
        'productOrService': 'service',
        'serviceDescription': 'Automated integration test deal',
        'stageId': stageId,
        'dealValue': '50000',
        'dealCurrency': 'USD',
        'winProbability': 30,
      });
      expect(created['id'], isNotNull);

      final opps = await api.opportunitiesList();
      expect(opps, isNotEmpty);
    });

    test('global search and dashboard respond', () async {
      final search = await api.searchGlobal('Test');
      expect(search.keys, containsAll(['leads', 'opportunities', 'accounts']));

      final overview = await api.dashboardOverview();
      expect(overview['pipeline'], isNotNull);
    });

    test('lists notifications and unread count', () async {
      final count = await api.notificationsUnreadCount();
      expect(count, greaterThanOrEqualTo(0));
      await api.notificationsList();
    });
  }, skip: configured ? false : 'Set RYSE_API_URL/EMAIL/PASSWORD to run.');
}
