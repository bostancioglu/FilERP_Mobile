import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:FilERP/services/auth/authorized_http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/api_config.dart';
import '../auth/authorization_session.dart';
import '../depo/dat/dat_service.dart';

/// Tek bir kuyruk kaydı
class OfflineQueueItem {
  final String localId;
  final String type; // "dat_full" | ...
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final String? ownerScope;
  String status; // "pending" | "sent" | "error"
  String? errorMessage;

  OfflineQueueItem({
    required this.localId,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.ownerScope,
    this.status = 'pending',
    this.errorMessage,
  });

  factory OfflineQueueItem.fromJson(Map<String, dynamic> j) => OfflineQueueItem(
        localId: j['localId'] as String,
        type: j['type'] as String,
        payload: Map<String, dynamic>.from(j['payload'] as Map),
        createdAt: DateTime.parse(j['createdAt'] as String),
        ownerScope: j['ownerScope'] as String?,
        status: j['status'] as String? ?? 'pending',
        errorMessage: j['errorMessage'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'type': type,
        'payload': payload,
        'createdAt': createdAt.toIso8601String(),
        'ownerScope': ownerScope,
        'status': status,
        'errorMessage': errorMessage,
      };
}

class BarcodeScanHistoryItem {
  final String localId;
  final int? belgeTuru;
  final String moduleKey;
  final String? belgeNo;
  final DateTime createdAt;
  final List<String> rawBarcodes;
  final List<Map<String, dynamic>> summary;

  BarcodeScanHistoryItem({
    required this.localId,
    required this.belgeTuru,
    required this.moduleKey,
    required this.belgeNo,
    required this.createdAt,
    required this.rawBarcodes,
    required this.summary,
  });

  factory BarcodeScanHistoryItem.fromJson(Map<String, dynamic> j) =>
      BarcodeScanHistoryItem(
        localId: j['localId'] as String,
        belgeTuru: j['belgeTuru'] as int?,
        moduleKey: j['moduleKey'] as String? ?? '',
        belgeNo: j['belgeNo'] as String?,
        createdAt: DateTime.parse(j['createdAt'] as String),
        rawBarcodes: (j['rawBarcodes'] as List<dynamic>? ?? [])
            .map((e) => e.toString())
            .toList(),
        summary: (j['summary'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        'localId': localId,
        'belgeTuru': belgeTuru,
        'moduleKey': moduleKey,
        'belgeNo': belgeNo,
        'createdAt': createdAt.toIso8601String(),
        'rawBarcodes': rawBarcodes,
        'summary': summary,
      };
}

/// ─── OfflineService ─────────────────────────────────────────────────────────
///
/// Kullanım:
///   await OfflineService.instance.init();          // main() içinde
///   OfflineService.instance.pendingCount.value     // bekleyen kayıt sayısı
///   OfflineService.instance.enqueue(type, payload) // kuyruğa ekle
///   OfflineService.instance.syncAll()              // elle sync başlat
/// ─────────────────────────────────────────────────────────────────────────────
class OfflineService {
  OfflineService._();
  static final OfflineService instance = OfflineService._();

  static const _boxName = 'offline_queue';
  static const _prefKey = 'offline_mode';
  static const _barcodeHistoryBoxName = 'barcode_scan_history';
  static const _kalemKaydetBekleme = Duration(milliseconds: 700);

  late Box<String> _box;
  late Box<String> _barcodeHistoryBox;
  StreamSubscription? _connectivitySub;

  bool _syncing = false;

  /// Bekleyen kayıt sayısı — UI bu ValueNotifier'ı dinler
  final ValueNotifier<int> pendingCount = ValueNotifier(0);

  /// Sync işlemi devam ediyor mu — UI bu ValueNotifier'ı dinler
  final ValueNotifier<bool> isSyncing = ValueNotifier(false);

  /// Anlık ağ bağlantısı var mı
  final ValueNotifier<bool> isOnline = ValueNotifier(true);

  /// Offline mod açık mı — UI bu ValueNotifier'ı dinler
  final ValueNotifier<bool> offlineMode = ValueNotifier(false);
  final ValueNotifier<int> barcodeHistoryCount = ValueNotifier(0);

  // ─── init ────────────────────────────────────────────────────────────────
  Future<void> init() async {
    _box = await Hive.openBox<String>(_boxName);
    _barcodeHistoryBox = await Hive.openBox<String>(_barcodeHistoryBoxName);
    _refreshCount();
    _refreshBarcodeHistoryCount();

    // Offline mod başlangıç değerini oku
    final prefs = await SharedPreferences.getInstance();
    offlineMode.value = prefs.getBool(_prefKey) ?? false;

    // Bağlantı durumunu dinle
    final connectivity = Connectivity();
    final result = await connectivity.checkConnectivity();
    isOnline.value = _connected(result);

    _connectivitySub = connectivity.onConnectivityChanged.listen((results) {
      final online = _connected(results);
      isOnline.value = online;
      if (online && !_syncing) syncAll();
    });
  }

  bool _connected(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);

  void dispose() {
    _connectivitySub?.cancel();
    pendingCount.dispose();
    isSyncing.dispose();
    isOnline.dispose();
    barcodeHistoryCount.dispose();
  }

  // ─── Offline Mode pref ──────────────────────────────────────────────────
  Future<bool> getOfflineMode() async {
    final p = await SharedPreferences.getInstance();
    return p.getBool(_prefKey) ?? false;
  }

  Future<void> setOfflineMode(bool val) async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_prefKey, val);
    offlineMode.value = val;
    // Online'a geçince otomatik sync
    if (!val && isOnline.value) syncAll();
  }

