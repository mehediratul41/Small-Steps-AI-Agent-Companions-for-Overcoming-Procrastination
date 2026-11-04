import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_steps/app/app.dart';
import 'package:small_steps/app/language.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/repository.dart';
import 'widget_test.dart' show launch;

Future<void> choose(WidgetTester tester, String id) async {
  await tester.tap(find.text('Task context'));
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(ValueKey('conversation-$id')));
  await tester.tap(find.byKey(ValueKey('conversation-$id')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'drafts survive navigation and remain separate by conversation and agent',
    (tester) async {
      final c = await launch(tester);
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('chat-composer')),
        '私の literature draft',
      );
      await tester.pump();
      c.read(routerProvider).go('/today');
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      String draft() => tester
          .widget<TextField>(find.byKey(const ValueKey('chat-composer')))
          .controller!
          .text;
      expect(draft(), '私の literature draft');
      await choose(tester, '__general__');
      expect(draft(), '');
      await tester.enterText(
        find.byKey(const ValueKey('chat-composer')),
        'General draft',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Friend-Agent'));
      await tester.pumpAndSettle();
      expect(draft(), '');
      await tester.enterText(
        find.byKey(const ValueKey('chat-composer')),
        'Friend draft',
      );
      await tester.pump();
      await tester.tap(find.widgetWithText(ChoiceChip, 'Self-Agent'));
      await tester.pumpAndSettle();
      expect(draft(), 'General draft');
      await choose(tester, 'literature');
      expect(draft(), '私の literature draft');
    },
  );

  testWidgets(
    'rapid sends append one request and preserve an editable failed message',
    (tester) async {
      final c = await launch(tester);
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      final send = find.byTooltip('Send message');
      expect(
        tester
            .widget<IconButton>(
              find.byWidgetPredicate(
                (w) => w is IconButton && w.tooltip == 'Send message',
              ),
            )
            .onPressed,
        isNull,
      );
      (c.read(repositoryProvider) as MockResearchRepository).failNext = true;
      await tester.enterText(
        find.byKey(const ValueKey('chat-composer')),
        'One synthetic attempt',
      );
      await tester.pump();
      await tester.tap(send);
      await tester.tap(send);
      await tester.pumpAndSettle();
      expect(c.read(appProvider).messages, hasLength(1));
      expect(c.read(appProvider).messages.single.delivery, 'failed');
      expect(find.text('Couldn’t send'), findsOneWidget);
      await tester.tap(find.byTooltip('Message options'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Edit message'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const ValueKey('chat-composer')))
            .controller!
            .text,
        'One synthetic attempt',
      );
      expect(c.read(appProvider).messages.single.delivery, 'cancelled');
    },
  );

  testWidgets(
    'conversation search uses loaded message content and preserves raw preview',
    (tester) async {
      final c = await launch(tester);
      final operation = c
          .read(appProvider.notifier)
          .send('固有の検索語 ABC', c.read(appProvider).tasks.first);
      await tester.pump(const Duration(seconds: 1));
      await operation;
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Task context'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('conversation-search')),
        '固有の検索語',
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('conversation-literature')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('conversation-methodology')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('conversation-__general__')),
        findsNothing,
      );
      await tester.enterText(
        find.byKey(const ValueKey('conversation-search')),
        'does-not-exist',
      );
      await tester.pumpAndSettle();
      expect(find.text('No matching conversations'), findsOneWidget);
      expect(c.read(appProvider).messages.first.text, '固有の検索語 ABC');
    },
  );

  testWidgets(
    'long-press copies exact text without changing the conversation',
    (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      final c = await launch(tester);
      final operation = c
          .read(appProvider.notifier)
          .send('Copy 日本語 🔎 exactly', c.read(appProvider).tasks.first);
      await tester.pump(const Duration(seconds: 1));
      await operation;
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Copy 日本語 🔎 exactly'));
      await tester.pumpAndSettle();
      await tester.longPress(find.text('Copy 日本語 🔎 exactly'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Copy message'));
      await tester.pumpAndSettle();
      expect(copied, 'Copy 日本語 🔎 exactly');
      expect(c.read(appProvider).messages, hasLength(2));
    },
  );

  testWidgets(
    'reading older text during a reply does not force a jump and offset restores',
    (tester) async {
      final c = await launch(tester);
      final first = c
          .read(appProvider.notifier)
          .send(
            List.filled(100, 'Read one small part.').join(' '),
            c.read(appProvider).tasks.first,
          );
      await tester.pump(const Duration(seconds: 1));
      await first;
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('chat-composer')),
        'Second synthetic request',
      );
      await tester.pump();
      await tester.tap(find.byTooltip('Send message'));
      await tester.pump(const Duration(milliseconds: 20));
      await tester.drag(find.byType(ListView).first, const Offset(0, 2500));
      await tester.pump(const Duration(milliseconds: 20));
      final scroll = tester
          .widget<ListView>(find.byType(ListView).first)
          .controller!;
      final before = scroll.offset;
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();
      expect(scroll.offset, closeTo(before, 1));
      expect(find.text('New reply · Show latest'), findsOneWidget);
      c.read(routerProvider).go('/today');
      await tester.pumpAndSettle();
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      final restored = tester
          .widget<ListView>(find.byType(ListView).first)
          .controller!;
      expect(restored.offset, closeTo(before, 1));
    },
  );

  for (final size in [const Size(320, 568), const Size(844, 390)]) {
    testWidgets('Japanese chat supports large text and keyboard: $size', (
      tester,
    ) async {
      final c = await launch(tester, size: size);
      await c.read(languageProvider.notifier).setLanguage('ja');
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      tester.view.viewInsets = const FakeViewPadding(bottom: 200);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('chat-composer')),
        '日本語の下書き\n次の行',
      );
      await tester.pump();
      final field = tester.getRect(find.byKey(const ValueKey('chat-composer')));
      expect(field.bottom, lessThanOrEqualTo(size.height - 200));
      expect(tester.takeException(), isNull);
    });
  }

  test(
    'HTTP failures carry safe presentation categories without changing retry policy',
    () async {
      for (final entry in {
        401: 'authentication',
        403: 'validation',
        409: 'validation',
        429: 'limited',
        503: 'provider',
        504: 'timeout',
      }.entries) {
        final dio = Dio(BaseOptions(baseUrl: 'https://synthetic.example'));
        dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (request, handler) {
              handler.reject(
                DioException(
                  requestOptions: request,
                  response: Response(
                    requestOptions: request,
                    statusCode: entry.key,
                  ),
                  type: DioExceptionType.badResponse,
                ),
              );
            },
          ),
        );
        final api = ApiResearchRepository(
          'https://synthetic.example',
          client: dio,
        );
        await expectLater(
          api.participant(),
          throwsA(
            isA<AppFailure>().having((e) => e.code, 'category', entry.value),
          ),
        );
        api.close();
      }
    },
  );
  testWidgets('render synthetic messaging for visual review', (tester) async {
    for (final font in {
      'MaterialIcons': 'fonts/MaterialIcons-Regular.otf',
      'Inter': 'assets/fonts/Inter.ttf',
      'Noto Sans JP': 'assets/fonts/NotoSansJP.ttf',
    }.entries) {
      await (FontLoader(font.key)..addFont(rootBundle.load(font.value))).load();
    }
    for (final lang in ['en', 'ja']) {
      final c = await launch(tester);
      await c.read(languageProvider.notifier).setLanguage(lang);
      final request = c
          .read(appProvider.notifier)
          .send(
            lang == 'ja'
                ? '小さな一歩から始めたいです。'
                : 'I would like to start with one small step.',
            c.read(appProvider).tasks.first,
          );
      await tester.pump(const Duration(seconds: 1));
      await request;
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('../design-review/messaging-$lang.png'),
      );
    }
  }, skip: !const bool.fromEnvironment('CAPTURE_MESSAGING'));
}
