import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../../widgets/popup_kapat_basligi.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../../models/entities/finans/banka/bankahesap_dto.dart';
import '../../../models/entities/finans/cek/cekalinanprotesto_create_dto.dart';
import '../../../models/entities/finans/cek/cekalinanhareket_dto.dart';
import '../../../models/entities/finans/cek/cekalinanhareket_filter_dto.dart';
import '../../../models/entities/finans/cek/cekalinanprotestohareket_dto.dart';
import '../../../models/entities/finans/cek/cekalinanprotestohareket_create_dto.dart';
import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/yonetim/belge_seri_dto.dart';
import '../../../services/finans/bankahesap_service.dart';
import '../../../services/finans/cekalinanprotesto_service.dart';
import '../../../services/finans/cekalinanhareket_service.dart';
import '../../../services/finans/cekalinanprotestohareket_service.dart';
import '../../../services/cari/cari_service.dart';
import '../../../services/yonetim/belgeseri_service.dart';
import '../../../services/offline/offline_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/belge_turu_couples.dart';
import '../../../helpers/cek_couples.dart';

class CekalinanprotestoEklePage extends StatefulWidget {
  const CekalinanprotestoEklePage({super.key});

  @override
  State<CekalinanprotestoEklePage> createState() =>
      _CekalinanprotestoEklePageState();
}

