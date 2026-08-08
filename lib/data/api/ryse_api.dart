import 'api_client.dart';

/// Typed wrapper over [ApiClient] exposing the techbanq_crm tRPC procedures
/// the mobile app uses. Method names mirror the backend routers
/// (`<router>.<procedure>`).
class RyseApi {
  RyseApi(this.client);

  final ApiClient client;

  String get baseUrl => client.baseUrl;
  set baseUrl(String value) => client.baseUrl = value;

  Map<String, String> get cookies => client.cookies;
  void loadCookies(Map<String, String> stored) => client.loadCookies(stored);
  void clearCookies() => client.clearCookies();

  List<Map<String, dynamic>> _asList(dynamic value) {
    if (value is List) {
      return value.whereType<Map>().map((e) => e.cast<String, dynamic>())
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> _asMap(dynamic value) =>
      value is Map ? value.cast<String, dynamic>() : <String, dynamic>{};

  // ─── Auth ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final data = await client.mutate('auth.login', input: {
      'email': email,
      'password': password,
    });
    return _asMap(_asMap(data)['user']);
  }

  Future<void> logout() => client.mutate('auth.logout');

  Future<Map<String, dynamic>?> me() async {
    final data = await client.query('auth.me');
    if (data == null) return null;
    return _asMap(data);
  }

  // ─── Leads ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> leadsList({int limit = 200}) async {
    final data = await client.query('leads.list', input: {'limit': limit});
    return _asList(_asMap(data)['data']);
  }

  Future<Map<String, dynamic>> leadCreate(Map<String, dynamic> input) async =>
      _asMap(await client.mutate('leads.create', input: input));

  Future<void> leadUpdate(Map<String, dynamic> input) =>
      client.mutate('leads.update', input: input);

  Future<void> leadDelete(int id) =>
      client.mutate('leads.delete', input: {'id': id});

  Future<Map<String, dynamic>> leadConvert(Map<String, dynamic> input) async =>
      _asMap(await client.mutate('leads.convert', input: input));

  // ─── Contacts ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> contactsList({int limit = 200}) async {
    final data = await client.query('contacts.list', input: {'limit': limit});
    return _asList(_asMap(data)['data']);
  }

  Future<Map<String, dynamic>> contactCreate(
          Map<String, dynamic> input) async =>
      _asMap(await client.mutate('contacts.create', input: input));

  Future<void> contactUpdate(Map<String, dynamic> input) =>
      client.mutate('contacts.update', input: input);

  Future<void> contactDelete(int id) =>
      client.mutate('contacts.delete', input: {'id': id});

  // ─── Accounts ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> accountsList({int limit = 200}) async {
    final data = await client.query('accounts.list', input: {'limit': limit});
    return _asList(_asMap(data)['data']);
  }

  Future<Map<String, dynamic>> accountCreate(
          Map<String, dynamic> input) async =>
      _asMap(await client.mutate('accounts.create', input: input));

  Future<void> accountUpdate(Map<String, dynamic> input) =>
      client.mutate('accounts.update', input: input);

  Future<void> accountDelete(int id) =>
      client.mutate('accounts.delete', input: {'id': id});

  // ─── Opportunities ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> opportunitiesList({int limit = 500}) async {
    final data =
        await client.query('opportunities.list', input: {'limit': limit});
    return _asList(_asMap(data)['data']);
  }

  Future<Map<String, dynamic>> opportunityCreate(
          Map<String, dynamic> input) async =>
      _asMap(await client.mutate('opportunities.create', input: input));

  Future<void> opportunityUpdate(Map<String, dynamic> input) =>
      client.mutate('opportunities.update', input: input);

  Future<void> opportunityMoveStage(int id, int stageId) =>
      client.mutate('opportunities.moveStage', input: {
        'id': id,
        'stageId': stageId,
      });

  Future<void> opportunityClose({
    required int id,
    required bool isWon,
    String? lostReason,
  }) =>
      client.mutate('opportunities.close', input: {
        'id': id,
        'isWon': isWon,
        if (lostReason != null) 'lostReason': lostReason,
      });

  Future<void> opportunityDelete(int id) =>
      client.mutate('opportunities.delete', input: {'id': id});

  // ─── Pipeline ────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> pipelineStages({int? productId}) async {
    final data = await client.query('pipeline.getStages', input: {
      'productId': productId,
    });
    return _asList(data);
  }

  // ─── Activities & tasks ──────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> myTasks() async =>
      _asList(await client.query('activities.myTasks'));

  Future<List<Map<String, dynamic>>> activitiesForRecord(
    String recordType,
    int recordId,
  ) async {
    final data = await client.query('activities.list', input: {
      'recordType': recordType,
      'recordId': recordId,
    });
    return _asList(data);
  }

  Future<Map<String, dynamic>> activityCreate(
          Map<String, dynamic> input) async =>
      _asMap(await client.mutate('activities.create', input: input));

  Future<void> activityComplete(int id) =>
      client.mutate('activities.complete', input: {'id': id});

  Future<void> activityUpdate(Map<String, dynamic> input) =>
      client.mutate('activities.update', input: input);

  Future<void> activityDelete(int id) =>
      client.mutate('activities.delete', input: {'id': id});

  // ─── Dashboard ───────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> activityFeed({int limit = 20}) async {
    final data = await client.query('dashboard.activityFeed', input: {
      'limit': limit,
    });
    return _asList(data);
  }

  Future<Map<String, dynamic>> dashboardOverview() async =>
      _asMap(await client.query('dashboard.overview', input: {}));

  // ─── Notifications ───────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> notificationsList() async =>
      _asList(await client.query('notifications.list'));

  Future<int> notificationsUnreadCount() async {
    final data = _asMap(await client.query('notifications.unreadCount'));
    final count = data['count'];
    return count is int ? count : int.tryParse('$count') ?? 0;
  }

  Future<void> notificationMarkRead(int id) =>
      client.mutate('notifications.markRead', input: {'id': id});

  Future<void> notificationMarkAllRead() =>
      client.mutate('notifications.markAllRead');

  // ─── Search ──────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> searchGlobal(String query) async =>
      _asMap(await client.query('search.global', input: {'query': query}));

  // ─── Notes ───────────────────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> notesList(
    String recordType,
    int recordId,
  ) async {
    final data = await client.query('notes.list', input: {
      'recordType': recordType,
      'recordId': recordId,
    });
    return _asList(data);
  }

  Future<Map<String, dynamic>> noteCreate(Map<String, dynamic> input) async =>
      _asMap(await client.mutate('notes.create', input: input));

  Future<void> noteUpdate(Map<String, dynamic> input) =>
      client.mutate('notes.update', input: input);

  Future<void> noteDelete(int id) =>
      client.mutate('notes.delete', input: {'id': id});

  Future<void> noteTogglePin(int id) =>
      client.mutate('notes.togglePin', input: {'id': id});

  // ─── Files / attachments ─────────────────────────────────────────────────

  Future<List<Map<String, dynamic>>> filesList(
    String recordType,
    int recordId,
  ) async {
    final data = await client.query('files.list', input: {
      'recordType': recordType,
      'recordId': recordId,
    });
    return _asList(data);
  }

  Future<void> fileDelete(int id) =>
      client.mutate('files.delete', input: {'id': id});

  // ─── Quick add (natural-language capture) ────────────────────────────────

  Future<Map<String, dynamic>> quickAddParse(String text) async =>
      _asMap(await client.mutate('quickAdd.parse', input: {'text': text}));

  Future<Map<String, dynamic>> quickAddCreate(
          Map<String, dynamic> input) async =>
      _asMap(await client.mutate('quickAdd.create', input: input));

  // ─── Lead capture (business card / QR) ───────────────────────────────────

  Future<Map<String, dynamic>> leadCaptureParseCard(String imageData) async =>
      _asMap(await client.mutate('leadCapture.parseCard',
          input: {'image': imageData}));

  Future<Map<String, dynamic>> leadCaptureParseQr(String payload) async =>
      _asMap(
          await client.mutate('leadCapture.parseQr', input: {'data': payload}));

  Future<Map<String, dynamic>> leadCaptureCreate(
          Map<String, dynamic> input) async =>
      _asMap(await client.mutate('leadCapture.create', input: input));
}
