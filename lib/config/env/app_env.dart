enum AppEnv { dev, staging, prod }

extension AppEnvExtension on AppEnv {
  // Base URL is now sourced from dotenv via core/config/env.dart.
  String get name => toString().split('.').last;

  bool get enableLogs => this != AppEnv.prod;
}
