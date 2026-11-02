import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:small_steps/features/backend_connection.dart';
import 'package:small_steps/features/settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';

class DevelopmentServer {
  final String condition;
  DevelopmentServer({this.condition = 'selfAgent'});
  bool acknowledged = true, failEvents = false, loseChatReply = false;
  int generations = 0;
  final tasks = <String, Map<String, dynamic>>{};
  final events = <String, dynamic>{};
  final replies = <String, Map<String, dynamic>>{};
  final messages = <Map<String, dynamic>>[];
  final checkIns = <Map<String, dynamic>>[];
  final requests = <RequestOptions>[];
  Map<String, dynamic> profile = const SupportProfile().toJson();
  ApiResearchRepository client() {
    final dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:8000'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          dynamic result;
          int status = 200;
          final path = request.path, body = request.data;
          switch (path) {
            case '/api/participants/me':
              result = {
                'id': 'DEV-1',
                'condition': condition,
                'onboarded': acknowledged,
                'consentVersion': 'demo-consent-v1',
                'mode': 'development',
              };
            case '/api/participants/erase-development-data':
              tasks.clear();
              events.clear();
              messages.clear();
              replies.clear();
              checkIns.clear();
              profile = const SupportProfile().toJson();
              result = {'dataErased': true, 'credentialRevoked': true};
            case '/api/export':
              result = {
                'participant': {'id': 'DEV-1', 'condition': condition},
                'tasks': tasks.values.toList(),
                'records': [
                  {'type': 'audit', 'id': 'server-only'},
                ],
              };
            case '/api/participants/onboarding':
              acknowledged = true;
              result = {};
            case '/api/state':
              result = {
                'participant': {'id': 'DEV-1', 'condition': condition},
                'tasks': tasks.values.toList(),
                'events': events.values.toList(),
                'messages': messages,
                'checkIns': checkIns,
                'profile': profile,
              };
            case '/api/tasks':
              final saved = Map<String, dynamic>.from(body);
              tasks[saved['id']] = saved;
              result = saved;
              status = 201;
            case '/api/events':
              if (failEvents) {
                status = 503;
                result = {};
                break;
              }
              for (final event in body['events']) {
                events[event['id']] = event;
              }
              result = {};
            case '/api/tasks/refine':
              result = {
                'suggestionId': 'proposal1',
                if (body['mode'] == 'correction')
                  'correction': {
                    'title': 'Read one paragraph',
                    'description': 'Save a short note',
                    'minutes': 10,
                    'reason': 'A manageable first step',
                  },
                'subtasks': [
                  {'title': 'Read one paragraph', 'done': false},
                ],
              };
            case '/api/refinements/proposal1/accept':
              final task = tasks.values.single;
              result = {
                ...task,
                'version': (task['version'] as int) + 1,
                if (body['correction'] != null)
                  ...Map<String, dynamic>.from(body['correction'])
                    ..remove('reason')
                else
                  'subtasks': body['subtasks'],
              };
              tasks[task['id']] = Map<String, dynamic>.from(result);
            case '/api/refinements/proposal1/reject':
              result = {};
            case '/api/participants/profile':
              profile = Map<String, dynamic>.from(body);
              result = profile;
            case '/api/check-ins':
              checkIns.add(Map<String, dynamic>.from(body));
              result = {};
            case '/api/chat':
              final id = request.headers['Idempotency-Key'] as String;
              if (!replies.containsKey(id)) {
                generations++;
                replies[id] = {
                  'id': 'reply$id',
                  'text': 'Choose a small step.',
                  'user': false,
                  'at': DateTime.now().toUtc().toIso8601String(),
                  'taskId': body['task_id'],
                };
                messages.add({
                  'id': id,
                  'text': body['message'],
                  'user': true,
                  'at': DateTime.now().toUtc().toIso8601String(),
                  'taskId': body['task_id'],
                });
                messages.add(replies[id]!);
              }
              if (loseChatReply) {
                loseChatReply = false;
                handler.reject(
                  DioException.connectionError(
                    requestOptions: request,
                    reason: 'Synthetic lost response',
                  ),
                );
                return;
              }
              result = replies[id];
            default:
              if (path.startsWith('/api/tasks/')) {
                final id = path.split('/').last;
                if (request.method == 'DELETE') {
                  tasks.remove(id);
                  result = {};
                } else {
                  tasks[id] = Map<String, dynamic>.from(body);
                  result = body;
                }
              } else {
                throw StateError('Unexpected test endpoint $path');
              }
          }
          final response = Response<dynamic>(
            requestOptions: request,
            data: result,
            statusCode: status,
          );
          if (status >= 400) {
            handler.reject(
              DioException.badResponse(
                statusCode: status,
                requestOptions: request,
                response: response,
              ),
            );
          } else {
            handler.resolve(response);
          }
        },
      ),
    );
    return ApiResearchRepository(
      'http://127.0.0.1:8000',
      client: dio,
      token: 'synthetic-participant-token',
    );
  }
}

