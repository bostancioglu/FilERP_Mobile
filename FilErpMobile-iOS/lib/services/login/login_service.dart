import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../auth/authorization_session.dart';
import '../auth/authorized_http.dart' as authorized;
import '../../models/entities/yonetim/branch_choice.dart';
import '../../helpers/cari_plasiyer_helper.dart';

// Modeller
import '../../models/entities/yonetim/sube_dto.dart';
import '../../models/entities/yonetim/sirket_dto.dart';
import '../../models/entities/yonetim/kullanici_dto.dart';
import '../../models/entities/yonetim/yetki_dto.dart';

class LoginService {
  /// 🔵 1) Kullanıcı adı + şifre ile giriş
  Future<KullaniciDto?> login(String user, String pass) async {
    await AuthorizationSession.instance.clear();
    final oldPrefs = await SharedPreferences.getInstance();
    await oldPrefs.remove('token_final');
    await oldPrefs.remove('token');
    final body = jsonEncode({
      "Kullaniciadi": user,
      "Sifre": pass,
    });

    final url = Uri.parse("${ApiConfig.baseUrl}/Login/Login");

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: body,
    );

    if (response.statusCode != 200) return null;

    final json = jsonDecode(response.body);

    if (json["Data"] == null) return null;

    final kullanici = KullaniciDto.fromJson(json["Data"]);
    await AuthorizationSession.instance
        .login(Map<String, dynamic>.from(json['Data']));

    // İlk token kaydet
    final prefs = await SharedPreferences.getInstance();
    if (kullanici.token != null) {
      await prefs.setString("token", kullanici.token!);
    }

    // Firma / Şirket / Şube ID'lerini kaydet
    await prefs.setInt("firma_id", kullanici.firmaId ?? 0);
    await prefs.setInt("sirket_id", kullanici.sirketId ?? 0);
    await prefs.setInt("sube_id", kullanici.subeId ?? 0);

