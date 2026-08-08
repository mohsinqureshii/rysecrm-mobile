import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'api/api_client.dart';
import 'api/remote_mappers.dart';
import 'api/ryse_api.dart';
import 'demo_data.dart';
import 'models/models.dart';

/// A single search hit across any record type.
class SearchResult {
  const SearchResult({
    required this.type,
    required this.id,
    required this.title,
    required this.subtitle,
  });

  final RecordType type;
  final String id;
  final String title;
  final String subtitle;
}

/// Result of converting a lead (Salesforce-style conversion).
class LeadConversionResult {
  const LeadConversionResult({
    required this.contact,
    required this.account,
    required this.opportunity,
  });

  final Contact contact;
  final Account account;
  final Opportunity opportunity;
}

/// Central in-app data store for all CRM records.
///
/// Persists to [SharedPreferences] as JSON so data survives restarts; seeds
/// itself with [DemoData] on first launch. A production build would back this
/// with a REST/GraphQL sync layer instead of local persistence.
class CrmStore extends ChangeNotifier {
  CrmStore({this.currentUserName = 'Maq Qureshi'});

  static const _storageKey = 'ryse_crm_data_v1';

  /// Notes and attachments are a client-side layer kept in their own key so
  /// they survive both local and server-backed sessions (in server mode the
  /// record data is the server's, but these extras stay device-local until the
  /// backend sync for `notes`/`files` is enabled).
  static const _extrasKey = 'ryse_crm_extras_v1';
  static const _uuid = Uuid();

  final String currentUserName;

  List<Lead> _leads = [];
  List<Contact> _contacts = [];
  List<Account> _accounts = [];
  List<Opportunity> _opportunities = [];
  List<TaskItem> _tasks = [];
  List<ActivityLog> _activities = [];
  List<AppNotification> _notifications = [];
  List<Note> _notes = [];
  List<Attachment> _attachments = [];

  bool _loaded = false;
  bool get isLoaded => _loaded;

  /// When set, the store is backed by the live backend instead of demo data.
  RyseApi? _api;
  bool get isServerBacked => _api != null;

  /// Backend pipeline stages, used to map between the app's fixed stage enum
  /// and the server's dynamic stage rows.
  List<Map<String, dynamic>> _stages = const [];

  /// Last error from a backend operation, surfaced to the UI as a banner.
  String? lastError;
  bool _syncing = false;
  bool get isSyncing => _syncing;

