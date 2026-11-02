enum StudyCondition { selfAgent, friendAgent, standardControl }

extension ConditionLabel on StudyCondition {
  String get label => switch (this) {
    StudyCondition.selfAgent => 'Self-Agent',
    StudyCondition.friendAgent => 'Friend-Agent',
    StudyCondition.standardControl => 'Standard reminders',
  };
  bool get hasAgent => this != StudyCondition.standardControl;
}

class TaskCorrection {
  final String title, description, reason;
  final int minutes;
  const TaskCorrection({
    required this.title,
    required this.description,
    required this.minutes,
    required this.reason,
  });
  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'minutes': minutes,
    'reason': reason,
  };
  factory TaskCorrection.fromJson(Map<String, dynamic> json) {
    final value = TaskCorrection(
      title: json['title'] as String,
      description: json['description'] as String,
      minutes: json['minutes'] as int,
      reason: json['reason'] as String,
    );
    if (value.title.trim().isEmpty ||
        value.title.length > 300 ||
        value.description.length > 5000 ||
        value.minutes < 1 ||
        value.minutes > 1440 ||
        value.reason.trim().isEmpty ||
        value.reason.length > 1000) {
      throw const FormatException('Invalid task correction');
    }
    return value;
  }
}

class CorrectionDraft {
  final Task original;
  final TaskCorrection correction;
  final StudyCondition condition;
  final String id;
  final String? serverId;
  const CorrectionDraft(
    this.original,
    this.correction,
    this.condition,
    this.id,
    this.serverId,
  );
}

class Subtask {
  final String title;
  final bool done;
  const Subtask(this.title, {this.done = false});
  Map<String, dynamic> toJson() => {'title': title, 'done': done};
  factory Subtask.fromJson(Map<String, dynamic> j) =>
      Subtask(j['title'] as String, done: j['done'] as bool? ?? false);
}

