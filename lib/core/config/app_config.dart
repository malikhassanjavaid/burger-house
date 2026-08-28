abstract final class AppConfig {
  static const privacyPolicyUrl = String.fromEnvironment(
    'PRIVACY_POLICY_URL',
    defaultValue:
        'https://malikhassanjavaid.github.io/burger-house/privacy-policy.html',
  );

  static const accountDeletionUrl = String.fromEnvironment(
    'ACCOUNT_DELETION_URL',
    defaultValue:
        'https://malikhassanjavaid.github.io/burger-house/delete-account.html',
  );

  /// Set for store builds with `--dart-define=SUPPORT_EMAIL=...`.
  static const supportEmail = String.fromEnvironment('SUPPORT_EMAIL');
}
