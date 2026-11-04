import 'dart:convert';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/app/chat_memory.dart';
import 'package:small_steps/app/app.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';
import 'package:small_steps/data/saved_connections.dart';

class AccountApi extends ApiResearchRepository {
  final StudyCondition condition;
  final bool unavailable;
  AccountApi(this.condition, {this.unavailable = false})
    : super('http://127.0.0.1:8000');
  String get accountId => condition == StudyCondition.selfAgent
      ? 'DEV-SELF-TEST'
      : 'DEV-FRIEND-TEST';
  @override
  Future<StudyParticipant> participant() async {
    if (unavailable) throw StateError('Service unavailable');
    assignment = {
      'id': accountId,
      'condition': condition.name,
      'mode': 'development',
      'onboarded': true,
    };
    return StudyParticipant(accountId, condition);
  }

  @override
  Future<Map<String, dynamic>> snapshot() async => {
    'participant': {'id': accountId, 'condition': condition.name},
    'tasks': [Task(id: accountId, title: accountId).toJson()],
    'events': [],
    'profile': {},
    'checkIns': [],
    'messages': [
      ChatMessage(
        id: accountId,
        text: accountId,
        user: false,
        at: DateTime(2026),
      ).toJson(),
    ],
  };
  @override
  Future<void> saveEvents(List<BehaviorEvent> events) async {}
  @override
  Future<void> eraseDevelopmentData() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences preferences;
  late MemoryConnectionStorage storage;
  late ProviderContainer c;
  bool unavailable = false;
  ProviderContainer makeContainer() => ProviderContainer(
    overrides: [
      preferencesProvider.overrideWithValue(preferences),
      connectionStorageProvider.overrideWithValue(storage),
      apiFactoryProvider.overrideWithValue(
        (url, token) => AccountApi(
          token == 'friend-token'
              ? StudyCondition.friendAgent
              : StudyCondition.selfAgent,
          unavailable: unavailable,
        ),
      ),
    ],
  );
  setUp(() async {
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({
      AppController.storageKey: jsonEncode(
        const AppState(loaded: true, consent: true).toJson(),
      ),
    });
    preferences = await SharedPreferences.getInstance();
    storage = MemoryConnectionStorage();
    unavailable = false;
    c = makeContainer();
    await c.read(appProvider.notifier).initialize();
  });
  tearDown(() => c.dispose());

  Future<void> linkBoth() async {
    final app = c.read(appProvider.notifier);
    await app.connectBackend(
      'http://127.0.0.1:8000',
      'self-token',
      remember: true,
    );
    await app.disconnectBackend();
    await app.connectBackend(
      'http://127.0.0.1:8000',
      'friend-token',
      remember: true,
    );
  }

  test('stale editor cannot overwrite a newer locally loaded task', () async {
    const original = Task(id: 'edit-test', title: 'Original');
    final app = c.read(appProvider.notifier);
    await app.saveTask(original);
    await app.saveTask(original.copyWith(title: 'Newer edit'));
    await expectLater(
      app.saveTask(original.copyWith(description: 'Stale form')),
      throwsA(isA<AppFailure>()),
    );
    expect(c.read(appProvider).tasks.single.title, 'Newer edit');
    expect(c.read(appProvider).tasks.single.version, 2);
  });

