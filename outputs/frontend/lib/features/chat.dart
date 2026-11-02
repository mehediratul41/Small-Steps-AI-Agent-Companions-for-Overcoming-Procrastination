import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../shared/widgets.dart';
import 'task_actions.dart';
import 'agent_actions.dart';
import '../app/config.dart';
import '../data/saved_connections.dart';

/// One implementation for both conditions: identical composer, actions and layout.
class ChatScreen extends ConsumerStatefulWidget {
  final String? initialTaskId;
  const ChatScreen({super.key, this.initialTaskId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController();
  bool busy = false, switching = false;
  String? error, taskId;
  final Map<StudyCondition, String> drafts = {};
  @override
  void initState() {
    super.initState();
    taskId = widget.initialTaskId;
  }

  @override
  void didUpdateWidget(covariant ChatScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialTaskId != widget.initialTaskId) {
      taskId = widget.initialTaskId;
    }
  }

  @override
  void dispose() {
    input.dispose();
    scroll.dispose();
    super.dispose();
  }

  void scrollDown() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (scroll.hasClients) {
        scroll.jumpTo(scroll.position.maxScrollExtent);
      }
    });
  }

  Future<void> switchAgent(StudyCondition agent) async {
    if (busy || switching || agent == ref.read(appProvider).condition) return;
    final previous = ref.read(appProvider).condition;
    drafts[previous] = input.text;
    setState(() => switching = true);
    try {
      final controller = ref.read(appProvider.notifier);
      if (ref.read(appProvider).connected) {
        await controller.switchLiveAgent(agent);
      } else {
        await controller.switchCondition(agent);
      }
      if (mounted) {
        setState(() {
          input.text = drafts[agent] ?? '';
          taskId = ref.read(appProvider).connected
              ? ref.read(appProvider).chatTaskId
              : taskId;
          error = null;
        });
      }
    } finally {
      if (mounted) setState(() => switching = false);
    }
  }

  Future<void> send(
    String text,
    Task? task, {
    bool retry = false,
    String? messageId,
  }) async {
    if (busy || text.trim().isEmpty) {
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    if (!retry) input.clear();
    try {
      final future = ref
          .read(appProvider.notifier)
          .send(text, task, retry: retry, retryMessageId: messageId);
      scrollDown();
      await future;
    } catch (e) {
      if (mounted) {
        setState(() {
          error = '$e';
        });
      }
    } finally {
      if (mounted) {
        setState(() => busy = false);
        scrollDown();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final condition = state.condition;
    if (!condition.hasAgent) {
      return EmptyPanel(
        context.l10n.standardTaskSupport_4fe425,
        context.l10n.chatIsUnavailableInThisCondition_fbd25e,
      );
    }
    final candidate = taskId ??=
        state.chatTaskId ??
        state.tasks.where((t) => !t.done && !t.paused).firstOrNull?.id ??
        '__general__';
    final selected =
        candidate == '__general__' ||
            state.tasks.any((t) => t.id == candidate) ||
            state.messages.any((m) => m.taskId == candidate)
        ? candidate
        : '__general__';
    final contextId = selected == '__general__' ? null : selected;
    final task = state.tasks.where((t) => t.id == contextId).firstOrNull;
    final archived = contextId != null && task == null;
    final messages = state.messages
        .where((m) => m.taskId == contextId)
        .toList();
    final archivedIds = state.messages
        .map((m) => m.taskId)
        .whereType<String>()
        .where((id) => !state.tasks.any((t) => t.id == id))
        .toSet();
    final otherAgent = condition == StudyCondition.selfAgent
        ? StudyCondition.friendAgent
        : StudyCondition.selfAgent;
    ref.watch(savedConnectionsProvider);
    final liveSwitch = ref
        .read(appProvider.notifier)
        .canSwitchLiveTo(otherAgent);
    final canSwitch =
        AppConfig.researcherDemo &&
        (!state.connected || liveSwitch) &&
        !busy &&
        !switching;
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact =
            constraints.maxHeight < 380 ||
            MediaQuery.textScalerOf(context).scale(14) > 21;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!compact)
                    Row(
                      children: [
                        AgentAvatar(condition),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.tr(condition.label),
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                condition == StudyCondition.selfAgent
                                    ? context.l10n.reflectionAutonomy_27a6a7
                                    : context.l10n.empathyGentleSupport_69b918,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  if (!compact) const SizedBox(height: 8),
                  if (constraints.maxHeight < 250)
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            context.tr(condition.label),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Tooltip(
                          message: context.l10n.switchTo_ce5010(
                            context.tr((otherAgent.label).toString()),
                          ),
                          child: TextButton.icon(
                            onPressed: canSwitch
                                ? () => perform(
                                    context,
                                    () => switchAgent(otherAgent),
                                  )
                                : null,
                            icon: const Icon(Icons.swap_horiz),
                            label: Text(context.l10n.switch_3e44c9),
                          ),
                        ),
                      ],
                    )
                  else
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final agent in [
                          StudyCondition.selfAgent,
                          StudyCondition.friendAgent,
                        ])
                          ChoiceChip(
                            label: Text(context.tr(agent.label)),
                            selected: condition == agent,
                            onSelected: canSwitch
                                ? (_) =>
                                      perform(context, () => switchAgent(agent))
                                : null,
                          ),
                      ],
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                controller: scroll,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                children: [
                  if (!state.connected && AppConfig.researcherDemo) ...[
                    Text(
                      context.l10n.scriptedDemoExplanation,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    TextButton.icon(
                      onPressed: busy || switching
                          ? null
                          : () => context.push('/backend'),
                      icon: const Icon(Icons.cloud_outlined),
                      label: Text(context.l10n.connectRealChat),
                    ),
                  ],
                  Text(
                    state.connected
                        ? liveSwitch
                              ? context.l10n.linkedAgentAccounts
                              : context
                                    .l10n
                                    .assignedByTheStudyBackendAgent_fcf49b
                        : context
                              .l10n
                              .researcherDemoSeparateAgentHistories_2e583b,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Chip(
                      label: Text(
                        condition == StudyCondition.selfAgent
                            ? context.l10n.selfReflection_4445e0
                            : context.l10n.supportiveChat_6a8335,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: softColor(
                        context,
                        condition == StudyCondition.selfAgent
                            ? AppTokens.mint
                            : AppTokens.lavender,
                      ),
                      side: BorderSide.none,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    key: ValueKey('${condition.name}-$selected'),
                    initialValue: selected,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: context.l10n.taskContext_0eecee,
                    ),
                    items: [
                      DropdownMenuItem(
                        value: '__general__',
                        child: Text(context.l10n.generalConversation_90962d),
                      ),
                      ...state.tasks.map(
                        (t) => DropdownMenuItem(
                          value: t.id,
                          child: Text(t.title, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      for (final id in archivedIds)
                        DropdownMenuItem(
                          value: id,
                          child: Text(
                            context.l10n.archivedTaskConversation_426aa2,
                          ),
                        ),
                    ],
                    onChanged: busy
                        ? null
                        : (v) {
                            setState(() {
                              taskId = v;
                              error = null;
                            });
                            ref.read(appProvider.notifier).selectChatTask(v);
                          },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    archived
                        ? context.l10n.thisTaskWasDeletedItsConversation_35be64
                        : context.l10n.messagesAndRetriesStayLinkedTo_f396c0,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 24),
                  if (messages.isEmpty)
                    MessageBubble(
                      ChatMessage(
                        id: 'intro',
                        text: condition == StudyCondition.selfAgent
                            ? 'What matters to you about the task you would like to begin?\n\nYou can choose a small step that fits your goals.'
                            : 'Starting can feel difficult sometimes.\n\nWould you like to talk about what feels hard, or try one small step together?',
                        user: false,
                        at: DateTime.now(),
                      ),
                    ),
                  for (final message in messages) ...[
                    MessageBubble(message),
                    if (message.user && message.delivery == 'failed')
                      Panel(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.theResponseDidNotArriveYou_c601c2,
                            ),
                            Wrap(
                              spacing: 8,
                              children: [
                                TextButton(
                                  onPressed: busy || archived
                                      ? null
                                      : () => send(
                                          message.text,
                                          task,
                                          retry: true,
                                          messageId: message.id,
                                        ),
                                  child: Text(context.l10n.tryAgain_042c86),
                                ),
                                TextButton(
                                  onPressed: busy || archived
                                      ? null
                                      : () async {
                                          await ref
                                              .read(appProvider.notifier)
                                              .cancelMessage(message.id);
                                          if (mounted) {
                                            setState(() {
                                              input.text = message.text;
                                              error = null;
                                            });
                                          }
                                        },
                                  child: Text(context.l10n.editMessage_96116a),
                                ),
                                TextButton(
                                  onPressed: busy
                                      ? null
                                      : () async {
                                          await ref
                                              .read(appProvider.notifier)
                                              .cancelMessage(message.id);
                                          if (mounted) {
                                            setState(() => error = null);
                                          }
                                        },
                                  child: Text(context.l10n.cancelRetry_09ba40),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    if (message.delivery == 'cancelled')
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          context
                              .l10n
                              .responseRetryCancelledMessageKeptIn_33e3a4,
                        ),
                      ),
                  ],
                  if (busy)
                    Semantics(
                      liveRegion: true,
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          state.connected
                              ? context.l10n.agentIsComposingAResponse_ec1bc2
                              : context
                                    .l10n
                                    .agentIsComposingADemoResponse_66b3f0,
                        ),
                      ),
                    ),
                  if (error != null)
                    Text(
                      error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 8),
                  AgentTaskActions(
                    task: task,
                    request: messages.where((m) => m.user).lastOrNull,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      ActionChip(
                        label: Text(context.l10n.correctThisTask_ef9d4d),
                        onPressed:
                            task == null || task.done || task.paused || busy
                            ? null
                            : () => showCorrectionSheet(context, task),
                      ),
                      ActionChip(
                        label: Text(context.l10n.chooseAFocusSession_41945f),
                        onPressed: task == null || task.done || task.paused
                            ? null
                            : () => showFocusSheet(context, ref, task),
                      ),
                      ActionChip(
                        label: Text(context.l10n.breakItDown_5798bd),
                        onPressed: task == null || task.done
                            ? null
                            : () => context.push('/refine/${task.id}'),
                      ),
                      ActionChip(
                        label: Text(context.l10n.reflectOnMyGoal_6d1d30),
                        onPressed: busy || archived
                            ? null
                            : () => send(
                                context.l10n.helpMeReflectOnMyGoal_d4b855,
                                task,
                              ),
                      ),
                      ActionChip(
                        label: Text(context.l10n.remindMeLater_bebc1c),
                        onPressed: task == null || task.done || task.paused
                            ? null
                            : () => showReminderSheet(context, ref, task),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    state.connected
                        ? context.l10n.connectedDevelopmentAiRepliesMayBe_ab7a5a
                        : context.l10n.demonstrationResponsesNotALiveAi_83abaf,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: input,
                      minLines: 1,
                      maxLines: 4,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        hintText: context.l10n.messageYour_e972d5(
                          context.tr(
                            (condition.label.toLowerCase()).toString(),
                          ),
                        ),
                        counterText: '',
                      ),
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: context.l10n.sendMessage_c70a89,
                    onPressed: busy || archived
                        ? null
                        : () => send(input.text, task),
                    icon: const Icon(Icons.arrow_forward),
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  const MessageBubble(this.message, {super.key});
  @override
  Widget build(BuildContext context) => Align(
    alignment: message.user ? Alignment.centerRight : Alignment.centerLeft,
    child: FractionallySizedBox(
      widthFactor: message.user ? 0.84 : 1,
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: message.user
              ? AppTokens.teal
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(19),
        ),
        child: Semantics(
          label: message.user
              ? context.l10n.you_905cb3
              : context.l10n.agent_5ce2e6,
          child: SelectableText(
            message.text,
            style: TextStyle(
              color: message.user
                  ? Colors.white
                  : Theme.of(context).colorScheme.onSurface,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ),
    ),
  );
}
