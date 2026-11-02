import 'package:flutter/widgets.dart';
import 'app_localizations.dart';
import 'catalog.dart';

export 'app_localizations.dart';

extension LocalizedValue on AppLocalizations {
  String text(String value) => translateValue(this, value);
}

extension AppLanguageContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(
        Locale(Localizations.localeOf(this).languageCode == 'ja' ? 'ja' : 'en'),
      );
  bool get isJapanese => Localizations.localeOf(this).languageCode == 'ja';

  /// Translate canonical UI values and known errors only. Never pass task text
  /// or stored conversation messages through this boundary.
  String tr(String value) => translateValue(l10n, value);
}
