import '../l10n/strings.dart';
import 'language.dart';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/onboarding.dart';
import '../features/account.dart';
import '../features/backend_connection.dart';
import '../features/dashboard.dart';
import '../features/tasks.dart';
import '../features/chat.dart';
import '../features/focus.dart';
import '../features/insights.dart';
import '../features/settings.dart';
import '../shared/widgets.dart';
import 'config.dart';
import 'state.dart';
import 'theme.dart';
import '../data/models.dart';
import 'reminders_controller.dart';
import '../features/check_ins.dart';
import '../features/support_preferences.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier(0);
  ref.listen(appProvider, (a, b) => refresh.value++);
  final router = GoRouter(
    initialLocation: '/welcome',
    refreshListenable: refresh,
    redirect: (context, route) {
      final state = ref.read(appProvider);
      final path = route.uri.path;
      if (!state.loaded) {
        return path == '/loading' ? null : '/loading';
      }
      if (!AppConfig.researcherDemo) {
        return path == '/unavailable' ? null : '/unavailable';
      }
      // Both synthetic accounts were prevalidated. Keep Chat mounted while
      // loading the target account instead of redirecting on temporary consent.
      if (path == '/chat' &&
          ref.read(appProvider.notifier).switchingLiveAccount) {
        return null;
      }
      if (!state.consent &&
          ![
            '/welcome',
            '/consent',
            '/settings',
            '/backend',
            '/account',
          ].contains(path)) {
        return '/welcome';
      }
      if (state.consent &&
          ['/welcome', '/consent', '/loading'].contains(path)) {
        return '/today';
      }
      if (!state.condition.hasAgent &&
          (path == '/chat' || path.startsWith('/refine/'))) {
        return '/reminders';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/account', builder: (context, _) => const AccountScreen()),
      GoRoute(
        path: '/loading',
        builder: (context, _) =>
            const Scaffold(body: Center(child: CircularProgressIndicator())),
      ),
      GoRoute(
        path: '/unavailable',
        builder: (context, _) => Scaffold(
          body: SafeArea(
            child: PageBody(
              children: [
                Heading(
                  context.l10n.studySetup_99dc41,
                  context.l10n.studyServiceRequired_fa898d,
                  context.l10n.participantEnrollmentIsNotEnabled_61c91c,
                ),
                EmptyPanel(
                  context.l10n.awaitingStudyConfiguration_2a3a93,
                  context
                      .l10n
                      .anAuthenticatedBackendAssignmentAndApproved_69d5f6,
                ),
              ],
            ),
          ),
        ),
      ),
      GoRoute(path: '/welcome', builder: (context, _) => const WelcomeScreen()),
      GoRoute(path: '/consent', builder: (context, _) => const ConsentScreen()),
      GoRoute(
        path: '/settings',
        builder: (context, _) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/backend',
        builder: (context, _) => const BackendConnectionScreen(),
      ),
      GoRoute(
        path: '/preferences',
        builder: (context, _) => const SupportPreferencesScreen(),
      ),
      GoRoute(
        path: '/demo-data',
        builder: (context, _) => const DemoDataScreen(),
      ),
      GoRoute(
        path: '/check-in',
        builder: (_, state) => CheckInScreen(
          key: ValueKey(state.uri.toString()),
          phase: switch (state.uri.queryParameters['phase']) {
            'baseline' => 'Baseline demo',
            'before' => 'Before session',
            'during' => 'During session',
            'after' => 'After session',
            _ => 'Daily',
          },
          taskId: state.uri.queryParameters['task'],
        ),
      ),
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(path: state.uri.path, child: child),
        routes: [
          GoRoute(
            path: '/today',
            builder: (context, _) => const DashboardScreen(),
          ),
          GoRoute(path: '/tasks', builder: (context, _) => const TasksScreen()),
          GoRoute(
            path: '/chat',
            builder: (_, state) =>
                ChatScreen(initialTaskId: state.uri.queryParameters['task']),
          ),
          GoRoute(
            path: '/reminders',
            builder: (context, _) => const TasksScreen(reminders: true),
          ),
          GoRoute(
            path: '/insights',
            builder: (context, _) => const InsightsScreen(),
          ),
          GoRoute(
            path: '/task/new',
            builder: (context, _) => const TaskEditor(),
          ),
          GoRoute(
            path: '/task/:id',
            builder: (_, state) => TaskDetail(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/edit/:id',
            builder: (_, state) => TaskEditor(id: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/refine/:id',
            builder: (_, state) =>
                RefinementScreen(id: state.pathParameters['id']!),
          ),
          GoRoute(path: '/focus', builder: (context, _) => const FocusScreen()),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: SafeArea(
        child: PageBody(
          children: [
            EmptyPanel(
              context.l10n.pageNotFound_bc3023,
              context.l10n.chooseTodayToReturnToYour_b02c03,
            ),
            TextButton(
              onPressed: () => context.go('/today'),
              child: Text(context.l10n.goToToday_d56ae4),
            ),
          ],
        ),
      ),
    ),
  );
  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

class SmallStepsApp extends ConsumerStatefulWidget {
  const SmallStepsApp({super.key});
  @override
  ConsumerState<SmallStepsApp> createState() => _SmallStepsAppState();
}

class _SmallStepsAppState extends ConsumerState<SmallStepsApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() async {
      await ref.read(appProvider.notifier).initialize();
      if (mounted) {
        await ref.read(remindersProvider.notifier).initialize();
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(remindersProvider.notifier).refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(remindersProvider, (previous, next) {
      if (next.connectionRequired) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || !ref.read(remindersProvider).connectionRequired) {
            return;
          }
          ref.read(remindersProvider.notifier).acknowledgeConnectionRequest();
          ref.read(routerProvider).go('/backend');
        });
      }
      if (next.openedTaskId != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          final app = ref.read(appProvider),
              id = ref.read(remindersProvider).openedTaskId;
          if (!app.loaded || !app.consent || id == null) {
            return;
          }
          ref.read(remindersProvider.notifier).acknowledgeOpen();
          ref
              .read(routerProvider)
              .go(
                app.tasks.any((task) => task.id == id)
                    ? '/task/${Uri.encodeComponent(id)}'
                    : '/tasks',
              );
        });
      }
    });
    final locale = ref.watch(languageProvider);
    Intl.defaultLocale = locale.languageCode;
    return MaterialApp.router(
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      title: 'Small Steps',
      debugShowCheckedModeBanner: false,
      theme: appTheme(Brightness.light),
      darkTheme: appTheme(Brightness.dark),
      themeMode: ref.watch(appProvider.select((s) => s.theme)),
      routerConfig: ref.watch(routerProvider),
    );
  }
}

