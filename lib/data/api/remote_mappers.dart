import '../../data/models/models.dart';

/// Converts between backend (techbanq_crm) JSON and the app's domain models.
///
/// Backend records use integer primary keys; the app keys records by string
/// id. Server-sourced records are keyed as `srv-<backendId>` so that string
/// foreign keys (e.g. a contact's accountId) resolve against other mapped
/// records without any extra bookkeeping.
class RemoteMappers {
  RemoteMappers._();

  static const _prefix = 'srv-';

  static String appId(Object? backendId) => '$_prefix$backendId';

  /// Extract the backend integer id from an app id like `srv-42`.
  static int? backendId(String appId) {
    if (!appId.startsWith(_prefix)) return null;
    return int.tryParse(appId.substring(_prefix.length));
  }

  // ── Primitive coercion (backend sends decimals & counts as strings) ──

  static double _double(Object? v) {
    if (v == null) return 0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString().replaceAll(',', '')) ?? 0;
  }

  static int _int(Object? v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? fallback;
  }

  static String _string(Object? v) => v?.toString() ?? '';

  static DateTime _date(Object? v, [DateTime? fallback]) {
    if (v is String && v.isNotEmpty) {
      return DateTime.tryParse(v)?.toLocal() ?? (fallback ?? DateTime.now());
    }
    return fallback ?? DateTime.now();
  }

  // ── User ──────────────────────────────────────────────────────────────

  static AppUser user(Map<String, dynamic> j) => AppUser(
        id: appId(j['id']),
        name: _string(j['name']).isEmpty ? 'User' : _string(j['name']),
        email: _string(j['email']),
        title: _string(j['title']).isNotEmpty
            ? _string(j['title'])
            : _roleLabel(_string(j['role'])),
        company: _string(j['department']),
      );

  static String _roleLabel(String role) => switch (role) {
        'admin' => 'Administrator',
        'sales_manager' => 'Sales Manager',
        'sales_rep' => 'Sales Rep',
        'executive' => 'Executive',
        _ => role.isEmpty ? 'User' : role,
      };

  // ── Lead ──────────────────────────────────────────────────────────────

  static LeadStatus _leadStatus(String s) => switch (s) {
        'new' => LeadStatus.newLead,
        'contacted' => LeadStatus.contacted,
        'qualified' => LeadStatus.qualified,
        'converted' => LeadStatus.converted,
        'not_qualified' => LeadStatus.unqualified,
        'archived' => LeadStatus.unqualified,
        _ => LeadStatus.newLead,
      };

  static String leadStatusApi(LeadStatus s) => switch (s) {
        LeadStatus.newLead => 'new',
        LeadStatus.contacted => 'contacted',
        LeadStatus.qualified => 'qualified',
        LeadStatus.converted => 'converted',
        LeadStatus.unqualified => 'not_qualified',
      };

  static LeadRating _leadRating(Map<String, dynamic> j) {
    final raw = _string(j['rating']).toLowerCase();
    final tier = _string(j['aiScoreTier']).toLowerCase();
    final value = raw.isNotEmpty ? raw : tier;
    return switch (value) {
      'hot' => LeadRating.hot,
      'cold' => LeadRating.cold,
      _ => LeadRating.warm,
    };
  }

  static Lead lead(Map<String, dynamic> j) {
    final created = _date(j['createdAt']);
    return Lead(
      id: appId(j['id']),
      firstName: _string(j['firstName']),
      lastName: _string(j['lastName']),
      company: _string(j['companyName']),
      title: _string(j['jobTitle']),
      email: _string(j['email']),
      phone: _string(j['phone']),
      industry: _string(j['industry']),
      source: _string(j['salesChannel']).isEmpty
          ? 'Web'
          : _string(j['salesChannel']),
      status: _leadStatus(_string(j['status'])),
      rating: _leadRating(j),
      annualRevenue: _double(j['annualRevenue']),
      city: _string(j['city']),
      country: _string(j['country']),
      notes: _string(j['notes']),
      ownerName: _string(j['ownerName']),
      aiScore: _int(j['aiScore'], _int(j['leadScore'], 50)),
      createdAt: created,
      updatedAt: _date(j['updatedAt'], created),
    );
  }

  /// App lead → backend `leads.create` input. The backend requires a sales
  /// channel and a product/service classification; we default to a described
  /// service so any lead the app captures is accepted.
  static Map<String, dynamic> leadCreateInput(Lead l) => {
        'firstName': l.firstName,
        'lastName': l.lastName.isEmpty ? '—' : l.lastName,
        'email': l.email.isEmpty ? _placeholderEmail(l.name) : l.email,
        if (l.phone.isNotEmpty) 'phone': l.phone,
        if (l.title.isNotEmpty) 'jobTitle': l.title,
        if (l.company.isNotEmpty) 'companyName': l.company,
        'productOrService': 'service',
        'serviceDescription':
            l.notes.isNotEmpty ? l.notes : 'Inbound interest — ${l.company}',
        'salesChannel': l.source.isEmpty ? 'Web' : l.source,
        'status': leadStatusApi(l.status),
        'rating': l.rating.label.toLowerCase(),
        if (l.industry.isNotEmpty) 'industry': l.industry,
        if (l.annualRevenue > 0)
          'annualRevenue': l.annualRevenue.toStringAsFixed(0),
        if (l.city.isNotEmpty) 'city': l.city,
        if (l.country.isNotEmpty) 'country': l.country,
        if (l.notes.isNotEmpty) 'notes': l.notes,
      };

  static Map<String, dynamic> leadUpdateInput(Lead l) => {
        'id': backendId(l.id),
        'firstName': l.firstName,
        'lastName': l.lastName.isEmpty ? '—' : l.lastName,
        'email': l.email.isEmpty ? _placeholderEmail(l.name) : l.email,
        if (l.phone.isNotEmpty) 'phone': l.phone,
        if (l.title.isNotEmpty) 'jobTitle': l.title,
        if (l.company.isNotEmpty) 'companyName': l.company,
        'salesChannel': l.source.isEmpty ? 'Web' : l.source,
        'status': leadStatusApi(l.status),
        'rating': l.rating.label.toLowerCase(),
        if (l.industry.isNotEmpty) 'industry': l.industry,
        if (l.annualRevenue > 0)
          'annualRevenue': l.annualRevenue.toStringAsFixed(0),
        if (l.city.isNotEmpty) 'city': l.city,
        if (l.country.isNotEmpty) 'country': l.country,
        if (l.notes.isNotEmpty) 'notes': l.notes,
      };

  static String _placeholderEmail(String name) {
    final slug = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '.');
    return '${slug.isEmpty ? 'lead' : slug}@example.com';
  }

  // ── Account ───────────────────────────────────────────────────────────

  static String _accountType(String status) => switch (status) {
        'customer' => 'Customer',
        'inactive' => 'Prospect',
        'archived' => 'Prospect',
        _ => 'Prospect',
      };

  static String accountStatusApi(String type) => switch (type) {
        'Customer' => 'customer',
        'Partner' => 'prospect',
        _ => 'prospect',
      };

  static Account account(Map<String, dynamic> j) {
    final created = _date(j['createdAt']);
    return Account(
      id: appId(j['id']),
      name: _string(j['name']),
      industry: _string(j['industry']),
      type: _accountType(_string(j['status'])),
      website: _string(j['website']),
      phone: _string(j['primaryContactPhone']),
      billingCity: _string(j['city']),
      billingCountry: _string(j['region']),
      employees: _int(j['employeeCountNumeric']),
      annualRevenue: _double(j['annualRevenue']),
      notes: _string(j['notes']),
      ownerName: _string(j['ownerName']),
      createdAt: created,
      updatedAt: _date(j['updatedAt'], created),
    );
  }

  static Map<String, dynamic> accountCreateInput(Account a) => {
        'name': a.name,
        'status': accountStatusApi(a.type),
        if (a.industry.isNotEmpty) 'industry': a.industry,
        if (a.website.isNotEmpty) 'website': a.website,
        if (a.annualRevenue > 0)
          'annualRevenue': a.annualRevenue.toStringAsFixed(0),
        if (a.phone.isNotEmpty) 'primaryContactPhone': a.phone,
        if (a.notes.isNotEmpty) 'notes': a.notes,
      };

  static Map<String, dynamic> accountUpdateInput(Account a) => {
        'id': backendId(a.id),
        ...accountCreateInput(a),
      };

  // ── Contact ───────────────────────────────────────────────────────────

  static Contact contact(Map<String, dynamic> j) {
    final created = _date(j['createdAt']);
    final accountId = j['accountId'];
    return Contact(
      id: appId(j['id']),
      firstName: _string(j['firstName']),
      lastName: _string(j['lastName']),
      accountId: accountId == null ? null : appId(accountId),
      title: _string(j['title']),
      department: _string(j['department']),
      email: _string(j['email']),
      phone: _string(j['phone']),
      mobile: _string(j['mobile']),
      notes: _string(j['description']),
      ownerName: _string(j['ownerName']),
      createdAt: created,
      updatedAt: _date(j['updatedAt'], created),
    );
  }

  static Map<String, dynamic> contactCreateInput(Contact c) => {
        'firstName': c.firstName,
        'lastName': c.lastName,
        if (c.email.isNotEmpty) 'email': c.email,
        if (c.phone.isNotEmpty) 'phone': c.phone,
        if (c.mobile.isNotEmpty) 'mobile': c.mobile,
        if (c.title.isNotEmpty) 'title': c.title,
        if (c.department.isNotEmpty) 'department': c.department,
        if (c.accountId != null) 'accountId': backendId(c.accountId!),
        if (c.notes.isNotEmpty) 'description': c.notes,
      };

  static Map<String, dynamic> contactUpdateInput(Contact c) => {
        'id': backendId(c.id),
        ...contactCreateInput(c),
      };

  // ── Opportunity ───────────────────────────────────────────────────────

  static Opportunity opportunity(
    Map<String, dynamic> j,
    OpportunityStage Function(int? stageId, bool won, bool lost) stageResolver,
  ) {
    final created = _date(j['createdAt']);
    final stage = stageResolver(
      j['stageId'] == null ? null : _int(j['stageId']),
      j['isWon'] == true,
      j['isClosed'] == true && j['isWon'] != true,
    );
    final accountId = j['accountId'];
    return Opportunity(
      id: appId(j['id']),
      name: _string(j['name']),
      accountId: accountId == null ? null : appId(accountId),
      contactId: null,
      amount: _double(j['dealValue']),
      stage: stage,
      probability: _int(j['winProbability'], 10) / 100.0,
      closeDate: _date(j['expectedCloseDate'], created),
      source: _string(j['dealType']),
      nextStep: _string(j['nextSteps']),
      notes: _string(j['dealNotes']),
      ownerName: _string(j['ownerName']),
      aiScore: _int(j['aiScore'], 50),
      createdAt: created,
      updatedAt: _date(j['updatedAt'], created),
    );
  }

  static Map<String, dynamic> opportunityCreateInput(
    Opportunity o,
    int? stageId,
  ) =>
      {
        'name': o.name,
        'accountId': o.accountId == null ? 0 : backendId(o.accountId!),
        'productOrService': 'service',
        'serviceDescription':
            o.notes.isNotEmpty ? o.notes : 'Opportunity — ${o.name}',
        if (stageId != null) 'stageId': stageId,
        'dealValue': o.amount.toStringAsFixed(0),
        'dealCurrency': 'USD',
        'winProbability': (o.probability * 100).round(),
        if (o.nextStep.isNotEmpty) 'dealNotes': o.nextStep,
      };

  static Map<String, dynamic> opportunityUpdateInput(
    Opportunity o,
    int? stageId,
  ) =>
      {
        'id': backendId(o.id),
        'name': o.name,
        if (stageId != null) 'stageId': stageId,
        'dealValue': o.amount.toStringAsFixed(0),
        'winProbability': (o.probability * 100).round(),
        if (o.nextStep.isNotEmpty) 'dealNotes': o.nextStep,
      };

  // ── Activity / Task ───────────────────────────────────────────────────

  static TaskType _taskType(String t) => switch (t) {
        'Call' => TaskType.call,
        'Email' => TaskType.email,
        'Meeting' => TaskType.meeting,
        'Demo' => TaskType.demo,
        _ => TaskType.todo,
      };

  static String taskTypeApi(TaskType t) => switch (t) {
        TaskType.call => 'Call',
        TaskType.email => 'Email',
        TaskType.meeting => 'Meeting',
        TaskType.demo => 'Demo',
        TaskType.todo => 'Task',
      };

  static TaskPriority _priority(String p) => switch (p) {
        'high' => TaskPriority.high,
        'low' => TaskPriority.low,
        _ => TaskPriority.normal,
      };

  static RecordType? _recordType(String t) => switch (t) {
        'lead' => RecordType.lead,
        'opportunity' => RecordType.opportunity,
        'account' => RecordType.account,
        'contact' => RecordType.contact,
        _ => null,
      };

  static String recordTypeApi(RecordType t) => switch (t) {
        RecordType.lead => 'lead',
        RecordType.opportunity => 'opportunity',
        RecordType.account => 'account',
        RecordType.contact => 'contact',
        RecordType.task => 'opportunity',
      };

  static TaskItem task(Map<String, dynamic> j) {
    final created = _date(j['createdAt']);
    final linkedType = _recordType(_string(j['linkedRecordType']));
    final linkedId = j['linkedRecordId'];
    return TaskItem(
      id: appId(j['id']),
      subject: _string(j['subject']),
      type: _taskType(_string(j['type'])),
      dueDate: _date(j['dueDate'], _date(j['activityDate'], created)),
      priority: _priority(_string(j['priority'])),
      completed: j['isCompleted'] == true,
      relatedType: linkedType,
      relatedId: linkedId == null ? null : appId(linkedId),
      relatedName: _string(j['linkedRecordName']),
      notes: _string(j['description']),
      ownerName: _string(j['assignedToName']),
      createdAt: created,
      completedAt: j['isCompleted'] == true ? _date(j['updatedAt']) : null,
    );
  }

  static ActivityKind _activityKind(String type) => switch (type) {
        'Call' => ActivityKind.call,
        'Email' => ActivityKind.email,
        'Meeting' => ActivityKind.meeting,
        'Task' => ActivityKind.taskCompleted,
        _ => ActivityKind.note,
      };

  static ActivityLog activity(Map<String, dynamic> j) {
    final linkedType = _recordType(_string(j['linkedRecordType']));
    final linkedId = j['linkedRecordId'];
    return ActivityLog(
      id: appId(j['id']),
      kind: _activityKind(_string(j['type'])),
      title: _string(j['subject']),
      detail: _string(j['description']).isNotEmpty
          ? _string(j['description'])
          : _string(j['outcome']),
      timestamp: _date(j['activityDate'], _date(j['createdAt'])),
      relatedType: linkedType,
      relatedId: linkedId == null ? null : appId(linkedId),
      relatedName: _string(j['linkedRecordName']),
      userName: _string(j['createdByName']),
    );
  }

  /// App task → backend `activities.create` input.
  static Map<String, dynamic> taskCreateInput(TaskItem t) {
    final linkedType = t.relatedType == null
        ? 'opportunity'
        : recordTypeApi(t.relatedType!);
    final linkedId =
        t.relatedId != null ? backendId(t.relatedId!) : null;
    return {
      'linkedRecordType': linkedType,
      'linkedRecordId': linkedId ?? 0,
      'type': taskTypeApi(t.type),
      'subject': t.subject,
      if (t.notes.isNotEmpty) 'description': t.notes,
      'activityDate': DateTime.now().toUtc().toIso8601String(),
      'dueDate': t.dueDate.toUtc().toIso8601String(),
      'priority': t.priority.label.toLowerCase(),
      'isCompleted': t.completed,
    };
  }

  /// Log-interaction sheet → backend `activities.create` input.
  static Map<String, dynamic> interactionInput({
    required ActivityKind kind,
    required String subject,
    required String detail,
    required RecordType relatedType,
    required String relatedId,
  }) {
    final type = switch (kind) {
      ActivityKind.call => 'Call',
      ActivityKind.email => 'Email',
      ActivityKind.meeting => 'Meeting',
      _ => 'Note',
    };
    return {
      'linkedRecordType': recordTypeApi(relatedType),
      'linkedRecordId': backendId(relatedId) ?? 0,
      'type': type,
      'subject': subject,
      if (detail.isNotEmpty) 'description': detail,
      'activityDate': DateTime.now().toUtc().toIso8601String(),
      'isCompleted': false,
    };
  }

  // ── Notification ──────────────────────────────────────────────────────

  static AppNotification notification(Map<String, dynamic> j) {
    final linkedType = _recordType(_string(j['linkedRecordType']));
    final linkedId = j['linkedRecordId'];
    return AppNotification(
      id: appId(j['id']),
      title: _string(j['title']),
      body: _string(j['body']),
      timestamp: _date(j['createdAt']),
      read: j['isRead'] == true,
      relatedType: linkedType,
      relatedId: linkedId == null ? null : appId(linkedId),
    );
  }
}
