import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:small_steps/app/reminders_controller.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/reminders.dart';
import 'package:small_steps/data/services/device_reminders.dart';

class FakeReminders implements ReminderService {
  @override
  bool supported = true;
  bool granted = false, allowRequest = true, fail = false;
  int requests = 0, cancellations = 0;
  String zone = 'Asia/Tokyo';
  List<PlannedReminder> pending = [];
  late void Function(ReminderTarget) openTarget;
  String scope = 'demo';
  void open(String id) => openTarget(ReminderTarget(id));
  @override
  Future<void> initialize(void Function(ReminderTarget) onOpen) async {
    openTarget = onOpen;
  }

  @override
  Future<String> timezoneName() async => zone;
  @override
  Future<bool> hasPermission() async => granted;
  @override
  Future<bool> requestPermission() async {
    requests++;
    granted = allowRequest;
    return granted;
  }

  @override
  Future<void> replacePending(
    List<PlannedReminder> reminders, {
    Set<String>? eligibleTaskIds,
    String scope = 'demo',
  }) async {
    pending = [];
    if (fail) {
      fail = false;
      throw StateError('Device schedule failed');
    }
    this.scope = scope;
    pending = List.of(reminders);
  }

  @override
  Future<void> cancelAll() async {
    cancellations++;
    pending = [];
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(tzdata.initializeTimeZones);
  group('quiet-hour planner', () {
    final base = DateTime.utc(2026, 10, 26);
    Task task(String id, DateTime at, {bool done = false}) =>
        Task(id: id, title: 'A task', due: at, reminder: at, done: done);
    // These cases isolate timezone conversion; burden-policy limits are tested separately.
    const on = ReminderPreferences(
      enabled: true,
      dailyLimit: 100,
      cooldownMinutes: 0,
    );
    test(
      'excludes completed, missing and expired reminders; orders future times',
      () {
        final zone = tz.getLocation('Asia/Tokyo');
        final plan = planReminders(
          [
            task('late', DateTime(2026, 10, 27, 12)),
            task('early', DateTime(2026, 10, 27, 9)),
            task('done', DateTime(2026, 10, 27, 9), done: true),
            task('past', DateTime(2020)),
            Task(id: 'none', title: 'None', due: base),
          ],
          on,
          zone,
          base,
        );
        expect(plan.map((p) => p.taskId), ['early', 'late']);
        expect(
          planReminders(
            [task('x', DateTime(2027))],
            const ReminderPreferences(),
            zone,
            base,
          ),
          isEmpty,
        );
      },
    );
    test(
      'overnight quiet hours shift late evening and early morning to end',
      () {
        final plan = planReminders(
          [
            task('late', DateTime(2026, 10, 26, 23)),
            task('early', DateTime(2026, 10, 27, 6)),
            task('edge', DateTime(2026, 10, 27, 8)),
          ],
          on.copyWith(quietHours: true),
          tz.getLocation('Asia/Tokyo'),
          base,
        );
        expect(
          plan.every((r) => r.scheduledAt.day == 27 && r.scheduledAt.hour == 8),
          isTrue,
        );
        expect(plan.where((r) => r.deferred).length, 2);
        expect(plan.map((r) => r.notificationId).toSet().length, 3);
      },
    );
    test('daytime quiet hours and boundary are half-open', () {
      final prefs = on.copyWith(
        quietHours: true,
        quietStart: 12 * 60,
        quietEnd: 14 * 60,
      );
      final plan = planReminders(
        [
          task('start', DateTime(2026, 10, 27, 12)),
          task('end', DateTime(2026, 10, 27, 14)),
        ],
        prefs,
        tz.UTC,
        base,
      );
      expect(plan.first.scheduledAt.hour, 14);
      expect(plan.singleWhere((p) => p.taskId == 'end').deferred, isFalse);
    });
    test('deferred reminders survive reopening after the requested time', () {
      final plan = planReminders(
        [task('night', DateTime(2026, 10, 26, 23))],
        on.copyWith(quietHours: true),
        tz.UTC,
        DateTime.utc(2026, 10, 27, 1),
      );
      expect(plan.single.scheduledAt, tz.TZDateTime(tz.UTC, 2026, 10, 27, 8));
      expect(
        planReminders(
          [task('night', DateTime(2026, 10, 26, 23))],
          on.copyWith(quietHours: true),
          tz.UTC,
          DateTime.utc(2026, 10, 27, 9),
        ),
        isEmpty,
      );
    });
    test('quiet-hour end follows DST calendar instead of adding 24 hours', () {
      final zone = tz.getLocation('America/New_York');
      final spring = planReminders(
        [task('spring', DateTime(2026, 3, 7, 23))],
        on.copyWith(quietHours: true),
        zone,
        DateTime.utc(2026, 3, 7),
      );
      expect(spring.single.scheduledAt.hour, 8);
      expect(
        spring.single.scheduledAt.timeZoneOffset,
        const Duration(hours: -4),
      );
      final fall = planReminders(
        [task('fall', DateTime(2026, 10, 31, 23))],
        on.copyWith(quietHours: true),
        zone,
        DateTime.utc(2026, 10, 31),
      );
      expect(fall.single.scheduledAt.hour, 8);
      expect(fall.single.scheduledAt.timeZoneOffset, const Duration(hours: -5));
    });
    test('wall-clock reminders follow the selected zone', () {
      final tasks = [task('travel', DateTime(2027, 1, 2, 9))];
      final tokyo = planReminders(
        tasks,
        on,
        tz.getLocation('Asia/Tokyo'),
        base,
      ).single;
      final london = planReminders(
        tasks,
        on,
        tz.getLocation('Europe/London'),
        base,
      ).single;
      expect(tokyo.scheduledAt.hour, 9);
      expect(london.scheduledAt.hour, 9);
      expect(tokyo.scheduledAt.toUtc(), isNot(london.scheduledAt.toUtc()));
    });
    test('invalid quiet hours are rejected on deserialization', () {
      expect(
        () => ReminderPreferences.fromJson({'quietStart': 60, 'quietEnd': 60}),
        throwsFormatException,
      );
      expect(
        () => ReminderPreferences.fromJson({'quietStart': 1440}),
        throwsFormatException,
      );
    });
  });
  group('device schedule coordinator', () {
    late ProviderContainer container;
    late SharedPreferences prefs;
    late FakeReminders service;
    late RemindersController controller;
    setUp(() async {
      final at = DateTime.now().add(const Duration(days: 2));
      final app = AppState(
        loaded: true,
        consent: true,
        tasks: [Task(id: 't1', title: 'Research task', due: at, reminder: at)],
      );
      SharedPreferences.setMockInitialValues({
        AppController.storageKey: jsonEncode(app.toJson()),
      });
      prefs = await SharedPreferences.getInstance();
      service = FakeReminders();
      container = ProviderContainer(
        overrides: [
          preferencesProvider.overrideWithValue(prefs),
          reminderServiceProvider.overrideWithValue(service),
        ],
      );
      await container.read(appProvider.notifier).initialize();
      controller = container.read(remindersProvider.notifier);
      await controller.initialize();
    });
    tearDown(() => container.dispose());
    test(
      'restart restores opt-in and quiet hours without requesting permission',
      () async {
        await controller.setEnabled(true);
        await controller.setQuietHours(enabled: true, start: 1260, end: 540);
        container.dispose();
        service = FakeReminders()..granted = true;
        container = ProviderContainer(
          overrides: [
            preferencesProvider.overrideWithValue(prefs),
            reminderServiceProvider.overrideWithValue(service),
          ],
        );
        await container.read(appProvider.notifier).initialize();
        await container.read(remindersProvider.notifier).initialize();
        expect(service.requests, 0);
        expect(service.pending.single.taskId, 't1');
        expect(
          container.read(remindersProvider).preferences.quietHours,
          isTrue,
        );
        expect(container.read(remindersProvider).preferences.quietStart, 1260);
      },
    );
    test(
      'startup never prompts; opt-in requests permission and schedules',
      () async {
        expect(service.requests, 0);
        expect(service.pending, isEmpty);
        await controller.setEnabled(true);
        expect(service.requests, 1);
        expect(service.pending.single.taskId, 't1');
        expect(container.read(remindersProvider).permission, isTrue);
        expect(
          jsonDecode(
            prefs.getString(RemindersController.storageKey)!,
          )['enabled'],
          isTrue,
        );
      },
    );
    test(
      'pause today reconciles reminders and resume restores eligible schedule',
      () async {
        await controller.setEnabled(true);
        expect(service.pending, isNotEmpty);
        await controller.pauseToday();
        final until = container
            .read(remindersProvider)
            .preferences
            .pausedUntil!;
        final now = DateTime.now();
        expect(until, DateTime(now.year, now.month, now.day + 1));
        // Future-day slots remain valid; only slots before pause expiry are suppressed.
        expect(
          service.pending.every((r) => !r.scheduledAt.isBefore(until)),
          isTrue,
        );
        await controller.pauseToday(resume: true);
        expect(
          container.read(remindersProvider).preferences.pausedUntil,
          isNull,
        );
        expect(service.pending, isNotEmpty);
      },
    );
    test('Tokyo pause suppresses today without replaying it tomorrow', () {
      final zone = tz.getLocation('Asia/Tokyo');
      final now = tz.TZDateTime(zone, 2026, 11, 2, 12);
      final until = tz.TZDateTime(zone, 2026, 11, 3);
      final plan = planReminders(
        [
          Task(
            id: 'today',
            title: 'Today',
            reminder: tz.TZDateTime(zone, 2026, 11, 2, 13),
          ),
          Task(
            id: 'tomorrow',
            title: 'Tomorrow',
            reminder: tz.TZDateTime(zone, 2026, 11, 3, 13),
          ),
        ],
        ReminderPreferences(enabled: true, pausedUntil: until),
        zone,
        now,
      );
      expect(plan.map((r) => r.taskId), ['tomorrow']);
    });
    test('permission denial is visible and queues nothing', () async {
      service.allowRequest = false;
      await controller.setEnabled(true);
      expect(service.pending, isEmpty);
      expect(container.read(remindersProvider).status, contains('not granted'));
    });
    test('completion and deletion cancel pending reminders', () async {
      await controller.setEnabled(true);
      await container
          .read(appProvider.notifier)
          .toggleTask(container.read(appProvider).tasks.single);
      await controller.refresh();
      expect(service.pending, isEmpty);
      await container
          .read(appProvider.notifier)
          .toggleTask(container.read(appProvider).tasks.single);
      await controller.refresh();
      expect(service.pending.length, 1);
      await container.read(appProvider.notifier).deleteTask('t1');
      await controller.refresh();
      expect(service.pending, isEmpty);
    });
    test('editing a reminder replaces the old scheduled time', () async {
      await controller.setEnabled(true);
      final original = service.pending.single.scheduledAt;
      final task = container.read(appProvider).tasks.single;
      await container
          .read(appProvider.notifier)
          .saveTask(
            task.copyWith(
              reminder: task.reminder!.add(const Duration(hours: 1)),
            ),
          );
      await controller.refresh();
      expect(service.pending.length, 1);
      expect(
        service.pending.single.scheduledAt,
        original.add(const Duration(hours: 1)),
      );
    });
    test(
      'condition switching does not alter notification content or timing',
      () async {
        await controller.setEnabled(true);
        final when = service.pending.single.scheduledAt;
        for (final condition in StudyCondition.values) {
          await container.read(appProvider.notifier).switchCondition(condition);
          await controller.refresh();
          expect(service.pending.single.scheduledAt, when);
          expect(service.pending.single.taskId, 't1');
        }
      },
    );
    test('OS revocation and opt-out cancel pending reminders', () async {
      await controller.setEnabled(true);
      service.granted = false;
      await controller.refresh();
      expect(service.pending, isEmpty);
      expect(container.read(remindersProvider).permission, isFalse);
      await controller.setEnabled(false);
      expect(container.read(remindersProvider).preferences.enabled, isFalse);
    });
    test(
      'scheduling failure is surfaced and retry restores the schedule',
      () async {
        service.fail = true;
        await controller.setEnabled(true);
        expect(container.read(remindersProvider).error, isNotNull);
        expect(service.pending, isEmpty);
        await controller.refresh();
        expect(container.read(remindersProvider).error, isNull);
        expect(service.pending.length, 1);
      },
    );
    test(
      'reset cancels delivered and pending notifications and removes preferences',
      () async {
        await controller.setEnabled(true);
        await controller.reset();
        expect(service.pending, isEmpty);
        expect(service.cancellations, 1);
        expect(prefs.containsKey(RemindersController.storageKey), isFalse);
      },
    );
    test(
      'tap exposes only a task id and never completes or starts work',
      () async {
        service.open('t1');
        expect(container.read(remindersProvider).openedTaskId, 't1');
        expect(container.read(appProvider).tasks.single.done, isFalse);
        expect(container.read(appProvider).focus, isNull);
        controller.acknowledgeOpen();
        expect(container.read(remindersProvider).openedTaskId, isNull);
      },
    );
    test(
      'unsupported platform does not request permissions or claim delivery',
      () async {
        service.supported = false;
        await controller.initialize();
        await controller.setEnabled(true);
        expect(service.requests, 0);
        expect(service.pending, isEmpty);
      },
    );
  });
}
