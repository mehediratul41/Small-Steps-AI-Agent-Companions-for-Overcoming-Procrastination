import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_steps/app/app.dart';
import 'package:small_steps/app/config.dart';
import 'package:small_steps/app/language.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';
import 'widget_test.dart' show launch;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('direct focus and development feedback', () {
    late ProviderContainer c;
    late SharedPreferences prefs;
    late AppController controller;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
      c = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
      );
      controller = c.read(appProvider.notifier);
      await controller.initialize();
    });
    tearDown(() => c.dispose());

    for (final condition in StudyCondition.values) {
      test(
        'five-minute rapid taps do not imply task start or completion: ${condition.name}',
        () async {
          await controller.switchCondition(condition);
          final task = c.read(appProvider).tasks.first;
          await Future.wait([
            controller.startFiveMinutes(task.id),
            controller.startFiveMinutes(task.id),
          ]);
          final state = c.read(appProvider);
          expect(state.focus!.durationSeconds, 300);
          expect(state.focus!.started, isTrue);
          expect(
            state.events.where((e) => e.kind == 'focus_started'),
            hasLength(1),
          );
          expect(state.events.where((e) => e.kind == 'task_started'), isEmpty);
          expect(state.tasks.first.done, isFalse);
          expect(state.tasks.first.firstStartedAt, isNull);
        },
      );
    }
    test('existing focus is preserved rather than replaced', () async {
      final tasks = c.read(appProvider).tasks;
      await controller.prepareFocus(tasks.first.id, minutes: 10);
      final before = c.read(appProvider).focus!.id;
      await controller.startFiveMinutes(tasks.last.id);
      expect(c.read(appProvider).focus!.id, before);
      expect(c.read(appProvider).focus!.durationSeconds, 600);
      expect(c.read(appProvider).focus!.started, isFalse);
    });
    test('feedback defaults off and cannot create measurements', () async {
      expect(AppConfig.supportFeedbackEnabled, isFalse);
      await controller.offerSupportFeedback();
      expect(c.read(appProvider).events, isEmpty);
      await expectLater(
        controller.answerSupportFeedback('quiet_time'),
        throwsException,
      );
    }, skip: AppConfig.supportFeedbackEnabled);

    test(
      'feedback is optional, throttled, duplicate-safe and restored as actual choices',
      () async {
        final task = c.read(appProvider).tasks.first;
        final now = DateTime.now();
        await controller.startFiveMinutes(task.id);
        await controller.endFocus(at: now.add(const Duration(seconds: 20)));
        await Future.wait([
          controller.offerSupportFeedback(at: now),
          controller.offerSupportFeedback(at: now),
        ]);
        expect(
          c
              .read(appProvider)
              .events
              .where((e) => e.kind == 'support_feedback_offered'),
          hasLength(1),
        );
        await Future.wait([
          controller.answerSupportFeedback('quiet_time'),
          controller.answerSupportFeedback('quiet_time'),
        ]);
        expect(
          c
              .read(appProvider)
              .events
              .where((e) => e.kind == 'support_feedback_answered'),
          hasLength(1),
        );
        final snapshot = AppState.fromJson(
          jsonDecode(prefs.getString(AppController.storageKey)!),
        );
        expect(snapshot.events.last.details['choice'], 'quiet_time');
        expect(snapshot.events.last.details['source'], 'explicit_user_choice');
        expect(
          snapshot.events.last.details['instrumentVersion'],
          'dev-support-feedback-v1',
        );
        await controller.startFiveMinutes(task.id);
        await controller.endFocus();
        await controller.offerSupportFeedback(
          at: now.add(const Duration(minutes: 30)),
        );
        expect(controller.pendingSupportFeedback, isNull);
        await controller.offerSupportFeedback(
          at: now.add(const Duration(days: 8)),
        );
        expect(controller.pendingSupportFeedback, isNotNull);
        await controller.answerSupportFeedback('skip');
        expect(controller.pendingSupportFeedback, isNull);
        expect(
          c.read(appProvider).events.last.kind,
          'support_feedback_skipped',
        );
      },
      skip: !AppConfig.supportFeedbackEnabled,
    );
  }, skip: !AppConfig.researcherDemo);

  testWidgets('Today starts five minutes directly and offers Resume', (
    tester,
  ) async {
    final c = await launch(tester);
    await tester.tap(find.text('Start 5 minutes'));
    await tester.pumpAndSettle();
    expect(c.read(appProvider).focus!.started, isTrue);
    c.read(routerProvider).go('/today');
    await tester.pumpAndSettle();
    expect(find.text('Resume session'), findsOneWidget);
    expect(find.text('Start 5 minutes'), findsNothing);
  });

  testWidgets(
    'chat context is compact and additional actions are discoverable',
    (tester) async {
      final c = await launch(tester);
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButtonFormField<String>), findsNothing);
      expect(find.text('Correct this task'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('More actions'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('More actions'));
      await tester.pumpAndSettle();
      expect(find.text('Correct this task'), findsOneWidget);
      expect(find.text('Remind me later'), findsOneWidget);
      expect(c.read(appProvider).tasks.first.title, 'Review HAI literature');
    },
  );

  testWidgets('Japanese direct-start label does not translate task text', (
    tester,
  ) async {
    final c = await launch(tester);
    await c.read(languageProvider.notifier).setLanguage('ja');
    await tester.pumpAndSettle();
    expect(find.text('5分だけ始める'), findsOneWidget);
    expect(find.text('Review HAI literature'), findsOneWidget);
  });
  testWidgets(
    'editable start example needs Save and dismissal keeps original',
    (tester) async {
      final c = await launch(tester);
      final original = c.read(appProvider).tasks.first;
      c.read(routerProvider).go('/task/${original.id}');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('My start plan'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('My start plan'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save my plan'));
      await tester.tap(find.text('Save my plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use an editable example'));
      await tester.pumpAndSettle();
      expect(c.read(appProvider).tasks.first.startCue, original.startCue);
      c.read(routerProvider).pop();
      await tester.pumpAndSettle();
      expect(c.read(appProvider).tasks.first.startAction, original.startAction);
      await tester.ensureVisible(find.text('Save my plan'));
      await tester.tap(find.text('Save my plan'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Use an editable example'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save my plan').last);
      await tester.tap(find.text('Save my plan').last);
      await tester.pumpAndSettle();
      expect(c.read(appProvider).tasks.first.startCue, 'After lunch');
      expect(
        c.read(appProvider).tasks.first.startAction,
        'Open one paper and read its abstract',
      );
      expect(c.read(appProvider).tasks.first.due, original.due);
    },
  );
  testWidgets('chat feedback follows real acknowledgement and safe failure', (
    tester,
  ) async {
    final c = await launch(tester);
    c.read(routerProvider).go('/chat');
    await tester.pumpAndSettle();
    final controller = c.read(appProvider.notifier);
    final first = controller.send('Hello', c.read(appProvider).tasks.first);
    await tester.pump(const Duration(milliseconds: 50));
    expect(c.read(appProvider).chatPhase, 'waiting');
    expect(
      c.read(appProvider).chats[StudyCondition.selfAgent.name]!.last.delivery,
      'sending',
    );
    expect(find.textContaining('Saved on server'), findsNothing);
    await tester.pump(const Duration(seconds: 1));
    await first;
    await tester.pumpAndSettle();
    expect(c.read(appProvider).chatPhase, 'acknowledged');
    expect(find.textContaining('Kept in local demo'), findsOneWidget);
    (c.read(repositoryProvider) as MockResearchRepository).failNext = true;
    final failure = expectLater(
      controller.send('Try again', c.read(appProvider).tasks.first),
      throwsException,
    );
    await tester.pump(const Duration(seconds: 1));
    await failure;
    await tester.pumpAndSettle();
    expect(c.read(appProvider).chatPhase, 'failed');
    expect(
      c.read(appProvider).chats[StudyCondition.selfAgent.name]!.last.delivery,
      'failed',
    );
    expect(find.textContaining('Saved on server'), findsNothing);
    await tester.scrollUntilVisible(
      find.widgetWithText(TextButton, 'Try again'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.widgetWithText(TextButton, 'Try again'), findsOneWidget);
  });
}
