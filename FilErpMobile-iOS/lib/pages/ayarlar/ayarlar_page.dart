import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:FilERP/widgets/corporate_menu_icon.dart';
import '../../theme/app_theme.dart';
import '../../widgets/erp_page_style.dart';
import 'tema_secim_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../helpers/belge_turu_couples.dart';
import '../../helpers/weighted_barcode_helper.dart';
import '../../services/offline/offline_service.dart';
import '../../services/update/update_service.dart';
import '../../models/entities/depo/depo_dto.dart';
import '../../services/depo/depo_service.dart';
import '../../helpers/varsayilan_depo_helper.dart';
import '../../models/entities/finans/kasa_islem/kasa_dto.dart';
import '../../services/finans/kasa_tanim_service.dart';
import '../../helpers/varsayilan_kasa_helper.dart';
import '../../models/entities/proje/proje_dto.dart';
import '../../services/proje/proje_service.dart';
import '../../helpers/varsayilan_proje_helper.dart';
import '../../widgets/erp_selector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../depo/dat/dat_ekle_page.dart';

enum _UpdateState {
  idle,
  checking,
  upToDate,
  updateAvailable,
  downloading,
  error
}

class AyarlarPage extends StatefulWidget {
  const AyarlarPage({super.key});

  @override
  State<AyarlarPage> createState() => _AyarlarPageState();
}

