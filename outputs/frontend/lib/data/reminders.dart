import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'models.dart';

/// No credentials or task content enter a notification payload.
class ReminderTarget {
  final String taskId, scope, category;
  const ReminderTarget(
    this.taskId, {
    this.scope = 'demo',
    this.category = 'manual',
  });
  String get payload => scope == 'demo' && category == 'manual'
      ? 'task:${Uri.encodeComponent(taskId)}'
      : 'target:${jsonEncode({'scope': scope, 'taskId': taskId, 'category': category})}';
  static ReminderTarget? parse(String? payload) {
    try {
      if (payload?.startsWith('task:') ?? false) {
        final id = Uri.decodeComponent(payload!.substring(5));
        return id.isEmpty ? null : ReminderTarget(id);
      }
      if (payload?.startsWith('target:') ?? false) {
        final value = jsonDecode(payload!.substring(7));
        if (value is Map &&
            value['scope'] is String &&
            value['taskId'] is String &&
            (value['scope'] as String).isNotEmpty &&
            (value['taskId'] as String).isNotEmpty) {
          final category = value['category'] ?? 'manual';
          if (!['manual', 'planned_start', 'deadline'].contains(category)) {
            return null;
          }
          return ReminderTarget(
            value['taskId'],
            scope: value['scope'],
            category: category,
          );
        }
      }
    } on Object {
      /* Ignore malformed external payloads. */
    }
    return null;
  }
}

String reminderScope(String? server, String? participant) => participant == null
    ? 'demo'
    : '${Uri.encodeComponent(server ?? '')}/${Uri.encodeComponent(participant)}';

int reminderId(String scope, String taskId) {
  var hash = 5381;
  for (final byte in utf8.encode('$scope\u0000$taskId')) {
    // Intermediate values remain exactly representable on Dart web too.
    hash = ((hash * 31) ^ byte) & 0x7fffffff;
  }
  return hash == 0 ? 1 : hash;
}

class ReminderPreferences {
  final DateTime? pausedUntil;
  final bool enabled, quietHours;
  final bool plannedStarts, deadlines, agentVoice;
  final int dailyLimit, cooldownMinutes;
  final int quietStart, quietEnd;
  const ReminderPreferences({
    this.pausedUntil,
    this.enabled = false,
    this.quietHours = false,
    this.quietStart = 22 * 60,
    this.quietEnd = 8 * 60,
    this.plannedStarts = false,
    this.deadlines = false,
    this.agentVoice = false,
    this.dailyLimit = 3,
    this.cooldownMinutes = 60,
  });
  ReminderPreferences copyWith({
    DateTime? pausedUntil,
    bool clearPause = false,
    bool? enabled,
    bool? quietHours,
    int? quietStart,
    int? quietEnd,
    bool? plannedStarts,
    bool? deadlines,
    bool? agentVoice,
    int? dailyLimit,
    int? cooldownMinutes,
  }) => ReminderPreferences(
    pausedUntil: clearPause ? null : pausedUntil ?? this.pausedUntil,
    enabled: enabled ?? this.enabled,
    quietHours: quietHours ?? this.quietHours,
    quietStart: quietStart ?? this.quietStart,
    quietEnd: quietEnd ?? this.quietEnd,
    plannedStarts: plannedStarts ?? this.plannedStarts,
    deadlines: deadlines ?? this.deadlines,
    agentVoice: agentVoice ?? this.agentVoice,
    dailyLimit: dailyLimit ?? this.dailyLimit,
    cooldownMinutes: cooldownMinutes ?? this.cooldownMinutes,
  );
  Map<String, dynamic> toJson() => {
    'pausedUntil': pausedUntil?.toUtc().toIso8601String(),
    'enabled': enabled,
    'quietHours': quietHours,
    'quietStart': quietStart,
    'quietEnd': quietEnd,
    'plannedStarts': plannedStarts,
    'deadlines': deadlines,
    'agentVoice': agentVoice,
    'dailyLimit': dailyLimit,
    'cooldownMinutes': cooldownMinutes,
  };
  factory ReminderPreferences.fromJson(Map<String, dynamic> json) {
    final start = json['quietStart'] as int? ?? 22 * 60;
    final end = json['quietEnd'] as int? ?? 8 * 60;
    final daily = json['dailyLimit'] as int? ?? 3;
    final cooldown = json['cooldownMinutes'] as int? ?? 60;
    if (daily < 1 || daily > 100 || cooldown < 0 || cooldown > 1440) {
      throw const FormatException('Invalid notification limits');
    }
    if (start < 0 || start >= 1440 || end < 0 || end >= 1440 || start == end) {
      throw const FormatException('Invalid quiet hours');
    }
    return ReminderPreferences(
      pausedUntil: DateTime.tryParse(json['pausedUntil'] as String? ?? ''),
      enabled: json['enabled'] as bool? ?? false,
      quietHours: json['quietHours'] as bool? ?? false,
      quietStart: start,
      quietEnd: end,
      plannedStarts: json['plannedStarts'] as bool? ?? false,
      deadlines: json['deadlines'] as bool? ?? false,
      agentVoice: json['agentVoice'] as bool? ?? false,
      dailyLimit: daily,
      cooldownMinutes: cooldown,
    );
  }
}

