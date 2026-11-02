import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/app/theme.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late AppController controller;
  late SharedPreferences prefs;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    controller = container.read(appProvider.notifier);
    await controller.initialize();
  });
  tearDown(() => container.dispose());
  test(
    'task edits, completion, subtasks and settings survive serialization',
    () async {
      final task = container.read(appProvider).tasks.first;
      await controller.saveTask(
        task.copyWith(title: 'Changed title', minutes: 30),
      );
      await controller.toggleTask(container.read(appProvider).tasks.first);
      await controller.acceptSuggestions(task.id, [
        const Subtask('A small step'),
      ]);
      await controller.setTheme(ThemeMode.dark);
      await controller.setBurden('Okay');
      final restored = AppState.fromJson(
        jsonDecode(prefs.getString(AppController.storageKey)!),
      );
      expect(restored.tasks.first.title, 'Changed title');
      expect(restored.tasks.first.done, isTrue);
      expect(restored.tasks.first.subtasks.single.title, 'A small step');
      expect(restored.theme, ThemeMode.dark);
      expect(
        restored.events.where((e) => e.kind == 'self_reported_completion'),
        hasLength(1),
      );
      expect(
        restored.events.where((e) => e.kind == 'refinement_accepted'),
        hasLength(1),
      );
      expect(restored.checkIns.single.answers['burden'], 'Okay');
    },
  );
  test('draft generation is not an accepted change', () async {
    final task = container.read(appProvider).tasks.last;
    final suggestions = await controller.suggestions(task, 0);
    expect(suggestions, isNotEmpty);
    expect(container.read(appProvider).tasks.last.subtasks, isEmpty);
    await controller.acceptSuggestions(task.id, suggestions);
    expect(
      container.read(appProvider).tasks.last.subtasks.length,
      suggestions.length,
    );
  });
  test('control denies repository and state agent operations', () async {
    await controller.switchCondition(StudyCondition.standardControl);
    expect(
      () => controller.suggestions(container.read(appProvider).tasks.first, 0),
      throwsA(isA<AppFailure>()),
    );
    await expectLater(
      controller.send('Hello', null),
      throwsA(isA<AppFailure>()),
    );
    await expectLater(
      controller.acceptSuggestions('literature', []),
      throwsA(isA<AppFailure>()),
    );
    expect(container.read(appProvider).messages, isEmpty);
  });
  test('chat histories are isolated', () async {
    await controller.send('My goal', null);
    await controller.switchCondition(StudyCondition.friendAgent);
    expect(container.read(appProvider).messages, isEmpty);
    await controller.send('Feeling stuck', null);
    expect(
      container.read(appProvider).messages.last.text,
      contains('own pace'),
    );
    await controller.switchCondition(StudyCondition.selfAgent);
    expect(container.read(appProvider).messages.first.text, 'My goal');
  });
  test(
    'timestamp timer survives pause, restart and elapsed background time',
    () async {
      final now = DateTime(2026, 10, 26, 10);
      await controller.prepareFocus('literature');
      await controller.startFocus(now);
      expect(
        container
            .read(appProvider)
            .focus!
            .remainingAt(now.add(const Duration(seconds: 90))),
        510,
      );
      await controller.pauseFocus(now.add(const Duration(seconds: 90)));
      final restored = AppState.fromJson(
        jsonDecode(prefs.getString(AppController.storageKey)!),
      );
      expect(
        restored.focus!.remainingAt(now.add(const Duration(hours: 1))),
        510,
      );
      await controller.startFocus(now.add(const Duration(hours: 1)));
      await controller.endFocus(
        at: now.add(const Duration(hours: 2)),
        reflection: 'A small start',
      );
      expect(container.read(appProvider).focus, isNull);
      expect(container.read(appProvider).tasks.first.done, isFalse);
      expect(
        container
            .read(appProvider)
            .events
            .where((e) => e.kind == 'focus_started')
            .length,
        1,
      );
      expect(container.read(appProvider).events.last.seconds, 600);
    },
  );
  test('ending an unstarted timer records no initiation', () async {
    await controller.prepareFocus('literature');
    await controller.endFocus();
    expect(container.read(appProvider).events, isEmpty);
  });
  test('failed task update does not mutate local task', () async {
    (container.read(repositoryProvider) as MockResearchRepository).failNext =
        true;
    await expectLater(
      controller.toggleTask(container.read(appProvider).tasks.first),
      throwsA(isA<AppFailure>()),
    );
    expect(container.read(appProvider).tasks.first.done, isFalse);
  });
  test('theme uses Material 3 and the design palette', () {
    expect(appTheme(Brightness.light).useMaterial3, isTrue);
    expect(appTheme(Brightness.light).colorScheme.primary, AppTokens.teal);
    expect(appTheme(Brightness.dark).brightness, Brightness.dark);
  });
  test('repeated completion taps record one event', () async {
    final task = container.read(appProvider).tasks.first;
    await Future.wait([
      controller.toggleTask(task),
      controller.toggleTask(task),
    ]);
    expect(
      container
          .read(appProvider)
          .events
          .where((e) => e.kind == 'self_reported_completion')
          .length,
      1,
    );
    expect(container.read(appProvider).tasks.first.done, isTrue);
  });
}
