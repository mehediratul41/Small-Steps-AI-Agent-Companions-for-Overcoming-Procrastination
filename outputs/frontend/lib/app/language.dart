import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'state.dart';
import '../l10n/strings.dart';

final languageProvider = NotifierProvider<LanguageController, Locale>(
  LanguageController.new,
);

class LanguageController extends Notifier<Locale> {
  static const storageKey = 'small_steps.language.v1';
  @override
  Locale build() => Locale(
    ref.read(preferencesProvider).getString(storageKey) == 'ja' ? 'ja' : 'en',
  );
  Future<void> setLanguage(String code) async {
    if (!['en', 'ja'].contains(code)) {
      throw ArgumentError('Unsupported language');
    }
    final saved = await ref
        .read(preferencesProvider)
        .setString(storageKey, code);
    if (!saved) throw StateError('Language preference could not be saved');
    state = Locale(code);
  }
}

class LanguageMenu extends ConsumerWidget {
  const LanguageMenu({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => PopupMenuButton<String>(
    tooltip: context.l10n.chooseLanguage,
    icon: const Icon(Icons.language),
    initialValue: ref.watch(languageProvider).languageCode,
    onSelected: (code) async {
      try {
        await ref.read(languageProvider.notifier).setLanguage(code);
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.isJapanese
                    ? '言語設定を保存できませんでした。もう一度お試しください。'
                    : 'Could not save the language. Please try again.',
              ),
            ),
          );
        }
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(value: 'en', child: Text('English')),
      PopupMenuItem(value: 'ja', child: Text('日本語')),
    ],
  );
}
