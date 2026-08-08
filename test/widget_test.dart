import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ryse_crm/app.dart';
import 'package:ryse_crm/data/crm_store.dart';
import 'package:ryse_crm/data/services/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget buildApp() {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AuthProvider()..restoreSession()),
      ChangeNotifierProvider(create: (_) => CrmStore()..load()),
    ],
    child: const RyseApp(),
  );
}

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('shows login screen when signed out', (tester) async {
    await tester.pumpWidget(buildApp());
    // Let restoreSession resolve.
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    expect(find.text('Welcome to RYSE'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('rejects invalid credentials with an error message',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      'wrong@user.com',
    );
    await tester.enterText(find.byType(TextFormField).at(1), 'badpassword');
    await tester.tap(find.text('Sign in'));
    // Simulated auth round-trip is ~900ms.
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump();

    expect(
      find.textContaining('Incorrect email or password'),
      findsOneWidget,
    );
  });

  testWidgets('signs in with demo credentials and lands on the dashboard',
      (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pump();

    await tester.enterText(
      find.byType(TextFormField).at(0),
      AuthProvider.demoEmail,
    );
    await tester.enterText(
      find.byType(TextFormField).at(1),
      AuthProvider.demoPassword,
    );
    await tester.tap(find.text('Sign in'));
    await tester.pump(const Duration(milliseconds: 1100));
    await tester.pump(const Duration(milliseconds: 100));

    // Dashboard KPIs are visible after login.
    expect(find.text('Open Pipeline'), findsOneWidget);
    expect(find.text('Won This Quarter'), findsOneWidget);
    expect(find.text('RYSE AI Insights'), findsOneWidget);
  });
}
