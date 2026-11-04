import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/chat_memory.dart';
import '../app/config.dart';
import '../app/state.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../data/saved_connections.dart';
import '../l10n/strings.dart';
import '../shared/widgets.dart';
import 'agent_actions.dart';
import 'chat_widgets.dart';
import 'task_actions.dart';
export 'chat_widgets.dart' show MessageBubble;

/// Both personas share navigation, composer, timeline and task capabilities.
class ChatScreen extends ConsumerStatefulWidget {
  final String? initialTaskId;
  const ChatScreen({super.key, this.initialTaskId});
  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final input = TextEditingController();
  final scroll = ScrollController(keepScrollOffset: false);
  bool busy = false,
      switching = false,
      newReply = false,
      followReply = true,
      restoring = false;
  String? taskId;
  AppFailure? failure;
  String? failedId;
  ChatKey? activeKey;
  String? lastMessage;

  @override
  void initState() {
    super.initState();
    taskId = widget.initialTaskId;
    scroll.addListener(rememberOffset);
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
    scroll.removeListener(rememberOffset);
    scroll.dispose();
    super.dispose();
  }

  void rememberOffset() {
    if (!restoring && activeKey != null && scroll.hasClients) {
      ref.read(chatMemoryProvider.notifier).offset(activeKey!, scroll.offset);
    }
  }

  void draft(String value) {
    if (activeKey != null) {
      ref.read(chatMemoryProvider.notifier).draft(activeKey!, value);
    }
  }

