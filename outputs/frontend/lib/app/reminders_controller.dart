import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timezone/timezone.dart' as tz;
import '../data/reminders.dart';
import '../data/models.dart';
import '../data/services/device_reminders.dart';
import 'config.dart';
import 'state.dart';
import 'language.dart';

final reminderServiceProvider = Provider<ReminderService>(
  (ref) => UnsupportedReminderService(),
);
final remindersProvider = NotifierProvider<RemindersController, ReminderState>(
  RemindersController.new,
);

class ReminderState {
  final ReminderPreferences preferences;
  final bool ready, busy, supported, permission;
  final bool connectionRequired;
  final String? error, timezone, openedTaskId;
  final List<PlannedReminder> scheduled;
  final int waiting;
  const ReminderState({
    this.preferences = const ReminderPreferences(),
    this.ready = false,
    this.busy = false,
    this.supported = false,
    this.permission = false,
    this.connectionRequired = false,
    this.error,
    this.timezone,
    this.openedTaskId,
    this.scheduled = const [],
    this.waiting = 0,
  });
  ReminderState copyWith({
    ReminderPreferences? preferences,
    bool? ready,
    bool? busy,
    bool? supported,
    bool? permission,
    bool? connectionRequired,
    String? error,
    String? timezone,
    String? openedTaskId,
    bool clearOpened = false,
    List<PlannedReminder>? scheduled,
    int? waiting,
  }) => ReminderState(
    preferences: preferences ?? this.preferences,
    ready: ready ?? this.ready,
    busy: busy ?? this.busy,
    supported: supported ?? this.supported,
    permission: permission ?? this.permission,
    connectionRequired: connectionRequired ?? this.connectionRequired,
    error: error,
    timezone: timezone ?? this.timezone,
    openedTaskId: clearOpened ? null : openedTaskId ?? this.openedTaskId,
    scheduled: scheduled ?? this.scheduled,
    waiting: waiting ?? this.waiting,
  );
  String get status {
    if (error != null) {
      return error!;
    }
    if (!ready) {
      return 'Checking reminders…';
    }
    if (!supported) {
      return 'Scheduled delivery is available in the Android and iOS apps. This preview only saves reminder times.';
    }
    if (!preferences.enabled) {
      return 'Notifications are off. Your saved reminder times are kept.';
    }
    if (!permission) {
      return 'Notification permission is not granted. Allow notifications in your phone settings, then refresh.';
    }
    if (busy) {
      return 'Updating scheduled reminders…';
    }
    return '${scheduled.length} reminders scheduled on this device${waiting > 0 ? ' · $waiting waiting for a scheduling slot' : ''}.';
  }
}

class RemindersController extends Notifier<ReminderState> {
  static const storageKey = 'small_steps.demo.reminders.v1';
  static const maximumPending = 60;
  Future<void> _queue = Future.value();
  bool _initialized = false;
  ReminderTarget? _pendingTarget;
  String _scope = 'demo';
  String get _currentScope {
    final app = ref.read(appProvider);
    return reminderScope(app.backendUrl, app.backendId);
  }

  String get _preferencesKey =>
      _scope == 'demo' ? storageKey : '$storageKey.$_scope';
  final Set<String> _dismissTaskIds = {};
  ReminderService get service => ref.read(reminderServiceProvider);
  @override
  ReminderState build() {
    ref.listen(languageProvider, (previous, next) {
      if (_initialized && previous != next) refresh();
    });
    ref.listen(appProvider, (previous, next) {
      if (previous != null && previous.condition != next.condition) {
        _dismissTaskIds.addAll(previous.tasks.map((t) => t.id));
      }
      if (previous != null && previous.tasks != next.tasks) {
        for (final old in previous.tasks) {
          final current = next.tasks.where((t) => t.id == old.id).firstOrNull;
          if (current == null || old.reminder != current.reminder) {
            _dismissTaskIds.add(old.id);
          }
        }
      }
      if (_initialized &&
          (previous?.tasks != next.tasks ||
              previous?.consent != next.consent ||
              previous?.loaded != next.loaded ||
              previous?.backendId != next.backendId ||
              previous?.condition != next.condition ||
              previous?.backendUrl != next.backendUrl)) {
        refresh();
      }
    });
    return const ReminderState();
  }

