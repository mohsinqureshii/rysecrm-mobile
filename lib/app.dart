import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/theme/app_theme.dart';
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
      theme: AppTheme.light,
      home: const _RootGate(),
    );
  }
}

/// Routes to splash / login / main shell based on auth state.
class _RootGate extends StatelessWidget {
  const _RootGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
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