class Task {
  final String startCue, startAction, futureNote, difficulty;
  final String id, title, description, priority;
  final DateTime? due, plannedStart, firstStartedAt;
  final bool paused;
  final int version;
  final int minutes;
  final bool done;
  final DateTime? completedAt, reminder;
  final List<Subtask> subtasks;
  const Task({
    required this.id,
    required this.title,
    this.startCue = '',
    this.startAction = '',
    this.futureNote = '',
    this.difficulty = '',
    this.due,
    this.plannedStart,
    this.firstStartedAt,
    this.paused = false,
    this.version = 1,
    this.description = '',
    this.priority = 'Normal',
    this.minutes = 15,
    this.done = false,
    this.completedAt,
    this.reminder,
    this.subtasks = const [],
  });
  Task copyWith({
    String? startCue,
    String? startAction,
    String? futureNote,
    String? difficulty,
    String? title,
    String? description,
    String? priority,
    DateTime? due,
    bool clearDue = false,
    DateTime? plannedStart,
    bool clearPlannedStart = false,
    DateTime? firstStartedAt,
    bool? paused,
    int? version,
    int? minutes,
    bool? done,
    DateTime? completedAt,
    DateTime? reminder,
    bool clearReminder = false,
    List<Subtask>? subtasks,
  }) => Task(
    id: id,
    startCue: startCue ?? this.startCue,
    startAction: startAction ?? this.startAction,
    futureNote: futureNote ?? this.futureNote,
    difficulty: difficulty ?? this.difficulty,
    title: title ?? this.title,
    description: description ?? this.description,
    priority: priority ?? this.priority,
    due: clearDue ? null : due ?? this.due,
    plannedStart: clearPlannedStart ? null : plannedStart ?? this.plannedStart,
    firstStartedAt: firstStartedAt ?? this.firstStartedAt,
    paused: paused ?? this.paused,
    version: version ?? this.version,
    minutes: minutes ?? this.minutes,
    done: done ?? this.done,
    completedAt: done == false ? null : completedAt ?? this.completedAt,
    reminder: clearReminder ? null : reminder ?? this.reminder,
    subtasks: subtasks ?? this.subtasks,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'priority': priority,
    'due': due?.toIso8601String(),
    'startCue': startCue,
    'startAction': startAction,
    'futureNote': futureNote,
    'difficulty': difficulty,
    'plannedStart': plannedStart?.toIso8601String(),
    'firstStartedAt': firstStartedAt?.toIso8601String(),
    'paused': paused,
    'version': version,
    'minutes': minutes,
    'done': done,
    'completedAt': completedAt?.toIso8601String(),
    'reminder': reminder?.toIso8601String(),
    'subtasks': subtasks.map((s) => s.toJson()).toList(),
  };
  factory Task.fromJson(Map<String, dynamic> j) => Task(
    startCue: j['startCue'] as String? ?? '',
    startAction: j['startAction'] as String? ?? '',
    futureNote: j['futureNote'] as String? ?? '',
    difficulty: j['difficulty'] as String? ?? '',
    id: j['id'] as String,
    title: j['title'] as String,
    due: DateTime.tryParse(j['due'] as String? ?? ''),
    plannedStart: DateTime.tryParse(j['plannedStart'] as String? ?? ''),
    firstStartedAt: DateTime.tryParse(j['firstStartedAt'] as String? ?? ''),
    paused: j['paused'] as bool? ?? false,
    version: j['version'] as int? ?? 1,
    description: j['description'] as String? ?? '',
    priority: j['priority'] as String? ?? 'Normal',
    minutes: j['minutes'] as int? ?? 15,
    done: j['done'] as bool? ?? false,
    completedAt: DateTime.tryParse(j['completedAt'] as String? ?? ''),
    reminder: DateTime.tryParse(j['reminder'] as String? ?? ''),
    subtasks: (j['subtasks'] as List? ?? [])
        .map((e) => Subtask.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
  );

  DateTime? get schedule => plannedStart ?? due;
  String get status => done
      ? 'Completed'
      : paused
      ? 'Paused'
      : firstStartedAt != null
      ? 'In progress'
      : 'To do';
  static int compareSchedule(Task a, Task b) {
    final x = a.schedule, y = b.schedule;
    if (x == null && y == null) return a.title.compareTo(b.title);
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }
}

class ChatMessage {
  final String id, text;
  final bool user;
  final DateTime at;
  final String? taskId;
  final String delivery;
  final String language;
  const ChatMessage({
    required this.id,
    required this.text,
    required this.user,
    required this.at,
    this.taskId,
    this.delivery = 'sent',
    this.language = 'en',
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'user': user,
    'at': at.toIso8601String(),
    'taskId': taskId,
    'delivery': delivery,
    'language': language,
  };
  factory ChatMessage.fromJson(Map<String, dynamic> j) => ChatMessage(
    id: j['id'],
    text: j['text'],
    user: j['user'],
    at: DateTime.parse(j['at']),
    taskId: j['taskId'],
    delivery: j['delivery'] ?? 'sent',
    language: j['language'] == 'ja' ? 'ja' : 'en',
  );
  ChatMessage withDelivery(String value) => ChatMessage(
    language: language,
    id: id,
    text: text,
    user: user,
    at: at,
    taskId: taskId,
    delivery: value,
  );
  ChatMessage forTask(String? value) => ChatMessage(
    language: language,
    id: id,
    text: text,
    user: user,
    at: at,
    taskId: value,
    delivery: delivery,
  );
}

class FocusSession {
  final String taskId;
  final String id, condition;
  final int remainingSeconds;
  final int durationSeconds;
  final DateTime? deadline;
  final bool started;
  const FocusSession({
    required this.taskId,
    this.id = 'legacy_unassigned',
    this.condition = 'unknown',
    this.remainingSeconds = 600,
    this.durationSeconds = 600,
    this.deadline,
    this.started = false,
  });
  int remainingAt(DateTime now) => deadline == null
      ? remainingSeconds
      : ((deadline!.difference(now).inMilliseconds / 1000).ceil()).clamp(
          0,
          durationSeconds,
        );
  FocusSession resume(DateTime now) => FocusSession(
    taskId: taskId,
    id: id,
    condition: condition,
    remainingSeconds: remainingSeconds,
    durationSeconds: durationSeconds,
    deadline: now.add(Duration(seconds: remainingSeconds)),
    started: true,
  );
  FocusSession pause(DateTime now) => FocusSession(
    taskId: taskId,
    id: id,
    condition: condition,
    remainingSeconds: remainingAt(now),
    durationSeconds: durationSeconds,
    started: started,
  );
  Map<String, dynamic> toJson() => {
    'taskId': taskId,
    'id': id,
    'condition': condition,
    'remainingSeconds': remainingSeconds,
    'durationSeconds': durationSeconds,
    'deadline': deadline?.toIso8601String(),
    'started': started,
  };
  factory FocusSession.fromJson(Map<String, dynamic> j) => FocusSession(
    taskId: j['taskId'],
    id: j['id'] ?? 'legacy_unassigned',
    condition: j['condition'] ?? 'unknown',
    remainingSeconds: j['remainingSeconds'],
    durationSeconds: j['durationSeconds'] ?? 600,
    deadline: DateTime.tryParse(j['deadline'] ?? ''),
    started: j['started'],
  );
}

class StudyParticipant {
  final String id;
  final StudyCondition condition;
  const StudyParticipant(this.id, this.condition);
  factory StudyParticipant.fromJson(Map<String, dynamic> j) {
    final id = j['id'];
    final condition = StudyCondition.values
        .where((value) => value.name == j['condition'])
        .firstOrNull;
    if (id is! String || id.trim().isEmpty || condition == null) {
      throw const FormatException('Invalid participant assignment');
    }
    return StudyParticipant(id, condition);
  }
}

class BehaviorEvent {
  final String kind, taskId;
  final DateTime at;
  final int? seconds;
  final String? reflection;
  final String? eventId, condition;
  final int? offsetMinutes, taskVersion;
  final Map<String, dynamic> details;
  const BehaviorEvent(
    this.kind,
    this.taskId,
    this.at, {
    this.seconds,
    this.reflection,
    this.eventId,
    this.condition,
    this.offsetMinutes,
    this.taskVersion,
    this.details = const {},
  });
  String get id =>
      eventId ??
      'legacy_${kind}_${taskId}_${at.toUtc().microsecondsSinceEpoch}';
  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind,
    'taskId': taskId,
    'at': at.toUtc().toIso8601String(),
    'offsetMinutes': offsetMinutes,
    'condition': condition,
    'taskVersion': taskVersion,
    'protocolVersion': 'demo-v2',
    'details': details,
    'seconds': seconds,
    'reflection': reflection,
  };
  factory BehaviorEvent.fromJson(Map<String, dynamic> j) => BehaviorEvent(
    j['kind'],
    j['taskId'],
    DateTime.parse(j['at']),
    seconds: j['seconds'],
    reflection: j['reflection'],
    eventId: j['id'],
    condition: j['condition'],
    offsetMinutes: j['offsetMinutes'],
    taskVersion: j['taskVersion'],
    details: Map<String, dynamic>.from(j['details'] ?? {}),
  );
}

class SupportProfile {
  final String values, goal;
  final bool brief, invitations;
  const SupportProfile({
    this.values = '',
    this.goal = '',
    this.brief = false,
    this.invitations = false,
  });
  Map<String, dynamic> toJson() => {
    'values': values,
    'goal': goal,
    'brief': brief,
    'invitations': invitations,
  };
  factory SupportProfile.fromJson(Map<String, dynamic> j) => SupportProfile(
    values: j['values'] ?? '',
    goal: j['goal'] ?? '',
    brief: j['brief'] ?? false,
    invitations: j['invitations'] ?? false,
  );
}

/// Demonstration items only. No validated instrument or score is implied.
class CheckIn {
  final String language;
  final String id, phase, condition;
  final DateTime at;
  final int offsetMinutes;
  final String? taskId;
  final Map<String, String> answers;
  const CheckIn({
    required this.id,
    required this.phase,
    required this.condition,
    required this.at,
    required this.offsetMinutes,
    required this.answers,
    this.taskId,
    this.language = 'en',
  });
  Map<String, dynamic> toJson() => {
    'id': id,
    'phase': phase,
    'condition': condition,
    'at': at.toUtc().toIso8601String(),
    'offsetMinutes': offsetMinutes,
    'taskId': taskId,
    'instrumentVersion': 'demo-check-in-v1',
    'language': language,
    'answers': answers,
  };
  factory CheckIn.fromJson(Map<String, dynamic> j) => CheckIn(
    language: j['language'] == 'ja' ? 'ja' : 'en',
    id: j['id'],
    phase: j['phase'],
    condition: j['condition'],
    at: DateTime.parse(j['at']),
    offsetMinutes: j['offsetMinutes'],
    taskId: j['taskId'],
    answers: Map<String, String>.from(j['answers']),
  );
}