class AppShell extends ConsumerWidget {
  final String path;
  final Widget child;
  const AppShell({super.key, required this.path, required this.child});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final reminderError = ref.watch(remindersProvider.select((s) => s.error));
    final index = path == '/insights'
        ? 3
        : (path == '/chat' || path == '/reminders')
        ? 2
        : (path.contains('task') ||
              path.startsWith('/edit') ||
              path.startsWith('/refine'))
        ? 1
        : 0;
    final detail = ![
      '/today',
      '/tasks',
      '/chat',
      '/reminders',
      '/insights',
    ].contains(path);
    return PopScope(
      canPop: detail || path == '/today',
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          context.go('/today');
        }
      },
      child: Scaffold(
        appBar: AppBar(
          toolbarHeight: 44,
          leading: detail
              ? BackButton(
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/today'),
                )
              : null,
          title: Text(
            ref.read(appProvider.notifier).sessionExpired
                ? context.l10n.sessionExpiredTitle
                : state.connected
                ? context.l10n.smallStepsConnectedDevelopment_b3aebd
                : (AppConfig.researcherDemo
                      ? context.l10n.smallStepsDemo_989b13
                      : context.l10n.smallSteps_5b77d5),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          actions: [
            const LanguageMenu(),
            IconButton(
              tooltip: context.l10n.settings_c7f73b,
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.tune_rounded, size: 21),
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          bottom: false,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Column(
                children: [
                  if (state.error != null && path != '/chat')
                    MaterialBanner(
                      content: Text(context.tr(state.error!)),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              ref.read(appProvider.notifier).initialize(),
                          child: Text(context.l10n.retry_9f5cd8),
                        ),
                      ],
                    ),
                  Expanded(child: child),
                  if (reminderError != null)
                    MaterialBanner(
                      content: Text(
                        context.l10n.reminderSchedulingNeedsAttention_0f940a,
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => context.push('/settings'),
                          child: Text(context.l10n.review_e29a79),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: MediaQuery.viewInsetsOf(context).bottom > 0
            ? null
            : NavigationBar(
                selectedIndex: index,
                onDestinationSelected: (i) => context.go(
                  [
                    '/today',
                    '/tasks',
                    state.condition.hasAgent ? '/chat' : '/reminders',
                    '/insights',
                  ][i],
                ),
                destinations: [
                  NavigationDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: context.l10n.today_24345a,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.checklist_outlined),
                    selectedIcon: Icon(Icons.checklist),
                    label: context.l10n.tasks_090ec5,
                  ),
                  NavigationDestination(
                    icon: Icon(
                      state.condition.hasAgent
                          ? Icons.chat_bubble_outline
                          : Icons.notifications_outlined,
                    ),
                    selectedIcon: Icon(
                      state.condition.hasAgent
                          ? Icons.chat_bubble
                          : Icons.notifications,
                    ),
                    label: state.condition.hasAgent
                        ? context.l10n.chat_2ced57
                        : context.l10n.reminders_ae8c39,
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.bar_chart_outlined),
                    selectedIcon: Icon(Icons.bar_chart),
                    label: context.l10n.insights_b45103,
                  ),
                ],
              ),
      ),
    );
  }
}