class _CekalinanprotestoEklePageState extends State<CekalinanprotestoEklePage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;
  Color get _kBlue => _scheme.primary;
  Color get _kRed => _scheme.error;
  Color get _kGold => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFCD34D)
      : const Color(0xFF9A6700);

  final _headerSvc = CekalinanprotestoService();
  final _hareketSvc = CekalinanhareketService();
  final _protestoHareketSvc = CekalinanprotestohareketService();
  final _fmt = DateFormat('dd.MM.yyyy');
  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');

  bool _loading = true;
  bool _saving = false;
  int _phase = 1;
  String? _headerId;

  List<CariDtoLite> _cariler = [];
  List<BankahesapDto> _hesaplar = [];
  List<BelgeSeriDto> _seriler = [];

  CariDtoLite? _seciliCari;
  BankahesapDto? _seciliHesap;
  int _seciliProtestoyeri = 1; // 1=Portföy varsayılan
  int _seciliYil = DateTime.now().year;
  String? _seciliSeri;

  late final TextEditingController _tarihCtrl;
  late final TextEditingController _belgeNoCtrl;
  late final TextEditingController _makbuzNoCtrl;
  late final TextEditingController _aciklamaCtrl;
  final _belgeNoFocus = FocusNode();

  bool _availLoading = false;
  List<CekalinanhareketDto> _available = [];
  List<CekalinanprotestohareketDto> _selected = [];

  bool get _cariGerekli =>
      _seciliProtestoyeri == 1 || _seciliProtestoyeri == 4; // Portföy, Ciro
  bool get _hesapGerekli =>
      _seciliProtestoyeri == 2 || _seciliProtestoyeri == 3; // Tahsil, Teminat

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tarihCtrl = TextEditingController(text: _fmt.format(now));
    _belgeNoCtrl = TextEditingController();
    _makbuzNoCtrl = TextEditingController();
    _aciklamaCtrl = TextEditingController();
    _belgeNoFocus.addListener(() {
      if (!_belgeNoFocus.hasFocus) _normalize();
    });
    _loadLookups();
  }

  @override
  void dispose() {
    _tarihCtrl.dispose();
    _belgeNoCtrl.dispose();
    _makbuzNoCtrl.dispose();
    _aciklamaCtrl.dispose();
    _belgeNoFocus.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    final now = DateTime.now();

    final results = await Future.wait([
      CariService().getCariler(token).catchError((_) => <CariDtoLite>[]),
      BankahesapService()
          .getAllWithoutAuth(token)
          .catchError((_) => <BankahesapDto>[]),
      BelgeSeriService()
          .getAll(token, BelgeTuruCouples.cekBordroMusteriProtesto)
          .catchError((_) => <BelgeSeriDto>[]),
    ]);

    if (!mounted) return;
    _cariler = results[0] as List<CariDtoLite>;
    _hesaplar = results[1] as List<BankahesapDto>;
    _seriler = results[2] as List<BelgeSeriDto>;

    if (_seriler.isNotEmpty) {
      _seciliSeri = _seriler.first.seri;
      try {
        final no = await _headerSvc.getNewCekalinanprotestoNo(
            token, _seciliSeri!, now.year);
        if (mounted) _belgeNoCtrl.text = no;
      } catch (_) {}
    }

    if (mounted) setState(() => _loading = false);
  }

  void _normalize() {
    final raw = _belgeNoCtrl.text.trim();
    if (raw.isEmpty) return;
    final n = int.tryParse(raw.replaceAll(RegExp(r'[^\d]'), ''));
    if (n != null) _belgeNoCtrl.text = n.toString().padLeft(8, '0');
  }

  Future<void> _fetchBelgeNo() async {
    if (_seciliSeri == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    try {
      final no = await _headerSvc.getNewCekalinanprotestoNo(
          token, _seciliSeri!, _seciliYil);
      if (mounted)
        setState(() {
          _belgeNoCtrl.text = no;
        });
    } catch (_) {}
  }

  DateTime? _parseDate(String s) {
    try {
      return DateFormat('dd.MM.yyyy').parse(s);
    } catch (_) {
      return null;
    }
  }

  Future<void> _createHeaderAndContinue() async {
    if (_cariGerekli && _seciliCari == null) {
      UiFeedback.showError(context, 'Lütfen cari seçiniz.');
      return;
    }
    if (_hesapGerekli && _seciliHesap == null) {
      UiFeedback.showError(context, 'Lütfen banka hesabı seçiniz.');
      return;
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';

      final dto = CekalinanprotestoCreateDto()
        ..cariid = _cariGerekli ? _seciliCari?.Id : null
        ..bankahesapid = _hesapGerekli ? _seciliHesap?.Id : null
        ..belgeseri = _seciliSeri
        ..belgeyil = _seciliYil
        ..belgeno = _belgeNoCtrl.text.trim()
        ..belgeserino = '${_seciliSeri ?? ''}$_seciliYil'
        ..belgeturu = BelgeTuruCouples.cekBordroMusteriProtesto
        ..tarih = _parseDate(_tarihCtrl.text)
        ..makbuzno =
            _makbuzNoCtrl.text.trim().isEmpty ? null : _makbuzNoCtrl.text.trim()
        ..aciklama =
            _aciklamaCtrl.text.trim().isEmpty ? null : _aciklamaCtrl.text.trim()
        ..protestoyeri = _seciliProtestoyeri;

      final id = await _headerSvc.saveSingle(token, dto);
      if (!mounted) return;
      setState(() {
        _headerId = id;
        _phase = 2;
      });
      await _loadAvailable();
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _loadAvailable() async {
    setState(() => _availLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    try {
      final filter = CekalinanhareketFilterDto()
        ..evrakdurum = [1]
        ..evrakyeri = [_seciliProtestoyeri];
      final results = await Future.wait([
        _hareketSvc.filter(token, filter),
        _protestoHareketSvc.getAllByCekalinanprotestoId(token, _headerId!),
      ]);
      if (!mounted) return;
      setState(() {
        _available = results[0] as List<CekalinanhareketDto>;
        _selected = results[1] as List<CekalinanprotestohareketDto>;
        _availLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _availLoading = false);
      UiFeedback.showException(context, e);
    }
  }

  Future<void> _addCek(CekalinanhareketDto h) async {
    final onay = await UiFeedback.confirm(context,
        title: 'Çeki Protesto Et',
        message:
            '${h.Ceknumarasi?.isNotEmpty == true ? "Çek No: ${h.Ceknumarasi}" : (h.Belgeserino ?? "")} — ${_moneyFmt.format(h.Tutar ?? 0)} tutarlı çek karşılıksız/protesto olarak işaretlenecek. Emin misiniz?',
        confirmLabel: 'Protesto Et',
        cancelLabel: 'Vazgeç',
        destructive: true);
    if (!onay || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final dto = CekalinanprotestohareketCreateDto()
        ..cekalinanhareketid = h.Id
        ..cekalinanprotestoid = _headerId;

      final manuelOffline = await OfflineService.instance.getOfflineMode();
      final internetYok = !OfflineService.instance.isOnline.value;
      if (manuelOffline || internetYok) {
        await OfflineService.instance.enqueue('single_full', {
          'endpoint': '/Cekalinanprotestohareket/SaveSingle',
          'body': dto.toJson(),
        });
        if (!mounted) return;
        setState(() {
          _selected = [
            ..._selected,
            CekalinanprotestohareketDto(
              Id: '',
              Cekalinanhareketid: h.Id,
              Cekalinanprotestoid: _headerId,
              Cekalinanhareket: h,
            ),
          ];
          _available = _available.where((a) => a.Id != h.Id).toList();
        });
        UiFeedback.showSuccess(
            context,
            internetYok
                ? 'İnternet yok — kayıt kuyruğa alındı, bağlantı gelince gönderilecek'
                : 'Kayıt kuyruğa eklendi — online olunca gönderilecek');
        return;
      }

      await _protestoHareketSvc.saveSingle(token, dto);
      if (!mounted) return;
      UiFeedback.showSuccess(context, 'Çek protesto edildi.');
      _loadAvailable();
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
  }

  Future<void> _removeCek(CekalinanprotestohareketDto h) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      await _protestoHareketSvc.removeSingle(token, h.Id!);
      if (!mounted) return;
      UiFeedback.showDeleted(context, 'Çek tekrar beklemede duruma alındı.');
      _loadAvailable();
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
  }

  Future<void> _complete() async {
    if (_selected.isEmpty) {
      UiFeedback.showError(context, 'Lütfen en az bir çek protesto ediniz.');
      return;
    }
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      await _headerSvc.complete(token, _headerId!);
      if (!mounted) return;
      UiFeedback.showSuccess(context, 'Protesto tamamlandı.', autoPop: true);
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double get _toplamTutar =>
      _selected.fold(0.0, (s, h) => s + (h.Cekalinanhareket?.Tutar ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _phase == 1
              ? _buildPhase1()
              : _buildPhase2(),
    );
  }

  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _kDark,
        elevation: 0,
        centerTitle: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Yeni Çek Protesto',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _kDark)),
        ]),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _scheme.surfaceContainerLow)),
      );

  // ── Phase 1: Bordro Bilgileri ─────────────────────────────────────────
  Widget _buildPhase1() => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSection(
              'Protesto Bilgileri', Icons.report_gmailerrorred_rounded, [
            _fieldRow(
                'Protesto Yeri',
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _seciliProtestoyeri,
                  decoration: _dec('Protesto Yeri'),
                  style: _style,
                  onChanged: (v) {
                    if (v != null)
                      setState(() {
                        _seciliProtestoyeri = v;
                        _seciliCari = null;
                        _seciliHesap = null;
                      });
                  },
                  items: EvrakYeriCouples.list
                      .where((e) => e.value <= 4)
                      .map((e) => DropdownMenuItem(
                          value: e.value,
                          child: Text(e.text,
                              style: const TextStyle(
                                  fontFamily: 'Roboto', fontSize: 13))))
                      .toList(),
                )),
            const SizedBox(height: 10),
            if (_cariGerekli) _buildCariDropdown(),
            if (_hesapGerekli) _buildHesapDropdown(),
          ]),
          const SizedBox(height: 12),
          _buildSection('Tarih & Belge', Icons.event_note_rounded, [
            _buildSeriTable(),
            const SizedBox(height: 10),
            _pairRow(
              _fieldRow('Tarih', _buildDateField(_tarihCtrl)),
              _fieldRow(
                  'Makbuz No',
                  TextFormField(
                      controller: _makbuzNoCtrl,
                      style: _style,
                      decoration: _dec('Makbuz No'))),
            ),
          ]),
          const SizedBox(height: 12),
          _buildSection('Detay', Icons.notes_rounded, [
            _fieldRow(
                'Açıklama',
                TextFormField(
                    controller: _aciklamaCtrl,
                    style: _style,
                    decoration: _dec('Açıklama'),
                    maxLines: 2)),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlue,
                  foregroundColor: _scheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 0),
              icon: _saving
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _scheme.onPrimary))
                  : const Icon(Icons.arrow_forward_rounded, size: 20),
              label: Text(_saving ? 'Kaydediliyor...' : 'Devam Et — Çek Seç',
                  style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              onPressed: _saving ? null : _createHeaderAndContinue,
            ),
          ),
        ],
      );

  // ── Phase 2: Çek Seçimi ───────────────────────────────────────────────
  Widget _buildPhase2() => DefaultTabController(
        length: 2,
        child: Column(children: [
          _buildOzetBar(),
          ErpAdaptiveTabs(
              context: context,
              tabBar: TabBar(
                labelColor: _kBlue,
                unselectedLabelColor: _scheme.onSurfaceVariant,
                indicatorColor: _kBlue,
                tabs: [
                  Tab(height: 40, text: 'Uygun Çekler'),
                  Tab(height: 40, text: 'Protestolu Çekler')
                ],
              )),
          Expanded(
            child: TabBarView(children: [
              _availLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _available.isEmpty
                      ? _emptyMini('Bu yerde protestoya uygun çek bulunamadı')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: _available.length,
                          itemBuilder: (_, i) =>
                              _buildAvailableCard(_available[i]),
                        ),
              _selected.isEmpty
                  ? _emptyMini('Henüz çek protesto edilmedi')
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      itemCount: _selected.length,
                      itemBuilder: (_, i) => _buildSelectedCard(_selected[i]),
                    ),
            ]),
          ),
          _buildTamamlaBar(),
        ]),
      );

  Widget _emptyMini(String text) => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inbox_outlined, size: 56, color: _scheme.outlineVariant),
          const SizedBox(height: 12),
          Text(text,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: _scheme.onSurfaceVariant)),
        ]),
      );

  Widget _buildOzetBar() => Container(
        color: _scheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  _cariGerekli
                      ? (_seciliCari?.Ad ?? '')
                      : (_seciliHesap?.Ad ?? ''),
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text('${_selected.length} çek protesto edildi',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: _scheme.onSurfaceVariant)),
            ]),
          ),
          Text(_moneyFmt.format(_toplamTutar),
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: _kRed)),
        ]),
      );

  Widget _buildTamamlaBar() => Container(
        color: _scheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: PermissionAction(
              modules: [1009],
              access: Access.write,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed,
                    foregroundColor: _scheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0),
                icon: _saving
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: _scheme.onPrimary))
                    : const Icon(Icons.check_rounded, size: 20),
                label: Text(_saving ? 'İşleniyor...' : 'Tamamla',
                    style: const TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 15,
                        fontWeight: FontWeight.w600)),
                onPressed: _saving ? null : _complete,
              )),
        ),
      );

  Widget _buildAvailableCard(CekalinanhareketDto h) {
    final fx = (h.DovizBirim ?? 'TL') != 'TL' && (h.DovizBirim ?? '') != '₺';
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius: BorderRadius.circular(14),
        border:
            fx ? Border.all(color: _kGold.withOpacity(0.35), width: 1.2) : null,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _addCek(h),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          h.Ceknumarasi?.isNotEmpty == true
                              ? 'Çek No: ${h.Ceknumarasi}'
                              : (h.Belgeserino ?? '-'),
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _kDark)),
                      const SizedBox(height: 3),
                      Text(h.CariAd ?? h.Bankaadi ?? '-',
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              color: _scheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                      if (h.Vadetarihi != null) ...[
                        const SizedBox(height: 3),
                        Text('Vade: ${_fmt.format(h.Vadetarihi!)}',
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                color: _scheme.onSurfaceVariant)),
                      ],
                    ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(_moneyFmt.format(h.Tutar ?? 0),
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _kDark)),
                const SizedBox(height: 4),
                Icon(Icons.report_gmailerrorred_rounded,
                    color: _kRed, size: 20),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCard(CekalinanprotestohareketDto h) {
    final cek = h.Cekalinanhareket;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(
                  cek?.Ceknumarasi?.isNotEmpty == true
                      ? 'Çek No: ${cek!.Ceknumarasi}'
                      : (cek?.Belgeserino ?? '-'),
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kDark)),
              const SizedBox(height: 3),
              Text(cek?.CariAd ?? cek?.Bankaadi ?? '-',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: _scheme.onSurfaceVariant)),
            ]),
          ),
          Text(_moneyFmt.format(cek?.Tutar ?? 0),
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _kRed)),
          IconButton(
              icon: Icon(Icons.close_rounded,
                  size: 18, color: _scheme.onSurfaceVariant),
              onPressed: () => _removeCek(h)),
        ]),
      ),
    );
  }

  // ── Ortak widget'lar ───────────────────────────────────────────────────
  Widget _buildSection(String title, IconData icon, List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: _scheme.surface,
          borderRadius:
              BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  color: _kBlue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 14, color: _kBlue),
            ),
            const SizedBox(width: 8),
            Text(title,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _scheme.onSurfaceVariant,
                    letterSpacing: 0.4)),
          ]),
          const SizedBox(height: 12),
          ...children,
        ]),
      );

  Widget _fieldRow(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          field,
        ],
      );

  Widget _pairRow(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b)
        ],
      );

  TextStyle get _style =>
      TextStyle(fontFamily: 'Roboto', fontSize: 14, color: _kDark);

  InputDecoration _dec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            color: _scheme.onSurfaceVariant),
        filled: true,
        fillColor: _scheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _kBlue, width: 1.5)),
      );

  InputDecoration _searchDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Roboto',
            color: _scheme.onSurfaceVariant,
            fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
      );

  Widget _buildCariDropdown() => _fieldRow(
      'Cari *',
      DropdownSearch<CariDtoLite>(
        items: _cariler,
        selectedItem: _seciliCari,
        itemAsString: (c) => '${c.Ad ?? ''} (${c.Kod ?? ''})',
        compareFn: (a, b) => a.Id == b.Id,
        filterFn: (c, q) =>
            (c.Ad ?? '').toLowerCase().contains(q.toLowerCase()) ||
            (c.Kod ?? '').toLowerCase().contains(q.toLowerCase()),
        onChanged: (v) => setState(() => _seciliCari = v),
        popupProps: PopupProps.bottomSheet(
          title: const PopupKapatBasligi(),
          showSearchBox: true,
          searchFieldProps:
              TextFieldProps(decoration: _searchDec('Cari ara...')),
          bottomSheetProps: const BottomSheetProps(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              constraints: BoxConstraints(maxHeight: 520)),
        ),
        dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: _dec('Cari seçiniz')),
      ));

  Widget _buildHesapDropdown() => _fieldRow(
      'Banka Hesabı *',
      DropdownSearch<BankahesapDto>(
        items: _hesaplar,
        selectedItem: _seciliHesap,
        itemAsString: (b) => '${b.Ad ?? ''} (${b.Kod ?? ''})',
        compareFn: (a, b) => a.Id == b.Id,
        onChanged: (v) => setState(() => _seciliHesap = v),
        popupProps: PopupProps.bottomSheet(
          title: const PopupKapatBasligi(),
          showSearchBox: true,
          searchFieldProps:
              TextFieldProps(decoration: _searchDec('Hesap ara...')),
          bottomSheetProps: const BottomSheetProps(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              constraints: BoxConstraints(maxHeight: 480)),
        ),
        dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: _dec('Hesap seçiniz')),
      ));

  Widget _buildDateField(TextEditingController ctrl) => TextFormField(
        controller: ctrl,
        readOnly: true,
        style: _style,
        decoration: _dec('gg.aa.yyyy').copyWith(
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18)),
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: _parseDate(ctrl.text) ?? DateTime.now(),
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
          );
          if (picked != null) ctrl.text = _fmt.format(picked);
        },
      );

  Widget _buildSeriTable() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Belge Seri / Yıl / No',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: _scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 4),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: _pickerField<String>(
              value: _seciliSeri,
              items: _seriler.map((s) => s.seri ?? '-').toList(),
              itemLabel: (v) => v,
              onSelected: (v) {
                setState(() => _seciliSeri = v);
                _fetchBelgeNo();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _pickerField<int>(
              value: _seciliYil,
              items: List.generate(7, (i) => DateTime.now().year - i),
              itemLabel: (v) => '$v',
              onSelected: (v) {
                setState(() => _seciliYil = v);
                _fetchBelgeNo();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: _belgeNoCtrl,
              focusNode: _belgeNoFocus,
              style: _style,
              decoration: _dec('Belge No').copyWith(
                suffixIcon: IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 18),
                    onPressed: _fetchBelgeNo),
              ),
            ),
          ),
        ]),
      ]);

  Widget _pickerField<T>({
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onSelected,
  }) =>
      PopupMenuButton<T>(
        enabled: items.isNotEmpty,
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        onSelected: onSelected,
        itemBuilder: (context) => items
            .map((it) => PopupMenuItem<T>(
                value: it,
                child: Text(itemLabel(it),
                    style:
                        const TextStyle(fontFamily: 'Roboto', fontSize: 14))))
            .toList(),
        child: Container(
          decoration: BoxDecoration(
              color: _scheme.surface,
              borderRadius: BorderRadius.circular(
                  ErpDesignStyle.modern(context) ? 18 : 12),
              border: Border.all(color: _scheme.outlineVariant)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(
                child: Text(value != null ? itemLabel(value) : '-',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Roboto', fontSize: 14, color: _kDark))),
            const SizedBox(width: 2),
            Icon(Icons.expand_more_rounded,
                size: 16, color: _scheme.onSurfaceVariant),
          ]),
        ),
      );
}