  List<Lead> get leads => List.unmodifiable(_leads);
  List<Contact> get contacts => List.unmodifiable(_contacts);
  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Opportunity> get opportunities => List.unmodifiable(_opportunities);
  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<ActivityLog> get activities => List.unmodifiable(_activities);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);
  List<Note> get notes => List.unmodifiable(_notes);
  List<Attachment> get attachments => List.unmodifiable(_attachments);

  String newId() => _uuid.v4();

  // -------------------------------------------------------------------------
  // Loading & persistence
  // -------------------------------------------------------------------------

  /// Point the store at a data source. Passing a live [api] switches to
  /// server mode; passing null returns to local demo data. Safe to call
  /// repeatedly — it reloads only when the source actually changes.
  Future<void> connect(RyseApi? api) async {
    final changed = !identical(_api, api) ||
        (api == null) != (_api == null);
    if (!changed && _loaded) return;
    _api = api;
    _loaded = false;
    await load();
  }

  Future<void> load() async {
    if (_loaded) return;
    await _loadExtras();
    if (_api != null) {
      await _loadFromServer();
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _leads = _decodeList(data['leads'], Lead.fromJson);
        _contacts = _decodeList(data['contacts'], Contact.fromJson);
        _accounts = _decodeList(data['accounts'], Account.fromJson);
        _opportunities =
            _decodeList(data['opportunities'], Opportunity.fromJson);
        _tasks = _decodeList(data['tasks'], TaskItem.fromJson);
        _activities = _decodeList(data['activities'], ActivityLog.fromJson);
      } catch (_) {
        _seed();
      }
    } else {
      _seed();
    }
    // Notifications are session-scoped (they reference live seed context).
    _notifications = DemoData.notifications();
    _loaded = true;
    notifyListeners();
  }

  static List<T> _decodeList<T>(
    Object? raw,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    if (raw is! List) return [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map(fromJson)
        .toList(growable: true);
  }

  void _seed() {
    _leads = DemoData.leads();
    _contacts = DemoData.contacts();
    _accounts = DemoData.accounts();
    _opportunities = DemoData.opportunities();
    _tasks = DemoData.tasks();
    _activities = DemoData.activities();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'leads': _leads.map((e) => e.toJson()).toList(),
        'contacts': _contacts.map((e) => e.toJson()).toList(),
        'accounts': _accounts.map((e) => e.toJson()).toList(),
        'opportunities': _opportunities.map((e) => e.toJson()).toList(),
        'tasks': _tasks.map((e) => e.toJson()).toList(),
        'activities': _activities.map((e) => e.toJson()).toList(),
      }),
    );
  }

  Future<void> _loadExtras() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_extrasKey);
    if (raw == null) return;
    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _notes = _decodeList(data['notes'], Note.fromJson);
      _attachments = _decodeList(data['attachments'], Attachment.fromJson);
    } catch (_) {
      _notes = [];
      _attachments = [];
    }
  }

  Future<void> _persistExtras() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _extrasKey,
      jsonEncode({
        'notes': _notes.map((e) => e.toJson()).toList(),
        'attachments': _attachments.map((e) => e.toJson()).toList(),
      }),
    );
  }

  // -------------------------------------------------------------------------
  // Server-backed loading
  // -------------------------------------------------------------------------

  Future<void> _loadFromServer() async {
    final api = _api!;
    _syncing = true;
    lastError = null;
    notifyListeners();
    try {
      _stages = await api.pipelineStages();
      await Future.wait([
        _refreshLeads(),
        _refreshContacts(),
        _refreshAccounts(),
        _refreshOpportunities(),
        _refreshTasks(),
        _refreshActivities(),
        _refreshNotifications(),
      ]);
    } on ApiException catch (e) {
      lastError = e.message;
    } catch (e) {
      lastError = 'Could not load data from the server. $e';
    } finally {
      _syncing = false;
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> _refreshLeads() async {
    final rows = await _api!.leadsList();
    _leads = rows.map(RemoteMappers.lead).toList();
  }

  Future<void> _refreshContacts() async {
    final rows = await _api!.contactsList();
    _contacts = rows.map(RemoteMappers.contact).toList();
  }

  Future<void> _refreshAccounts() async {
    final rows = await _api!.accountsList();
    _accounts = rows.map(RemoteMappers.account).toList();
  }

  Future<void> _refreshOpportunities() async {
    final rows = await _api!.opportunitiesList();
    _opportunities =
        rows.map((j) => RemoteMappers.opportunity(j, _resolveStage)).toList();
  }

  Future<void> _refreshTasks() async {
    final rows = await _api!.myTasks();
    _tasks = rows.map(RemoteMappers.task).toList();
  }

  Future<void> _refreshActivities() async {
    try {
      final rows = await _api!.activityFeed(limit: 30);
      _activities = rows.map(RemoteMappers.activity).toList();
    } catch (_) {
      // Activity feed is non-critical; leave whatever we had.
    }
  }

  Future<void> _refreshNotifications() async {
    try {
      final rows = await _api!.notificationsList();
      _notifications = rows.map(RemoteMappers.notification).toList();
    } catch (_) {
      _notifications = const [];
    }
  }

  /// Run a server mutation, refresh the affected collections, and surface any
  /// error to the UI.
  Future<void> _runServer(Future<void> Function() action) async {
    _syncing = true;
    notifyListeners();
    try {
      await action();
      lastError = null;
    } on ApiException catch (e) {
      lastError = e.message;
    } catch (e) {
      lastError = 'That action could not be completed. $e';
    } finally {
      _syncing = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (lastError != null) {
      lastError = null;
      notifyListeners();
    }
  }

  // ── Stage mapping (app enum ↔ backend stage rows) ──

  int _sid(Object? v) =>
      v is num ? v.toInt() : int.tryParse('$v') ?? -1;

  Map<String, dynamic>? _findStage(bool Function(Map<String, dynamic>) test) {
    for (final s in _stages) {
      if (test(s)) return s;
    }
    return null;
  }

  OpportunityStage _resolveStage(int? stageId, bool won, bool lost) {
    if (won) return OpportunityStage.closedWon;
    if (lost) return OpportunityStage.closedLost;
    final stage =
        stageId == null ? null : _findStage((s) => _sid(s['id']) == stageId);
    final name = (stage?['name'] ?? '').toString().toLowerCase();
    if (name.contains('prospect')) return OpportunityStage.prospecting;
    if (name.contains('qualif')) return OpportunityStage.qualification;
    if (name.contains('analysis') || name.contains('discov')) {
      return OpportunityStage.needsAnalysis;
    }
    if (name.contains('proposal') || name.contains('quote')) {
      return OpportunityStage.proposal;
    }
    if (name.contains('negoti')) return OpportunityStage.negotiation;
    if (stage?['isClosedWon'] == true) return OpportunityStage.closedWon;
    if (stage?['isClosedLost'] == true) return OpportunityStage.closedLost;
    return OpportunityStage.qualification;
  }

  int? _stageIdFor(OpportunityStage stage) {
    Map<String, dynamic>? match;
    bool named(Map<String, dynamic> s, String kw) =>
        (s['name'] ?? '').toString().toLowerCase().contains(kw);

    switch (stage) {
      case OpportunityStage.closedWon:
        match = _findStage((s) => s['isClosedWon'] == true);
      case OpportunityStage.closedLost:
        match = _findStage((s) => s['isClosedLost'] == true);
      case OpportunityStage.negotiation:
        match = _findStage((s) => named(s, 'negoti'));
      case OpportunityStage.proposal:
      case OpportunityStage.needsAnalysis:
        match = _findStage((s) => named(s, 'proposal') || named(s, 'analysis'));
      case OpportunityStage.qualification:
      case OpportunityStage.prospecting:
        match = _findStage((s) => named(s, 'qualif') || named(s, 'prospect'));
    }
    match ??= _findStage(
      (s) => s['isClosedWon'] != true && s['isClosedLost'] != true,
    );
    match ??= _stages.isNotEmpty ? _stages.first : null;
    return match == null ? null : _sid(match['id']);
  }

  int? _backendId(String appId) => RemoteMappers.backendId(appId);

  /// Reset all data back to the demo seed.
  Future<void> resetDemoData() async {
    if (isServerBacked) {
      await _loadFromServer();
      return;
    }
    _seed();
    _notifications = DemoData.notifications();
    await _persist();
    notifyListeners();
  }

  void _commit() {
    notifyListeners();
    _persist();
  }

  void _logActivity({
    required ActivityKind kind,
    required String title,
    String detail = '',
    RecordType? relatedType,
    String? relatedId,
    String relatedName = '',
  }) {
    _activities.insert(
      0,
      ActivityLog(
        id: newId(),
        kind: kind,
        title: title,
        detail: detail,
        timestamp: DateTime.now(),
        relatedType: relatedType,
        relatedId: relatedId,
        relatedName: relatedName,
        userName: currentUserName,
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Lookups
  // -------------------------------------------------------------------------

  Lead? leadById(String? id) =>
      id == null ? null : _leads.where((e) => e.id == id).firstOrNull;

  Contact? contactById(String? id) =>
      id == null ? null : _contacts.where((e) => e.id == id).firstOrNull;

  Account? accountById(String? id) =>
      id == null ? null : _accounts.where((e) => e.id == id).firstOrNull;

  Opportunity? opportunityById(String? id) =>
      id == null ? null : _opportunities.where((e) => e.id == id).firstOrNull;

  TaskItem? taskById(String? id) =>
      id == null ? null : _tasks.where((e) => e.id == id).firstOrNull;

  List<Contact> contactsForAccount(String accountId) =>
      _contacts.where((c) => c.accountId == accountId).toList();

  List<Opportunity> opportunitiesForAccount(String accountId) =>
      _opportunities.where((o) => o.accountId == accountId).toList();

  List<Opportunity> opportunitiesForContact(String contactId) =>
      _opportunities.where((o) => o.contactId == contactId).toList();

  List<TaskItem> tasksForRecord(RecordType type, String id) => _tasks
      .where((t) => t.relatedType == type && t.relatedId == id)
      .toList();

  List<ActivityLog> activitiesForRecord(RecordType type, String id) =>
      _activities
          .where((a) => a.relatedType == type && a.relatedId == id)
          .toList();

  // -------------------------------------------------------------------------
  // Leads
  // -------------------------------------------------------------------------

  void addLead(Lead lead) {
    if (isServerBacked) {
      unawaited(_runServer(() async {
        await _api!.leadCreate(RemoteMappers.leadCreateInput(lead));
        await _refreshLeads();
      }));
      return;
    }
    _leads.insert(0, lead);
    _logActivity(
      kind: ActivityKind.created,
      title: 'New lead: ${lead.name}',
      detail: lead.company.isEmpty ? '' : 'Company: ${lead.company}',
      relatedType: RecordType.lead,
      relatedId: lead.id,
      relatedName: lead.name,
    );
    _commit();
  }

  void updateLead(Lead lead, {bool log = true}) {
    if (isServerBacked) {
      unawaited(_runServer(() async {
        await _api!.leadUpdate(RemoteMappers.leadUpdateInput(lead));
        await _refreshLeads();
      }));
      return;
    }
    final index = _leads.indexWhere((e) => e.id == lead.id);
    if (index == -1) return;
    final previous = _leads[index];
    _leads[index] = lead;
    if (log && previous.status != lead.status) {
      _logActivity(
        kind: ActivityKind.statusChange,
        title: '${lead.name} marked ${lead.status.label}',
        relatedType: RecordType.lead,
        relatedId: lead.id,
        relatedName: lead.name,
      );
    }
    _commit();
  }

  void deleteLead(String id) {
    if (isServerBacked) {
      final backendId = _backendId(id);
      if (backendId == null) return;
      unawaited(_runServer(() async {
        await _api!.leadDelete(backendId);
        await _refreshLeads();
      }));
      return;
    }
    _leads.removeWhere((e) => e.id == id);
    _commit();
  }

  /// Salesforce-style conversion: lead becomes contact + account +
  /// opportunity in a single step.
  Future<LeadConversionResult?> convertLead(
    Lead lead, {
    double? opportunityAmount,
  }) async {
    if (isServerBacked) {
      return _convertLeadServer(lead, opportunityAmount);
    }
    final now = DateTime.now();

    var account = _accounts
        .where((a) => a.name.toLowerCase() == lead.company.toLowerCase())
        .firstOrNull;
    if (account == null) {
      account = Account(
        id: newId(),
        name: lead.company.isEmpty ? '${lead.name} Co.' : lead.company,
        industry: lead.industry,
        type: 'Prospect',
        billingCity: lead.city,
        billingCountry: lead.country,
        annualRevenue: lead.annualRevenue,
        ownerName: currentUserName,
        createdAt: now,
        updatedAt: now,
      );
      _accounts.insert(0, account);
    }

    final contact = Contact(
      id: newId(),
      firstName: lead.firstName,
      lastName: lead.lastName,
      accountId: account.id,
      title: lead.title,
      email: lead.email,
      phone: lead.phone,
      ownerName: currentUserName,
      notes: lead.notes,
      createdAt: now,
      updatedAt: now,
    );
    _contacts.insert(0, contact);

    final opportunity = Opportunity(
      id: newId(),
      name: '${account.name} — New Business',
      accountId: account.id,
      contactId: contact.id,
      amount: opportunityAmount ?? (lead.annualRevenue * 0.002),
      stage: OpportunityStage.qualification,
      probability: OpportunityStage.qualification.defaultProbability,
      closeDate: now.add(const Duration(days: 45)),
      source: lead.source,
      nextStep: 'Discovery call',
      ownerName: currentUserName,
      aiScore: lead.aiScore,
      createdAt: now,
      updatedAt: now,
    );
    _opportunities.insert(0, opportunity);

    final index = _leads.indexWhere((e) => e.id == lead.id);
    if (index != -1) {
      _leads[index] = lead.copyWith(
        status: LeadStatus.converted,
        updatedAt: now,
      );
    }

    _logActivity(
      kind: ActivityKind.converted,
      title: 'Converted lead ${lead.name}',
      detail:
          'Created contact, account "${account.name}", and a new opportunity.',
      relatedType: RecordType.opportunity,
      relatedId: opportunity.id,
      relatedName: opportunity.name,
    );
    _commit();

    return LeadConversionResult(
      contact: contact,
      account: account,
      opportunity: opportunity,
    );
  }

  Future<LeadConversionResult?> _convertLeadServer(
    Lead lead,
    double? opportunityAmount,
  ) async {
    final leadId = _backendId(lead.id);
    if (leadId == null) return null;
    LeadConversionResult? result;
    await _runServer(() async {
      final existingAccount = _accounts
          .where((a) => a.name.toLowerCase() == lead.company.toLowerCase())
          .firstOrNull;
      final stageId = _stageIdFor(OpportunityStage.qualification);
      final input = <String, dynamic>{
        'leadId': leadId,
        'opportunityName': '${lead.company.isEmpty ? lead.name : lead.company}'
            ' — New Business',
        'dealValue': opportunityAmount ?? (lead.annualRevenue * 0.002),
        'currency': 'USD',
        if (stageId != null) 'stageId': stageId,
        'createContact': true,
      };
      final existingId = existingAccount == null
          ? null
          : _backendId(existingAccount.id);
      if (existingId != null) {
        input['accountId'] = existingId;
      } else {
        input['accountName'] =
            lead.company.isEmpty ? '${lead.name} Co.' : lead.company;
      }
      final res = await _api!.leadConvert(input);

      await Future.wait([
        _refreshLeads(),
        _refreshContacts(),
        _refreshAccounts(),
        _refreshOpportunities(),
      ]);

      final oppId = res['opportunityId'];
      final accId = res['accountId'];
      final conId = res['contactId'];
      final opportunity = opportunityById(RemoteMappers.appId(oppId));
      final account = accountById(RemoteMappers.appId(accId));
      final contact = contactById(RemoteMappers.appId(conId));
      if (opportunity != null && account != null && contact != null) {
        result = LeadConversionResult(
          contact: contact,
          account: account,
          opportunity: opportunity,
        );
      }
    });
    return result;
  }

  // -------------------------------------------------------------------------
  // Contacts
  // -------------------------------------------------------------------------

  void addContact(Contact contact) {
    if (isServerBacked) {
      unawaited(_runServer(() async {
        await _api!.contactCreate(RemoteMappers.contactCreateInput(contact));
        await _refreshContacts();
      }));
      return;
    }
    _contacts.insert(0, contact);
    _logActivity(
      kind: ActivityKind.created,
      title: 'New contact: ${contact.name}',
      relatedType: RecordType.contact,
      relatedId: contact.id,
      relatedName: contact.name,
    );
    _commit();
  }

  void updateContact(Contact contact) {
    if (isServerBacked) {
      unawaited(_runServer(() async {
        await _api!.contactUpdate(RemoteMappers.contactUpdateInput(contact));
        await _refreshContacts();
      }));
      return;
    }
    final index = _contacts.indexWhere((e) => e.id == contact.id);
    if (index == -1) return;
    _contacts[index] = contact;
    _commit();
  }

  void deleteContact(String id) {
    if (isServerBacked) {
      final backendId = _backendId(id);
      if (backendId == null) return;
      unawaited(_runServer(() async {
        await _api!.contactDelete(backendId);
        await _refreshContacts();
      }));
      return;
    }
    _contacts.removeWhere((e) => e.id == id);
    _commit();
  }

  // -------------------------------------------------------------------------
  // Accounts
  // -------------------------------------------------------------------------

  void addAccount(Account account) {
    if (isServerBacked) {
      unawaited(_runServer(() async {
        await _api!.accountCreate(RemoteMappers.accountCreateInput(account));
        await _refreshAccounts();
      }));
      return;
    }
    _accounts.insert(0, account);
    _logActivity(
      kind: ActivityKind.created,
      title: 'New account: ${account.name}',
      relatedType: RecordType.account,
      relatedId: account.id,
      relatedName: account.name,
    );
    _commit();
  }

  void updateAccount(Account account) {
    if (isServerBacked) {
      unawaited(_runServer(() async {
        await _api!.accountUpdate(RemoteMappers.accountUpdateInput(account));
        await _refreshAccounts();
      }));
      return;
    }
    final index = _accounts.indexWhere((e) => e.id == account.id);
    if (index == -1) return;
    _accounts[index] = account;
    _commit();
  }

  void deleteAccount(String id) {
    if (isServerBacked) {
      final backendId = _backendId(id);
      if (backendId == null) return;
      unawaited(_runServer(() async {
        await _api!.accountDelete(backendId);
        await _refreshAccounts();
      }));
      return;
    }
    _accounts.removeWhere((e) => e.id == id);
    _commit();
  }

  // -------------------------------------------------------------------------
  // Opportunities
  // -------------------------------------------------------------------------

  void addOpportunity(Opportunity opportunity) {
    if (isServerBacked) {
      final stageId = _stageIdFor(opportunity.stage);
      unawaited(_runServer(() async {
        await _api!.opportunityCreate(
          RemoteMappers.opportunityCreateInput(opportunity, stageId),
        );
        await _refreshOpportunities();
      }));
      return;
    }
    _opportunities.insert(0, opportunity);
    _logActivity(
      kind: ActivityKind.created,
      title: 'New opportunity: ${opportunity.name}',
      relatedType: RecordType.opportunity,
      relatedId: opportunity.id,
      relatedName: opportunity.name,
    );
    _commit();
  }

  void updateOpportunity(Opportunity opportunity, {bool log = true}) {
    if (isServerBacked) {
      final stageId = _stageIdFor(opportunity.stage);
      unawaited(_runServer(() async {
        await _api!.opportunityUpdate(
          RemoteMappers.opportunityUpdateInput(opportunity, stageId),
        );
        await _refreshOpportunities();
      }));
      return;
    }
    final index = _opportunities.indexWhere((e) => e.id == opportunity.id);
    if (index == -1) return;
    final previous = _opportunities[index];
    _opportunities[index] = opportunity;
    if (log && previous.stage != opportunity.stage) {
      _logActivity(
        kind: ActivityKind.stageChange,
        title: '${opportunity.name} moved to ${opportunity.stage.label}',
        detail: 'Stage changed from ${previous.stage.label} to '
            '${opportunity.stage.label}.',
        relatedType: RecordType.opportunity,
        relatedId: opportunity.id,
        relatedName: opportunity.name,
      );
    }
    _commit();
  }

  void setOpportunityStage(Opportunity opportunity, OpportunityStage stage) {
    if (isServerBacked) {
      final backendId = _backendId(opportunity.id);
      if (backendId == null) return;
      unawaited(_runServer(() async {
        if (stage == OpportunityStage.closedWon ||
            stage == OpportunityStage.closedLost) {
          await _api!.opportunityClose(
            id: backendId,
            isWon: stage == OpportunityStage.closedWon,
            lostReason:
                stage == OpportunityStage.closedLost ? 'Other' : null,
          );
        } else {
          final stageId = _stageIdFor(stage);
          if (stageId != null) {
            await _api!.opportunityMoveStage(backendId, stageId);
          }
        }
        await _refreshOpportunities();
      }));
      return;
    }
    updateOpportunity(
      opportunity.copyWith(
        stage: stage,
        probability: stage.defaultProbability,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void deleteOpportunity(String id) {
    if (isServerBacked) {
      final backendId = _backendId(id);
      if (backendId == null) return;
      unawaited(_runServer(() async {
        await _api!.opportunityDelete(backendId);
        await _refreshOpportunities();
      }));
      return;
    }
    _opportunities.removeWhere((e) => e.id == id);
    _commit();
  }

  // -------------------------------------------------------------------------
  // Tasks & logged activities
  // -------------------------------------------------------------------------

  void addTask(TaskItem task) {
    if (isServerBacked) {
      unawaited(_runServer(() async {
        await _api!.activityCreate(RemoteMappers.taskCreateInput(task));
        await _refreshTasks();
      }));
      return;
    }
    _tasks.insert(0, task);
    _commit();
  }

  void updateTask(TaskItem task) {
    if (isServerBacked) {
      final backendId = _backendId(task.id);
      if (backendId == null) return;
      unawaited(_runServer(() async {
        await _api!.activityUpdate({
          'id': backendId,
          'subject': task.subject,
          if (task.notes.isNotEmpty) 'description': task.notes,
          'priority': task.priority.label.toLowerCase(),
          'dueDate': task.dueDate.toUtc().toIso8601String(),
        });
        await _refreshTasks();
      }));
      return;
    }
    final index = _tasks.indexWhere((e) => e.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
    _commit();
  }

  void toggleTask(TaskItem task) {
    if (isServerBacked) {
      final backendId = _backendId(task.id);
      if (backendId == null) return;
      unawaited(_runServer(() async {
        if (!task.completed) {
          await _api!.activityComplete(backendId);
        } else {
          await _api!.activityUpdate({'id': backendId, 'isCompleted': false});
        }
        await _refreshTasks();
      }));
      return;
    }
    final completed = !task.completed;
    final updated = task.copyWith(
      completed: completed,
      completedAt: completed ? DateTime.now() : null,
      clearCompletedAt: !completed,
    );
    final index = _tasks.indexWhere((e) => e.id == task.id);
    if (index == -1) return;
    _tasks[index] = updated;
    if (completed) {
      _logActivity(
        kind: ActivityKind.taskCompleted,
        title: 'Completed: ${task.subject}',
        relatedType: task.relatedType,
        relatedId: task.relatedId,
        relatedName: task.relatedName,
      );
    }
    _commit();
  }

  void deleteTask(String id) {
    if (isServerBacked) {
      final backendId = _backendId(id);
      if (backendId == null) return;
      unawaited(_runServer(() async {
        await _api!.activityDelete(backendId);
        await _refreshTasks();
      }));
      return;
    }
    _tasks.removeWhere((e) => e.id == id);
    _commit();
  }

  /// Log a call/email/meeting/note against a record (shows in its timeline).
  void logInteraction({
    required ActivityKind kind,
    required String title,
    String detail = '',
    RecordType? relatedType,
    String? relatedId,
    String relatedName = '',
  }) {
    if (isServerBacked && relatedType != null && relatedId != null) {
      unawaited(_runServer(() async {
        await _api!.activityCreate(RemoteMappers.interactionInput(
          kind: kind,
          subject: title,
          detail: detail,
          relatedType: relatedType,
          relatedId: relatedId,
        ));
        await Future.wait([_refreshActivities(), _refreshTasks()]);
      }));
      return;
    }
    _logActivity(
      kind: kind,
      title: title,
      detail: detail,
      relatedType: relatedType,
      relatedId: relatedId,
      relatedName: relatedName,
    );
    _commit();
  }

  // -------------------------------------------------------------------------
  // Notifications
  // -------------------------------------------------------------------------

  int get unreadNotificationCount =>
      _notifications.where((n) => !n.read).length;

  void markNotificationRead(String id) {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    _notifications[index] = _notifications[index].copyWith(read: true);
    notifyListeners();
    if (isServerBacked) {
      final backendId = _backendId(id);
      if (backendId != null) {
        unawaited(_api!.notificationMarkRead(backendId).catchError((_) {}));
      }
    }
  }

  void markAllNotificationsRead() {
    _notifications =
        _notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
    if (isServerBacked) {
      unawaited(_api!.notificationMarkAllRead().catchError((_) {}));
    }
  }

  // -------------------------------------------------------------------------
  // Notes (per record)
  // -------------------------------------------------------------------------

  /// Notes for a record, pinned first then most-recently updated.
  List<Note> notesForRecord(RecordType type, String id) {
    final list = _notes
        .where((n) => n.relatedType == type && n.relatedId == id)
        .toList()
      ..sort((a, b) {
        if (a.pinned != b.pinned) return a.pinned ? -1 : 1;
        return b.updatedAt.compareTo(a.updatedAt);
      });
    return list;
  }

  void addNote(Note note) {
    _notes.insert(0, note);
    _logActivity(
      kind: ActivityKind.note,
      title: 'Note added${note.title.isEmpty ? '' : ': ${note.title}'}',
      detail: note.body,
      relatedType: note.relatedType,
      relatedId: note.relatedId,
    );
    notifyListeners();
    _persistExtras();
    if (isServerBacked) {
      final recordId = _backendId(note.relatedId);
      if (recordId != null) {
        unawaited(_api!
            .noteCreate({
              'recordType': note.relatedType.name,
              'recordId': recordId,
              if (note.title.isNotEmpty) 'title': note.title,
              'body': note.body,
              'pinned': note.pinned,
            })
            .catchError((_) => <String, dynamic>{}));
      }
    }
  }

  void updateNote(Note note) {
    final index = _notes.indexWhere((n) => n.id == note.id);
    if (index == -1) return;
    _notes[index] = note;
    notifyListeners();
    _persistExtras();
    if (isServerBacked) {
      final backendId = _backendId(note.id);
      if (backendId != null) {
        unawaited(_api!
            .noteUpdate({
              'id': backendId,
              'title': note.title,
              'body': note.body,
              'pinned': note.pinned,
            })
            .catchError((_) {}));
      }
    }
  }

  void togglePinNote(Note note) =>
      updateNote(note.copyWith(pinned: !note.pinned));

  void deleteNote(String id) {
    _notes.removeWhere((n) => n.id == id);
    notifyListeners();
    _persistExtras();
    if (isServerBacked) {
      final backendId = _backendId(id);
      if (backendId != null) {
        unawaited(_api!.noteDelete(backendId).catchError((_) {}));
      }
    }
  }

  // -------------------------------------------------------------------------
  // Attachments / files (per record)
  // -------------------------------------------------------------------------

  List<Attachment> attachmentsForRecord(RecordType type, String id) => _attachments
      .where((a) => a.relatedType == type && a.relatedId == id)
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  void addAttachment(Attachment attachment) {
    _attachments.insert(0, attachment);
    _logActivity(
      kind: ActivityKind.note,
      title: '${attachment.kind == AttachmentKind.link ? 'Link' : 'File'} '
          'attached: ${attachment.name}',
      relatedType: attachment.relatedType,
      relatedId: attachment.relatedId,
    );
    notifyListeners();
    _persistExtras();
  }

  void deleteAttachment(String id) {
    _attachments.removeWhere((a) => a.id == id);
    notifyListeners();
    _persistExtras();
    if (isServerBacked) {
      final backendId = _backendId(id);
      if (backendId != null) {
        unawaited(_api!.fileDelete(backendId).catchError((_) {}));
      }
    }
  }

  // -------------------------------------------------------------------------
  // Metrics (dashboard)
  // -------------------------------------------------------------------------

  List<Opportunity> get openOpportunities =>
      _opportunities.where((o) => o.stage.isOpen).toList();

  List<Opportunity> get wonOpportunities => _opportunities
      .where((o) => o.stage == OpportunityStage.closedWon)
      .toList();

  double get pipelineValue =>
      openOpportunities.fold(0, (sum, o) => sum + o.amount);

  double get weightedPipelineValue =>
      openOpportunities.fold(0, (sum, o) => sum + o.expectedRevenue);

  double get wonValueThisQuarter {
    final now = DateTime.now();
    final quarterStart =
        DateTime(now.year, ((now.month - 1) ~/ 3) * 3 + 1, 1);
    return wonOpportunities
        .where((o) => !o.closeDate.isBefore(quarterStart))
        .fold(0, (sum, o) => sum + o.amount);
  }

  double get winRate {
    final closed = _opportunities.where((o) => o.stage.isClosed).length;
    if (closed == 0) return 0;
    return wonOpportunities.length / closed;
  }

  int get openTaskCount => _tasks.where((t) => !t.completed).length;

  List<TaskItem> get tasksDueToday {
    final now = DateTime.now();
    return _tasks.where((t) {
      if (t.completed) return false;
      final d = t.dueDate;
      return d.year == now.year && d.month == now.month && d.day == now.day;
    }).toList();
  }

  List<TaskItem> get overdueTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks
        .where((t) =>
            !t.completed &&
            DateTime(t.dueDate.year, t.dueDate.month, t.dueDate.day)
                .isBefore(today))
        .toList();
  }

  Map<OpportunityStage, List<Opportunity>> get pipelineByStage {
    final map = <OpportunityStage, List<Opportunity>>{
      for (final stage in OpportunityStage.values)
        if (stage.isOpen) stage: [],
    };
    for (final opp in openOpportunities) {
      map[opp.stage]?.add(opp);
    }
    return map;
  }

  int get hotLeadCount => _leads
      .where((l) =>
          l.rating == LeadRating.hot && l.status != LeadStatus.converted)
      .length;

  // -------------------------------------------------------------------------
  // Global search
  // -------------------------------------------------------------------------

  List<SearchResult> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    bool matches(List<String> fields) =>
        fields.any((f) => f.toLowerCase().contains(q));

    final results = <SearchResult>[];
    for (final lead in _leads) {
      if (matches([lead.name, lead.company, lead.email, lead.title])) {
        results.add(SearchResult(
          type: RecordType.lead,
          id: lead.id,
          title: lead.name,
          subtitle: '${lead.title.isEmpty ? 'Lead' : lead.title} · '
              '${lead.company}',
        ));
      }
    }
    for (final contact in _contacts) {
      if (matches([contact.name, contact.email, contact.title])) {
        final account = accountById(contact.accountId);
        results.add(SearchResult(
          type: RecordType.contact,
          id: contact.id,
          title: contact.name,
          subtitle: account == null ? contact.title : account.name,
        ));
      }
    }
    for (final account in _accounts) {
      if (matches([account.name, account.industry, account.billingCity])) {
        results.add(SearchResult(
          type: RecordType.account,
          id: account.id,
          title: account.name,
          subtitle: account.industry,
        ));
      }
    }
    for (final opp in _opportunities) {
      if (matches([opp.name, opp.stage.label])) {
        results.add(SearchResult(
          type: RecordType.opportunity,
          id: opp.id,
          title: opp.name,
          subtitle: opp.stage.label,
        ));
      }
    }
    for (final task in _tasks) {
      if (matches([task.subject, task.relatedName])) {
        results.add(SearchResult(
          type: RecordType.task,
          id: task.id,
          title: task.subject,
          subtitle: task.type.label,
        ));
      }
    }
    return results;
  }
}
