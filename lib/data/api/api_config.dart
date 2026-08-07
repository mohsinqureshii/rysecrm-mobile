import 'dart:io';

/// Resolves the RYSE backend base URL.
///
/// The techbanq_crm backend serves tRPC at `<baseUrl>/api/trpc`. Because the
/// right host differs by run target, we pick a sensible default and let the
/// user override it on the login screen.
class ApiConfig {
  ApiConfig._();

  /// A compile-time override: `flutter run --dart-define=RYSE_API_URL=...`.
  static const String _fromEnv = String.fromEnvironment('RYSE_API_URL');

  /// Best-effort default base URL for the current platform.
  ///
  /// - Android emulator reaches the host machine at `10.0.2.2`.
  /// - iOS simulator / desktop can use `localhost`.
  /// A real device needs the host's LAN IP — set it on the login screen.
  static String get defaultBaseUrl {
    if (_fromEnv.isNotEmpty) return _fromEnv;
    try {
      if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    } catch (_) {
      // Platform is unavailable (e.g. tests) — fall through.
    }
    return 'http://localhost:3000';
  }

  static String normalize(String raw) {
    var url = raw.trim();
    if (url.isEmpty) return defaultBaseUrl;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://$url';
    }
    // Strip a trailing slash and any accidental /api/trpc suffix.
    url = url.replaceAll(RegExp(r'/+$'), '');
    url = url.replaceAll(RegExp(r'/api/trpc$'), '');
    return url;
  }
}
