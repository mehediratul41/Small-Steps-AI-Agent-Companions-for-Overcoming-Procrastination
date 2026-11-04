import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:small_steps/app/app.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/app/reminders_controller.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/reminders.dart';
import 'package:small_steps/data/repository.dart';
import 'backend_connection_test.dart' show DevelopmentServer;
import 'widget_test.dart' show launch;
import 'reminders_test.dart' show FakeReminders;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  group('approved corrections and agent context', () {
    late ProviderContainer c;
    late AppController controller;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      c = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
      );
      controller = c.read(appProvider.notifier);
      await controller.initialize();
    });
    tearDown(() => c.dispose());
    for (final condition in [
      StudyCondition.selfAgent,
      StudyCondition.friendAgent,
    ]) {
      test(
        'editable correction preserves dates and steps in ${condition.name}',
        () async {
          await controller.switchCondition(condition);
          final before = c.read(appProvider).tasks.first;
          final draft = await controller.proposeCorrection(before);
          expect(c.read(appProvider).tasks.first.toJson(), before.toJson());
          await controller.decideCorrection(
            draft,
            accepted: TaskCorrection(
              title: 'Read one research paper',
              description: 'Write one note',
              minutes: 10,
              reason: draft.correction.reason,
            ),
          );
          final saved = c.read(appProvider).tasks.first;
          expect(saved.title, 'Read one research paper');
          expect(saved.due, before.due);
          expect(saved.reminder, before.reminder);
          expect(saved.subtasks, before.subtasks);
          expect(saved.done, isFalse);
          expect(
            c
                .read(appProvider)
                .events
                .where((e) => e.kind == 'correction_accepted'),
            hasLength(1),
          );
          await expectLater(
            controller.decideCorrection(draft, accepted: draft.correction),
            throwsException,
          );
        },
      );
    }
    test(
      'rejection, later edits, and control condition cannot mutate proposals',
      () async {
        final before = c.read(appProvider).tasks.first;
        final draft = await controller.proposeCorrection(before);
        await controller.decideCorrection(draft);
        expect(c.read(appProvider).tasks.first.toJson(), before.toJson());
        final stale = await controller.proposeCorrection(before);
        await controller.saveTask(before.copyWith(title: 'Later edit'));
        await expectLater(
          controller.decideCorrection(stale, accepted: stale.correction),
          throwsException,
        );
        expect(c.read(appProvider).tasks.first.title, 'Later edit');
        await controller.switchCondition(StudyCondition.standardControl);
        await expectLater(
          controller.proposeCorrection(c.read(appProvider).tasks.first),
          throwsException,
        );
      },
    );
    test(
      'failed correction leaves task intact and can be requested again',
      () async {
        final before = c.read(appProvider).tasks.first;
        (c.read(repositoryProvider) as MockResearchRepository).failNext = true;
        await expectLater(
          controller.proposeCorrection(before),
          throwsException,
        );
        expect(c.read(appProvider).tasks.first.toJson(), before.toJson());
        expect(
          (await controller.proposeCorrection(before)).correction.title,
          isNotEmpty,
        );
      },
    );
    test(
      'switching uses separate histories and survives restart serialization',
      () async {
        final task = c.read(appProvider).tasks.first;
        await controller.send('Help me begin', task);
        final self = c.read(appProvider).messages.last.text;
        await controller.switchCondition(StudyCondition.friendAgent);
        expect(c.read(appProvider).messages, isEmpty);
        await controller.send('Help me begin', task);
        expect(c.read(appProvider).messages.last.text, isNot(self));
        final prefs = c.read(preferencesProvider);
        final restored = AppState.fromJson(
          jsonDecode(prefs.getString(AppController.storageKey)!),
        );
        expect(restored.condition, StudyCondition.friendAgent);
        expect(restored.chats['selfAgent']!.last.text, self);
        expect(restored.chats['friendAgent'], hasLength(2));
        expect(
          restored.events.where((e) => e.kind == 'agent_switched'),
          hasLength(1),
        );
      },
    );
    test(
      'suggestion display is idempotent and condition transitions wait for generation',
      () async {
        final task = c.read(appProvider).tasks.first;
        final pending = controller.proposeCorrection(task);
        await expectLater(
          controller.switchCondition(StudyCondition.friendAgent),
          throwsException,
        );
        final draft = await pending;
        await controller.reportSuggestion(
          'suggestion_displayed',
          task,
          draft.id,
        );
        await controller.reportSuggestion(
          'suggestion_displayed',
          task,
          draft.id,
        );
        expect(
          c
              .read(appProvider)
              .events
              .where((e) => e.kind == 'suggestion_displayed'),
          hasLength(1),
        );
      },
    );
    test(
      'connected correction travels through API proposal and approval with no client assignment',
      () async {
        final server = DevelopmentServer(condition: 'friendAgent');
        await controller.connectBackend(
          'http://127.0.0.1:8000',
          'synthetic-token',
          client: server.client(),
        );
        await controller.saveTask(const Task(id: 'remote', title: 'Study AI'));
        final draft = await controller.proposeCorrection(
          c.read(appProvider).tasks.single,
        );
        expect(server.tasks['remote']!['title'], 'Study AI');
        await controller.decideCorrection(draft, accepted: draft.correction);
        expect(server.tasks['remote']!['title'], 'Read one paragraph');
        expect(c.read(appProvider).tasks.single.minutes, 10);
        final requests = server.requests.where(
          (r) => r.path == '/api/tasks/refine',
        );
        expect(requests.single.data['mode'], 'correction');
        expect(requests.single.data.containsKey('condition'), isFalse);
      },
    );
  });

  testWidgets(
    'chat selector changes actual demo agent and retains separate composer drafts',
    (tester) async {
      final c = await launch(tester);
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField).last,
        'A private self draft',
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Friend-Agent'));
      await tester.pumpAndSettle();
      expect(c.read(appProvider).condition, StudyCondition.friendAgent);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        isEmpty,
      );
      await tester.enterText(find.byType(TextField).last, 'A friend draft');
      await tester.tap(find.widgetWithText(ChoiceChip, 'Self-Agent'));
      await tester.pumpAndSettle();
      expect(c.read(appProvider).condition, StudyCondition.selfAgent);
      expect(
        tester.widget<TextField>(find.byType(TextField).last).controller!.text,
        'A private self draft',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('connected chat selector cannot change backend assignment', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    SharedPreferences.setMockInitialValues({
      AppController.storageKey: jsonEncode(
        const AppState(loaded: true, consent: true).toJson(),
      ),
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(() {
      c.dispose();
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final server = DevelopmentServer(condition: 'friendAgent');
    await tester.runAsync(() async {
      await c.read(appProvider.notifier).initialize();
      await c
          .read(appProvider.notifier)
          .connectBackend(
            'http://127.0.0.1:8000',
            'synthetic-token',
            client: server.client(),
          );
    });
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const SmallStepsApp()),
    );
    c.read(routerProvider).go('/chat');
    await tester.pumpAndSettle();
    for (final label in ['Self-Agent', 'Friend-Agent']) {
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, label))
            .onSelected,
        isNull,
      );
    }
    await expectLater(
      c.read(appProvider.notifier).switchCondition(StudyCondition.selfAgent),
      throwsException,
    );
    expect(c.read(appProvider).condition, StudyCondition.friendAgent);
  });

  testWidgets('task correction UI saves edited proposal only after approval', (
    tester,
  ) async {
    final c = await launch(tester);
    c.read(routerProvider).go('/chat');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('More actions'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('More actions'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Correct this task'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Correct this task'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(c.read(appProvider).tasks.first.title, 'Review HAI literature');
    await tester.enterText(
      find.widgetWithText(TextField, 'Suggested title · editable'),
      'Read one HAI paper',
    );
    await tester.scrollUntilVisible(
      find.text('Accept correction'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.tap(find.text('Accept correction'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(c.read(appProvider).tasks.first.title, 'Read one HAI paper');
    expect(tester.takeException(), isNull);
  });

  test(
    'native coordinator updates persona copy, cancels completed slots and saves opt-ins',
    () async {
      final now = DateTime.now();
      SharedPreferences.setMockInitialValues({
        AppController.storageKey: jsonEncode(
          AppState(
            loaded: true,
            consent: true,
            tasks: [
              Task(
                id: 't1',
                title: 'Study one paper',
                plannedStart: now.add(const Duration(hours: 1)),
                reminder: now.add(const Duration(hours: 3)),
                due: now.add(const Duration(hours: 5)),
              ),
            ],
          ).toJson(),
        ),
      });
      final prefs = await SharedPreferences.getInstance();
      final service = FakeReminders();
      final c = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          reminderServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(c.dispose);
      await c.read(appProvider.notifier).initialize();
      final reminders = c.read(remindersProvider.notifier);
      await reminders.initialize();
      await reminders.setPolicy(
        plannedStarts: true,
        deadlines: true,
        agentVoice: true,
      );
      expect(service.requests, 0);
      expect(service.pending, isEmpty);
      await reminders.setEnabled(true);
      expect(service.pending, hasLength(3));
      final before = service.pending.first.body;
      int registrations() => c
          .read(appProvider)
          .events
          .where((e) => e.kind == 'notification_schedule_registered')
          .length;
      final count = registrations();
      await reminders.refresh();
      expect(registrations(), count);
      await reminders.setPolicy(agentVoice: false);
      expect(registrations(), count + 3);
      await reminders.setPolicy(agentVoice: true);
      expect(registrations(), count + 6);
      await c
          .read(appProvider.notifier)
          .switchCondition(StudyCondition.friendAgent);
      await reminders.refresh();
      expect(service.pending, hasLength(3));
      expect(service.pending.first.body, isNot(before));
      final restored = ReminderPreferences.fromJson(
        jsonDecode(prefs.getString(RemindersController.storageKey)!),
      );
      expect(restored.deadlines, isTrue);
      await c
          .read(appProvider.notifier)
          .toggleTask(c.read(appProvider).tasks.single);
      await reminders.refresh();
      expect(service.pending, isEmpty);
    },
  );

  testWidgets(
    'chat request opens an actual breakdown and records one dismissal',
    (tester) async {
      final c = await launch(tester);
      final request = c
          .read(appProvider.notifier)
          .send('Break down this task', c.read(appProvider).tasks.first);
      await tester.pump(const Duration(seconds: 1));
      await request;
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      expect(
        c
            .read(appProvider)
            .events
            .where((e) => e.kind == 'suggestion_displayed'),
        hasLength(
          1,
        ), // restored at the latest messages; the card is actually visible
      );
      await tester.scrollUntilVisible(
        find.text('Review suggestion'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(
        c
            .read(appProvider)
            .events
            .where((e) => e.kind == 'suggestion_displayed'),
        hasLength(1),
      );
      await tester.tap(find.text('Review suggestion'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(find.text('Make it manageable'), findsOneWidget);
      expect(c.read(appProvider).tasks.first.subtasks, isEmpty);
      c.read(routerProvider).pop();
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Dismiss'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Dismiss'));
      await tester.pumpAndSettle();
      expect(find.text('Review suggestion'), findsNothing);
      expect(
        c
            .read(appProvider)
            .events
            .where((e) => e.kind == 'suggestion_dismissed'),
        hasLength(1),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('leaving a loading breakdown cannot record an unseen rejection', (
    tester,
  ) async {
    final c = await launch(tester);
    c.read(routerProvider).push('/refine/literature');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    final reject = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Reject suggestions · Not now'),
    );
    expect(reject.onPressed, isNull);
    c.read(routerProvider).pop();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(
      c
          .read(appProvider)
          .events
          .where(
            (e) =>
                e.kind == 'refinement_rejected' ||
                e.kind == 'suggestion_displayed',
          ),
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('expanded reminder controls fit a small screen at 200% text', (
    tester,
  ) async {
    final c = await launch(tester, size: const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    c.read(routerProvider).go('/settings');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Reminder types & limits'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Reminder types & limits'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Minimum time between slots'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture integrated agent controls for visual review', (
    tester,
  ) async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await icons.load();
    await font.load();
    final c = await launch(tester);
    c.read(routerProvider).go('/chat');
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../work/agent-review/chat.png'),
    );
    await tester.scrollUntilVisible(
      find.text('More actions'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('More actions'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Correct this task'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Correct this task'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../work/agent-review/correction.png'),
    );
  }, skip: !const bool.fromEnvironment('CAPTURE_AGENT_PREVIEWS'));

  group('common notification burden policy', () {
    final now = DateTime.utc(2026, 10, 30);
    final zone = tz.getLocation('Asia/Tokyo');
    Task item(String id, int minutes) => Task(
      id: id,
      title: 'Private title',
      reminder: now.add(Duration(minutes: minutes)),
    );
    test('defaults are opt-in categories and persist valid limits', () {
      final prefs = ReminderPreferences.fromJson(
        const ReminderPreferences().toJson(),
      );
      expect(prefs.plannedStarts, isFalse);
      expect(prefs.deadlines, isFalse);
      expect(prefs.agentVoice, isFalse);
      expect(prefs.dailyLimit, 3);
      expect(prefs.cooldownMinutes, 60);
      expect(
        () => ReminderPreferences.fromJson({'dailyLimit': 0}),
        throwsFormatException,
      );
    });
    test(
      'start, manual and deadline slots cancel when done and update when edited',
      () {
        final task = Task(
          id: 't1',
          title: 'Private title',
          plannedStart: now.add(const Duration(hours: 1)),
          reminder: now.add(const Duration(hours: 3)),
          due: now.add(const Duration(hours: 5)),
        );
        const prefs = ReminderPreferences(
          enabled: true,
          plannedStarts: true,
          deadlines: true,
        );
        final slots = planReminders([task], prefs, zone, now);
        expect(slots.map((s) => s.category), [
          'planned_start',
          'manual',
          'deadline',
        ]);
        expect(slots.map((s) => s.notificationId).toSet(), hasLength(3));
        expect(
          planReminders([task.copyWith(done: true)], prefs, zone, now),
          isEmpty,
        );
        expect(
          planReminders([task.copyWith(firstStartedAt: now)], prefs, zone, now),
          hasLength(2),
        );
        final revised = planReminders(
          [task.copyWith(due: now.add(const Duration(hours: 7)))],
          prefs,
          zone,
          now,
        );
        expect(revised.last.notificationId, slots.last.notificationId);
        expect(revised.last.scheduledAt.isAtSameMomentAs(task.due!), isFalse);
      },
    );
    test(
      'daily cap and cooldown span every type and survive restart or agent switch',
      () {
        const prefs = ReminderPreferences(enabled: true);
        final slots = planReminders(
          [
            for (final m in [1, 10, 70, 140, 210]) item('$m', m),
          ],
          prefs,
          zone,
          now,
        );
        expect(slots.map((s) => s.taskId), ['1', '70', '140']);
        final history = [
          for (var i = 0; i < 3; i++)
            BehaviorEvent(
              'notification_schedule_registered',
              'old$i',
              now,
              condition: 'selfAgent',
              details: {
                'scheduledAtUtc': now
                    .subtract(Duration(minutes: i * 70))
                    .toIso8601String(),
              },
            ),
        ];
        expect(
          planReminders(
            [item('new', 300)],
            prefs,
            zone,
            now,
            condition: StudyCondition.friendAgent,
            history: history,
          ),
          isEmpty,
        );
      },
    );
    test(
      'quiet hours, equal-time deduplication and matched persona scheduling',
      () {
        final at = tz.TZDateTime(zone, 2026, 10, 30, 23);
        final task = Task(
          id: 't1',
          title: 'Secret research text',
          reminder: at,
          plannedStart: at,
          due: at,
        );
        const prefs = ReminderPreferences(
          enabled: true,
          plannedStarts: true,
          deadlines: true,
          agentVoice: true,
          quietHours: true,
        );
        final self = planReminders(
          [task],
          prefs,
          zone,
          now,
          condition: StudyCondition.selfAgent,
        ).single;
        final friend = planReminders(
          [task],
          prefs,
          zone,
          now,
          condition: StudyCondition.friendAgent,
        ).single;
        final control = planReminders([task], prefs, zone, now).single;
        expect(self.scheduledAt.hour, 8);
        expect(self.scheduledAt, friend.scheduledAt);
        expect(self.notificationId, friend.notificationId);
        expect(self.body, isNot(friend.body));
        expect(control.body, isNot(self.body));
        expect(self.body, isNot(contains(task.title)));
      },
    );
    test('category payload roundtrips without content or credentials', () {
      const target = ReminderTarget(
        'task-1',
        scope: 'synthetic-account',
        category: 'deadline',
      );
      final parsed = ReminderTarget.parse(target.payload)!;
      expect(parsed.taskId, 'task-1');
      expect(parsed.scope, 'synthetic-account');
      expect(parsed.category, 'deadline');
      expect(
        ReminderTarget.parse(
          'target:{"scope":"a","taskId":"b","category":"execute_model_action"}',
        ),
        isNull,
      );
    });
  });
}
