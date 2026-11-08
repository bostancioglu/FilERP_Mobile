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
import '../../../models/entities/finans/kasa_islem/kasa_dto.dart';
import '../../../models/entities/finans/cek/cekalinanportfoydentahsil_create_dto.dart';
import '../../../models/entities/finans/cek/cekalinanhareket_dto.dart';
import '../../../models/entities/finans/cek/cekalinanhareket_filter_dto.dart';
import '../../../models/entities/finans/cek/cekalinanportfoydentahsilhareket_dto.dart';
import '../../../models/entities/finans/cek/cekalinanportfoydentahsilhareket_create_dto.dart';
import '../../../models/entities/yonetim/belge_seri_dto.dart';
import '../../../services/finans/bankahesap_service.dart';
import '../../../services/finans/kasa_tanim_service.dart';
import '../../../services/finans/cekalinanportfoydentahsil_service.dart';
import '../../../services/finans/cekalinanhareket_service.dart';
import '../../../services/finans/cekalinanportfoydentahsilhareket_service.dart';
import '../../../services/yonetim/belgeseri_service.dart';
import '../../../services/offline/offline_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/belge_turu_couples.dart';
import '../../../helpers/cek_couples.dart';
import '../../../helpers/number_format_helper.dart';

class CekalinanportfoydentahsilEklePage extends StatefulWidget {
  const CekalinanportfoydentahsilEklePage({super.key});

  @override
  State<CekalinanportfoydentahsilEklePage> createState() =>
      _CekalinanportfoydentahsilEklePageState();
}

