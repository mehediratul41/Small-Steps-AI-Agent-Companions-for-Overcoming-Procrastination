import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/state.dart';
import '../data/models.dart';
import '../shared/widgets.dart';
import 'task_actions.dart';

Future<void> showCorrectionSheet(BuildContext context, Task task) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => CorrectionSheet(task: task),
    );

class CorrectionSheet extends ConsumerStatefulWidget {
  final Task task;
  const CorrectionSheet({super.key, required this.task});
  @override
  ConsumerState<CorrectionSheet> createState() => _CorrectionSheetState();
}

class _CorrectionSheetState extends ConsumerState<CorrectionSheet> {
  final title = TextEditingController(),
      description = TextEditingController(),
      minutes = TextEditingController();
  CorrectionDraft? draft;
  bool loading = true, saving = false;
  String? error;
  @override
  void initState() {
    super.initState();
    Future.microtask(load);
  }

  @override
  void dispose() {
    title.dispose();
    description.dispose();
    minutes.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final result = await ref
          .read(appProvider.notifier)
          .proposeCorrection(widget.task);
      if (!mounted) return;
      title.text = result.correction.title;
      description.text = result.correction.description;
      minutes.text = '${result.correction.minutes}';
      setState(() => draft = result);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && ModalRoute.of(context)?.isCurrent == true) {
          ref
              .read(appProvider.notifier)
              .reportSuggestion('suggestion_displayed', widget.task, result.id)
              .catchError((Object _) {});
        }
      });
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> decide(bool accept) async {
    if (draft == null || saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      final correction = accept
          ? TaskCorrection.fromJson({
              'title': title.text.trim(),
              'description': description.text.trim(),
              'minutes': int.tryParse(minutes.text) ?? 0,
              'reason': draft!.correction.reason,
            })
          : null;
      await ref
          .read(appProvider.notifier)
          .decideCorrection(draft!, accepted: correction);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) setState(() => error = '$e');
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            context.l10n.reviewTaskCorrection_1ccbf7,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          Text(
            context.l10n.originalMinutes_bd2d00(
              (widget.task.title).toString(),
              (widget.task.minutes).toString(),
            ),
          ),
          Text(context.l10n.onlyTheTitleDescriptionAndEstimate_1dfeda),
          const SizedBox(height: 16),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (draft == null && error != null)
            ErrorPanel(error!, retry: load)
          else if (draft != null) ...[
            Text(
              context.l10n.value_948253(
                context.tr((draft!.condition.label).toString()),
                context.tr(
                  (ref.watch(appProvider).connected
                          ? 'Backend AI proposal'
                          : 'Scripted demo proposal')
                      .toString(),
                ),
              ),
            ),
            Text(draft!.correction.reason),
            const SizedBox(height: 16),
            TextField(
              controller: title,
              maxLength: 300,
              decoration: InputDecoration(
                labelText: context.l10n.suggestedTitleEditable_aa86af,
              ),
            ),
            TextField(
              controller: description,
              minLines: 2,
              maxLines: 5,
              maxLength: 5000,
              decoration: InputDecoration(
                labelText: context.l10n.suggestedDescriptionEditable_fe6d8a,
              ),
            ),
            TextField(
              controller: minutes,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: context.l10n.estimatedMinutes_a5485e,
              ),
            ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            const SizedBox(height: 16),
            PrimaryButton(
              context.l10n.acceptCorrection_9acb19,
              busy: saving,
              onPressed: () => decide(true),
            ),
            TextButton(
              onPressed: saving ? null : () => decide(false),
              child: Text(context.l10n.rejectCorrection_03abed),
            ),
          ],
        ],
      ),
    ),
  );
}

/// Task-aware UI recommendations. Free-form model text is never executed.
class AgentTaskActions extends ConsumerStatefulWidget {
  final Task? task;
  final ChatMessage? request;
  const AgentTaskActions({super.key, this.task, this.request});
  @override
  ConsumerState<AgentTaskActions> createState() => _AgentTaskActionsState();
}