    return kullanici;
  }

  /// 🔵 2) Login sonrası Şirket ve Şube listesi oluşturma (Blazor ile aynı)
  Map<String, dynamic> extractSirketSubeLists(KullaniciDto kullanici) {
    // Yetkiler asla null olmayacak
    final yetkiler = kullanici.yetkiler ?? [];

    // SUBELER
    List<SubeDto> subeler = [];
    for (YetkiDto y in yetkiler) {
      if (y.sube != null && !subeler.any((s) => s.id == y.sube!.id)) {
        subeler.add(y.sube!);
      }
    }

    // SIRKETLER
    List<SirketDto> sirketler = [];
    for (SubeDto s in subeler) {
      if (s.sirket != null && !sirketler.any((x) => x.id == s.sirket!.id)) {
        sirketler.add(s.sirket!);
      }
    }

    return {
      "Sirketler": sirketler,
      "Subeler": subeler,
    };
  }

  /// 🔵 3) Şirket + Şube login (/api/Login/SS)
  Future<Map<String, dynamic>?> loginSirketSube(
      int sirketId, int subeId) async {
    final session = AuthorizationSession.instance;
    final envelope = await session.loginEnvelope();
    if (!(envelope['rows'] as List).any((r) => r['Subeid'] == subeId))
      throw Exception('Bu şubeye erişiminiz yok.');
    final known = (envelope['branchChoices'] as List? ?? [])
        .where((r) => r['Id'] == subeId)
        .firstOrNull;
    if (known != null && known['Sirketid'] != sirketId)
      throw Exception('Şirket ve şube eşleşmiyor.');
    final oldScope = session.cacheScope;

    // An active SS token carries OturumId: reuse that server session on switches.
    final prefs = await SharedPreferences.getInstance();
    final tokenKey = oldScope == null ? 'token' : 'token_final';
    final loginToken = prefs.getString(tokenKey);

    if (loginToken == null) {
      return {
        "Errors": ["Login token eksik!"]
      };
    }

    final body = jsonEncode({
      "Sid": sirketId,
      "Suid": subeId,
    });

    final url = Uri.parse("${ApiConfig.baseUrl}/Login/SS");

    final response = await http.post(
      url,
      headers: {
        "Content-Type": "application/json",
        "Authorization": "Bearer $loginToken"
      },
      body: body,
    );

    if (response.statusCode != 200) {
      return {
        "status": response.statusCode,
        "raw": response.body,
      };
    }

    final json = jsonDecode(response.body);

    // Yeni token kaydet
    if (json["Data"] != null && json["Data"]["Token"] != null) {
      if (prefs.getString(tokenKey) != loginToken)
        throw Exception('Oturum değişti. İşlemi tekrar deneyin.');
      await prefs.setString("token_final", json["Data"]["Token"]);
      await prefs.setInt("sirket_id", sirketId);
      await prefs.setInt("sube_id", subeId);
      await AuthorizationSession.instance
          .selectBranch(sirketId, subeId, admin: json['Data']['Admin'] == true);
      CariPlasiyerHelper.temizle();
      await _branchDefaults(prefs, oldScope, session.cacheScope);
    }

    return json;
  }

  /// Recover older installed sessions using only branches in the saved grants.
  Future<KullaniciDto> branchSelectionUser() async {
    final session = AuthorizationSession.instance;
    final envelope = await session.loginEnvelope();
    final allowed = {
      for (final row in envelope['rows'] as List)
        if (row['Subeid'] is int) row['Subeid'] as int
    };
    final choices = <int, Map<String, dynamic>>{
      for (final row in envelope['branchChoices'] as List? ?? [])
        if (row is Map &&
            allowed.contains(row['Id']) &&
            branchChoice(row) != null)
          row['Id']: branchChoice(row)!,
    };
    final prefs = await SharedPreferences.getInstance();
    final currentToken = prefs.getString('token_final') ?? '';
    final headers = {'Authorization': 'Bearer $currentToken'};
    final missing = allowed.where((id) => !choices.containsKey(id)).toList();
    final recovered = await Future.wait(missing.map((id) async {
      final response = await authorized.get(
          Uri.parse('${ApiConfig.baseUrl}/Sube/Sube/$id'),
          headers: headers);
      if (response.statusCode != 200)
        throw Exception('Şube listesi alınamadı. Tekrar deneyin.');
      final data = jsonDecode(utf8.decode(response.bodyBytes))['Data'];
      final choice = data is Map ? branchChoice(data) : null;
      if (choice == null || choice['Id'] != id)
        throw Exception('Şube bilgisi alınamadı.');
      return choice;
    }));
    if (prefs.getString('token_final') != currentToken)
      throw Exception('Oturum değişti. İşlemi tekrar deneyin.');
    for (final row in recovered) {
      choices[row['Id']] = row;
    }
    if (choices.isEmpty) throw Exception('Seçilebilecek şube bulunamadı.');
    if (missing.isNotEmpty)
      await session.rememberBranchChoices(choices.values.toList());
    final display = envelope['display'] as Map? ?? {};
    return KullaniciDto.fromJson({
      'Firmaid': envelope['firm'],
      'Admin': envelope['admin'] == true,
      'Kullaniciadi': display['user'] ?? prefs.getString('kullanici_adi'),
      'Firma': {'Ad': display['firm'] ?? prefs.getString('firma_adi')},
      'Yetki': [
        for (final choice in choices.values)
          {'Subeid': choice['Id'], 'Sube': choice}
      ],
    });
  }

  Future<void> _branchDefaults(
      SharedPreferences prefs, String? oldScope, String? newScope) async {
    if (oldScope == null || newScope == null || oldScope == newScope) return;
    const keys = [
      'varsayilan_depo_id',
      'ilk_depo_id_cache',
      'varsayilan_proje_id',
      'ilk_proje_id_cache'
    ];
    Map<String, dynamic> all;
    try {
      all = Map<String, dynamic>.from(
          jsonDecode(prefs.getString('branch_defaults_v1') ?? '{}'));
    } catch (_) {
      all = {};
    }
    all[oldScope] = {
      for (final key in keys)
        if (prefs.getInt(key) != null) key: prefs.getInt(key)
    };
    await prefs.setString('branch_defaults_v1', jsonEncode(all));
    final next = all[newScope] as Map? ?? {};
    for (final key in keys) {
      if (next[key] is int) {
        await prefs.setInt(key, next[key]);
      } else {
        await prefs.remove(key);
      }
    }
  }

  /// 🔵 4) Çıkış — sunucu tarafındaki oturumu düşürür (kullanıcı limiti için gerekli)
  Future<void> logout(String token) async {
    final logoutUrl = Uri.parse('${ApiConfig.baseUrl}/Login/Logout');
    await AuthorizationSession.instance.clear();
    final prefs = await SharedPreferences.getInstance();
    // Clear session identity only. Remembered credentials, theme, printer and
    // quick-access preferences belong to the device and survive logout.
    for (final key in [
      'token',
      'token_final',
      'firma_id',
      'sirket_id',
      'sube_id',
      'firma_adi',
      'sirket_adi',
      'sube_adi',
      'kullanici_adi'
    ]) {
      await prefs.remove(key);
    }
    if (token.isEmpty) return;
    try {
      await http.post(
        logoutUrl,
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      ).timeout(const Duration(seconds: 5));
    } catch (_) {
      // Ağ hatası/timeout — yerel çıkışı engellemesin, sessizce geç
    }
  }
}
