import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:small_steps/data/reminders.dart';
import 'package:small_steps/data/services/device_reminders.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('dexterous.com/flutter/local_notifications');
  late List<MethodCall> calls;
  bool fail = false;
  setUp(() {
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    AndroidFlutterLocalNotificationsPlugin.registerWith();
    tzdata.initializeTimeZones();
    calls = [];
    fail = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call);
          if (call.method == 'initialize') {
            return true;
          }
          if (call.method == 'getNotificationAppLaunchDetails') {
            return {
              'notificationLaunchedApp': true,
              'notificationResponse': {
                'notificationId': 1,
                'notificationResponseType': 0,
                'payload': 'task:example%2Ftask',
              },
            };
          }
          if (call.method == 'getActiveNotifications') {
            return [
              {'id': 40, 'payload': 'task:removed'},
              {'id': 41, 'payload': 'task:kept'},
            ];
          }
          if (call.method == 'zonedSchedule' && fail) {
            throw PlatformException(code: 'schedule_failed');
          }
          return null;
        });
  });
  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });
  test(
    'native adapter uses silent neutral inexact reminders and task-only payload',
    () async {
      final service = DeviceReminderService();
      String? opened;
      await service.initialize((target) => opened = target.taskId);
      expect(opened, 'example/task');
      expect(
        calls.any((c) => c.method == 'requestNotificationsPermission'),
        isFalse,
      );
      final at = tz.TZDateTime.now(tz.UTC).add(const Duration(days: 1));
      await service.replacePending([
        PlannedReminder(
          taskId: 'example/task',
          requestedAt: at,
          scheduledAt: at,
          notificationId: 1,
        ),
      ]);
      final args =
          calls.singleWhere((c) => c.method == 'zonedSchedule').arguments
              as Map;
      expect(args['payload'], 'task:example%2Ftask');
      expect(args['title'], 'Small Steps · Task reminder');
      expect(args['body'], 'Open Small Steps to view your scheduled task.');
      final android = args['platformSpecifics'] as Map;
      expect(android['playSound'], isFalse);
      expect(android['enableVibration'], isFalse);
      expect(android['scheduleMode'], 'inexactAllowWhileIdle');
      expect(
        calls.where((c) => c.method == 'cancelAllPendingNotifications').length,
        1,
      );
    },
  );
  test(
    'native scheduling failure clears a partial replacement batch',
    () async {
      final service = DeviceReminderService();
      await service.initialize((_) {});
      fail = true;
      final at = tz.TZDateTime.now(tz.UTC).add(const Duration(days: 1));
      await expectLater(
        service.replacePending([
          PlannedReminder(
            taskId: 't',
            requestedAt: at,
            scheduledAt: at,
            notificationId: 1,
          ),
        ]),
        throwsA(isA<PlatformException>()),
      );
      expect(
        calls.where((c) => c.method == 'cancelAllPendingNotifications').length,
        2,
      );
    },
  );
  test(
    'completion/deletion cleanup removes displayed obsolete reminders only',
    () async {
      final service = DeviceReminderService();
      await service.initialize((_) {});
      await service.replacePending([], eligibleTaskIds: {'kept'});
      final canceled = calls
          .where((c) => c.method == 'cancel')
          .map((c) => c.arguments is Map ? c.arguments['id'] : c.arguments)
          .toList();
      expect(canceled, [40]);
    },
  );
  test(
    'turning reminders off clears displayed task notifications too',
    () async {
      final service = DeviceReminderService();
      await service.initialize((_) {});
      await service.replacePending([], eligibleTaskIds: {});
      expect(calls.where((c) => c.method == 'cancel').length, 2);
    },
  );
}