  void bind(ChatKey key, String? latest) {
    if (activeKey == key) return;
    activeKey = key;
    lastMessage = latest;
    failure = null;
    failedId = null;
    newReply = false;
    restoring = true;
    input.text = ref.read(chatMemoryProvider).drafts[key] ?? '';
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || activeKey != key || !scroll.hasClients) return;
      final saved = ref.read(chatMemoryProvider).offsets[key];
      scroll.jumpTo(
        (saved ?? scroll.position.maxScrollExtent).clamp(
          0,
          scroll.position.maxScrollExtent,
        ),
      );
      followReply = scroll.position.extentAfter < 100;
      restoring = false;
    });
  }

  void latest({bool force = false}) {
    final key = activeKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || key != activeKey || !scroll.hasClients) return;
      if (force || followReply) {
        scroll.jumpTo(scroll.position.maxScrollExtent);
        if (newReply) setState(() => newReply = false);
      } else if (!newReply) {
        setState(() => newReply = true);
      }
    });
  }

  Future<void> switchAgent(StudyCondition agent) async {
    if (busy || switching || agent == ref.read(appProvider).condition) return;
    setState(() => switching = true);
    try {
      final controller = ref.read(appProvider.notifier);
      if (ref.read(appProvider).connected) {
        await controller.switchLiveAgent(agent);
      } else {
        await controller.switchCondition(agent);
      }
      if (mounted) setState(() => taskId = ref.read(appProvider).chatTaskId);
    } finally {
      if (mounted) setState(() => switching = false);
    }
  }

  Future<void> signInAgain() async {
    if (busy || switching) return;
    final router = GoRouter.of(context);
    setState(() => switching = true);
    try {
      await perform(context, () async {
        if (ref.read(appProvider).connected) {
          await ref.read(appProvider.notifier).disconnectBackend();
        }
        router.go('/account');
      });
    } finally {
      if (mounted) setState(() => switching = false);
    }
  }

  Future<void> retryConnection() async {
    if (busy || switching) return;
    setState(() => switching = true);
    try {
      await perform(
        context,
        () => ref.read(appProvider.notifier).retrySavedConnection(),
      );
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
    if (busy ||
        switching ||
        text.trim().isEmpty ||
        ref.read(appProvider.notifier).needsConnectionRecovery) {
      return;
    }
    final key = activeKey;
    final before = ref.read(appProvider).messages.map((m) => m.id).toSet();
    final clearComposer = !retry && input.text.trim() == text.trim();
    setState(() {
      busy = true;
      failure = null;
      failedId = null;
    });
    if (clearComposer) {
      input.clear();
      draft('');
    }
    followReply = true;
    try {
      final pending = ref
          .read(appProvider.notifier)
          .send(text, task, retry: retry, retryMessageId: messageId);
      latest(force: true);
      await pending;
      if (mounted) latest();
    } catch (error) {
      if (!mounted) return;
      final saved = ref
          .read(appProvider)
          .messages
          .where(
            (m) =>
                m.user &&
                (retry ? m.id == messageId : !before.contains(m.id)) &&
                m.delivery == 'failed',
          )
          .lastOrNull;
      setState(() {
        failure = error is AppFailure ? error : AppFailure('$error');
        failedId = saved?.id;
      });
      if (clearComposer && saved == null && key == activeKey) {
        input.text = text;
        draft(text);
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> conversations(AppState snapshot, String selected) async {
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (_) =>
          ConversationPicker(snapshot: snapshot, selected: selected),
    );
    if (!mounted || result == null) return;
    final current = ref.read(appProvider);
    if (chatOwner(current) != chatOwner(snapshot) ||
        current.condition != snapshot.condition) {
      return;
    }
    setState(() => taskId = result);
    if (!ref.read(appProvider.notifier).needsConnectionRecovery) {
      await perform(
        context,
        () => ref.read(appProvider.notifier).selectChatTask(result),
      );
    }
  }

  void information(AppState state, bool linked) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.uxChatInfo,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              if (state.error != null) Text(context.tr(state.error!)),
              Text(context.tr(state.condition.label)),
              Text(
                state.condition == StudyCondition.selfAgent
                    ? context.l10n.reflectionAutonomy_27a6a7
                    : context.l10n.empathyGentleSupport_69b918,
              ),
              const SizedBox(height: 12),
              Text(
                state.connected
                    ? context
                          .l10n
                          .connectedDevelopmentUsesASyntheticAccount_13f12b
                    : context.l10n.scriptedDemoExplanation,
              ),
              const SizedBox(height: 12),
              Text(
                state.connected
                    ? linked
                          ? context.l10n.linkedAgentAccounts
                          : context.l10n.assignedByTheStudyBackendAgent_fcf49b
                    : context.l10n.researcherDemoSeparateAgentHistories_2e583b,
              ),
              Text(context.l10n.messagesAndRetriesStayLinkedTo_f396c0),
              if (!state.connected && AppConfig.researcherDemo)
                TextButton.icon(
                  icon: const Icon(Icons.cloud_outlined),
                  label: Text(context.l10n.connectRealChat),
                  onPressed: () {
                    Navigator.pop(sheet);
                    context.push('/backend');
                  },
                ),
              TextButton.icon(
                icon: const Icon(Icons.settings_outlined),
                label: Text(context.l10n.settings_c7f73b),
                onPressed: () {
                  Navigator.pop(sheet);
                  context.push('/settings');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void more(Task? task, bool blocked, bool archived) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheet) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text(context.l10n.uxMoreActions)),
              ListTile(
                leading: const Icon(Icons.edit_note),
                title: Text(context.l10n.correctThisTask_ef9d4d),
                enabled: !blocked && task != null && !task.done && !task.paused,
                onTap: () {
                  Navigator.pop(sheet);
                  showCorrectionSheet(context, task!);
                },
              ),
              ListTile(
                leading: const Icon(Icons.lightbulb_outline),
                title: Text(context.l10n.reflectOnMyGoal_6d1d30),
                enabled: !blocked && !archived,
                onTap: () {
                  Navigator.pop(sheet);
                  send(context.l10n.helpMeReflectOnMyGoal_d4b855, task);
                },
              ),
              ListTile(
                leading: const Icon(Icons.notifications_none),
                title: Text(context.l10n.remindMeLater_bebc1c),
                enabled: !blocked && task != null && !task.done && !task.paused,
                onTap: () {
                  Navigator.pop(sheet);
                  showReminderSheet(context, ref, task!);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  String failureText(AppFailure? error) => switch (error?.code) {
    'capacity' =>
      context.isJapanese
          ? 'Geminiは現在混雑しています。時間をおいてから「メッセージを編集」で内容を確認し、新しい試行として送信してください。'
          : 'Gemini is temporarily at capacity. Wait, then use Edit message to review and send a new attempt.',
    'quota' =>
      context.isJapanese
          ? 'Gemini APIの利用上限に達しました。管理者が利用制限を確認する必要があります。'
          : 'Gemini API quota was reached. The server operator needs to check the project limits.',
    'provider_access' =>
      context.isJapanese
          ? 'Gemini APIへのアクセスが拒否されました。管理者がサーバーの認証情報と権限を確認する必要があります。'
          : 'Gemini API access was rejected. The server operator needs to check its credentials and permissions.',
    'network' => context.l10n.msgNetwork,
    'timeout' => context.l10n.msgTimeout,
    'limited' => context.l10n.msgLimited,
    'provider' => context.l10n.msgProvider,
    'pending' => context.l10n.msgPending,
    'malformed' => context.l10n.msgMalformed,
    _ =>
      error == null ? context.l10n.msgCouldNotSend : context.tr(error.message),
  };
  Future<void> messageOption(String choice, ChatMessage message) async {
    if (choice == 'details') {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(context.l10n.msgDetails),
          content: Text(failureText(failedId == message.id ? failure : null)),
        ),
      );
      return;
    }
    await perform(context, () async {
      await ref.read(appProvider.notifier).cancelMessage(message.id);
      if (!mounted) return;
      setState(() {
        failure = null;
        failedId = null;
      });
      if (choice == 'edit') {
        input.text = message.text;
        draft(message.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final controller = ref.read(appProvider.notifier);
    final recovery = controller.needsConnectionRecovery,
        expired = controller.sessionExpired;
    final condition = state.condition;
    ref.read(
      chatMemoryProvider,
    ); // activate account-transition cleanup even without a draft
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
    final task = state.tasks.where((t) => t.id == selected).firstOrNull;
    final archived = selected != '__general__' && task == null;
    final messages = state.messages
        .where((m) => (m.taskId ?? '__general__') == selected)
        .toList();
    final key = chatKey(state, selected);
    bind(key, messages.lastOrNull?.id);
    if (lastMessage != messages.lastOrNull?.id) {
      lastMessage = messages.lastOrNull?.id;
      if (messages.lastOrNull?.user == false) latest();
    }
    ref.watch(savedConnectionsProvider);
    final linked = controller.canSwitchLiveTo(
      condition == StudyCondition.selfAgent
          ? StudyCondition.friendAgent
          : StudyCondition.selfAgent,
    );
    final blocked = busy || switching || recovery;
    final canSwitch =
        AppConfig.researcherDemo && (!state.connected || linked) && !blocked;
    final status = expired
        ? context.l10n.msgSignInRequired
        : recovery
        ? context.l10n.msgUnavailable
        : state.connected
        ? context.l10n.msgConnected
        : context.l10n.msgDemo;
    final conversationTitle =
        task?.title ??
        (archived
            ? context.l10n.archivedTaskConversation_426aa2
            : context.l10n.generalConversation_90962d);
    return LayoutBuilder(
      builder: (context, size) {
        final compact =
            size.maxHeight < 300 ||
            MediaQuery.textScalerOf(context).scale(14) > 24;
        Widget contextRow() => Material(
          color: Colors.transparent,
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16),
            title: Text(
              conversationTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: compact ? null : Text(context.l10n.taskContext_0eecee),
            trailing: const Icon(Icons.expand_more),
            enabled: !busy && !switching,
            onTap: () => conversations(state, selected),
          ),
        );
        final tiny = size.maxHeight < 210;
        final header = Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              if (!compact)
                SizedBox(
                  width: 36,
                  height: 36,
                  child: FittedBox(child: AgentAvatar(condition)),
                ),
              if (!compact) const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr(condition.label),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (!compact)
                      Text(
                        status,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                  ],
                ),
              ),
              if (compact)
                IconButton(
                  tooltip: context.l10n.switchTo_ce5010(
                    context.tr(
                      condition == StudyCondition.selfAgent
                          ? StudyCondition.friendAgent.label
                          : StudyCondition.selfAgent.label,
                    ),
                  ),
                  onPressed: canSwitch
                      ? () => perform(
                          context,
                          () => switchAgent(
                            condition == StudyCondition.selfAgent
                                ? StudyCondition.friendAgent
                                : StudyCondition.selfAgent,
                          ),
                        )
                      : null,
                  icon: const Icon(Icons.swap_horiz),
                ),
              if (recovery)
                IconButton(
                  tooltip: context.l10n.reconnectAccount,
                  onPressed: busy || switching ? null : signInAgain,
                  icon: const Icon(Icons.login),
                ),
              IconButton(
                tooltip: context.l10n.uxChatInfo,
                onPressed: () => information(state, linked),
                icon: Icon(
                  state.error == null ? Icons.more_vert : Icons.info_outline,
                  color: state.error == null
                      ? null
                      : Theme.of(context).colorScheme.error,
                ),
              ),
            ],
          ),
        );
        return Column(
          children: [
            if (!tiny) header,
            if (!compact)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Wrap(
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
                            ? (_) => perform(context, () => switchAgent(agent))
                            : null,
                      ),
                  ],
                ),
              ),
            if (!compact) contextRow(),
            Expanded(
              child: NotificationListener<UserScrollNotification>(
                onNotification: (notification) {
                  if (scroll.hasClients) {
                    followReply = scroll.position.extentAfter < 100;
                    if (followReply && newReply) {
                      setState(() => newReply = false);
                    }
                  }
                  return false;
                },
                child: ListView(
                  key: PageStorageKey(key),
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  children: [
                    if (tiny) header,
                    if (compact) contextRow(),
                    if (archived)
                      Text(
                        context.l10n.thisTaskWasDeletedItsConversation_35be64,
                      ),
                    if (messages.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: EmptyPanel(
                          context.l10n.msgStart,
                          context.l10n.msgStartHint,
                        ),
                      ),
                    for (var i = 0; i < messages.length; i++) ...[
                      if (i == 0 ||
                          !_sameDay(messages[i - 1].at, messages[i].at))
                        MessageDay(messages[i].at),
                      MessageBubble(
                        messages[i],
                        key: ValueKey('message-${messages[i].id}'),
                        acknowledgement: messages[i].user
                            ? messages[i].delivery == 'sent'
                                  ? state.connected
                                        ? context.l10n.uxServerSaved
                                        : context.l10n.uxLocalSaved
                                  : messages[i].delivery == 'sending'
                                  ? state.chatPhase == 'waiting'
                                        ? context.l10n.uxWaiting
                                        : context.l10n.uxSending
                                  : null
                            : null,
                      ),
                      if (messages[i].user && messages[i].delivery == 'failed')
                        Align(
                          alignment: Alignment.centerRight,
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                context.l10n.msgCouldNotSend,
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                ),
                              ),
                              if (failedId == messages[i].id &&
                                  {
                                    'capacity',
                                    'quota',
                                    'provider_access',
                                  }.contains(failure?.code))
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(failureText(failure)),
                                ),
                              TextButton(
                                onPressed: blocked || archived
                                    ? null
                                    : () => send(
                                        messages[i].text,
                                        task,
                                        retry: true,
                                        messageId: messages[i].id,
                                      ),
                                child: Text(context.l10n.tryAgain_042c86),
                              ),
                              TextButton(
                                onPressed: blocked || archived
                                    ? null
                                    : () => messageOption('edit', messages[i]),
                                child: Text(context.l10n.editMessage_96116a),
                              ),
                              PopupMenuButton<String>(
                                tooltip: context.l10n.msgMessageOptions,
                                onSelected: (choice) =>
                                    messageOption(choice, messages[i]),
                                itemBuilder: (_) => [
                                  PopupMenuItem(
                                    value: 'details',
                                    child: Text(context.l10n.msgDetails),
                                  ),
                                  PopupMenuItem(
                                    value: 'cancel',
                                    enabled: !busy && !switching,
                                    child: Text(
                                      context.l10n.cancelRetry_09ba40,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      if (messages[i].delivery == 'cancelled')
                        Text(
                          context.l10n.msgCancelled,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                    if (failure != null && failedId == null && !recovery)
                      Text(
                        failureText(failure),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    if (state.error != null && !recovery)
                      Text(context.tr(state.error!)),
                    if (!blocked)
                      AgentTaskActions(
                        key: ValueKey(('suggestion', key)),
                        task: task,
                        request: messages.where((m) => m.user).lastOrNull,
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        ActionChip(
                          label: Text(context.l10n.chooseAFocusSession_41945f),
                          onPressed:
                              blocked ||
                                  task == null ||
                                  task.done ||
                                  task.paused
                              ? null
                              : () => showFocusSheet(context, ref, task),
                        ),
                        if (task != null)
                          ActionChip(
                            label: Text(context.l10n.breakItDown_5798bd),
                            onPressed: blocked || task.done || task.paused
                                ? null
                                : () => context.push(
                                    '/refine/${Uri.encodeComponent(task.id)}',
                                  ),
                          )
                        else
                          ActionChip(
                            label: Text(context.l10n.reflectOnMyGoal_6d1d30),
                            onPressed: blocked || archived
                                ? null
                                : () => send(
                                    context.l10n.helpMeReflectOnMyGoal_d4b855,
                                    task,
                                  ),
                          ),
                      ],
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => more(task, blocked, archived),
                        child: Text(context.l10n.uxMoreActions),
                      ),
                    ),
                    if (recovery)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expired
                                ? context.l10n.sessionExpiredMessage
                                : context.l10n.connectionRestoreFailed,
                          ),
                          Wrap(
                            children: [
                              if (!expired)
                                TextButton(
                                  onPressed: busy || switching
                                      ? null
                                      : retryConnection,
                                  child: Text(context.l10n.retryConnection),
                                ),
                              TextButton(
                                onPressed: busy || switching
                                    ? null
                                    : signInAgain,
                                child: Text(context.l10n.reconnectAccount),
                              ),
                            ],
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            if (newReply)
              TextButton.icon(
                onPressed: () {
                  followReply = true;
                  latest(force: true);
                },
                icon: const Icon(Icons.arrow_downward),
                label: Text(context.l10n.uxNewReply),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('chat-composer'),
                      controller: input,
                      enabled: !recovery && !switching && !archived,
                      minLines: 1,
                      maxLines: tiny
                          ? 1
                          : compact
                          ? 2
                          : 4,
                      maxLength: 2000,
                      decoration: InputDecoration(
                        hintMaxLines: 1,
                        hintText: context.l10n.messageYour_e972d5(
                          context.tr(condition.label),
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: Theme.of(context).colorScheme.surface,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                      ),
                      onChanged: (value) {
                        draft(value);
                        setState(() {});
                      },
                      textInputAction: TextInputAction.newline,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: context.l10n.sendMessage_c70a89,
                    constraints: const BoxConstraints(
                      minWidth: 48,
                      minHeight: 48,
                    ),
                    onPressed: blocked || archived || input.text.trim().isEmpty
                        ? null
                        : () => send(input.text, task),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  bool _sameDay(DateTime a, DateTime b) {
    final left = a.toLocal(), right = b.toLocal();
    return left.year == right.year &&
        left.month == right.month &&
        left.day == right.day;
  }
}
