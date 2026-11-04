import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:small_steps/app/app.dart';
import 'package:small_steps/app/reminders_controller.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';
import 'package:small_steps/features/reminder_settings.dart';
import 'reminders_test.dart' show FakeReminders;
import 'widget_test.dart' show launch;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);

  group('completion correction', () {
    late ProviderContainer container;
    late AppController controller;
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      container = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
      );
      controller = container.read(appProvider.notifier);
      await controller.initialize();
    });
    tearDown(() => container.dispose());

    test('Undo preserves both completion and correction events', () async {
      final before = container.read(appProvider).tasks.first;
      final receipt = await controller.toggleTask(before);
      expect(receipt, isNotNull);
      await controller.undoCompletion(receipt!);
      final after = container.read(appProvider).tasks.first;
      expect(after.done, isFalse);
      expect(after.completedAt, isNull);
      expect(after.version, before.version + 2);
      expect(after.title, before.title);
      final kinds = container.read(appProvider).events.map((e) => e.kind);
      expect(kinds.where((k) => k == 'self_reported_completion'), hasLength(1));
      expect(kinds.where((k) => k == 'completion_undone'), hasLength(1));
      expect(kinds, isNot(contains('task_started')));
      await expectLater(controller.undoCompletion(receipt), throwsException);
    });

    test('Undo refuses to overwrite a later edit', () async {
      final receipt = await controller.toggleTask(
        container.read(appProvider).tasks.first,
      );
      await controller.saveTask(
        container.read(appProvider).tasks.first.copyWith(title: 'Later edit'),
      );
      await expectLater(controller.undoCompletion(receipt!), throwsException);
      expect(container.read(appProvider).tasks.first.title, 'Later edit');
      expect(container.read(appProvider).tasks.first.done, isTrue);
    });

    test('condition changes invalidate Undo', () async {
      final receipt = await controller.toggleTask(
        container.read(appProvider).tasks.first,
      );
      await controller.switchCondition(StudyCondition.friendAgent);
      await expectLater(controller.undoCompletion(receipt!), throwsException);
      expect(container.read(appProvider).tasks.first.done, isTrue);
    });

    test('stale checkbox cannot overwrite a later task edit', () async {
      final old = container.read(appProvider).tasks.first;
      await controller.saveTask(old.copyWith(title: 'New title'));
      await expectLater(controller.toggleTask(old), throwsException);
      expect(container.read(appProvider).tasks.first.title, 'New title');
      expect(container.read(appProvider).tasks.first.done, isFalse);
    });

    test('choosing Today task persists without recording initiation', () async {
      final id = container.read(appProvider).tasks.last.id;
      final before = container.read(appProvider).events.length;
      await controller.selectTodayTask(id);
      final prefs = container.read(preferencesProvider);
      final restored = AppState.fromJson(
        jsonDecode(prefs.getString(AppController.storageKey)!),
      );
      expect(restored.todayTaskId, id);
      expect(restored.events.length, before);
      expect(restored.focus, isNull);
    });
  });

  for (final condition in StudyCondition.values) {
    testWidgets('completion Undo works from the list in ${condition.name}', (
      tester,
    ) async {
      final container = await launch(tester);
      await container.read(appProvider.notifier).switchCondition(condition);
      container.read(routerProvider).go('/tasks');
      await tester.pumpAndSettle();
      final id = container.read(appProvider).tasks.first.id;
      await tester.tap(find.byType(Checkbox).first);
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        container.read(appProvider).tasks.firstWhere((t) => t.id == id).done,
        isTrue,
      );
      expect(find.text('Undo'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(
        container.read(appProvider).tasks.firstWhere((t) => t.id == id).done,
        isFalse,
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Today selection and focus setup never imply work started', (
    tester,
  ) async {
    final container = await launch(tester);
    expect(find.text('One task, at your own pace.'), findsOneWidget);
    expect(find.text('Choose duration'), findsOneWidget);
    expect(find.text('Optional check-in'), findsNothing);
    await tester.tap(find.text('Change task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Draft presentation slides').last);
    await tester.pumpAndSettle();
    expect(container.read(appProvider).todayTaskId, 'presentation');
    await tester.tap(find.text('Choose duration'));
    await tester.pumpAndSettle();
    expect(find.text('Make room for a small start'), findsOneWidget);
    expect(container.read(appProvider).focus, isNull);
    await tester.tap(find.text('5 minutes'));
    await tester.pumpAndSettle();
    expect(container.read(appProvider).focus?.taskId, 'presentation');
    expect(container.read(appProvider).focus?.started, isFalse);
    expect(
      container
          .read(appProvider)
          .events
          .where((e) => e.kind == 'task_started' || e.kind == 'focus_started'),
      isEmpty,
    );
  });

  testWidgets('failed Undo keeps completion and presents an error', (
    tester,
  ) async {
    final container = await launch(tester);
    container.read(routerProvider).go('/task/literature');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark complete'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    (container.read(repositoryProvider) as MockResearchRepository).failNext =
        true;
    await tester.tap(find.text('Undo'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(container.read(appProvider).tasks.first.done, isTrue);
    expect(
      container
          .read(appProvider)
          .events
          .where((e) => e.kind == 'completion_undone'),
      isEmpty,
    );
    expect(find.byType(SnackBar), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('Today and chooser support long Unicode at 200% text: $size', (
      tester,
    ) async {
      final container = await launch(tester, size: size);
      final task = container.read(appProvider).tasks.first;
      final saving = container
          .read(appProvider.notifier)
          .saveTask(
            task.copyWith(
              title: List.filled(12, '研究計画を確認する 🌱').join(' '),
              subtasks: [
                Subtask(List.filled(12, 'Read one small section').join(' ')),
              ],
            ),
          );
      await tester.pump(const Duration(seconds: 1));
      await saving;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Change task'),
        150,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Change task'));
      await tester.pumpAndSettle();
      expect(find.text('Choose one task'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(CloseButton).last);
      await tester.pumpAndSettle();
    });
  }

  testWidgets('capture first UX implementation for visual review', (
    tester,
  ) async {
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await icons.load();
    await font.load();
    final container = await launch(tester);
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../work/ux-first/today.png'),
    );
    await tester.tap(find.text('Change task'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../work/ux-first/choose-task.png'),
    );
    await tester.tap(find.byType(CloseButton).last);
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/task/literature');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark complete'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('../../../work/ux-first/completion-undo.png'),
    );
  }, skip: !const bool.fromEnvironment('CAPTURE_UX_PREVIEWS'));

  for (final mode in ['off', 'denied', 'unsupported', 'scheduled', 'failure']) {
    testWidgets('reminder state is honest and actionable: $mode', (
      tester,
    ) async {
      SharedPreferences.setMockInitialValues({
        AppController.storageKey: jsonEncode(
          AppState(
            loaded: true,
            consent: true,
            tasks: [
              Task(
                id: 'reminder',
                title: 'Read one paper',
                reminder: DateTime.now().add(const Duration(days: 1)),
              ),
            ],
          ).toJson(),
        ),
      });
      final prefs = await SharedPreferences.getInstance();
      final service = FakeReminders()
        ..allowRequest = mode != 'denied'
        ..supported = mode != 'unsupported';
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          reminderServiceProvider.overrideWithValue(service),
        ],
      );
      addTearDown(container.dispose);
      await container.read(appProvider.notifier).initialize();
      await container.read(remindersProvider.notifier).initialize();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: ReminderStatusPanel(
                  task: container.read(appProvider).tasks.first,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      if (mode == 'unsupported') {
        expect(find.text('Time saved'), findsOneWidget);
        expect(find.text('Scheduled on this phone'), findsNothing);
        expect(find.text('Enable notifications'), findsNothing);
        return;
      }
      expect(find.text('Notifications off'), findsOneWidget);
      if (mode == 'off') return;
      service.fail = mode == 'failure';
      await tester.tap(find.text('Enable notifications'));
      await tester.pumpAndSettle();
      expect(service.requests, 1);
      if (mode == 'denied') {
        expect(find.text('Permission needed'), findsOneWidget);
        expect(find.text('Request permission'), findsOneWidget);
        expect(find.text('Check again'), findsOneWidget);
        expect(service.pending, isEmpty);
      } else {
        if (mode == 'failure') {
          expect(find.text('Could not update reminders'), findsOneWidget);
          await tester.tap(find.text('Try again'));
          await tester.pumpAndSettle();
        }
        expect(find.text('Scheduled on this phone'), findsOneWidget);
        expect(service.pending, hasLength(1));
      }
      expect(container.read(appProvider).tasks.first.reminder, isNotNull);
      expect(tester.takeException(), isNull);
    });
  }
}
