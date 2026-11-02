import 'dart:async';
import 'package:dio/dio.dart';
import 'models.dart';

class AppFailure implements Exception {
  final String message;
  const AppFailure(this.message);
  @override
  String toString() => message;
}

abstract interface class ResearchRepository {
  Future<TaskCorrection> correct(
    Task task,
    StudyCondition condition, {
    String language = 'en',
  });
  Future<StudyParticipant> participant();
  Future<void> onboard(Map<String, dynamic> answers);
  Future<List<Task>> tasks();
  Future<Task> createTask(Task task);
  Future<Task> updateTask(Task task);
  Future<void> deleteTask(String id);
  Future<List<Subtask>> refine(
    Task task,
    StudyCondition condition, {
    int variant = 0,
    String language = 'en',
  });
  Future<ChatMessage> chat(
    String message,
    StudyCondition condition,
    Task? task, {
    SupportProfile profile = const SupportProfile(),
    String language = 'en',
  });
  Future<void> saveFocus(BehaviorEvent event);
  Future<List<BehaviorEvent>> progress();
}

class MockResearchRepository implements ResearchRepository {
  TaskCorrection _japaneseCorrection(Task task, StudyCondition condition) {
    final title = '具体的な一部分に取り組む：${task.title}';
    return TaskCorrection(
      title: title.length > 300 ? title.substring(0, 300) : title,
      description: task.description.isEmpty
          ? '資料を一つ選び、小さな範囲に取り組んで、学んだことを短くメモする。'
          : task.description,
      minutes: task.minutes > 25 ? 25 : task.minutes,
      reason: condition == StudyCondition.selfAgent
          ? '最初の一歩を具体的にすると、これからの準備につながりそうです。ご自身の目標に合う部分を選んでください。'
          : '最初の一歩を具体的にして、無理のない形にできます。合わないところは自由に編集してくださいね。',
    );
  }

  List<Subtask> _japaneseSteps(Task task, int variant) => [
    Subtask(
      '小さく始める部分を選ぶ：${task.title}'.substring(
        0,
        ('小さく始める部分を選ぶ：${task.title}').length.clamp(0, 300),
      ),
    ),
    const Subtask('必要な資料をそろえる'),
    Subtask(variant.isEven ? '最初の手順を10分だけ試す' : '最初の手順を5分だけ試す'),
    const Subtask('取り組みを見直し、次の一歩を選ぶ'),
  ];
  String _japaneseReply(String message, StudyCondition condition, Task? task) {
    final text = message.trim().toLowerCase().replaceFirst(
      RegExp(r'[.!?。！？]+$'),
      '',
    );
    if ([
      'stop sending reminders',
      'turn off reminders',
      'disable reminders',
      'リマインダーを止めて',
      '通知を止めて',
      '通知をオフにして',
    ].contains(text)) {
      return '設定から通知をオフにできます。この会話では、通知設定は変更されていません。';
    }
    if (['remind me later', '後でリマインドして', '後で知らせて'].contains(text)) {
      return 'タスクの操作から通知時刻を選べます。端末の通知には、設定での有効化と通知の許可が必要です。このメッセージでは予約はしていません。';
    }
    if ([
          'i already finished this task',
          'i finished this task',
          'もう終わりました',
          '完了しました',
        ].contains(text) &&
        !(task?.done ?? false)) {
      return '終わったとのご報告ですね。タスクのチェックボックスから完了にできます。この会話では状態は変更していません。';
    }
    if (task?.done ?? false) {
      return condition == StudyCondition.selfAgent
          ? 'このタスクは完了になっています。うまくいったことを振り返っても、ここで終えても大丈夫です。'
          : 'このタスクは完了になっていますね。ひと休みしても大丈夫です。次にどうするかは自由に選べます。';
    }
    final subject = task == null ? '大切にしていること' : '「${task.title}」';
    return condition == StudyCondition.selfAgent
        ? '$subjectの小さな一歩は、ご自身の目標やこれからの準備に、どのようにつながりそうですか？ 今日に合う一歩を選んでも、立ち止まって考えても大丈夫です。'
        : '$subjectを始めるのが難しく感じることもありますよね。無理のない形で、一緒に小さな一歩を考えてみますか？ 休むことを選んでも大丈夫です。';
  }

