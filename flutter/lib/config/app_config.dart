class AppConfig {
  static const String serverUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'http://10.0.2.2:3000',
  );
}
