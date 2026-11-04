import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:small_steps/app/app.dart';
import 'package:small_steps/app/state.dart';
import 'package:small_steps/data/models.dart';
import 'package:small_steps/data/saved_connections.dart';
import 'live_agent_accounts_test.dart' show AccountApi;

class UserApi extends AccountApi {
  UserApi(super.condition);
  @override
  String get accountId => 'USER-${condition.name}';
  static int logouts = 0;
  @override
  Future<void> signOutAccount() async {
    logouts++;
  }
}

class TestVault extends MemoryConnectionStorage {
  bool failWrites = false;
  @override
  Future<void> write(String value) async {
    if (failWrites) throw StateError('Synthetic secure storage failure');
    await super.write(value);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late SharedPreferences prefs;
  late TestVault storage;
  late ProviderContainer container;
  ProviderContainer create() => ProviderContainer(
    overrides: [
      preferencesProvider.overrideWithValue(prefs),
      connectionStorageProvider.overrideWithValue(storage),
      apiFactoryProvider.overrideWithValue(
        (url, token) => UserApi(
          token == 'control'
              ? StudyCondition.standardControl
              : StudyCondition.selfAgent,
        ),
      ),
    ],
  );
  setUp(() async {
    SharedPreferences.setMockInitialValues({
      AppController.storageKey: jsonEncode(
        const AppState(loaded: true, consent: true).toJson(),
      ),
    });
    prefs = await SharedPreferences.getInstance();
    storage = TestVault();
    container = create();
    UserApi.logouts = 0;
    await container.read(appProvider.notifier).initialize();
  });
  tearDown(() => container.dispose());

  test(
    'secure storage failure cannot leave a signed-out account visible or restore it',
    () async {
      await container
          .read(appProvider.notifier)
          .connectBackend(
            'http://127.0.0.1:8000',
            'control',
            accountLogin: true,
            remember: true,
          );
      storage.failWrites = true;
      await container.read(appProvider.notifier).signOutAccount();
      expect(container.read(appProvider).connected, isFalse);
      expect(container.read(appProvider).tasks, isEmpty);
      expect(container.read(appProvider).error, contains('saved credentials'));
      container.dispose();
      container = create();
      await container.read(appProvider.notifier).initialize();
      expect(container.read(appProvider).connected, isFalse);
    },
  );

  test(
    'normal control login restores securely and cannot enable agent switching',
    () async {
      await container
          .read(appProvider.notifier)
          .connectBackend(
            'http://127.0.0.1:8000',
            'control',
            accountLogin: true,
            remember: true,
          );
      expect(container.read(savedConnectionsProvider), isEmpty);
      expect(
        prefs.getString(AppController.storageKey),
        isNot(contains('control')),
      );
      container.dispose();
      container = create();
      await container.read(appProvider.notifier).initialize();
      expect(container.read(appProvider).backendId, 'USER-standardControl');
      expect(
        container.read(appProvider).condition,
        StudyCondition.standardControl,
      );
      expect(
        container
            .read(appProvider.notifier)
            .canSwitchLiveTo(StudyCondition.selfAgent),
        isFalse,
      );
      await container.read(appProvider.notifier).signOutAccount();
      expect(UserApi.logouts, 1);
      expect(container.read(appProvider).connected, isFalse);
      container.dispose();
      container = create();
      await container.read(appProvider.notifier).initialize();
      expect(container.read(appProvider).connected, isFalse);
    },
  );

  test(
    'a second user never receives the first users cached task state',
    () async {
      final controller = container.read(appProvider.notifier);
      await controller.connectBackend(
        'http://127.0.0.1:8000',
        'self',
        accountLogin: true,
        remember: true,
      );
      expect(container.read(appProvider).tasks.single.title, 'USER-selfAgent');
      await controller.signOutAccount();
      await controller.connectBackend(
        'http://127.0.0.1:8000',
        'control',
        accountLogin: true,
        remember: true,
      );
      expect(
        container.read(appProvider).tasks.single.title,
        'USER-standardControl',
      );
      expect(
        container.read(appProvider).messages.single.text,
        'USER-standardControl',
      );
    },
  );

  testWidgets('account form validates and exposes invitation enrollment', (
    tester,
  ) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const SmallStepsApp(),
      ),
    );
    await tester.pumpAndSettle();
    container.read(routerProvider).go('/account');
    await tester.pumpAndSettle();
    expect(find.text('Backend URL'), findsNothing);
    await tester.tap(find.text('Sign in'));
    await tester.pump();
    expect(find.text('Use 12–128 characters.'), findsOneWidget);
    final enroll = find.text('Have an invitation? Create account');
    await tester.ensureVisible(enroll);
    await tester.tap(enroll);
    await tester.pumpAndSettle();
    expect(find.text('Invitation code'), findsOneWidget);
    expect(find.text('Confirm password'), findsOneWidget);
    await tester.enterText(
      find.byKey(const ValueKey('password-confirmation')),
      'different-password',
    );
    await tester.ensureVisible(find.text('Create account'));
    await tester.tap(find.text('Create account'));
    await tester.pumpAndSettle();
    expect(find.text('Passwords do not match.'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
