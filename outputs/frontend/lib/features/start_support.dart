import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/state.dart';
import '../app/reminders_controller.dart';
import '../data/models.dart';
import '../l10n/strings.dart';
import '../shared/widgets.dart';
import 'task_actions.dart';

/// User-authored plans, never model-executed instructions. Shared across conditions;
/// future-self reflection is explicitly restricted to Self-Agent.
class StartSupportPanel extends ConsumerWidget {
  final Task task;
  const StartSupportPanel({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.l10n;
    final reminders = ref.watch(remindersProvider);
    final paused =
        reminders.preferences.pausedUntil?.isAfter(DateTime.now()) == true;
    return Card(
      child: ExpansionTile(
        title: Text(l.supportPlan),
        subtitle: task.startCue.isEmpty
            ? null
            : Text('${task.startCue} → ${task.startAction}'),
        childrenPadding: const EdgeInsets.all(16),
        children: [
          Text(l.supportPlanHint),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.edit_calendar_outlined),
            label: Text(l.saveSupport),
            onPressed: () => showStartSupport(context, ref, task),
          ),
          TextButton(
            onPressed: () => showSubtaskEditor(context, ref, task),
            child: Text(l.supportSmallStep),
          ),
          TextButton(
            onPressed: () => showRecoverySheet(context, ref, task),
            child: Text(l.supportNotNow),
          ),
          TextButton(
            onPressed: () => showReminderSheet(context, ref, task),
            child: Text(l.remindMeLater_bebc1c),
          ),
          TextButton.icon(
            icon: const Icon(Icons.notifications_paused_outlined),
            label: Text(paused ? l.resumeReminders : l.pauseToday),
            onPressed: reminders.ready && !reminders.busy
                ? () => perform(
                    context,
                    () => ref
                        .read(remindersProvider.notifier)
                        .pauseToday(resume: paused),
                  )
                : null,
          ),
          Text(l.pauseHint),
        ],
      ),
    );
  }
}

Future<void> showStartSupport(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final selected = await showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _StartSupportEditor(task: task),
  );
  if (!context.mounted) return;
  if (selected == 'smaller') {
    await showSubtaskEditor(context, ref, task);
  } else if (selected == 'duration') {
    await showFocusSheet(context, ref, task);
  }
}

class _StartSupportEditor extends ConsumerStatefulWidget {
  final Task task;
  const _StartSupportEditor({required this.task});
  @override
  ConsumerState<_StartSupportEditor> createState() =>
      _StartSupportEditorState();
}

class _StartSupportEditorState extends ConsumerState<_StartSupportEditor> {
  late final cue = TextEditingController(text: widget.task.startCue);
  late final action = TextEditingController(text: widget.task.startAction);
  late final future = TextEditingController(text: widget.task.futureNote);
  late String difficulty = widget.task.difficulty;
  bool saving = false, adviceDismissed = false;
  String? error;

  @override
  void dispose() {
    cue.dispose();
    action.dispose();
    future.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (saving) return;
    if (cue.text.trim().isEmpty != action.text.trim().isEmpty) {
      setState(() => error = context.l10n.supportIncomplete);
      return;
    }
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final state = ref.read(appProvider);
      final current = state.tasks
          .where((t) => t.id == widget.task.id)
          .firstOrNull;
      if (current == null || current.version != widget.task.version) {
        throw StateError('This task changed. Close this panel and reopen it.');
      }
      await ref
          .read(appProvider.notifier)
          .saveTask(
            current.copyWith(
              startCue: cue.text.trim(),
              startAction: action.text.trim(),
              difficulty: difficulty,
              futureNote: state.condition == StudyCondition.selfAgent
                  ? future.text.trim()
                  : current.futureNote,
            ),
          );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.supportSaved)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) setState(() => error = context.tr('$e'));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final self =
        ref.watch(appProvider.select((s) => s.condition)) ==
        StudyCondition.selfAgent;
    final labels = {
      'unclear': l.difficultyUnclear,
      'overwhelming': l.difficultyOverwhelming,
      'worried': l.difficultyWorried,
      'distracted': l.difficultyDistracted,
      'tired': l.difficultyTired,
    };
    final advice = {
      'unclear': l.supportUnclear,
      'overwhelming': l.supportOverwhelming,
      'worried': l.supportWorried,
      'distracted': l.supportDistracted,
      'tired': l.supportTired,
    };
    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          8,
          24,
          MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(l.supportPlan, style: Theme.of(context).textTheme.titleLarge),
            Text(widget.task.title),
            const SizedBox(height: 12),
            Text(l.supportPlanHint),
            Text(l.uxDraftHint, style: Theme.of(context).textTheme.bodySmall),
            TextButton(
              onPressed: saving
                  ? null
                  : () => setState(() {
                      cue.text = l.uxExampleCue;
                      action.text = l.uxExampleAction;
                    }),
              child: Text(l.uxExample),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: cue,
              enabled: !saving,
              maxLength: 300,
              decoration: InputDecoration(labelText: l.startCue),
            ),
            TextField(
              controller: action,
              enabled: !saving,
              maxLength: 300,
              decoration: InputDecoration(labelText: l.startAction),
            ),
            Text(
              l.difficultyQuestion,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(l.difficultyOptional),
            Wrap(
              spacing: 8,
              children: [
                for (final entry in labels.entries)
                  ChoiceChip(
                    label: Text(entry.value),
                    selected: difficulty == entry.key,
                    onSelected: saving
                        ? null
                        : (selected) => setState(() {
                            difficulty = selected ? entry.key : '';
                            adviceDismissed = false;
                          }),
                  ),
              ],
            ),
            if (!adviceDismissed && advice[difficulty] != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(advice[difficulty]!),
                    TextButton(
                      onPressed: saving
                          ? null
                          : () async {
                              if (difficulty == 'unclear' ||
                                  difficulty == 'overwhelming') {
                                Navigator.pop(context, 'smaller');
                              } else if (difficulty == 'tired') {
                                Navigator.pop(context, 'duration');
                              } else {
                                setState(
                                  () => action.text =
                                      (difficulty == 'worried'
                                          ? l.uxDraftAction
                                          : l.uxDistractionAction) +
                                      widget.task.title,
                                );
                              }
                            },
                      child: Text(switch (difficulty) {
                        'worried' => l.uxRoughDraft,
                        'distracted' => l.uxDistraction,
                        'tired' => l.uxChooseDuration,
                        _ => l.uxReviewStep,
                      }),
                    ),
                    TextButton(
                      onPressed: saving
                          ? null
                          : () => setState(() => adviceDismissed = true),
                      child: Text(l.uxSkip),
                    ),
                  ],
                ),
              ),
            if (self) ...[
              Text(l.futureNoteHint),
              TextField(
                controller: future,
                enabled: !saving,
                maxLength: 1000,
                maxLines: 3,
                decoration: InputDecoration(labelText: l.futureNote),
              ),
            ],
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            PrimaryButton(l.saveSupport, onPressed: saving ? null : save),
          ],
        ),
      ),
    );
  }
}