  // ─── Kuyruk işlemleri ────────────────────────────────────────────────────
  Future<void> enqueue(String type, Map<String, dynamic> payload) async {
    final item = OfflineQueueItem(
      localId: DateTime.now().microsecondsSinceEpoch.toString(),
      type: type,
      payload: payload,
      createdAt: DateTime.now(),
      ownerScope: AuthorizationSession.instance.cacheScope,
    );
    await _box.put(item.localId, jsonEncode(item.toJson()));
    _refreshCount();
  }

  List<OfflineQueueItem> getAll() {
    final items = <OfflineQueueItem>[];
    for (final raw in _box.values) {
      try {
        items.add(
            OfflineQueueItem.fromJson(jsonDecode(raw) as Map<String, dynamic>));
      } catch (_) {}
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  List<OfflineQueueItem> getPending() =>
      getAll().where((i) => i.status == 'pending').toList();

  Future<void> deleteItem(String localId) async {
    await _box.delete(localId);
    _refreshCount();
  }

  Future<void> clearSent() async {
    final keys = <String>[];
    for (final key in _box.keys) {
      final raw = _box.get(key as String);
      if (raw == null) continue;
      try {
        final m = jsonDecode(raw) as Map<String, dynamic>;
        if (m['status'] == 'sent') keys.add(key);
      } catch (_) {}
    }
    await _box.deleteAll(keys);
    _refreshCount();
  }

  void _refreshCount() {
    pendingCount.value = getPending().length;
  }

  Future<void> saveBarcodeScanHistory({
    required int? belgeTuru,
    required String moduleKey,
    String? belgeNo,
    required List<String> rawBarcodes,
    required List<Map<String, dynamic>> summary,
  }) async {
    final item = BarcodeScanHistoryItem(
      localId: DateTime.now().microsecondsSinceEpoch.toString(),
      belgeTuru: belgeTuru,
      moduleKey: moduleKey,
      belgeNo: belgeNo,
      createdAt: DateTime.now(),
      rawBarcodes: rawBarcodes,
      summary: summary,
    );
    await _barcodeHistoryBox.put(item.localId, jsonEncode(item.toJson()));
    _refreshBarcodeHistoryCount();
  }

  List<BarcodeScanHistoryItem> getBarcodeScanHistory({
    int? belgeTuru,
    String? moduleKey,
  }) {
    final items = <BarcodeScanHistoryItem>[];
    for (final raw in _barcodeHistoryBox.values) {
      try {
        final item = BarcodeScanHistoryItem.fromJson(
            jsonDecode(raw) as Map<String, dynamic>);
        final belgeUygun = belgeTuru == null || item.belgeTuru == belgeTuru;
        final modulUygun = moduleKey == null || item.moduleKey == moduleKey;
        if (belgeUygun && modulUygun) {
          items.add(item);
        }
      } catch (_) {}
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Future<void> deleteBarcodeScanHistoryItem(String localId) async {
    await _barcodeHistoryBox.delete(localId);
    _refreshBarcodeHistoryCount();
  }

  void _refreshBarcodeHistoryCount() {
    barcodeHistoryCount.value = _barcodeHistoryBox.length;
  }

  // ─── Sync ────────────────────────────────────────────────────────────────
  Future<void> syncAll() async {
    if (_syncing) return;
    _syncing = true;
    isSyncing.value = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final subeId = prefs.getInt('sube_id') ?? 0;
      if (token.isEmpty) return;

      final pending = getPending();
      for (int i = 0; i < pending.length; i++) {
        final item = pending[i];
        // Keep legacy/unowned records for manual review; never send them under
        // another user's, branch's or environment's credentials.
        if (item.ownerScope == null ||
            item.ownerScope != AuthorizationSession.instance.cacheScope)
          continue;
        try {
          await _process(token, subeId, item);
          item.status = 'sent';
        } catch (e) {
          item.status = 'error';
          item.errorMessage = e.toString();
        }
        await _box.put(item.localId, jsonEncode(item.toJson()));
        // Sunucuyu aşırı yüklememek için işlemler arası 1 sn bekle
        if (i < pending.length - 1) {
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    } finally {
      _refreshCount();
      _syncing = false;
      isSyncing.value = false;
    }
  }

  Future<void> retryItem(String localId) async {
    final raw = _box.get(localId);
    if (raw == null) return;
    final item =
        OfflineQueueItem.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    item.status = 'pending';
    item.errorMessage = null;
    await _box.put(localId, jsonEncode(item.toJson()));
    _refreshCount();
    await syncAll();
  }

  /// Mevcut bir kuyruk kaydının payload'ını güncelle (offline düzenleme)
  Future<void> updateQueueItem(
      String localId, Map<String, dynamic> newPayload) async {
    final raw = _box.get(localId);
    if (raw == null) return;
    final item =
        OfflineQueueItem.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    final updated = OfflineQueueItem(
      localId: item.localId,
      type: item.type,
      payload: newPayload,
      createdAt: item.createdAt,
      ownerScope: item.ownerScope,
      status: 'pending', // güncelleme → tekrar bekliyor
    );
    await _box.put(localId, jsonEncode(updated.toJson()));
    _refreshCount();
  }

  // ─── İşlem türleri ───────────────────────────────────────────────────────
  //
  // 'dat_full' / 'dat_status_change' / 'dat_delete': DAT modülüne özel,
  // belge numarası yeniden çekme gibi ek iş mantığı içerdiği için bespoke.
  //
  // Diğer TÜM modüller (Cari, Stok, Fatura, İrsaliye, Sipariş, Kasa/Banka
  // Hareket, Çek, Tahsilat, AmbarGC, ...) bu ikisinden birini kullanır —
  // ayrı bir case/handler yazmaya gerek yok, sayfa sadece doğru payload
  // şekliyle enqueue() çağırır:
  //
  //   'single_full' → { 'endpoint': '/Cari', 'body': dto.toJson() }
  //       Tek istekte kaydedilen her şey için (tekil kayıt ya da
  //       SaveWithItems gibi kalemleri zaten içinde barındıran istekler).
  //
  //   'header_hareket_full' → {
  //       'headerEndpoint': '/Fatura/SaveSingle',
  //       'hareketEndpoint': '/Faturahareket/SaveSingle',
  //       'headerIdField': 'faturaid',       // kalem DTO'sundaki üst belge id alanı
  //       'header': {...},                    // üst belge body'si
  //       'kalemler': [{...}, {...}],          // kalem body'leri (headerIdField hariç doldurulmuş)
  //     }
  //       Üst belge + kalem listesi şeklinde kaydedilen belgeler için.
  //       Üst belge kaydedilir, dönen Id kalemlerin headerIdField alanına
  //       yazılır, kalemler sırayla kaydedilir (DAT ile aynı akış).
  Future<void> _process(String token, int subeId, OfflineQueueItem item) async {
    switch (item.type) {
      case 'dat_full':
        await _processDatFull(token, subeId, item.payload);
        break;
      case 'dat_status_change':
        await _processDatStatusChange(token, item.payload);
        break;
      case 'dat_delete':
        await DatService().deleteDat(token, item.payload['datId'] as String);
        break;
      case 'single_full':
        await _processSingleFull(token, item.payload);
        break;
      case 'header_hareket_full':
        await _processHeaderHareketFull(token, item.payload);
        break;
      default:
        throw Exception('Bilinmeyen kuyruk tipi: ${item.type}');
    }
  }

  Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  /// Tek istekte kaydedilen genel amaçlı kayıtlar (Cari, Stok, Kasa/Banka
  /// Hareket, Kasa/Banka Tanım, Tahsilat, SaveWithItems ile giden Çekler vb.)
  ///
  /// `payload['method']` opsiyoneldir: 'POST' (varsayılan, yeni kayıt) veya
  /// 'PUT' (düzenleme) — online akışta hangisi kullanılıyorsa offline
  /// kuyruğa da aynısı yazılmalı, aksi halde düzenleme senkronda yeni kayıt
  /// olarak POST edilir.
  Future<void> _processSingleFull(
      String token, Map<String, dynamic> payload) async {
    final endpoint = payload['endpoint'] as String;
    final method = (payload['method'] as String?)?.toUpperCase() ?? 'POST';
    final body = Map<String, dynamic>.from(payload['body'] as Map);
    final uri = Uri.parse('$_apiBase$endpoint');
    final res = method == 'PUT'
        ? await http.put(uri, headers: _headers(token), body: jsonEncode(body))
        : await http.post(uri,
            headers: _headers(token), body: jsonEncode(body));
    if (res.statusCode != 200 && res.statusCode != 201) {
      throw Exception('Kayıt başarısız (HTTP ${res.statusCode}): ${res.body}');
    }
  }

  /// Üst belge + kalem listesi şeklindeki kayıtlar (Fatura, İrsaliye, Sipariş,
  /// AmbarGC, Çek üst bilgi+hareket ekranları vb.)
  Future<void> _processHeaderHareketFull(
      String token, Map<String, dynamic> payload) async {
    final headerEndpoint = payload['headerEndpoint'] as String;
    final hareketEndpoint = payload['hareketEndpoint'] as String;
    final headerIdField = payload['headerIdField'] as String;
    final header = Map<String, dynamic>.from(payload['header'] as Map);
    final kalemler = (payload['kalemler'] as List).cast<dynamic>();

    final headerRes = await http.post(
      Uri.parse('$_apiBase$headerEndpoint'),
      headers: _headers(token),
      body: jsonEncode(header),
    );
    if (headerRes.statusCode != 200 && headerRes.statusCode != 201) {
      throw Exception(
          'Belge kaydı başarısız (HTTP ${headerRes.statusCode}): ${headerRes.body}');
    }
    final decoded = jsonDecode(utf8.decode(headerRes.bodyBytes));
    final headerId =
        decoded is Map ? (decoded['Data'] ?? decoded['data']) : null;
    if (headerId == null)
      throw Exception('Belge kaydedildi ama dönen Id okunamadı.');

    for (int i = 0; i < kalemler.length; i++) {
      final km = Map<String, dynamic>.from(kalemler[i] as Map);
      km[headerIdField] = headerId;
      final kRes = await http.post(
        Uri.parse('$_apiBase$hareketEndpoint'),
        headers: _headers(token),
        body: jsonEncode(km),
      );
      if (kRes.statusCode != 200 && kRes.statusCode != 201) {
        throw Exception(
            '${i + 1}. kalem kaydı başarısız (HTTP ${kRes.statusCode}): ${kRes.body}');
      }
      if (i < kalemler.length - 1) {
        await Future.delayed(_kalemKaydetBekleme);
      }
    }
  }

  String get _apiBase => ApiConfig.baseUrl;

  Future<void> _processDatFull(
      String token, int subeId, Map<String, dynamic> payload) async {
    final svc = DatService();
    final datPayload = Map<String, dynamic>.from(payload['dat'] as Map);

    // 1. Taze belge numarası çek — offline sırasında başkası aynı numarayı almış olabilir
    final seri = datPayload['belgeseri'] as String?;
    final yil = datPayload['belgeyil'] as int? ?? DateTime.now().year;
    if (seri != null && seri.isNotEmpty) {
      try {
        final yeniNo = await svc.getNewDatNo(token, seri, yil);
        datPayload['belgeno'] = yeniNo;
      } catch (_) {
        // numara çekilemezse mevcut devam eder
      }
    }

    // 2. DAT başlığını kaydet
    final datId = await svc.saveSingle(token, datPayload);

    // 3. Kalemleri sırayla kaydet
    final kalemler = payload['kalemler'] as List<dynamic>;
    for (int i = 0; i < kalemler.length; i++) {
      final k = kalemler[i];
      final km = Map<String, dynamic>.from(k as Map);
      km['datid'] = datId;
      km['cikacagisubeid'] = subeId;
      km['gidecegisubeid'] = datPayload['gidecegisubeid'];
      await svc.saveHareket(token, km);
      if (i < kalemler.length - 1) {
        await Future.delayed(_kalemKaydetBekleme);
      }
    }
  }

  Future<void> _processDatStatusChange(
      String token, Map<String, dynamic> payload) async {
    final datId = payload['datId'] as String;
    final durum = payload['durum'] as int;
    await DatService().belgeDurumGuncelle(token, datId, durum);
  }
}
