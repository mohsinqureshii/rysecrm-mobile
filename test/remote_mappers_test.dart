import 'package:flutter_test/flutter_test.dart';
import 'package:ryse_crm/data/api/api_client.dart';
import 'package:ryse_crm/data/api/api_config.dart';
import 'package:ryse_crm/data/api/remote_mappers.dart';
import 'package:ryse_crm/data/models/models.dart';

void main() {
  group('ApiConfig.normalize', () {
    test('adds scheme and strips trailing slash and trpc suffix', () {
      expect(ApiConfig.normalize('example.com/'), 'http://example.com');
      expect(
        ApiConfig.normalize('https://api.ryse.app/api/trpc'),
        'https://api.ryse.app',
      );
      expect(ApiConfig.normalize('  '), ApiConfig.defaultBaseUrl);
    });
  });

  group('ApiClient session', () {
    test('starts without a session and loads/clears cookies', () {
      final client = ApiClient(baseUrl: 'http://localhost:3000');
      expect(client.hasSession, isFalse);
      client.loadCookies({'crm_access_token': 'abc'});
      expect(client.hasSession, isTrue);
      client.clearCookies();
      expect(client.hasSession, isFalse);
    });
  });

  group('RemoteMappers id round-trip', () {
    test('appId / backendId are inverse for server ids', () {
      expect(RemoteMappers.appId(42), 'srv-42');
      expect(RemoteMappers.backendId('srv-42'), 42);
      expect(RemoteMappers.backendId('local-uuid'), isNull);
    });
  });

  group('RemoteMappers.lead', () {
    test('maps a backend lead row into the app model', () {
      final lead = RemoteMappers.lead({
        'id': 7,
        'firstName': 'Sofia',
        'lastName': 'Marchetti',
        'companyName': 'Lumen Analytics',
        'jobTitle': 'VP of Sales',
        'email': 'sofia@lumen.ai',
        'salesChannel': 'Webinar',
        'status': 'qualified',
        'rating': 'hot',
        'annualRevenue': '28000000.00',
        'aiScore': 92,
        'city': 'New York',
        'country': 'United States',
        'createdAt': '2026-08-01T10:00:00.000Z',
        'updatedAt': '2026-08-02T10:00:00.000Z',
      });

      expect(lead.id, 'srv-7');
      expect(lead.name, 'Sofia Marchetti');
      expect(lead.company, 'Lumen Analytics');
      expect(lead.status, LeadStatus.qualified);
      expect(lead.rating, LeadRating.hot);
      expect(lead.annualRevenue, 28000000);
      expect(lead.aiScore, 92);
      expect(lead.source, 'Webinar');
    });

    test('create input carries required backend fields', () {
      final now = DateTime.now();
      final input = RemoteMappers.leadCreateInput(Lead(
        id: 'x',
        firstName: 'Jane',
        lastName: 'Doe',
        company: 'Acme',
        email: 'jane@acme.com',
        source: 'Referral',
        rating: LeadRating.warm,
        status: LeadStatus.newLead,
        createdAt: now,
        updatedAt: now,
      ));
      expect(input['firstName'], 'Jane');
      expect(input['salesChannel'], 'Referral');
      expect(input['productOrService'], 'service');
      expect(input['serviceDescription'], isNotNull);
      expect(input['status'], 'new');
    });
  });

  group('RemoteMappers.opportunity', () {
    OpportunityStage resolver(int? stageId, bool won, bool lost) {
      if (won) return OpportunityStage.closedWon;
      if (lost) return OpportunityStage.closedLost;
      return switch (stageId) {
        1 => OpportunityStage.qualification,
        2 => OpportunityStage.proposal,
        3 => OpportunityStage.negotiation,
        _ => OpportunityStage.qualification,
      };
    }

    test('maps deal value strings and win probability', () {
      final opp = RemoteMappers.opportunity({
        'id': 3,
        'name': 'Big Deal',
        'accountId': 5,
        'dealValue': '240000.00',
        'winProbability': 80,
        'stageId': 3,
        'isClosed': false,
        'isWon': false,
        'createdAt': '2026-08-01T10:00:00.000Z',
      }, resolver);

      expect(opp.id, 'srv-3');
      expect(opp.accountId, 'srv-5');
      expect(opp.amount, 240000);
      expect(opp.probability, closeTo(0.8, 0.0001));
      expect(opp.stage, OpportunityStage.negotiation);
    });

    test('closed-won flag wins over stage id', () {
      final opp = RemoteMappers.opportunity({
        'id': 9,
        'name': 'Won Deal',
        'accountId': 1,
        'dealValue': '88000',
        'isClosed': true,
        'isWon': true,
        'createdAt': '2026-08-01T10:00:00.000Z',
      }, resolver);
      expect(opp.stage, OpportunityStage.closedWon);
    });

    test('create input maps stage id and amount', () {
      final now = DateTime.now();
      final input = RemoteMappers.opportunityCreateInput(
        Opportunity(
          id: 'x',
          name: 'Deal',
          accountId: 'srv-5',
          amount: 120000,
          probability: 0.45,
          closeDate: now,
          createdAt: now,
          updatedAt: now,
        ),
        2,
      );
      expect(input['accountId'], 5);
      expect(input['stageId'], 2);
      expect(input['dealValue'], '120000');
      expect(input['winProbability'], 45);
    });
  });

  group('RemoteMappers.task & activity', () {
    test('maps a backend Task activity into a TaskItem', () {
      final task = RemoteMappers.task({
        'id': 11,
        'type': 'Call',
        'subject': 'Follow up',
        'linkedRecordType': 'opportunity',
        'linkedRecordId': 3,
        'priority': 'high',
        'isCompleted': false,
        'dueDate': '2026-08-10T09:00:00.000Z',
        'activityDate': '2026-08-08T09:00:00.000Z',
        'createdAt': '2026-08-07T09:00:00.000Z',
      });
      expect(task.id, 'srv-11');
      expect(task.type, TaskType.call);
      expect(task.priority, TaskPriority.high);
      expect(task.relatedType, RecordType.opportunity);
      expect(task.relatedId, 'srv-3');
      expect(task.completed, isFalse);
    });

    test('interaction input targets the right record', () {
      final input = RemoteMappers.interactionInput(
        kind: ActivityKind.call,
        subject: 'Call: Acme',
        detail: 'Discussed pricing',
        relatedType: RecordType.account,
        relatedId: 'srv-4',
      );
      expect(input['type'], 'Call');
      expect(input['linkedRecordType'], 'account');
      expect(input['linkedRecordId'], 4);
      expect(input['description'], 'Discussed pricing');
    });
  });

  group('RemoteMappers.account & contact', () {
    test('maps account status to app type', () {
      final account = RemoteMappers.account({
        'id': 1,
        'name': 'Northwind',
        'status': 'customer',
        'industry': 'Transportation',
        'region': 'Global',
        'annualRevenue': '84000000.00',
        'createdAt': '2026-08-01T10:00:00.000Z',
      });
      expect(account.id, 'srv-1');
      expect(account.type, 'Customer');
      expect(account.annualRevenue, 84000000);
    });

    test('maps contact account linkage to server id', () {
      final contact = RemoteMappers.contact({
        'id': 2,
        'firstName': 'Elena',
        'lastName': 'Vasquez',
        'accountId': 1,
        'title': 'VP',
        'email': 'elena@nw.com',
        'createdAt': '2026-08-01T10:00:00.000Z',
      });
      expect(contact.id, 'srv-2');
      expect(contact.accountId, 'srv-1');
      expect(contact.name, 'Elena Vasquez');
    });
  });
}
