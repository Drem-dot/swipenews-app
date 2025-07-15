// lib/config/environment.dart
class Environment {
  static const String webClientId = String.fromEnvironment(
    'WEB_CLIENT_ID',
    defaultValue: '', // Empty for public repo
  );
}