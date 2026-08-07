import 'package:flutter_test/flutter_test.dart';
import 'package:ryse_crm/data/crm_store.dart';
import 'package:ryse_crm/data/services/auth_provider.dart';
import 'package:ryse_crm/features/assistant/assistant_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthProvider', () {
    test('rejects wrong credentials', () async {
      final auth = AuthProvider();
      final ok = await auth.signIn(
        email: 'nobody@nowhere.com',
        password: 'wrong',
      );
      expect(ok, isFalse);
      expect(auth.isAuthenticated, isFalse);
      expect(auth.error, isNotNull);
    });

    test('accepts demo credentials and persists the session', () async {
      final auth = AuthProvider();
      final ok = await auth.signIn(
        email: AuthProvider.demoEmail,
        password: AuthProvider.demoPassword,
      );
      expect(ok, isTrue);
      expect(auth.isAuthenticated, isTrue);
      expect(auth.user!.email, AuthProvider.demoEmail);

      // A new provider instance restores the same session.
      final restored = AuthProvider();
      await restored.restoreSession();
      expect(restored.isAuthenticated, isTrue);
      expect(restored.user!.email, AuthProvider.demoEmail);
    });

    test('email match is case-insensitive', () async {
      final auth = AuthProvider();
      final ok = await auth.signIn(
        email: AuthProvider.demoEmail.toUpperCase(),
        password: AuthProvider.demoPassword,
      );
      expect(ok, isTrue);
    });

    test('sign out clears the session', () async {
      final auth = AuthProvider();
      await auth.signIn(
        email: AuthProvider.demoEmail,
        password: AuthProvider.demoPassword,
      );
      await auth.signOut();
      expect(auth.isAuthenticated, isFalse);

      final restored = AuthProvider();
      await restored.restoreSession();
      expect(restored.isAuthenticated, isFalse);
    });
  });

  group('AssistantEngine', () {
    late CrmStore store;
    late AssistantEngine engine;

    setUp(() async {
      store = CrmStore();
      await store.load();
      engine = AssistantEngine(store);
    });

    test('summarizes the pipeline with real numbers', () {
      final reply = engine.answer('Summarize my pipeline');
      expect(reply.text, contains('open deals'));
      expect(reply.text, contains('\$'));
    });

    test('identifies deals at risk', () {
      final reply = engine.answer('Which deals are at risk?');
      expect(reply.text, isNotEmpty);
      expect(reply.suggestions, isNotEmpty);
    });

    test('builds a daily plan', () {
      final reply = engine.answer('What should I do today?');
      expect(reply.text, isNotEmpty);
    });

    test('falls back gracefully for unknown queries', () {
      final reply = engine.answer('sing me a song');
      expect(reply.suggestions, AssistantEngine.defaultSuggestions);
    });
  });
}
