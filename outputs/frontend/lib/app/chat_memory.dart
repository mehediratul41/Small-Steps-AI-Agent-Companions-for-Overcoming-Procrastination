import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state.dart';

typedef ChatKey = (String, String, String);
String chatOwner(AppState state) => jsonEncode([
  state.connected ? 'account' : 'demo',
  state.backendUrl,
  state.backendId,
]);
ChatKey chatKey(AppState state, String conversation) =>
    (chatOwner(state), state.condition.name, conversation);

class ChatMemoryState {
  final Map<ChatKey, String> drafts;
  final Map<ChatKey, double> offsets;
  const ChatMemoryState({this.drafts = const {}, this.offsets = const {}});
}

/// RAM only: no tokens or new disk database. Explicit disconnect clears the
/// departing account; restricted DEV switches retain separately keyed entries.
class ChatMemory extends Notifier<ChatMemoryState> {
  @override
  ChatMemoryState build() {
    ref.listen(appProvider, (previous, next) {
      if (previous != null &&
          previous.connected &&
          !next.connected &&
          !ref.read(appProvider.notifier).switchingLiveAccount) {
        clearOwner(chatOwner(previous));
      }
    });
    return const ChatMemoryState();
  }

  void draft(ChatKey key, String text) {
    final next = Map<ChatKey, String>.of(state.drafts);
    if (text.isEmpty) {
      next.remove(key);
    } else {
      next[key] = text;
    }
    state = ChatMemoryState(drafts: next, offsets: state.offsets);
  }

  void offset(ChatKey key, double value) {
    state = ChatMemoryState(
      drafts: state.drafts,
      offsets: {...state.offsets, key: value},
    );
  }

  void clearOwner(String owner) {
    state = ChatMemoryState(
      drafts: {...state.drafts}..removeWhere((key, _) => key.$1 == owner),
      offsets: {...state.offsets}..removeWhere((key, _) => key.$1 == owner),
    );
  }
}

final chatMemoryProvider = NotifierProvider<ChatMemory, ChatMemoryState>(
  ChatMemory.new,
);
