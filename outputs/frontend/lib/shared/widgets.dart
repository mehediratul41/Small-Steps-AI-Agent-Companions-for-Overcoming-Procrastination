import '../l10n/strings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../app/state.dart';
import '../app/theme.dart';
import '../data/models.dart';

/// Editable four-point brand mark; independent of platform font fallback.
class BrandSpark extends StatelessWidget {
  final Color color;
  final double size;
  const BrandSpark({super.key, this.color = AppTokens.teal, this.size = 40});
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
    child: CustomPaint(size: Size.square(size), painter: _SparkPainter(color)),
  );
}

class _SparkPainter extends CustomPainter {
  final Color color;
  const _SparkPainter(this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final path = Path()
      ..moveTo(w / 2, 0)
      ..cubicTo(w * .60, h * .30, w * .70, h * .40, w, h / 2)
      ..cubicTo(w * .70, h * .60, w * .60, h * .70, w / 2, h)
      ..cubicTo(w * .40, h * .70, w * .30, h * .60, 0, h / 2)
      ..cubicTo(w * .30, h * .40, w * .40, h * .30, w / 2, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_SparkPainter oldDelegate) => oldDelegate.color != color;
}

class PageBody extends StatelessWidget {
  final List<Widget> children;
  const PageBody({super.key, required this.children});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
    children: children,
  );
}

class Heading extends StatelessWidget {
  final String eyebrow, title, subtitle;
  const Heading(this.eyebrow, this.title, this.subtitle, {super.key});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 28),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        const SizedBox(height: 14),
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 8),
        Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      ],
    ),
  );
}

class Panel extends StatelessWidget {
  final Widget child;
  final Color? color;
  const Panel({super.key, required this.child, this.color});
  @override
  Widget build(BuildContext context) => Card(
    color: color == null ? null : softColor(context, color!),
    child: Padding(padding: const EdgeInsets.all(20), child: child),
  );
}

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  const PrimaryButton(
    this.label, {
    super.key,
    this.onPressed,
    this.busy = false,
  });
  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox.square(
              dimension: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    ),
  );
}

class EmptyPanel extends StatelessWidget {
  final String title, detail;
  const EmptyPanel(this.title, this.detail, {super.key});
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      children: [
        Icon(
          Icons.spa_outlined,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 12),
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(detail, textAlign: TextAlign.center),
      ],
    ),
  );
}

class ErrorPanel extends StatelessWidget {
  final String message;
  final VoidCallback retry;
  const ErrorPanel(this.message, {super.key, required this.retry});
  @override
  Widget build(BuildContext context) => Panel(
    child: Column(
      children: [
        Text(context.tr(message)),
        TextButton.icon(
          onPressed: retry,
          icon: const Icon(Icons.refresh),
          label: Text(context.l10n.tryAgain_042c86),
        ),
      ],
    ),
  );
}

class AgentAvatar extends StatelessWidget {
  final StudyCondition condition;
  const AgentAvatar(this.condition, {super.key});
  @override
  Widget build(BuildContext context) => Container(
    width: 52,
    height: 52,
    decoration: BoxDecoration(
      color: softColor(
        context,
        condition == StudyCondition.friendAgent
            ? AppTokens.lavender
            : AppTokens.mint,
      ),
      borderRadius: BorderRadius.circular(17),
    ),
    child: Icon(
      condition == StudyCondition.friendAgent
          ? Icons.favorite_border
          : Icons.auto_awesome_outlined,
      color: Theme.of(context).colorScheme.primary,
    ),
  );
}

class TaskCard extends ConsumerWidget {
  final Task task;
  final bool reminder;
  const TaskCard(this.task, {super.key, this.reminder = false});
  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        leading: Checkbox(
          value: task.done,
          semanticLabel: context.l10n.complete_3d1040((task.title).toString()),
          onChanged: (_) => toggleTaskWithUndo(context, ref, task),
        ),
        title: Text(
          task.title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            decoration: task.done ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            reminder
                ? context.l10n.reminderTime_bbde4a(
                    context.tr(
                      (task.reminder == null
                              ? 'Not set'
                              : DateFormat.MMMMd().add_jm().format(
                                  task.reminder!,
                                ))
                          .toString(),
                    ),
                  )
                : context.l10n.min_548460(
                    context.tr((task.status).toString()),
                    (task.minutes).toString(),
                    context.tr(
                      (task.plannedStart != null
                              ? 'Start ${DateFormat.MMMd().add_jm().format(task.plannedStart!)}'
                              : task.due != null
                              ? 'Due ${DateFormat.MMMd().add_jm().format(task.due!)}'
                              : 'No dates set')
                          .toString(),
                    ),
                  ),
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
        onTap: () => context.push('/task/${Uri.encodeComponent(task.id)}'),
      ),
    ),
  );
}

/// Capture the messenger before awaiting: a completed card can disappear from
/// the Active filter before its repository write finishes.
Future<void> toggleTaskWithUndo(
  BuildContext context,
  WidgetRef ref,
  Task task,
) async {
  final messenger = ScaffoldMessenger.of(context);
  final strings = context.l10n;
  final controller = ref.read(appProvider.notifier);
  try {
    final receipt = await controller.toggleTask(task);
    if (receipt == null || !messenger.mounted) return;
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(strings.taskMarkedComplete_1999ee),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: strings.undo_39fc72,
          onPressed: () async {
            try {
              await controller.undoCompletion(receipt);
            } catch (error) {
              if (messenger.mounted) {
                messenger.showSnackBar(
                  SnackBar(content: Text(strings.text(error.toString()))),
                );
              }
            }
          },
        ),
      ),
    );
  } catch (error) {
    if (messenger.mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(strings.text(error.toString()))),
      );
    }
  }
}

Future<void> perform(BuildContext context, Future<void> Function() work) async {
  try {
    await work();
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.tr(e.toString()))));
    }
  }
}

Future<bool> confirm(BuildContext context, String title, String detail) async =>
    await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(detail),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel_77dfd2),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.confirm_04a212),
          ),
        ],
      ),
    ) ??
    false;
