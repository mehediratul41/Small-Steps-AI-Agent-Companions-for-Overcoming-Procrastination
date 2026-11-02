import 'dart:convert';
// Manual visual review capture, not a nondeterministic regression baseline.
// flutter test test/preview_test.dart --update-goldens --dart-define=CAPTURE_PREVIEWS=true
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_steps/app/app.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';

void main() {
  testWidgets('capture the nine screen concepts for visual review', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    final icons = FontLoader('MaterialIcons')
      ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
    final font = FontLoader('Inter')
      ..addFont(rootBundle.load('assets/fonts/Inter.ttf'));
    await font.load();
    SharedPreferences.setMockInitialValues({
      AppController.storageKey: jsonEncode(
        AppState(
          loaded: true,
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
        ).toJson(),
      ),
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
    Future<void> capture(String name) async {
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../design-review/$name.png'),
      );
    }

    await capture('01-welcome');
    c.read(routerProvider).go('/consent');
    await tester.pumpAndSettle();
    await capture('02-consent');
    await c.read(appProvider.notifier).acceptConsent();
    await tester.pumpAndSettle();
    await capture('03-today');
    c.read(routerProvider).go('/refine/presentation');
    await tester.pumpAndSettle();
    await capture('04-refinement');
    c
        .read(appProvider.notifier)
        .send(
          'I keep delaying the research outline. I haven’t started yet.',
          c.read(appProvider).tasks.first,
        );
    await tester.pump(const Duration(seconds: 1));
    c.read(routerProvider).go('/chat');
    await tester.pumpAndSettle();
    await capture('05-self-agent');
    await c
        .read(appProvider.notifier)
        .switchCondition(StudyCondition.friendAgent);
    c
        .read(appProvider.notifier)
        .send(
          'I keep delaying the research outline. I haven’t started yet.',
          c.read(appProvider).tasks.first,
        );
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    await capture('06-friend-agent');
    await c.read(appProvider.notifier).prepareFocus('literature');
    c.read(routerProvider).go('/focus');
    await tester.pumpAndSettle();
    await capture('07-focus');
    c.read(routerProvider).go('/insights');
    await tester.pumpAndSettle();
    await capture('08-insights');
    await c
        .read(appProvider.notifier)
        .switchCondition(StudyCondition.standardControl);
    c.read(routerProvider).go('/reminders');
    await tester.pumpAndSettle();
    await capture('09-control');
    await c.read(appProvider.notifier).setTheme(ThemeMode.dark);
    c.read(routerProvider).go('/today');
    await tester.pumpAndSettle();
    await capture('10-dark-theme');
    await c.read(appProvider.notifier).setTheme(ThemeMode.light);
    for (final entry in {
      '11-quick-capture': '/task/new',
      '12-check-in': '/check-in',
      '13-support-preferences': '/preferences',
      '14-task-recovery': '/task/literature',
    }.entries) {
      c.read(routerProvider).go(entry.value);
      await tester.pumpAndSettle();
      await capture(entry.key);
    }
    await tester.pumpWidget(const SizedBox());
    c.dispose();
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  }, skip: !const bool.fromEnvironment('CAPTURE_PREVIEWS'));
}
