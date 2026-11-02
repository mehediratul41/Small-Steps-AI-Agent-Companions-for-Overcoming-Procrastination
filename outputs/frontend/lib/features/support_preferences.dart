import '../l10n/strings.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/state.dart';
import '../data/models.dart';
import '../shared/widgets.dart';

class SupportPreferencesScreen extends ConsumerStatefulWidget {
  const SupportPreferencesScreen({super.key});
  @override
  ConsumerState<SupportPreferencesScreen> createState() =>
      _SupportPreferencesScreenState();
}

class _SupportPreferencesScreenState
    extends ConsumerState<SupportPreferencesScreen> {
  late final TextEditingController values, goal;
  late bool brief, invitations;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    final p = ref.read(appProvider).profile;
    values = TextEditingController(text: p.values);
    goal = TextEditingController(text: p.goal);
    brief = p.brief;
    invitations = p.invitations;
  }

  @override
  void dispose() {
    values.dispose();
    goal.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasAgent = ref.watch(appProvider).condition.hasAgent;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.yourPreferences_41bc34)),
      body: SafeArea(
        child: PageBody(
          children: [
            Heading(
              context.l10n.makeItYours_541351,
              context.l10n.whatMattersToYou_0337b3,
              context.l10n.theseDetailsAreOptionalYouCan_c938a9,
            ),
            TextField(
              controller: values,
              maxLength: 200,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.l10n.whatMattersToMe_7344b1,
                hintText:
                    context.l10n.forExampleCuriosityBalanceIndependence_47cf1f,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: goal,
              maxLength: 200,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: context.l10n.aLongerTermGoal_9c0345,
                hintText:
                    context.l10n.forExampleExplainMyResearchClearly_753e5a,
              ),
            ),
            if (hasAgent) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.preferShorterResponses_f32f83),
                value: brief,
                onChanged: (v) => setState(() => brief = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.showSmallStepInvitations_5e4106),
                subtitle: Text(
                  context.l10n.optionalSuggestionsOnTodayWhenA_ed4750,
                ),
                value: invitations,
                onChanged: (v) => setState(() => invitations = v),
              ),
              Text(context.l10n.invitationsAreOffByDefaultThey_963d6c),
            ],
            const SizedBox(height: 20),
            Panel(
              child: Text(
                ref.watch(appProvider).connected
                    ? context.l10n.thesePreferencesAreSavedOnThe_4453aa
                    : context.l10n.localDemoOnlyUseFictionalInformation_9010f0,
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              context.l10n.savePreferences_d8ab74,
              busy: busy,
              onPressed: () async {
                setState(() => busy = true);
                await perform(context, () async {
                  await ref
                      .read(appProvider.notifier)
                      .saveProfile(
                        SupportProfile(
                          values: values.text.trim(),
                          goal: goal.text.trim(),
                          brief: brief,
                          invitations: invitations,
                        ),
                      );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(context.l10n.preferencesSaved_0b7d6e),
                      ),
                    );
                    context.canPop() ? context.pop() : context.go('/today');
                  }
                });
                if (mounted) setState(() => busy = false);
              },
            ),
            TextButton(
              onPressed: () => setState(() {
                values.clear();
                goal.clear();
                brief = false;
                invitations = false;
              }),
              child: Text(context.l10n.clearTheseFields_c6e6cd),
            ),
          ],
        ),
      ),
    );
  }
}

class DemoDataScreen extends ConsumerWidget {
  const DemoDataScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appProvider);
    final export = const JsonEncoder.withIndent('  ').convert({
      'format': 'small-steps-demo-export-v2',
      'demoOnly': true,
      'source': state.connected ? 'development-backend-snapshot' : 'local-demo',
      'account': state.backendId,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
      'data': state.toJson(),
    });
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.dataStudyInformation_2cc532)),
      body: SafeArea(
        child: PageBody(
          children: [
            Heading(
              context.l10n.yourData_48cd18,
              context.l10n.youStayInControl_277bc5,
              state.connected
                  ? context
                        .l10n
                        .connectedDevelopmentAccountFictionalDataOnly_0991c1
                  : context.l10n.thisInstallationIsALocalDemonstration_df04cf,
            ),
            Panel(
              child: Text(
                context.l10n.participantEnrollmentIsDisabledNoReal_2d5279,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              context.l10n.tasksActivityRecordsCheckIns_8accaa(
                (state.tasks.length).toString(),
                (state.events.length).toString(),
                (state.checkIns.length).toString(),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              state.connected
                  ? context.l10n.copyRetrievesTheCompleteServerExport_08b93d
                  : context.l10n.theExportIncludesLocalTaskText_7ad752,
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () async {
                await perform(context, () async {
                  final text = state.connected
                      ? const JsonEncoder.withIndent('  ').convert(
                          await ref
                              .read(appProvider.notifier)
                              .exportServerData(),
                        )
                      : export;
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          context
                              .l10n
                              .developmentJsonCopiedToYourClipboard_27d777,
                        ),
                      ),
                    );
                  }
                });
              },
              icon: const Icon(Icons.copy),
              label: Text(
                state.connected
                    ? context.l10n.copyCompleteServerExport_db2f88
                    : context.l10n.copyDemoJson_fc2b92,
              ),
            ),
            Card(
              child: ExpansionTile(
                title: Text(
                  state.connected
                      ? context.l10n.reviewLoadedStatePartial_314c03
                      : context.l10n.reviewExportContents_614fb9,
                ),
                children: [
                  SizedBox(
                    height: 360,
                    child: SingleChildScrollView(
                      child: SelectableText(
                        export,
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(context.l10n.newRecordsHaveIdsUtcTimestamps_c6e6f7),
          ],
        ),
      ),
    );
  }
}
