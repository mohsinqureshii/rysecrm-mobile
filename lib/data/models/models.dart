import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

// ---------------------------------------------------------------------------
// Enums
// ---------------------------------------------------------------------------

enum LeadStatus {
  newLead('New', AppColors.brandAccent),
  contacted('Contacted', AppColors.warning),
  qualified('Qualified', AppColors.success),
  unqualified('Unqualified', AppColors.info),
  converted('Converted', AppColors.ai);

  const LeadStatus(this.label, this.color);
  final String label;
  final Color color;

  static LeadStatus fromLabel(String label) => LeadStatus.values.firstWhere(
        (s) => s.label == label,
        orElse: () => LeadStatus.newLead,
      );
}

enum LeadRating {
  hot('Hot', AppColors.errorBright),
  warm('Warm', AppColors.warning),
  cold('Cold', AppColors.brandAccent);

  const LeadRating(this.label, this.color);
  final String label;
  final Color color;

  static LeadRating fromLabel(String label) => LeadRating.values.firstWhere(
        (r) => r.label == label,
        orElse: () => LeadRating.warm,
      );
}

enum OpportunityStage {
  prospecting('Prospecting', 0.10),
  qualification('Qualification', 0.25),
  needsAnalysis('Needs Analysis', 0.45),
  proposal('Proposal', 0.65),
  negotiation('Negotiation', 0.80),
  closedWon('Closed Won', 1.0),
  closedLost('Closed Lost', 0.0);

  const OpportunityStage(this.label, this.defaultProbability);
  final String label;
  final double defaultProbability;

  bool get isClosed => this == closedWon || this == closedLost;
  bool get isOpen => !isClosed;

  /// Stages shown on the sales path (open stages + won).
  static List<OpportunityStage> get pathStages => const [
        prospecting,
        qualification,
        needsAnalysis,
        proposal,
        negotiation,
        closedWon,
      ];

  static OpportunityStage fromLabel(String label) =>
      OpportunityStage.values.firstWhere(
        (s) => s.label == label,
        orElse: () => OpportunityStage.prospecting,
      );
}

enum TaskType {
  call('Call', Icons.phone_outlined),
  email('Email', Icons.mail_outline),
  meeting('Meeting', Icons.groups_outlined),
  todo('To-Do', Icons.check_circle_outline),
  demo('Demo', Icons.co_present_outlined);

  const TaskType(this.label, this.icon);
  final String label;
  final IconData icon;

  static TaskType fromLabel(String label) => TaskType.values.firstWhere(
        (t) => t.label == label,
        orElse: () => TaskType.todo,
      );
}

enum TaskPriority {
  high('High', AppColors.errorBright),
  normal('Normal', AppColors.brandAccent),
  low('Low', AppColors.info);

  const TaskPriority(this.label, this.color);
  final String label;
  final Color color;

  static TaskPriority fromLabel(String label) =>
      TaskPriority.values.firstWhere(
        (p) => p.label == label,
        orElse: () => TaskPriority.normal,
      );
}

enum RecordType {
  lead('Lead', 'Leads', Icons.filter_alt_outlined, AppColors.lead),
  contact('Contact', 'Contacts', Icons.person_outline, AppColors.contact),
  account('Account', 'Accounts', Icons.business_outlined, AppColors.account),
  opportunity(
    'Opportunity',
    'Opportunities',
    Icons.emoji_events_outlined,
    AppColors.opportunity,
  ),
  task('Task', 'Tasks', Icons.task_alt, AppColors.task);

  const RecordType(this.label, this.plural, this.icon, this.color);
  final String label;
  final String plural;
  final IconData icon;
  final Color color;

  static RecordType fromLabel(String label) => RecordType.values.firstWhere(
        (t) => t.label == label,
        orElse: () => RecordType.lead,
      );
}

enum ActivityKind {
  call('Call logged', Icons.phone_outlined),
  email('Email sent', Icons.mail_outline),
  meeting('Meeting', Icons.groups_outlined),
  note('Note', Icons.sticky_note_2_outlined),
  stageChange('Stage change', Icons.route_outlined),
  statusChange('Status change', Icons.flag_outlined),
  created('Created', Icons.add_circle_outline),
  updated('Updated', Icons.edit_outlined),
  converted('Converted', Icons.swap_horiz),
  taskCompleted('Task completed', Icons.task_alt);

  const ActivityKind(this.label, this.icon);
  final String label;
  final IconData icon;

  static ActivityKind fromName(String name) => ActivityKind.values.firstWhere(
        (k) => k.name == name,
        orElse: () => ActivityKind.note,
      );
}

// ---------------------------------------------------------------------------
// User
// ---------------------------------------------------------------------------

