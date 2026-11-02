import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_steps/app/reminders_controller.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/reminders.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'backend_connection_test.dart' show DevelopmentServer;
import 'reminders_test.dart' show FakeReminders;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);
  test(
    'forget saved accounts clears only connected caches and preferences',
    () async {
      SharedPreferences.setMockInitialValues({
        'small_steps.backend.v1.synthetic': 'pending synthetic report',
        'small_steps.demo.reminders.v1.account': 'synthetic preference',
        'unrelated': 'keep',
      });
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
      );
      final app = container.read(appProvider.notifier);
      await app.initialize();
      await app.forgetSavedDevelopmentAccounts();
      expect(prefs.containsKey('small_steps.backend.v1.synthetic'), isFalse);
      expect(
        prefs.containsKey('small_steps.demo.reminders.v1.account'),
        isFalse,
      );
      expect(prefs.getString('unrelated'), 'keep');
      expect(container.read(appProvider).tasks, isNotEmpty);
      container.dispose();
    },
  );
  for (final condition in StudyCondition.values) {
    test(
      '${condition.name}: account opt-in, scoped taps and honest schedule reports',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final service = FakeReminders();
        final container = ProviderContainer(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            reminderServiceProvider.overrideWithValue(service),
          ],
        );
        final app = container.read(appProvider.notifier);
        await app.initialize();
        final reminders = container.read(remindersProvider.notifier);
        await reminders.initialize();
        final server = DevelopmentServer(condition: condition.name);
        final at = DateTime.now().toUtc().add(const Duration(days: 1));
        server.tasks['shared'] = Task(
          id: 'shared',
          title: 'Synthetic task',
          reminder: at,
        ).toJson();
        await app.connectBackend(
          'http://127.0.0.1:8000',
          'synthetic',
          client: server.client(),
        );
        await reminders.refresh();
        expect(container.read(remindersProvider).preferences.enabled, isFalse);
        expect(service.pending, isEmpty);
        await reminders.setEnabled(true);
        expect(container.read(remindersProvider).error, isNull);
        expect(service.pending.single.taskId, 'shared');
        final scope = reminderScope('http://127.0.0.1:8000', 'DEV-1');
        expect(service.scope, scope);
        expect(service.pending.single.requestedAt.isAtSameMomentAs(at), isTrue);
        await reminders.refresh();
        final reports = container
            .read(appProvider)
            .events
            .where((e) => e.kind == 'notification_schedule_registered');
        expect(reports.length, 1);
        expect(reports.single.details['deliveryConfirmed'], isFalse);
        expect(reports.single.condition, condition.name);
        service.open(
          'shared',
        ); // Legacy/local-demo payload cannot open account task.
        expect(container.read(remindersProvider).openedTaskId, isNull);
        service.openTarget(ReminderTarget('shared', scope: scope));
        expect(container.read(remindersProvider).openedTaskId, 'shared');
        await app.persist();
        expect(
          container
              .read(appProvider)
              .events
              .where((e) => e.kind == 'notification_opened')
              .length,
          1,
        );
        await app.disconnectBackend();
        await reminders.refresh();
        expect(container.read(remindersProvider).preferences.enabled, isFalse);
        expect(container.read(remindersProvider).openedTaskId, isNull);
        expect(service.pending, isEmpty);
        container.dispose();
      },
    );
  }
  test(
    'cold account notification waits for matching authentication before opening',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final service = FakeReminders();
      final container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          reminderServiceProvider.overrideWithValue(service),
        ],
      );
      final app = container.read(appProvider.notifier);
      await app.initialize();
      final reminders = container.read(remindersProvider.notifier);
      await reminders.initialize();
      final scope = reminderScope('http://127.0.0.1:8000', 'DEV-1');
      service.openTarget(ReminderTarget('private', scope: scope));
      expect(container.read(remindersProvider).openedTaskId, isNull);
      expect(container.read(remindersProvider).connectionRequired, isTrue);
      reminders.acknowledgeConnectionRequest();
      final server = DevelopmentServer();
      server.tasks['private'] = Task(
        id: 'private',
        title: 'Synthetic owned task',
      ).toJson();
      await app.connectBackend(
        'http://127.0.0.1:8000',
        'synthetic',
        client: server.client(),
      );
      await reminders.refresh();
      expect(container.read(remindersProvider).openedTaskId, 'private');
      expect(
        container
            .read(appProvider)
            .events
            .where((e) => e.kind == 'notification_opened')
            .length,
        1,
      );
      container.dispose();
    },
  );
  test(
    'confirmed erasure removes only connected cache and restores local demo',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [preferencesProvider.overrideWithValue(prefs)],
      );
      final app = container.read(appProvider.notifier);
      await app.initialize();
      final localTasks = container.read(appProvider).tasks.length;
      final server = DevelopmentServer();
      await app.connectBackend(
        'http://127.0.0.1:8000',
        'synthetic',
        client: server.client(),
      );
      await app.saveTask(Task(id: 'private', title: 'Fictional private task'));
      final exported = await app.exportServerData();
      expect((exported['records'] as List).single['id'], 'server-only');
      expect(exported['devicePendingReports'], isA<Map>());
      expect(
        prefs.getKeys().where((k) => k.startsWith('small_steps.backend.v1.')),
        isNotEmpty,
      );
      await app.eraseDevelopmentData();
      expect(container.read(appProvider).connected, isFalse);
      expect(container.read(appProvider).tasks.length, localTasks);
      expect(
        prefs.getKeys().where((k) => k.startsWith('small_steps.backend.v1.')),
        isEmpty,
      );
      expect(server.tasks, isEmpty);
      container.dispose();
    },
  );
  test(
    'stable notification IDs survive ordering changes and differ by account',
    () {
      tzdata.initializeTimeZones();
      final first = Task(
        id: 'a',
        title: 'A',
        reminder: DateTime.utc(2030, 1, 1),
      );
      final second = Task(
        id: 'b',
        title: 'B',
        reminder: DateTime.utc(2030, 1, 2),
      );
      final plan = planReminders(
        [first, second],
        const ReminderPreferences(enabled: true),
        tz.UTC,
        DateTime.utc(2026),
      );
      final reordered = planReminders(
        [first, second.copyWith(reminder: DateTime.utc(2029))],
        const ReminderPreferences(enabled: true),
        tz.UTC,
        DateTime.utc(2026),
      );
      expect(plan.first.notificationId, reordered.last.notificationId);
      expect(reminderId('account-a', 'a'), isNot(reminderId('account-b', 'a')));
    },
  );
  test(
    'notification payloads reject malformed values and preserve Unicode IDs',
    () {
      const target = ReminderTarget('研究/task 🌱', scope: 'server/account');
      final restored = ReminderTarget.parse(target.payload)!;
      expect(restored.taskId, target.taskId);
      expect(restored.scope, target.scope);
      for (final invalid in [
        null,
        '',
        'task:',
        'task:%xx',
        'target:{}',
        'target:[]',
        'target:not-json',
      ]) {
        expect(ReminderTarget.parse(invalid), isNull);
      }
    },
  );
}
