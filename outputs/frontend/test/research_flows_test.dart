import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';

class ContextRepository extends MockResearchRepository {
  final receivedTasks = <String?>[];
  @override
  Future<ChatMessage> chat(
    String message,
    StudyCondition condition,
    Task? task, {
    SupportProfile profile = const SupportProfile(),
    String language = 'en',
  }) {
    receivedTasks.add(task?.id);
    return super.chat(message, condition, task, profile: profile);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer c;
  late AppController app;
  late SharedPreferences prefs;
  late ContextRepository repo;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    repo = ContextRepository();
    c = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        repositoryProvider.overrideWithValue(repo),
      ],
    );
    app = c.read(appProvider.notifier);
    await app.initialize();
  });
  tearDown(() => c.dispose());
  test(
    'quick capture has no artificial deadline and independently saves planned start',
    () async {
      await app.saveTask(const Task(id: 'quick', title: 'Open my draft'));
      final task = c.read(appProvider).tasks.last;
      expect(task.due, isNull);
      expect(task.plannedStart, isNull);
      final planned = DateTime(2027, 1, 3, 10), due = DateTime(2027, 1, 4, 17);
      await app.saveTask(task.copyWith(due: due, plannedStart: planned));
      await app.saveTask(
        c.read(appProvider).tasks.last.copyWith(clearDue: true),
      );
      final restored = AppState.fromJson(
        jsonDecode(prefs.getString(AppController.storageKey)!),
      ).tasks.last;
      expect(restored.due, isNull);
      expect(restored.plannedStart, planned);
      expect(restored.version, 3);
    },
  );
  test(
    'legacy demo records retain chats and dates without inventing measurements',
    () {
      final legacy = {
        'version': 1,
        'consent': true,
        'condition': 'selfAgent',
        'theme': 'system',
        'tasks': [
          {'id': 'old', 'title': 'Legacy', 'due': '2026-10-26T12:00:00'},
        ],
        'chats': {
          'selfAgent': [
            {
              'id': 'm',
              'text': 'Old conversation',
              'user': true,
              'at': '2026-10-26T10:00:00',
            },
          ],
        },
        'events': [
          {
            'kind': 'focus_started',
            'taskId': 'old',
            'at': '2026-10-26T11:00:00',
          },
        ],
        'burden': 'Heavy',
        'focus': {
          'taskId': 'old',
          'remainingSeconds': 450,
          'deadline': null,
          'started': true,
        },
      };
      final restored = AppState.fromJson(legacy);
      expect(restored.tasks.single.due, DateTime(2026, 10, 26, 12));
      expect(restored.messages.single.taskId, isNull);
      expect(restored.checkIns, isEmpty);
      expect(restored.burden, 'Heavy');
      expect(restored.events.single.condition, isNull);
      expect(restored.events.single.offsetMinutes, isNull);
      expect(restored.focus!.durationSeconds, 600);
      expect(restored.focus!.condition, 'unknown');
      expect(
        AppState.fromJson(restored.toJson()).events.single.id,
        restored.events.single.id,
      );
    },
  );
  test(
    'recovery preserves deadline and reason without inferring procrastination',
    () async {
      final original = c.read(appProvider).tasks.first;
      final later = DateTime.now().add(const Duration(days: 2));
      await app.recoverTask(
        original.id,
        'reschedule',
        reason: 'Priorities changed',
        plannedStart: later,
      );
      final changed = c.read(appProvider).tasks.first;
      expect(changed.due, original.due);
      expect(changed.plannedStart, later);
      final event = c.read(appProvider).events.last;
      expect(event.details['procrastinationInferred'], isFalse);
      expect(event.details['reason'], 'Priorities changed');
      await app.recoverTask(original.id, 'pause');
      expect(c.read(appProvider).tasks.first.paused, isTrue);
      await expectLater(
        app.prepareFocus(original.id),
        throwsA(isA<AppFailure>()),
      );
      await app.recoverTask(original.id, 'resume');
      expect(c.read(appProvider).tasks.first.paused, isFalse);
    },
  );
  test(
    'snoozing changes reminder only and refuses completed or past reminders',
    () async {
      final task = c.read(appProvider).tasks.first;
      final later = DateTime.now().add(const Duration(hours: 1));
      await app.snooze(task.id, later);
      expect(c.read(appProvider).tasks.first.reminder, later);
      expect(c.read(appProvider).tasks.first.due, task.due);
      expect(c.read(appProvider).tasks.first.plannedStart, task.plannedStart);
      await expectLater(
        app.snooze(task.id, DateTime(2000)),
        throwsA(isA<AppFailure>()),
      );
      await app.toggleTask(c.read(appProvider).tasks.first);
      await expectLater(app.snooze(task.id, later), throwsA(isA<AppFailure>()));
    },
  );
  test('explicit task initiation is separate from starting a timer', () async {
    final at = DateTime.now();
    await app.startTask('literature', at: at);
    await app.startTask('literature');
    expect(c.read(appProvider).tasks.first.firstStartedAt, at);
    expect(
      c.read(appProvider).events.where((e) => e.kind == 'task_started'),
      hasLength(1),
    );
    expect(c.read(appProvider).focus, isNull);
    final event = c.read(appProvider).events.last;
    expect(event.condition, 'selfAgent');
    expect(event.taskVersion, 2);
    expect(event.toJson()['at'].endsWith('Z'), isTrue);
  });
  test(
    'refinement acceptance keeps original and accepted versions; rejection changes no task',
    () async {
      final task = c.read(appProvider).tasks.last;
      await app.suggestions(task, 0);
      final proposal = c.read(appProvider).events.last;
      await app.rejectSuggestions(task.id, proposal.id);
      expect(c.read(appProvider).tasks.last.subtasks, isEmpty);
      expect(c.read(appProvider).tasks.last.version, task.version);
      await app.acceptSuggestions(task.id, [
        const Subtask('My edited step'),
      ], proposalId: proposal.id);
      final decision = c.read(appProvider).events.last;
      expect(decision.kind, 'refinement_accepted');
      expect(decision.details['before']['title'], task.title);
      expect(decision.details['accepted'][0]['title'], 'My edited step');
    },
  );
  test('stale refinement cannot overwrite a later task edit', () async {
    final task = c.read(appProvider).tasks.last;
    final steps = await app.suggestions(task, 0);
    final proposal = c.read(appProvider).events.last.id;
    await app.saveTask(task.copyWith(title: 'A revised goal'));
    await expectLater(
      app.acceptSuggestions(task.id, steps, proposalId: proposal),
      throwsA(isA<AppFailure>()),
    );
    expect(c.read(appProvider).tasks.last.subtasks, isEmpty);
  });
  test('manual subtasks and recovery remain available to control', () async {
    await app.switchCondition(StudyCondition.standardControl);
    await app.saveTask(
      c
          .read(appProvider)
          .tasks
          .first
          .copyWith(subtasks: [const Subtask('Open notes')]),
    );
    await app.recoverTask('literature', 'pause');
    expect(c.read(appProvider).tasks.first.subtasks.single.title, 'Open notes');
    expect(c.read(appProvider).tasks.first.paused, isTrue);
    await expectLater(
      app.invitationOpened('literature'),
      throwsA(isA<AppFailure>()),
    );
  });
  test(
    'check-ins append immutable dated entries across conditions and restart',
    () async {
      final answers = {'burden': 'Heavy'};
      await app.saveCheckIn('Baseline demo', answers);
      answers['burden'] = 'Light';
      await app.switchCondition(StudyCondition.friendAgent);
      await app.saveCheckIn('Daily', answers);
      final restored = AppState.fromJson(
        jsonDecode(prefs.getString(AppController.storageKey)!),
      );
      expect(restored.checkIns.map((c) => c.answers['burden']), [
        'Heavy',
        'Light',
      ]);
      expect(restored.checkIns.map((c) => c.condition), [
        'selfAgent',
        'friendAgent',
      ]);
      expect(restored.checkIns.map((c) => c.id).toSet(), hasLength(2));
      expect(
        restored.checkIns.first.toJson()['instrumentVersion'],
        'demo-check-in-v1',
      );
      await app.saveCheckIn('Daily', {});
      expect(c.read(appProvider).checkIns, hasLength(2));
    },
  );
  test(
    'both agents use optional preferences while invitations stay opt-in and control-isolated',
    () async {
      await expectLater(
        app.invitationOpened('literature'),
        throwsA(isA<AppFailure>()),
      );
      await app.saveProfile(
        const SupportProfile(
          values: 'Curiosity',
          goal: 'Finish a clear draft',
          brief: true,
          invitations: true,
        ),
      );
      for (final condition in [
        StudyCondition.selfAgent,
        StudyCondition.friendAgent,
      ]) {
        await app.switchCondition(condition);
        await app.send('Help me start', c.read(appProvider).tasks.first);
        expect(c.read(appProvider).messages.last.text, contains('Curiosity'));
        expect(
          c.read(appProvider).messages.last.text,
          contains('Finish a clear draft'),
        );
      }
      await app.invitationOpened('literature');
      await app.switchCondition(StudyCondition.standardControl);
      await expectLater(
        app.invitationOpened('literature'),
        throwsA(isA<AppFailure>()),
      );
    },
  );
  test(
    'retry keeps original task after selection changes and does not duplicate the user message',
    () async {
      repo.failNext = true;
      await expectLater(
        app.send('Original request', c.read(appProvider).tasks.first),
        throwsA(isA<AppFailure>()),
      );
      final failedId = c.read(appProvider).messages.single.id;
      await app.selectChatTask('presentation');
      await app.send(
        'Different text',
        c.read(appProvider).tasks.last,
        retry: true,
        retryMessageId: failedId,
      );
      expect(repo.receivedTasks, ['literature', 'literature']);
      expect(c.read(appProvider).messages, hasLength(2));
      expect(
        c.read(appProvider).messages.every((m) => m.taskId == 'literature'),
        isTrue,
      );
      expect(c.read(appProvider).messages.first.text, 'Original request');
    },
  );
  test('cancelled retries keep history and allow a new message', () async {
    repo.failNext = true;
    await expectLater(app.send('First', null), throwsA(isA<AppFailure>()));
    await app.cancelMessage(c.read(appProvider).messages.single.id);
    await app.send('A new start', null);
    expect(c.read(appProvider).messages, hasLength(3));
    expect(c.read(appProvider).messages.first.delivery, 'cancelled');
  });
  test('interrupted sends restore as retryable after restart', () {
    final state = AppState(
      chats: {
        'selfAgent': [
          ChatMessage(
            id: 'm',
            text: 'Hi',
            user: true,
            at: DateTime.now(),
            taskId: 'literature',
            delivery: 'sending',
          ),
        ],
      },
    );
    expect(
      AppState.fromJson(state.toJson()).messages.single.delivery,
      'failed',
    );
  });
  for (final minutes in [5, 10, 15, 25]) {
    test(
      '$minutes minute focus survives pause and expiry without completing the task',
      () async {
        final at = DateTime.now();
        await app.prepareFocus('literature', minutes: minutes);
        await app.startFocus(at);
        final id = c.read(appProvider).focus!.id;
        await app.pauseFocus(at.add(const Duration(seconds: 30)));
        expect(c.read(appProvider).focus!.remainingSeconds, minutes * 60 - 30);
        await app.switchCondition(StudyCondition.friendAgent);
        await app.startFocus(at.add(const Duration(minutes: 2)));
        await app.endFocus(at: at.add(const Duration(hours: 2)));
        final event = c.read(appProvider).events.last;
        expect(event.seconds, minutes * 60);
        expect(event.details['sessionId'], id);
        expect(event.condition, 'selfAgent');
        expect(c.read(appProvider).tasks.first.done, isFalse);
        expect(c.read(appProvider).tasks.first.firstStartedAt, isNull);
      },
    );
  }
}
