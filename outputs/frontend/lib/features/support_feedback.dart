import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/config.dart';
import '../app/state.dart';
import '../app/reminders_controller.dart';
import '../l10n/strings.dart';
import '../shared/widgets.dart';

String supportChoiceLabel(BuildContext context, String choice) =>
    switch (choice) {
      'smaller_step' => context.l10n.uxSmallerStep,
      'clear_plan' => context.l10n.uxClearPlan,
      'encouragement' => context.l10n.uxEncouragement,
      'quiet_time' => context.l10n.uxQuietTime,
      _ => context.l10n.uxSkip,
    };

class SupportFeedbackPanel extends ConsumerStatefulWidget {
  const SupportFeedbackPanel({super.key});
  @override
  ConsumerState<SupportFeedbackPanel> createState() =>
      _SupportFeedbackPanelState();
}

class _SupportFeedbackPanelState extends ConsumerState<SupportFeedbackPanel> {
  bool busy = false;
  String? error;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      try {
        await ref.read(appProvider.notifier).offerSupportFeedback();
      } catch (_) {
        if (mounted) setState(() => error = context.l10n.uxFeedbackError);
      }
    });
  }

  Future<void> answer(String choice) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await ref.read(appProvider.notifier).answerSupportFeedback(choice);
    } catch (_) {
      if (mounted) setState(() => error = context.l10n.uxFeedbackError);
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    if (!AppConfig.supportFeedbackEnabled) return const SizedBox.shrink();
    final pending = ref.read(appProvider.notifier).pendingSupportFeedback;
    final previous = state.events
        .where(
          (e) =>
              e.kind == 'support_feedback_answered' &&
              e.condition == state.condition.name &&
              AppController.feedbackChoices.contains(e.details['choice']),
        )
        .lastOrNull;
    if (pending == null && previous == null && error == null) {
      return const SizedBox.shrink();
    }
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pending != null) ...[
            Text(
              context.l10n.uxFeedback,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(context.l10n.uxFeedbackHint),
            Wrap(
              spacing: 8,
              children: [
                for (final choice in AppController.feedbackChoices)
                  TextButton(
                    onPressed: busy ? null : () => answer(choice),
                    child: Text(supportChoiceLabel(context, choice)),
                  ),
              ],
            ),
          ] else if (previous != null)
            Text(
              '${context.l10n.uxFeedbackLast} ${supportChoiceLabel(context, previous.details['choice'] as String)}',
            ),
          Text(
            context.l10n.uxFeedbackStorage,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (error != null)
            Text(
              error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}

class LessSupportButton extends ConsumerWidget {
  const LessSupportButton({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!AppConfig.reducedSupportEnabled) return const SizedBox.shrink();
    final reminders = ref.watch(remindersProvider);
    final paused =
        reminders.preferences.pausedUntil?.isAfter(DateTime.now()) == true;
    return TextButton.icon(
      icon: const Icon(Icons.notifications_paused_outlined),
      label: Text(
        paused ? context.l10n.resumeReminders : context.l10n.uxLessSupport,
      ),
      onPressed: !reminders.ready || reminders.busy
          ? null
          : () async {
              if (!paused &&
                  !await confirm(
                    context,
                    context.l10n.uxPauseAll,
                    context.l10n.uxPauseAllHint,
                  )) {
                return;
              }
              if (!context.mounted) return;
              await perform(
                context,
                () => ref
                    .read(remindersProvider.notifier)
                    .pauseToday(resume: paused),
              );
            },
    );
  }
}
