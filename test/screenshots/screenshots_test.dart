// Generates real rendered PNG screenshots of the app's key screens using the
// Flutter software rasterizer (no emulator needed).
//
//   flutter test test/screenshots/screenshots_test.dart --update-goldens
//
// Output PNGs land in test/screenshots/goldens/.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:ryse_crm/core/theme/app_theme.dart';
import 'package:ryse_crm/data/crm_store.dart';
import 'package:ryse_crm/data/services/auth_provider.dart';
import 'package:ryse_crm/features/assistant/assistant_screen.dart';
import 'package:ryse_crm/features/auth/login_screen.dart';
import 'package:ryse_crm/features/calendar/calendar_screen.dart';
import 'package:ryse_crm/features/home/home_screen.dart';
import 'package:ryse_crm/features/leads/lead_detail_screen.dart';
import 'package:ryse_crm/features/leads/leads_screen.dart';
import 'package:ryse_crm/features/menu/menu_screen.dart';
import 'package:ryse_crm/features/opportunities/opportunity_detail_screen.dart';
import 'package:ryse_crm/features/opportunities/pipeline_screen.dart';
import 'package:ryse_crm/features/reports/reports_screen.dart';
import 'package:ryse_crm/features/tasks/tasks_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const double _dpr = 2.0;
const Size _phone = Size(390, 844);

// These goldens are rendered with fonts from a specific SDK layout. On any
// other machine (CI, a teammate's laptop) the fonts are absent and the render
// would differ, so the suite skips itself unless that reference font exists.
final bool _canRun = File(
  '/opt/flutter/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
).existsSync();

Future<void> _loadFonts() async {
  Future<void> load(String family, List<String> paths) async {
    final loader = FontLoader(family);
    for (final path in paths) {
      final file = File(path);
      if (file.existsSync()) {
        loader.addFont(Future.value(file.readAsBytesSync().buffer.asByteData()));
      }
    }
    await loader.load();
  }

  const roboto = [
    '/opt/flutter/engine/src/flutter/txt/third_party/fonts/Roboto-Regular.ttf',
    '/opt/flutter/engine/src/flutter/txt/third_party/fonts/Roboto-Medium.ttf',
    // Emoji glyphs (e.g. the 👋 in the greeting) as an in-family fallback.
    '/usr/share/fonts/truetype/noto/NotoColorEmoji.ttf',
  ];
  await load('Roboto', roboto);
  await load('MaterialIcons', const [
    '/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  ]);
}

void main() {
  if (!_canRun) {
    test('screenshots (skipped outside reference environment)', () {},
        skip: 'Reference fonts not found; run in the golden environment.');
    return;
  }
  setUpAll(_loadFonts);

  Future<({CrmStore store, AuthProvider auth})> seed(
    WidgetTester tester,
  ) async {
    late CrmStore store;
    late AuthProvider auth;
    await tester.runAsync(() async {
      SharedPreferences.setMockInitialValues({});
      store = CrmStore();
      await store.load();
      auth = AuthProvider();
      await auth.signIn(
        email: AuthProvider.demoEmail,
        password: AuthProvider.demoPassword,
      );
    });
    return (store: store, auth: auth);
  }

  Future<void> shoot(
    WidgetTester tester,
    String name,
    Widget screen, {
    CrmStore? store,
    AuthProvider? auth,
    bool settle = true,
  }) async {
    tester.view.devicePixelRatio = _dpr;
    tester.view.physicalSize = Size(_phone.width * _dpr, _phone.height * _dpr);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final app = MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark,
      home: screen,
    );

    final tree = (store == null && auth == null)
        ? app
        : MultiProvider(
            providers: [
              if (auth != null)
                ChangeNotifierProvider<AuthProvider>.value(value: auth),
              if (store != null)
                ChangeNotifierProvider<CrmStore>.value(value: store),
            ],
            child: app,
          );

    await tester.pumpWidget(tree);
    if (settle) {
      await tester.pumpAndSettle(const Duration(milliseconds: 100));
    } else {
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
    }
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/$name.png'),
    );
  }

  testWidgets('01 login', (tester) async {
    final auth = AuthProvider();
    await shoot(tester, '01_login', const LoginScreen(), auth: auth);
  });

  testWidgets('02 dashboard', (tester) async {
    final s = await seed(tester);
    await shoot(tester, '02_dashboard', const HomeScreen(),
        store: s.store, auth: s.auth);
  });

  testWidgets('03 pipeline kanban', (tester) async {
    final s = await seed(tester);
    await shoot(tester, '03_pipeline', const PipelineScreen(),
        store: s.store, auth: s.auth);
  });

  testWidgets('04 leads', (tester) async {
    final s = await seed(tester);
    await shoot(tester, '04_leads', const LeadsScreen(),
        store: s.store, auth: s.auth);
  });

  testWidgets('05 opportunity detail', (tester) async {
    final s = await seed(tester);
    await shoot(
      tester,
      '05_opportunity',
      const OpportunityDetailScreen(opportunityId: 'opp-1'),
      store: s.store,
      auth: s.auth,
    );
  });

  testWidgets('06 lead detail', (tester) async {
    final s = await seed(tester);
    await shoot(
      tester,
      '06_lead_detail',
      const LeadDetailScreen(leadId: 'lead-1'),
      store: s.store,
      auth: s.auth,
    );
  });

  testWidgets('07 assistant', (tester) async {
    final s = await seed(tester);
    await shoot(tester, '07_assistant', const AssistantScreen(),
        store: s.store, auth: s.auth, settle: false);
  });

  testWidgets('08 tasks', (tester) async {
    final s = await seed(tester);
    await shoot(tester, '08_tasks', const TasksScreen(),
        store: s.store, auth: s.auth);
  });

  testWidgets('09 reports', (tester) async {
    final s = await seed(tester);
    await shoot(tester, '09_reports', const ReportsScreen(),
        store: s.store, auth: s.auth);
  });

  testWidgets('10 calendar', (tester) async {
    final s = await seed(tester);
    await shoot(tester, '10_calendar', const CalendarScreen(),
        store: s.store, auth: s.auth);
  });

  testWidgets('11 menu', (tester) async {
    final s = await seed(tester);
    await shoot(tester, '11_menu', const MenuScreen(),
        store: s.store, auth: s.auth);
  });
}
