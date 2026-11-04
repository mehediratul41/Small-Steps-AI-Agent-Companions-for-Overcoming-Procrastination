import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'models.dart';

abstract interface class ConnectionStorage {
  Future<String?> read();
  Future<void> write(String value);
  Future<void> clear();
}

/// Used in tests and browser previews; never persists a token in browser storage.
class MemoryConnectionStorage implements ConnectionStorage {
  String? value;
  @override
  Future<String?> read() async => value;
  @override
  Future<void> write(String value) async {
    this.value = value;
  }

  @override
  Future<void> clear() async {
    value = null;
  }
}

class SecureConnectionStorage implements ConnectionStorage {
  static const key = 'small_steps.synthetic_logins.v1';
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  @override
  Future<String?> read() => storage.read(key: key);
  @override
  Future<void> write(String value) => storage.write(key: key, value: value);
  @override
  Future<void> clear() => storage.delete(key: key);
}

class SavedConnection {
  final String url, token, id;
  final StudyCondition condition;
  const SavedConnection(this.url, this.token, this.id, this.condition);
  Map<String, dynamic> toJson() => {
    'url': url,
    'token': token,
    'id': id,
    'condition': condition.name,
  };
  factory SavedConnection.fromJson(Map<String, dynamic> json) =>
      SavedConnection(
        json['url'] as String,
        json['token'] as String,
        json['id'] as String,
        StudyCondition.values.byName(json['condition'] as String),
      );
}

final connectionStorageProvider = Provider<ConnectionStorage>(
  (ref) => MemoryConnectionStorage(),
);
final savedConnectionsProvider =
    NotifierProvider<SavedConnections, Map<StudyCondition, SavedConnection>>(
      SavedConnections.new,
    );

class SavedConnections extends Notifier<Map<StudyCondition, SavedConnection>> {
  StudyCondition? active;
  SavedConnection? userSession;
  @override
  Map<StudyCondition, SavedConnection> build() => {};
  Future<SavedConnection?> load() async {
    final raw = await ref.read(connectionStorageProvider).read();
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final accounts = (data['accounts'] as List).map(
      (e) => SavedConnection.fromJson(Map<String, dynamic>.from(e)),
    );
    state = {
      for (final a in accounts)
        if (a.id.startsWith('DEV-') && a.condition.hasAgent) a.condition: a,
    };
    active = data['active'] == null
        ? null
        : StudyCondition.values.byName(data['active']);
    userSession = data['userSession'] == null
        ? null
        : SavedConnection.fromJson(
            Map<String, dynamic>.from(data['userSession']),
          );
    return userSession ?? state[active];
  }

  Future<void> remember(SavedConnection account) async {
    if (!account.id.startsWith('DEV-') || !account.condition.hasAgent) {
      throw StateError('Only synthetic DEV- agent accounts can be remembered.');
    }
    userSession = null;
    final next = {...state, account.condition: account};
    await _save(next, account.condition);
    state = next;
    active = account.condition;
  }

  Future<void> rememberUser(SavedConnection account) async {
    userSession = account;
    await _save(state, null);
    active = null;
  }

  Future<void> deactivate() async {
    userSession = null;
    await _save(state, null);
    active = null;
  }

  Future<void> removeAccount(String url, String id) async {
    final next = Map<StudyCondition, SavedConnection>.from(state)
      ..removeWhere((_, account) => account.url == url && account.id == id);
    if (userSession?.url == url && userSession?.id == id) userSession = null;
    final selected = next.containsKey(active) ? active : null;
    await _save(next, selected);
    state = next;
    active = selected;
  }

  Future<void> forget() async {
    await ref.read(connectionStorageProvider).clear();
    active = null;
    userSession = null;
    state = {};
  }

  Future<void> _save(
    Map<StudyCondition, SavedConnection> accounts,
    StudyCondition? selected,
  ) => ref
      .read(connectionStorageProvider)
      .write(
        jsonEncode({
          'accounts': accounts.values.map((e) => e.toJson()).toList(),
          'active': selected?.name,
          'userSession': userSession?.toJson(),
        }),
      );
}
