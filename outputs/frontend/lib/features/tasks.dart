import '../l10n/strings.dart';
import 'start_support.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/state.dart';
import '../data/models.dart';
import '../shared/widgets.dart';
import '../app/reminders_controller.dart';
import 'reminder_settings.dart';
import 'task_actions.dart';
import 'agent_actions.dart';

class TasksScreen extends ConsumerStatefulWidget {
  final bool reminders;
  const TasksScreen({super.key, this.reminders = false});
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String filter = 'Active', query = '';
  @override
  Widget build(BuildContext context) {
    final reminders = widget.reminders;
    final state = ref.watch(appProvider);
    final notifications = ref.watch(remindersProvider);
    final tasks = state.tasks.where((t) {
      if (!t.title.toLowerCase().contains(query.toLowerCase())) return false;
      return switch (filter) {
        'Completed' => t.done,
        'Paused' => !t.done && t.paused,
        'Today' =>
          !t.done &&
              !t.paused &&
              DateUtils.isSameDay(t.schedule, DateTime.now()),
        _ => !t.done && !t.paused,
      };
    }).toList()..sort(Task.compareSchedule);
    return PageBody(
      children: [
        Heading(
          reminders
              ? context.l10n.standardTaskSupport_4fe425
              : context.l10n.taskPlanning_fe486a,
          reminders
              ? context.l10n.todaySReminders_9b690a
              : context.l10n.yourSmallSteps_dcbeb9,
          reminders
              ? context.l10n.yourTaskRemindersAndNotificationStatus_7b490a
              : context.l10n.makeRoomForWhatMattersOne_93e5ec,
        ),
        PrimaryButton(
          context.l10n.addTask_d417d7,
          onPressed: () => context.push('/task/new'),
        ),
        const SizedBox(height: 16),
        TextField(
          decoration: InputDecoration(
            labelText: context.l10n.findATask_fcbde8,
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) => setState(() => query = value),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            for (final option in ['Active', 'Today', 'Paused', 'Completed'])
              ChoiceChip(
                label: Text(context.tr((option).toString())),
                selected: filter == option,
                onSelected: (_) => setState(() => filter = option),
              ),
          ],
        ),
        const SizedBox(height: 20),
        if (reminders) ...[
          Panel(
            child: Text(
              context.l10n.completedRemaining_d56a0c(
                (tasks.where((t) => t.done).length).toString(),
                (tasks.where((t) => !t.done).length).toString(),
              ),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (tasks.isEmpty)
          EmptyPanel(
            context.l10n.noTasksInThisView_5d338c,
            context.l10n.chooseAnotherFilterOrAddA_91fbc4,
          ),
        if (reminders) ...[
          const ReminderStatusPanel(),
          TextButton(
            onPressed: () => context.push('/settings'),
            child: Text(context.l10n.notificationPreferences_0ead6c),
          ),
          const SizedBox(height: 12),
        ],
        ...tasks.expand((t) {
          final plan = notifications.scheduled
              .where((r) => r.taskId == t.id)
              .firstOrNull;
          return <Widget>[
            TaskCard(t, reminder: reminders),
            if (reminders && plan != null && plan.deferred)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  context.l10n.quietHoursScheduledFor_d7c9f9(
                    (DateFormat.MMMd().add_jm().format(
                      plan.scheduledAt,
                    )).toString(),
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ];
        }),
      ],
    );
  }
}

class TaskEditor extends ConsumerStatefulWidget {
  final String? id;
  const TaskEditor({super.key, this.id});
  @override
  ConsumerState<TaskEditor> createState() => _TaskEditorState();
}

class _TaskEditorState extends ConsumerState<TaskEditor> {
  final form = GlobalKey<FormState>();
  final title = TextEditingController(),
      description = TextEditingController(),
      duration = TextEditingController(text: '15');
  DateTime? due, plannedStart;
  DateTime? reminder;
  String priority = 'Normal';
  bool busy = false;
  Task? original;
  @override
  void initState() {
    super.initState();
    original = ref
        .read(appProvider)
        .tasks
        .where((t) => t.id == widget.id)
        .firstOrNull;
    if (original case final t?) {
      title.text = t.title;
      description.text = t.description;
      duration.text = '${t.minutes}';
      due = t.due;
      plannedStart = t.plannedStart;
      priority = t.priority;
      reminder = t.reminder;
    }
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    duration.dispose();
    super.dispose();
  }

  Future<DateTime?> pick(DateTime initial) =>
      chooseDateTime(context, initial: initial);

  Future<void> save() async {
    if (!form.currentState!.validate()) {
      return;
    }
    setState(() => busy = true);
    try {
      final task =
          (original ??
                  Task(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    title: '',
                    due: due,
                  ))
              .copyWith(
                title: title.text.trim(),
                description: description.text.trim(),
                due: due,
                clearDue: due == null,
                plannedStart: plannedStart,
                clearPlannedStart: plannedStart == null,
                priority: priority,
                minutes: int.parse(duration.text),
                reminder: reminder,
                clearReminder: reminder == null,
              );
      await ref.read(appProvider.notifier).saveTask(task);
      if (mounted) {
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.tr((e).toString()))));
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.id != null && original == null) {
      return PageBody(
        children: [
          EmptyPanel(
            context.l10n.taskNotFound_69113b,
            context.l10n.itMayHaveBeenDeleted_8b326e,
          ),
        ],
      );
    }
    return Form(
      key: form,
      child: PageBody(
        children: [
          Heading(
            context.l10n.taskPlanning_fe486a,
            original == null
                ? context.l10n.addTask_24700e
                : context.l10n.editYourTask_52ff42,
            context.l10n.youCanChangeYourPlanAt_7e2939,
          ),
          TextFormField(
            controller: title,
            decoration: InputDecoration(
              labelText: context.l10n.taskTitle_624d94,
            ),
            maxLength: 160,
            validator: (v) => v == null || v.trim().isEmpty
                ? context.tr('Give your task a title.')
                : null,
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            context.l10n.saveTask_e84d4a,
            busy: busy,
            onPressed: save,
          ),
          const SizedBox(height: 16),
          Text(context.l10n.aTitleIsEnoughToBegin_c03561),
          const SizedBox(height: 12),
          Card(
            child: ExpansionTile(
              title: Text(context.l10n.moreDetailsAndScheduling_89bad4),
              initiallyExpanded: original != null,
              children: [
                TextFormField(
                  controller: description,
                  decoration: InputDecoration(
                    labelText: context.l10n.descriptionOptional_388de6,
                  ),
                  maxLines: 3,
                  maxLength: 2000,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: priority,
                  decoration: InputDecoration(
                    labelText: context.l10n.priority_886cbf,
                  ),
                  items: ['Low', 'Normal', 'High']
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text(context.tr((p).toString())),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => priority = v!),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: duration,
                  decoration: InputDecoration(
                    labelText: context.l10n.estimatedDurationMinutes_546aa1,
                  ),
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final n = int.tryParse(v ?? '');
                    return n == null || n < 1 || n > 480
                        ? context.tr('Choose between 1 and 480 minutes.')
                        : null;
                  },
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.play_circle_outline),
                  label: Text(
                    plannedStart == null
                        ? context.l10n.plannedStartOptional_db8dd7
                        : context.l10n.planToStart_abd52d(
                            (DateFormat.MMMd().add_jm().format(
                              plannedStart!,
                            )).toString(),
                          ),
                  ),
                  onPressed: () async {
                    final at = await chooseDateTime(
                      context,
                      initial: plannedStart,
                    );
                    if (at != null && mounted) {
                      setState(() => plannedStart = at);
                    }
                  },
                ),
                if (plannedStart != null)
                  TextButton(
                    onPressed: () => setState(() => plannedStart = null),
                    child: Text(context.l10n.removePlannedStart_f74604),
                  ),
                OutlinedButton.icon(
                  onPressed: () async {
                    final value = await pick(
                      due ?? DateTime.now().add(const Duration(hours: 1)),
                    );
                    if (value != null && context.mounted) {
                      setState(() => due = value);
                    }
                  },
                  icon: const Icon(Icons.event_outlined),
                  label: Text(
                    due == null
                        ? context.l10n.deadlineOptional_34fb64
                        : context.l10n.due_483844(
                            (DateFormat.MMMd().add_jm().format(
                              due!,
                            )).toString(),
                          ),
                  ),
                ),
                if (due != null)
                  TextButton(
                    onPressed: () => setState(() => due = null),
                    child: Text(context.l10n.removeDeadline_75e430),
                  ),
                if (plannedStart != null &&
                    due != null &&
                    plannedStart!.isAfter(due!))
                  Text(context.l10n.yourPlannedStartIsAfterYour_6aac64),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final value = await pick(
                      reminder ??
                          plannedStart ??
                          due ??
                          DateTime.now().add(const Duration(hours: 1)),
                    );
                    if (value != null && context.mounted) {
                      if (!value.isAfter(DateTime.now())) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              context.l10n.chooseAFutureReminderTime_a80a33,
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => reminder = value);
                    }
                  },
                  icon: const Icon(Icons.notifications_none),
                  label: Text(
                    reminder == null
                        ? context.l10n.chooseAReminderTime_785b09
                        : DateFormat.MMMd().add_jm().format(reminder!),
                  ),
                ),
                if (reminder != null)
                  TextButton(
                    onPressed: () => setState(() => reminder = null),
                    child: Text(context.l10n.removeReminder_ccd793),
                  ),
                const SizedBox(height: 8),
                Text(
                  context.l10n.reminderTimesFollowTheLocalClock_83f93e,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                TextButton(
                  onPressed: () => context.push('/settings'),
                  child: Text(context.l10n.notificationPreferences_0ead6c),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class TaskDetail extends ConsumerWidget {
  final String id;
  const TaskDetail({super.key, required this.id});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final task = state.tasks.where((t) => t.id == id).firstOrNull;
    if (task == null) {
      return PageBody(
        children: [
          EmptyPanel(
            context.l10n.taskNotFound_69113b,
            context.l10n.itMayHaveBeenDeleted_8b326e,
          ),
        ],
      );
    }
    return PageBody(
      children: [
        Heading(
          context.l10n.yourTask_3aec10,
          task.title,
          context.l10n.priorityMinutes_4b3956(
            context.tr((task.priority).toString()),
            (task.minutes).toString(),
          ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                task.description.isEmpty
                    ? context.l10n.noDescriptionAdded_0dc3da
                    : task.description,
              ),
              const SizedBox(height: 16),
              Text(
                task.plannedStart == null
                    ? context.l10n.noPlannedStart_0813ca
                    : context.l10n.plannedStart_6b09db(
                        (DateFormat.yMMMd().add_jm().format(
                          task.plannedStart!,
                        )).toString(),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                task.due == null
                    ? context.l10n.noDeadline_c4a597
                    : context.l10n.due_483844(
                        (DateFormat.yMMMd().add_jm().format(
                          task.due!,
                        )).toString(),
                      ),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.status_185ea7(
                  context.tr((task.status).toString()),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (!task.done) StartSupportPanel(task: task),
        const SizedBox(height: 20),
        PrimaryButton(
          task.done
              ? context.l10n.markAsToDo_8ee8bd
              : context.l10n.markComplete_0c0184,
          onPressed: () => toggleTaskWithUndo(context, ref, task),
        ),
        const SizedBox(height: 12),
        if (!task.done && !task.paused && task.firstStartedAt == null) ...[
          OutlinedButton.icon(
            onPressed: () => perform(
              context,
              () => ref.read(appProvider.notifier).startTask(task.id),
            ),
            icon: const Icon(Icons.play_arrow),
            label: Text(context.l10n.iAmStartingThisTask_bb9a50),
          ),
          const SizedBox(height: 12),
        ],
        if (!task.done) ...[
          OutlinedButton.icon(
            onPressed: () => showRecoverySheet(context, ref, task),
            icon: const Icon(Icons.tune),
            label: Text(context.l10n.adjustMyPlan_a2c8a9),
          ),
          const SizedBox(height: 12),
        ],
        OutlinedButton(
          onPressed: task.done || task.paused
              ? null
              : () => showFocusSheet(context, ref, task),
          child: Text(
            state.focus == null
                ? context.l10n.startAFocusSession_c5dc51
                : context.l10n.returnToFocusSession_f18054,
          ),
        ),
        if (!task.done && !task.paused)
          TextButton.icon(
            onPressed: () => showReminderSheet(context, ref, task),
            icon: const Icon(Icons.notifications_none),
            label: Text(context.l10n.remindMeLater_bebc1c),
          ),
        const SizedBox(height: 20),
        if (task.reminder != null ||
            (ref.watch(remindersProvider).preferences.plannedStarts &&
                task.plannedStart != null) ||
            (ref.watch(remindersProvider).preferences.deadlines &&
                task.due != null)) ...[
          ReminderStatusPanel(task: task),
          const SizedBox(height: 20),
        ],
        if (state.condition.hasAgent && !task.done && !task.paused)
          TextButton.icon(
            onPressed: () => showCorrectionSheet(context, task),
            icon: const Icon(Icons.auto_fix_high_outlined),
            label: Text(context.l10n.reviewTaskCorrection_1ccbf7),
          ),
        Card(
          child: ExpansionTile(
            initiallyExpanded: true,
            title: Text(
              context.l10n.smallSteps_937996(
                (task.subtasks.where((s) => s.done).length).toString(),
                (task.subtasks.length).toString(),
              ),
            ),
            children: [
              if (task.subtasks.isEmpty)
                Padding(
                  padding: EdgeInsets.all(20),
                  child: Text(context.l10n.noSmallStepsAddedYet_45e2ff),
                ),
              for (var i = 0; i < task.subtasks.length; i++)
                CheckboxListTile(
                  title: Text(task.subtasks[i].title),
                  value: task.subtasks[i].done,
                  onChanged: (v) => perform(
                    context,
                    () => ref
                        .read(appProvider.notifier)
                        .saveTask(
                          task.copyWith(
                            subtasks: [
                              for (var j = 0; j < task.subtasks.length; j++)
                                j == i
                                    ? Subtask(
                                        task.subtasks[j].title,
                                        done: v ?? false,
                                      )
                                    : task.subtasks[j],
                            ],
                          ),
                        ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        OutlinedButton.icon(
          onPressed: () => showSubtaskEditor(context, ref, task),
          icon: const Icon(Icons.edit_note),
          label: Text(context.l10n.editMySmallSteps_e1eb3a),
        ),
        if (state.condition.hasAgent)
          OutlinedButton.icon(
            onPressed: () => context.push('/refine/$id'),
            icon: const Icon(Icons.auto_awesome_outlined),
            label: Text(context.l10n.breakItDown_5798bd),
          ),
        if (state.condition.hasAgent)
          TextButton.icon(
            onPressed: () =>
                context.go('/chat?task=${Uri.encodeComponent(task.id)}'),
            icon: const Icon(Icons.chat_bubble_outline),
            label: Text(context.l10n.talkAboutThisTask_b85110),
          ),
        TextButton.icon(
          onPressed: () => context.push('/edit/$id'),
          icon: const Icon(Icons.edit_outlined),
          label: Text(context.l10n.editOrReschedule_613c15),
        ),
        TextButton.icon(
          onPressed: () async {
            if (await confirm(
              context,
              context.l10n.deleteTask_b50826,
              context.l10n.thisRemovesTheTaskAndIts_97c470,
            )) {
              if (context.mounted) {
                await perform(context, () async {
                  await ref.read(appProvider.notifier).deleteTask(id);
                  if (context.mounted) {
                    context.go('/tasks');
                  }
                });
              }
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: Text(context.l10n.deleteTask_9ad9dc),
        ),
      ],
    );
  }
}

class RefinementScreen extends ConsumerStatefulWidget {
  final String id;
  const RefinementScreen({super.key, required this.id});
  @override
  ConsumerState<RefinementScreen> createState() => _RefinementScreenState();
}

class _RefinementScreenState extends ConsumerState<RefinementScreen> {
  List<TextEditingController> suggestions = [];
  bool loading = true, saving = false;
  String? error;
  int variant = 0;
  String? proposalId;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  @override
  void dispose() {
    for (final c in suggestions) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
      proposalId = null;
    });
    try {
      final task = ref
          .read(appProvider)
          .tasks
          .firstWhere((t) => t.id == widget.id);
      final result = await ref
          .read(appProvider.notifier)
          .suggestions(task, variant++);
      proposalId = ref
          .read(appProvider)
          .events
          .where((e) => e.taskId == task.id && e.kind == 'refinement_proposed')
          .lastOrNull
          ?.id;
      if (!mounted) {
        return;
      }
      for (final c in suggestions) {
        c.dispose();
      }
      setState(
        () => suggestions = result
            .map((s) => TextEditingController(text: s.title))
            .toList(),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted &&
            proposalId != null &&
            ModalRoute.of(context)?.isCurrent == true) {
          ref
              .read(appProvider.notifier)
              .reportSuggestion('suggestion_displayed', task, proposalId!)
              .catchError((Object _) {});
        }
      });
    } catch (e) {
      if (mounted) {
        setState(() => error = '$e');
      }
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = ref
        .watch(appProvider)
        .tasks
        .where((t) => t.id == widget.id)
        .firstOrNull;
    return PageBody(
      children: [
        Heading(
          context.l10n.taskPlanning_fe486a,
          context.l10n.makeItManageable_1208ae,
          context.l10n.aBigTaskDoesnTNeed_3e219b,
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.yourOriginalGoal_3efaa8,
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 14),
              Text(
                task?.title ?? 'Task unavailable',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          ref.watch(appProvider).connected
              ? context.l10n.suggestedBreakdownBackendAi_ad7b42
              : context.l10n.suggestedBreakdownDemoService_329994,
        ),
        const SizedBox(height: 16),
        if (loading)
          const Center(child: CircularProgressIndicator())
        else if (error != null)
          ErrorPanel(error!, retry: load)
        else ...[
          for (var i = 0; i < suggestions.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: TextField(
                controller: suggestions[i],
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: context.l10n.stepEditable_ca61e8(
                    (i + 1).toString(),
                  ),
                  prefixIcon: const Icon(Icons.circle_outlined, size: 20),
                ),
              ),
            ),
          const SizedBox(height: 20),
          PrimaryButton(
            context.l10n.acceptTheseSteps_f68c84,
            busy: saving,
            onPressed: () async {
              if (suggestions.any((s) => s.text.trim().isEmpty)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      context.l10n.giveEveryStepATitleBefore_cbfc40,
                    ),
                  ),
                );
                return;
              }
              setState(() => saving = true);
              await perform(context, () async {
                await ref
                    .read(appProvider.notifier)
                    .acceptSuggestions(
                      widget.id,
                      suggestions.map((s) => Subtask(s.text.trim())).toList(),
                      proposalId: proposalId,
                    );
                if (context.mounted) {
                  context.canPop()
                      ? context.pop()
                      : context.go('/task/${widget.id}');
                }
              });
              if (mounted) {
                setState(() => saving = false);
              }
            },
          ),
          TextButton(
            onPressed: saving ? null : load,
            child: Text(context.l10n.regenerateSuggestions_986faf),
          ),
        ],
        TextButton(
          onPressed: saving || loading || proposalId == null
              ? null
              : () => perform(context, () async {
                  await ref
                      .read(appProvider.notifier)
                      .rejectSuggestions(widget.id, proposalId);
                  if (context.mounted) {
                    context.canPop()
                        ? context.pop()
                        : context.go('/task/${widget.id}');
                  }
                }),
          child: Text(context.l10n.rejectSuggestionsNotNow_9bb5e5),
        ),
        if (proposalId == null)
          TextButton(
            onPressed: () => context.canPop()
                ? context.pop()
                : context.go('/task/${Uri.encodeComponent(widget.id)}'),
            child: Text(context.l10n.close_bbfa77),
          ),
        const SizedBox(height: 8),
        Text(
          context.l10n.suggestionsRemainADraftUntilYou_4b4705,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
