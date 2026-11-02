import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../shared/widgets.dart';
import 'task_actions.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final now = DateTime.now();
    final today = state.tasks
        .where(
          (t) =>
              !t.paused &&
              (DateUtils.isSameDay(t.plannedStart, now) ||
                  DateUtils.isSameDay(t.due, now)),
        )
        .toList();
    final done = today.where((t) => t.done).length;
    final pending = state.tasks.where((t) => !t.done && !t.paused).toList()
      ..sort(Task.compareSchedule);
    final invitation = pending
        .where(
          (t) => t.subtasks.isEmpty || (t.plannedStart?.isBefore(now) ?? false),
        )
        .firstOrNull;
    final greeting = now.hour < 12
        ? 'morning'
        : now.hour < 18
        ? 'afternoon'
        : 'evening';
    final selected =
        pending.where((t) => t.id == state.todayTaskId).firstOrNull ??
        pending.firstOrNull;
    final focusTask = state.tasks
        .where((t) => t.id == state.focus?.taskId)
        .firstOrNull;
    final nextStep = selected?.subtasks.where((s) => !s.done).firstOrNull;
    final others = pending
        .where((t) => t.id != (state.focus?.taskId ?? selected?.id))
        .toList();
    return PageBody(
      children: [
        Heading(
          (context.isJapanese
                  ? DateFormat('M月d日 EEEE', 'ja')
                  : DateFormat('EEEE, d MMMM', 'en'))
              .format(now),
          context.l10n.good_b4f086(context.tr((greeting).toString())),
          context.l10n.oneTaskAtYourOwnPace_d49f69,
        ),
        if (state.focus != null)
          Panel(
            color: AppTokens.mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.yourFocusSession_584cf8,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  focusTask?.title ?? 'Focus session',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  context.l10n.returnToFocusSession_f18054,
                  onPressed: () => context.push('/focus'),
                ),
              ],
            ),
          )
        else if (selected != null)
          Panel(
            color: AppTokens.mint,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.upNext_567bfc,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  selected.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  nextStep == null
                      ? context.l10n.chooseAStartingPointThatFeels_4992dc
                      : context.l10n.nextSmallStep_c296c8(
                          (nextStep.title).toString(),
                        ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 20),
                Semantics(
                  label: context.l10n.chooseAFocusDurationFor_65e4a6(
                    (selected.title).toString(),
                  ),
                  child: PrimaryButton(
                    context.l10n.focusOnThisTask_1ad73f,
                    onPressed: () => showFocusSheet(context, ref, selected),
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => context.push(
                        '/task/${Uri.encodeComponent(selected.id)}',
                      ),
                      child: Text(context.l10n.viewTask_39e023),
                    ),
                    if (pending.length > 1)
                      TextButton(
                        onPressed: () =>
                            _chooseTask(context, ref, pending, selected.id),
                        child: Text(context.l10n.changeTask_c89335),
                      ),
                  ],
                ),
              ],
            ),
          )
        else ...[
          EmptyPanel(
            context.l10n.noActiveTasks_405725,
            context.l10n.addATaskWheneverYouAre_259006,
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            context.l10n.addTask_24700e,
            onPressed: () => context.push('/task/new'),
          ),
        ],
        if (pending.isNotEmpty || state.focus != null) ...[
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => context.push('/task/new'),
            icon: const Icon(Icons.add),
            label: Text(context.l10n.addTask_24700e),
          ),
        ],
        const SizedBox(height: 24),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.today_24345a,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                today.isEmpty
                    ? context.l10n.noTasksPlannedForToday_3117fd
                    : context.l10n.ofTasksMarkedComplete_37d578(
                        (done).toString(),
                        (today.length).toString(),
                      ),
              ),
              if (today.isNotEmpty) ...[
                const SizedBox(height: 12),
                Semantics(
                  label: context.l10n.ofTasksCompleted_d52ed6(
                    (done).toString(),
                    (today.length).toString(),
                  ),
                  child: LinearProgressIndicator(
                    value: done / today.length,
                    minHeight: 6,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ],
          ),
        ),
        if (others.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            context.l10n.otherTasks_c7690d,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          ...others.take(2).map(TaskCard.new),
        ],
        TextButton(
          onPressed: () => context.go('/tasks'),
          child: Text(context.l10n.viewAllTasks_806e80),
        ),
        if (state.condition.hasAgent &&
            state.profile.invitations &&
            invitation != null) ...[
          const SizedBox(height: 16),
          Panel(
            color: AppTokens.blue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.aSmallInvitation_67a1b1,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  state.condition == StudyCondition.selfAgent
                      ? context.l10n.whatWouldAManageableStartOn_e2d547(
                          (invitation.title).toString(),
                        )
                      : context.l10n.ifFeelsDifficultWouldASmaller_44870d(
                          (invitation.title).toString(),
                        ),
                ),
                TextButton(
                  onPressed: () => perform(context, () async {
                    await ref
                        .read(appProvider.notifier)
                        .invitationOpened(invitation.id);
                    if (context.mounted) {
                      context.push(
                        '/refine/${Uri.encodeComponent(invitation.id)}',
                      );
                    }
                  }),
                  child: Text(context.l10n.exploreASmallerStep_34fb75),
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        Card(
          child: ExpansionTile(
            title: Text(context.l10n.optionalSupport_f28163),
            subtitle: Text(
              context.l10n.checkInsAndPreferencesWheneverYou_c58ac3,
            ),
            children: [
              ListTile(
                leading: const Icon(Icons.spa_outlined),
                title: Text(context.l10n.optionalCheckIn_3f57e8),
                onTap: () => context.push('/check-in'),
              ),
              ListTile(
                leading: const Icon(Icons.tune),
                title: Text(context.l10n.yourPreferences_41bc34),
                onTap: () => context.push('/preferences'),
              ),
              if (state.checkIns.every((c) => c.phase != 'Baseline demo'))
                ListTile(
                  title: Text(context.l10n.tryABaselineCheckIn_a2c0b4),
                  onTap: () => context.push('/check-in?phase=baseline'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _chooseTask(
    BuildContext context,
    WidgetRef ref,
    List<Task> tasks,
    String selectedId,
  ) async {
    final id = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * .65,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 12, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.chooseOneTask_dd61ed,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    CloseButton(onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final task in tasks)
                      ListTile(
                        leading: Icon(
                          task.id == selectedId
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                        ),
                        selected: task.id == selectedId,
                        title: Text(
                          task.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () => Navigator.pop(context, task.id),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (id == null || !context.mounted) return;
    await perform(
      context,
      () => ref.read(appProvider.notifier).selectTodayTask(id),
    );
  }
}