class PlannedReminder {
  final String taskId;
  final String category, title, body;
  final String language;
  final tz.TZDateTime requestedAt, scheduledAt;
  final int notificationId;
  const PlannedReminder({
    required this.taskId,
    required this.requestedAt,
    required this.scheduledAt,
    required this.notificationId,
    this.category = 'manual',
    this.title = 'Small Steps · Task reminder',
    this.body = 'Open Small Steps to view your scheduled task.',
    this.language = 'en',
  });
  bool get deferred => !scheduledAt.isAtSameMomentAs(requestedAt);
}

/// One-shot slots with a common policy across conditions. Persona changes copy only.
/// Calendar constructors (rather than adding 24 hours) preserve DST transitions.
List<PlannedReminder> planReminders(
  List<Task> tasks,
  ReminderPreferences preferences,
  tz.Location location,
  DateTime now, {
  String scope = 'demo',
  bool absoluteTimes = false,
  StudyCondition condition = StudyCondition.standardControl,
  List<BehaviorEvent> history = const [],
  String language = 'en',
}) {
  if (!preferences.enabled) {
    return [];
  }
  final candidates =
      <
        ({
          Task task,
          String category,
          tz.TZDateTime requested,
          tz.TZDateTime scheduled,
        })
      >[];
  for (final task in tasks) {
    if (task.done || task.paused) {
      continue;
    }
    final times = <String, DateTime>{
      if (task.reminder != null) 'manual': task.reminder!,
      if (preferences.plannedStarts &&
          task.firstStartedAt == null &&
          task.plannedStart != null)
        'planned_start': task.plannedStart!,
      if (preferences.deadlines && task.due != null) 'deadline': task.due!,
    };
    final seen = <int>{};
    for (final entry in times.entries) {
      final raw = entry.value;
      final requested = raw.isUtc || absoluteTimes
          ? tz.TZDateTime.from(raw, location)
          : tz.TZDateTime(
              location,
              raw.year,
              raw.month,
              raw.day,
              raw.hour,
              raw.minute,
              raw.second,
              raw.millisecond,
              raw.microsecond,
            );
      // Suppress rather than defer: never create a burst when the pause ends.
      if (preferences.pausedUntil != null &&
          requested.isBefore(preferences.pausedUntil!)) {
        continue;
      }
      var scheduled = requested;
      final minute = requested.hour * 60 + requested.minute;
      final start = preferences.quietStart, end = preferences.quietEnd;
      final overnight = start > end;
      final quiet =
          preferences.quietHours &&
          (overnight
              ? (minute >= start || minute < end)
              : (minute >= start && minute < end));
      if (quiet) {
        scheduled = tz.TZDateTime(
          location,
          requested.year,
          requested.month,
          requested.day + (overnight && minute >= start ? 1 : 0),
          end ~/ 60,
          end % 60,
        );
      }
      // Never replay an expired reminder. A deferred reminder remains eligible
      // until its actual scheduled time, including after a restart.
      if (scheduled.isAfter(now) &&
          seen.add(scheduled.millisecondsSinceEpoch)) {
        candidates.add((
          task: task,
          category: entry.key,
          requested: requested,
          scheduled: scheduled,
        ));
      }
    }
  }
  candidates.sort((a, b) {
    final time = a.scheduled.compareTo(b.scheduled);
    return time == 0
        ? '${a.task.id}:${a.category}'.compareTo('${b.task.id}:${b.category}')
        : time;
  });
  // Count prior reserved slots, not presumed deliveries. A refresh cannot reset
  // today's budget or cooldown. Future cancelled slots do not consume the budget.
  final reserved = <DateTime>[];
  final historyKeys = <String>{};
  for (final event in history.where(
    (e) => e.kind == 'notification_schedule_registered',
  )) {
    final at = DateTime.tryParse('${event.details['scheduledAtUtc']}');
    final key = '${event.taskId}:${event.details['category'] ?? 'manual'}:$at';
    if (at != null && !at.isAfter(now) && historyKeys.add(key)) {
      reserved.add(tz.TZDateTime.from(at, location));
    }
  }
  final allowed = candidates.where((candidate) {
    final day = candidate.scheduled;
    if (reserved
            .where(
              (at) =>
                  at.year == day.year &&
                  at.month == day.month &&
                  at.day == day.day,
            )
            .length >=
        preferences.dailyLimit) {
      return false;
    }
    if (reserved.any(
      (at) =>
          day.difference(at).abs() <
          Duration(minutes: preferences.cooldownMinutes),
    )) {
      return false;
    }
    reserved.add(day);
    return true;
  }).toList();
  final used = <int>{};
  int uniqueId(String taskId) {
    var id = reminderId(scope, taskId);
    while (!used.add(id)) {
      id = (id + 1) & 0x7fffffff;
    }
    return id;
  }

  return [
    for (var i = 0; i < allowed.length; i++)
      PlannedReminder(
        taskId: allowed[i].task.id,
        requestedAt: allowed[i].requested,
        scheduledAt: allowed[i].scheduled,
        notificationId: uniqueId(
          allowed[i].category == 'manual'
              ? allowed[i].task.id
              : '${allowed[i].task.id}:${allowed[i].category}',
        ),
        category: allowed[i].category,
        language: language,
        title: language == 'ja'
            ? 'Small Steps・${allowed[i].category == 'deadline'
                  ? '締め切りのリマインダー'
                  : allowed[i].category == 'planned_start'
                  ? '開始予定'
                  : 'タスクのリマインダー'}'
            : 'Small Steps · ${allowed[i].category == 'deadline'
                  ? 'Deadline reminder'
                  : allowed[i].category == 'planned_start'
                  ? 'Planned start'
                  : 'Task reminder'}',
        body: language == 'ja'
            ? (!preferences.agentVoice || !condition.hasAgent
                  ? 'Small Stepsを開いてタスクを確認し、次にどうするか選べます。'
                  : condition == StudyCondition.selfAgent
                  ? '小さな一歩は、これからの準備につながりそうですか？ 計画は確認・変更できます。'
                  : '小さな一歩で大丈夫。タスクを確認して、別の計画を選んでも大丈夫です。')
            : !preferences.agentVoice || !condition.hasAgent
            ? 'Open Small Steps to review your task and choose what to do.'
            : condition == StudyCondition.selfAgent
            ? 'Would a small step support your future plans? You can review or change your plan.'
            : 'A small step is okay. You can review your task or choose a different plan.',
      ),
  ];
}
