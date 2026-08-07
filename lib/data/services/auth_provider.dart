import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../api/api_client.dart';
import '../api/api_config.dart';
import '../api/remote_mappers.dart';
import '../api/ryse_api.dart';
import '../models/models.dart';

enum AuthStatus { unknown, unauthenticated, authenticating, authenticated }

/// Handles sign-in, session persistence, and the current user.
///
/// Two modes:
///  - **Server mode**: authenticates against the techbanq_crm backend over
///    tRPC, persisting the httpOnly session cookies so the app stays signed in.
///  - **Demo mode**: validates against a local directory so the app works
///    fully offline for evaluation.
class AuthProvider extends ChangeNotifier {
  AuthProvider();

  static const _sessionKey = 'ryse_session_v2';

  /// Demo login directory (used when [serverMode] is false).
  static const demoEmail = 'demo@ryse.app';
  static const demoPassword = 'RyseDemo1';

  static final Map<String, ({String password, AppUser user})> _directory = {
    demoEmail: (
      password: demoPassword,
      user: const AppUser(
        id: 'user-1',
        name: 'Maq Qureshi',
        email: demoEmail,
        title: 'Account Executive',
        company: 'RYSE',
      ),
    ),
    'maq@techbanq.net': (
      password: demoPassword,
      user: const AppUser(
        id: 'user-2',
        name: 'Maq Qureshi',
        email: 'maq@techbanq.net',
        title: 'Account Executive',
        company: 'TechBanq',
      ),
    ),
  };

  AuthStatus _status = AuthStatus.unknown;
  AppUser? _user;
  String? _error;
  bool _serverMode = false;
  String _serverUrl = ApiConfig.defaultBaseUrl;
  RyseApi? _api;

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  bool get serverMode => _serverMode;
  String get serverUrl => _serverUrl;

  /// The live API client, available only while signed in against the server.
  RyseApi? get api => (_serverMode && isAuthenticated) ? _api : null;

  RyseApi _ensureApi(String baseUrl) {
    final normalized = ApiConfig.normalize(baseUrl);
    _serverUrl = normalized;
    if (_api == null) {
      _api = RyseApi(ApiClient(baseUrl: normalized));
    } else {
      _api!.baseUrl = normalized;
    }
    return _api!;
  }

  /// Restore a persisted session on app launch.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      _serverMode = data['serverMode'] as bool? ?? false;
      _serverUrl = data['serverUrl'] as String? ?? ApiConfig.defaultBaseUrl;

      if (_serverMode) {
        final api = _ensureApi(_serverUrl);
        final cookies = (data['cookies'] as Map?)?.cast<String, String>() ?? {};
        api.loadCookies(cookies);
        // Validate the restored session against the backend.
        final me = await api.me();
        if (me == null) {
          await _clearPersisted();
          _status = AuthStatus.unauthenticated;
        } else {
          _user = RemoteMappers.user(me);
          _status = AuthStatus.authenticated;
        }
      } else {
        _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
        _status = AuthStatus.authenticated;
      }
    } catch (_) {
      await _clearPersisted();
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
    bool rememberMe = true,
    bool serverMode = false,
    String? serverUrl,
  }) async {
    _serverMode = serverMode;
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();

    if (serverMode) {
      return _signInServer(
        email: email.trim(),
        password: password,
        serverUrl: serverUrl ?? _serverUrl,
        rememberMe: rememberMe,
      );
    }
    return _signInDemo(
      email: email.trim().toLowerCase(),
      password: password,
      rememberMe: rememberMe,
    );
  }

  Future<bool> _signInServer({
    required String email,
    required String password,
    required String serverUrl,
    required bool rememberMe,
  }) async {
    final api = _ensureApi(serverUrl);
    try {
      final userJson = await api.login(email, password);
      _user = RemoteMappers.user(userJson);
      _status = AuthStatus.authenticated;
      if (rememberMe) await _persist();
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _error = 'Something went wrong signing in. $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> _signInDemo({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    await Future<void>.delayed(const Duration(milliseconds: 700));
    final entry = _directory[email];
    if (entry == null || entry.password != password) {
      _status = AuthStatus.unauthenticated;
      _error = 'Incorrect email or password. Try the demo account below.';
      notifyListeners();
      return false;
    }
    _user = entry.user;
    _status = AuthStatus.authenticated;
    if (rememberMe) await _persist();
    notifyListeners();
    return true;
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _sessionKey,
      jsonEncode({
        'serverMode': _serverMode,
        'serverUrl': _serverUrl,
        'user': _user?.toJson(),
        'cookies': _serverMode ? (_api?.cookies ?? {}) : {},
        'issuedAt': DateTime.now().toIso8601String(),
      }),
    );
  }

  Future<void> _clearPersisted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  Future<void> signOut() async {
    if (_serverMode && _api != null) {
      await _api!.logout().catchError((_) {});
      _api!.clearCookies();
    }
    await _clearPersisted();
    _user = null;
    _status = AuthStatus.unauthenticated;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}