  @override
  Future<TaskCorrection> correct(
    Task task,
    StudyCondition condition, {
    String language = 'en',
  }) async {
    if (!condition.hasAgent) {
      throw const AppFailure('Task correction is unavailable.');
    }
    await _delay();
    if (language == 'ja') return _japaneseCorrection(task, condition);
    final title = 'Work on one concrete part of: ${task.title}';
    return TaskCorrection(
      title: title.length > 300 ? title.substring(0, 300) : title,
      description: task.description.isEmpty
          ? 'Choose one resource, work on a small section, and save a short note about what you learned.'
          : task.description,
      minutes: task.minutes > 25 ? 25 : task.minutes,
      reason: condition == StudyCondition.selfAgent
          ? 'A clearer first step can help your future preparation. Keep what fits your own goal.'
          : 'We can make this gentler with one clear first step. You can edit anything that does not fit.',
    );
  }

  bool failNext = false;
  Future<void> _delay() async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
    if (failNext) {
      failNext = false;
      throw const AppFailure(
        'The demo request did not finish. Please try again.',
      );
    }
  }

  @override
  Future<StudyParticipant> participant() async =>
      const StudyParticipant('DEMO-P001', StudyCondition.selfAgent);
  @override
  Future<void> onboard(Map<String, dynamic> answers) => _delay();
  @override
  Future<List<Task>> tasks() async {
    await _delay();
    final now = DateTime.now();
    return [
      Task(
        id: 'literature',
        title: 'Review HAI literature',
        description: 'Read two related papers and note what feels relevant.',
        due: DateTime(now.year, now.month, now.day, 16),
      ),
      Task(
        id: 'methodology',
        title: 'Prepare research methodology',
        due: DateTime(now.year, now.month, now.day, 18),
        minutes: 25,
      ),
      Task(
        id: 'presentation',
        title: 'Draft presentation slides',
        due: DateTime(now.year, now.month, now.day + 1, 10),
        minutes: 30,
      ),
    ];
  }

  @override
  Future<Task> createTask(Task task) async {
    await _delay();
    return task;
  }

  @override
  Future<Task> updateTask(Task task) async {
    await _delay();
    return task;
  }

  @override
  Future<void> deleteTask(String id) => _delay();
  @override
  Future<List<Subtask>> refine(
    Task task,
    StudyCondition condition, {
    int variant = 0,
    String language = 'en',
  }) async {
    if (!condition.hasAgent) {
      throw const AppFailure(
        'Task refinement is unavailable in this condition.',
      );
    }
    await _delay();
    if (language == 'ja') return _japaneseSteps(task, variant);
    if (task.title.toLowerCase().contains('presentation') ||
        task.title.toLowerCase().contains('slides')) {
      return (variant.isEven
              ? [
                  'Review research objectives',
                  'Identify the research gap',
                  'Prepare the methodology diagram',
                  'Draft the opening slides',
                  'Review the presentation',
                ]
              : [
                  'Write one sentence about the research question',
                  'Choose three points to share',
                  'Sketch the slide order',
                  'Create one slide',
                  'Review the draft',
                ])
          .map(Subtask.new)
          .toList();
    }
    return (variant.isEven
            ? [
                'Choose one small part of: ${task.title}',
                'Gather the materials you need',
                'Work on a first draft for ten minutes',
                'Review and choose the next step',
              ]
            : [
                'Describe what done would look like',
                'Pick a starting point for: ${task.title}',
                'Try the first step for five minutes',
                'Save your work and review',
              ])
        .map(Subtask.new)
        .toList();
  }

  @override
  Future<ChatMessage> chat(
    String message,
    StudyCondition condition,
    Task? task, {
    SupportProfile profile = const SupportProfile(),
    String language = 'en',
  }) async {
    if (!condition.hasAgent) {
      throw const AppFailure('Chat is unavailable in this condition.');
    }
    await _delay();
    final greeting = message.trim().toLowerCase().replaceFirst(
      RegExp(r'[.!?。！？]+$'),
      '',
    );
    if (['hi', 'hello', 'hey', 'こんにちは', 'こんばんは', 'おはよう'].contains(greeting)) {
      return ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        user: false,
        at: DateTime.now(),
        taskId: task?.id,
        language: language,
        text: language == 'ja'
            ? 'こんにちは！これは定型文によるデモです。実際のAIと会話するには、バックエンドに接続してください。'
            : 'Hi! This is a scripted demo. Connect the backend for a real AI conversation.',
      );
    }
    if (language == 'ja') {
      return ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: _japaneseReply(message, condition, task),
        user: false,
        at: DateTime.now(),
        taskId: task?.id,
        language: language,
      );
    }
    final normalized = message.trim().toLowerCase().replaceFirst(
      RegExp(r'[.!?。！？]+$'),
      '',
    );
    String? notice;
    if ([
      'stop sending reminders',
      'turn off reminders',
      'disable reminders',
      'リマインダーを止めて',
    ].contains(normalized)) {
      notice =
          'You can turn notifications off in Settings. This conversation has not changed your notification preferences.';
    }
    if (['remind me later', '後でリマインドして'].contains(normalized)) {
      notice =
          'You can choose a reminder time using the task controls. This message has not scheduled a reminder.';
    }
    if ([
          'i already finished this task',
          'i finished this task',
          'もう終わりました',
        ].contains(normalized) &&
        !(task?.done ?? false)) {
      notice =
          'You reported finishing this task. You can use its checkbox to mark it complete; this conversation has not changed it.';
    }
    if (notice != null) {
      return ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: notice,
        user: false,
        at: DateTime.now(),
        taskId: task?.id,
      );
    }
    if (task?.done ?? false) {
      return ChatMessage(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        text: condition == StudyCondition.selfAgent
            ? 'You marked this task complete. You can reflect on what worked or leave it here.'
            : 'You marked this task complete. A break is okay; you choose what comes next.',
        user: false,
        at: DateTime.now(),
        taskId: task!.id,
      );
    }
    final goal = task == null ? 'this task' : '“${task.title}”';
    final personal = profile.goal.isEmpty
        ? ''
        : ' Your chosen longer-term goal is “${profile.goal}”.';
    final values = profile.values.isEmpty
        ? ''
        : ' You said “${profile.values}” matters to you.';
    final brief = profile.brief;
    return ChatMessage(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      user: false,
      at: DateTime.now(),
      taskId: task?.id,
      text: condition == StudyCondition.selfAgent
          ? '$values$personal\n\nWhat would your future self appreciate about a small start on $goal?${brief ? '' : ' You can choose one step that fits your own priorities, or take more time to reflect.'}'
                .trim()
          : '$values$personal\n\nIt can be frustrating when $goal feels hard to start. It is okay to go at your own pace.${brief ? '' : ' Would you like to choose one small step together, or talk about what feels difficult?'}'
                .trim(),
    );
  }

  @override
  Future<void> saveFocus(BehaviorEvent event) => _delay();
  @override
  Future<List<BehaviorEvent>> progress() async => [];
}

