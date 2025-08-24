import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ai_service.dart';

class SettingsService {
  static const _storage = FlutterSecureStorage();
  
  // API Keys
  static Future<void> saveAPIKey(AIProvider provider, String key) async {
    await _storage.write(key: '${provider.name}_api_key', value: key);
  }
  
  static Future<String?> getAPIKey(AIProvider provider) async {
    return await _storage.read(key: '${provider.name}_api_key');
  }
  
  static Future<void> deleteAPIKey(AIProvider provider) async {
    await _storage.delete(key: '${provider.name}_api_key');
  }
  
  // Default AI Provider
  static Future<void> setDefaultProvider(AIProvider provider) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('default_provider', provider.name);
  }
  
  static Future<AIProvider> getDefaultProvider() async {
    final prefs = await SharedPreferences.getInstance();
    final providerName = prefs.getString('default_provider') ?? 'gemini';
    return AIProvider.values.firstWhere(
      (p) => p.name == providerName,
      orElse: () => AIProvider.gemini,
    );
  }
  
  // Education Level
  static Future<void> setEducationLevel(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('education_level', level);
  }
  
  static Future<String> getEducationLevel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('education_level') ?? 'Undergraduate';
  }
  
  // Speaker Mode
  static Future<void> setSingleSpeakerMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('single_speaker_mode', enabled);
  }
  
  static Future<bool> getSingleSpeakerMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('single_speaker_mode') ?? true;
  }
}