class _CekalinanportfoydentahsilEklePageState
    extends State<CekalinanportfoydentahsilEklePage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;
  Color get _kBlue => _scheme.primary;
  Color get _kGreen => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF6EE7B7)
      : const Color(0xFF0E7C5A);
  Color get _kGold => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFCD34D)
      : const Color(0xFF9A6700);

  final _headerSvc = CekalinanportfoydentahsilService();
  final _hareketSvc = CekalinanhareketService();
  final _tahsilHareketSvc = CekalinanportfoydentahsilhareketService();
  final _fmt = DateFormat('dd.MM.yyyy');
  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');

  bool _loading = true;
  bool _saving = false;
  int _phase = 1;
  String? _headerId;

  List<KasaDto> _kasalar = [];
  List<BankahesapDto> _hesaplar = [];
  List<BelgeSeriDto> _seriler = [];

  KasaDto? _seciliKasa;
  BankahesapDto? _seciliHesap;
  int _seciliTahsilyeri = 1; // 1=Kasa varsayılan
  int _seciliYil = DateTime.now().year;
  String? _seciliSeri;

  late final TextEditingController _tarihCtrl;
  late final TextEditingController _belgeNoCtrl;
  late final TextEditingController _makbuzNoCtrl;
  late final TextEditingController _aciklamaCtrl;
  final _belgeNoFocus = FocusNode();

  bool _availLoading = false;
  List<CekalinanhareketDto> _available = [];
  List<CekalinanportfoydentahsilhareketDto> _selected = [];

  bool get _kasaGerekli => _seciliTahsilyeri == 1;
  bool get _hesapGerekli => _seciliTahsilyeri == 2;

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
      KasaTanimService()
          .getAllWithoutAuth(token)
          .catchError((_) => <KasaDto>[]),
      BankahesapService()
          .getAllWithoutAuth(token)
          .catchError((_) => <BankahesapDto>[]),
      BelgeSeriService()
          .getAll(token, BelgeTuruCouples.cekBordroMusteriPortfoy)
          .catchError((_) => <BelgeSeriDto>[]),
    ]);

    if (!mounted) return;
    _kasalar = results[0] as List<KasaDto>;
    _hesaplar = results[1] as List<BankahesapDto>;
    _seriler = results[2] as List<BelgeSeriDto>;

    if (_seriler.isNotEmpty) {
      _seciliSeri = _seriler.first.seri;
      try {
        final no = await _headerSvc.getNewCekalinanportfoydentahsilNo(
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
      final no = await _headerSvc.getNewCekalinanportfoydentahsilNo(
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
    if (_kasaGerekli && _seciliKasa == null) {
      UiFeedback.showError(context, 'Lütfen kasa seçiniz.');
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

      final dto = CekalinanportfoydentahsilCreateDto()
        ..kasaid = _kasaGerekli ? _seciliKasa?.Id : null
        ..bankahesapid = _hesapGerekli ? _seciliHesap?.Id : null
        ..belgeseri = _seciliSeri
        ..belgeyil = _seciliYil
        ..belgeno = _belgeNoCtrl.text.trim()
        ..belgeserino = '${_seciliSeri ?? ''}$_seciliYil'
        ..belgeturu = BelgeTuruCouples.cekBordroMusteriPortfoy
        ..tarih = _parseDate(_tarihCtrl.text)
        ..makbuzno =
            _makbuzNoCtrl.text.trim().isEmpty ? null : _makbuzNoCtrl.text.trim()
        ..aciklama =
            _aciklamaCtrl.text.trim().isEmpty ? null : _aciklamaCtrl.text.trim()
        ..tahsilyeri = _seciliTahsilyeri;

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
        ..evrakdurum = [1, 6] // Beklemede, Kısmi Ödeme
        ..evrakyeri = [1]; // Portföy
      final results = await Future.wait([
        _hareketSvc.filter(token, filter),
        _tahsilHareketSvc.getAllByCekalinanportfoydentahsilId(
            token, _headerId!),
      ]);
      if (!mounted) return;
      setState(() {
        _available = results[0] as List<CekalinanhareketDto>;
        _selected = results[1] as List<CekalinanportfoydentahsilhareketDto>;
        _availLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _availLoading = false);
      UiFeedback.showException(context, e);
    }
  }

  Future<void> _addCek(CekalinanhareketDto h) async {
    final isFx = (h.DovizBirim ?? 'TL') != 'TL' && (h.DovizBirim ?? '') != '₺';
    final kalan = (h.Tutar ?? 0) - (h.Kismitahsiltutar ?? 0);

    final kurCtrl = TextEditingController(
        text:
            h.Kur != null ? NumberFormatHelper.format(h.Kur!, decimal: 4) : '');
    final dovizTutarCtrl = TextEditingController(
        text: h.Doviztutar != null
            ? NumberFormatHelper.format(h.Doviztutar!)
            : '');
    final tutarCtrl =
        TextEditingController(text: NumberFormatHelper.format(kalan));
    final masrafCtrl = TextEditingController(text: '0,00');
    bool masrafIcindenMi = false;

    final onaylandi = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final masrafVar = NumberFormatHelper.parse(masrafCtrl.text) > 0;
          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20),
            child: SingleChildScrollView(
              child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Çeki Tahsil Et',
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: _kDark)),
                    const SizedBox(height: 4),
                    Text(
                        h.Ceknumarasi?.isNotEmpty == true
                            ? 'Çek No: ${h.Ceknumarasi}'
                            : (h.Belgeserino ?? ''),
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: _scheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    if (isFx) ...[
                      Row(children: [
                        Expanded(
                            child: _sheetField('Döviz Tutar (${h.DovizBirim})',
                                dovizTutarCtrl)),
                        const SizedBox(width: 10),
                        Expanded(child: _sheetField('Kur', kurCtrl)),
                      ]),
                      const SizedBox(height: 12),
                    ],
                    _sheetField('Tutar (Bu tahsilde alınan)', tutarCtrl),
                    const SizedBox(height: 4),
                    Text('Kalan: ${_moneyFmt.format(kalan)}',
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            color: _scheme.onSurfaceVariant)),
                    const SizedBox(height: 12),
                    _sheetField('Masraf', masrafCtrl,
                        onChanged: (_) => setSheetState(() {})),
                    if (masrafVar) ...[
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: Text('Masraf İçinden mi?',
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 13,
                                    color: _scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500))),
                        Switch(
                          value: masrafIcindenMi,
                          activeColor: _kBlue,
                          onChanged: (v) =>
                              setSheetState(() => masrafIcindenMi = v),
                        ),
                      ]),
                    ],
                    const SizedBox(height: 12),
                    SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: _kBlue,
                              foregroundColor: _scheme.onPrimary,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 13)),
                          child: const Text('Tahsil Et'),
                        )),
                    const SizedBox(height: 20),
                  ]),
            ),
          );
        },
      ),
    );
    if (onaylandi != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final dto = CekalinanportfoydentahsilhareketCreateDto()
        ..cekalinanhareketid = h.Id
        ..cekalinanportfoydentahsilid = _headerId
        ..kur = isFx ? NumberFormatHelper.parse(kurCtrl.text) : null
        ..doviztutar =
            isFx ? NumberFormatHelper.parse(dovizTutarCtrl.text) : null
        ..tutar = NumberFormatHelper.parse(tutarCtrl.text)
        ..masraf = NumberFormatHelper.parse(masrafCtrl.text)
        ..masraficindenmi = masrafIcindenMi
        ..oncekievrakdurum = h.Evrakdurum
        ..oncekievrakyeri = h.Evrakyeri;

      final manuelOffline = await OfflineService.instance.getOfflineMode();
      final internetYok = !OfflineService.instance.isOnline.value;
      if (manuelOffline || internetYok) {
        await OfflineService.instance.enqueue('single_full', {
          'endpoint': '/Cekalinanportfoydentahsilhareket/SaveSingle',
          'body': dto.toJson(),
        });
        if (!mounted) return;
        setState(() {
          _selected = [
            ..._selected,
            CekalinanportfoydentahsilhareketDto(
              Id: '',
              Cekalinanhareketid: h.Id,
              Cekalinanportfoydentahsilid: _headerId,
              Kur: dto.kur,
              Doviztutar: dto.doviztutar,
              Tutar: dto.tutar,
              Masraf: dto.masraf,
              Masraficindenmi: dto.masraficindenmi,
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

      await _tahsilHareketSvc.saveSingle(token, dto);
      if (!mounted) return;
      UiFeedback.showSuccess(context, 'Çek tahsil edildi.');
      _loadAvailable();
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
  }

  Widget _sheetField(String label, TextEditingController ctrl,
          {ValueChanged<String>? onChanged}) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          TextField(
            controller: ctrl,
            onChanged: onChanged,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: _kDark),
            decoration: InputDecoration(
              filled: true,
              fillColor: _kBg,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none),
            ),
          ),
        ],
      );

  Future<void> _removeCek(CekalinanportfoydentahsilhareketDto h) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      await _tahsilHareketSvc.removeSingle(token, h.Id!);
      if (!mounted) return;
      UiFeedback.showDeleted(context, 'Çek tahsili geri alındı.');
      _loadAvailable();
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
  }

  Future<void> _complete() async {
    if (_selected.isEmpty) {
      UiFeedback.showError(context, 'Lütfen en az bir çek tahsil ediniz.');
      return;
    }
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      await _headerSvc.complete(token, _headerId!);
      if (!mounted) return;
      UiFeedback.showSuccess(context, 'Tahsil tamamlandı.', autoPop: true);
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  double get _toplamTutar =>
      _selected.fold(0.0, (s, h) => s + (h.Tutar ?? 0.0));

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
          Text('Yeni Portföyden Tahsil',
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
          _buildSection('Tahsil Bilgileri', Icons.savings_rounded, [
            _fieldRow(
                'Tahsil Yeri',
                DropdownButtonFormField<int>(
                  isExpanded: true,
                  value: _seciliTahsilyeri,
                  decoration: _dec('Tahsil Yeri'),
                  style: _style,
                  onChanged: (v) {
                    if (v != null)
                      setState(() {
                        _seciliTahsilyeri = v;
                        _seciliKasa = null;
                        _seciliHesap = null;
                      });
                  },
                  items: TahsilyeriCouples.list
                      .map((e) => DropdownMenuItem(
                          value: e.value,
                          child: Text(e.text,
                              style: const TextStyle(
                                  fontFamily: 'Roboto', fontSize: 13))))
                      .toList(),
                )),
            const SizedBox(height: 10),
            if (_kasaGerekli) _buildKasaDropdown(),
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
                  Tab(height: 40, text: 'Portföydeki Çekler'),
                  Tab(height: 40, text: 'Tahsil Edilen Çekler')
                ],
              )),
          Expanded(
            child: TabBarView(children: [
              _availLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _available.isEmpty
                      ? _emptyMini('Portföyde tahsile uygun çek bulunamadı')
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                          itemCount: _available.length,
                          itemBuilder: (_, i) =>
                              _buildAvailableCard(_available[i]),
                        ),
              _selected.isEmpty
                  ? _emptyMini('Henüz çek tahsil edilmedi')
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
                  _kasaGerekli
                      ? (_seciliKasa?.Ad ?? '')
                      : (_seciliHesap?.Ad ?? ''),
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _kDark),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              Text('${_selected.length} çek tahsil edildi',
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
                  color: _kGreen)),
        ]),
      );

  Widget _buildTamamlaBar() => Container(
        color: _scheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
        child: SizedBox(
          width: double.infinity,
          height: 46,
          child: PermissionAction(
              modules: [1011],
              access: Access.write,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kGreen,
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
    final kismi = (h.Kismitahsiltutar ?? 0) > 0;
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
                      if (kismi) ...[
                        const SizedBox(height: 3),
                        Text(
                            'Kalan: ${_moneyFmt.format((h.Tutar ?? 0) - (h.Kismitahsiltutar ?? 0))}',
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 10,
                                color: _kGold,
                                fontWeight: FontWeight.w600)),
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
                Icon(Icons.add_circle_rounded, color: _kBlue, size: 22),
              ]),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCard(CekalinanportfoydentahsilhareketDto h) {
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
              if (h.Masraf != null && h.Masraf! > 0) ...[
                const SizedBox(height: 3),
                Text(
                    'Masraf: ${_moneyFmt.format(h.Masraf)}${h.Masraficindenmi == true ? ' (içinden)' : ''}',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        color: _scheme.onSurfaceVariant)),
              ],
            ]),
          ),
          Text(_moneyFmt.format(h.Tutar ?? 0),
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _kGreen)),
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

  Widget _buildKasaDropdown() => _fieldRow(
      'Kasa *',
      DropdownSearch<KasaDto>(
        items: _kasalar,
        selectedItem: _seciliKasa,
        itemAsString: (k) => '${k.Ad ?? ''} (${k.Kod ?? ''})',
        compareFn: (a, b) => a.Id == b.Id,
        onChanged: (v) => setState(() => _seciliKasa = v),
        popupProps: PopupProps.bottomSheet(
          title: const PopupKapatBasligi(),
          showSearchBox: true,
          searchFieldProps:
              TextFieldProps(decoration: _searchDec('Kasa ara...')),
          bottomSheetProps: const BottomSheetProps(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              constraints: BoxConstraints(maxHeight: 480)),
        ),
        dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: _dec('Kasa seçiniz')),
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