class AppUser {
  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.title,
    required this.company,
  });

  final String id;
  final String name;
  final String email;
  final String title;
  final String company;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'title': title,
        'company': company,
      };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        title: json['title'] as String? ?? '',
        company: json['company'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// Lead
// ---------------------------------------------------------------------------

class Lead {
  const Lead({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.company,
    this.title = '',
    this.email = '',
    this.phone = '',
    this.website = '',
    this.industry = '',
    this.source = 'Web',
    this.status = LeadStatus.newLead,
    this.rating = LeadRating.warm,
    this.annualRevenue = 0,
    this.city = '',
    this.country = '',
    this.notes = '',
    this.ownerName = '',
    this.aiScore = 50,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String company;
  final String title;
  final String email;
  final String phone;
  final String website;
  final String industry;
  final String source;
  final LeadStatus status;
  final LeadRating rating;
  final double annualRevenue;
  final String city;
  final String country;
  final String notes;
  final String ownerName;
  final int aiScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get name => '$firstName $lastName'.trim();

  Lead copyWith({
    String? firstName,
    String? lastName,
    String? company,
    String? title,
    String? email,
    String? phone,
    String? website,
    String? industry,
    String? source,
    LeadStatus? status,
    LeadRating? rating,
    double? annualRevenue,
    String? city,
    String? country,
    String? notes,
    String? ownerName,
    int? aiScore,
    DateTime? updatedAt,
  }) {
    return Lead(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      company: company ?? this.company,
      title: title ?? this.title,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      website: website ?? this.website,
      industry: industry ?? this.industry,
      source: source ?? this.source,
      status: status ?? this.status,
      rating: rating ?? this.rating,
      annualRevenue: annualRevenue ?? this.annualRevenue,
      city: city ?? this.city,
      country: country ?? this.country,
      notes: notes ?? this.notes,
      ownerName: ownerName ?? this.ownerName,
      aiScore: aiScore ?? this.aiScore,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'company': company,
        'title': title,
        'email': email,
        'phone': phone,
        'website': website,
        'industry': industry,
        'source': source,
        'status': status.label,
        'rating': rating.label,
        'annualRevenue': annualRevenue,
        'city': city,
        'country': country,
        'notes': notes,
        'ownerName': ownerName,
        'aiScore': aiScore,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Lead.fromJson(Map<String, dynamic> json) => Lead(
        id: json['id'] as String,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        company: json['company'] as String? ?? '',
        title: json['title'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        website: json['website'] as String? ?? '',
        industry: json['industry'] as String? ?? '',
        source: json['source'] as String? ?? 'Web',
        status: LeadStatus.fromLabel(json['status'] as String? ?? 'New'),
        rating: LeadRating.fromLabel(json['rating'] as String? ?? 'Warm'),
        annualRevenue: (json['annualRevenue'] as num?)?.toDouble() ?? 0,
        city: json['city'] as String? ?? '',
        country: json['country'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        aiScore: json['aiScore'] as int? ?? 50,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// Contact
// ---------------------------------------------------------------------------

class Contact {
  const Contact({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.accountId,
    this.title = '',
    this.department = '',
    this.email = '',
    this.phone = '',
    this.mobile = '',
    this.notes = '',
    this.ownerName = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? accountId;
  final String title;
  final String department;
  final String email;
  final String phone;
  final String mobile;
  final String notes;
  final String ownerName;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get name => '$firstName $lastName'.trim();

  Contact copyWith({
    String? firstName,
    String? lastName,
    String? accountId,
    String? title,
    String? department,
    String? email,
    String? phone,
    String? mobile,
    String? notes,
    String? ownerName,
    DateTime? updatedAt,
  }) {
    return Contact(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      accountId: accountId ?? this.accountId,
      title: title ?? this.title,
      department: department ?? this.department,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      mobile: mobile ?? this.mobile,
      notes: notes ?? this.notes,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'firstName': firstName,
        'lastName': lastName,
        'accountId': accountId,
        'title': title,
        'department': department,
        'email': email,
        'phone': phone,
        'mobile': mobile,
        'notes': notes,
        'ownerName': ownerName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Contact.fromJson(Map<String, dynamic> json) => Contact(
        id: json['id'] as String,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        accountId: json['accountId'] as String?,
        title: json['title'] as String? ?? '',
        department: json['department'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// Account
// ---------------------------------------------------------------------------

class Account {
  const Account({
    required this.id,
    required this.name,
    this.industry = '',
    this.type = 'Prospect',
    this.website = '',
    this.phone = '',
    this.billingCity = '',
    this.billingCountry = '',
    this.employees = 0,
    this.annualRevenue = 0,
    this.notes = '',
    this.ownerName = '',
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String industry;
  final String type; // Customer, Prospect, Partner
  final String website;
  final String phone;
  final String billingCity;
  final String billingCountry;
  final int employees;
  final double annualRevenue;
  final String notes;
  final String ownerName;
  final DateTime createdAt;
  final DateTime updatedAt;

  Account copyWith({
    String? name,
    String? industry,
    String? type,
    String? website,
    String? phone,
    String? billingCity,
    String? billingCountry,
    int? employees,
    double? annualRevenue,
    String? notes,
    String? ownerName,
    DateTime? updatedAt,
  }) {
    return Account(
      id: id,
      name: name ?? this.name,
      industry: industry ?? this.industry,
      type: type ?? this.type,
      website: website ?? this.website,
      phone: phone ?? this.phone,
      billingCity: billingCity ?? this.billingCity,
      billingCountry: billingCountry ?? this.billingCountry,
      employees: employees ?? this.employees,
      annualRevenue: annualRevenue ?? this.annualRevenue,
      notes: notes ?? this.notes,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'industry': industry,
        'type': type,
        'website': website,
        'phone': phone,
        'billingCity': billingCity,
        'billingCountry': billingCountry,
        'employees': employees,
        'annualRevenue': annualRevenue,
        'notes': notes,
        'ownerName': ownerName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Account.fromJson(Map<String, dynamic> json) => Account(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        industry: json['industry'] as String? ?? '',
        type: json['type'] as String? ?? 'Prospect',
        website: json['website'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        billingCity: json['billingCity'] as String? ?? '',
        billingCountry: json['billingCountry'] as String? ?? '',
        employees: json['employees'] as int? ?? 0,
        annualRevenue: (json['annualRevenue'] as num?)?.toDouble() ?? 0,
        notes: json['notes'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// Opportunity
// ---------------------------------------------------------------------------

class Opportunity {
  const Opportunity({
    required this.id,
    required this.name,
    this.accountId,
    this.contactId,
    this.amount = 0,
    this.stage = OpportunityStage.prospecting,
    this.probability = 0.10,
    required this.closeDate,
    this.source = 'Web',
    this.nextStep = '',
    this.notes = '',
    this.ownerName = '',
    this.aiScore = 50,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final String? accountId;
  final String? contactId;
  final double amount;
  final OpportunityStage stage;
  final double probability;
  final DateTime closeDate;
  final String source;
  final String nextStep;
  final String notes;
  final String ownerName;
  final int aiScore;
  final DateTime createdAt;
  final DateTime updatedAt;

  double get expectedRevenue => amount * probability;

  Opportunity copyWith({
    String? name,
    String? accountId,
    String? contactId,
    double? amount,
    OpportunityStage? stage,
    double? probability,
    DateTime? closeDate,
    String? source,
    String? nextStep,
    String? notes,
    String? ownerName,
    int? aiScore,
    DateTime? updatedAt,
  }) {
    return Opportunity(
      id: id,
      name: name ?? this.name,
      accountId: accountId ?? this.accountId,
      contactId: contactId ?? this.contactId,
      amount: amount ?? this.amount,
      stage: stage ?? this.stage,
      probability: probability ?? this.probability,
      closeDate: closeDate ?? this.closeDate,
      source: source ?? this.source,
      nextStep: nextStep ?? this.nextStep,
      notes: notes ?? this.notes,
      ownerName: ownerName ?? this.ownerName,
      aiScore: aiScore ?? this.aiScore,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'accountId': accountId,
        'contactId': contactId,
        'amount': amount,
        'stage': stage.label,
        'probability': probability,
        'closeDate': closeDate.toIso8601String(),
        'source': source,
        'nextStep': nextStep,
        'notes': notes,
        'ownerName': ownerName,
        'aiScore': aiScore,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory Opportunity.fromJson(Map<String, dynamic> json) => Opportunity(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        accountId: json['accountId'] as String?,
        contactId: json['contactId'] as String?,
        amount: (json['amount'] as num?)?.toDouble() ?? 0,
        stage: OpportunityStage.fromLabel(
          json['stage'] as String? ?? 'Prospecting',
        ),
        probability: (json['probability'] as num?)?.toDouble() ?? 0.1,
        closeDate: DateTime.parse(json['closeDate'] as String),
        source: json['source'] as String? ?? 'Web',
        nextStep: json['nextStep'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        aiScore: json['aiScore'] as int? ?? 50,
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// Task
// ---------------------------------------------------------------------------

class TaskItem {
  const TaskItem({
    required this.id,
    required this.subject,
    this.type = TaskType.todo,
    required this.dueDate,
    this.priority = TaskPriority.normal,
    this.completed = false,
    this.relatedType,
    this.relatedId,
    this.relatedName = '',
    this.notes = '',
    this.ownerName = '',
    required this.createdAt,
    this.completedAt,
  });

  final String id;
  final String subject;
  final TaskType type;
  final DateTime dueDate;
  final TaskPriority priority;
  final bool completed;
  final RecordType? relatedType;
  final String? relatedId;
  final String relatedName;
  final String notes;
  final String ownerName;
  final DateTime createdAt;
  final DateTime? completedAt;

  TaskItem copyWith({
    String? subject,
    TaskType? type,
    DateTime? dueDate,
    TaskPriority? priority,
    bool? completed,
    RecordType? relatedType,
    String? relatedId,
    String? relatedName,
    String? notes,
    String? ownerName,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return TaskItem(
      id: id,
      subject: subject ?? this.subject,
      type: type ?? this.type,
      dueDate: dueDate ?? this.dueDate,
      priority: priority ?? this.priority,
      completed: completed ?? this.completed,
      relatedType: relatedType ?? this.relatedType,
      relatedId: relatedId ?? this.relatedId,
      relatedName: relatedName ?? this.relatedName,
      notes: notes ?? this.notes,
      ownerName: ownerName ?? this.ownerName,
      createdAt: createdAt,
      completedAt:
          clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'type': type.label,
        'dueDate': dueDate.toIso8601String(),
        'priority': priority.label,
        'completed': completed,
        'relatedType': relatedType?.label,
        'relatedId': relatedId,
        'relatedName': relatedName,
        'notes': notes,
        'ownerName': ownerName,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
      };

  factory TaskItem.fromJson(Map<String, dynamic> json) => TaskItem(
        id: json['id'] as String,
        subject: json['subject'] as String? ?? '',
        type: TaskType.fromLabel(json['type'] as String? ?? 'To-Do'),
        dueDate: DateTime.parse(json['dueDate'] as String),
        priority:
            TaskPriority.fromLabel(json['priority'] as String? ?? 'Normal'),
        completed: json['completed'] as bool? ?? false,
        relatedType: json['relatedType'] == null
            ? null
            : RecordType.fromLabel(json['relatedType'] as String),
        relatedId: json['relatedId'] as String?,
        relatedName: json['relatedName'] as String? ?? '',
        notes: json['notes'] as String? ?? '',
        ownerName: json['ownerName'] as String? ?? '',
        createdAt: DateTime.parse(json['createdAt'] as String),
        completedAt: json['completedAt'] == null
            ? null
            : DateTime.parse(json['completedAt'] as String),
      );
}

// ---------------------------------------------------------------------------
// Activity log entry
// ---------------------------------------------------------------------------

class ActivityLog {
  const ActivityLog({
    required this.id,
    required this.kind,
    required this.title,
    this.detail = '',
    required this.timestamp,
    this.relatedType,
    this.relatedId,
    this.relatedName = '',
    this.userName = '',
  });

  final String id;
  final ActivityKind kind;
  final String title;
  final String detail;
  final DateTime timestamp;
  final RecordType? relatedType;
  final String? relatedId;
  final String relatedName;
  final String userName;

  Map<String, dynamic> toJson() => {
        'id': id,
        'kind': kind.name,
        'title': title,
        'detail': detail,
        'timestamp': timestamp.toIso8601String(),
        'relatedType': relatedType?.label,
        'relatedId': relatedId,
        'relatedName': relatedName,
        'userName': userName,
      };

  factory ActivityLog.fromJson(Map<String, dynamic> json) => ActivityLog(
        id: json['id'] as String,
        kind: ActivityKind.fromName(json['kind'] as String? ?? 'note'),
        title: json['title'] as String? ?? '',
        detail: json['detail'] as String? ?? '',
        timestamp: DateTime.parse(json['timestamp'] as String),
        relatedType: json['relatedType'] == null
            ? null
            : RecordType.fromLabel(json['relatedType'] as String),
        relatedId: json['relatedId'] as String?,
        relatedName: json['relatedName'] as String? ?? '',
        userName: json['userName'] as String? ?? '',
      );
}

// ---------------------------------------------------------------------------
// Notification
// ---------------------------------------------------------------------------

class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
    this.read = false,
    this.icon = Icons.notifications_outlined,
    this.relatedType,
    this.relatedId,
  });

  final String id;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool read;
  final IconData icon;
  final RecordType? relatedType;
  final String? relatedId;

  AppNotification copyWith({bool? read}) => AppNotification(
        id: id,
        title: title,
        body: body,
        timestamp: timestamp,
        read: read ?? this.read,
        icon: icon,
        relatedType: relatedType,
        relatedId: relatedId,
      );
}

// ---------------------------------------------------------------------------
// Assistant chat message
// ---------------------------------------------------------------------------

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.isUser,
    required this.text,
    required this.timestamp,
    this.suggestions = const [],
  });

  final String id;
  final bool isUser;
  final String text;
  final DateTime timestamp;
  final List<String> suggestions;
}
