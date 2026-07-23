import 'package:shared_preferences/shared_preferences.dart';

abstract final class OnboardingPreferences {
  static const _completedKey = 'hungry_spot_onboarding_completed_v1';
  static final _preferences = SharedPreferencesAsync();

  static Future<bool> hasCompleted() async {
    return await _preferences.getBool(_completedKey) ?? false;
  }

  static Future<void> markCompleted() {
    return _preferences.setBool(_completedKey, true);
  }
}
