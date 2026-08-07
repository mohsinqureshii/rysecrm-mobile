import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

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
  static const _uuid = Uuid();

  final String currentUserName;

  List<Lead> _leads = [];
  List<Contact> _contacts = [];
  List<Account> _accounts = [];
  List<Opportunity> _opportunities = [];
  List<TaskItem> _tasks = [];
  List<ActivityLog> _activities = [];
  List<AppNotification> _notifications = [];

  bool _loaded = false;
  bool get isLoaded => _loaded;

  List<Lead> get leads => List.unmodifiable(_leads);
  List<Contact> get contacts => List.unmodifiable(_contacts);
  List<Account> get accounts => List.unmodifiable(_accounts);
  List<Opportunity> get opportunities => List.unmodifiable(_opportunities);
  List<TaskItem> get tasks => List.unmodifiable(_tasks);
  List<ActivityLog> get activities => List.unmodifiable(_activities);
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  String newId() => _uuid.v4();

  // -------------------------------------------------------------------------
  // Loading & persistence
  // -------------------------------------------------------------------------

  Future<void> load() async {
    if (_loaded) return;
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

  /// Reset all data back to the demo seed.
  Future<void> resetDemoData() async {
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
    _leads.removeWhere((e) => e.id == id);
    _commit();
  }

  /// Salesforce-style conversion: lead becomes contact + account +
  /// opportunity in a single step.
  LeadConversionResult convertLead(Lead lead, {double? opportunityAmount}) {
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

  // -------------------------------------------------------------------------
  // Contacts
  // -------------------------------------------------------------------------

  void addContact(Contact contact) {
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
    final index = _contacts.indexWhere((e) => e.id == contact.id);
    if (index == -1) return;
    _contacts[index] = contact;
    _commit();
  }

  void deleteContact(String id) {
    _contacts.removeWhere((e) => e.id == id);
    _commit();
  }

  // -------------------------------------------------------------------------
  // Accounts
  // -------------------------------------------------------------------------

  void addAccount(Account account) {
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
    final index = _accounts.indexWhere((e) => e.id == account.id);
    if (index == -1) return;
    _accounts[index] = account;
    _commit();
  }

  void deleteAccount(String id) {
    _accounts.removeWhere((e) => e.id == id);
    _commit();
  }

  // -------------------------------------------------------------------------
  // Opportunities
  // -------------------------------------------------------------------------

  void addOpportunity(Opportunity opportunity) {
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
    updateOpportunity(
      opportunity.copyWith(
        stage: stage,
        probability: stage.defaultProbability,
        updatedAt: DateTime.now(),
      ),
    );
  }

  void deleteOpportunity(String id) {
    _opportunities.removeWhere((e) => e.id == id);
    _commit();
  }

  // -------------------------------------------------------------------------
  // Tasks & logged activities
  // -------------------------------------------------------------------------

  void addTask(TaskItem task) {
    _tasks.insert(0, task);
    _commit();
  }

  void updateTask(TaskItem task) {
    final index = _tasks.indexWhere((e) => e.id == task.id);
    if (index == -1) return;
    _tasks[index] = task;
    _commit();
  }

  void toggleTask(TaskItem task) {
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
  }

  void markAllNotificationsRead() {
    _notifications =
        _notifications.map((n) => n.copyWith(read: true)).toList();
    notifyListeners();
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
