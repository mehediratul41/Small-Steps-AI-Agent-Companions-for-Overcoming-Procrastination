import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:small_steps/app/app.dart';
import 'package:small_steps/app/language.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/app/reminders_controller.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';
import 'package:small_steps/l10n/strings.dart';
import 'reminders_test.dart' show FakeReminders;
import 'widget_test.dart' show launch;

class LanguageSpy extends MockResearchRepository {
  final languages = <String>[];
  @override
  Future<ChatMessage> chat(
    String message,
    StudyCondition condition,
    Task? task, {
    SupportProfile profile = const SupportProfile(),
    String language = 'en',
  }) {
    languages.add(language);
    return super.chat(
      message,
      condition,
      task,
      profile: profile,
      language: language,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tzdata.initializeTimeZones();
  test(
    'canonical values translate for display without translating arbitrary text',
    () {
      final ja = lookupAppLocalizations(const Locale('ja'));
      expect(ja.text('Normal'), '通常');
      expect(ja.text('Study AI'), 'Study AI');
      expect(ja.text('Self-Agent'), 'セルフ・エージェント');
    },
  );
  group('language state and agent integration', () {
    late ProviderContainer c;
    late LanguageSpy spy;
    setUp(() async {
      SharedPreferences.setMockInitialValues({
        AppController.storageKey: jsonEncode(
          AppState(
            loaded: true,
            consent: true,
            tasks: [
              Task(
                id: 't1',
                title: 'Today 日本語 🌱',
                reminder: DateTime.now().add(const Duration(days: 1)),
              ),
            ],
          ).toJson(),
        ),
      });
      final prefs = await SharedPreferences.getInstance();
      spy = LanguageSpy();
      c = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          repositoryProvider.overrideWithValue(spy),
        ],
      );
      await c.read(appProvider.notifier).initialize();
    });
    tearDown(() => c.dispose());
    test(
      'language persists independently of condition and user content',
      () async {
        final original = c.read(appProvider).tasks.single.toJson();
        await c.read(languageProvider.notifier).setLanguage('ja');
        await c
            .read(appProvider.notifier)
            .switchCondition(StudyCondition.friendAgent);
        final prefs = c.read(preferencesProvider);
        final restored = ProviderContainer(
          overrides: [preferencesProvider.overrideWithValue(prefs)],
        );
        addTearDown(restored.dispose);
        expect(restored.read(languageProvider).languageCode, 'ja');
        expect(c.read(appProvider).tasks.single.toJson(), original);
        expect(c.read(appProvider).condition, StudyCondition.friendAgent);
        await expectLater(
          c.read(languageProvider.notifier).setLanguage('fr'),
          throwsArgumentError,
        );
        expect(c.read(languageProvider).languageCode, 'ja');
      },
    );
    test(
      'Japanese replies keep persona and previous English messages',
      () async {
        final app = c.read(appProvider.notifier),
            task = c.read(appProvider).tasks.single;
        await app.send('Help me begin', task);
        final original = c.read(appProvider).messages.last.text;
        await c.read(languageProvider.notifier).setLanguage('ja');
        await app.send('始めるのを手伝って', task);
        expect(c.read(appProvider).messages.last.text, contains('ご自身の目標'));
        expect(c.read(appProvider).messages.last.language, 'ja');
        expect(c.read(appProvider).messages[1].text, original);
        await app.switchCondition(StudyCondition.friendAgent);
        await app.send('始めるのを手伝って', task);
        expect(c.read(appProvider).messages.last.text, contains('一緒に'));
        expect(c.read(appProvider).chats['selfAgent']![1].text, original);
      },
    );
    test(
      'retry retains original request language after interface switches',
      () async {
        final app = c.read(appProvider.notifier),
            task = c.read(appProvider).tasks.single;
        await c.read(languageProvider.notifier).setLanguage('ja');
        spy.failNext = true;
        await expectLater(app.send('手伝って', task), throwsException);
        final pending = c.read(appProvider).messages.single;
        await c.read(languageProvider.notifier).setLanguage('en');
        await app.send(
          pending.text,
          task,
          retry: true,
          retryMessageId: pending.id,
        );
        expect(spy.languages, ['ja', 'ja']);
        expect(c.read(appProvider).messages.where((m) => m.user), hasLength(1));
        expect(c.read(appProvider).messages.last.language, 'ja');
      },
    );
    test(
      'Japanese proposals require approval and check-ins keep canonical codes',
      () async {
        await c.read(languageProvider.notifier).setLanguage('ja');
        final app = c.read(appProvider.notifier),
            task = c.read(appProvider).tasks.single;
        final steps = await app.suggestions(task, 0);
        expect(steps.first.title, contains('小さく'));
        expect(c.read(appProvider).tasks.single.subtasks, isEmpty);
        final correction = await app.proposeCorrection(task);
        expect(correction.correction.reason, contains('ご自身'));
        expect(c.read(appProvider).tasks.single.title, task.title);
        await app.saveCheckIn('Daily', {'burden': 'Okay'});
        expect(c.read(appProvider).checkIns.single.language, 'ja');
        expect(c.read(appProvider).checkIns.single.answers, {'burden': 'Okay'});
        expect(c.read(appProvider).events.last.details['uiLanguage'], 'ja');
      },
    );
    test(
      'language change reschedules Japanese copy without duplicate slots',
      () async {
        final service = FakeReminders();
        final remindersContainer = ProviderContainer(
          overrides: [
            preferencesProvider.overrideWithValue(c.read(preferencesProvider)),
            reminderServiceProvider.overrideWithValue(service),
          ],
        );
        addTearDown(remindersContainer.dispose);
        await remindersContainer.read(appProvider.notifier).initialize();
        final reminders = remindersContainer.read(remindersProvider.notifier);
        await reminders.initialize();
        await reminders.setEnabled(true);
        final before = service.pending.single;
        await remindersContainer
            .read(languageProvider.notifier)
            .setLanguage('ja');
        await reminders.refresh();
        final after = service.pending.single;
        expect(after.language, 'ja');
        expect(after.title, contains('リマインダー'));
        expect(after.notificationId, before.notificationId);
        expect(after.scheduledAt, before.scheduledAt);
        expect(after.body, isNot(contains('Today 日本語')));
      },
    );
  });