class _AyarlarPageState extends State<AyarlarPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.onSurface;
  Color get _accent => _scheme.primary;
  Color get _positive => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFF6EE7B7)
      : Color(0xFF16704A);

  final _svc = OfflineService.instance;

  bool _offlineMode = false;
  bool _loading = true;
  List<OfflineQueueItem> _items = [];
  List<BarcodeScanHistoryItem> _barcodeHistory = [];
  List<WeightedBarcodeRule> _weightedRules = [];

  /// Her grubun açık/kapalı durumu (key → expanded)
  final Map<String, bool> _expandedGroups = {};

  // ── Versiyon / güncelleme durumu ─────────────────────────────────────────
  _UpdateState _updateState = _UpdateState.idle;
  UpdateInfo? _updateInfo;
  String? _updateError;
  String _currentVersion = '';

  @override
  void initState() {
    super.initState();
    _load();
    _svc.pendingCount.addListener(_reload);
    _svc.isSyncing.addListener(_reload);
    _svc.offlineMode.addListener(_onOfflineModeChanged);
    _svc.barcodeHistoryCount.addListener(_reload);
    _loadVarsayilanDepo();
    _loadVarsayilanKasa();
    _loadVarsayilanProje();
  }

  // ── Varsayılan proje ─────────────────────────────────────────────────────
  ProjeDto? _varsayilanProje;
  List<ProjeDto> _projeler = [];
  bool _projeYukleniyor = false;

  Future<List<ProjeDto>> _projeleriGetir() async {
    if (_projeler.isNotEmpty) return _projeler;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    _projeler = await ProjeService().getProjeList(token);
    return _projeler;
  }

  Future<void> _loadVarsayilanProje() async {
    final id = await VarsayilanProjeHelper.getSecilenId();
    if (id == null) return;
    try {
      final liste = await _projeleriGetir();
      final bulunan = liste.where((p) => p.id == id).firstOrNull;
      if (mounted) setState(() => _varsayilanProje = bulunan);
    } catch (_) {}
  }

  Future<void> _varsayilanProjeSec() async {
    setState(() => _projeYukleniyor = true);
    List<ProjeDto> liste;
    try {
      liste = await _projeleriGetir();
    } catch (e) {
      if (mounted) {
        setState(() => _projeYukleniyor = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Proje listesi alınamadı: $e")));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _projeYukleniyor = false);
    final secilen = await showErpSelector<ProjeDto>(
      context: context,
      title: "Varsayılan Proje",
      hintText: "Proje Kodu veya Adı...",
      items: liste,
      itemText: (p) => "${p.kod ?? ''} - ${p.ad ?? ''}",
    );
    if (secilen == null || secilen.id == null) return;
    await VarsayilanProjeHelper.setSecilenId(secilen.id);
    if (mounted) setState(() => _varsayilanProje = secilen);
  }

  Future<void> _varsayilanProjeTemizle() async {
    await VarsayilanProjeHelper.setSecilenId(null);
    if (mounted) setState(() => _varsayilanProje = null);
  }

  Widget _settingRow(
          {required IconData icon,
          required String title,
          String? value,
          VoidCallback? onTap,
          Widget? trailing}) =>
      Material(
        color: _scheme.surface,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
                color: _scheme.outlineVariant.withValues(alpha: .6))),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
            onTap: onTap,
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(children: [
                  Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                          color: _accent.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(9)),
                      child:
                          CorporateMenuIcon(title, size: 25, fallback: icon)),
                  SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(title,
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 13,
                                fontWeight: FontWeight.w600)),
                        if (value != null)
                          Text(value,
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11,
                                  color: _scheme.onSurfaceVariant))
                      ])),
                  if (trailing != null)
                    trailing
                  else
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: _scheme.onSurfaceVariant),
                ]))),
      );
  Widget _defaultRow(
          {required IconData icon,
          required String title,
          String? value,
          required bool loading,
          required VoidCallback select,
          required VoidCallback clear}) =>
      _settingRow(
          icon: icon,
          title: title,
          value: value ?? 'Seçilmedi',
          onTap: loading ? null : select,
          trailing: loading
              ? SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : value == null
                  ? null
                  : IconButton(
                      tooltip: '$title Temizle',
                      onPressed: clear,
                      icon: Icon(Icons.close_rounded, size: 18)));
  Widget _buildVarsayilanProjeKarti() => _defaultRow(
      icon: Icons.folder_special_outlined,
      title: 'Varsayılan Proje',
      value: _varsayilanProje == null
          ? null
          : '${_varsayilanProje!.kod ?? ''} - ${_varsayilanProje!.ad ?? ''}',
      loading: _projeYukleniyor,
      select: _varsayilanProjeSec,
      clear: _varsayilanProjeTemizle);

  // ── Varsayılan depo ──────────────────────────────────────────────────────
  DepoDto? _varsayilanDepo;
  List<DepoDto> _depolar = [];
  bool _depoYukleniyor = false;

  Future<List<DepoDto>> _depolariGetir() async {
    if (_depolar.isNotEmpty) return _depolar;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    _depolar = await DepoService().getDepoList(token);
    return _depolar;
  }

  Future<void> _loadVarsayilanDepo() async {
    final id = await VarsayilanDepoHelper.getSecilenId();
    if (id == null) return;
    try {
      final liste = await _depolariGetir();
      final bulunan = liste.where((d) => d.id == id).firstOrNull;
      if (mounted) setState(() => _varsayilanDepo = bulunan);
    } catch (_) {}
  }

  Future<void> _varsayilanDepoSec() async {
    setState(() => _depoYukleniyor = true);
    List<DepoDto> liste;
    try {
      liste = await _depolariGetir();
    } catch (e) {
      if (mounted) {
        setState(() => _depoYukleniyor = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Depo listesi alınamadı: $e")));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _depoYukleniyor = false);
    final secilen = await showErpSelector<DepoDto>(
      context: context,
      title: "Varsayılan Depo",
      hintText: "Depo Kodu veya Adı...",
      items: liste,
      itemText: (d) => "${d.kod ?? ''} - ${d.ad ?? ''}",
    );
    if (secilen == null || secilen.id == null) return;
    await VarsayilanDepoHelper.setSecilenId(secilen.id);
    if (mounted) setState(() => _varsayilanDepo = secilen);
  }

  Future<void> _varsayilanDepoTemizle() async {
    await VarsayilanDepoHelper.setSecilenId(null);
    if (mounted) setState(() => _varsayilanDepo = null);
  }

  Widget _buildVarsayilanDepoKarti() => _defaultRow(
      icon: Icons.warehouse_outlined,
      title: 'Varsayılan Depo',
      value: _varsayilanDepo == null
          ? null
          : '${_varsayilanDepo!.kod ?? ''} - ${_varsayilanDepo!.ad ?? ''}',
      loading: _depoYukleniyor,
      select: _varsayilanDepoSec,
      clear: _varsayilanDepoTemizle);

  // ── Varsayılan kasa (plasiyer kasası otomatik bulunamazsa yedek) ──────────
  KasaDto? _varsayilanKasa;
  List<KasaDto> _kasalar = [];
  bool _kasaYukleniyor = false;

  Future<List<KasaDto>> _kasalariGetir() async {
    if (_kasalar.isNotEmpty) return _kasalar;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    _kasalar = await KasaTanimService().getAllWithoutAuth(token);
    return _kasalar;
  }

  Future<void> _loadVarsayilanKasa() async {
    final id = await VarsayilanKasaHelper.getSecilenId();
    if (id == null) return;
    try {
      final liste = await _kasalariGetir();
      final bulunan = liste.where((k) => k.Id == id).firstOrNull;
      if (mounted) setState(() => _varsayilanKasa = bulunan);
    } catch (_) {}
  }

  Future<void> _varsayilanKasaSec() async {
    setState(() => _kasaYukleniyor = true);
    List<KasaDto> liste;
    try {
      liste = await _kasalariGetir();
    } catch (e) {
      if (mounted) {
        setState(() => _kasaYukleniyor = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Kasa listesi alınamadı: $e")));
      }
      return;
    }
    if (!mounted) return;
    setState(() => _kasaYukleniyor = false);
    final secilen = await showErpSelector<KasaDto>(
      context: context,
      title: "Varsayılan Kasa",
      hintText: "Kasa Kodu veya Adı...",
      items: liste,
      itemText: (k) => "${k.Kod ?? ''} - ${k.Ad ?? ''}",
    );
    if (secilen == null || secilen.Id == null) return;
    await VarsayilanKasaHelper.setSecilenId(secilen.Id);
    if (mounted) setState(() => _varsayilanKasa = secilen);
  }

  Future<void> _varsayilanKasaTemizle() async {
    await VarsayilanKasaHelper.setSecilenId(null);
    if (mounted) setState(() => _varsayilanKasa = null);
  }

  Widget _buildVarsayilanKasaKarti() => _defaultRow(
      icon: Icons.account_balance_wallet_outlined,
      title: 'Varsayılan Kasa',
      value: _varsayilanKasa == null
          ? null
          : '${_varsayilanKasa!.Kod ?? ''} - ${_varsayilanKasa!.Ad ?? ''}',
      loading: _kasaYukleniyor,
      select: _varsayilanKasaSec,
      clear: _varsayilanKasaTemizle);

  @override
  void dispose() {
    _svc.pendingCount.removeListener(_reload);
    _svc.isSyncing.removeListener(_reload);
    _svc.offlineMode.removeListener(_onOfflineModeChanged);
    _svc.barcodeHistoryCount.removeListener(_reload);
    super.dispose();
  }

  void _onOfflineModeChanged() {
    if (mounted) setState(() => _offlineMode = _svc.offlineMode.value);
  }

  void _reload() {
    if (mounted) {
      setState(() {
        _items = _svc.getAll();
        _barcodeHistory = _svc.getBarcodeScanHistory();
      });
    }
  }

  Future<void> _load() async {
    await WeightedBarcodeHelper.ensureLoaded();
    final pkgInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _offlineMode = _svc.offlineMode.value;
        _items = _svc.getAll();
        _barcodeHistory = _svc.getBarcodeScanHistory();
        _weightedRules = WeightedBarcodeHelper.getCachedRules();
        _currentVersion = pkgInfo.version;
        _loading = false;
      });
    }

    // Giriş akışından gelen otomatik güncelleme bayrağı
    final pending = UpdateService.instance.pendingAutoInstall;
    if (pending != null && mounted) {
      UpdateService.instance.pendingAutoInstall = null; // bayrağı temizle
      setState(() {
        _updateInfo = pending;
        _updateState = _UpdateState.updateAvailable;
      });
      // Kısa gecikme sonrası indirmeyi otomatik başlat
      await Future.delayed(Duration(milliseconds: 600));
      if (mounted) _startDownload();
    }
  }

  // ── Güncelleme işlemleri ─────────────────────────────────────────────────
  Future<void> _checkUpdate() async {
    setState(() {
      _updateState = _UpdateState.checking;
      _updateError = null;
    });
    try {
      final info = await UpdateService.instance.checkForUpdate();
      if (!mounted) return;
      if (info != null) {
        setState(() {
          _updateState = _UpdateState.updateAvailable;
          _updateInfo = info;
        });
      } else {
        setState(() => _updateState = _UpdateState.upToDate);
        Future.delayed(Duration(seconds: 3), () {
          if (mounted && _updateState == _UpdateState.upToDate) {
            setState(() => _updateState = _UpdateState.idle);
          }
        });
      }
    } catch (e) {
      if (mounted)
        setState(() {
          _updateState = _UpdateState.error;
          _updateError = e.toString();
        });
    }
  }

  Future<void> _startDownload() async {
    if (_updateInfo == null) return;
    setState(() => _updateState = _UpdateState.downloading);
    try {
      await UpdateService.instance.downloadAndInstall(_updateInfo!);
      if (mounted) setState(() => _updateState = _UpdateState.idle);
    } catch (e) {
      if (mounted)
        setState(() {
          _updateState = _UpdateState.error;
          _updateError = e.toString();
        });
    }
  }

  Future<void> _toggleOffline(bool val) async {
    setState(() => _offlineMode = val);
    await _svc.setOfflineMode(val);
  }

  String _formatQuantity(double value) {
    final text = value.toStringAsFixed(4);
    final trimmed =
        text.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\\.$'), '');
    return trimmed.replaceAll('.', ',');
  }

  // ─── BUILD ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        title: Text("Ayarlar",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        actions: [
          if (_svc.isSyncing.value)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                  child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _accent))),
            )
          else
            IconButton(
              icon: Icon(Icons.sync_rounded),
              tooltip: "Şimdi Senkronize Et",
              onPressed: () async {
                await _svc.syncAll();
                if (mounted) setState(() => _items = _svc.getAll());
              },
            ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  Container(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _scheme.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _scheme.outlineVariant),
                      ),
                      child: ErpAdaptiveTabs(
                          context: context,
                          tabBar: TabBar(
                            labelColor: _primary,
                            unselectedLabelColor: _scheme.onSurfaceVariant,
                            indicatorColor: _accent,
                            tabs: [
                              Tab(text: "Genel"),
                              Tab(text: "Kuyruk"),
                              Tab(text: "Barkod"),
                            ],
                          )),
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        ListView(
                          padding: EdgeInsets.all(12),
                          children: [
                            Card(
                                child: ListTile(
                              leading: const CorporateMenuIcon('Tema Seçimi',
                                  size: 28),
                              title: const Text('Tema Seçimi'),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.push(
                                  context,
                                  PermissionMaterialPageRoute(
                                      builder: (_) => const TemaSecimPage())),
                            )),
                            SizedBox(height: 8),
                            _buildBaglantiKarti(),
                            SizedBox(height: 8),
                            _buildOfflineToggle(),
                            SizedBox(height: 8),
                            _buildVarsayilanDepoKarti(),
                            SizedBox(height: 8),
                            _buildVarsayilanKasaKarti(),
                            SizedBox(height: 8),
                            _buildVarsayilanProjeKarti(),
                            SizedBox(height: 8),
                            _buildVersionCard(),
                            SizedBox(height: 24),
                          ],
                        ),
                        ListView(
                          padding: EdgeInsets.all(12),
                          children: [
                            _buildKuyrukBaslik(),
                            SizedBox(height: 8),
                            if (_items.isEmpty)
                              _buildKuyrukBos()
                            else
                              ..._buildGroupedQueue(),
                            if (_items.any((i) => i.status == 'sent')) ...[
                              SizedBox(height: 8),
                              _buildClearSentBtn(),
                            ],
                            SizedBox(height: 24),
                          ],
                        ),
                        ListView(
                          padding: EdgeInsets.all(12),
                          children: [
                            _buildWeightedBarcodeSection(),
                            SizedBox(height: 20),
                            _buildBarcodeHistorySection(),
                            SizedBox(height: 24),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // ─── VERSİYON / GÜNCELLEME KARTI ────────────────────────────────────────
  Widget _buildVersionCard() {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: Offset(0, 3))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Başlık satırı ────────────────────────────────────────────────
        Row(children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const CorporateMenuIcon('Güncelleme', size: 28),
          ),
          SizedBox(width: 14),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text("Uygulama Versiyonu",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        fontSize: 13)),
                SizedBox(height: 2),
                Text("Mevcut: $_currentVersion",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: _scheme.onSurfaceVariant)),
              ])),
          // Kontrol butonu veya durum göstergesi
          _buildUpdateActionChip(),
        ]),

        // ── Güncelleme mevcut ─────────────────────────────────────────────
        if (_updateState == _UpdateState.updateAvailable &&
            _updateInfo != null) ...[
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _accent.withValues(alpha: .3)),
            ),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.new_releases_rounded, size: 16, color: _accent),
                SizedBox(width: 6),
                Text("Yeni versiyon: ${_updateInfo!.versionName}",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: _accent)),
              ]),
              if (_updateInfo!.releaseNotes.isNotEmpty) ...[
                SizedBox(height: 6),
                Text(_updateInfo!.releaseNotes,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: _accent,
                        height: 1.5)),
              ],
              SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _startDownload,
                  icon: Icon(Icons.download_rounded, size: 16),
                  label: Text("Güncellemeyi İndir",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: _scheme.onPrimary,
                    padding: EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ]),
          ),
        ],

        // ── İndirme ilerlemesi ────────────────────────────────────────────
        if (_updateState == _UpdateState.downloading) ...[
          SizedBox(height: 8),
          ValueListenableBuilder<double?>(
            valueListenable: UpdateService.instance.downloadProgress,
            builder: (_, progress, __) {
              final pct = progress != null ? (progress * 100).toInt() : 0;
              return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Icon(Icons.download_rounded, size: 14, color: _accent),
                      SizedBox(width: 6),
                      Text("İndiriliyor... %$pct",
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: _accent,
                              fontWeight: FontWeight.w500)),
                    ]),
                    SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: _accent.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(_accent),
                      ),
                    ),
                  ]);
            },
          ),
        ],

        // ── Hata ─────────────────────────────────────────────────────────
        if (_updateState == _UpdateState.error && _updateError != null) ...[
          SizedBox(height: 10),
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _scheme.error.withValues(alpha: .08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.error_outline_rounded, size: 14, color: _scheme.error),
              SizedBox(width: 8),
              Expanded(
                  child: Text(_updateError!,
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: _scheme.error,
                          height: 1.4))),
            ]),
          ),
          SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _checkUpdate,
            icon: Icon(Icons.refresh_rounded, size: 14),
            label: Text("Tekrar Dene",
                style: TextStyle(fontFamily: 'Roboto', fontSize: 12)),
            style: OutlinedButton.styleFrom(
              foregroundColor: _accent,
              side: BorderSide(color: _accent.withOpacity(0.5)),
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildUpdateActionChip() {
    switch (_updateState) {
      case _UpdateState.checking:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: _accent)),
            SizedBox(width: 6),
            Text("Kontrol ediliyor...",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: _scheme.onSurfaceVariant)),
          ]),
        );

      case _UpdateState.upToDate:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _positive.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.check_circle_rounded, size: 14, color: _positive),
            SizedBox(width: 4),
            Text("Güncel",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _positive)),
          ]),
        );

      case _UpdateState.updateAvailable:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _accent.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.arrow_circle_up_rounded, size: 14, color: _accent),
            SizedBox(width: 4),
            Text("Güncelleme var",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _accent)),
          ]),
        );

      case _UpdateState.downloading:
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(
                    strokeWidth: 1.5, color: _accent)),
            SizedBox(width: 6),
            Text("İndiriliyor",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _accent)),
          ]),
        );

      default: // idle veya error
        return TextButton.icon(
          onPressed: _updateState == _UpdateState.error ? null : _checkUpdate,
          icon: Icon(Icons.refresh_rounded, size: 14, color: _accent),
          label: Text("Kontrol Et",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: _accent,
                  fontWeight: FontWeight.w500)),
          style: TextButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        );
    }
  }

  // ─── BAĞLANTI KARTI ───────────────────────────────────────────────────────
  Widget _buildBaglantiKarti() => ValueListenableBuilder<bool>(
      valueListenable: _svc.isOnline,
      builder: (_, online, __) => _settingRow(
          icon: online ? Icons.wifi_rounded : Icons.wifi_off_rounded,
          title: 'Bağlantı',
          value: online ? 'Çevrimiçi' : 'Çevrimdışı',
          trailing: ValueListenableBuilder<int>(
              valueListenable: _svc.pendingCount,
              builder: (_, count, __) => Text('$count bekliyor',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: _scheme.onSurfaceVariant)))));
  Widget _buildOfflineToggle() => _settingRow(
      icon: Icons.cloud_off_outlined,
      title: 'Çevrimdışı Mod',
      value: _offlineMode ? 'Açık' : 'Kapalı',
      trailing: Switch(value: _offlineMode, onChanged: _toggleOffline));

  // ─── KUYRUK BAŞLIĞI ───────────────────────────────────────────────────────
  Widget _buildKuyrukBaslik() {
    return Row(children: [
      Container(
          width: 3,
          height: 18,
          decoration: BoxDecoration(
              color: _accent, borderRadius: BorderRadius.circular(2))),
      SizedBox(width: 10),
      Text("Senkronizasyon Kuyruğu",
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _primary)),
      Spacer(),
      ValueListenableBuilder<bool>(
        valueListenable: _svc.isSyncing,
        builder: (_, syncing, __) => syncing
            ? Row(children: [
                SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: _accent)),
                SizedBox(width: 6),
                Text("Gönderiliyor...",
                    style: TextStyle(
                        fontFamily: 'Roboto', fontSize: 11, color: _accent)),
              ])
            : SizedBox.shrink(),
      ),
    ]);
  }

  // ─── KUYRUK BOŞ ───────────────────────────────────────────────────────────
  Widget _buildKuyrukBos() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 32),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)
        ],
      ),
      child: Column(children: [
        Icon(Icons.check_circle_outline_rounded,
            size: 48, color: _positive.withValues(alpha: .3)),
        SizedBox(height: 10),
        Text("Kuyruk boş",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13,
                color: _scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
        SizedBox(height: 4),
      ]),
    );
  }

  // ─── GRUP TANIMI ─────────────────────────────────────────────────────────
  List<Map<String, dynamic>> get _gruplar => [
        {
          'key': 'dat',
          'label': 'DAT',
          'subtitle': 'Depolar Arası Transfer',
          'icon': Icons.swap_horiz_rounded,
          'types': <String>['dat_full', 'dat_status_change', 'dat_delete'],
        },
        // İleride yeni modüller buraya eklenebilir
      ];

  // ─── GRUPLU KUYRUK ───────────────────────────────────────────────────────
  List<Widget> _buildGroupedQueue() {
    final widgets = <Widget>[];

    // Tanımlı grupları işle
    final handledLocalIds = <String>{};
    for (final grup in _gruplar) {
      final types = grup['types'] as List<String>;
      final grupItems = _items.where((i) => types.contains(i.type)).toList();
      if (grupItems.isEmpty) continue;
      for (final i in grupItems) handledLocalIds.add(i.localId);
      widgets.add(_buildGroupCard(
        groupKey: grup['key'] as String,
        label: grup['label'] as String,
        subtitle: grup['subtitle'] as String,
        icon: grup['icon'] as IconData,
        items: grupItems,
      ));
      widgets.add(SizedBox(height: 8));
    }

    // Hiçbir gruba girmeyen bilinmeyen tipler
    final diger =
        _items.where((i) => !handledLocalIds.contains(i.localId)).toList();
    if (diger.isNotEmpty) {
      widgets.add(_buildGroupCard(
        groupKey: 'diger',
        label: 'Diğer',
        subtitle: 'Bilinmeyen işlemler',
        icon: Icons.more_horiz_rounded,
        items: diger,
      ));
      widgets.add(SizedBox(height: 8));
    }

    return widgets;
  }

  Widget _buildGroupCard({
    required String groupKey,
    required String label,
    required String subtitle,
    required IconData icon,
    required List<OfflineQueueItem> items,
  }) {
    final pendingCnt = items.where((i) => i.status == 'pending').length;
    final errorCnt = items.where((i) => i.status == 'error').length;
    final hasBorder = errorCnt > 0;

    return Container(
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: Offset(0, 2))
        ],
        border: hasBorder
            ? Border.all(color: _scheme.error.withValues(alpha: .3))
            : null,
      ),
      child: Theme(
        // ExpansionTile'ın default ayırıcılarını kaldır
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _expandedGroups[groupKey] ?? true,
          onExpansionChanged: (v) =>
              setState(() => _expandedGroups[groupKey] = v),
          tilePadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          childrenPadding: EdgeInsets.fromLTRB(14, 0, 14, 6),
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          shape: Border(), // köşe çizgisi çıkmasın
          collapsedShape: Border(),
          title: Row(children: [
            // Modül ikonu
            Container(
              padding: EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: CorporateMenuIcon(label, size: 26, fallback: icon),
            ),
            SizedBox(width: 12),
            // Başlık
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _primary)),
                  Text(subtitle,
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: _scheme.onSurfaceVariant)),
                ])),
            SizedBox(width: 8),
            // Pending badge
            if (pendingCnt > 0)
              Container(
                margin: EdgeInsets.only(right: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("$pendingCnt bekliyor",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _accent)),
              ),
            // Error badge
            if (errorCnt > 0)
              Container(
                margin: EdgeInsets.only(right: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _scheme.error.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text("$errorCnt hata",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: _scheme.error)),
              ),
            // Sent-only: yeşil checkmark
            if (pendingCnt == 0 && errorCnt == 0)
              Container(
                margin: EdgeInsets.only(right: 4),
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _positive.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.check_circle_outline_rounded,
                      size: 12, color: _positive),
                  SizedBox(width: 4),
                  Text("Tümü gönderildi",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _positive)),
                ]),
              ),
          ]),
          // Grup içindeki kartlar
          children: items.map(_buildQueueCard).toList(),
        ),
      ),
    );
  }

  // ─── KUYRUK KARTI ─────────────────────────────────────────────────────────
  Widget _buildQueueCard(OfflineQueueItem item) {
    final isPending = item.status == 'pending';
    final isError = item.status == 'error';
    final isSent = item.status == 'sent';

    final statusColor = isPending
        ? _accent
        : isError
            ? _scheme.error
            : _positive;

    final statusBg = isPending
        ? _accent.withValues(alpha: .08)
        : isError
            ? _scheme.error.withValues(alpha: .08)
            : _positive.withValues(alpha: .08);

    final statusText = isPending
        ? "Bekliyor"
        : isError
            ? "Hata"
            : "Gönderildi";

    final statusIcon = isPending
        ? Icons.hourglass_empty_rounded
        : isError
            ? Icons.error_outline_rounded
            : Icons.check_circle_rounded;

    final typeLabel = _typeLabel(item.type);
    final dateFmt = DateFormat('dd.MM.yyyy HH:mm');

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
        border: isError
            ? Border.all(color: _scheme.error.withValues(alpha: .3))
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            // Tip ikonu
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.swap_horiz_rounded, color: _accent, size: 18),
            ),
            SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(typeLabel,
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: _primary)),
                  SizedBox(height: 2),
                  Text(dateFmt.format(item.createdAt),
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          color: _scheme.onSurfaceVariant)),
                ])),
            // Durum badge
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: statusBg, borderRadius: BorderRadius.circular(8)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(statusIcon, size: 12, color: statusColor),
                SizedBox(width: 4),
                Text(statusText,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
              ]),
            ),
          ]),
          // Hata mesajı
          if (isError && item.errorMessage != null) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _scheme.error.withValues(alpha: .08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(item.errorMessage!,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: _scheme.error,
                      height: 1.4)),
            ),
          ],
          if (!isSent)
            Align(
                alignment: Alignment.centerRight,
                child: PopupMenuButton<String>(
                  tooltip: 'Kayıt İşlemleri',
                  icon: const Icon(Icons.more_horiz_rounded),
                  onSelected: (action) async {
                    if (action == 'edit') {
                      final result = await _openEditor(item);
                      if (result == true && mounted)
                        setState(() => _items = _svc.getAll());
                    }
                    if (action == 'retry') {
                      await _svc.retryItem(item.localId);
                      if (mounted) setState(() => _items = _svc.getAll());
                    }
                    if (action == 'delete') {
                      final ok = await showDialog<bool>(
                          context: context,
                          builder: (_) => AlertDialog(
                                  title: const Text('Kaydı Sil'),
                                  content: const Text(
                                      'Bu çevrimdışı kayıt silinecek. Devam edilsin mi?'),
                                  actions: [
                                    ErpDialogAction(
                                        onPressed: () =>
                                            Navigator.pop(context, false),
                                        child: const Text('İptal')),
                                    ErpDialogAction(
                                        onPressed: () =>
                                            Navigator.pop(context, true),
                                        child: const Text('Sil'))
                                  ]));
                      if (ok == true) {
                        await _svc.deleteItem(item.localId);
                        if (mounted) setState(() => _items = _svc.getAll());
                      }
                    }
                  },
                  itemBuilder: (_) => [
                    if (isError && _canEdit(item.type))
                      const PopupMenuItem(
                          value: 'edit', child: Text('Düzenle')),
                    if (isError)
                      const PopupMenuItem(
                          value: 'retry', child: Text('Tekrar Dene')),
                    const PopupMenuItem(value: 'delete', child: Text('Sil')),
                  ],
                )),
        ]),
      ),
    );
  }

  /// Bu kuyruk tipi için düzenleme ekranı var mı?
  bool _canEdit(String type) => type == 'dat_full';

  /// İlgili düzenleme sayfasını aç, sonucu döndür
  Future<bool?> _openEditor(OfflineQueueItem item) {
    switch (item.type) {
      case 'dat_full':
        return Navigator.push<bool>(
            context,
            PermissionMaterialPageRoute(
                builder: (_) => DatEklePage(queueItem: item)));
      default:
        return Future.value(null);
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'dat_full':
        return 'DAT — Depolar Arası Transfer';
      case 'dat_status_change':
        return 'DAT — Durum Değişikliği';
      case 'dat_delete':
        return 'DAT — Silme';
      default:
        return type;
    }
  }

  Widget _buildClearSentBtn() {
    return TextButton.icon(
      onPressed: () async {
        await _svc.clearSent();
        setState(() => _items = _svc.getAll());
      },
      icon: Icon(Icons.cleaning_services_rounded,
          size: 16, color: _scheme.onSurfaceVariant),
      label: Text("Gönderilenleri Temizle",
          style: TextStyle(
              fontFamily: 'Roboto',
              color: _scheme.onSurfaceVariant,
              fontSize: 12)),
    );
  }

  Widget _buildWeightedBarcodeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 10),
          Text(
            "Tartılı Barkod Ayarları",
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          Spacer(),
          Text(
            "${_weightedRules.length} kural",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                color: _scheme.onSurfaceVariant),
          ),
        ]),
        SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius:
                BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 10),
              ..._weightedRules.map(_buildWeightedRuleCard),
              if (_weightedRules.isEmpty)
                Text(
                  "Kural yok",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: _scheme.onSurfaceVariant),
                ),
              SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _addWeightedRule,
                      icon: Icon(Icons.add_rounded, size: 16),
                      label: Text("Kural Ekle"),
                    ),
                  ),
                  SizedBox(width: 8),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: _resetWeightedRules,
                      icon: Icon(Icons.restart_alt_rounded, size: 16),
                      label: Text("Varsayılan"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWeightedRuleCard(WeightedBarcodeRule rule) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _accent.withValues(alpha: .08)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "On ek ${rule.prefix} | Toplam ${rule.totalLength} hane",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: _primary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Stok ${rule.stockBarcodeLength}, miktar ${rule.quantityLength}, kontrol ${rule.controlLength}, ondalik ${rule.quantityDecimalDigits}",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: _scheme.onSurfaceVariant,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Duzenle",
            onPressed: () => _editWeightedRule(rule),
            icon: Icon(Icons.edit_outlined),
          ),
          IconButton(
            tooltip: "Sil",
            onPressed: () => _deleteWeightedRule(rule),
            icon: Icon(Icons.delete_outline, color: _scheme.error),
          ),
        ],
      ),
    );
  }

  Future<void> _addWeightedRule() async {
    final rule = await _showWeightedRuleDialog();
    if (rule == null) {
      return;
    }
    final next = [..._weightedRules, rule];
    await WeightedBarcodeHelper.saveRules(next);
    if (!mounted) {
      return;
    }
    setState(() => _weightedRules = WeightedBarcodeHelper.getCachedRules());
  }

  Future<void> _editWeightedRule(WeightedBarcodeRule rule) async {
    final updated = await _showWeightedRuleDialog(rule: rule);
    if (updated == null) {
      return;
    }
    final next = _weightedRules
        .map((e) => identical(e, rule) ? updated : e)
        .toList(growable: false);
    await WeightedBarcodeHelper.saveRules(next);
    if (!mounted) {
      return;
    }
    setState(() => _weightedRules = WeightedBarcodeHelper.getCachedRules());
  }

  Future<void> _deleteWeightedRule(WeightedBarcodeRule rule) async {
    final next = _weightedRules.where((e) => !identical(e, rule)).toList();
    await WeightedBarcodeHelper.saveRules(next);
    if (!mounted) {
      return;
    }
    setState(() => _weightedRules = WeightedBarcodeHelper.getCachedRules());
  }

  Future<void> _resetWeightedRules() async {
    await WeightedBarcodeHelper.resetRules();
    if (!mounted) {
      return;
    }
    setState(() => _weightedRules = WeightedBarcodeHelper.getCachedRules());
  }

  Future<WeightedBarcodeRule?> _showWeightedRuleDialog({
    WeightedBarcodeRule? rule,
  }) {
    final prefixCtrl = TextEditingController(text: rule?.prefix ?? '');
    final stockCtrl = TextEditingController(
      text: rule?.stockBarcodeLength.toString() ?? '6',
    );
    final quantityCtrl = TextEditingController(
      text: rule?.quantityLength.toString() ?? '6',
    );
    final controlCtrl = TextEditingController(
      text: rule?.controlLength.toString() ?? '1',
    );
    final decimalCtrl = TextEditingController(
      text: rule?.quantityDecimalDigits.toString() ?? '4',
    );

    return showDialog<WeightedBarcodeRule>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title:
            Text(rule == null ? 'Tartılı Barkod Ayarları' : 'Ayarları Düzenle'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _ruleField(prefixCtrl, "Ön ek", "27"),
              SizedBox(height: 10),
              _ruleField(stockCtrl, "Stok barkod uzunluğu", "6"),
              SizedBox(height: 10),
              _ruleField(quantityCtrl, "Miktar uzunluğu", "6"),
              SizedBox(height: 10),
              _ruleField(controlCtrl, "Kontrol hanesi", "1"),
              SizedBox(height: 10),
              _ruleField(decimalCtrl, "Ondalık basamak", "4"),
            ],
          ),
        ),
        actions: [
          ErpDialogAction(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal"),
          ),
          ElevatedButton(
            onPressed: () {
              final nextRule = WeightedBarcodeRule(
                prefix: prefixCtrl.text.trim(),
                stockBarcodeLength: int.tryParse(stockCtrl.text.trim()) ?? 0,
                quantityLength: int.tryParse(quantityCtrl.text.trim()) ?? 0,
                controlLength: int.tryParse(controlCtrl.text.trim()) ?? 0,
                quantityDecimalDigits:
                    int.tryParse(decimalCtrl.text.trim()) ?? 0,
              );
              if (!nextRule.isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Kural bilgileri geçersiz."),
                  ),
                );
                return;
              }
              Navigator.pop(context, nextRule);
            },
            child: Text("Kaydet"),
          ),
        ],
      ),
    );
  }

  Widget _ruleField(
    TextEditingController controller,
    String label,
    String hint,
  ) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        hintText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildBarcodeHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: _positive,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 10),
          Text(
            "Hızlı Barkod Geçmişi",
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _primary,
            ),
          ),
          Spacer(),
          Text(
            "${_barcodeHistory.length} kayıt",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                color: _scheme.onSurfaceVariant),
          ),
        ]),
        SizedBox(height: 8),
        if (_barcodeHistory.isEmpty)
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: _scheme.surface,
              borderRadius: BorderRadius.circular(
                  ErpDesignStyle.modern(context) ? 18 : 12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Text(
              "Kaydedilmiş hızlı barkod listesi yok.",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: _scheme.onSurfaceVariant),
            ),
          )
        else
          ..._barcodeHistory.take(10).map(_buildBarcodeHistoryCard),
      ],
    );
  }

  Widget _buildBarcodeHistoryCard(BarcodeScanHistoryItem item) {
    final totalCount = item.summary.fold<double>(
      0,
      (sum, row) => sum + ((row['quantity'] as num?)?.toDouble() ?? 0),
    );
    final uniqueCount = item.summary.length;
    final belgeAdi = BelgeTuruCouples.adById(item.belgeTuru);
    final tarih = DateFormat('dd.MM.yyyy HH:mm').format(item.createdAt);

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: _positive.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const CorporateMenuIcon('Barkod', size: 26),
        ),
        title: Text(
          belgeAdi == '-' ? 'Belge Türü Yok' : belgeAdi,
          style: TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 13,
            color: _primary,
          ),
        ),
        subtitle: Text(
          "${item.belgeNo ?? '-'}  |  $uniqueCount farkli / ${_formatQuantity(totalCount)} toplam  |  $tarih",
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              color: _scheme.onSurfaceVariant),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: "Detay",
              onPressed: () => _showBarcodeHistoryDetail(item),
              icon: Icon(Icons.visibility_outlined),
            ),
            IconButton(
              tooltip: "Sil",
              onPressed: () async {
                await _svc.deleteBarcodeScanHistoryItem(item.localId);
                _reload();
              },
              icon: Icon(Icons.delete_outline, color: _scheme.error),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showBarcodeHistoryDetail(BarcodeScanHistoryItem item) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(BelgeTuruCouples.adById(item.belgeTuru)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: item.summary.length,
            separatorBuilder: (_, __) => Divider(height: 12),
            itemBuilder: (_, index) {
              final row = item.summary[index];
              final stokKod = row['stokKod']?.toString() ?? '';
              final stokAd = row['stokAd']?.toString() ?? '';
              final barcode = row['barcode']?.toString() ?? '';
              final quantity = (row['quantity'] as num?)?.toDouble() ?? 0;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stokKod.isEmpty && stokAd.isEmpty
                        ? barcode
                        : "$stokKod - $stokAd",
                    style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    "Barkod: $barcode",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: _scheme.onSurfaceVariant),
                  ),
                  Text(
                    "Adet: ${_formatQuantity(quantity)}",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12,
                        color: _scheme.onSurfaceVariant),
                  ),
                ],
              );
            },
          ),
        ),
        actions: [
          ErpDialogAction(
            secondary: true,
            onPressed: () => Navigator.pop(context),
            child: Text("Kapat"),
          ),
        ],
      ),
    );
  }
}
