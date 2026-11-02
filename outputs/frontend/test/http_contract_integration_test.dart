import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/repository.dart';

/// Run only against backend/tool/http_fixture.py (temporary DB + mock provider).
void main() {
  for (final condition in StudyCondition.values) {
    test('real HTTP contract ${condition.name}', () async {
      final tokens =
          jsonDecode(
                await File(
                  '../backend/.tmp/http-fixture-accounts.json',
                ).readAsString(),
              )
              as Map;
      final api = ApiResearchRepository(
        'http://127.0.0.1:8766',
        token: tokens[condition.name] as String,
      );
      addTearDown(api.close);
      expect((await api.participant()).condition, condition);
      await api.onboard({
        'acknowledged': true,
        'demonstration': true,
        'consent_version': api.assignment['consentVersion'],
      });
      var task = await api.createTask(
        Task(
          id: 'http-task',
          title: 'Read 日本語 ${condition.name}',
          startCue: 'After lunch',
          startAction: 'Open one paper',
          futureNote: condition == StudyCondition.selfAgent
              ? 'Tomorrow I can review my note.'
              : '',
          difficulty: 'unclear',
          plannedStart: DateTime.utc(2030, 1, 2, 3),
        ),
      );
      expect((await api.createTask(task)).version, 1);
      final update = task.copyWith(description: 'Synthetic only', version: 2);
      task = await api.updateTask(update);
      expect((await api.updateTask(update)).version, 2);
      if (condition.hasAgent) {
        final steps = await api.refine(task, condition, language: 'ja');
        task = await api.acceptProposal(api.proposalIds[task.id]!, task, steps);
        expect(task.subtasks, isNotEmpty);
        final reply = await api.chatWithId(
          'Help me start',
          condition,
          task,
          'http-chat',
          language: 'ja',
        );
        final replay = await api.chatWithId(
          'Help me start',
          condition,
          task,
          'http-chat',
          language: 'ja',
        );
        expect(reply.id, replay.id);
        final correction = await api.correct(task, condition);
        task = await api.acceptCorrection(
          api.proposalIds[task.id]!,
          task,
          correction,
        );
      } else {
        await expectLater(
          api.chat('hello', condition, task),
          throwsA(isA<AppFailure>()),
        );
      }
      final event = BehaviorEvent(
        'task_started',
        task.id,
        DateTime.now().toUtc(),
        eventId: 'http-start',
        condition: condition.name,
        taskVersion: task.version,
        offsetMinutes: 540,
      );
      await api.saveEvents([event]);
      await api.saveEvents([event]);
      await api.saveFocus(
        BehaviorEvent(
          'focus_started',
          task.id,
          DateTime.now().toUtc(),
          eventId: 'http-focus',
          condition: condition.name,
          offsetMinutes: 540,
        ),
      );
      await api.saveCheckIn(
        CheckIn(
          id: 'http-check',
          phase: 'Daily',
          condition: condition.name,
          at: DateTime.now().toUtc(),
          offsetMinutes: 540,
          answers: {'burden': 'Low'},
          taskId: task.id,
          language: 'ja',
        ),
      );
      await api.saveProfile(const SupportProfile(goal: 'Synthetic learning'));
      final state = await api.snapshot();
      expect(state['participant']['condition'], condition.name);
      expect(state['tasks'], hasLength(1));
      expect(state['checkIns'], hasLength(1));
      expect(
        (state['events'] as List).where((e) => e['id'] == 'http-start'),
        hasLength(1),
      );
      expect(state['messages'], hasLength(condition.hasAgent ? 2 : 0));
      final export = await api.exportData();
      expect(export['participant']['id'], api.assignment['id']);
      await api.deleteVersioned(task.id, task.version);
      await api.deleteVersioned(task.id, task.version);
      expect(await api.tasks(), isEmpty);
    }, skip: !const bool.fromEnvironment('RUN_HTTP_INTEGRATION'));
  }
}
