import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_steps/app/app.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';
import 'widget_test.dart' show launch;

void main() {
  testWidgets(
    'one-tap agent selector stays visible at the bottom of a conversation',
    (tester) async {
      final c = await launch(tester);
      final sending = c
          .read(appProvider.notifier)
          .send(
            List.filled(
              25,
              'Help me start one small part of my task.',
            ).join(' '),
            c.read(appProvider).tasks.first,
          );
      await tester.pump(const Duration(seconds: 1));
      await sending;
      c.read(routerProvider).go('/chat');
      await tester.pumpAndSettle();
      await tester.drag(find.byType(ListView).first, const Offset(0, -1800));
      await tester.pumpAndSettle();
      final friend = find.widgetWithText(ChoiceChip, 'Friend-Agent');
      expect(friend.hitTestable(), findsOneWidget);
      await tester.tap(friend);
      await tester.pumpAndSettle();
      expect(c.read(appProvider).condition, StudyCondition.friendAgent);
      expect(c.read(appProvider).messages, isEmpty);
      expect(c.read(appProvider).chats['selfAgent'], hasLength(2));
      expect(
        find.widgetWithText(ChoiceChip, 'Self-Agent').hitTestable(),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
