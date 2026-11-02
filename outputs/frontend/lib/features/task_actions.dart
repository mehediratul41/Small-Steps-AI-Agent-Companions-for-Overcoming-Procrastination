import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/state.dart';
import '../data/models.dart';
import '../shared/widgets.dart';

Future<DateTime?> chooseDateTime(
  BuildContext context, {
  DateTime? initial,
}) async {
  final start = initial ?? DateTime.now().add(const Duration(hours: 1));
  final day = await showDatePicker(
    context: context,
    initialDate: start,
    firstDate: DateTime(start.year < 2020 ? start.year : 2020),
    lastDate: DateTime(start.year > 2100 ? start.year : 2100, 12, 31),
  );
  if (day == null || !context.mounted) return null;
  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(start),
  );
  return time == null
      ? null
      : DateTime(day.year, day.month, day.day, time.hour, time.minute);
}

Future<void> showReminderSheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final minutes = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.remindMeLater_bebc1c,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(task.title),
              const SizedBox(height: 12),
              for (final value in [15, 30, 60])
                ListTile(
                  title: Text(
                    context.l10n.inMinutes_3400a8((value).toString()),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, value),
                ),
              ListTile(
                title: Text(context.l10n.chooseATime_09efe8),
                onTap: () => Navigator.pop(context, -1),
              ),
              Text(context.l10n.thisChangesTheReminderOnlyYour_5da181),
            ],
          ),
        ),
      ),
    ),
  );
  if (minutes == null || !context.mounted) return;
  final at = minutes == -1
      ? await chooseDateTime(context)
      : DateTime.now().add(Duration(minutes: minutes));
  if (at == null || !context.mounted) return;
  await perform(context, () async {
    await ref.read(appProvider.notifier).snooze(task.id, at);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.reminderTimeSavedDeliveryDependsOn_26ca16(
              (DateFormat.MMMd().add_jm().format(at)).toString(),
            ),
          ),
        ),
      );
    }
  });
}

Future<void> showFocusSheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  if (ref.read(appProvider).focus != null) {
    context.push('/focus');
    return;
  }
  final minutes = await showModalBottomSheet<int>(
    context: context,
    showDragHandle: true,
    builder: (context) => SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.l10n.makeRoomForASmallStart_9f05fd,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(task.title),
              const SizedBox(height: 16),
              for (final minutes in [5, 10, 15, 25])
                ListTile(
                  title: Text(
                    context.l10n.minutes_8d40d2((minutes).toString()),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.pop(context, minutes),
                ),
              Text(context.l10n.chooseADurationThenStartWhen_6c8fb1),
            ],
          ),
        ),
      ),
    ),
  );
  if (minutes == null || !context.mounted) return;
  await perform(context, () async {
    await ref
        .read(appProvider.notifier)
        .prepareFocus(task.id, minutes: minutes);
    if (context.mounted) context.push('/focus');
  });
}

Future<void> showRecoverySheet(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  String? reason;
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  context.l10n.adjustThePlan_9b154f,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(context.l10n.plansChangeChooseWhatWorksFor_80a848),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  initialValue: reason,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: context.l10n.optionalReason_b2c92f,
                  ),
                  items:
                      [
                            'Priorities changed',
                            'The task feels too large',
                            'Energy or time is limited',
                            'I did not feel ready',
                            'Prefer not to answer',
                          ]
                          .map(
                            (s) => DropdownMenuItem(value: s, child: Text(s)),
                          )
                          .toList(),
                  onChanged: (s) => setState(() => reason = s),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.event_outlined),
                  title: Text(context.l10n.chooseAnotherStartTime_7d26d3),
                  onTap: () => Navigator.pop(context, 'reschedule'),
                ),
                ListTile(
                  leading: const Icon(Icons.pause_circle_outline),
                  title: Text(
                    task.paused
                        ? context.l10n.resumeThisTask_a4926e
                        : context.l10n.pauseThisTask_993399,
                  ),
                  onTap: () =>
                      Navigator.pop(context, task.paused ? 'resume' : 'pause'),
                ),
                ListTile(
                  leading: const Icon(Icons.checklist),
                  title: Text(context.l10n.chooseASmallerStep_58fb38),
                  onTap: () => Navigator.pop(context, 'smaller_step'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(context.l10n.keepMyPlan_b160c2),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  DateTime? start;
  if (action == 'reschedule') {
    start = await chooseDateTime(context, initial: task.plannedStart);
    if (start == null || !context.mounted) return;
  }
  await perform(context, () async {
    await ref
        .read(appProvider.notifier)
        .recoverTask(task.id, action, reason: reason, plannedStart: start);
    if (!context.mounted) return;
    if (action == 'smaller_step') {
      if (ref.read(appProvider).condition.hasAgent) {
        context.push('/refine/${task.id}');
      } else {
        await showSubtaskEditor(context, ref, task);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.yourPlanHasBeenUpdated_3e0c3d)),
      );
    }
  });
}

Future<void> showSubtaskEditor(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final fields = task.subtasks
      .map((s) => TextEditingController(text: s.title))
      .toList();
  if (fields.isEmpty) fields.add(TextEditingController());
  final removed = <TextEditingController>[];
  final steps = await showDialog<List<Subtask>>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(context.l10n.yourSmallSteps_dcbeb9),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(context.l10n.writeEditOrRemoveYourOwn_c6e042),
                for (var i = 0; i < fields.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: fields[i],
                            maxLength: 160,
                            decoration: InputDecoration(
                              labelText: context.l10n.step_203035(
                                (i + 1).toString(),
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: context.l10n.removeStep_1d868a(
                            (i + 1).toString(),
                          ),
                          onPressed: () => setState(() {
                            removed.add(fields.removeAt(i));
                          }),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                  ),
                TextButton.icon(
                  onPressed: fields.length >= 20
                      ? null
                      : () =>
                            setState(() => fields.add(TextEditingController())),
                  icon: const Icon(Icons.add),
                  label: Text(context.l10n.addAStep_90d24a),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel_77dfd2),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, [
              for (final f in fields)
                if (f.text.trim().isNotEmpty)
                  Subtask(
                    f.text.trim(),
                    done: task.subtasks.any(
                      (s) => s.title == f.text.trim() && s.done,
                    ),
                  ),
            ]),
            child: Text(context.l10n.saveSteps_802b24),
          ),
        ],
      ),
    ),
  );
  if (steps != null && context.mounted) {
    await perform(context, () async {
      final latest = ref
          .read(appProvider)
          .tasks
          .where((t) => t.id == task.id)
          .firstOrNull;
      if (latest == null || latest.version != task.version) {
        throw StateError('This task changed. Reopen the steps editor.');
      }
      await ref
          .read(appProvider.notifier)
          .saveTask(latest.copyWith(subtasks: steps));
    });
  }
  Future<void>.delayed(const Duration(milliseconds: 400), () {
    for (final f in [...fields, ...removed]) {
      f.dispose();
    }
  });
}
