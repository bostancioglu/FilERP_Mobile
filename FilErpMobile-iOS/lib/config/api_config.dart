import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth/authorization_session.dart';

enum ServerType { canli, test }

class ApiConfig {
  // ── Sabit URL'ler ──────────────────────────────────────────
  static const String canliUrl = "http://api.filerp.com/api";
  static const String testUrl = "http://apitest.filerp.com/api";
  static const String eBelgeCanliUrl = 'http://152.89.38.195:7199/api';
  static const String eBelgeTestUrl = 'http://31.207.84.254:7197/api';

  static String get eBelgeBaseUrl =>
      _serverType == ServerType.test ? eBelgeTestUrl : eBelgeCanliUrl;

  // ── Runtime state ──────────────────────────────────────────
  static String _baseUrl = canliUrl;
  static ServerType _serverType = ServerType.canli;

  static String get baseUrl => _baseUrl;
  static ServerType get serverType => _serverType;

  // ── Uygulama açılışında SharedPreferences'tan yükle ────────
  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString("server_type") ?? "canli";
    await setServer(
      saved == "test" ? ServerType.test : ServerType.canli,
      save: false,
    );
  }

  // ── Server değiştir (login ekranından çağrılır) ────────────
  static Future<void> setServer(ServerType type, {bool save = true}) async {
    if (type != _serverType) {
      await AuthorizationSession.instance.clear();
      final oldPrefs = await SharedPreferences.getInstance();
      await oldPrefs.remove('token');
      await oldPrefs.remove('token_final');
    }
    _serverType = type;
    _baseUrl = (type == ServerType.test) ? testUrl : canliUrl;
    if (save) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        "server_type",
        type == ServerType.test ? "test" : "canli",
      );
    }
  }
}
