import '../l10n/strings.dart';
import '../app/language.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/config.dart';
import '../app/state.dart';
import '../data/models.dart';
import '../data/repository.dart';
import '../shared/widgets.dart';
import '../app/reminders_controller.dart';
import 'reminder_settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.settings_c7f73b)),
      body: SafeArea(
        child: PageBody(
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(context.l10n.language),
              subtitle: const Text('English / 日本語'),
              trailing: const LanguageMenu(),
            ),
            Heading(
              context.l10n.smallSteps_5b77d5,
              context.l10n.yourPreferences_41bc34,
              context.l10n.adjustTheAppearanceAndExploreThe_cbc0ad,
            ),
            if (AppConfig.researcherDemo)
              ListTile(
                leading: const Icon(Icons.cloud_outlined),
                title: Text(
                  state.connected
                      ? context.l10n.developmentBackend_3f59e0(
                          (state.backendId).toString(),
                        )
                      : context.l10n.connectToDevelopmentBackend_3ac1a0,
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/backend'),
              ),
            DropdownButtonFormField<ThemeMode>(
              isExpanded: true,
              initialValue: state.theme,
              decoration: InputDecoration(
                labelText: context.l10n.appearance_41def7,
              ),
              items: ThemeMode.values
                  .map(
                    (m) => DropdownMenuItem(
                      value: m,
                      child: Text(context.tr((m.name).toString())),
                    ),
                  )
                  .toList(),
              onChanged: (v) => ref.read(appProvider.notifier).setTheme(v!),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.favorite_border),
              title: Text(context.l10n.yourGoalsPreferences_e71b24),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/preferences'),
            ),
            ListTile(
              leading: const Icon(Icons.assignment_outlined),
              title: Text(context.l10n.optionalBaselineDemo_dbf225),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/check-in?phase=baseline'),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip_outlined),
              title: Text(context.l10n.dataStudyInformation_2cc532),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/demo-data'),
            ),
            const SizedBox(height: 24),
            const ReminderSettings(),
            if (!state.connected)
              TextButton.icon(
                icon: const Icon(Icons.phonelink_erase_outlined),
                label: Text(
                  context.l10n.forgetSavedDevelopmentAccountsOnThis_b3e68b,
                ),
                onPressed: () async {
                  if (!await confirm(
                    context,
                    context.l10n.forgetSavedDevelopmentData_cc5ca3,
                    context.l10n.removeAllConnectedAccountPendingReports_ed9e78,
                  )) {
                    return;
                  }
                  if (!context.mounted) return;
                  await perform(
                    context,
                    () => ref
                        .read(appProvider.notifier)
                        .forgetSavedDevelopmentAccounts(),
                  );
                },
              ),
            const SizedBox(height: 24),
            if (AppConfig.researcherDemo && !state.connected) ...[
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.researcherDemoMode_44c8be,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context
                          .l10n
                          .forDemonstrationOnlyParticipantBuildsDo_142767,
                    ),
                    const SizedBox(height: 20),
                    DropdownButtonFormField<StudyCondition>(
                      initialValue: state.condition,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: context.l10n.experimentalCondition_7873b9,
                      ),
                      items: StudyCondition.values
                          .map(
                            (c) => DropdownMenuItem(
                              value: c,
                              child: Text(context.tr(c.label)),
                            ),
                          )
                          .toList(),
                      onChanged: (v) =>
                          ref.read(appProvider.notifier).switchCondition(v!),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () {
                  final repo = ref.read(repositoryProvider);
                  if (repo is MockResearchRepository) {
                    repo.failNext = true;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context.l10n.theNextDemoRequestWillFail_325484,
                        ),
                      ),
                    );
                  }
                },
                child: Text(context.l10n.simulateNextRequestFailure_aa9665),
              ),
              TextButton(
                onPressed: () async {
                  if (await confirm(
                    context,
                    context.l10n.resetLocalDemo_fc75d3,
                    context
                        .l10n
                        .thisRemovesDemoTasksConversationsReflections_707870,
                  )) {
                    await ref.read(remindersProvider.notifier).reset();
                    if (ref.read(remindersProvider).error == null) {
                      await ref.read(appProvider.notifier).reset();
                    }
                  }
                },
                child: Text(context.l10n.resetLocalDemo_c6435b),
              ),
            ],
            const SizedBox(height: 24),
            Text(
              context
                  .l10n
                  .researchPrototypeShimaneUniversityUseFictional_78a317,
            ),
          ],
        ),
      ),
    );
  }
}