class _AgentTaskActionsState extends ConsumerState<AgentTaskActions> {
  final Set<String> displayed = {};
  ScrollPosition? position;
  String? currentId;
  Task? currentTask;
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != position) {
      position?.removeListener(checkExposure);
      position = next;
      position?.addListener(checkExposure);
    }
  }

  @override
  void dispose() {
    position?.removeListener(checkExposure);
    super.dispose();
  }

  void checkExposure() {
    if (!mounted ||
        currentId == null ||
        displayed.contains(currentId) ||
        ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final box = context.findRenderObject();
    final Object? viewport = box == null
        ? null
        : RenderAbstractViewport.maybeOf(box);
    if (box is! RenderBox ||
        viewport is! RenderBox ||
        !box.hasSize ||
        !viewport.hasSize) {
      return;
    }
    final visible = (box.localToGlobal(Offset.zero) & box.size).intersect(
      viewport.localToGlobal(Offset.zero) & viewport.size,
    );
    if (visible.width <= 0 || visible.height <= 0) return;
    final id = currentId!;
    displayed.add(id);
    ref
        .read(appProvider.notifier)
        .reportSuggestion('suggestion_displayed', currentTask, id)
        .catchError((Object _) {});
  }

  @override
  Widget build(BuildContext context) {
    currentId = null;
    final state = ref.watch(appProvider);
    if (!state.condition.hasAgent ||
        widget.request == null ||
        widget.request!.delivery != 'sent') {
      return const SizedBox.shrink();
    }
    final originalText = widget.request!.text.toLowerCase();
    var text = originalText;
    // Intent hints do not alter stored/sent user text or execute model prose.
    if (['通知を止め', '通知をオフ', 'リマインダーを止め'].any(originalText.contains)) {
      text += ' stop reminders';
    } else if (['後で', 'リマインド', '知らせて'].any(originalText.contains)) {
      text += ' remind';
    } else if (['何を', 'どれ', '優先', '大切なタスク'].any(originalText.contains)) {
      text += ' what should';
    } else if (['分け', '小さな手順', '細かく'].any(originalText.contains)) {
      text += ' breakdown';
    } else if (['修正', '具体的', '明確に'].any(originalText.contains)) {
      text += ' correct';
    } else if (['延期', '予定を変', '先延ばし'].any(originalText.contains)) {
      text += ' reschedule';
    } else if (['完了', '終わり', '終わった'].any(originalText.contains)) {
      text += ' finished';
    } else if (['そっとして', 'やめて', '中断'].any(originalText.contains)) {
      return const SizedBox.shrink();
    } else if (['始め', '着手', '課題'].any(originalText.contains)) {
      text += ' start';
    }
    if (![
      'help',
      'task',
      'assignment',
      'work',
      'now',
      'productive',
      'priority',
      'important',
      'remind',
      'correct',
      'clarif',
      'break',
      'small',
      'reschedul',
      'postpon',
      'start',
      'finished',
      'stuck',
    ].any(text.contains)) {
      return const SizedBox.shrink();
    }
    if ((text.contains('stop') || text.contains('leave me')) &&
        !text.contains('remind')) {
      return const SizedBox.shrink();
    }
    final active = state.tasks.where((t) => !t.done && !t.paused).toList()
      ..sort((a, b) {
        final priority = (b.priority == 'High' ? 1 : 0).compareTo(
          a.priority == 'High' ? 1 : 0,
        );
        return priority != 0 ? priority : Task.compareSchedule(a, b);
      });
    final wantsNext =
        text.contains('what should') ||
        text.contains('most important') ||
        text.contains('priority') ||
        text.contains('productive');
    final task = wantsNext
        ? active.firstOrNull
        : widget.task ?? active.firstOrNull;
    final kind =
        ['stop', 'turn off', 'disable', 'no more'].any(text.contains) &&
            text.contains('remind')
        ? 'settings'
        : task == null || task.done || task.paused || text.contains('finished')
        ? 'review'
        : text.contains('break') || text.contains('smaller')
        ? 'breakdown'
        : text.contains('correct') || text.contains('clarif')
        ? 'correction'
        : text.contains('remind')
        ? 'reminder'
        : text.contains('reschedul') || text.contains('postpon')
        ? 'reschedule'
        : task.minutes > 60 ||
              task.title.trim().split(RegExp(r'\s+')).length < 3
        ? 'correction'
        : 'focus';
    final id =
        '${state.condition.name}:${widget.request!.id}:${task?.id}:${task?.version}:$kind';
    if (state.events.any(
      (e) =>
          e.kind == 'suggestion_dismissed' && e.details['suggestionId'] == id,
    )) {
      return const SizedBox.shrink();
    }
    currentId = id;
    currentTask = task;
    WidgetsBinding.instance.addPostFrameCallback((_) => checkExposure());
    final label = switch (kind) {
      'settings' => context.l10n.reviewNotificationPreferences_9a963c,
      'review' => context.l10n.reviewTaskStatus_6f6ec9,
      'breakdown' => context.l10n.reviewATaskBreakdown_359f9f,
      'correction' => context.l10n.clarifyThisTask_c41598,
      'reminder' => context.l10n.chooseAReminderTime_785b09,
      'reschedule' => context.l10n.reviewADifferentPlan_64fb85,
      _ => context.l10n.tryAFiveMinuteStart_c99d07,
    };
    Future<void> open() async {
      await ref
          .read(appProvider.notifier)
          .reportSuggestion('suggestion_opened', task, id);
      if (!context.mounted) return;
      switch (kind) {
        case 'settings':
          context.push('/settings');
        case 'review':
          context.push(
            task == null ? '/tasks' : '/task/${Uri.encodeComponent(task.id)}',
          );
        case 'breakdown':
          context.push('/refine/${Uri.encodeComponent(task!.id)}');
        case 'correction':
          await showCorrectionSheet(context, task!);
        case 'reminder':
          await showReminderSheet(context, ref, task!);
        case 'reschedule':
          await showRecoverySheet(context, ref, task!);
        default:
          // Opening the sheet is not initiation. The existing Start control is explicit.
          await showFocusSheet(context, ref, task!);
      }
    }

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExpansionTile(
            key: PageStorageKey('suggestion-details-$id'),
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            title: Text(label, style: Theme.of(context).textTheme.titleMedium),
            subtitle: task == null
                ? null
                : Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
            children: [
              if (task != null)
                Text(
                  context.l10n.priority_18c496(
                    (task.title).toString(),
                    context.tr((task.priority).toString()),
                    context.tr(
                      (task.subtasks.any((s) => !s.done)
                              ? '\nNext step: ${task.subtasks.where((s) => !s.done).first.title}'
                              : '')
                          .toString(),
                    ),
                  ),
                ),
              Text(
                kind == 'settings'
                    ? context.l10n.youCanTurnNotificationsOffThis_83fe52
                    : state.condition == StudyCondition.selfAgent
                    ? context.l10n.chooseWhatFitsYourOwnGoals_44f6d5
                    : context.l10n.weCanKeepThisManageableYou_ab5784,
              ),
              Text(
                context.l10n.appSelectedActionUsingYourTask_428a07,
                style: TextStyle(fontSize: 12),
              ),
            ],
          ),
          Text(
            context.l10n.msgTaskSupportSource,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          Wrap(
            children: [
              TextButton(
                onPressed: () => perform(context, open),
                child: Text(context.l10n.reviewSuggestion_bcac70),
              ),
              TextButton(
                onPressed: () => perform(
                  context,
                  () => ref
                      .read(appProvider.notifier)
                      .reportSuggestion('suggestion_dismissed', task, id),
                ),
                child: Text(context.l10n.dismiss_70afe9),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
