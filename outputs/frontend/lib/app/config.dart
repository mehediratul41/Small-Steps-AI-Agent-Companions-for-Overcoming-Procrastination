/// Participant builds fail closed until an authenticated backend is connected.
class AppConfig {
  static const researcherDemo = bool.fromEnvironment(
    'RESEARCHER_DEMO',
    defaultValue: true,
  );
  static const baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );
  static const baselineQuestions = <String>[];
}
