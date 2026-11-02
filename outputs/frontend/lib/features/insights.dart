import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../app/state.dart';
import '../app/theme.dart';
import '../shared/widgets.dart';

class InsightsScreen extends ConsumerWidget {
  const InsightsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final now = DateTime.now();
    final days = List.generate(
      7,
      (i) => DateTime(now.year, now.month, now.day - 6 + i),
    );
    final completed = state.tasks
        .where(
          (t) =>
              t.done &&
              t.completedAt != null &&
              !t.completedAt!.isBefore(days.first),
        )
        .length;
    final starts = state.events
        .where((e) => e.kind == 'focus_started' && !e.at.isBefore(days.first))
        .length;
    final taskStarts = state.events
        .where((e) => e.kind == 'task_started' && !e.at.isBefore(days.first))
        .length;
    final counts = days
        .map(
          (d) => state.events
              .where(
                (e) =>
                    e.kind == 'focus_started' &&
                    DateUtils.isSameDay(e.at.toLocal(), d),
              )
              .length,
        )
        .toList();
    final maximum = counts.fold<int>(1, (a, b) => a > b ? a : b);
    return PageBody(
      children: [
        Heading(
          context.l10n.insights_b45103,
          context.l10n.yourProgress_44a680,
          context.l10n.noticeYourPatternsWithCompassion_1a39b5,
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.connected
                    ? context.l10n.lastDaysDevelopmentAccount_9b1ce3
                    : context.l10n.lastDaysLocalDemo_3f1c63,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 22),
              Wrap(
                spacing: 28,
                runSpacing: 16,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.value_114413((completed).toString()),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        context.l10n.tasksCompleted_e0803f,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.value_114413((starts).toString()),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        context.l10n.focusStarts_c5929a,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.l10n.value_114413((taskStarts).toString()),
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        context.l10n.reportedTaskStarts_56b2db,
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 106,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (var i = 0; i < 7; i++)
                      Expanded(
                        child: Semantics(
                          label: context.l10n.focusStarts_8ede1c(
                            (DateFormat.MMMd().format(days[i])).toString(),
                            (counts[i]).toString(),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text(
                                context.l10n.value_114413(
                                  (counts[i]).toString(),
                                ),
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(height: 5),
                              Container(
                                width: 22,
                                height: counts[i] == 0
                                    ? 3
                                    : 55 * counts[i] / maximum,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                DateFormat('E').format(days[i]),
                                style: const TextStyle(fontSize: 10),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                context.l10n.countsReflectLocalDemoInteractionsReported_7ada41,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          color: AppTokens.blue,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.aMomentToReflect_bec4d1,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 14),
              Text(context.l10n.whatMadeItEasierOrHarder_6dc655),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.howHeavyDidTasksFeel_6c29b8,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(context.l10n.aShortVoluntaryCheckIn_881d40),
              const SizedBox(height: 16),
              Wrap(
                spacing: 10,
                children: ['Light', 'Okay', 'Heavy']
                    .map(
                      (b) => ChoiceChip(
                        label: Text(b),
                        selected: state.burden == b,
                        onSelected: (_) => perform(
                          context,
                          () => ref.read(appProvider.notifier).setBurden(b),
                        ),
                      ),
                    )
                    .toList(),
              ),
              if (state.burden != null)
                Text(
                  state.connected
                      ? context.l10n.savedToDevelopmentAccount_cd928e(
                          (state.burden).toString(),
                        )
                      : context.l10n.savedLocally_fd07a5(
                          (state.burden).toString(),
                        ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        OutlinedButton.icon(
          onPressed: () => context.push('/check-in'),
          icon: const Icon(Icons.spa_outlined),
          label: Text(context.l10n.addAnOptionalCheckIn_1bec0f),
        ),
        const SizedBox(height: 20),
        Text(
          context.l10n.yourCheckInHistory_fc0caa,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(context.l10n.datedDemoResponsesNotValidatedScores_77dd4f),
        const SizedBox(height: 12),
        if (state.checkIns.isEmpty)
          EmptyPanel(
            context.l10n.noCheckInsYet_b49f04,
            context.l10n.checkInsAreVoluntaryYourTask_87f153,
          ),
        for (final c in state.checkIns.reversed.take(6))
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.value_948253(
                      context.tr((c.phase).toString()),
                      (DateFormat.MMMd().add_jm().format(
                        c.at.toLocal(),
                      )).toString(),
                    ),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.answers.entries
                        .map(
                          (a) =>
                              '${context.tr(a.key.replaceAll('_', ' '))}: ${context.tr(a.value)}',
                        )
                        .join('\n'),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 24),
        Text(
          context.l10n.taskSessionHistory_6df948,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        if (state.events.isEmpty)
          EmptyPanel(
            context.l10n.yourHistoryStartsHere_31333c,
            context.l10n.completeATaskOrStartA_8176cf,
          ),
        ...state.events.reversed
            .take(30)
            .map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(switch (e.kind) {
                        'focus_started' => context.l10n.focusStarted_37a5b7,
                        'self_reported_completion' =>
                          context.l10n.taskMarkedComplete_c1e013,
                        'completion_undone' =>
                          context.l10n.taskCompletionUndone_b6f2c6,
                        'agent_switched' =>
                          context.l10n.demoAgentChanged_5f2cb7,
                        'correction_proposed' =>
                          context.l10n.taskCorrectionProposed_2cad2b,
                        'correction_accepted' =>
                          context.l10n.taskCorrectionAccepted_402281,
                        'correction_rejected' =>
                          context.l10n.taskCorrectionRejected_08118f,
                        'suggestion_displayed' =>
                          context.l10n.suggestionShown_f317b4,
                        'suggestion_opened' =>
                          context.l10n.suggestionReviewOpened_40a73a,
                        'suggestion_dismissed' =>
                          context.l10n.suggestionDismissed_c4ed78,
                        'focus_elapsed' =>
                          context.l10n.sessionTimeElapsed_dd08a1,
                        'focus_ended_early' =>
                          context.l10n.sessionEndedEarly_da9211,
                        'focus_paused' => context.l10n.focusPaused_93230c,
                        'focus_resumed' => context.l10n.focusResumed_dcbc1a,
                        'task_created' => context.l10n.taskAdded_6bb7dd,
                        'task_updated' => context.l10n.taskUpdated_f1e9a1,
                        'task_started' => context.l10n.taskStartReported_c445cb,
                        'task_resumed' => context.l10n.taskResumed_cb663d,
                        'task_recovery' => context.l10n.planAdjusted_290c9a,
                        'task_deleted' => context.l10n.taskDeleted_d3c52b,
                        'refinement_proposed' =>
                          context.l10n.suggestionsRequested_1fa652,
                        'refinement_accepted' =>
                          context.l10n.suggestedStepsAccepted_b67ab6,
                        'refinement_rejected' =>
                          context.l10n.suggestionsDeclined_5af8e5,
                        'reminder_requested' =>
                          context.l10n.reminderTimeChosen_8c748f,
                        'invitation_opened' =>
                          context.l10n.smallStepInvitationOpened_231b06,
                        _ => context.l10n.activityRecorded_c5d39b,
                      }, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 5),
                      Text(
                        state.tasks
                                .where((t) => t.id == e.taskId)
                                .firstOrNull
                                ?.title ??
                            'Deleted task',
                      ),
                      Text(
                        context.l10n.value_c16121(
                          (DateFormat.MMMd().add_jm().format(
                            e.at.toLocal(),
                          )).toString(),
                          (e.seconds == null
                                  ? ''
                                  : ' · ${e.seconds! ~/ 60}m ${e.seconds! % 60}s')
                              .toString(),
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      if (e.reflection != null) Text(e.reflection!),
                      if (e.kind == 'task_recovery')
                        Text(
                          context.l10n.value_c16121(
                            (e.details['action'] ?? '').toString(),
                            (e.details['reason'] == null
                                    ? ''
                                    : ' · ${e.details['reason']}')
                                .toString(),
                          ),
                        ),
                      if (e.kind == 'task_started' &&
                          e.details['plannedStart'] != null)
                        Text(
                          _startTiming(
                            e.at,
                            DateTime.parse(e.details['plannedStart']),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
      ],
    );
  }

  String _startTiming(DateTime at, DateTime planned) {
    final minutes = at.difference(planned).inMinutes;
    return 'Self-reported start ${minutes.abs()} minutes ${minutes < 0 ? 'before' : 'after'} the planned time. This does not establish procrastination.';
  }
}
