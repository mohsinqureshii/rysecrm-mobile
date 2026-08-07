import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Raised when a tRPC call fails (network error or a server-side TRPCError).
class ApiException implements Exception {
  ApiException(this.message, {this.code, this.statusCode});

  final String message;
  final String? code; // tRPC error code, e.g. UNAUTHORIZED
  final int? statusCode;

  bool get isUnauthorized =>
      code == 'UNAUTHORIZED' || statusCode == 401;

  @override
  String toString() => 'ApiException($message)';
}

/// Minimal tRPC-over-HTTP client for the techbanq_crm backend.
///
/// The backend uses `superjson`, so request payloads are wrapped as
/// `{"json": <input>}` and responses arrive as
/// `{"result":{"data":{"json": <output>}}}`. Authentication is cookie-based
/// (`crm_access_token` / `crm_refresh_token`); this client keeps a small
/// in-memory cookie jar and replays it on every request, which is exactly
/// what a browser would do.
class ApiClient {
  ApiClient({required this.baseUrl, HttpClient? httpClient})
      : _http = httpClient ?? HttpClient() {
    _http.connectionTimeout = const Duration(seconds: 12);
  }

  String baseUrl;
  final HttpClient _http;
  final Map<String, String> _cookies = {};

  /// Serialized cookies for session persistence.
  Map<String, String> get cookies => Map.unmodifiable(_cookies);

  void loadCookies(Map<String, String> stored) {
    _cookies
      ..clear()
      ..addAll(stored);
  }

  void clearCookies() => _cookies.clear();

  bool get hasSession => _cookies.containsKey('crm_access_token') ||
      _cookies.containsKey('crm_refresh_token');

  Uri _uri(String path, {Object? input}) {
    final base = '$baseUrl/api/trpc/$path';
    if (input == null) return Uri.parse(base);
    final encoded = Uri.encodeComponent(jsonEncode({'json': input}));
    return Uri.parse('$base?input=$encoded');
  }

  String get _cookieHeader =>
      _cookies.entries.map((e) => '${e.key}=${e.value}').join('; ');

  void _captureCookies(HttpClientResponse response) {
    for (final cookie in response.cookies) {
      // maxAge <= 0 (or an expiry in the past) means the server is clearing it.
      final expired = cookie.maxAge != null && cookie.maxAge! <= 0;
      if (expired || cookie.value.isEmpty) {
        _cookies.remove(cookie.name);
      } else {
        _cookies[cookie.name] = cookie.value;
      }
    }
  }

  Future<dynamic> query(String path, {Object? input}) =>
      _send(path, method: 'GET', input: input);

  Future<dynamic> mutate(String path, {Object? input}) =>
      _send(path, method: 'POST', input: input);

  Future<dynamic> _send(
    String path, {
    required String method,
    Object? input,
  }) async {
    late HttpClientResponse response;
    late String body;
    try {
      final HttpClientRequest request;
      if (method == 'GET') {
        request = await _http.getUrl(_uri(path, input: input));
      } else {
        request = await _http.postUrl(_uri(path));
        request.headers.contentType = ContentType.json;
      }
      if (_cookies.isNotEmpty) {
        request.headers.set(HttpHeaders.cookieHeader, _cookieHeader);
      }
      if (method == 'POST') {
        request.add(utf8.encode(jsonEncode({'json': input ?? {}})));
      }
      response = await request.close();
      _captureCookies(response);
      body = await response.transform(utf8.decoder).join();
    } on SocketException catch (e) {
      throw ApiException(
        'Cannot reach the server. Check the URL and that the backend is '
        'running.\n(${e.message})',
      );
    } on HttpException catch (e) {
      throw ApiException('Network error: ${e.message}');
    } on TimeoutException {
      throw ApiException('The server took too long to respond.');
    }

    dynamic decoded;
    try {
      decoded = body.isEmpty ? null : jsonDecode(body);
    } catch (_) {
      throw ApiException(
        'Unexpected response from server (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    if (decoded is Map && decoded['error'] != null) {
      throw _errorFrom(decoded['error'], response.statusCode);
    }
    if (response.statusCode >= 400) {
      throw ApiException(
        'Request failed (HTTP ${response.statusCode}).',
        statusCode: response.statusCode,
      );
    }

    // Unwrap { result: { data: { json: <value> } } }.
    if (decoded is Map) {
      final result = decoded['result'];
      if (result is Map && result['data'] is Map) {
        return (result['data'] as Map)['json'];
      }
    }
    return decoded;
  }

  ApiException _errorFrom(dynamic error, int statusCode) {
    String message = 'Request failed';
    String? code;
    if (error is Map) {
      final json = error['json'];
      final node = json is Map ? json : error;
      message = (node['message'] as String?) ?? message;
      final data = node['data'];
      if (data is Map) code = data['code'] as String?;
    }
    return ApiException(message, code: code, statusCode: statusCode);
  }

  void close() => _http.close(force: true);
}
