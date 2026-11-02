import 'dart:convert';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_steps/app/app.dart';
import 'package:small_steps/app/config.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';

void main() {
  testWidgets('participant build cannot load demo assignment or open chat', (
    tester,
  ) async {
    expect(
      AppConfig.researcherDemo,
      isFalse,
      reason: 'Run with --dart-define=RESEARCHER_DEMO=false',
    );
    SharedPreferences.setMockInitialValues({
      AppController.storageKey: jsonEncode(
        const AppState(
          loaded: true,
          consent: true,
          condition: StudyCondition.friendAgent,
        ).toJson(),
      ),
    });
    final prefs = await SharedPreferences.getInstance();
    final c = ProviderContainer(
      overrides: [preferencesProvider.overrideWithValue(prefs)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(container: c, child: const SmallStepsApp()),
    );
    await tester.pumpAndSettle();
    for (final route in ['/chat', '/check-in', '/preferences', '/demo-data']) {
      c.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      expect(find.text('Awaiting study configuration'), findsOneWidget);
    }
    expect(c.read(appProvider).consent, isFalse);
    expect(c.read(appProvider).tasks, isEmpty);
    await expectLater(
      c.read(appProvider.notifier).switchCondition(StudyCondition.friendAgent),
      throwsA(isA<AppFailure>()),
    );
    await tester.pumpWidget(const ProviderScope(child: SizedBox()));
    c.dispose();
  }, skip: AppConfig.researcherDemo);
}
