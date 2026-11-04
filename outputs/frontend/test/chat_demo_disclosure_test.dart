import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_steps/app/app.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';
import 'widget_test.dart' show launch;

void main() {
  test(
    'demo greetings disclose scripted mode without inventing distress',
    () async {
      final repository = MockResearchRepository();
      for (final condition in [
        StudyCondition.selfAgent,
        StudyCondition.friendAgent,
      ]) {
        for (final language in ['en', 'ja']) {
          final reply = await repository.chat(
            'hi',
            condition,
            const Task(id: 't', title: 'Review a paper'),
            language: language,
          );
          expect(
            reply.text,
            contains(language == 'ja' ? 'デモ' : 'scripted demo'),
          );
          expect(reply.text, isNot(contains('frustrating')));
          expect(reply.taskId, 't');
        }
      }
    },
  );
  testWidgets('chat explains demo mode and opens backend connection', (
    tester,
  ) async {
    final container = await launch(tester);
    container.read(routerProvider).go('/chat');
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('About this conversation'));
    await tester.pumpAndSettle();
    final button = find.widgetWithText(TextButton, 'Connect AI backend');
    expect(button, findsOneWidget);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(find.text('Connect Small Steps'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
