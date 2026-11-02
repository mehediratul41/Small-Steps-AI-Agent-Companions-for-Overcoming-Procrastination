import '../l10n/strings.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/state.dart';
import '../app/reminders_controller.dart';
import '../shared/widgets.dart';
import '../data/saved_connections.dart';

class BackendConnectionScreen extends ConsumerStatefulWidget {
  const BackendConnectionScreen({super.key});
  @override
  ConsumerState<BackendConnectionScreen> createState() =>
      _BackendConnectionScreenState();
}

class _BackendConnectionScreenState
    extends ConsumerState<BackendConnectionScreen> {
  final url = TextEditingController(
    text: kIsWeb || defaultTargetPlatform != TargetPlatform.android
        ? 'http://127.0.0.1:8000'
        : 'http://10.0.2.2:8000',
  );
  final token = TextEditingController();
  bool busy = false, acknowledged = false, remember = true;
  String? error;
  @override
  void dispose() {
    url.dispose();
    token.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.developmentBackend_6d6dad),
        leading: BackButton(
          onPressed: () => context.go(state.consent ? '/today' : '/welcome'),
        ),
      ),
      body: SafeArea(
        child: PageBody(
          children: [
            Heading(
              context.l10n.syntheticAccountsOnly_9fd71e,
              context.l10n.connectSmallSteps_f9ba22,
              context.l10n.useTheRunningFastapiServiceAnd_911b62,
            ),
            if (state.connected) ...[
              TextButton.icon(
                icon: const Icon(Icons.person_add_alt_1),
                label: Text(context.l10n.addAgentAccount),
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        try {
                          await ref
                              .read(appProvider.notifier)
                              .disconnectBackend();
                          if (mounted) setState(() => acknowledged = false);
                        } catch (e) {
                          if (mounted) setState(() => error = '$e');
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
              ),
              Text(context.l10n.linkedAgentAccounts),
              Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.connectedAs_41c3bd(
                        (state.backendId).toString(),
                      ),
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    Text(state.backendUrl!),
                    Text(
                      context.l10n.assignedCondition_06173e(
                        (state.condition.name).toString(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(context.l10n.tasksAndConversationsAreStoredOn_b5abfb),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                context.l10n.refreshServerData_7b6b1d,
                busy: busy,
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        await ref.read(appProvider.notifier).initialize();
                        if (mounted) setState(() => busy = false);
                      },
              ),
              TextButton(
                onPressed: busy
                    ? null
                    : () async {
                        setState(() => busy = true);
                        try {
                          await ref
                              .read(appProvider.notifier)
                              .disconnectBackend();
                          if (context.mounted) {
                            context.go(
                              ref.read(appProvider).consent
                                  ? '/today'
                                  : '/welcome',
                            );
                          }
                        } catch (e) {
                          if (mounted) setState(() => error = '$e');
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
                child: Text(context.l10n.disconnectAndReturnToLocalDemo_91878e),
              ),
              TextButton.icon(
                icon: const Icon(Icons.delete_forever_outlined),
                label: Text(
                  context.l10n.eraseThisDevelopmentAccountSData_d44c64,
                ),
                onPressed: busy
                    ? null
                    : () async {
                        if (!await confirm(
                          context,
                          context.l10n.eraseDevelopmentData_da3da0,
                          context.l10n.permanentlyEraseThisAccountSTasks_aa06c1,
                        )) {
                          return;
                        }
                        if (!mounted) return;
                        setState(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await ref
                              .read(appProvider.notifier)
                              .eraseDevelopmentData();
                          if (context.mounted) context.go('/settings');
                        } catch (e) {
                          if (mounted) setState(() => error = '$e');
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
              ),
              if (state.error != null)
                Text(
                  state.error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ] else ...[
              if (ref.watch(savedConnectionsProvider).isNotEmpty)
                TextButton(
                  onPressed: busy
                      ? null
                      : () => perform(
                          context,
                          () => ref
                              .read(appProvider.notifier)
                              .forgetSavedLogins(),
                        ),
                  child: Text(context.l10n.forgetAgentLogins),
                ),
              Panel(child: Text(context.l10n.startTheBackendThenEnterA_26d501)),
              const SizedBox(height: 20),
              TextField(
                controller: url,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: context.l10n.backendUrl_61290c,
                ),
                keyboardType: TextInputType.url,
                autocorrect: false,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: token,
                enabled: !busy,
                obscureText: true,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: context.l10n.developmentParticipantToken_df51bc,
                ),
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: acknowledged,
                onChanged: busy
                    ? null
                    : (v) => setState(() => acknowledged = v ?? false),
                title: Text(context.l10n.iWillUseFictionalDataConnected_750258),
              ),
              Text(context.l10n.pendingReportsUnsentMessagesAndThe_650fbe),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(context.l10n.rememberAgentLogin),
                subtitle: Text(context.l10n.rememberAgentHint),
                value: remember,
                onChanged: busy
                    ? null
                    : (v) => setState(() => remember = v ?? false),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                context.l10n.connect_b65463,
                busy: busy,
                onPressed: busy || !acknowledged
                    ? null
                    : () async {
                        setState(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await ref
                              .read(appProvider.notifier)
                              .connectBackend(
                                url.text,
                                token.text,
                                remember: remember,
                              );
                          await ref.read(remindersProvider.notifier).refresh();
                          token.clear();
                          if (context.mounted) {
                            context.go(
                              ref.read(appProvider).consent
                                  ? '/today'
                                  : '/consent',
                            );
                          }
                        } catch (e) {
                          if (mounted) setState(() => error = '$e');
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
              ),
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
