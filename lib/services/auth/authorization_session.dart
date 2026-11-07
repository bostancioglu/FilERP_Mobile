import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';
import '../../models/entities/yonetim/yetki_dto.dart';
import '../../helpers/response.dart';
import 'user_parameters.dart';
import '../../models/entities/yonetim/branch_choice.dart';

enum Access { authorized, read, create, update, delete, write }

class AuthorizationSession extends ChangeNotifier {
  static final instance = AuthorizationSession();
  static const _pendingKey = 'permission_login_v1';
  static const _activeKey = 'permission_active_v1';
  Map<int, YetkiDto> _permissions = {};
  bool _ready = false;
  String? _environment;
  String _account = '';
  int revision = 0;
  String? activeToken;
  UserParameters _parameters = const UserParameters();
  bool get automaticElectronicSend =>
      signedIn && _parameters.automaticElectronicSend;
  String? get cacheScope => signedIn && _account.isNotEmpty
      ? '$_environment:$_account:$companyId:$branchId'
      : null;
  int? branchId, companyId;
  bool get signedIn => _ready && _environment == ApiConfig.serverType.name;

  bool can(int module, [Access access = Access.authorized]) {
    if (!signedIn) return false;
    if (module == -1) return true;
    final row = _permissions[module];
    if (row == null) return false;
    return switch (access) {
      Access.authorized => true,
      Access.read => row.tumunuOkuma,
      Access.create => row.ekleme,
      Access.update => row.guncelleme,
      Access.delete => row.silme,
      Access.write => row.ekleme || row.guncelleme,
    };
  }

  bool any(Iterable<int> modules, [Access access = Access.authorized]) =>
      modules.any((id) => can(id, access));

  void require(int module, Access access) {
    if (!can(module, access)) throw const YetkiHatasi();
  }

  /// Only permission fields are retained; nested company credentials are omitted.
  Future<void> login(Map<String, dynamic> user) async {
    await deactivate();
    final rows = (user['Yetki'] as List? ?? [])
        .map((row) => YetkiDto.fromJson(Map<String, dynamic>.from(row))
            .toPermissionJson())
        .toList();
    final envelope = {
      'environment': ApiConfig.serverType.name,
      'user': user['Id']?.toString() ?? user['Kullaniciadi']?.toString(),
      'firm': user['Firmaid'],
      'rows': rows,
      'branchChoices': [
        for (final row in user['Yetki'] as List? ?? [])
          if (row is Map && row['Sube'] is Map && branchChoice(row) != null)
            branchChoice(row)
      ],
      'display': {
        'user': user['Kullaniciadi'],
        'firm': user['Firma'] is Map ? user['Firma']['Ad'] : null
      },
    };
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pendingKey, jsonEncode(envelope));
  }

  Future<void> selectBranch(int company, int branch) async {
    final prefs = await SharedPreferences.getInstance();
    final envelope = await loginEnvelope();
    if (!(envelope['rows'] as List).any((r) => r['Subeid'] == branch))
      throw const YetkiHatasi('Bu şubeye erişiminiz yok.');
    envelope['company'] = company;
    envelope['branch'] = branch;
    await prefs.setString(_activeKey, jsonEncode(envelope));
    activate(envelope['rows'] as List,
        branch: branch,
        company: company,
        environment: envelope['environment'] as String,
        account: '${envelope['firm']}:${envelope['user']}',
        token: prefs.getString('token_final'));
  }

  Future<Map<String, dynamic>> loginEnvelope() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey);
    if (raw == null)
      throw const YetkiHatasi('Yetki bilgisi eksik. Tekrar giriş yapın.');
    final envelope = Map<String, dynamic>.from(jsonDecode(raw));
    if (envelope['environment'] != ApiConfig.serverType.name ||
        envelope['firm'] != prefs.getInt('firma_id')) {
      throw const YetkiHatasi('Oturum değişti. Tekrar giriş yapın.');
    }
    return envelope;
  }

  Future<void> rememberBranchChoices(List<Map<String, dynamic>> choices) async {
    final envelope = await loginEnvelope();
    envelope['branchChoices'] = choices;
    await (await SharedPreferences.getInstance())
        .setString(_pendingKey, jsonEncode(envelope));
  }

  void activate(List rows,
      {required int branch,
      required int company,
      required String environment,
      String account = '',
      String? token}) {
    final permissions = <int, YetkiDto>{};
    for (final raw in rows) {
      final row = YetkiDto.fromJson(Map<String, dynamic>.from(raw));
      if (row.subeId == branch && row.modulAltId != null) {
        // AuthExtension uses the first matching branch/module record.
        permissions.putIfAbsent(row.modulAltId!, () => row);
      }
    }
    _permissions = permissions;
    branchId = branch;
    companyId = company;
    _environment = environment;
    _account = account;
    activeToken = token;
    _parameters = UserParameters.fromToken(token);
    _ready = true;
    revision++;
    notifyListeners();
  }

  Future<void> restore() async {
    reset();
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_activeKey);
    if (raw == null || (prefs.getString('token_final') ?? '').isEmpty) return;
    try {
      final data = jsonDecode(raw) as Map;
      if (data['environment'] != ApiConfig.serverType.name ||
          data['firm'] != prefs.getInt('firma_id') ||
          data['branch'] != prefs.getInt('sube_id') ||
          data['company'] != prefs.getInt('sirket_id')) return;
      activate(data['rows'] as List,
          branch: data['branch'] as int,
          company: data['company'] as int,
          environment: data['environment'] as String,
          account: '${data['firm']}:${data['user']}',
          token: prefs.getString('token_final'));
    } catch (_) {
      reset();
    }
  }

  void reset() {
    _permissions = {};
    branchId = companyId = null;
    _environment = null;
    _ready = false;
    _account = '';
    activeToken = null;
    _parameters = const UserParameters();
    revision++;
    notifyListeners();
  }

  Future<void> clear() async {
    reset();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingKey);
    await prefs.remove(_activeKey);
  }

  Future<void> deactivate() async {
    reset();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_activeKey);
    await prefs.remove('token_final');
  }
}
