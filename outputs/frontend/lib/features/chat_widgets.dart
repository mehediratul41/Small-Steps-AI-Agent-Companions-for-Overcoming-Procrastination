import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import '../app/state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../l10n/strings.dart';

class ConversationPicker extends StatefulWidget {
  final AppState snapshot;
  final String selected;
  const ConversationPicker({
    super.key,
    required this.snapshot,
    required this.selected,
  });
  @override
  State<ConversationPicker> createState() => _ConversationPickerState();
}

class _ConversationPickerState extends State<ConversationPicker> {
  String query = '';
  @override
  Widget build(BuildContext context) {
    final state = widget.snapshot;
    final messages =
        state.messages; // already bound to the active account/agent
    final ids = <String>{
      '__general__',
      ...state.tasks.map((t) => t.id),
      ...messages.map((m) => m.taskId ?? '__general__'),
    }.toList();
    List<ChatMessage> history(String id) =>
        messages.where((m) => (m.taskId ?? '__general__') == id).toList();
    String title(String id) => id == '__general__'
        ? context.l10n.generalConversation_90962d
        : state.tasks.where((t) => t.id == id).firstOrNull?.title ??
              context.l10n.archivedTaskConversation_426aa2;
    ids.sort((a, b) {
      if (a == '__general__') return -1;
      if (b == '__general__') return 1;
      final left = history(a).lastOrNull?.at;
      final right = history(b).lastOrNull?.at;
      if (left == null && right == null) return title(a).compareTo(title(b));
      if (left == null) return 1;
      if (right == null) return -1;
      return right.compareTo(left);
    });
    final shown = ids
        .where(
          (id) =>
              query.isEmpty ||
              title(id).toLowerCase().contains(query) ||
              history(id).any((m) => m.text.toLowerCase().contains(query)),
        )
        .toList();
    final available =
        MediaQuery.sizeOf(context).height -
        MediaQuery.viewInsetsOf(context).bottom -
        MediaQuery.paddingOf(context).top -
        24;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        child: SizedBox(
          height: math.min(600, math.max(100, available * .9)),
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                context.l10n.msgConversations,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('conversation-search'),
                decoration: InputDecoration(
                  labelText: context.l10n.msgSearch,
                  prefixIcon: const Icon(Icons.search),
                ),
                onChanged: (value) =>
                    setState(() => query = value.trim().toLowerCase()),
              ),
              const SizedBox(height: 8),
              Text(
                context.l10n.msgSearchHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              for (final id in shown)
                ListTile(
                  key: ValueKey('conversation-$id'),
                  selected: widget.selected == id,
                  leading: Icon(
                    id == '__general__'
                        ? Icons.chat_bubble_outline
                        : Icons.task_alt,
                  ),
                  title: Text(
                    title(id),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    history(id).lastOrNull?.text ?? context.l10n.msgNoMessages,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: widget.selected == id
                      ? const Icon(Icons.check)
                      : history(id).isEmpty
                      ? null
                      : Text(
                          DateFormat.MMMd(
                            context.l10n.localeName,
                          ).format(history(id).last.at.toLocal()),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                  onTap: () => Navigator.pop(context, id),
                ),
              if (shown.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(context.l10n.msgNoResults),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MessageDay extends StatelessWidget {
  final DateTime at;
  const MessageDay(this.at, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 16),
    child: Center(
      child: Text(
        DateFormat.yMMMd(context.l10n.localeName).format(at.toLocal()),
        style: Theme.of(context).textTheme.bodySmall,
      ),
    ),
  );
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final String? acknowledgement;
  const MessageBubble(this.message, {super.key, this.acknowledgement});

  Future<void> copy(BuildContext context) async {
    await Clipboard.setData(ClipboardData(text: message.text));
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.msgCopied)));
    }
  }

  void menu(BuildContext context) => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: ListTile(
        leading: const Icon(Icons.copy),
        title: Text(context.l10n.msgCopy),
        onTap: () {
          Navigator.pop(sheet);
          copy(context);
        },
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final foreground = message.user
        ? Colors.white
        : Theme.of(context).colorScheme.onSurface;
    return Align(
      alignment: message.user ? Alignment.centerRight : Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: message.user ? .84 : .92,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Semantics(
              label: message.user
                  ? context.l10n.you_905cb3
                  : context.l10n.agent_5ce2e6,
              customSemanticsActions: {
                CustomSemanticsAction(label: context.l10n.msgCopy): () =>
                    copy(context),
              },
              child: GestureDetector(
                onLongPress: () => menu(context),
                onSecondaryTap: () => menu(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: message.user
                        ? AppTokens.teal
                        : Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.text,
                        style: TextStyle(
                          color: foreground,
                          fontSize: 14,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        [
                          DateFormat.Hm(
                            context.l10n.localeName,
                          ).format(message.at.toLocal()),
                          ?acknowledgement,
                        ].join(' · '),
                        style: TextStyle(
                          color: foreground,
                          fontSize: 11,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
