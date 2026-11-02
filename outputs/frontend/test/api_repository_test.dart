import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';

void main() {
  late Dio client;
  late ApiResearchRepository repository;
  late List<RequestOptions> requests;
  dynamic response;
  int status = 200;

  setUp(() {
    requests = [];
    status = 200;
    response = null;
    client = Dio(BaseOptions(baseUrl: 'https://study.invalid'));
    client.interceptors.add(
      InterceptorsWrapper(
        onRequest: (request, handler) {
          requests.add(request);
          final result = Response<dynamic>(
            requestOptions: request,
            data: response,
            statusCode: status,
          );
          if (status >= 400) {
            handler.reject(
              DioException.badResponse(
                statusCode: status,
                requestOptions: request,
                response: result,
              ),
            );
          } else {
            handler.resolve(result);
          }
        },
      ),
    );
    repository = ApiResearchRepository('https://study.invalid', client: client);
  });
  tearDown(() => client.close(force: true));

  test('complete export validates owner and includes server audit', () async {
    repository.assignment = {'id': 'p1'};
    response = {
      'participant': {'id': 'p1'},
      'tasks': [],
      'records': [
        {'type': 'audit'},
      ],
    };
    expect((await repository.exportData())['records'], isNotEmpty);
    response = {
      'participant': {'id': 'someone-else'},
      'tasks': [],
      'records': [],
    };
    await expectLater(repository.exportData(), throwsA(isA<AppFailure>()));
  });
  test(
    'erasure requires a validated server receipt before device cleanup',
    () async {
      response = {};
      await expectLater(
        repository.eraseDevelopmentData(),
        throwsA(isA<AppFailure>()),
      );
      response = {'dataErased': true, 'credentialRevoked': true};
      await repository.eraseDevelopmentData();
      expect(requests.last.data, {'confirmation': 'ERASE MY DEVELOPMENT DATA'});
    },
  );

  test('assignment accepts only a known condition and nonempty ID', () async {
    for (final condition in StudyCondition.values) {
      response = {'id': 'p1', 'condition': condition.name};
      expect((await repository.participant()).condition, condition);
    }
    for (final invalid in [
      {'id': 'p1', 'condition': 'unknown'},
      {'id': '', 'condition': 'selfAgent'},
      {'id': 'p1'},
      null,
    ]) {
      response = invalid;
      await expectLater(repository.participant(), throwsA(isA<AppFailure>()));
    }
  });

  test('control AI calls fail before sending any network request', () async {
    final task = Task(id: 't1', title: 'Read', due: DateTime.utc(2026));
    await expectLater(
      repository.refine(task, StudyCondition.standardControl),
      throwsA(isA<AppFailure>()),
    );
    await expectLater(
      repository.chat('Help', StudyCondition.standardControl, task),
      throwsA(isA<AppFailure>()),
    );
    expect(requests, isEmpty);
  });

  test('chat omits client assignment and preserves task context', () async {
    response = {
      'id': 'm1',
      'text': 'Hello',
      'user': false,
      'at': '2026-10-26T00:00:00Z',
    };
    final task = Task(id: 't1', title: 'Read', due: DateTime.utc(2026));
    await repository.chat('Help', StudyCondition.friendAgent, task);
    expect(requests.single.data, {
      'message': 'Help',
      'task_id': 't1',
      'language': 'en',
    });
    expect(requests.single.path, '/api/chat');
  });

  test('task update encodes identifiers as one path segment', () async {
    final task = Task(id: 'a/b?c', title: 'Read', due: DateTime.utc(2026));
    response = task.toJson();
    expect((await repository.updateTask(task)).id, task.id);
    expect(requests.single.path, '/api/tasks/a%2Fb%3Fc');
    expect(requests.single.method, 'PATCH');
    expect(requests.single.data, task.toJson());
  });

  test('malformed task responses become user-facing failures', () async {
    for (final invalid in [
      null,
      {},
      [
        {'id': 'missing fields'},
      ],
    ]) {
      response = invalid;
      await expectLater(repository.tasks(), throwsA(isA<AppFailure>()));
    }
  });

  for (final code in [401, 403, 404, 409, 422, 429, 500]) {
    test(
      'HTTP $code is sanitized and writes are not automatically retried',
      () async {
        status = code;
        response = {'detail': 'PRIVATE SERVER DETAIL'};
        await expectLater(
          repository.onboard({}),
          throwsA(
            isA<AppFailure>().having(
              (e) => e.message,
              'safe message',
              isNot(contains('PRIVATE')),
            ),
          ),
        );
        expect(requests, hasLength(1));
      },
    );
  }
}
