import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_steps/app/app.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/app/theme.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';
import 'package:small_steps/shared/widgets.dart';

Future<ProviderContainer> launch(
  WidgetTester tester, {
  bool consent = true,
  Size size = const Size(390, 844),
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  final fixture = AppState(
    loaded: true,
    consent: consent,
    tasks: [
      Task(
        id: 'literature',
        title: 'Review HAI literature',
        due: DateTime.now(),
      ),
      Task(
        id: 'methodology',
        title: 'Prepare research methodology',
        due: DateTime.now(),
      ),
      Task(
        id: 'presentation',
        title: 'Draft presentation slides',
        due: DateTime.now(),
      ),
    ],
  );
  SharedPreferences.setMockInitialValues({
    AppController.storageKey: jsonEncode(fixture.toJson()),
  });
  final prefs = await SharedPreferences.getInstance();
  final c = ProviderContainer(
    overrides: [preferencesProvider.overrideWithValue(prefs)],
  );
  await c.read(appProvider.notifier).initialize();
  await tester.pumpWidget(
    UncontrolledProviderScope(container: c, child: const SmallStepsApp()),
  );
  await tester.pumpAndSettle();
  addTearDown(() {
    c.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
  return c;
}

void main() {
  testWidgets('startup and demo consent gate', (tester) async {
    final c = await launch(tester, consent: false);
    expect(find.text('Progress, not pressure.'), findsOneWidget);
    await tester.ensureVisible(find.text('Get Started'));
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Agree & continue'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.widgetWithText(FilledButton, 'Agree & continue'),
          )
          .onPressed,
      isNull,
    );
    await tester.ensureVisible(find.byType(CheckboxListTile));
    await tester.tap(find.byType(CheckboxListTile));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Agree & continue'));
    await tester.tap(find.text('Agree & continue'));
    await tester.pumpAndSettle();
    expect(c.read(appProvider).consent, isTrue);
    expect(find.text('Up next'), findsOneWidget);
  });
  testWidgets('navigation, task creation and completion update shared state', (
    tester,
  ) async {
    final c = await launch(tester);
    await tester.tap(find.text('Tasks').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('+ Add task'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextFormField).first,
      'Write a research question',
    );
    await tester.scrollUntilVisible(
      find.text('Save task'),
      250,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save task'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Save task'));
    await tester.pumpAndSettle();
    expect(c.read(appProvider).tasks.length, 4);
    final created = c.read(appProvider).tasks.last;
    c.read(routerProvider).go('/task/${created.id}');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mark complete'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(c.read(appProvider).tasks.last.done, isTrue);
    await tester.tap(find.text('Insights').last);
    await tester.pumpAndSettle();
    expect(find.text('Your progress'), findsOneWidget);
    expect(find.text('1').first, findsOneWidget);
  });
  testWidgets('refinement reject leaves task unchanged and accept saves edits', (
    tester,
  ) async {
    final c = await launch(tester);
    c.read(routerProvider).go('/refine/presentation');
    await tester.pumpAndSettle();
    expect(c.read(appProvider).tasks.last.subtasks, isEmpty);
    await tester.scrollUntilVisible(
      find.text('Reject suggestions · Not now'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    // go() has no previous route; rejection uses the normal pushed detail flow below.
    c.read(routerProvider).go('/task/presentation');
    await tester.pumpAndSettle();
    c.read(routerProvider).push('/refine/presentation');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Reject suggestions · Not now'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Reject suggestions · Not now'));
    await tester.pumpAndSettle();
    expect(c.read(appProvider).tasks.last.subtasks, isEmpty);
    c.read(routerProvider).push('/refine/presentation');
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byType(TextField).first,
      'My chosen first step',
    );
    await tester.scrollUntilVisible(
      find.text('Accept these steps'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Accept these steps'));
    await tester.pumpAndSettle();
    expect(
      c.read(appProvider).tasks.last.subtasks.first.title,
      'My chosen first step',
    );
  });
  for (final condition in [
    StudyCondition.selfAgent,
    StudyCondition.friendAgent,
  ]) {
    testWidgets('${condition.name} message and retry without duplication', (
      tester,
    ) async {
      final c = await launch(tester);
      await c.read(appProvider.notifier).switchCondition(condition);
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      (c.read(repositoryProvider) as MockResearchRepository).failNext = true;
      await tester.enterText(
        find.byType(TextField),
        'I am finding it hard to start',
      );
      await tester.tap(find.byTooltip('Send message'));
      await tester.pumpAndSettle();
      expect(c.read(appProvider).messages.length, 1);
      await tester.ensureVisible(find.text('Try again'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Try again'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(c.read(appProvider).messages.length, 2);
      expect(c.read(appProvider).messages.last.user, isFalse);
      expect(
        c.read(appProvider).messages.last.text,
        contains(
          condition == StudyCondition.selfAgent ? 'future self' : 'own pace',
        ),
      );
    });
  }
  testWidgets('control blocks direct chat and refinement routes', (
    tester,
  ) async {
    final c = await launch(tester);
    await c
        .read(appProvider.notifier)
        .switchCondition(StudyCondition.standardControl);
    for (final route in ['/chat', '/refine/literature']) {
      c.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      expect(find.text('Today’s reminders'), findsOneWidget);
      expect(find.byTooltip('Send message'), findsNothing);
    }
    expect(find.text('Chat'), findsNothing);
    expect(find.text('Reminders'), findsOneWidget);
  });
  testWidgets('empty and recoverable error panels', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: appTheme(Brightness.light),
        home: Scaffold(
          body: Column(
            children: [
              const EmptyPanel('Nothing here', 'Add a task'),
              ErrorPanel('Try later', retry: () {}),
            ],
          ),
        ),
      ),
    );
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
  for (final size in [
    const Size(320, 568),
    const Size(390, 844),
    const Size(844, 390),
  ]) {
    testWidgets('responsive routes at $size with large text', (tester) async {
      final c = await launch(tester, size: size);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final route in [
        '/today',
        '/tasks',
        '/chat',
        '/insights',
        '/settings',
        '/reminders',
        '/task/new',
        '/task/literature',
      ]) {
        c.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
      }
      await c.read(appProvider.notifier).prepareFocus('literature');
      c.read(routerProvider).go('/focus');
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      c.read(routerProvider).go('/today');
      await tester.pumpAndSettle();
    });
  }
  testWidgets('dark theme renders core routes', (tester) async {
    final c = await launch(tester);
    await c.read(appProvider.notifier).setTheme(ThemeMode.dark);
    for (final route in ['/today', '/chat', '/insights']) {
      c.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      expect(
        Theme.of(tester.element(find.byType(Scaffold).last)).brightness,
        Brightness.dark,
      );
      expect(tester.takeException(), isNull);
    }
  });
  testWidgets('keyboard leaves the chat composer visible on a small phone', (
    tester,
  ) async {
    final c = await launch(tester, size: const Size(320, 568));
    c.read(routerProvider).go('/chat');
    await tester.pumpAndSettle();
    tester.view.viewInsets = const FakeViewPadding(bottom: 250);
    addTearDown(tester.view.resetViewInsets);
    await tester.tap(find.byType(TextField));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomLeft(find.byType(TextField)).dy,
      lessThanOrEqualTo(318),
    );
    expect(find.byType(NavigationBar), findsNothing);
  });
}