  Future<void> _enqueue(Future<void> Function() operation) {
    _queue = _queue.then((_) async {
      if (!ref.mounted) {
        return;
      }
      state = state.copyWith(busy: true);
      try {
        await operation();
      } catch (_) {
        if (ref.mounted) {
          state = state.copyWith(
            ready: true,
            busy: false,
            scheduled: [],
            waiting: 0,
            error:
                'Could not update device reminders. Your tasks are saved. Retry to check notification permission and scheduling.',
          );
        }
      } finally {
        if (ref.mounted) {
          state = state.copyWith(busy: false, error: state.error);
        }
      }
    });
    return _queue;
  }

  Future<void> initialize() => _enqueue(() async {
    if (_initialized) {
      await _sync();
      return;
    }
    await service.initialize((target) {
      if (!ref.mounted || !AppConfig.researcherDemo) return;
      final app = ref.read(appProvider);
      if (target.scope != _currentScope) {
        if (!app.connected && target.scope != 'demo') {
          _pendingTarget = target;
          state = state.copyWith(connectionRequired: true, clearOpened: true);
        }
        return;
      }
      state = state.copyWith(openedTaskId: target.taskId, error: state.error);
      if (app.tasks.any((t) => t.id == target.taskId)) {
        ref
            .read(appProvider.notifier)
            .reportReminder('notification_opened', target.taskId, {
              'source': 'os_notification_callback',
              'category': target.category,
              'deliveryConfirmed': false,
            })
            .catchError((Object _) {
              if (ref.mounted) {
                state = state.copyWith(
                  error: 'Could not save the notification interaction report.',
                );
              }
            });
      }
    });
    _scope = _currentScope;
    var preferences = const ReminderPreferences();
    if (AppConfig.researcherDemo) {
      final raw = ref.read(preferencesProvider).getString(_preferencesKey);
      if (raw != null) {
        try {
          preferences = ReminderPreferences.fromJson(jsonDecode(raw));
        } on Object {
          await service.cancelAll();
          throw const FormatException('Invalid notification preferences');
        }
      }
    }
    _initialized = true;
    state = state.copyWith(
      ready: true,
      supported: service.supported,
      preferences: preferences,
    );
    await _sync();
  });
  Future<void> _save(ReminderPreferences value) async {
    if (!AppConfig.researcherDemo) {
      return;
    }
    final saved = await ref
        .read(preferencesProvider)
        .setString(_preferencesKey, jsonEncode(value.toJson()));
    if (!saved) {
      throw StateError('Could not save notification preferences');
    }
    state = state.copyWith(preferences: value);
  }

  Future<void> setEnabled(bool enabled) => _enqueue(() async {
    if (!AppConfig.researcherDemo ||
        !service.supported ||
        (enabled && !ref.read(appProvider).consent)) {
      return;
    }
    if (enabled) {
      await service.requestPermission();
    }
    await _save(state.preferences.copyWith(enabled: enabled));
    await _sync();
  });
  Future<void> pauseToday({bool resume = false}) => _enqueue(() async {
    final now = DateTime.now();
    await _save(
      state.preferences.copyWith(
        pausedUntil: DateTime(now.year, now.month, now.day + 1),
        clearPause: resume,
      ),
    );
    await _sync();
  });
  Future<void> setQuietHours({bool? enabled, int? start, int? end}) =>
      _enqueue(() async {
        final next = state.preferences.copyWith(
          quietHours: enabled,
          quietStart: start,
          quietEnd: end,
        );
        ReminderPreferences.fromJson(
          next.toJson(),
        ); // Validate before persistence.
        await _save(next);
        await _sync();
      });
  Future<void> refresh() => _initialized ? _enqueue(_sync) : initialize();
  Future<void> setPolicy({
    bool? plannedStarts,
    bool? deadlines,
    bool? agentVoice,
    int? dailyLimit,
    int? cooldownMinutes,
  }) => _enqueue(() async {
    final next = state.preferences.copyWith(
      plannedStarts: plannedStarts,
      deadlines: deadlines,
      agentVoice: agentVoice,
      dailyLimit: dailyLimit,
      cooldownMinutes: cooldownMinutes,
    );
    ReminderPreferences.fromJson(next.toJson());
    await _save(next);
    await _sync();
  });
  Future<void> _sync() async {
    final dismissed = Set<String>.of(_dismissTaskIds);
    _dismissTaskIds.clear();
    try {
      await _syncPlan(dismissed);
    } catch (_) {
      _dismissTaskIds.addAll(dismissed);
      rethrow;
    }
  }