class LocalRepository extends MockResearchRepository {
  @override
  Future<List<Task>> tasks() async => [
    const Task(id: 'LOCAL', title: 'Local only'),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ProviderContainer container;
  late AppController app;
  late SharedPreferences prefs;
  late DevelopmentServer server;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        preferencesProvider.overrideWithValue(prefs),
        repositoryProvider.overrideWithValue(LocalRepository()),
      ],
    );
    app = container.read(appProvider.notifier);
    await app.initialize();
    server = DevelopmentServer();
  });
  tearDown(() => container.dispose());
  Future<void> connect() => app.connectBackend(
    'http://127.0.0.1:8000',
    'synthetic-participant-token',
    client: server.client(),
  );

  test(
    'connect isolates local records, binds assignment, and never persists token',
    () async {
      final local = prefs.getString(AppController.storageKey);
      await connect();
      expect(container.read(appProvider).connected, isTrue);
      expect(container.read(appProvider).tasks, isEmpty);
      expect(server.requests.any((r) => r.method == 'POST'), isFalse);
      await expectLater(
        app.switchCondition(StudyCondition.friendAgent),
        throwsA(isA<AppFailure>()),
      );
      expect(prefs.getString(AppController.storageKey), local);
      for (final key in prefs.getKeys()) {
        expect(
          prefs.get(key).toString(),
          isNot(contains('synthetic-participant-token')),
        );
      }
      await app.disconnectBackend();
      expect(container.read(appProvider).tasks.single.id, 'LOCAL');
    },
  );
  test(
    'server onboarding remains required until explicitly acknowledged',
    () async {
      server.acknowledged = false;
      await connect();
      expect(container.read(appProvider).consent, isFalse);
      expect(server.requests.any((r) => r.path == '/api/state'), isFalse);
      await app.acceptConsent();
      final request = server.requests.singleWhere(
        (r) => r.path == '/api/participants/onboarding',
      );
      expect(request.data, {
        'acknowledged': true,
        'demonstration': true,
        'consent_version': 'demo-consent-v1',
      });
      expect(container.read(appProvider).consent, isTrue);
    },
  );
  test(
    'network task dates use UTC and deletion uses the observed revision',
    () async {
      await connect();
      final when = DateTime(2027, 1, 2, 10);
      await app.saveTask(Task(id: 'remote', title: 'Read', due: when));
      final request = server.requests.singleWhere(
        (r) => r.path == '/api/tasks',
      );
      expect(DateTime.parse(request.data['due']).isUtc, isTrue);
      expect(container.read(appProvider).tasks.single.due, when);
      await app.deleteTask('remote');
      expect(
        server.requests.lastWhere((r) => r.method == 'DELETE').queryParameters,
        {'version': 1},
      );
      expect(server.tasks, isEmpty);
    },
  );
  test(
    'suggestion acceptance uses the server proposal and rejection never edits tasks',
    () async {
      await connect();
      await app.saveTask(const Task(id: 't1', title: 'Read'));
      final suggestions = await app.suggestions(
        container.read(appProvider).tasks.single,
        0,
      );
      final proposal = container.read(appProvider).events.last;
      expect(container.read(appProvider).tasks.single.subtasks, isEmpty);
      await app.rejectSuggestions('t1', proposal.id);
      expect(server.tasks['t1']!['subtasks'], isEmpty);
      await app.acceptSuggestions('t1', suggestions, proposalId: proposal.id);
      expect(
        server.requests.any(
          (r) => r.path == '/api/refinements/proposal1/accept',
        ),
        isTrue,
      );
      expect(
        container.read(appProvider).tasks.single.subtasks.single.title,
        'Read one paragraph',
      );
      expect(container.read(appProvider).tasks.single.version, 2);
    },
  );
  test('chat retry reuses request identity after a lost response', () async {
    await connect();
    server.loseChatReply = true;
    await expectLater(
      app.send('A small step', null),
      throwsA(isA<AppFailure>()),
    );
    final pending = container.read(appProvider).messages.single;
    expect(pending.delivery, 'failed');
    await app.send(pending.text, null, retry: true, retryMessageId: pending.id);
    final requests = server.requests
        .where((r) => r.path == '/api/chat')
        .toList();
    expect(requests.length, 2);
    expect(
      requests[0].headers['Idempotency-Key'],
      requests[1].headers['Idempotency-Key'],
    );
    expect(server.generations, 1);
    expect(container.read(appProvider).messages.length, 2);
    expect(container.read(appProvider).messages.first.delivery, 'sent');
  });
  test(
    'failed event sync survives on the device and retries without duplicate reports',
    () async {
      await connect();
      server.failEvents = true;
      await app.saveTask(const Task(id: 't1', title: 'Read'));
      expect(container.read(appProvider).error, isNotNull);
      final key = prefs.getKeys().singleWhere(
        (k) => k.startsWith('small_steps.backend'),
      );
      expect(
        (jsonDecode(prefs.getString(key)!)['pendingEvents'] as List).length,
        1,
      );
      server.failEvents = false;
      await app.initialize();
      expect(server.events.length, 1);
      expect(jsonDecode(prefs.getString(key)!)['pendingEvents'], isEmpty);
      expect(container.read(appProvider).error, isNull);
    },
  );
  test('connected check-ins and preferences use server endpoints', () async {
    await connect();
    await app.saveCheckIn('Before session', {'burden': 'Low'});
    expect(server.checkIns.single['phase'], 'before');
    await app.saveProfile(const SupportProfile(goal: 'Learn'));
    expect(server.profile['goal'], 'Learn');
    await app.initialize();
    expect(container.read(appProvider).checkIns.single.phase, 'Before session');
    expect(container.read(appProvider).profile.goal, 'Learn');
  });
  test(
    'connected control assignment cannot access AI even through direct controller calls',
    () async {
      server = DevelopmentServer(condition: 'standardControl');
      await connect();
      expect(
        container.read(appProvider).condition,
        StudyCondition.standardControl,
      );
      await expectLater(app.send('Help', null), throwsA(isA<AppFailure>()));
      await expectLater(
        app.suggestions(const Task(id: 'x', title: 'Read'), 0),
        throwsA(isA<AppFailure>()),
      );
      expect(
        server.requests.any(
          (r) => r.path == '/api/chat' || r.path == '/api/tasks/refine',
        ),
        isFalse,
      );
    },
  );
  testWidgets(
    'connection form hides token and requires data-flow acknowledgment',
    (tester) async {
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: BackendConnectionScreen()),
        ),
      );
      final fields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      expect(fields.length, 2);
      expect(fields.last.obscureText, isTrue);
      expect(find.textContaining('Gemini API key'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Connect'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      final button = tester.widget<FilledButton>(
        find.widgetWithText(FilledButton, 'Connect'),
      );
      expect(button.onPressed, isNull);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('connected settings hide assignment switching and local reset', (
    tester,
  ) async {
    await tester.runAsync(connect);
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: SettingsScreen()),
      ),
    );
    expect(find.textContaining('Development backend'), findsOneWidget);
    expect(find.text('Researcher Demo Mode'), findsNothing);
    expect(find.text('Reset local demo'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
