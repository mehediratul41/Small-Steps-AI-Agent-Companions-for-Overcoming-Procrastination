import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';

// Explicitly opt in: this writes synthetic records and makes two Gemini calls.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final enabled = Platform.environment['SMALL_STEPS_LIVE_TEST'] == 'true';
  test(
    'live Flutter controller through FastAPI and Gemini',
    () async {
      // Explicit opt-in integration test: use real HTTP rather than Flutter's fake client.
      final previousHttpOverrides = HttpOverrides.current;
      HttpOverrides.global = null;
      addTearDown(() => HttpOverrides.global = previousHttpOverrides);
      final credentialFile = Platform.environment['SMALL_STEPS_TOKEN_FILE']!;
      final credential =
          jsonDecode(await File(credentialFile).readAsString()) as Map;
      final token = credential['token'] as String;
      final baseUrl =
          Platform.environment['SMALL_STEPS_API_URL'] ??
          'http://127.0.0.1:8000';
      SharedPreferences.setMockInitialValues({});
      final preferences = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(preferences)],
      );
      addTearDown(container.dispose);
      final api = ApiResearchRepository(baseUrl, token: token);
      final app = container.read(appProvider.notifier);
      await app.initialize();
      await app.connectBackend(baseUrl, token, client: api);
      if (!container.read(appProvider).consent) await app.acceptConsent();
      expect(container.read(appProvider).connected, isTrue);
      final id = 'connection_${DateTime.now().microsecondsSinceEpoch}';
      await app.saveTask(
        Task(
          id: id,
          title: 'Synthetic integration check: read one paragraph',
          due: DateTime.now().add(const Duration(days: 1)),
        ),
      );
      Task current() =>
          container.read(appProvider).tasks.singleWhere((t) => t.id == id);
      expect(current().version, 1);
      if (container.read(appProvider).condition.hasAgent) {
        final suggestions = await app.suggestions(current(), 0);
        final proposal = container
            .read(appProvider)
            .events
            .lastWhere(
              (e) => e.kind == 'refinement_proposed' && e.taskId == id,
            );
        expect(current().subtasks, isEmpty);
        await app.acceptSuggestions(id, suggestions, proposalId: proposal.id);
        expect(current().subtasks, isNotEmpty);
        await app.send(
          'This is a synthetic connection test. Suggest one small first step.',
          current(),
        );
        expect(container.read(appProvider).messages.last.user, isFalse);
        expect(container.read(appProvider).messages.last.text, isNotEmpty);
      }
      await app.startTask(id);
      await app.prepareFocus(id);
      await app.startFocus();
      await app.pauseFocus();
      await app.endFocus(reflection: 'Synthetic integration test only.');
      expect(current().done, isFalse);
      await app.toggleTask(current());
      expect(current().done, isTrue);
      await app.initialize();
      expect(current().done, isTrue);
      expect(container.read(appProvider).error, isNull);
      await app.deleteTask(id);
      expect(container.read(appProvider).tasks.any((t) => t.id == id), isFalse);
      await app.disconnectBackend();
      expect(container.read(appProvider).connected, isFalse);
    },
    skip: !enabled,
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