/// Authenticated development adapter. Model-provider credentials stay on FastAPI.
class ApiResearchRepository implements ResearchRepository {
  @override
  Future<TaskCorrection> correct(
    Task task,
    StudyCondition condition, {
    String language = 'en',
  }) => _request(() async {
    if (!condition.hasAgent) {
      throw const AppFailure('Task correction is unavailable.');
    }
    final data = Map<String, dynamic>.from(
      (await dio.post(
        '/api/tasks/refine',
        data: {
          'task': _taskJson(task),
          'mode': 'correction',
          'language': language,
        },
        options: Options(headers: {'Idempotency-Key': requestId()}),
      )).data,
    );
    final correction = TaskCorrection.fromJson(
      Map<String, dynamic>.from(data['correction']),
    );
    proposalIds[task.id] = data['suggestionId'] as String;
    return correction;
  });
  Future<Task> acceptCorrection(
    String id,
    Task task,
    TaskCorrection correction,
  ) => _request(
    () async => readTask(
      Map<String, dynamic>.from(
        (await dio.post(
          '/api/refinements/${Uri.encodeComponent(id)}/accept',
          data: {
            'task_version': task.version,
            'correction': correction.toJson(),
          },
        )).data,
      ),
    ),
  );
  final Dio dio;
  int activeRequests = 0;
  Map<String, dynamic> assignment = {};
  final Map<String, String> proposalIds = {};
  ApiResearchRepository(String baseUrl, {Dio? client, String? token})
    : dio =
          client ??
          Dio(
            BaseOptions(
              baseUrl: baseUrl,
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 40),
            ),
          ) {
    if (token != null) {
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (request, handler) {
            request.headers['Authorization'] = 'Bearer $token';
            handler.next(request);
          },
        ),
      );
    }
  }
  static int _serial = 0;
  static String requestId() =>
      '${DateTime.now().microsecondsSinceEpoch}_${_serial++}';
  Future<T> _request<T>(Future<T> Function() work) async {
    activeRequests++;
    try {
      return await work();
    } on DioException catch (error) {
      final data = error.response?.data;
      final code = data is Map && data['error'] is Map
          ? data['error']['code']
          : null;
      final message = code == 'ai_request_unresolved'
          ? 'This AI attempt failed or is still pending. Cancel the message before explicitly sending a new attempt.'
          : switch (error.response?.statusCode) {
              401 =>
                'Your development token is invalid or expired. Disconnect and sign in again.',
              403 => 'This action is not available for your study assignment.',
              404 => 'The requested study record is no longer available.',
              409 => 'This record has changed. Refresh before trying again.',
              422 => 'The study service could not accept these details.',
              429 =>
                'The study service is busy. Please wait before trying again.',
              503 =>
                'The AI or study service is unavailable. Your task was not changed by the AI request.',
              _ => 'Could not reach the study service. Please try again.',
            };
      throw AppFailure(message);
    } on FormatException catch (_) {
      throw const AppFailure(
        'The study service returned an unexpected response.',
      );
    } on TypeError catch (_) {
      throw const AppFailure(
        'The study service response does not match the API contract.',
      );
    } finally {
      activeRequests--;
    }
  }

  Map<String, dynamic> _taskJson(Task task) {
    final data = task.toJson();
    for (final field in [
      'due',
      'plannedStart',
      'firstStartedAt',
      'completedAt',
      'reminder',
    ]) {
      if (data[field] != null) {
        data[field] = DateTime.parse(data[field]).toUtc().toIso8601String();
      }
    }
    return data;
  }

  Task readTask(Map<String, dynamic> json) {
    final local = Map<String, dynamic>.from(json);
    for (final field in [
      'due',
      'plannedStart',
      'firstStartedAt',
      'completedAt',
      'reminder',
    ]) {
      if (local[field] != null) {
        local[field] = DateTime.parse(local[field]).toLocal().toIso8601String();
      }
    }
    return Task.fromJson(local);
  }

  @override
  Future<StudyParticipant> participant() => _request(() async {
    assignment = Map<String, dynamic>.from(
      (await dio.get('/api/participants/me')).data,
    );
    return StudyParticipant.fromJson(assignment);
  });
  @override
  Future<void> onboard(Map<String, dynamic> answers) => _request(() async {
    await dio.post('/api/participants/onboarding', data: answers);
  });
  Future<Map<String, dynamic>> snapshot() => _request(
    () async => Map<String, dynamic>.from((await dio.get('/api/state')).data),
  );
  Future<Map<String, dynamic>> exportData() => _request(() async {
    final value = Map<String, dynamic>.from(
      (await dio.get('/api/export')).data,
    );
    if (value['participant'] is! Map ||
        value['participant']['id'] != assignment['id'] ||
        value['tasks'] is! List ||
        value['records'] is! List) {
      throw const AppFailure(
        'The export does not match this account. Nothing was copied.',
      );
    }
    return value;
  });
  Future<void> eraseDevelopmentData() => _request(() async {
    final response = await dio.post(
      '/api/participants/erase-development-data',
      data: {'confirmation': 'ERASE MY DEVELOPMENT DATA'},
    );
    if (response.data is! Map ||
        response.data['dataErased'] != true ||
        response.data['credentialRevoked'] != true) {
      throw const AppFailure(
        'The server did not confirm erasure. Your device data was retained.',
      );
    }
  });
  @override
  Future<List<Task>> tasks() => _request(
    () async => ((await dio.get('/api/tasks')).data as List)
        .map((j) => readTask(Map<String, dynamic>.from(j)))
        .toList(),
  );
  @override
  Future<Task> createTask(Task task) => _request(
    () async => readTask(
      Map<String, dynamic>.from(
        (await dio.post('/api/tasks', data: _taskJson(task))).data,
      ),
    ),
  );
  @override
  Future<Task> updateTask(Task task) => _request(
    () async => readTask(
      Map<String, dynamic>.from(
        (await dio.patch(
          '/api/tasks/${Uri.encodeComponent(task.id)}',
          data: _taskJson(task),
        )).data,
      ),
    ),
  );
  @override
  Future<void> deleteTask(String id) => _request(() async {
    final current = Map<String, dynamic>.from(
      (await dio.get('/api/tasks/${Uri.encodeComponent(id)}')).data,
    );
    await deleteVersioned(id, current['version'] as int);
  });
  Future<void> deleteVersioned(String id, int version) => _request(() async {
    await dio.delete(
      '/api/tasks/${Uri.encodeComponent(id)}',
      queryParameters: {'version': version},
    );
  });
  @override
  Future<List<Subtask>> refine(
    Task task,
    StudyCondition condition, {
    int variant = 0,
    String language = 'en',
  }) => _request(() async {
    if (!condition.hasAgent) {
      throw const AppFailure('Task refinement is unavailable.');
    }
    final data = Map<String, dynamic>.from(
      (await dio.post(
        '/api/tasks/refine',
        data: {
          'task': _taskJson(task),
          'variant': variant,
          'language': language,
        },
        options: Options(headers: {'Idempotency-Key': requestId()}),
      )).data,
    );
    proposalIds[task.id] = data['suggestionId'] as String;
    return (data['subtasks'] as List)
        .map((j) => Subtask.fromJson(Map<String, dynamic>.from(j)))
        .toList();
  });
  Future<Task> acceptProposal(
    String proposalId,
    Task task,
    List<Subtask> subtasks,
  ) => _request(
    () async => readTask(
      Map<String, dynamic>.from(
        (await dio.post(
          '/api/refinements/${Uri.encodeComponent(proposalId)}/accept',
          data: {
            'task_version': task.version,
            'subtasks': subtasks.map((s) => s.toJson()).toList(),
          },
        )).data,
      ),
    ),
  );
  Future<void> rejectProposal(String proposalId) => _request(() async {
    await dio.post(
      '/api/refinements/${Uri.encodeComponent(proposalId)}/reject',
    );
  });
  @override
  Future<ChatMessage> chat(
    String message,
    StudyCondition condition,
    Task? task, {
    SupportProfile profile = const SupportProfile(),
    String language = 'en',
  }) => chatWithId(message, condition, task, requestId(), language: language);
  Future<ChatMessage> chatWithId(
    String message,
    StudyCondition condition,
    Task? task,
    String id, {
    String language = 'en',
  }) => _request(() async {
    if (!condition.hasAgent) throw const AppFailure('Chat is unavailable.');
    return ChatMessage.fromJson(
      Map<String, dynamic>.from(
        (await dio.post(
          '/api/chat',
          data: {'message': message, 'task_id': task?.id, 'language': language},
          options: Options(headers: {'Idempotency-Key': id}),
        )).data,
      ),
    );
  });
  Future<void> saveEvents(List<BehaviorEvent> events) => _request(() async {
    await dio.post(
      '/api/events',
      data: {'events': events.map((e) => e.toJson()).toList()},
    );
  });
  Future<void> saveCheckIn(CheckIn checkIn) => _request(() async {
    final data = checkIn.toJson();
    data['phase'] = checkIn.phase.toLowerCase().split(' ').first;
    await dio.post('/api/check-ins', data: data);
  });
  Future<void> saveProfile(SupportProfile profile) => _request(() async {
    await dio.patch('/api/participants/profile', data: profile.toJson());
  });
  @override
  Future<void> saveFocus(BehaviorEvent event) => _request(() async {
    await dio.post('/api/focus-sessions', data: event.toJson());
  });
  @override
  Future<List<BehaviorEvent>> progress() => _request(
    () async => ((await dio.get('/api/progress')).data as List)
        .map((j) => BehaviorEvent.fromJson(Map<String, dynamic>.from(j)))
        .toList(),
  );
  void close() => dio.close(force: true);
}
