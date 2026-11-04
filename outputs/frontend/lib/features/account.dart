import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../app/config.dart';
import '../app/language.dart';
import '../app/state.dart';
import '../data/repository.dart';
import '../l10n/strings.dart';
import '../shared/widgets.dart';

/// Invite-only development accounts. Authentication is separate from consent.
class AccountScreen extends ConsumerStatefulWidget {
  const AccountScreen({super.key});
  @override
  ConsumerState<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends ConsumerState<AccountScreen> {
  final form = GlobalKey<FormState>();
  final url = TextEditingController(
    text: kIsWeb ? 'http://127.0.0.1:8000' : AppConfig.baseUrl,
  );
  final username = TextEditingController();
  final password = TextEditingController();
  final invitation = TextEditingController();
  bool enroll = false, busy = false, remember = true;
  String? error;
  String copy(String en, String ja) => context.isJapanese ? ja : en;

  @override
  void dispose() {
    for (final field in [url, username, password, invitation]) {
      field.dispose();
    }
    super.dispose();
  }

  Future<void> submit() async {
    if (!form.currentState!.validate()) return;
    if (!AppConfig.acceptsBackendUrl(url.text)) {
      setState(
        () => error = copy(
          'Use HTTPS. Local HTTP is for debug builds on this computer or simulator.',
          'HTTPSを使用してください。ローカルHTTPは、開発用PCまたはシミュレーターのデバッグビルド専用です。',
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      error = null;
    });
    final base = url.text.trim().replaceFirst(RegExp(r'/+$'), '');
    final api = ApiResearchRepository(base);
    try {
      final session = await api.authenticateAccount(
        username: username.text.trim(),
        password: password.text,
        invitation: enroll ? invitation.text.trim() : null,
      );
      password.clear();
      invitation.clear();
      await ref
          .read(appProvider.notifier)
          .connectBackend(
            base,
            session['token'] as String,
            expectedId: session['participant_id'] as String,
            accountLogin: true,
            remember: remember,
          );
      if (mounted) {
        context.go(ref.read(appProvider).consent ? '/today' : '/consent');
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => error = copy(
            'Could not sign in. Check the server, credentials or invitation; wait ten minutes after repeated attempts. If enrollment succeeded but connection failed, use Sign in.',
            'ログインできませんでした。サーバー、認証情報、招待コードを確認してください。試行回数が多い場合は10分待ってください。登録後に接続に失敗した場合はログインしてください。',
          ),
        );
      }
    } finally {
      api.close();
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(copy('Account', 'アカウント')),
        actions: const [LanguageMenu()],
      ),
      body: SafeArea(
        child: PageBody(
          children: [
            Text(
              copy(
                'Invite-only development accounts. Study consent and approved deployment are separate requirements.',
                '招待制の開発用アカウントです。研究参加への同意と承認済みの運用は別途必要です。',
              ),
            ),
            if (state.connected) ...[
              Text('${copy('Signed in as', 'ログイン中')}: ${state.backendId}'),
              Text(
                '${copy('Server assignment', 'サーバー側の割り当て')}: ${state.condition.name}',
              ),
              PrimaryButton(
                copy('Sign out', 'ログアウト'),
                busy: busy,
                onPressed: busy
                    ? null
                    : () async {
                        setState(() {
                          busy = true;
                          error = null;
                        });
                        try {
                          await ref.read(appProvider.notifier).signOutAccount();
                          if (mounted) {
                            setState(() => error = ref.read(appProvider).error);
                          }
                        } catch (_) {
                          if (mounted) {
                            setState(
                              () => error = copy(
                                'End the active session or request before signing out.',
                                '進行中のセッションや処理を終了してからログアウトしてください。',
                              ),
                            );
                          }
                        } finally {
                          if (mounted) setState(() => busy = false);
                        }
                      },
              ),
            ] else
              Form(
                key: form,
                child: Column(
                  children: [
                    TextFormField(
                      controller: url,
                      enabled: !busy,
                      autocorrect: false,
                      decoration: InputDecoration(
                        labelText: copy('Backend URL', 'バックエンド URL'),
                      ),
                    ),
                    TextFormField(
                      controller: username,
                      enabled: !busy,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: copy('Username', 'ユーザー名'),
                      ),
                      validator: (v) =>
                          RegExp(
                            r'^[a-zA-Z0-9_.-]{3,64}$',
                          ).hasMatch(v?.trim() ?? '')
                          ? null
                          : copy(
                              'Use 3–64 letters, digits, dots, dashes or underscores.',
                              '英数字、ピリオド、ハイフン、アンダースコアで3～64文字にしてください。',
                            ),
                    ),
                    TextFormField(
                      controller: password,
                      enabled: !busy,
                      obscureText: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      decoration: InputDecoration(
                        labelText: copy('Password', 'パスワード'),
                      ),
                      validator: (v) =>
                          (v?.length ?? 0) >= 12 && (v?.length ?? 0) <= 128
                          ? null
                          : copy('Use 12–128 characters.', '12～128文字にしてください。'),
                    ),
                    if (enroll)
                      TextFormField(
                        controller: invitation,
                        enabled: !busy,
                        obscureText: true,
                        autocorrect: false,
                        enableSuggestions: false,
                        decoration: InputDecoration(
                          labelText: copy('Invitation code', '招待コード'),
                        ),
                        validator: (v) =>
                            (v?.trim().length ?? 0) >= 20 &&
                                (v?.trim().length ?? 0) <= 200
                            ? null
                            : copy('Enter your invitation.', '招待コードを入力してください。'),
                      ),
                    CheckboxListTile(
                      value: remember,
                      onChanged: busy
                          ? null
                          : (v) => setState(() => remember = v ?? false),
                      title: Text(copy('Remember this session', 'セッションを保存')),
                      subtitle: Text(
                        copy(
                          'Mobile: secure storage. Web: memory only. Password is never saved.',
                          'モバイルは安全なストレージ、Web はメモリのみ。パスワードは保存しません。',
                        ),
                      ),
                    ),
                    PrimaryButton(
                      enroll
                          ? copy('Use invitation', '招待コードで登録')
                          : copy('Sign in', 'ログイン'),
                      busy: busy,
                      onPressed: busy ? null : submit,
                    ),
                    TextButton(
                      onPressed: busy
                          ? null
                          : () => setState(() {
                              enroll = !enroll;
                              error = null;
                            }),
                      child: Text(
                        enroll
                            ? copy('Already registered? Sign in', '登録済みの方はこちら')
                            : copy(
                                'Have an invitation? Create account',
                                '招待コードでアカウントを作成',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            if (error != null)
              Text(
                error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
          ],
        ),
      ),
    );
  }
}
