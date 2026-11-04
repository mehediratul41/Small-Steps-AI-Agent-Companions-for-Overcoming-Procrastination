import 'package:flutter/foundation.dart';

/// Participant builds fail closed until an authenticated backend is connected.
class AppConfig {
  static const researcherDemo = bool.fromEnvironment(
    'RESEARCHER_DEMO',
    defaultValue: true,
  );
  static const _configuredUrl = String.fromEnvironment('API_BASE_URL');
  static String get baseUrl => _configuredUrl.isNotEmpty
      ? _configuredUrl
      : defaultBackendUrl(defaultTargetPlatform, web: kIsWeb);

  static String defaultBackendUrl(
    TargetPlatform platform, {
    bool web = false,
  }) => !web && platform == TargetPlatform.android
      ? 'http://10.0.2.2:8000'
      : 'http://127.0.0.1:8000';

  /// No credentials, query strings or insecure distribution endpoints.
  /// Local HTTP is debug-only; physical iPhones use a trusted HTTPS backend.
  static bool acceptsBackendUrl(
    String value, {
    bool development = kDebugMode,
    TargetPlatform? platform,
  }) {
    final uri = Uri.tryParse(value.trim());
    if (uri == null ||
        uri.userInfo.isNotEmpty ||
        uri.hasQuery ||
        uri.hasFragment ||
        uri.host.isEmpty ||
        !{'http', 'https'}.contains(uri.scheme)) {
      return false;
    }
    final target = platform ?? defaultTargetPlatform;
    if (uri.host == '10.0.2.2' &&
        (kIsWeb || target != TargetPlatform.android)) {
      return false;
    }
    if (uri.scheme == 'https') return true;
    return development &&
        {
          'localhost',
          '127.0.0.1',
          '::1',
          if (!kIsWeb && target == TargetPlatform.android) '10.0.2.2',
        }.contains(uri.host);
  }

  static const supportFeedbackEnabled =
      researcherDemo &&
      bool.fromEnvironment('DEV_SUPPORT_FEEDBACK', defaultValue: false);
  static const reducedSupportEnabled =
      researcherDemo &&
      bool.fromEnvironment('DEV_REDUCED_SUPPORT', defaultValue: false);
  static const feedbackCooldownHours = int.fromEnvironment(
    'DEV_SUPPORT_FEEDBACK_HOURS',
    defaultValue: 24,
  );
  static const baselineQuestions = <String>[];
}
