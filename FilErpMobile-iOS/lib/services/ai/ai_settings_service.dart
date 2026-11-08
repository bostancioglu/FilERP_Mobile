import 'package:shared_preferences/shared_preferences.dart';

/// Yapay zekâ (Anthropic) API anahtarının cihazda saklanması.
///
/// NOT: Bu, mobil-taraflı bir GEÇİCİ çözümdür (anahtar cihazda, SharedPreferences'ta
/// düz metin tutulur). İleride bu çağrı .NET backend'e taşındığında anahtar sunucu
/// tarafında saklanacak ve bu servis kaldırılacak.
class AiSettingsService {
  AiSettingsService._();
  static final AiSettingsService instance = AiSettingsService._();

  static const _kApiKey = 'ai_anthropic_api_key';

  Future<String?> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getString(_kApiKey);
    return (v == null || v.trim().isEmpty) ? null : v.trim();
  }

  Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kApiKey, key.trim());
  }

  Future<void> clearApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kApiKey);
  }

  /// Ekranda gösterim için maskelenmiş önizleme: sk-ant-...ab12
  String maskKey(String key) {
    if (key.length <= 10) return '••••••••';
    return '${key.substring(0, 7)}...${key.substring(key.length - 4)}';
  }
}
