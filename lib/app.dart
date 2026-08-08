import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
import 'data/crm_store.dart';
import 'data/services/auth_provider.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/splash_screen.dart';
import 'features/shell/main_shell.dart';

class RyseApp extends StatelessWidget {
  const RyseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RYSE CRM',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      home: const _RootGate(),
    );
  }
}

/// Routes to splash / login / main shell based on auth state, and keeps the
/// [CrmStore] pointed at the right data source (live backend vs demo).
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.status == AuthStatus.authenticated) {
      final store = context.read<CrmStore>();
      final api = auth.api; // null in demo mode
      // Configure the store after this frame to avoid notifying during build.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        store.connect(api);
      });
    }

    switch (auth.status) {
      case AuthStatus.unknown:
        return const SplashScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.authenticating:
        return const LoginScreen();
      case AuthStatus.authenticated:
        return const MainShell();
    }
  }
}