  test(
    'live switch opens correct account and separate tasks/history',
    () async {
      await linkBoth();
      final app = c.read(appProvider.notifier);
      expect(app.canSwitchLiveTo(StudyCondition.selfAgent), isTrue);
      expect(c.read(appProvider).messages.single.text, 'DEV-FRIEND-TEST');
      await app.switchLiveAgent(StudyCondition.selfAgent);
      expect(c.read(appProvider).backendId, 'DEV-SELF-TEST');
      expect(c.read(appProvider).tasks.single.id, 'DEV-SELF-TEST');
      expect(c.read(appProvider).messages.single.text, 'DEV-SELF-TEST');
      await app.switchLiveAgent(StudyCondition.friendAgent);
      expect(c.read(appProvider).messages.single.text, 'DEV-FRIEND-TEST');
      expect(app.canSwitchLiveTo(StudyCondition.standardControl), isFalse);
      await expectLater(
        app.switchCondition(StudyCondition.selfAgent),
        throwsA(isA<AppFailure>()),
      );
      expect(
        preferences.getKeys().any(
          (key) =>
              (preferences.get(key)?.toString() ?? '').contains('friend-token'),
        ),
        isFalse,
      );
    },
  );
  testWidgets('chat route stays open during live account transition', (
    tester,
  ) async {
    await tester.runAsync(linkBoth);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(routerConfig: c.read(routerProvider)),
      ),
    );
    await tester.pumpAndSettle();
    c.read(routerProvider).go('/chat');
    await tester.pumpAndSettle();
    await tester.runAsync(
      () => c
          .read(appProvider.notifier)
          .switchLiveAgent(StudyCondition.selfAgent),
    );
    await tester.pumpAndSettle();
    expect(c.read(appProvider).condition, StudyCondition.selfAgent);
    expect(
      c.read(routerProvider).routeInformationProvider.value.uri.path,
      '/chat',
    );
    expect(find.text('DEV-SELF-TEST'), findsWidgets);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
  });
  test('nonremembered connection clears automatic restoration', () async {
    await linkBoth();
    await c.read(appProvider.notifier).disconnectBackend();
    await c
        .read(appProvider.notifier)
        .connectBackend('http://127.0.0.1:8000', 'self-token');
    c.dispose();
    c = makeContainer();
    await c.read(appProvider.notifier).initialize();
    expect(c.read(appProvider).connected, isFalse);
  });
  test('restart restores remembered assignment and history', () async {
    await linkBoth();
    c.dispose();
    c = makeContainer();
    await c.read(appProvider.notifier).initialize();
    expect(c.read(appProvider).connected, isTrue);
    expect(c.read(appProvider).condition, StudyCondition.friendAgent);
    expect(c.read(appProvider).messages.single.text, 'DEV-FRIEND-TEST');
  });
  test(
    'live account drafts stay isolated across switching and clear on explicit disconnect',
    () async {
      await linkBoth();
      final memory = c.read(chatMemoryProvider.notifier);
      final friend = chatKey(c.read(appProvider), '__general__');
      memory.draft(friend, 'Friend private draft');
      await c
          .read(appProvider.notifier)
          .switchLiveAgent(StudyCondition.selfAgent);
      final self = chatKey(c.read(appProvider), '__general__');
      expect(c.read(chatMemoryProvider).drafts[self], isNull);
      memory.draft(self, 'Self private draft');
      await c
          .read(appProvider.notifier)
          .switchLiveAgent(StudyCondition.friendAgent);
      expect(c.read(chatMemoryProvider).drafts[friend], 'Friend private draft');
      await c.read(appProvider.notifier).disconnectBackend();
      expect(c.read(chatMemoryProvider).drafts[friend], isNull);
      expect(c.read(chatMemoryProvider).drafts[self], 'Self private draft');
    },
  );
  test('offline restoration does not silently send a mock response', () async {
    await linkBoth();
    unavailable = true;
    c.dispose();
    c = makeContainer();
    await c.read(appProvider.notifier).initialize();
    expect(
      c.read(appProvider).error,
      contains('Saved AI connection unavailable'),
    );
    await expectLater(
      c.read(appProvider.notifier).send('hello', null),
      throwsA(isA<AppFailure>()),
    );
  });
  test(
    'saved connection retry restores the same owned account without demo fallback',
    () async {
      await linkBoth();
      unavailable = true;
      c.dispose();
      c = makeContainer();
      await c.read(appProvider.notifier).initialize();
      expect(c.read(appProvider.notifier).needsConnectionRecovery, true);
      await expectLater(
        c.read(appProvider.notifier).retrySavedConnection(),
        throwsStateError,
      );
      expect(c.read(appProvider.notifier).needsConnectionRecovery, true);
      unavailable = false;
      await c.read(appProvider.notifier).retrySavedConnection();
      expect(c.read(appProvider.notifier).needsConnectionRecovery, false);
      expect(c.read(appProvider).backendId, 'DEV-FRIEND-TEST');
      expect(c.read(appProvider).messages.single.text, 'DEV-FRIEND-TEST');
    },
  );
  testWidgets(
    'blocked restored chat exposes retry and resumes only after authenticated recovery',
    (tester) async {
      await tester.runAsync(() async {
        await linkBoth();
        unavailable = true;
        c.dispose();
        c = makeContainer();
        await c.read(appProvider.notifier).initialize();
      });
      await tester.pumpWidget(
        UncontrolledProviderScope(container: c, child: const SmallStepsApp()),
      );
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      expect(find.text('Retry connection'), findsOneWidget);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).enabled,
        false,
      );
      unavailable = false;
      await tester.runAsync(() async {
        await tester.tap(find.text('Retry connection'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(c.read(appProvider).connected, true);
      expect(find.text('Retry connection'), findsNothing);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).enabled,
        true,
      );
      await tester.pumpWidget(const SizedBox());
    },
  );
  test('offline target leaves existing live account unchanged', () async {
    await linkBoth();
    unavailable = true;
    await expectLater(
      c.read(appProvider.notifier).switchLiveAgent(StudyCondition.selfAgent),
      throwsStateError,
    );
    expect(c.read(appProvider).backendId, 'DEV-FRIEND-TEST');
  });
  test(
    'saved identity mismatch cannot restore a different same-condition account',
    () async {
      await c
          .read(savedConnectionsProvider.notifier)
          .remember(
            const SavedConnection(
              'http://127.0.0.1:8000',
              'self-token',
              'DEV-WRONG-ID',
              StudyCondition.selfAgent,
            ),
          );
      c.dispose();
      c = makeContainer();
      await c.read(appProvider.notifier).initialize();
      expect(c.read(appProvider).connected, isFalse);
      expect(
        c.read(appProvider).error,
        contains('Saved AI connection unavailable'),
      );
    },
  );
  test(
    'failed restoration also blocks task writes and refinement in mock mode',
    () async {
      await linkBoth();
      unavailable = true;
      c.dispose();
      c = makeContainer();
      await c.read(appProvider.notifier).initialize();
      const task = Task(id: 'test', title: 'Synthetic');
      await expectLater(
        c.read(appProvider.notifier).saveTask(task),
        throwsA(isA<AppFailure>()),
      );
      await expectLater(
        c.read(appProvider.notifier).suggestions(task, 0),
        throwsA(isA<AppFailure>()),
      );
      expect(c.read(appProvider).tasks, isEmpty);
    },
  );
  test('erasure forgets only the erased account credential', () async {
    await linkBoth();
    await c.read(appProvider.notifier).eraseDevelopmentData();
    final saved = c.read(savedConnectionsProvider);
    expect(saved.containsKey(StudyCondition.friendAgent), isFalse);
    expect(saved.containsKey(StudyCondition.selfAgent), isTrue);
    expect(c.read(savedConnectionsProvider.notifier).active, isNull);
    c.dispose();
    c = makeContainer();
    await c.read(appProvider.notifier).initialize();
    expect(c.read(appProvider).connected, isFalse);
  });
  test(
    'unlinked accounts remain locked and forgetting clears credentials',
    () async {
      final app = c.read(appProvider.notifier);
      await app.connectBackend(
        'http://127.0.0.1:8000',
        'self-token',
        remember: true,
      );
      expect(app.canSwitchLiveTo(StudyCondition.friendAgent), isFalse);
      await expectLater(
        app.switchLiveAgent(StudyCondition.friendAgent),
        throwsA(isA<AppFailure>()),
      );
      await app.disconnectBackend();
      await app.forgetSavedDevelopmentAccounts();
      expect(storage.value, isNull);
      expect(c.read(savedConnectionsProvider), isEmpty);
    },
  );
}
