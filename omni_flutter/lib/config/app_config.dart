/// Build-time configuration.
///
/// Nothing secret is allowed to live in this file. Keys arrive through
/// `--dart-define` so they stay out of version control:
///
/// ```
/// flutter run --dart-define=GEMINI_API_KEY=...
/// flutter build ipa --dart-define=GEMINI_API_KEY=...
/// ```
///
/// A key compiled into a client binary is extractable by anyone who downloads
/// the app, so `--dart-define` is a stopgap, not a solution. Before launch the
/// model calls must move behind a server that holds the key and checks the
/// caller's subscription — see docs/LAUNCH.md.
class AppConfig {
  const AppConfig._();

  static const String geminiApiKey =
      String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');

  /// Whether model-backed features can run at all.
  static bool get hasModelAccess => geminiApiKey.isNotEmpty;

  /// Base URL of the backend proxy. When set, the app calls the proxy instead
  /// of talking to the model provider directly.
  static const String apiBaseUrl =
      String.fromEnvironment('OMNI_API_BASE_URL', defaultValue: '');

  static bool get usesBackendProxy => apiBaseUrl.isNotEmpty;

  static const String appVersion = '1.0.0';

  /// Free tier limits. Deliberately generous: the paywall converts better after
  /// the user has seen a real reading than before.
  static const int freeChatMessagesPerDay = 3;
  static const int freeOracleDrawsPerDay = 1;
  static const int freeCompatibilityChecksPerMonth = 3;
}
