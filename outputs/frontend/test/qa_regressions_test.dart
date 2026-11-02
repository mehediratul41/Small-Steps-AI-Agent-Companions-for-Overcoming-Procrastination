import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/reminders.dart';
import 'package:small_steps/data/repository.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';
import 'package:small_steps/app/theme.dart';
import 'package:small_steps/app/reminders_controller.dart';
import 'reminders_test.dart' show FakeReminders;
import 'backend_connection_test.dart' show DevelopmentServer;

class WaitingChat extends MockResearchRepository {
  final entered = Completer<void>();
  final reply = Completer<ChatMessage>();
  int calls = 0;
  @override
  Future<ChatMessage> chat(
    String message,
    StudyCondition condition,
    Task? task, {
    SupportProfile profile = const SupportProfile(),
    String language = 'en',
  }) {
    calls++;
    if (!entered.isCompleted) entered.complete();
    return reply.future;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late AppController app;
  late SharedPreferences preferences;
  late WaitingChat repository;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    repository = WaitingChat();
    container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(preferences),
        repositoryProvider.overrideWithValue(repository),
      ],
    );
    app = container.read(appProvider.notifier);
    await app.initialize();
  });
  tearDown(() => container.dispose());
  void finishChat() => repository.reply.complete(
    ChatMessage(
      id: 'response',
      text: 'Your choice.',
      user: false,
      at: DateTime.now(),
    ),
  );

  test(
    'future reminder preserves seconds instead of being dropped as expired',
    () {
      tzdata.initializeTimeZones();
      final now = DateTime.utc(2027, 1, 2, 0, 0, 10);
      final plan = planReminders(
        [
          Task(
            id: 'seconds',
            title: 'Read',
            reminder: DateTime(2027, 1, 2, 9, 0, 40, 250),
          ),
        ],
        const ReminderPreferences(enabled: true),
        tz.getLocation('Asia/Tokyo'),
        now,
      );
      expect(plan.length, 1);
      expect(plan.single.scheduledAt.second, 40);
      expect(plan.single.scheduledAt.millisecond, 250);
    },
  );
  test(
    'unstarted and already-paused timers do not create pause reports',
    () async {
      await app.prepareFocus('literature');
      await app.pauseFocus();
      expect(
        container
            .read(appProvider)
            .events
            .where((e) => e.kind == 'focus_paused'),
        isEmpty,
      );
      await app.startFocus();
      await app.pauseFocus();
      await app.pauseFocus();
      expect(
        container
            .read(appProvider)
            .events
            .where((e) => e.kind == 'focus_paused')
            .length,
        1,
      );
    },
  );
  test('switching conditions cannot relabel a pending conversation', () async {
    final sending = app.send('I feel stuck', null);
    await repository.entered.future;
    try {
      await expectLater(
        app.switchCondition(StudyCondition.friendAgent),
        throwsA(isA<AppFailure>()),
      );
    } finally {
      finishChat();
      await sending;
    }
    expect(container.read(appProvider).condition, StudyCondition.selfAgent);
  });
  test(
    'controller rejects a second submission while a reply is pending',
    () async {
      final sending = app.send('I feel stuck', null);
      await repository.entered.future;
      try {
        await expectLater(
          app
              .send('I feel stuck', null)
              .timeout(const Duration(milliseconds: 150)),
          throwsA(isA<AppFailure>()),
        );
      } finally {
        finishChat();
        await sending;
      }
      expect(repository.calls, 1);
      expect(container.read(appProvider).messages.length, 2);
    },
  );
  test('refresh cannot turn a live sending message into failed', () async {
    final server = DevelopmentServer();
    final api = server.client();
    final entered = Completer<void>(), release = Completer<void>();
    api.dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (r, h) async {
          if (r.path == '/api/chat') {
            entered.complete();
            await release.future;
          }
          h.next(r);
        },
      ),
    );
    await app.connectBackend(
      'http://127.0.0.1:8000',
      'synthetic-token',
      client: api,
    );
    final sending = app.send('Read one paragraph', null);
    await entered.future;
    try {
      final snapshots = server.requests
          .where((r) => r.path == '/api/state')
          .length;
      await app.initialize();
      expect(
        server.requests.where((r) => r.path == '/api/state').length,
        snapshots,
      );
      expect(container.read(appProvider).messages.single.delivery, 'sending');
    } finally {
      release.complete();
      await sending;
    }
  });
  test('completed tasks cannot be sent for another AI breakdown', () async {
    await app.toggleTask(container.read(appProvider).tasks.first);
    final task = container.read(appProvider).tasks.first;
    await expectLater(app.suggestions(task, 0), throwsA(isA<AppFailure>()));
  });
  test('two account connections cannot overlap', () async {
    final firstServer = DevelopmentServer(),
        secondServer = DevelopmentServer(condition: 'friendAgent');
    final firstApi = firstServer.client();
    final entered = Completer<void>(), release = Completer<void>();
    var first = true;
    firstApi.dio.interceptors.insert(
      0,
      InterceptorsWrapper(
        onRequest: (r, h) async {
          if (r.path == '/api/participants/me' && first) {
            first = false;
            entered.complete();
            await release.future;
          }
          h.next(r);
        },
      ),
    );
    final connecting = app.connectBackend(
      'http://127.0.0.1:8000',
      'synthetic-a',
      client: firstApi,
    );
    await entered.future;
    try {
      await expectLater(
        app.send('During connection', null),
        throwsA(isA<AppFailure>()),
      );
      expect(repository.calls, 0);
      final previousTasks = container.read(appProvider).tasks;
      await app.initialize();
      expect(container.read(appProvider).tasks, previousTasks);
      await expectLater(
        app.connectBackend(
          'http://127.0.0.1:8000',
          'synthetic-b',
          client: secondServer.client(),
        ),
        throwsA(isA<AppFailure>()),
      );
    } finally {
      release.complete();
      await connecting;
    }
    expect(container.read(appProvider).condition, StudyCondition.selfAgent);
  });
  test(
    'a proposal from a different demo condition cannot be accepted',
    () async {
      final task = container.read(appProvider).tasks.first;
      final suggestions = await app.suggestions(task, 0);
      final proposal = container.read(appProvider).events.last;
      await app.switchCondition(StudyCondition.friendAgent);
      await expectLater(
        app.acceptSuggestions(task.id, suggestions, proposalId: proposal.id),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test(
    'concurrent writes to a task do not silently replace each other',
    () async {
      final task = container.read(appProvider).tasks.first;
      final saving = app.saveTask(task.copyWith(title: 'First revision'));
      try {
        await expectLater(
          app.saveTask(task.copyWith(title: 'Stale revision')),
          throwsA(isA<AppFailure>()),
        );
      } finally {
        await saving;
      }
      expect(container.read(appProvider).tasks.first.title, 'First revision');
    },
  );
  test(
    'connected notification callbacks cannot open local demo tasks',
    () async {
      final service = FakeReminders();
      final second = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(preferences),
          reminderServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(second.dispose);
      final controller = second.read(appProvider.notifier);
      await controller.initialize();
      final reminders = second.read(remindersProvider.notifier);
      await reminders.initialize();
      await controller.connectBackend(
        'http://127.0.0.1:8000',
        'synthetic',
        client: DevelopmentServer().client(),
      );
      await reminders.refresh();
      service.open('literature');
      expect(second.read(remindersProvider).openedTaskId, isNull);
    },
  );
  test(
    'failed remote burden check-in does not display a false saved value',
    () async {
      final api = DevelopmentServer().client();
      api.dio.interceptors.insert(
        0,
        InterceptorsWrapper(
          onRequest: (r, h) {
            if (r.path == '/api/check-ins') {
              h.reject(
                DioException.connectionError(
                  requestOptions: r,
                  reason: 'synthetic offline',
                ),
              );
            } else {
              h.next(r);
            }
          },
        ),
      );
      await app.connectBackend(
        'http://127.0.0.1:8000',
        'synthetic',
        client: api,
      );
      await expectLater(app.setBurden('Heavy'), throwsA(isA<AppFailure>()));
      expect(container.read(appProvider).burden, isNull);
      expect(container.read(appProvider).checkIns, isEmpty);
    },
  );
  test(
    'retrying a deleted-task message never changes its context to general chat',
    () async {
      final task = container.read(appProvider).tasks.first;
      final sending = app.send('Read this task', task);
      await repository.entered.future;
      repository.reply.completeError(const AppFailure('Synthetic offline'));
      await expectLater(sending, throwsA(isA<AppFailure>()));
      final message = container.read(appProvider).messages.single;
      await app.deleteTask(task.id);
      await expectLater(
        app.send(message.text, null, retry: true, retryMessageId: message.id),
        throwsA(isA<AppFailure>()),
      );
      expect(repository.calls, 1);
      expect(container.read(appProvider).messages.single.taskId, task.id);
      expect(container.read(appProvider).messages.single.delivery, 'failed');
    },
  );
  test('selected chip labels meet 4.5 contrast in light and dark themes', () {
    for (final brightness in Brightness.values) {
      final theme = appTheme(brightness);
      final foreground = theme.chipTheme.labelStyle!.color!.computeLuminance();
      final background = theme.chipTheme.selectedColor!.computeLuminance();
      final high = foreground > background ? foreground : background;
      final low = foreground > background ? background : foreground;
      expect((high + .05) / (low + .05), greaterThanOrEqualTo(4.5));
    }
  });
}
