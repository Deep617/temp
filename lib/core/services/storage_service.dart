import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const String kOnboarded = 'onboarded';

  Future<void> setOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(kOnboarded, true);
  }

  Future<bool> getOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(kOnboarded) ?? false;
  }

  Future<void> clearStorage() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}
