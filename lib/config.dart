import 'package:shared_preferences/shared_preferences.dart';

class Config {
  static const _apiUrlKey = 'api_url';

  final SharedPreferencesAsync _prefs = SharedPreferencesAsync();

  Future<String?> getApiUrl() {
    return _prefs.getString(_apiUrlKey);
  }

  Future<void> setApiUrl(String url) {
    return _prefs.setString(_apiUrlKey, url);
  }

  Future<void> clearApiUrl() {
    return _prefs.remove(_apiUrlKey);
  }
}