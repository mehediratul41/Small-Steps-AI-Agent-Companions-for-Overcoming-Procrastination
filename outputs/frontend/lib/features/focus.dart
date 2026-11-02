import '../l10n/strings.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/state.dart';
import '../app/theme.dart';
import '../data/models.dart';
import '../shared/widgets.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});
  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen>
    with WidgetsBindingObserver {
  Timer? ticker;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    ticker?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> finish() async {
    final reflection = TextEditingController();
    final taskId = ref.read(appProvider).focus?.taskId;
    bool checkIn = false;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.finishThisSession_e68101),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(context.l10n.theSessionWillBeSavedSeparately_4a1171),
              const SizedBox(height: 16),
              TextField(
                controller: reflection,
                maxLines: 3,
                maxLength: 1000,
                decoration: InputDecoration(
                  labelText: context.l10n.optionalReflection_a4797d,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.keepSession_32239a),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.saveSession_8c7478),
          ),
          TextButton(
            onPressed: () {
              checkIn = true;
              Navigator.pop(context, true);
            },
            child: Text(context.l10n.saveCheckIn_1894e2),
          ),
        ],
      ),
    );
    final text = reflection.text.trim();
    // Dialog exit animation still references its controller for one frame.
    Future<void>.delayed(const Duration(milliseconds: 400), reflection.dispose);
    if (accepted == true) {
      await ref
          .read(appProvider.notifier)
          .endFocus(reflection: text.isEmpty ? null : text);
      if (mounted) {
        context.go(
          checkIn
              ? '/check-in?phase=after&task=${Uri.encodeComponent(taskId ?? '')}'
              : '/insights',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    final focus = state.focus;
    if (focus == null) {
      return PageBody(
        children: [
          EmptyPanel(
            context.l10n.noActiveSession_efed39,
            context.l10n.chooseATaskToBeginA_5c965f,
          ),
        ],
      );
    }
    final task = state.tasks.where((t) => t.id == focus.taskId).firstOrNull;
    final remaining = focus.remainingAt(DateTime.now());
    final label = context.l10n.value_ebc826(
      ((remaining ~/ 60).toString().padLeft(2, '0')).toString(),
      ((remaining % 60).toString().padLeft(2, '0')).toString(),
    );
    return PageBody(
      children: [
        Heading(
          context.l10n.focusSession_3ee7c5,
          state.condition.hasAgent
              ? context.l10n.youVeGotThis_ecf44a
              : context.l10n.focusSession_3ee7c5,
          state.condition.hasAgent
              ? context.l10n.justOneStepNoNeedTo_2e292d
              : context.l10n.aMinuteWorkSession_e980c5(
                  (focus.durationSeconds ~/ 60).toString(),
                ),
        ),
        Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.currentStep_57706f,
                style: TextStyle(fontSize: 11),
              ),
              const SizedBox(height: 16),
              Text(
                task?.title ?? 'Task no longer available',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 38),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 272),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.surface,
                      ),
                    ),
                  ),
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: remaining / focus.durationSeconds,
                      strokeWidth: 20,
                      strokeAlign: -1,
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      color: softColor(context, AppTokens.mint),
                      semanticsLabel: '$label remaining',
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(26),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 47,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            context.l10n.ofAMinuteSession_4129d6(
                              (focus.durationSeconds ~/ 60).toString(),
                            ),
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 38),
        if (remaining == 0)
          Panel(child: Text(context.l10n.yourSessionTimeHasElapsedYour_f295ed)),
        const SizedBox(height: 16),
        if (remaining > 0)
          PrimaryButton(
            focus.deadline != null
                ? context.l10n.pauseSession_c5eb7f
                : focus.started
                ? context.l10n.resumeSession_bcc407
                : context.l10n.startSession_76684e,
            onPressed: () => focus.deadline != null
                ? ref.read(appProvider.notifier).pauseFocus()
                : ref.read(appProvider.notifier).startFocus(),
          ),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: finish,
          child: Text(
            remaining == 0
                ? context.l10n.finishReflect_fd1c04
                : context.l10n.endSession_8c0f4c,
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.push(
            '/check-in?phase=${!focus.started
                ? 'before'
                : remaining == 0
                ? 'after'
                : 'during'}&task=${Uri.encodeComponent(focus.taskId)}',
          ),
          child: Text(context.l10n.optionalSessionCheckIn_124d0d),
        ),
        Text(
          context.l10n.youCanLeaveThisScreenA_4d2f96,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