  Future<void> _syncPlan(Set<String> dismissed) async {
    final app = ref.read(appProvider);
    final scope = _currentScope;
    final pending = _pendingTarget;
    final resumeTarget =
        pending != null &&
        pending.scope == scope &&
        app.consent &&
        !ref.read(appProvider.notifier).sessionTransitioning;
    if (resumeTarget) {
      _pendingTarget = null;
      state = state.copyWith(
        openedTaskId: pending.taskId,
        connectionRequired: false,
      );
      if (app.tasks.any((t) => t.id == pending.taskId)) {
        await ref
            .read(appProvider.notifier)
            .reportReminder('notification_opened', pending.taskId, {
              'source': 'authenticated_notification_resume',
              'category': pending.category,
              'deliveryConfirmed': false,
            });
      }
    }
    if (scope != _scope) {
      await service.cancelAll();
      _scope = scope;
      final raw = ref.read(preferencesProvider).getString(_preferencesKey);
      final preferences = raw == null
          ? const ReminderPreferences()
          : ReminderPreferences.fromJson(
              Map<String, dynamic>.from(jsonDecode(raw)),
            );
      state = state.copyWith(
        preferences: preferences,
        scheduled: [],
        clearOpened: !resumeTarget,
      );
    }
    if (!AppConfig.researcherDemo ||
        !app.loaded ||
        !app.consent ||
        !state.preferences.enabled ||
        !service.supported) {
      await service.replacePending([], eligibleTaskIds: {}, scope: _scope);
      state = state.copyWith(scheduled: [], waiting: 0, permission: false);
      return;
    }
    final permission = await service.hasPermission();
    if (!permission) {
      await service.replacePending([], eligibleTaskIds: {}, scope: _scope);
      state = state.copyWith(permission: false, scheduled: [], waiting: 0);
      return;
    }
    final zone = await service.timezoneName();
    final plan = planReminders(
      app.tasks,
      state.preferences,
      tz.getLocation(zone),
      DateTime.now(),
      scope: _scope,
      absoluteTimes: app.connected,
      condition: app.condition,
      history: app.events,
      language: ref.read(languageProvider).languageCode,
    );
    final scheduled = plan.take(maximumPending).toList();
    await service.replacePending(
      scheduled,
      scope: _scope,
      eligibleTaskIds: app.tasks
          .where((t) => !t.done && !t.paused && !dismissed.contains(t.id))
          .map((t) => t.id)
          .toSet(),
    );
    if (_currentScope != scope) {
      await service.cancelAll();
      return;
    }
    for (final reminder in scheduled) {
      await ref
          .read(appProvider.notifier)
          .reportReminder('notification_schedule_registered', reminder.taskId, {
            'scheduledAtUtc': reminder.scheduledAt.toUtc().toIso8601String(),
            'requestedAtUtc': reminder.requestedAt.toUtc().toIso8601String(),
            'timezone': zone,
            'source': 'os_schedule_api',
            'category': reminder.category,
            'language': reminder.language,
            'wording': state.preferences.agentVoice && app.condition.hasAgent
                ? app.condition.name
                : 'neutral',
            'policyVersion': 'reminders-v2',
            'deliveryConfirmed': false,
          });
    }
    state = state.copyWith(
      permission: true,
      timezone: zone,
      scheduled: scheduled,
      waiting: plan.length - scheduled.length,
    );
  }

  void acknowledgeOpen() {
    state = state.copyWith(clearOpened: true, error: state.error);
  }

  void acknowledgeConnectionRequest() {
    state = state.copyWith(connectionRequired: false, error: state.error);
  }

  Future<void> reset() => _enqueue(() async {
    _pendingTarget = null;
    await service.cancelAll();
    await ref.read(preferencesProvider).remove(_preferencesKey);
    state = ReminderState(ready: true, supported: service.supported);
  });
}
