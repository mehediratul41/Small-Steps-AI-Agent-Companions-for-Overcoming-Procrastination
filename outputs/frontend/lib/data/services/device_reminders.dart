import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import '../reminders.dart';

abstract interface class ReminderService {
  bool get supported;
  Future<void> initialize(void Function(ReminderTarget target) onOpen);
  Future<String> timezoneName();
  Future<bool> hasPermission();
  Future<bool> requestPermission();
  Future<void> replacePending(
    List<PlannedReminder> reminders, {
    Set<String>? eligibleTaskIds,
    String scope = 'demo',
  });
  Future<void> cancelAll();
}

/// Browser and test default. Native delivery is explicitly injected by main.
class UnsupportedReminderService implements ReminderService {
  @override
  bool get supported => false;
  @override
  Future<void> initialize(void Function(ReminderTarget) onOpen) async {}
  @override
  Future<String> timezoneName() async => 'Etc/UTC';
  @override
  Future<bool> hasPermission() async => false;
  @override
  Future<bool> requestPermission() async => false;
  @override
  Future<void> replacePending(
    List<PlannedReminder> reminders, {
    Set<String>? eligibleTaskIds,
    String scope = 'demo',
  }) async {}
  @override
  Future<void> cancelAll() async {}
}

class DeviceReminderService implements ReminderService {
  final FlutterLocalNotificationsPlugin plugin;
  DeviceReminderService({FlutterLocalNotificationsPlugin? plugin})
    : plugin = plugin ?? FlutterLocalNotificationsPlugin();
  @override
  bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  void _open(String? payload, void Function(ReminderTarget) onOpen) {
    final target = ReminderTarget.parse(payload);
    if (target != null) onOpen(target);
  }

  @override
  Future<void> initialize(void Function(ReminderTarget) onOpen) async {
    if (!supported) {
      return;
    }
    tzdata.initializeTimeZones();
    await plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('ic_notification'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (response) =>
          _open(response.payload, onOpen),
    );
    final launch = await plugin.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp ?? false) {
      _open(launch?.notificationResponse?.payload, onOpen);
    }
  }

  @override
  Future<String> timezoneName() async =>
      (await FlutterTimezone.getLocalTimezone()).identifier;
  @override
  Future<bool> hasPermission() async {
    if (!supported) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.areNotificationsEnabled() ??
          false;
    }
    final permission = await plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.checkPermissions();
    return permission?.isEnabled ?? false;
  }

  @override
  Future<bool> requestPermission() async {
    if (!supported) {
      return false;
    }
    if (defaultTargetPlatform == TargetPlatform.android) {
      return await plugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    return await plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >()
            ?.requestPermissions(alert: true, badge: false, sound: false) ??
        false;
  }

  @override
  Future<void> replacePending(
    List<PlannedReminder> reminders, {
    Set<String>? eligibleTaskIds,
    String scope = 'demo',
  }) async {
    if (!supported) {
      return;
    }
    await plugin.cancelAllPendingNotifications();
    try {
      // Pending alarms and already displayed notifications are separate OS lists.
      if (eligibleTaskIds != null) {
        for (final active in await plugin.getActiveNotifications()) {
          final target = ReminderTarget.parse(active.payload);
          if (target != null &&
              (target.scope != scope ||
                  !eligibleTaskIds.contains(target.taskId)) &&
              active.id != null) {
            await plugin.cancel(id: active.id!);
          }
        }
      }
      for (final reminder in reminders) {
        await plugin.zonedSchedule(
          id: reminder.notificationId,
          title: reminder.title,
          body: reminder.body,
          scheduledDate: reminder.scheduledAt,
          notificationDetails: const NotificationDetails(
            android: AndroidNotificationDetails(
              'task_reminders_v1',
              'Task reminders',
              channelDescription: 'Reminders you choose for your tasks',
              importance: Importance.defaultImportance,
              priority: Priority.defaultPriority,
              playSound: false,
              enableVibration: false,
              icon: 'ic_notification',
              visibility: NotificationVisibility.private,
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBanner: true,
              presentList: true,
              presentBadge: false,
              presentSound: false,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          payload: ReminderTarget(
            reminder.taskId,
            scope: scope,
            category: reminder.category,
          ).payload,
        );
      }
    } catch (_) {
      // A failed batch must not leave an undisclosed partial schedule.
      await plugin.cancelAllPendingNotifications();
      rethrow;
    }
  }

  @override
  Future<void> cancelAll() async {
    if (supported) {
      await plugin.cancelAll();
    }
  }
}
