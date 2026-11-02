import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../data/saved_connections.dart';
import 'config.dart';
import 'language.dart';

final preferencesProvider = Provider<SharedPreferences>(
  (ref) => throw StateError('Preferences must be initialized'),
);
final repositoryProvider = Provider<ResearchRepository>(
  (ref) => MockResearchRepository(),
);
final apiFactoryProvider =
    Provider<ApiResearchRepository Function(String, String)>(
      (ref) =>
          (url, token) => ApiResearchRepository(url, token: token),
    );
final appProvider = NotifierProvider<AppController, AppState>(
  AppController.new,
);

class AppState {
  final bool loaded, consent;
  final String? backendId, backendUrl;
  bool get connected => backendId != null;
  final StudyCondition condition;
  final List<Task> tasks;
  final Map<String, List<ChatMessage>> chats;
  final List<BehaviorEvent> events;
  final List<CheckIn> checkIns;
  final SupportProfile profile;
  final FocusSession? focus;
  final ThemeMode theme;
  final String? burden, error;
  final String? chatTaskId, todayTaskId;
  const AppState({
    this.backendId,
    this.backendUrl,
    this.loaded = false,
    this.consent = false,
    this.condition = StudyCondition.selfAgent,
    this.tasks = const [],
    this.chats = const {},
    this.events = const [],
    this.checkIns = const [],
    this.profile = const SupportProfile(),
    this.focus,
    this.theme = ThemeMode.system,
    this.burden,
    this.error,
    this.chatTaskId,
    this.todayTaskId,
  });
  AppState copyWith({
    String? backendId,
    String? backendUrl,
    bool? loaded,
    bool? consent,
    StudyCondition? condition,
    List<Task>? tasks,
    Map<String, List<ChatMessage>>? chats,
    List<BehaviorEvent>? events,
    List<CheckIn>? checkIns,
    SupportProfile? profile,
    FocusSession? focus,
    bool clearFocus = false,
    ThemeMode? theme,
    String? burden,
    String? error,
    String? chatTaskId,
    String? todayTaskId,
  }) => AppState(
    backendId: backendId ?? this.backendId,
    backendUrl: backendUrl ?? this.backendUrl,
    loaded: loaded ?? this.loaded,
    consent: consent ?? this.consent,
    condition: condition ?? this.condition,
    tasks: tasks ?? this.tasks,
    chats: chats ?? this.chats,
    events: events ?? this.events,
    checkIns: checkIns ?? this.checkIns,
    profile: profile ?? this.profile,
    focus: clearFocus ? null : focus ?? this.focus,
    theme: theme ?? this.theme,
    burden: burden ?? this.burden,
    error: error,
    chatTaskId: chatTaskId ?? this.chatTaskId,
    todayTaskId: todayTaskId ?? this.todayTaskId,
  );
  List<ChatMessage> get messages => chats[condition.name] ?? [];
  Map<String, dynamic> toJson() => {
    'version': 2,
    'consent': consent,
    'condition': condition.name,
    'tasks': tasks.map((t) => t.toJson()).toList(),
    'chats': chats.map(
      (k, v) => MapEntry(k, v.map((m) => m.toJson()).toList()),
    ),
    'events': events.map((e) => e.toJson()).toList(),
    'checkIns': checkIns.map((c) => c.toJson()).toList(),
    'profile': profile.toJson(),
    'focus': focus?.toJson(),
    'theme': theme.name,
    'burden': burden,
    'chatTaskId': chatTaskId,
    'todayTaskId': todayTaskId,
  };
  factory AppState.fromJson(Map<String, dynamic> j) => AppState(
    loaded: true,
    consent: j['consent'] ?? false,
    condition: StudyCondition.values.byName(j['condition']),
    tasks: (j['tasks'] as List)
        .map((t) => Task.fromJson(Map<String, dynamic>.from(t)))
        .toList(),
    chats: (j['chats'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(
        k,
        (v as List).map((m) {
          final message = ChatMessage.fromJson(Map<String, dynamic>.from(m));
          return message.delivery == 'sending'
              ? message.withDelivery('failed')
              : message;
        }).toList(),
      ),
    ),
    events: (j['events'] as List? ?? [])
        .map((e) => BehaviorEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList(),
    checkIns: (j['checkIns'] as List? ?? [])
        .map((c) => CheckIn.fromJson(Map<String, dynamic>.from(c)))
        .toList(),
    profile: SupportProfile.fromJson(
      Map<String, dynamic>.from(j['profile'] ?? {}),
    ),
    focus: j['focus'] == null
        ? null
        : FocusSession.fromJson(Map<String, dynamic>.from(j['focus'])),
    theme: ThemeMode.values.byName(j['theme'] ?? 'system'),
    burden: j['burden'],
    chatTaskId: j['chatTaskId'],
    todayTaskId: j['todayTaskId'] as String?,
  );
}

class CompletionUndo {
  final String token, taskId;
  final int version;
  final StudyCondition condition;
  final String? backendId, backendUrl;
  const CompletionUndo._(
    this.token,
    this.taskId,
    this.version,
    this.condition,
    this.backendId,
    this.backendUrl,
  );
}

class AppController extends Notifier<AppState> {
  CompletionUndo? _completionUndo;
  static const storageKey = 'small_steps.demo.v1';
  ApiResearchRepository? _api;
  AppState? _localDemo;
  String? _backendCacheKey;
  final Set<String> _acknowledgedEvents = {};
  bool _restoredLogin = false,
      _restoreFailed = false,
      _switchingAccount = false;

  Future<void> forgetSavedLogins() async {
    if (state.connected || _connectionBusy || _switchingAccount) {
      throw const AppFailure('Disconnect before forgetting saved logins.');
    }
    await ref.read(savedConnectionsProvider.notifier).forget();
    _restoreFailed = false;
    state = state.copyWith();
  }

  bool canSwitchLiveTo(StudyCondition target) {
    final accounts = ref.read(savedConnectionsProvider);
    return AppConfig.researcherDemo &&
        state.connected &&
        state.backendId?.startsWith('DEV-') == true &&
        target.hasAgent &&
        accounts[state.condition]?.id == state.backendId &&
        accounts[state.condition]?.url == state.backendUrl &&
        accounts[target]?.url == state.backendUrl;
  }

  bool get switchingLiveAccount => _switchingAccount;

  Future<void> switchLiveAgent(StudyCondition target) async {
    if (!canSwitchLiveTo(target) || _switchingAccount) {
      throw const AppFailure(
        'Connect and remember both synthetic agent accounts first.',
      );
    }
    if (target == state.condition) return;
    if (_connectionBusy ||
        _chatBusy ||
        _refinementRequests > 0 ||
        _savingTasks.isNotEmpty ||
        _completing.isNotEmpty ||
        state.focus != null) {
      throw const AppFailure(
        'Finish the current session or request before switching accounts.',
      );
    }
    final accounts = ref.read(savedConnectionsProvider);
    final previous = accounts[state.condition]!;
    final next = accounts[target]!;
    _switchingAccount = true;
    try {
      // Validate assignment before leaving the current account.
      final probe = ref.read(apiFactoryProvider)(next.url, next.token);
      try {
        final participant = await probe.participant();
        if (participant.id != next.id ||
            participant.condition != target ||
            probe.assignment['mode'] != 'development') {
          throw const AppFailure(
            'Saved account assignment does not match. Reconnect it.',
          );
        }
      } finally {
        probe.close();
      }
      await disconnectBackend();
      try {
        await connectBackend(
          next.url,
          next.token,
          remember: true,
          expectedCondition: target,
        );
      } catch (_) {
        try {
          await connectBackend(
            previous.url,
            previous.token,
            remember: true,
            expectedCondition: previous.condition,
          );
        } catch (_) {
          _restoreFailed = true;
        }
        rethrow;
      }
    } finally {
      _switchingAccount = false;
    }
  }

  Future<void> connectBackend(
    String url,
    String token, {
    ApiResearchRepository? client,
    bool remember = false,
    bool restoring = false,
    StudyCondition? expectedCondition,
    String? expectedId,
  }) async {
    if (!AppConfig.researcherDemo) {
      throw const AppFailure('Participant enrollment is not enabled.');
    }
    if (_connectionBusy ||
        _refinementRequests > 0 ||
        _api != null ||
        _chatBusy ||
        (_savingTasks.isNotEmpty || _completing.isNotEmpty) ||
        state.focus != null ||
        state.messages.any((m) => m.delivery == 'sending')) {
      throw const AppFailure(
        'Finish the current session or request before connecting.',
      );
    }
    final uri = Uri.tryParse(url.trim());
    if (uri == null ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.userInfo.isNotEmpty ||
        !['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty ||
        (uri.scheme == 'http' &&
            !['localhost', '127.0.0.1', '10.0.2.2'].contains(uri.host))) {
      throw const AppFailure(
        'Use a localhost/emulator HTTP address or an HTTPS backend URL.',
      );
    }
    if (token.trim().isEmpty) {
      throw const AppFailure('Enter a development participant token.');
    }
    final api =
        client ??
        ref.read(apiFactoryProvider)(
          url.trim().replaceFirst(RegExp(r'/+$'), ''),
          token.trim(),
        );
    _connectionBusy = true;
    _completionUndo = null;
    try {
      await api.participant();
      if (expectedId != null && api.assignment['id'] != expectedId) {
        throw const AppFailure(
          'Saved account identity does not match. Reconnect it.',
        );
      }
      if (expectedCondition != null &&
          api.assignment['condition'] != expectedCondition.name) {
        throw const AppFailure(
          'Saved account assignment does not match. Reconnect it.',
        );
      }
      if (api.assignment['mode'] != 'development') {
        throw const AppFailure(
          'This connection supports synthetic development accounts only.',
        );
      }
      await _writes;
      _localDemo = state;
      _api = api;
      _backendCacheKey =
          'small_steps.backend.v1.${Uri.encodeComponent(url.trim())}.${api.assignment['id']}';
      state = AppState(
        loaded: true,
        backendId: api.assignment['id'],
        backendUrl: url.trim(),
        theme: state.theme,
      );
      await _loadBackend();
      if (remember &&
          state.condition.hasAgent &&
          state.backendId!.startsWith('DEV-')) {
        await ref
            .read(savedConnectionsProvider.notifier)
            .remember(
              SavedConnection(
                state.backendUrl!,
                token.trim(),
                state.backendId!,
                state.condition,
              ),
            );
      } else if (!restoring) {
        await ref.read(savedConnectionsProvider.notifier).deactivate();
      }
      _restoreFailed = false;
    } catch (_) {
      _api = null;
      api.close();
      if (_localDemo != null) state = _localDemo!;
      _localDemo = null;
      rethrow;
    } finally {
      _connectionBusy = false;
    }
  }

  Future<void> disconnectBackend() async {
    _completionUndo = null;
    if (_connectionBusy ||
        _refinementRequests > 0 ||
        _chatBusy ||
        (_savingTasks.isNotEmpty || _completing.isNotEmpty)) {
      throw const AppFailure(
        'Finish the current request before disconnecting.',
      );
    }
    final api = _api;
    if (api == null) return;
    if (api.activeRequests > 0 ||
        state.focus != null ||
        state.messages.any((m) => m.delivery == 'sending')) {
      throw const AppFailure(
        'Finish or end the current session/request before disconnecting.',
      );
    }
    _connectionBusy = true;
    try {
      await _writes;
      await ref.read(savedConnectionsProvider.notifier).deactivate();
      _api = null;
      _restoreFailed = false;
      api.close();
      state = _localDemo ?? const AppState();
      _localDemo = null;
      _backendCacheKey = null;
      _acknowledgedEvents.clear();
      if (!state.loaded) await initialize();
    } finally {
      _connectionBusy = false;
    }
  }

  Future<Map<String, dynamic>> exportServerData() async {
    _assertSessionReady();
    final api = _api;
    if (api == null) {
      throw const AppFailure('Connect to the development backend first.');
    }
    await _persistBackend();
    final exported = await api.exportData();
    if (_api != api) {
      throw const AppFailure('Account changed during export. Try again.');
    }
    return {
      ...exported,
      'devicePendingReports': _backendCache(),
      'warning':
          'Contains raw development text. Pending device reports are not verified server events.',
    };
  }

  Future<void> eraseDevelopmentData() async {
    _assertSessionReady();
    final api = _api;
    if (api == null) {
      throw const AppFailure('No development account is connected.');
    }
    if (api.activeRequests > 0 ||
        _chatBusy ||
        (_savingTasks.isNotEmpty || _completing.isNotEmpty) ||
        _refinementRequests > 0 ||
        state.focus != null) {
      throw const AppFailure(
        'Finish the current session or request before erasing data.',
      );
    }
    _connectionBusy = true;
    try {
      await _writes;
      await api.eraseDevelopmentData();
      var cleared = true;
      try {
        await ref
            .read(savedConnectionsProvider.notifier)
            .removeAccount(state.backendUrl!, state.backendId!);
      } catch (_) {
        cleared = false;
      }
      final prefs = ref.read(preferencesProvider);
      for (final key in [
        _backendCacheKey!,
        'small_steps.demo.reminders.v1.${Uri.encodeComponent(state.backendUrl ?? '')}/${Uri.encodeComponent(state.backendId!)}',
      ]) {
        try {
          cleared = await prefs.remove(key) && cleared;
        } on Object {
          cleared = false;
        }
      }
      _api = null;
      api.close();
      state = (_localDemo ?? const AppState(loaded: true)).copyWith(
        error: cleared
            ? null
            : 'Server data was erased, but device cleanup failed. Clear this app’s storage in phone settings.',
      );
      _localDemo = null;
      _backendCacheKey = null;
      _acknowledgedEvents.clear();
    } finally {
      _connectionBusy = false;
    }
  }

  Future<void> forgetSavedDevelopmentAccounts() async {
    _assertSessionReady();
    if (state.connected) {
      throw const AppFailure(
        'Disconnect before clearing saved development data.',
      );
    }
    await _writes;
    await ref.read(savedConnectionsProvider.notifier).forget();
    _restoreFailed = false;
    final prefs = ref.read(preferencesProvider);
    for (final key in prefs.getKeys().where(
      (key) =>
          key.startsWith('small_steps.backend.v1.') ||
          key.startsWith('small_steps.demo.reminders.v1.'),
    )) {
      if (!await prefs.remove(key)) {
        throw const AppFailure(
          'Some device data could not be cleared. Try again or clear app storage.',
        );
      }
    }
  }

  Future<void> _loadBackend() async {
    final api = _api!;
    final participant = await api.participant();
    final consent = api.assignment['onboarded'] == true;
    if (!consent) {
      state = AppState(
        loaded: true,
        condition: participant.condition,
        backendId: participant.id,
        backendUrl: state.backendUrl,
        theme: state.theme,
      );
      return;
    }
    final data = await api.snapshot();
    if (data['participant']['id'] != participant.id ||
        data['participant']['condition'] != participant.condition.name) {
      throw const AppFailure(
        'The server assignment changed. Disconnect and sign in again.',
      );
    }
    final tasks = (data['tasks'] as List)
        .map((t) => api.readTask(Map<String, dynamic>.from(t)))
        .toList();
    final events = (data['events'] as List)
        .map((e) => BehaviorEvent.fromJson(Map<String, dynamic>.from(e)))
        .toList();
    final messages = (data['messages'] as List)
        .map((m) => ChatMessage.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    _acknowledgedEvents
      ..clear()
      ..addAll(events.map((e) => e.id));
    final raw = ref.read(preferencesProvider).getString(_backendCacheKey!);
    FocusSession? focus;
    String? todayTaskId;
    if (raw != null) {
      final cache = Map<String, dynamic>.from(jsonDecode(raw));
      final selected = cache['todayTaskId'];
      if (selected is String &&
          tasks.any((t) => t.id == selected && !t.done && !t.paused)) {
        todayTaskId = selected;
      }
      for (final item in cache['pendingEvents'] as List? ?? []) {
        final e = BehaviorEvent.fromJson(Map<String, dynamic>.from(item));
        if (e.condition == participant.condition.name &&
            !events.any((v) => v.id == e.id)) {
          events.add(e);
        }
      }
      for (final item in cache['pendingMessages'] as List? ?? []) {
        final m = ChatMessage.fromJson(Map<String, dynamic>.from(item));
        if (!messages.any((v) => v.id == m.id)) {
          messages.add(m.withDelivery('failed'));
        }
      }
      if (cache['focus'] != null) {
        final saved = FocusSession.fromJson(
          Map<String, dynamic>.from(cache['focus']),
        );
        if (saved.condition == participant.condition.name &&
            tasks.any((t) => t.id == saved.taskId && !t.done && !t.paused)) {
          focus = saved;
        }
      }
    }
    state = AppState(
      loaded: true,
      consent: true,
      backendId: participant.id,
      backendUrl: state.backendUrl,
      condition: participant.condition,
      tasks: tasks,
      events: events,
      chats: {participant.condition.name: messages},
      focus: focus,
      todayTaskId: todayTaskId,
      theme: state.theme,
      profile: SupportProfile.fromJson(
        Map<String, dynamic>.from(data['profile']),
      ),
      checkIns: (data['checkIns'] as List).map((c) {
        final json = Map<String, dynamic>.from(c);
        json['phase'] =
            const {
              'baseline': 'Baseline demo',
              'daily': 'Daily',
              'before': 'Before session',
              'during': 'During session',
              'after': 'After session',
            }[json['phase']] ??
            json['phase'];
        return CheckIn.fromJson(json);
      }).toList(),
    );
    await _persistBackend();
  }

  Map<String, dynamic> _backendCache() => {
    'todayTaskId': state.todayTaskId,
    'focus': state.focus?.toJson(),
    'pendingEvents': state.events
        .where((e) => !_acknowledgedEvents.contains(e.id))
        .map((e) => e.toJson())
        .toList(),
    'pendingMessages': state.messages
        .where((m) => m.user && ['sending', 'failed'].contains(m.delivery))
        .map((m) => m.toJson())
        .toList(),
  };

  Future<void> _persistBackend() {
    final api = _api!;
    final key = _backendCacheKey!;
    _writes = _writes.then((_) async {
      try {
        final preferences = ref.read(preferencesProvider);
        if (!await preferences.setString(key, jsonEncode(_backendCache()))) {
          throw const AppFailure(
            'Could not save pending development reports on this device.',
          );
        }
        if (state.consent) {
          final pending = state.events
              .where((e) => !_acknowledgedEvents.contains(e.id))
              .toList();
          for (var i = 0; i < pending.length; i += 20) {
            final batch = pending.skip(i).take(20).toList();
            await api.saveEvents(batch);
            _acknowledgedEvents.addAll(batch.map((e) => e.id));
          }
          if (!await preferences.setString(key, jsonEncode(_backendCache()))) {
            throw const AppFailure(
              'Could not update the local synchronization record.',
            );
          }
        }
      } catch (_) {
        state = state.copyWith(
          error:
              'Some development reports remain on this device. Check the connection, then refresh to retry synchronization.',
        );
      }
    });
    return _writes;
  }

  void _assertSessionReady() {
    if (_restoreFailed) {
      throw const AppFailure(
        'Saved AI connection unavailable. Reconnect the backend before chatting.',
      );
    }
    if (_switchingAccount) {
      throw const AppFailure('Please let the account connection finish first.');
    }
    if (_connectionBusy) {
      throw const AppFailure('Please let the account connection finish first.');
    }
  }

  final Set<String> _completing = {};
  final Set<String> _savingTasks = {};
  bool _chatBusy = false;
  bool _connectionBusy = false;
  bool get sessionTransitioning => _connectionBusy;
  int _refinementRequests = 0;
  Future<void> _writes = Future.value();
  @override
  AppState build() {
    ref.onDispose(() => _api?.close());
    return const AppState();
  }

  ResearchRepository get repository => _api ?? ref.read(repositoryProvider);
  Future<void> initialize() async {
    if (_connectionBusy) return;
    if (_api != null) {
      if (_api!.activeRequests > 0 ||
          _chatBusy ||
          (_savingTasks.isNotEmpty || _completing.isNotEmpty)) {
        state = state.copyWith(
          error: 'Please let the current request finish before refreshing.',
        );
        return;
      }
      try {
        await _persistBackend();
        await _loadBackend();
      } catch (_) {
        state = state.copyWith(
          loaded: true,
          error:
              'Could not refresh the development service. Reconnect if the token has expired.',
        );
      }
      return;
    }
    if (!AppConfig.researcherDemo) {
      state = state.copyWith(
        loaded: true,
        error:
            'Participant mode requires an authenticated study service and approved consent materials. This build does not enroll participants.',
      );
      return;
    }
    try {
      final saved = ref.read(preferencesProvider).getString(storageKey);
      if (saved != null) {
        state = AppState.fromJson(jsonDecode(saved));
      } else {
        state = state.copyWith(loaded: true, tasks: await repository.tasks());
        await persist();
      }
    } catch (_) {
      state = state.copyWith(
        loaded: true,
        error:
            'Could not load demo data. Retry, or reset the local demo in Settings.',
      );
    }
    if (!_restoredLogin && AppConfig.researcherDemo && _api == null) {
      _restoredLogin = true;
      try {
        final saved = await ref.read(savedConnectionsProvider.notifier).load();
        if (saved != null) {
          await connectBackend(
            saved.url,
            saved.token,
            expectedCondition: saved.condition,
            expectedId: saved.id,
            restoring: true,
          );
        }
      } catch (_) {
        _restoreFailed = true;
        state = state.copyWith(
          error:
              'Saved AI connection unavailable. Reconnect the backend before chatting.',
        );
      }
    }
  }

  Future<void> persist() {
    if (_api != null) return _persistBackend();
    if (!AppConfig.researcherDemo) {
      return Future.value();
    }
    final snapshot = jsonEncode(state.toJson());
    _writes = _writes.then((_) async {
      try {
        final ok = await ref
            .read(preferencesProvider)
            .setString(storageKey, snapshot);
        if (!ok) {
          throw const AppFailure('Storage unavailable');
        }
      } catch (_) {
        state = state.copyWith(
          error: 'Changes are visible but could not be saved on this device.',
        );
      }
    });
    return _writes;
  }

  Future<void> acceptConsent() async {
    _assertSessionReady();
    if (_api != null) {
      await _api!.onboard({
        'acknowledged': true,
        'demonstration': true,
        'consent_version': _api!.assignment['consentVersion'],
      });
      await _loadBackend();
      return;
    }
    state = state.copyWith(consent: true);
    await persist();
  }

  Future<void> switchCondition(StudyCondition condition) async {
    if (!AppConfig.researcherDemo || state.connected) {
      throw const AppFailure('Study assignment is controlled by the backend.');
    }
    if (_connectionBusy ||
        _refinementRequests > 0 ||
        _chatBusy ||
        (_savingTasks.isNotEmpty || _completing.isNotEmpty)) {
      throw const AppFailure(
        'Finish the current request before changing demo conditions.',
      );
    }
    _completionUndo = null;
    final previous = state.condition;
    state = state.copyWith(condition: condition);
    if (previous != condition) {
      _record(
        'agent_switched',
        null,
        details: {
          'from': previous.name,
          'to': condition.name,
          'scope': 'researcher_demo',
        },
      );
    }
    await persist();
  }

  Future<void> saveTask(Task task) async {
    _assertSessionReady();
    if (task.startCue.length > 300 ||
        task.startAction.length > 300 ||
        task.futureNote.length > 1000 ||
        task.startCue.trim().isEmpty != task.startAction.trim().isEmpty ||
        ![
          '',
          'unclear',
          'overwhelming',
          'worried',
          'distracted',
          'tired',
        ].contains(task.difficulty)) {
      throw const AppFailure(
        'Invalid start plan. Enter a situation and an action together.',
      );
    }
    if (_connectionBusy) {
      throw const AppFailure('Please let the account connection finish first.');
    }
    if (!_savingTasks.add(task.id)) {
      throw const AppFailure(
        'This task is being saved. Please wait for it to finish.',
      );
    }
    try {
      final previous = state.tasks.where((t) => t.id == task.id).firstOrNull;
      final exists = previous != null;
      if (previous != null && task.version != previous.version) {
        throw const AppFailure(
          'This task changed. Refresh before saving your edits.',
        );
      }
      final revision = task.copyWith(version: (previous?.version ?? 0) + 1);
      final saved = exists
          ? await repository.updateTask(revision)
          : await repository.createTask(revision);
      state = state.copyWith(
        tasks: exists
            ? state.tasks.map((t) => t.id == saved.id ? saved : t).toList()
            : [...state.tasks, saved],
      );
      _record(
        exists ? 'task_updated' : 'task_created',
        saved,
        details: {'before': previous?.toJson(), 'after': saved.toJson()},
      );
      await persist();
    } finally {
      _savingTasks.remove(task.id);
    }
  }

  int _serial = 0;
  String _id() => '${DateTime.now().microsecondsSinceEpoch}_${_serial++}';
  void _record(
    String kind,
    Task? task, {
    DateTime? at,
    int? seconds,
    String? reflection,
    String? condition,
    Map<String, dynamic> details = const {},
  }) {
    final now = at ?? DateTime.now();
    state = state.copyWith(
      events: [
        ...state.events,
        BehaviorEvent(
          kind,
          task?.id ?? '',
          now,
          eventId: _id(),
          condition: condition ?? state.condition.name,
          offsetMinutes: now.timeZoneOffset.inMinutes,
          taskVersion: task?.version,
          seconds: seconds,
          reflection: reflection,
          details: {
            'uiLanguage': ref.read(languageProvider).languageCode,
            ...details,
          },
        ),
      ],
    );
  }

  Task _task(String id) => state.tasks.firstWhere((t) => t.id == id);
  Future<void> startTask(String id, {DateTime? at}) async {
    _assertSessionReady();
    final task = _task(id);
    if (task.done) {
      throw const AppFailure('Reopen this task before starting it.');
    }
    if (task.firstStartedAt != null && !task.paused) return;
    final now = at ?? DateTime.now();
    await saveTask(
      task.copyWith(firstStartedAt: task.firstStartedAt ?? now, paused: false),
    );
    _record(
      task.firstStartedAt == null ? 'task_started' : 'task_resumed',
      _task(id),
      at: now,
      details: {
        'source': 'explicit_self_report',
        'plannedStart': task.plannedStart?.toIso8601String(),
      },
    );
    await persist();
  }

  Future<void> recoverTask(
    String id,
    String action, {
    String? reason,
    DateTime? plannedStart,
  }) async {
    _assertSessionReady();
    final task = _task(id);
    if (task.done) {
      throw const AppFailure('Reopen this task to change its plan.');
    }
    if (!['pause', 'resume', 'reschedule', 'smaller_step'].contains(action)) {
      throw const AppFailure('Unknown recovery action.');
    }
    if (state.focus?.taskId == id) {
      throw const AppFailure(
        'Finish the current focus session before changing this plan.',
      );
    }
    if (action == 'reschedule' && plannedStart == null) {
      throw const AppFailure('Choose a new planned start.');
    }
    if (action != 'smaller_step') {
      await saveTask(
        task.copyWith(paused: action == 'pause', plannedStart: plannedStart),
      );
    }
    _record(
      'task_recovery',
      _task(id),
      details: {
        'action': action,
        'reason': reason,
        'previousPlannedStart': task.plannedStart?.toIso8601String(),
        'newPlannedStart': plannedStart?.toIso8601String(),
        'procrastinationInferred': false,
      },
    );
    await persist();
  }

  Future<void> reportReminder(
    String kind,
    String taskId,
    Map<String, dynamic> details,
  ) async {
    if (![
      'notification_schedule_registered',
      'notification_opened',
    ].contains(kind)) {
      throw const AppFailure('Unknown notification report.');
    }
    if (_connectionBusy ||
        !state.consent ||
        !state.tasks.any((t) => t.id == taskId)) {
      return;
    }
    if (kind == 'notification_schedule_registered') {
      final last = state.events
          .where(
            (e) =>
                e.kind == kind &&
                e.taskId == taskId &&
                e.condition == state.condition.name &&
                (e.details['category'] ?? 'manual') ==
                    (details['category'] ?? 'manual'),
          )
          .lastOrNull;
      if (last != null &&
          last.details['scheduledAtUtc'] == details['scheduledAtUtc'] &&
          last.details['wording'] == details['wording'] &&
          last.details['language'] == details['language'] &&
          last.details['policyVersion'] == details['policyVersion']) {
        return;
      }
    }
    _record(kind, _task(taskId), details: details);
    await persist();
  }

  Future<void> snooze(String id, DateTime at) async {
    if (!at.isAfter(DateTime.now())) {
      throw const AppFailure('Choose a future reminder time.');
    }
    final task = _task(id);
    if (task.done || task.paused) {
      throw const AppFailure(
        'Reopen or resume this task before setting a reminder.',
      );
    }
    await saveTask(task.copyWith(reminder: at));
    _record(
      'reminder_requested',
      _task(id),
      details: {'at': at.toIso8601String(), 'deliveryConfirmed': false},
    );
    await persist();
  }

  Future<CompletionUndo?> toggleTask(Task task) async {
    _assertSessionReady();
    if (!_completing.add(task.id)) {
      return null;
    }
    try {
      if (_task(task.id).version != task.version) {
        throw const AppFailure(
          'This task changed. Review its current status before trying again.',
        );
      }
      await saveTask(
        task.copyWith(
          done: !task.done,
          completedAt: task.done ? null : DateTime.now(),
        ),
      );
      final completedVersion = _task(task.id).version;
      state = state.copyWith(
        events: [
          ...state.events,
          BehaviorEvent(
            task.done ? 'completion_undone' : 'self_reported_completion',
            task.id,
            DateTime.now(),
            eventId: _id(),
            condition: state.condition.name,
            offsetMinutes: DateTime.now().timeZoneOffset.inMinutes,
            taskVersion: completedVersion,
          ),
        ],
      );
      await persist();
      if (!task.done) {
        final receipt = CompletionUndo._(
          _id(),
          task.id,
          completedVersion,
          state.condition,
          state.backendId,
          state.backendUrl,
        );
        _completionUndo = receipt;
        return receipt;
      }
      return null;
    } finally {
      _completing.remove(task.id);
    }
  }

  Future<void> undoCompletion(CompletionUndo receipt) async {
    _assertSessionReady();
    final current = state.tasks
        .where((t) => t.id == receipt.taskId)
        .firstOrNull;
    if (_completionUndo?.token != receipt.token ||
        state.condition != receipt.condition ||
        state.backendId != receipt.backendId ||
        state.backendUrl != receipt.backendUrl ||
        current == null ||
        !current.done ||
        current.version != receipt.version) {
      throw const AppFailure(
        'This task or account changed. Nothing was undone.',
      );
    }
    _completionUndo = null;
    await toggleTask(current);
  }

  Future<void> selectTodayTask(String id) async {
    _assertSessionReady();
    final task = _task(id);
    if (task.done || task.paused) {
      throw const AppFailure('Choose an active task for Today.');
    }
    state = state.copyWith(todayTaskId: id);
    await persist();
  }

  Future<void> deleteTask(String id) async {
    if (_connectionBusy || !_savingTasks.add(id)) {
      throw const AppFailure(
        'Please let the current task or account request finish.',
      );
    }
    try {
      if (state.focus?.taskId == id) {
        throw const AppFailure(
          'End the current focus session before deleting its task.',
        );
      }
      if (_api != null) {
        await _api!.deleteVersioned(id, _task(id).version);
      } else {
        await repository.deleteTask(id);
      }
      _record('task_deleted', _task(id));
      state = state.copyWith(
        tasks: state.tasks.where((t) => t.id != id).toList(),
      );
      await persist();
    } finally {
      _savingTasks.remove(id);
    }
  }

  Future<List<Subtask>> suggestions(Task task, int variant) async {
    _assertSessionReady();
    if (_connectionBusy) {
      throw const AppFailure('Please let the account connection finish first.');
    }
    _refinementRequests++;
    try {
      if (!state.condition.hasAgent) {
        throw const AppFailure(
          'Task refinement is unavailable in this condition.',
        );
      }
      if (task.done) {
        throw const AppFailure(
          'Reopen this task before requesting a breakdown.',
        );
      }
      final condition = state.condition;
      final result = await repository.refine(
        task,
        condition,
        variant: variant,
        language: ref.read(languageProvider).languageCode,
      );
      _record(
        'refinement_proposed',
        task,
        condition: condition.name,
        details: {
          'variant': variant,
          'original': task.toJson(),
          'suggested': result.map((s) => s.toJson()).toList(),
          'service': state.connected ? 'backend' : 'mock',
          'serverProposalId': _api?.proposalIds[task.id],
        },
      );
      await persist();
      return result;
    } finally {
      _refinementRequests--;
    }
  }

  Future<CorrectionDraft> proposeCorrection(Task task) async {
    _assertSessionReady();
    if (!state.condition.hasAgent || task.done || task.paused) {
      throw const AppFailure('Choose an active task in an AI condition.');
    }
    _refinementRequests++;
    try {
      final condition = state.condition;
      final correction = await repository.correct(
        task,
        condition,
        language: ref.read(languageProvider).languageCode,
      );
      _record(
        'correction_proposed',
        task,
        details: {
          'original': task.toJson(),
          'proposed': correction.toJson(),
          'service': state.connected ? 'backend' : 'mock',
        },
      );
      final id = state.events.last.id;
      final serverId = _api?.proposalIds[task.id];
      await persist();
      return CorrectionDraft(task, correction, condition, id, serverId);
    } finally {
      _refinementRequests--;
    }
  }

  final Set<String> _decidingCorrections = {};
  Future<void> reportSuggestion(String kind, Task? task, String id) async {
    _assertSessionReady();
    if (!state.condition.hasAgent ||
        ![
          'suggestion_displayed',
          'suggestion_opened',
          'suggestion_dismissed',
        ].contains(kind)) {
      return;
    }
    if (task != null && !state.tasks.any((t) => t.id == task.id)) return;
    if (state.events.any(
      (e) =>
          e.kind == kind &&
          e.condition == state.condition.name &&
          e.details['suggestionId'] == id,
    )) {
      return;
    }
    _record(
      kind,
      task,
      details: {
        'suggestionId': id,
        'source': 'task_support_ui',
        'supportVersion': 'task-support-ui-v1',
      },
    );
    await persist();
  }

  Future<void> decideCorrection(
    CorrectionDraft draft, {
    TaskCorrection? accepted,
  }) async {
    _assertSessionReady();
    final current = _task(draft.original.id);
    if (!state.condition.hasAgent ||
        state.condition != draft.condition ||
        current.version != draft.original.version ||
        !state.events.any(
          (e) => e.id == draft.id && e.kind == 'correction_proposed',
        ) ||
        state.events.any(
          (e) =>
              e.details['proposalId'] == draft.id &&
              ['correction_accepted', 'correction_rejected'].contains(e.kind),
        ) ||
        !_decidingCorrections.add(draft.id)) {
      throw const AppFailure(
        'This proposal changed or was already decided. Request a new one.',
      );
    }
    _refinementRequests++;
    try {
      if (accepted != null) {
        TaskCorrection.fromJson(accepted.toJson());
        if (_api != null) {
          if (draft.serverId == null) {
            throw const AppFailure('Request a server proposal first.');
          }
          final saved = await _api!.acceptCorrection(
            draft.serverId!,
            current,
            accepted,
          );
          state = state.copyWith(
            tasks: state.tasks
                .map((t) => t.id == saved.id ? saved : t)
                .toList(),
          );
        } else {
          await saveTask(
            current.copyWith(
              title: accepted.title.trim(),
              description: accepted.description.trim(),
              minutes: accepted.minutes,
            ),
          );
        }
      } else if (_api != null) {
        if (draft.serverId == null) {
          throw const AppFailure('Request a server proposal first.');
        }
        await _api!.rejectProposal(draft.serverId!);
      }
      _record(
        accepted == null ? 'correction_rejected' : 'correction_accepted',
        _task(current.id),
        details: {
          'proposalId': draft.id,
          'serverProposalId': draft.serverId,
          'before': current.toJson(),
          'accepted': accepted?.toJson(),
        },
      );
      await persist();
    } finally {
      _refinementRequests--;
      _decidingCorrections.remove(draft.id);
    }
  }

  Future<void> acceptSuggestions(
    String taskId,
    List<Subtask> suggestions, {
    String? proposalId,
  }) async {
    _assertSessionReady();
    if (!state.condition.hasAgent) {
      throw const AppFailure(
        'Task refinement is unavailable in this condition.',
      );
    }
    final task = state.tasks.firstWhere((t) => t.id == taskId);
    final proposal = state.events.where((e) => e.id == proposalId).firstOrNull;
    if (proposalId != null &&
        (proposal == null ||
            proposal.taskId != taskId ||
            proposal.condition != state.condition.name ||
            proposal.taskVersion != task.version)) {
      throw const AppFailure(
        'This task changed. Regenerate suggestions before accepting.',
      );
    }
    if (_api != null) {
      final serverId = proposal?.details['serverProposalId'];
      if (serverId is! String) {
        throw const AppFailure(
          'Regenerate a server suggestion before accepting.',
        );
      }
      final saved = await _api!.acceptProposal(serverId, task, [
        ...task.subtasks,
        ...suggestions,
      ]);
      state = state.copyWith(
        tasks: state.tasks.map((t) => t.id == saved.id ? saved : t).toList(),
      );
    } else {
      await saveTask(
        task.copyWith(subtasks: [...task.subtasks, ...suggestions]),
      );
    }
    _record(
      'refinement_accepted',
      _task(taskId),
      details: {
        'proposalId': proposalId,
        'before': task.toJson(),
        'accepted': suggestions.map((s) => s.toJson()).toList(),
      },
    );
    await persist();
  }

  Future<void> rejectSuggestions(String taskId, String? proposalId) async {
    _assertSessionReady();
    if (!state.condition.hasAgent) {
      throw const AppFailure('Refinement is unavailable.');
    }
    if (proposalId == null ||
        !state.events.any(
          (e) =>
              e.id == proposalId &&
              e.taskId == taskId &&
              e.condition == state.condition.name &&
              e.kind == 'refinement_proposed',
        ) ||
        state.events.any(
          (e) =>
              e.details['proposalId'] == proposalId &&
              ['refinement_accepted', 'refinement_rejected'].contains(e.kind),
        )) {
      throw const AppFailure('There is no undecided suggestion to reject.');
    }
    if (_api != null) {
      final proposal = state.events
          .where((e) => e.id == proposalId)
          .firstOrNull;
      final serverId = proposal?.details['serverProposalId'];
      if (serverId is! String) {
        throw const AppFailure('No server suggestion is available to reject.');
      }
      await _api!.rejectProposal(serverId);
    }
    _record(
      'refinement_rejected',
      _task(taskId),
      details: {'proposalId': proposalId},
    );
    await persist();
  }

  void _append(StudyCondition condition, ChatMessage message) {
    state = state.copyWith(
      chats: {
        ...state.chats,
        condition.name: [
          ...(state.chats[condition.name] ?? <ChatMessage>[]).where(
            (m) => m.id != message.id,
          ),
          message,
        ],
      },
    );
  }

  Future<void> send(
    String text,
    Task? task, {
    bool retry = false,
    String? retryMessageId,
  }) async {
    _assertSessionReady();
    if (_chatBusy) {
      throw const AppFailure(
        'Please wait for the current reply before sending another message.',
      );
    }
    _chatBusy = true;
    try {
      final condition = state.condition;
      if (!condition.hasAgent) {
        throw const AppFailure('Chat is unavailable in this condition.');
      }
      if (text.trim().isEmpty) {
        return;
      }
      ChatMessage? pending;
      if (retry) {
        pending = state.messages
            .where(
              (m) =>
                  m.user &&
                  m.delivery == 'failed' &&
                  (retryMessageId == null || m.id == retryMessageId),
            )
            .lastOrNull;
        if (pending == null) {
          throw const AppFailure('There is no failed message to retry.');
        }
        text = pending.text;
        task = state.tasks.where((t) => t.id == pending!.taskId).firstOrNull;
        if (pending.taskId != null && task == null) {
          throw const AppFailure(
            'This task was deleted. Cancel this failed message before starting a new conversation.',
          );
        }
        _replaceMessage(condition, pending.withDelivery('sending'));
      } else {
        pending = ChatMessage(
          id: _id(),
          text: text.trim(),
          user: true,
          at: DateTime.now(),
          taskId: task?.id,
          delivery: 'sending',
          language: ref.read(languageProvider).languageCode,
        );
        _append(condition, pending);
      }
      await persist();
      try {
        final response = _api != null
            ? await _api!.chatWithId(
                text,
                condition,
                task,
                pending.id,
                language: pending.language,
              )
            : await repository.chat(
                text,
                condition,
                task,
                profile: state.profile,
                language: pending.language,
              );
        _replaceMessage(condition, pending.withDelivery('sent'));
        _append(condition, response.forTask(pending.taskId));
        await persist();
      } catch (_) {
        _replaceMessage(condition, pending.withDelivery('failed'));
        await persist();
        rethrow;
      }
    } finally {
      _chatBusy = false;
    }
  }

  void _replaceMessage(StudyCondition condition, ChatMessage message) {
    state = state.copyWith(
      chats: {
        ...state.chats,
        condition.name: [
          for (final m in state.chats[condition.name] ?? <ChatMessage>[])
            m.id == message.id ? message : m,
        ],
      },
    );
  }

  Future<void> cancelMessage(String id) async {
    _assertSessionReady();
    final message = state.messages
        .where((m) => m.id == id && m.user && m.delivery == 'failed')
        .firstOrNull;
    if (message != null) {
      _replaceMessage(state.condition, message.withDelivery('cancelled'));
      await persist();
    }
  }

  Future<void> selectChatTask(String? id) async {
    _assertSessionReady();
    state = state.copyWith(chatTaskId: id ?? '__general__');
    await persist();
  }

  Future<void> prepareFocus(String taskId, {int minutes = 10}) async {
    _assertSessionReady();
    if (state.focus != null) {
      return;
    }
    if (![5, 10, 15, 25].contains(minutes)) {
      throw const AppFailure('Choose an available session duration.');
    }
    if (_task(taskId).done || _task(taskId).paused) {
      throw const AppFailure('Reopen or resume the task before focusing.');
    }
    state = state.copyWith(
      focus: FocusSession(
        taskId: taskId,
        id: _id(),
        condition: state.condition.name,
        remainingSeconds: minutes * 60,
        durationSeconds: minutes * 60,
      ),
    );
    await persist();
  }

  Future<void> startFocus([DateTime? at]) async {
    _assertSessionReady();
    final f = state.focus;
    if (f == null || f.deadline != null || f.remainingSeconds == 0) {
      return;
    }
    final now = at ?? DateTime.now();
    state = state.copyWith(focus: f.resume(now));
    _record(
      f.started ? 'focus_resumed' : 'focus_started',
      _task(f.taskId),
      at: now,
      details: {
        'durationSeconds': f.durationSeconds,
        'workVerified': false,
        'sessionId': f.id,
      },
      condition: f.condition,
    );
    await persist();
  }

  Future<void> pauseFocus([DateTime? at]) async {
    _assertSessionReady();
    if (state.focus == null ||
        !state.focus!.started ||
        state.focus!.deadline == null) {
      return;
    }
    final f = state.focus!;
    state = state.copyWith(focus: f.pause(at ?? DateTime.now()));
    _record(
      'focus_paused',
      _task(f.taskId),
      at: at,
      condition: f.condition,
      details: {'sessionId': f.id},
    );
    await persist();
  }

  Future<void> endFocus({String? reflection, DateTime? at}) async {
    _assertSessionReady();
    final f = state.focus;
    if (f == null) {
      return;
    }
    final now = at ?? DateTime.now();
    if (f.started) {
      _record(
        f.remainingAt(now) == 0 ? 'focus_elapsed' : 'focus_ended_early',
        _task(f.taskId),
        at: now,
        seconds: f.durationSeconds - f.remainingAt(now),
        reflection: reflection,
        details: {
          'durationSeconds': f.durationSeconds,
          'workVerified': false,
          'sessionId': f.id,
          'timerDeadline': f.deadline?.toUtc().toIso8601String(),
        },
        condition: f.condition,
      );
      state = state.copyWith(clearFocus: true);
    } else {
      state = state.copyWith(clearFocus: true);
    }
    await persist();
  }

  Future<void> setTheme(ThemeMode theme) async {
    _assertSessionReady();
    state = state.copyWith(theme: theme);
    await persist();
  }

  Future<void> setBurden(String burden) async {
    _assertSessionReady();
    await saveCheckIn('Daily', {'burden': burden});
    state = state.copyWith(burden: burden);
    await persist();
  }

  Future<void> saveCheckIn(
    String phase,
    Map<String, String> answers, {
    String? taskId,
  }) async {
    _assertSessionReady();
    if (!AppConfig.researcherDemo) {
      throw const AppFailure('Approved study instruments are not connected.');
    }
    if (answers.isEmpty) return;
    final now = DateTime.now();
    final entry = CheckIn(
      language: ref.read(languageProvider).languageCode,
      id: _id(),
      phase: phase,
      condition: state.condition.name,
      at: now,
      offsetMinutes: now.timeZoneOffset.inMinutes,
      answers: Map.of(answers),
      taskId: taskId,
    );
    if (_api != null) await _api!.saveCheckIn(entry);
    state = state.copyWith(checkIns: [...state.checkIns, entry]);
    await persist();
  }

  Future<void> saveProfile(SupportProfile profile) async {
    _assertSessionReady();
    if (!AppConfig.researcherDemo) {
      throw const AppFailure('Study preferences are not connected.');
    }
    if (_api != null) await _api!.saveProfile(profile);
    state = state.copyWith(profile: profile);
    await persist();
  }

  Future<void> invitationOpened(String taskId) async {
    if (!state.condition.hasAgent || !state.profile.invitations) {
      throw const AppFailure('Task invitations are off.');
    }
    _record(
      'invitation_opened',
      _task(taskId),
      details: {'policy': 'demo-on-device-v1', 'notificationDelivered': false},
    );
    await persist();
  }

  Future<void> reset() async {
    _assertSessionReady();
    _completionUndo = null;
    if (state.connected) {
      throw const AppFailure('Disconnect before resetting the local demo.');
    }
    await _writes;
    await ref.read(preferencesProvider).remove(storageKey);
    state = const AppState();
    await initialize();
  }
}