  testWidgets(
    'globe switches English and Japanese without altering task text',
    (tester) async {
      final c = await launch(tester);
      final titles = c.read(appProvider).tasks.map((t) => t.title).toList();
      await tester.tap(find.byTooltip('Choose language').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('日本語'));
      await tester.pumpAndSettle();
      expect(find.text('今日').last, findsOneWidget);
      expect(find.text('チャット'), findsOneWidget);
      expect(find.text('一つずつ、自分のペースで。'), findsOneWidget);
      expect(c.read(appProvider).tasks.map((t) => t.title), titles);
      expect(
        c.read(preferencesProvider).getString(LanguageController.storageKey),
        'ja',
      );
      expect(
        MaterialLocalizations.of(
          tester.element(find.byType(Scaffold).last),
        ).cancelButtonLabel,
        'キャンセル',
      );
      await tester.tap(find.byTooltip('言語を選択').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('One task, at your own pace.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Japanese task form saves original text and canonical priority', (
    tester,
  ) async {
    final c = await launch(tester);
    await c.read(languageProvider.notifier).setLanguage('ja');
    c.read(routerProvider).go('/task/new');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Today');
    await tester.tap(find.text('タスクを保存'));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
    expect(c.read(appProvider).tasks.last.title, 'Today');
    expect(c.read(appProvider).tasks.last.priority, 'Normal');
    expect(find.text('Today'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('Japanese core routes at 150% text on $size', (tester) async {
      final c = await launch(tester, size: size);
      await c.read(languageProvider.notifier).setLanguage('ja');
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      for (final path in [
        '/today',
        '/tasks',
        '/chat',
        '/insights',
        '/settings',
        '/reminders',
        '/task/new',
        '/task/literature',
        '/preferences',
        '/check-in',
      ]) {
        c.read(routerProvider).go(path);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: path);
      }
    });
  }

  testWidgets('Japanese onboarding stays explicitly a demo', (tester) async {
    final c = await launch(tester, consent: false);
    await c.read(languageProvider.notifier).setLanguage('ja');
    await tester.pumpAndSettle();
    expect(find.text('はじめる'), findsOneWidget);
    c.read(routerProvider).go('/consent');
    await tester.pumpAndSettle();
    expect(c.read(appProvider).consent, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('capture Japanese screens for visual review', (tester) async {
    for (final entry in {
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'Inter': 'assets/fonts/Inter.ttf',
      'Noto Sans JP': 'assets/fonts/NotoSansJP.ttf',
    }.entries) {
      await (FontLoader(
        entry.key,
      )..addFont(rootBundle.load(entry.value))).load();
    }
    final c = await launch(tester);
    await c.read(languageProvider.notifier).setLanguage('ja');
    for (final entry in {
      'today': '/today',
      'chat': '/chat',
      'tasks': '/tasks',
      'settings': '/settings',
      'check-in': '/check-in',
    }.entries) {
      c.read(routerProvider).go(entry.value);
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../../../work/ja-review/${entry.key}.png'),
      );
    }
  }, skip: !const bool.fromEnvironment('CAPTURE_JA_PREVIEWS'));
}
