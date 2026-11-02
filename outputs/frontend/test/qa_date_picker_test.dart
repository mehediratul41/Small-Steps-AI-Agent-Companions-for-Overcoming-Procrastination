import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_steps/features/task_actions.dart';

void main() {
  testWidgets(
    'existing distant dates remain editable without picker assertion',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () =>
                    chooseDateTime(context, initial: DateTime(2101, 12, 31)),
                child: const Text('Choose'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Choose'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(find.byType(DatePickerDialog), findsOneWidget);
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    },
  );
}
