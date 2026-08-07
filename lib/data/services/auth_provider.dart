import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

enum AuthStatus { unknown, unauthenticated, authenticating, authenticated }

/// Handles sign-in, session persistence, and the current user.
///
/// Credentials are validated against a local demo directory so the app works
/// fully offline. Swap [_verifyCredentials] with a real API call to connect a
/// production identity provider (OAuth / OpenID Connect).
class AuthProvider extends ChangeNotifier {
  AuthProvider();

  static const _sessionKey = 'ryse_session_v1';

  /// Demo login directory. Any of these accounts can sign in.
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

  AuthStatus get status => _status;
  AppUser? get user => _user;
  String? get error => _error;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  /// Restore a persisted session on app launch.
  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw != null) {
      try {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        _user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
        _status = AuthStatus.authenticated;
      } catch (_) {
        await prefs.remove(_sessionKey);
        _status = AuthStatus.unauthenticated;
      }
    } else {
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<bool> signIn({
    required String email,
    required String password,
    bool rememberMe = true,
  }) async {
    _status = AuthStatus.authenticating;
    _error = null;
    notifyListeners();

    // Simulated network round-trip.
    await Future<void>.delayed(const Duration(milliseconds: 900));

    final user = _verifyCredentials(email.trim().toLowerCase(), password);
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _error = 'Incorrect email or password. Try the demo account below.';
      notifyListeners();
      return false;
    }

    _user = user;
    _status = AuthStatus.authenticated;

    if (rememberMe) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _sessionKey,
        jsonEncode({
          'user': user.toJson(),
          'issuedAt': DateTime.now().toIso8601String(),
        }),
      );
    }
    notifyListeners();
    return true;
  }

  AppUser? _verifyCredentials(String email, String password) {
    final entry = _directory[email];
    if (entry == null) return null;
    if (entry.password != password) return null;
    return entry.user;
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
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
