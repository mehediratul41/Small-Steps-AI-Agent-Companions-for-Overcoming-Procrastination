import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_steps/app/app.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';
import 'widget_test.dart' as fixture;

void main() {
  testWidgets(
    'quick capture saves title without a forced deadline or opening details',
    (tester) async {
      final c = await fixture.launch(tester);
      c.read(routerProvider).go('/task/new');
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Open my notes');
      expect(
        find.text('Estimated duration (minutes)').hitTestable(),
        findsNothing,
      );
      await tester.tap(find.text('Save task'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      final task = c.read(appProvider).tasks.last;
      expect(task.title, 'Open my notes');
      expect(task.due, isNull);
      expect(task.plannedStart, isNull);
    },
  );
  testWidgets(
    'pausing a task moves it into Paused and preserves completion status',
    (tester) async {
      final c = await fixture.launch(tester);
      c.read(routerProvider).go('/task/literature');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Adjust my plan'));
      await tester.tap(find.text('Adjust my plan'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Pause this task'));
      await tester.tap(find.text('Pause this task'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(c.read(appProvider).tasks.first.paused, isTrue);
      expect(c.read(appProvider).tasks.first.done, isFalse);
      c.read(routerProvider).go('/tasks');
      await tester.pumpAndSettle();
      expect(find.text('Review HAI literature'), findsNothing);
      await tester.tap(find.widgetWithText(ChoiceChip, 'Paused'));
      await tester.pumpAndSettle();
      expect(find.text('Review HAI literature'), findsOneWidget);
    },
  );
  testWidgets('control participants can add their own small steps without AI', (
    tester,
  ) async {
    final c = await fixture.launch(tester);
    await c
        .read(appProvider.notifier)
        .switchCondition(StudyCondition.standardControl);
    c.read(routerProvider).go('/task/literature');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Edit my small steps'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Edit my small steps'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Read one paragraph');
    await tester.tap(find.text('Save steps'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(
      c.read(appProvider).tasks.first.subtasks.single.title,
      'Read one paragraph',
    );
    expect(find.text('Talk about this task'), findsNothing);
    expect(find.text('Break it down'), findsNothing);
  });
  testWidgets(
    'snooze sheet updates reminder without entering the full editor',
    (tester) async {
      final c = await fixture.launch(tester);
      final due = c.read(appProvider).tasks.first.due;
      c.read(routerProvider).go('/task/literature');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Remind me later'));
      await tester.tap(find.text('Remind me later'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('In 15 minutes'));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();
      expect(c.read(appProvider).tasks.first.reminder, isNotNull);
      expect(c.read(appProvider).tasks.first.due, due);
      expect(find.text('Edit your task'), findsNothing);
    },
  );
  testWidgets(
    'focus duration sheet opens a five-minute timer and does not start it',
    (tester) async {
      final c = await fixture.launch(tester);
      c.read(routerProvider).go('/task/literature');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Start a focus session'));
      await tester.tap(find.text('Start a focus session'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('5 minutes'));
      await tester.pumpAndSettle();
      expect(find.text('05:00'), findsOneWidget);
      expect(c.read(appProvider).focus!.started, isFalse);
      await tester.ensureVisible(find.text('Start session'));
      await tester.tap(find.text('Start session'));
      await tester.pump();
      expect(c.read(appProvider).focus!.started, isTrue);
      c.read(routerProvider).go('/today');
      await tester.pumpAndSettle();
    },
  );
  testWidgets('failed chat can cancel retry and send a different message', (
    tester,
  ) async {
    final c = await fixture.launch(tester);
    c.read(routerProvider).go('/chat');
    await tester.pumpAndSettle();
    (c.read(repositoryProvider) as MockResearchRepository).failNext = true;
    await tester.enterText(find.byType(TextField), 'First attempt');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byTooltip('Message options'));
    await tester.tap(find.byTooltip('Message options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel retry'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Let us try something else');
    await tester.pump();
    await tester.tap(find.byTooltip('Send message'));
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();
    expect(c.read(appProvider).messages.first.delivery, 'cancelled');
    expect(c.read(appProvider).messages, hasLength(3));
  });
  testWidgets(
    'optional check-in appends a dated response and skipping saves nothing',
    (tester) async {
      final c = await fixture.launch(tester);
      c.read(routerProvider).go('/check-in');
      await tester.pumpAndSettle();
      await tester.tap(find.byType(DropdownButtonFormField<String>).first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Heavy').last);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Save check-in'),
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Save check-in'));
      await tester.pumpAndSettle();
      expect(c.read(appProvider).checkIns.single.answers['burden'], 'Heavy');
      c.read(routerProvider).go('/check-in?phase=baseline');
      await tester.pumpAndSettle();
      expect(find.text('Heavy'), findsNothing);
      await tester.scrollUntilVisible(
        find.text('Skip for now'),
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Skip for now'));
      await tester.pumpAndSettle();
      expect(c.read(appProvider).checkIns, hasLength(1));
    },
  );
  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('new forms and expanded controls fit $size with large text', (
      tester,
    ) async {
      final c = await fixture.launch(tester, size: size);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final route in [
        '/preferences',
        '/check-in',
        '/check-in?phase=baseline',
        '/demo-data',
        '/task/new',
        '/task/literature',
      ]) {
        c.read(routerProvider).go(route);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: route);
        if (route == '/task/new') {
          await tester.scrollUntilVisible(
            find.text('More details and scheduling'),
            180,
            scrollable: find
                .descendant(
                  of: find.byType(ListView).last,
                  matching: find.byType(Scrollable),
                )
                .first,
          );
          await tester.tap(find.text('More details and scheduling'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
      }
      await tester.scrollUntilVisible(
        find.text('Adjust my plan'),
        180,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      await tester.tap(find.text('Adjust my plan'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.text('Keep my plan'));
      await tester.tap(find.text('Keep my plan'));
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/today');
      await tester.pumpAndSettle();
    });
  }
}
