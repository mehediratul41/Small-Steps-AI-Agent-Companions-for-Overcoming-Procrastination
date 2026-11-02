import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/state.dart';
import '../shared/widgets.dart';

class CheckInScreen extends ConsumerStatefulWidget {
  final String phase;
  final String? taskId;
  const CheckInScreen({super.key, this.phase = 'Daily', this.taskId});
  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final answers = <String, String>{};
  bool busy = false;
  Widget question(String key, String title, List<String> options) => Padding(
    padding: const EdgeInsets.only(bottom: 22),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          initialValue: answers[key],
          isExpanded: true,
          decoration: InputDecoration(
            labelText: context.l10n.optionalResponse_e43a2e,
          ),
          items: [...options, 'Prefer not to answer']
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(context.tr((v).toString())),
                ),
              )
              .toList(),
          onChanged: busy
              ? null
              : (v) => setState(() {
                  if (v != null) answers[key] = v;
                }),
        ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) {
    final baseline = widget.phase == 'Baseline demo';
    final history = ref
        .watch(appProvider)
        .checkIns
        .where(
          (c) =>
              c.phase == widget.phase &&
              (widget.taskId == null || c.taskId == widget.taskId),
        )
        .toList();
    final task = ref
        .watch(appProvider)
        .tasks
        .where((t) => t.id == widget.taskId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.optionalCheckIn_3f57e8)),
      body: SafeArea(
        child: PageBody(
          children: [
            Heading(
              context.l10n.yourExperience_15ee78,
              baseline
                  ? context.l10n.beforeYouBegin_b4738e
                  : context.l10n.howDoesStartingFeel_4c40aa,
              context.l10n.skipAnyQuestionOrLeaveWithout_7a8ae8,
            ),
            Panel(
              child: Text(
                ref.watch(appProvider).connected
                    ? context
                          .l10n
                          .demonstrationQuestionsNotAValidatedInstrument_ebaf67
                    : context.l10n.demoQuestionsOnlyNotAValidated_d3799c,
              ),
            ),
            const SizedBox(height: 20),
            if (task != null) ...[
              Text(
                context.l10n.about_30ae27((task.title).toString()),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
            ],
            if (baseline) ...[
              question(
                'following_plans',
                context.l10n.recentlyHowEasyHasFollowingYour_7bf490,
                ['Very difficult', 'Difficult', 'Mixed', 'Easy', 'Very easy'],
              ),
              question(
                'unwanted_delay',
                context.l10n.howOftenHaveYouDelayedTasks_50a43a,
                ['Rarely', 'Sometimes', 'Often', 'Very often'],
              ),
            ] else ...[
              question('burden', context.l10n.howHeavyDoYourTasksFeel_4db047, [
                'Light',
                'Okay',
                'Heavy',
              ]),
              question('readiness', context.l10n.howReadyDoYouFeelTo_82c0fb, [
                'Not ready',
                'Somewhat ready',
                'Ready',
              ]),
              Card(
                child: ExpansionTile(
                  title: Text(context.l10n.moreReflectionOptional_835ed9),
                  children: [
                    question(
                      'resistance',
                      context.l10n.howDifficultDoesStartingFeel_3af19b,
                      ['Not difficult', 'Somewhat difficult', 'Very difficult'],
                    ),
                    question(
                      'motivation',
                      context.l10n.howMotivatedDoYouFeel_78d035,
                      ['Low', 'Mixed', 'High'],
                    ),
                    question(
                      'alignment',
                      context.l10n.doesYourNextStepFitYour_e7ebd0,
                      ['Not yet', 'Partly', 'Yes'],
                    ),
                    question(
                      'awareness',
                      context.l10n.howClearIsWhatIsHolding_51d8ab,
                      ['Unclear', 'Partly clear', 'Clear'],
                    ),
                    question(
                      'autonomy',
                      context.l10n.doYouFeelFreeToChoose_ad8869,
                      ['Not much', 'Somewhat', 'Yes'],
                    ),
                    question(
                      'support',
                      context.l10n.didTheSupportYouUsedFeel_a29436,
                      [
                        'Not helpful',
                        'Mixed',
                        'Helpful',
                        'Did not use support',
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 20),
            PrimaryButton(
              context.l10n.saveCheckIn_6dfe99,
              busy: busy,
              onPressed: answers.isEmpty
                  ? null
                  : () async {
                      setState(() => busy = true);
                      await perform(context, () async {
                        await ref
                            .read(appProvider.notifier)
                            .saveCheckIn(
                              widget.phase,
                              answers,
                              taskId: task?.id,
                            );
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                context.l10n.checkInSavedAsANew_976966,
                              ),
                            ),
                          );
                          context.canPop()
                              ? context.pop()
                              : context.go('/insights');
                        }
                      });
                      if (mounted) setState(() => busy = false);
                    },
            ),
            TextButton(
              onPressed: busy
                  ? null
                  : () =>
                        context.canPop() ? context.pop() : context.go('/today'),
              child: Text(context.l10n.skipForNow_6fc096),
            ),
            const SizedBox(height: 24),
            if (history.isNotEmpty) ...[
              Text(
                context.l10n.previousEntries_7d8403,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              for (final c in history.reversed.take(6))
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat.yMMMd().add_jm().format(c.at.toLocal()),
                        ),
                        Text(
                          c.answers.entries
                              .map(
                                (e) =>
                                    '${context.tr(e.key.replaceAll('_', ' '))}: ${context.tr(e.value)}',
                              )
                              .join('\n'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
