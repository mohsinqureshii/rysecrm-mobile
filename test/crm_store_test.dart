import 'package:flutter_test/flutter_test.dart';
import 'package:ryse_crm/data/crm_store.dart';
import 'package:ryse_crm/data/models/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CrmStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = CrmStore();
    await store.load();
  });

  group('CrmStore seed & metrics', () {
    test('seeds demo data on first launch', () {
      expect(store.leads, isNotEmpty);
      expect(store.contacts, isNotEmpty);
      expect(store.accounts, isNotEmpty);
      expect(store.opportunities, isNotEmpty);
      expect(store.tasks, isNotEmpty);
    });

    test('pipeline metrics only count open opportunities', () {
      final openTotal = store.openOpportunities
          .fold<double>(0, (sum, o) => sum + o.amount);
      expect(store.pipelineValue, openTotal);
      expect(
        store.openOpportunities.every((o) => o.stage.isOpen),
        isTrue,
      );
      expect(store.weightedPipelineValue, lessThan(store.pipelineValue));
    });

    test('win rate is between 0 and 1', () {
      expect(store.winRate, inInclusiveRange(0, 1));
    });
  });

  group('CRUD', () {
    test('adding and deleting a lead updates the list and activity feed', () {
      final now = DateTime.now();
      final lead = Lead(
        id: store.newId(),
        firstName: 'Test',
        lastName: 'Person',
        company: 'Testco',
        createdAt: now,
        updatedAt: now,
      );
      final before = store.leads.length;
      store.addLead(lead);
      expect(store.leads.length, before + 1);
      expect(store.activities.first.title, contains('Test Person'));

      store.deleteLead(lead.id);
      expect(store.leads.length, before);
    });

    test('changing an opportunity stage logs a stage-change activity', () {
      final opp = store.openOpportunities
          .firstWhere((o) => o.stage != OpportunityStage.negotiation);
      store.setOpportunityStage(opp, OpportunityStage.negotiation);

      final updated = store.opportunityById(opp.id)!;
      expect(updated.stage, OpportunityStage.negotiation);
      expect(
        updated.probability,
        OpportunityStage.negotiation.defaultProbability,
      );
      expect(store.activities.first.kind, ActivityKind.stageChange);
    });

    test('toggling a task completes it and logs activity', () {
      final task = store.tasks.firstWhere((t) => !t.completed);
      store.toggleTask(task);
      final updated = store.taskById(task.id)!;
      expect(updated.completed, isTrue);
      expect(updated.completedAt, isNotNull);

      store.toggleTask(updated);
      expect(store.taskById(task.id)!.completed, isFalse);
      expect(store.taskById(task.id)!.completedAt, isNull);
    });
  });

  group('Lead conversion', () {
    test('creates contact, account, and opportunity like Salesforce',
        () async {
      final lead = store.leads
          .firstWhere((l) => l.status != LeadStatus.converted);
      final contactsBefore = store.contacts.length;
      final oppsBefore = store.opportunities.length;

      final result = (await store.convertLead(lead))!;

      expect(store.contacts.length, contactsBefore + 1);
      expect(store.opportunities.length, oppsBefore + 1);
      expect(result.contact.firstName, lead.firstName);
      expect(result.opportunity.accountId, result.account.id);
      expect(result.opportunity.contactId, result.contact.id);
      expect(
        store.leadById(lead.id)!.status,
        LeadStatus.converted,
      );
    });

    test('reuses an existing account with the same company name', () async {
      final account = store.accounts.first;
      final now = DateTime.now();
      final lead = Lead(
        id: store.newId(),
        firstName: 'Same',
        lastName: 'Company',
        company: account.name,
        createdAt: now,
        updatedAt: now,
      );
      store.addLead(lead);
      final accountsBefore = store.accounts.length;

      final result = (await store.convertLead(lead))!;

      expect(store.accounts.length, accountsBefore);
      expect(result.account.id, account.id);
    });
  });

  group('Search', () {
    test('finds records across entity types', () {
      final results = store.search('Northwind');
      expect(results, isNotEmpty);
      expect(
        results.map((r) => r.type).toSet(),
        containsAll({RecordType.account, RecordType.opportunity}),
      );
    });

    test('returns empty list for blank query', () {
      expect(store.search('   '), isEmpty);
    });
  });

  group('Persistence', () {
    test('data survives a reload from storage', () async {
      final now = DateTime.now();
      final lead = Lead(
        id: 'persist-check',
        firstName: 'Persist',
        lastName: 'Check',
        company: 'Diskco',
        createdAt: now,
        updatedAt: now,
      );
      store.addLead(lead);
      // Let the async persist complete.
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final fresh = CrmStore();
      await fresh.load();
      expect(fresh.leadById('persist-check'), isNotNull);
      expect(fresh.leadById('persist-check')!.company, 'Diskco');
    });
  });
}
