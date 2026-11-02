import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../data/models.dart';
import 'task_actions.dart';
import '../app/reminders_controller.dart';
import '../app/state.dart';
import '../shared/widgets.dart';

class ReminderSettings extends ConsumerWidget {
  const ReminderSettings({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remindersProvider);
    final controller = ref.read(remindersProvider.notifier);
    final connected = ref.watch(appProvider.select((s) => s.connected));
    final consent = ref.watch(appProvider.select((s) => s.consent));
    String time(int minutes) =>
        TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60).format(context);
    Future<void> pick(bool start) async {
      final minutes = start
          ? state.preferences.quietStart
          : state.preferences.quietEnd;
      final selected = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      );
      if (selected == null || !context.mounted) {
        return;
      }
      final value = selected.hour * 60 + selected.minute;
      if (value ==
          (start ? state.preferences.quietEnd : state.preferences.quietStart)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.chooseDifferentStartAndEndTimes_8cf782),
          ),
        );
        return;
      }
      await controller.setQuietHours(
        start: start ? value : null,
        end: start ? null : value,
      );
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.taskReminders_ca6754,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(context.l10n.chooseWhetherYourPhoneNotifiesYou_21a270),
          TextButton.icon(
            icon: const Icon(Icons.notifications_paused_outlined),
            label: Text(
              state.preferences.pausedUntil?.isAfter(DateTime.now()) == true
                  ? context.l10n.resumeReminders
                  : context.l10n.pauseToday,
            ),
            onPressed: state.ready && !state.busy
                ? () => perform(
                    context,
                    () => controller.pauseToday(
                      resume:
                          state.preferences.pausedUntil?.isAfter(
                            DateTime.now(),
                          ) ==
                          true,
                    ),
                  )
                : null,
          ),
          Text(context.l10n.pauseHint),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.allowTaskNotifications_1e16ea),
            value: state.preferences.enabled,
            onChanged: state.ready && state.supported && consent && !state.busy
                ? controller.setEnabled
                : null,
          ),
          if (!consent)
            Text(
              context
                  .l10n
                  .completeDemoOnboardingBeforeEnablingNotifications_5ff178,
            ),
          const ReminderStatusPanel(framed: false),
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(context.l10n.reminderTypesLimits_feea2b),
            subtitle: Text(
              context.l10n.upToScheduledSlotsPerDay_77771e(
                (state.preferences.dailyLimit).toString(),
                (state.preferences.cooldownMinutes).toString(),
              ),
            ),
            children: [
              Text(context.l10n.additionalTypesAreOffUntilYou_bfe80c),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.remindAtPlannedStart_0f1513),
                value: state.preferences.plannedStarts,
                onChanged: state.ready && !state.busy
                    ? (v) => controller.setPolicy(plannedStarts: v)
                    : null,
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.remindAtDeadline_bbd863),
                value: state.preferences.deadlines,
                onChanged: state.ready && !state.busy
                    ? (v) => controller.setPolicy(deadlines: v)
                    : null,
              ),
              if (ref.watch(appProvider).condition.hasAgent)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(context.l10n.useAssignedAgentWording_104d77),
                  subtitle: Text(
                    context.l10n.fixedGentleTemplatesNoAiCall_56fe14,
                  ),
                  value: state.preferences.agentVoice,
                  onChanged: state.ready && !state.busy
                      ? (v) => controller.setPolicy(agentVoice: v)
                      : null,
                ),
              DropdownButtonFormField<int>(
                isExpanded: true,
                key: ValueKey('daily-${state.preferences.dailyLimit}'),
                initialValue: state.preferences.dailyLimit,
                decoration: InputDecoration(
                  labelText: context.l10n.maximumScheduledSlotsPerDay_23ac4f,
                ),
                items:
                    ({1, 3, 5, 10, state.preferences.dailyLimit}.toList()
                          ..sort())
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              context.l10n.value_114413((v).toString()),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: state.ready && !state.busy
                    ? (v) => controller.setPolicy(dailyLimit: v)
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                isExpanded: true,
                key: ValueKey('cooldown-${state.preferences.cooldownMinutes}'),
                initialValue: state.preferences.cooldownMinutes,
                decoration: InputDecoration(
                  labelText: context.l10n.minimumTimeBetweenSlots_28a254,
                ),
                items:
                    ({
                          0,
                          30,
                          60,
                          120,
                          240,
                          state.preferences.cooldownMinutes,
                        }.toList()..sort())
                        .map(
                          (v) => DropdownMenuItem(
                            value: v,
                            child: Text(
                              context.l10n.minutes_8d40d2((v).toString()),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: state.ready && !state.busy
                    ? (v) => controller.setPolicy(cooldownMinutes: v)
                    : null,
              ),
              const SizedBox(height: 12),
            ],
          ),
          const Divider(height: 28),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(context.l10n.quietHours_706b24),
            subtitle: Text(context.l10n.moveRemindersInThisPeriodTo_644d2e),
            value: state.preferences.quietHours,
            onChanged: state.ready && !state.busy
                ? (v) => controller.setQuietHours(enabled: v)
                : null,
          ),
          if (state.preferences.quietHours) ...[
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: state.busy ? null : () => pick(true),
                  child: Text(
                    context.l10n.from_80d3ab(
                      (time(state.preferences.quietStart)).toString(),
                    ),
                  ),
                ),
                OutlinedButton(
                  onPressed: state.busy ? null : () => pick(false),
                  child: Text(
                    context.l10n.until_7472c2(
                      (time(state.preferences.quietEnd)).toString(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          if (connected)
            Text(context.l10n.connectedReminderTimesAreSavedAs_5a3346),
          Text(
            context.l10n.localClockTimeWhenYouReopen_6f9b9e(
              (state.timezone == null ? '' : ' · ${state.timezone}').toString(),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (state.waiting > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                context.l10n.theNextRemindersAreScheduledReopen_cc8080(
                  (RemindersController.maximumPending).toString(),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ReminderStatusPanel extends ConsumerWidget {
  final Task? task;
  final bool framed;
  const ReminderStatusPanel({super.key, this.task, this.framed = true});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(remindersProvider);
    final app = ref.watch(appProvider);
    final controller = ref.read(remindersProvider.notifier);
    bool savedTime(Task t) =>
        t.reminder != null ||
        (state.preferences.plannedStarts && t.plannedStart != null) ||
        (state.preferences.deadlines && t.due != null);
    final hasTime = task != null
        ? savedTime(task!)
        : app.tasks.any((t) => savedTime(t) && !t.done && !t.paused);
    final plans = state.scheduled.where((r) => r.taskId == task?.id).toList();
    final plan = plans.firstOrNull;
    String title, detail;
    String? action;
    VoidCallback? onAction;
    var permissionAction = false;
    if (state.error != null) {
      title = context.l10n.couldNotUpdateReminders_92128b;
      detail = state.error!;
      action = 'Try again';
      onAction = controller.refresh;
    } else if (!state.ready || state.busy) {
      title = state.busy
          ? context.l10n.updatingReminders_d06961
          : context.l10n.checkingReminders_651066;
      detail = context.l10n.pleaseWaitWhileThisPhoneChecks_26f534;
    } else if (task != null && (task!.done || task!.paused)) {
      title = context.l10n.noActiveReminder_48abe9;
      detail = task!.done
          ? context.l10n.thisTaskIsCompleteItsReminders_f3d943
          : context.l10n.thisTaskIsPausedResumeIt_27db0a;
    } else if (!state.supported) {
      title = hasTime
          ? context.l10n.timeSaved_bf2a1a
          : context.l10n.phoneRemindersUnavailable_3844a0;
      detail = hasTime
          ? context.l10n.thisPreviewSavesTheTimeBut_95d4b4
          : context.l10n.thisPreviewCannotSendNotificationsYou_01e75e;
    } else if (!app.consent) {
      title = context.l10n.notificationsOff_0b58a9;
      detail = context.l10n.completeDemoOnboardingBeforeEnablingPhone_f92eeb;
      action = 'Complete onboarding';
      onAction = () => context.go('/consent');
    } else if (!state.preferences.enabled) {
      title = context.l10n.notificationsOff_0b58a9;
      detail = hasTime
          ? context.l10n.yourReminderTimeIsSavedTurn_a05f65
          : context.l10n.youDecideWhetherThisPhoneSends_fdb337;
      action = 'Enable notifications';
      onAction = () => controller.setEnabled(true);
    } else if (!state.permission) {
      title = context.l10n.permissionNeeded_7c7a8e;
      detail = context.l10n.thisPhoneHasNotAllowedNotifications_e79c77;
      action = 'Request permission';
      onAction = () => controller.setEnabled(true);
      permissionAction = true;
    } else if (plan != null || (task == null && state.scheduled.isNotEmpty)) {
      title = context.l10n.scheduledOnThisPhone_441ddb;
      detail = plan != null
          ? context.l10n.yourPhoneMayDelayDelivery_f30906(
              (plans
                      .map(
                        (p) =>
                            '${context.tr(p.category == 'deadline'
                                ? 'Deadline'
                                : p.category == 'planned_start'
                                ? 'Planned start'
                                : 'Manual reminder')}: ${DateFormat.MMMd().add_jm().format(p.scheduledAt)}${p.deferred ? context.tr(' after quiet hours') : ''}',
                      )
                      .join('\n'))
                  .toString(),
            )
          : context.l10n.upcomingReminderYourPhoneMayDelay_322859(
              (state.scheduled.length).toString(),
              context.tr((state.scheduled.length == 1 ? '' : 's').toString()),
            );
      action = 'Check again';
      onAction = controller.refresh;
    } else {
      title = task != null && hasTime
          ? context.l10n.timeSaved_bf2a1a
          : context.l10n.noUpcomingReminders_114a7c;
      detail = task != null && hasTime
          ? context.l10n.thisTaskIsNotCurrentlyScheduled_6cb52b
          : context.l10n.chooseAFutureReminderTimeOn_f01a16;
      action = task != null ? 'Choose a time' : 'Choose a task';
      onAction = task != null
          ? () => showReminderSheet(context, ref, task!)
          : () => context.go('/tasks');
    }
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          liveRegion: true,
          child: Text(title, style: Theme.of(context).textTheme.titleMedium),
        ),
        const SizedBox(height: 8),
        Text(context.tr(detail), style: Theme.of(context).textTheme.bodySmall),
        if (state.busy || !state.ready)
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: LinearProgressIndicator(),
          ),
        if (action != null)
          TextButton(
            onPressed: state.busy ? null : onAction,
            child: Text(context.tr(action)),
          ),
        if (permissionAction)
          TextButton(
            onPressed: state.busy ? null : controller.refresh,
            child: Text(context.l10n.checkAgain_e18504),
          ),
        if (state.waiting > 0)
          Text(
            context.l10n.moreWaitingForASchedulingSlot_bf9d6a(
              (state.waiting).toString(),
            ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
      ],
    );
    return framed ? Panel(child: content) : content;
  }
}
