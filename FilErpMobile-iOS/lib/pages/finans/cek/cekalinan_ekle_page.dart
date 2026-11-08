import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/erp_page_style.dart';
import '../../../services/finans/bordro_kayit_service.dart';
import 'package:flutter/material.dart';
import '../../../widgets/popup_kapat_basligi.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../../models/entities/finans/cek/cekalinan_create_dto.dart';
import '../../../models/entities/finans/cek/cekalinanhareket_create_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/yonetim/belge_seri_dto.dart';
import '../../../services/finans/cekalinan_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../services/plasiyer/plasiyer_service.dart';
import '../../../services/cari/cari_service.dart';
import '../../../services/yonetim/belgeseri_service.dart';
import '../../../services/yonetim/kur_service.dart';
import '../../../helpers/cari_plasiyer_helper.dart';
import '../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../widgets/cari_bakiye_satiri.dart';
import '../../../helpers/varsayilan_proje_helper.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/belge_turu_couples.dart';
import '../../../helpers/number_format_helper.dart';
import '../../../services/offline/offline_service.dart';

final _fmt = DateFormat('dd.MM.yyyy');

DateTime? _parseDate(String s) {
  try {
    return DateFormat('dd.MM.yyyy').parse(s);
  } catch (_) {
    return null;
  }
}

/// TRY (TL) mi?
bool _isTry(DovizDto? d) {
  final b = (d?.Birim ?? '').trim().toUpperCase();
  return b == 'TL' || b == 'TRY' || b == '₺';
}

bool _isDovizliOf(DovizDto? d) => d != null && !_isTry(d);

DovizDto? _findTry(List<DovizDto> list) => list.where(_isTry).firstOrNull;

/// IBAN: büyük harf, sadece harf/rakam, her zaman "TR" ile başlar, en fazla 26 karakter.
class _IbanFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nw) {
    var t = nw.text.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (t.length < 2) {
      t = 'TR';
    } else if (!t.startsWith('TR')) {
      t = 'TR${t.replaceFirst(RegExp(r'^[A-Z]{0,2}'), '')}';
    }
    if (t.length > 26) t = t.substring(0, 26);
    return TextEditingValue(
        text: t, selection: TextSelection.collapsed(offset: t.length));
  }
}

class _TutarFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue old, TextEditingValue nw) {
    final raw = nw.text;
    if (raw.isEmpty) return nw;
    final cleaned = raw.replaceAll(RegExp(r'[^\d,]'), '');
    final parts = cleaned.split(',');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : null;
    final n = int.tryParse(intPart.replaceAll('.', '')) ?? 0;
    final formatted = NumberFormat('#,##0', 'tr_TR').format(n);
    final result = decPart != null ? '$formatted,$decPart' : formatted;
    return TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length));
  }
}

// ── Ortak UI yardımcıları ─────────────────────────────────────────────────────

class _CekItem {
  String? cekSeri;
  String belgeNo = '';
  String cekNumarasi = '';
  DateTime? vade;
  DateTime? odeme;
  bool ciro = false; // false: Asıl, true: Ciro
  String ciroCari = '';
  String ciroVkn = '';
  String bankaAdi = '';
  String subeAdi = '';
  String hesapNo = '';
  String iban = '';
  DovizDto? doviz;
  double kur = 0;
  DateTime? dovizTarih;
  double dovizTutar = 0;
  double tutar = 0;

  bool get isDovizli => _isDovizliOf(doviz);
}

/// Hesap no boş bırakılırsa / IBAN boş bırakılırsa kullanılan varsayılanlar.
const _kVarsayilanBankaAdi = 'BANKA';
const _kVarsayilanSubeAdi = 'BANKA ŞUBE';
const _kVarsayilanHesapNo = '111111';
final _kVarsayilanIban = 'TR${'1' * 24}';

// ── Sayfa ─────────────────────────────────────────────────────────────────────
// Sekmeler: Belge • İşlem • Tutar • Detay.
// Belge ve Detay bordro (üst bilgi) içindir; İşlem ve Tutar o an girilen belgeye aittir.
// "Çek Ekle" ile çek bordroya eklenir ve İşlem/Tutar boşalır; böylece aynı bordroya birden çok çek girilebilir.
class CekalinanEklePage extends StatefulWidget {
  const CekalinanEklePage({super.key});

  @override
  State<CekalinanEklePage> createState() => _CekalinanEklePageState();
}

class _CekalinanEklePageState extends State<CekalinanEklePage>
    with SingleTickerProviderStateMixin {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;
  Color get _kBlue => _scheme.primary;
  Color get _kRed => _scheme.error;
  Color get _kGreen => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF6EE7B7)
      : const Color(0xFF0E7C5A);

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
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
      );

  InputDecoration _searchDec(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Roboto',
            color: _scheme.onSurfaceVariant,
            fontSize: 13),
        prefixIcon: const Icon(Icons.search_rounded, size: 18),
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

  Widget _dateField(BuildContext context, TextEditingController ctrl,
          {required Function(DateTime?) onChanged}) =>
      TextFormField(
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
          if (picked != null) {
            ctrl.text = _fmt.format(picked);
            onChanged(picked);
          }
        },
      );

  Widget _tutarField(TextEditingController ctrl, String hint,
          {bool required = false}) =>
      TextFormField(
        controller: ctrl,
        style: _style,
        textAlign: TextAlign.right,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_TutarFormatter()],
        decoration: _dec(hint),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Tutar giriniz' : null
            : null,
      );

  Widget _pickerField<T>({
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required bool enabled,
    required ValueChanged<T> onSelected,
  }) =>
      PopupMenuButton<T>(
        enabled: enabled && items.isNotEmpty,
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
            color: enabled ? _scheme.surface : _scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _scheme.outlineVariant),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(
              child: Text(
                value != null ? itemLabel(value) : '-',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    color: enabled ? _kDark : _scheme.onSurfaceVariant),
              ),
            ),
            if (enabled) ...[
              const SizedBox(width: 2),
              Icon(Icons.expand_more_rounded,
                  size: 16, color: _scheme.onSurfaceVariant),
            ],
          ]),
        ),
      );

  /// Bordro seri / yıl / no satırı (bordro için sayfada, çek için formda kullanılır)
  Widget _seriTable({
    required String label,
    required String? seciliSeri,
    required List<BelgeSeriDto> seriler,
    required int yil,
    List<int>? yilListesi,
    required TextEditingController noCtrl,
    required FocusNode noFocus,
    required ValueChanged<String?> onSeriChanged,
    ValueChanged<int>? onYilSelected,
    required VoidCallback onRefresh,
  }) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
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
              value: seciliSeri,
              items: seriler.map((s) => s.seri ?? '-').toList(),
              itemLabel: (v) => v,
              enabled: true,
              onSelected: onSeriChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _pickerField<int>(
              value: yil,
              items: yilListesi ?? [yil],
              itemLabel: (v) => '$v',
              enabled: onYilSelected != null,
              onSelected: (v) => onYilSelected?.call(v),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: noCtrl,
              focusNode: noFocus,
              style: _style,
              decoration: _dec('Belge No').copyWith(
                suffixIcon: IconButton(
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  onPressed: onRefresh,
                ),
              ),
            ),
          ),
        ]),
      ]);

  void _normalizeNo(TextEditingController ctrl) {
    final raw = ctrl.text.trim();
    if (raw.isEmpty) return;
    final n = int.tryParse(raw.replaceAll(RegExp(r'[^\d]'), ''));
    if (n != null) ctrl.text = n.toString().padLeft(9, '0');
  }

// ── Bordroya eklenen tek bir çek ──────────────────────────────────────────────

  final _svc = CekalinanService();
  late final TabController _tabs;

  bool _loading = true;
  bool _saving = false;
  bool _plasiyerKilitli =
      false; // Plasiyer kullanıcısı: kendi plasiyeri, değiştirilemez
  String _ilkImza = ''; // çıkışta "kaydedilmemiş değişiklik" kontrolü için

  List<DovizDto> _dovizler = [];
  List<ProjeDto> _projeler = [];
  List<PlasiyerDto> _plasiyerler = [];
  List<CariDtoLite> _cariler = [];
  List<BelgeSeriDto> _bordroSeriler = [];
  List<BelgeSeriDto> _cekSeriler = [];

  // Bordro (üst bilgi)
  CariDtoLite? _seciliCari;
  ProjeDto? _seciliProje;
  PlasiyerDto? _seciliPlasiyer;
  int _seciliYil = DateTime.now().year;
  String? _bordroSeri;
  late List<int> _yilListesi;
  late final TextEditingController _tarihCtrl;
  late final TextEditingController _bordroNoCtrl;
  late final TextEditingController _makbuzNoCtrl;
  late final TextEditingController _aciklamaCtrl;
  final _bordroNoFocus = FocusNode();

  // Bordroya eklenmiş çekler
  final List<_CekItem> _cekler = [];

  // Şu an girilen çek (İşlem + Tutar sekmeleri)
  String? _cekSeri;
  DovizDto? _doviz;
  bool _ciro = false;
  late final TextEditingController _cekNoCtrl; // çek belge no
  late final TextEditingController _matbuCtrl; // matbu çek numarası
  late final TextEditingController _vadeCtrl;
  late final TextEditingController _odemeCtrl;
  late final TextEditingController _ciroCariCtrl;
  late final TextEditingController _ciroVknCtrl;
  late final TextEditingController _bankaAdiCtrl;
  late final TextEditingController _bankaSubeCtrl;
  late final TextEditingController _hesapNoCtrl;
  late final TextEditingController _ibanCtrl;
  late final TextEditingController _kurCtrl;
  late final TextEditingController _dovizTarihCtrl;
  late final TextEditingController _dovizTutarCtrl;
  late final TextEditingController _tutarCtrl;
  final _cekNoFocus = FocusNode();

  bool get _isDovizli => _isDovizliOf(_doviz);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _yilListesi = List.generate(7, (i) => now.year - i);
    _tabs = TabController(length: 4, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });

    _tarihCtrl = TextEditingController(text: _fmt.format(now));
    _bordroNoCtrl = TextEditingController();
    _makbuzNoCtrl = TextEditingController();
    _aciklamaCtrl = TextEditingController();

    _cekNoCtrl = TextEditingController();
    _matbuCtrl = TextEditingController();
    _vadeCtrl = TextEditingController(text: _fmt.format(now));
    _odemeCtrl = TextEditingController(
        text: _fmt
            .format(now)); // ödeme tarihi varsayılan olarak vade tarihine eşit
    _ciroCariCtrl = TextEditingController();
    _ciroVknCtrl = TextEditingController();
    _bankaAdiCtrl = TextEditingController();
    _bankaSubeCtrl = TextEditingController();
    _hesapNoCtrl = TextEditingController();
    _ibanCtrl = TextEditingController(text: 'TR');
    _kurCtrl = TextEditingController();
    _dovizTarihCtrl = TextEditingController(text: _fmt.format(now));
    _dovizTutarCtrl = TextEditingController();
    _tutarCtrl = TextEditingController();

    _bordroNoFocus.addListener(() {
      if (!_bordroNoFocus.hasFocus) _normalizeNo(_bordroNoCtrl);
    });
    _cekNoFocus.addListener(() {
      if (!_cekNoFocus.hasFocus) _normalizeNo(_cekNoCtrl);
    });

    // Metin değişiklikleri: bakiye önizlemesi ve çıkış uyarısı (PopScope) güncellensin
    for (final c in [
      _tarihCtrl,
      _bordroNoCtrl,
      _makbuzNoCtrl,
      _aciklamaCtrl,
      _cekNoCtrl,
      _matbuCtrl,
      _vadeCtrl,
      _odemeCtrl,
      _ciroCariCtrl,
      _ciroVknCtrl,
      _bankaAdiCtrl,
      _bankaSubeCtrl,
      _hesapNoCtrl,
      _ibanCtrl,
      _kurCtrl,
      _dovizTarihCtrl,
      _dovizTutarCtrl,
      _tutarCtrl,
    ]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }

    _loadLookups();
  }

  @override
  void dispose() {
    _tabs.dispose();
    for (final c in [
      _tarihCtrl,
      _bordroNoCtrl,
      _makbuzNoCtrl,
      _aciklamaCtrl,
      _cekNoCtrl,
      _matbuCtrl,
      _vadeCtrl,
      _odemeCtrl,
      _ciroCariCtrl,
      _ciroVknCtrl,
      _bankaAdiCtrl,
      _bankaSubeCtrl,
      _hesapNoCtrl,
      _ibanCtrl,
      _kurCtrl,
      _dovizTarihCtrl,
      _dovizTutarCtrl,
      _tutarCtrl,
    ]) {
      c.dispose();
    }
    _bordroNoFocus.dispose();
    _cekNoFocus.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    final now = DateTime.now();

    final results = await Future.wait([
      DovizService().getDovizler(token).catchError((_) => <DovizDto>[]),
      ProjeService().getProjeList(token).catchError((_) => <ProjeDto>[]),
      PlasiyerService()
          .getPlasiyerler(token)
          .catchError((_) => <PlasiyerDto>[]),
      CariService().getCariler(token).catchError((_) => <CariDtoLite>[]),
      BelgeSeriService()
          .getAll(token, BelgeTuruCouples.cekBordroMusteri)
          .catchError((_) => <BelgeSeriDto>[]),
      BelgeSeriService()
          .getAll(token, BelgeTuruCouples.cekMusteri)
          .catchError((_) => <BelgeSeriDto>[]),
    ]);

    if (!mounted) return;
    _dovizler = results[0] as List<DovizDto>;
    _projeler = results[1] as List<ProjeDto>;
    _plasiyerler = results[2] as List<PlasiyerDto>;
    _cariler = results[3] as List<CariDtoLite>;
    _bordroSeriler = results[4] as List<BelgeSeriDto>;
    _cekSeriler = results[5] as List<BelgeSeriDto>;

    _doviz = _findTry(_dovizler);

    // Plasiyer: kullanıcı plasiyer ise kendisi (kilitli), değilse ilk kayıt (değiştirilebilir)
    final kp = await KullaniciPlasiyerHelper.getir();
    if (kp.kilitli) {
      _plasiyerKilitli = true;
      _seciliPlasiyer =
          _plasiyerler.where((p) => p.Id == kp.plasiyerid).firstOrNull;
    }
    _seciliPlasiyer ??= _plasiyerler.firstOrNull;

    final prid = await VarsayilanProjeHelper.pickFrom(_projeler);
    _seciliProje = _projeler.where((p) => p.id == prid).firstOrNull ??
        _projeler.firstOrNull;

    if (_bordroSeriler.isNotEmpty) {
      _bordroSeri = _bordroSeriler.first.seri;
      try {
        final no = await _svc.getNewCekalinanNo(token, _bordroSeri!, now.year);
        if (mounted) _bordroNoCtrl.text = no;
      } catch (_) {}
    }
    if (_cekSeriler.isNotEmpty) {
      _cekSeri = _cekSeriler.first.seri;
      final no = await _nextCekNo(_cekSeri!);
      if (no != null && mounted) _cekNoCtrl.text = no;
    }

    _ilkImza = _imza();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fetchBordroNo() async {
    if (_bordroSeri == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    try {
      final no = await _svc.getNewCekalinanNo(token, _bordroSeri!, _seciliYil);
      if (mounted)
        setState(() {
          _bordroNoCtrl.text = no;
        });
    } catch (_) {}
  }

  Future<void> _fetchCekNo() async {
    if (_cekSeri == null) return;
    final no = await _nextCekNo(_cekSeri!);
    if (no != null && mounted) setState(() => _cekNoCtrl.text = no);
  }

  /// Yeni çek için sıradaki belge no: sunucudan gelen no ile bordrodaki aynı serili çeklerin en büyüğü+1'in büyüğü.
  Future<String?> _nextCekNo(String seri) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    String? no;
    try {
      no = await _svc.getNewCekalinanhareketNo(token, seri, _seciliYil);
    } catch (_) {}
    var n = int.tryParse((no ?? '').replaceAll(RegExp(r'[^\d]'), ''));
    for (final c in _cekler.where((c) => c.cekSeri == seri)) {
      final cn = int.tryParse(c.belgeNo.replaceAll(RegExp(r'[^\d]'), ''));
      if (cn != null && (n == null || cn >= n)) n = cn + 1;
    }
    if (n == null) return no;
    return n.toString().padLeft(9, '0');
  }

  Future<void> _fetchKur(DateTime? date) async {
    if (!_isDovizli || _doviz?.Id == null || date == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    try {
      final kurDto =
          await KurService().getByDovizIdAndDate(token, _doviz!.Id!, date);
      final kur = kurDto?.Dovizsatis ?? kurDto?.Dovizalis;
      if (kur != null && mounted)
        setState(() {
          _kurCtrl.text = NumberFormatHelper.format(kur, decimal: 4);
        });
    } catch (_) {}
  }

  // ── Çek formu: doğrulama / ekleme ────────────────────────────────────────────
  /// İşlem sekmesi (çek bilgileri) için eksik/hatalı alan mesajı.
  String? _islemHatasi() {
    if (_cekSeriler.isNotEmpty && _cekSeri == null)
      return 'Lütfen çek serisi seçiniz.';
    if (_cekNoCtrl.text.trim().isEmpty)
      return 'Çek belge numarası alınamadı, seriyi yeniden seçiniz.';
    if (_parseDate(_vadeCtrl.text) == null) return 'Vade tarihi giriniz.';
    final iban = _ibanCtrl.text.trim();
    if (iban.length > 2 && iban.length != 26)
      return 'IBAN 26 karakter olmalıdır (TR + 24 hane).';
    return null;
  }

  /// Tutar sekmesi için eksik/hatalı alan mesajı.
  String? _tutarHatasi() {
    if (_doviz == null) return 'Lütfen döviz tipi seçiniz.';
    if (_isDovizli && NumberFormatHelper.parse(_kurCtrl.text) <= 0)
      return 'Döviz tipi TL olmadığından kur giriniz.';
    if (_isDovizli && NumberFormatHelper.parse(_dovizTutarCtrl.text) <= 0)
      return 'Lütfen döviz tutar giriniz.';
    if (NumberFormatHelper.parse(_tutarCtrl.text) <= 0)
      return 'Lütfen tutar giriniz.';
    return null;
  }

  /// Çek formunda herhangi bir şey girildi mi? (bordroda zaten çek varsa boş form hata sayılmaz)
  bool get _cekFormDolu =>
      NumberFormatHelper.parse(_tutarCtrl.text) > 0 ||
      _matbuCtrl.text.trim().isNotEmpty;

  _CekItem _formdanCek() {
    final iban = _ibanCtrl.text.trim();
    final hesap = _hesapNoCtrl.text.trim();
    return _CekItem()
      ..cekSeri = _cekSeri
      ..belgeNo = _cekNoCtrl.text.trim()
      ..cekNumarasi = _matbuCtrl.text.trim()
      ..vade = _parseDate(_vadeCtrl.text)
      ..odeme =
          _odemeCtrl.text.trim().isEmpty ? null : _parseDate(_odemeCtrl.text)
      ..ciro = _ciro
      ..ciroCari = _ciro ? _ciroCariCtrl.text.trim() : ''
      ..ciroVkn = _ciro ? _ciroVknCtrl.text.trim() : ''
      ..bankaAdi = _bankaAdiCtrl.text.trim().isEmpty
          ? _kVarsayilanBankaAdi
          : _bankaAdiCtrl.text.trim()
      ..subeAdi = _bankaSubeCtrl.text.trim().isEmpty
          ? _kVarsayilanSubeAdi
          : _bankaSubeCtrl.text.trim()
      ..hesapNo = hesap.isEmpty ? _kVarsayilanHesapNo : hesap
      ..iban = iban.length <= 2
          ? _kVarsayilanIban
          : iban // boş bırakılırsa TR + 24 tane 1
      ..doviz = _doviz
      ..kur = _isDovizli ? NumberFormatHelper.parse(_kurCtrl.text) : 0
      ..dovizTarih = _parseDate(_dovizTarihCtrl.text)
      ..dovizTutar =
          _isDovizli ? NumberFormatHelper.parse(_dovizTutarCtrl.text) : 0
      ..tutar = NumberFormatHelper.parse(_tutarCtrl.text);
  }

  void _cekiFormaYukle(_CekItem c) {
    _cekSeri = c.cekSeri;
    _cekNoCtrl.text = c.belgeNo;
    _matbuCtrl.text = c.cekNumarasi;
    _vadeCtrl.text = c.vade != null ? _fmt.format(c.vade!) : '';
    _odemeCtrl.text = c.odeme != null ? _fmt.format(c.odeme!) : '';
    _ciro = c.ciro;
    _ciroCariCtrl.text = c.ciroCari;
    _ciroVknCtrl.text = c.ciroVkn;
    _bankaAdiCtrl.text = c.bankaAdi == _kVarsayilanBankaAdi ? '' : c.bankaAdi;
    _bankaSubeCtrl.text = c.subeAdi == _kVarsayilanSubeAdi ? '' : c.subeAdi;
    _hesapNoCtrl.text = c.hesapNo == _kVarsayilanHesapNo ? '' : c.hesapNo;
    _ibanCtrl.text = c.iban == _kVarsayilanIban ? 'TR' : c.iban;
    _doviz = c.doviz;
    _kurCtrl.text = (c.isDovizli && c.kur != 0)
        ? NumberFormatHelper.format(c.kur, decimal: 4)
        : '';
    _dovizTarihCtrl.text = _fmt.format(c.dovizTarih ?? DateTime.now());
    _dovizTutarCtrl.text = (c.isDovizli && c.dovizTutar != 0)
        ? NumberFormatHelper.format(c.dovizTutar)
        : '';
    _tutarCtrl.text = c.tutar != 0 ? NumberFormatHelper.format(c.tutar) : '';
  }

  /// Çek eklendikten sonra İşlem/Tutar sekmelerini yeni bir çek için hazırlar.
  void _cekFormunuSifirla() {
    final now = DateTime.now();
    _matbuCtrl.clear();
    _ciro = false;
    _ciroCariCtrl.clear();
    _ciroVknCtrl.clear();
    _bankaAdiCtrl.clear();
    _bankaSubeCtrl.clear();
    _hesapNoCtrl.clear();
    _ibanCtrl.text = 'TR';
    _vadeCtrl.text = _fmt.format(now);
    _odemeCtrl.text = _fmt.format(now);
    _kurCtrl.clear();
    _dovizTutarCtrl.clear();
    _tutarCtrl.clear();
    _doviz = _findTry(_dovizler);
    _fetchCekNo();
  }

  void _cekEkle() {
    final h = _islemHatasi();
    if (h != null) {
      _tabs.animateTo(1);
      UiFeedback.showError(context, h);
      return;
    }
    final t = _tutarHatasi();
    if (t != null) {
      _tabs.animateTo(2);
      UiFeedback.showError(context, t);
      return;
    }

    setState(() {
      _cekler.add(_formdanCek());
      _cekFormunuSifirla();
    });
    _tabs.animateTo(1);
    UiFeedback.showSuccess(context,
        'Çek bordroya eklendi (${_cekler.length}). Sıradaki çeki girebilirsiniz.');
  }

  void _cekDuzenle(_CekItem c) {
    if (_cekFormDolu) {
      UiFeedback.showError(
          context, 'Önce girmekte olduğunuz çeki ekleyin ya da temizleyin.');
      return;
    }
    setState(() {
      _cekler.remove(c);
      _cekiFormaYukle(c);
    });
    _tabs.animateTo(1);
  }

  Future<void> _cekSil(_CekItem c) async {
    final ok = await UiFeedback.confirm(context,
        title: 'Çeki Sil',
        message: 'Bu çek bordrodan çıkarılsın mı?',
        confirmLabel: 'Sil',
        cancelLabel: 'Vazgeç',
        destructive: true);
    if (ok && mounted) setState(() => _cekler.remove(c));
  }

  double get _bordroToplam => _cekler.fold(0.0, (s, c) => s + c.tutar);

  /// Çek girişi cariyi alacaklandırır: bakiye (borç +) bordrodaki çekler ve girilen çek kadar azalır.
  double? get _bakiyeDegisim {
    if (_seciliCari == null) return null;
    return -(_bordroToplam + NumberFormatHelper.parse(_tutarCtrl.text));
  }

  // ── Sekme geçişi: alanlar doldurulmadan ilerlenemez ──────────────────────────
  String? _sekmeHatasi(int i) {
    switch (i) {
      case 0:
        if (_parseDate(_tarihCtrl.text) == null) return 'Lütfen tarih seçiniz.';
        if (_seciliCari == null) return 'Lütfen cari seçiniz.';
        if (_bordroSeriler.isNotEmpty && _bordroSeri == null)
          return 'Lütfen bordro serisi seçiniz.';
        if (_bordroNoCtrl.text.trim().isEmpty)
          return 'Bordro numarası alınamadı, seriyi yeniden seçiniz.';
        return null;
      case 1:
        if (_cekler.isNotEmpty && !_cekFormDolu)
          return null; // zaten çek eklenmiş, yeni çek girilmiyor
        return _islemHatasi();
      case 2:
        if (_cekler.isNotEmpty && !_cekFormDolu) return null;
        return _tutarHatasi();
    }
    return null;
  }

  (int, String)? _ilerlemeEngeli(int hedef) {
    for (var i = 0; i < hedef; i++) {
      final h = _sekmeHatasi(i);
      if (h != null) return (i, h);
    }
    return null;
  }

  void _ileri() {
    if (_tabs.index < _tabs.length - 1) {
      final h = _sekmeHatasi(_tabs.index);
      if (h != null) {
        UiFeedback.showError(context, h);
        return;
      }
      _tabs.animateTo(_tabs.index + 1);
    } else {
      _save();
    }
  }

  void _geri() {
    if (_tabs.index > 0) _tabs.animateTo(_tabs.index - 1);
  }

  void _sekmeTikla(int hedef) {
    if (hedef <= _tabs.previousIndex) return;
    final e = _ilerlemeEngeli(hedef);
    if (e != null) {
      UiFeedback.showError(context, e.$2);
      _tabs.animateTo(e.$1);
    }
  }

  // ── Kaydedilmemiş değişiklik kontrolü ────────────────────────────────────────
  String _imza() => [
        _seciliCari?.Id,
        _seciliPlasiyer?.Id,
        _seciliProje?.id,
        _bordroSeri,
        _seciliYil,
        _cekSeri,
        _doviz?.Id,
        _ciro,
        _tarihCtrl.text,
        _bordroNoCtrl.text,
        _makbuzNoCtrl.text,
        _aciklamaCtrl.text,
        _cekNoCtrl.text,
        _matbuCtrl.text,
        _vadeCtrl.text,
        _odemeCtrl.text,
        _ciroCariCtrl.text,
        _ciroVknCtrl.text,
        _bankaAdiCtrl.text,
        _bankaSubeCtrl.text,
        _hesapNoCtrl.text,
        _ibanCtrl.text,
        _kurCtrl.text,
        _dovizTarihCtrl.text,
        _dovizTutarCtrl.text,
        _tutarCtrl.text,
        _cekler.length,
      ].join('|');

  bool get _degisti => !_loading && !_saving && _imza() != _ilkImza;

  Future<void> _cikisSor() async {
    final cik = await UiFeedback.confirm(
      context,
      title: 'Sayfadan Çık',
      message:
          'Girdiğiniz bilgiler kaydedilmedi. Çıkarsanız kaybolacak. Çıkmak istiyor musunuz?',
      confirmLabel: 'Çık',
      cancelLabel: 'Kal',
      destructive: true,
    );
    if (cik && mounted) Navigator.of(context).pop();
  }

  // ── Kaydet ────────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    final bordroHata = _sekmeHatasi(0);
    if (bordroHata != null) {
      _tabs.animateTo(0);
      UiFeedback.showError(context, bordroHata);
      return;
    }

    // Formda yarım kalmış çek varsa o da bordroya dahil edilir (önce doğrulanır)
    final listedekiler = List<_CekItem>.from(_cekler);
    if (_cekFormDolu || listedekiler.isEmpty) {
      final h = _islemHatasi();
      if (h != null) {
        _tabs.animateTo(1);
        UiFeedback.showError(
            context,
            listedekiler.isEmpty && !_cekFormDolu
                ? 'En az bir çek giriniz.'
                : h);
        return;
      }
      final t = _tutarHatasi();
      if (t != null) {
        _tabs.animateTo(2);
        UiFeedback.showError(
            context,
            listedekiler.isEmpty && !_cekFormDolu
                ? 'En az bir çek giriniz.'
                : t);
        return;
      }
      listedekiler.add(_formdanCek());
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';

      final tarih = _parseDate(_tarihCtrl.text);
      final aciklama =
          _aciklamaCtrl.text.trim().isEmpty ? null : _aciklamaCtrl.text.trim();

      final hareketler = listedekiler
          .map((c) => CekalinanhareketCreateDto()
            ..projeid = _seciliProje?.id
            ..plasiyerid = _seciliPlasiyer?.Id
            ..dovizid = c.doviz?.Id
            ..belgeseri = c.cekSeri
            ..belgeyil = _seciliYil
            ..belgeno = c.belgeNo
            ..belgeserino = '${c.cekSeri ?? ''}$_seciliYil'
            ..asilciro = c.ciro
            ..cirocariad = c.ciro && c.ciroCari.isNotEmpty ? c.ciroCari : null
            ..cirocarivergino =
                c.ciro && c.ciroVkn.isNotEmpty ? c.ciroVkn : null
            ..vadetarihi = c.vade
            ..odemetarihi = c.odeme
            ..kur = c.kur
            ..doviztarih = c.dovizTarih
            ..doviztutar = c.isDovizli ? c.dovizTutar : null
            ..tutar = c.tutar
            ..bankaadi = c.bankaAdi.isEmpty ? null : c.bankaAdi
            ..bankasubeadi = c.subeAdi.isEmpty ? null : c.subeAdi
            ..hesapno = c.hesapNo
            ..iban = c.iban
            ..ceknumarasi = c.cekNumarasi.isEmpty ? null : c.cekNumarasi
            ..aciklama = aciklama)
          .toList();

      final dto = CekalinanCreateDto()
        ..cariid = _seciliCari!.Id
        ..projeid = _seciliProje?.id
        ..plasiyerid = _seciliPlasiyer?.Id
        ..belgeseri = _bordroSeri
        ..belgeyil = _seciliYil
        ..belgeno = _bordroNoCtrl.text.trim()
        ..belgeserino = '${_bordroSeri ?? ''}$_seciliYil'
        ..belgeturu = BelgeTuruCouples.cekBordroMusteri
        ..tarih = tarih
        ..makbuzno =
            _makbuzNoCtrl.text.trim().isEmpty ? null : _makbuzNoCtrl.text.trim()
        ..cekalinanhareket = hareketler;

      // ── Offline mod kontrolü ───────────────────────────────────────────
      final manuelOffline = await OfflineService.instance.getOfflineMode();
      final internetYok = !OfflineService.instance.isOnline.value;
      if (manuelOffline || internetYok) {
        await OfflineService.instance.enqueue('single_full', {
          'endpoint': '/Cekalinan/SaveWithItems',
          'method': 'POST',
          'body': dto.toJson(),
        });
        if (!mounted) return;
        UiFeedback.showSuccess(
          context,
          internetYok
              ? "İnternet yok — kayıt kuyruğa alındı, bağlantı gelince gönderilecek"
              : "Kayıt kuyruğa eklendi — online olunca gönderilecek",
          autoPop: true,
        );
        return;
      }

      await BordroKayitService.kaydet(token, 'Cekalinan', dto.toJson(),
          dto.cekalinanhareket!.map((e) => e.toJson()).toList());

      if (!mounted) return;
      UiFeedback.showSuccess(context, 'Çek bordrosu kaydedildi.',
          autoPop: true);
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_degisti,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _cikisSor();
      },
      child: Scaffold(
        backgroundColor: _kBg,
        appBar: _buildAppBar(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabs,
                // Kaydırarak sekme atlamayı kapat: ilerleme yalnızca Sonraki / sekme başlığı ile ve kontrollü.
                physics: const NeverScrollableScrollPhysics(),
                children: [_tabBelge(), _tabIslem(), _tabTutar(), _tabDetay()],
              ),
        bottomNavigationBar: _loading ? null : _buildBottomBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _kDark,
        elevation: 0,
        centerTitle: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Yeni Müşteri Çeki',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _kDark)),
        ]),
        bottom: ErpAdaptiveTabs(
            context: context,
            tabBar: TabBar(
              controller: _tabs,
              onTap: _sekmeTikla,
              labelColor: _kBlue,
              unselectedLabelColor: _scheme.onSurfaceVariant,
              indicatorColor: _kBlue,
              dividerColor: _scheme.surfaceContainerLow,
              tabs: [
                Tab(height: 40, text: 'Belge'),
                Tab(height: 40, text: 'İşlem'),
                Tab(height: 40, text: 'Tutar'),
                Tab(height: 40, text: 'Detay'),
              ],
            )),
      );

  // ── Sekme 1: Belge ────────────────────────────────────────────────────────────
  // Tarih • Cari • Bordro Seri/Yıl/No • Makbuz No • Plasiyer
  Widget _tabBelge() => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSection('Belge', Icons.event_note_rounded, [
            _fieldRow(
                'Tarih', _dateField(context, _tarihCtrl, onChanged: (_) {})),
            const SizedBox(height: 10),
            _buildCariDropdown(),
            const SizedBox(height: 10),
            _seriTable(
              label: 'Bordro Seri / Yıl / No',
              seciliSeri: _bordroSeri,
              seriler: _bordroSeriler,
              yil: _seciliYil,
              yilListesi: _yilListesi,
              noCtrl: _bordroNoCtrl,
              noFocus: _bordroNoFocus,
              onSeriChanged: (v) {
                setState(() => _bordroSeri = v);
                _fetchBordroNo();
              },
              onYilSelected: (v) {
                setState(() => _seciliYil = v);
                _fetchBordroNo();
              },
              onRefresh: _fetchBordroNo,
            ),
            const SizedBox(height: 10),
            _fieldRow(
                'Makbuz No',
                TextFormField(
                    controller: _makbuzNoCtrl,
                    style: _style,
                    decoration: _dec('Makbuz No'))),
            const SizedBox(height: 10),
            _buildPlasiyerField(),
          ]),
        ],
      );

  // ── Sekme 2: İşlem (girilen çek) ──────────────────────────────────────────────
  // Çek Seri/Yıl/No • (Vade | Ödeme) • (Matbu Çek No | Asıl/Ciro) • [Ciro Cari] • [Ciro VKN] • (Banka | Şube) • Hesap No • IBAN
  Widget _tabIslem() => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSection('Çek Bilgileri', Icons.receipt_long_rounded, [
            _seriTable(
              label: 'Çek Seri / Yıl / No',
              seciliSeri: _cekSeri,
              seriler: _cekSeriler,
              yil: _seciliYil,
              noCtrl: _cekNoCtrl,
              noFocus: _cekNoFocus,
              onSeriChanged: (v) {
                setState(() => _cekSeri = v);
                _fetchCekNo();
              },
              onRefresh: _fetchCekNo,
            ),
            const SizedBox(height: 10),
            _pairRow(
              _fieldRow(
                  'Vade Tarihi *',
                  _dateField(context, _vadeCtrl, onChanged: (d) {
                    // Ödeme tarihi vade tarihiyle eşit gelir (sonradan elle değiştirilebilir)
                    if (d != null) _odemeCtrl.text = _fmt.format(d);
                  })),
              _fieldRow('Ödeme Tarihi',
                  _dateField(context, _odemeCtrl, onChanged: (_) {})),
            ),
            const SizedBox(height: 10),
            _pairRow(
              _fieldRow(
                  'Matbu Çek No',
                  TextFormField(
                      controller: _matbuCtrl,
                      style: _style,
                      decoration: _dec('Matbu Çek No'))),
              _fieldRow('Asıl / Ciro', _buildAsilCiroSwitch()),
            ),
            if (_ciro) ...[
              const SizedBox(height: 10),
              _fieldRow(
                  'Ciro Cari',
                  TextFormField(
                      controller: _ciroCariCtrl,
                      style: _style,
                      decoration: _dec('Ciro eden cari'))),
              const SizedBox(height: 10),
              _fieldRow(
                  'Ciro Cari VKN',
                  TextFormField(
                    controller: _ciroVknCtrl,
                    style: _style,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(11)
                    ],
                    decoration: _dec('Vergi / TC kimlik no'),
                  )),
            ],
            const SizedBox(height: 10),
            _pairRow(
              _fieldRow(
                  'Banka Adı',
                  TextFormField(
                      controller: _bankaAdiCtrl,
                      style: _style,
                      decoration: _dec('Banka Adı'))),
              _fieldRow(
                  'Şube Adı',
                  TextFormField(
                      controller: _bankaSubeCtrl,
                      style: _style,
                      decoration: _dec('Şube Adı'))),
            ),
            const SizedBox(height: 10),
            _fieldRow(
                'Hesap No',
                TextFormField(
                    controller: _hesapNoCtrl,
                    style: _style,
                    decoration: _dec('Hesap No'))),
            const SizedBox(height: 10),
            _fieldRow(
                'IBAN',
                TextFormField(
                  controller: _ibanCtrl,
                  style: _style,
                  inputFormatters: [_IbanFormatter()],
                  textCapitalization: TextCapitalization.characters,
                  decoration: _dec('IBAN'),
                )),
          ]),
        ],
      );

  /// Asıl / Ciro anahtarı (İhesap web ile aynı: kapalı = Asıl, açık = Ciro).
  Widget _buildAsilCiroSwitch() => Container(
        height: 48,
        padding: const EdgeInsets.only(left: 12, right: 4),
        decoration: BoxDecoration(
          color: _scheme.surface,
          borderRadius:
              BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
          border: Border.all(color: _scheme.outlineVariant),
        ),
        child: Row(children: [
          Expanded(child: Text(_ciro ? 'Ciro' : 'Asıl', style: _style)),
          Switch(
            value: _ciro,
            activeColor: _kBlue,
            onChanged: (v) => setState(() {
              _ciro = v;
              if (!v) {
                _ciroCariCtrl.clear();
                _ciroVknCtrl.clear();
              }
            }),
          ),
        ]),
      );

  // ── Sekme 3: Tutar (girilen çek) ──────────────────────────────────────────────
  // (Döviz | Kur) • [Kur Tarihi | Döviz Tutar] • Tutar • Bakiye
  Widget _tabTutar() => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSection('Tutar', Icons.payments_rounded, [
            if (_isDovizli)
              _pairRow(_buildDovizDropdown(),
                  _fieldRow('Kur *', _tutarField(_kurCtrl, 'Kur')))
            else
              _buildDovizDropdown(),
            if (_isDovizli) ...[
              const SizedBox(height: 10),
              _pairRow(
                _fieldRow(
                    'Kur Tarihi',
                    _dateField(context, _dovizTarihCtrl, onChanged: (d) {
                      _fetchKur(d);
                    })),
                _fieldRow('Döviz Tutar *',
                    _tutarField(_dovizTutarCtrl, 'Döviz Tutar')),
              ),
            ],
            const SizedBox(height: 10),
            _fieldRow('Tutar *', _tutarField(_tutarCtrl, 'Tutar')),
            if (_cekler.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                  'Bordroda ${_cekler.length} çek • ${NumberFormatHelper.format(_bordroToplam)} ₺ (bu çek hariç)',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11,
                      color: _scheme.onSurfaceVariant)),
            ],
            if (_seciliCari != null) ...[
              const SizedBox(height: 10),
              _buildBakiyeKutusu(),
            ],
          ]),
        ],
      );

  Widget _buildDovizDropdown() => _fieldRow(
      'Döviz *',
      DropdownButtonFormField<DovizDto>(
        isExpanded: true,
        value: _doviz,
        decoration: _dec('Döviz'),
        style: _style,
        items: _dovizler
            .map((d) => DropdownMenuItem(
                value: d,
                child: Text(d.Birim ?? '',
                    style:
                        const TextStyle(fontFamily: 'Roboto', fontSize: 13))))
            .toList(),
        onChanged: (v) => setState(() {
          _doviz = v;
          if (!_isDovizli) {
            _kurCtrl.clear();
            _dovizTutarCtrl.clear();
          } else {
            _fetchKur(_parseDate(_dovizTarihCtrl.text));
          }
        }),
      ));

  /// Cari bakiyesi + bu bordroyla oluşacak bakiye (tutar girildikçe güncellenir).
  Widget _buildBakiyeKutusu() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _kBlue.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _scheme.outlineVariant),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bakiye',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          CariBakiyeSatiri(cariId: _seciliCari!.Id, degisim: _bakiyeDegisim),
        ]),
      );

  // ── Sekme 4: Detay ────────────────────────────────────────────────────────────
  // Proje • Açıklama • (bordroya eklenen çekler)
  Widget _tabDetay() => ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSection('Detay', Icons.notes_rounded, [
            _buildProjeDropdown(),
            const SizedBox(height: 10),
            _fieldRow(
                'Açıklama',
                TextFormField(
                    controller: _aciklamaCtrl,
                    style: _style,
                    decoration: _dec('Açıklama'),
                    maxLines: 3)),
          ]),
          if (_cekler.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildSection('Bordrodaki Çekler (${_cekler.length})',
                Icons.receipt_long_rounded, [
              ..._cekler.map(_buildCekCard),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Toplam',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        color: _scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500)),
                Text('${NumberFormatHelper.format(_bordroToplam)} ₺',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: _kDark)),
              ]),
            ]),
          ],
        ],
      );

  Widget _buildCekCard(_CekItem c) {
    final baslik = c.cekNumarasi.isNotEmpty
        ? c.cekNumarasi
        : '${c.cekSeri ?? ''} ${c.belgeNo}'.trim();
    final birim = c.doviz?.Birim ?? '';
    var ek = '';
    if (c.bankaAdi.isNotEmpty && c.bankaAdi != _kVarsayilanBankaAdi)
      ek += ' • ${c.bankaAdi}';
    if (c.ciro) ek += ' • Ciro';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 2, 8),
      child: Row(children: [
        Expanded(
          child: InkWell(
            onTap: () => _cekDuzenle(c),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(baslik.isEmpty ? '-' : baslik,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _kDark)),
              const SizedBox(height: 2),
              Text('Vade: ${c.vade != null ? _fmt.format(c.vade!) : '-'}$ek',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 11.5,
                      color: _scheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text('${NumberFormatHelper.format(c.tutar)} ₺',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _kBlue)),
          if (c.isDovizli)
            Text('${NumberFormatHelper.format(c.dovizTutar)} $birim',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: _scheme.onSurfaceVariant)),
        ]),
        PermissionAction(
            modules: [1005],
            access: Access.write,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.edit_outlined, size: 19, color: _kBlue),
              onPressed: () => _cekDuzenle(c),
            )),
        PermissionAction(
            modules: [1005],
            access: Access.write,
            child: IconButton(
              visualDensity: VisualDensity.compact,
              icon: Icon(Icons.delete_outline_rounded,
                  size: 19, color: Colors.red.shade400),
              onPressed: () => _cekSil(c),
            )),
      ]),
    );
  }

  // ── Alt çubuk ─────────────────────────────────────────────────────────────────
  // Son sekmede "Çek Ekle" kendi satırında (tam genişlik); altında Önceki + Kaydet.
  // Diğer sekmelerde tek satır: Önceki + Sonraki. Etiketler tek satır kalır (sığmazsa küçülür).
  Widget _butonYazi(String t, TextStyle stil) => FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(t, maxLines: 1, softWrap: false, style: stil),
      );

  Widget _buildBottomBar() {
    final son = _tabs.index == _tabs.length - 1;
    const yaziStil = TextStyle(
        fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.w600);
    return Container(
      color: _scheme.surface,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (son) ...[
              SizedBox(
                width: double.infinity,
                height: 44,
                child: PermissionAction(
                    modules: [1005],
                    access: Access.write,
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _cekEkle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kBlue,
                        side: BorderSide(color: _kBlue),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.add_rounded, size: 20),
                      label: _butonYazi(
                        _cekler.isEmpty
                            ? 'Çek Ekle'
                            : 'Çek Ekle  (${_cekler.length} çek • ${NumberFormatHelper.format(_bordroToplam)} ₺)',
                        yaziStil,
                      ),
                    )),
              ),
              const SizedBox(height: 8),
            ],
            Row(children: [
              if (_tabs.index > 0) ...[
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 46,
                    child: OutlinedButton.icon(
                      onPressed: _saving ? null : _geri,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _kRed,
                        side: BorderSide(color: _kRed),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: _butonYazi('Önceki', yaziStil),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                flex: 3,
                child: SizedBox(
                  height: 46,
                  child: PermissionAction(
                      modules: [1005],
                      access: Access.write,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: son ? _kGreen : _kBlue,
                          foregroundColor: _scheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        icon: _saving
                            ? SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _scheme.onPrimary))
                            : Icon(
                                son
                                    ? Icons.check_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 18),
                        label: _butonYazi(
                            _saving
                                ? 'Kaydediliyor...'
                                : (son ? 'Kaydet' : 'Sonraki'),
                            yaziStil),
                        onPressed: _saving ? null : _ileri,
                      )),
                ),
              ),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Alan bileşenleri ──────────────────────────────────────────────────────────
  Widget _buildCariDropdown() => _fieldRow(
      'Cari *',
      DropdownSearch<CariDtoLite>(
        items: _cariler,
        selectedItem: _seciliCari,
        itemAsString: (c) => '${c.Kod ?? ''} - ${c.Ad ?? ''}',
        compareFn: (a, b) => a.Id == b.Id,
        filterFn: (c, q) =>
            (c.Ad ?? '').toLowerCase().contains(q.toLowerCase()) ||
            (c.Kod ?? '').toLowerCase().contains(q.toLowerCase()),
        onChanged: (v) async {
          setState(() => _seciliCari = v);
          if (v == null) return;
          final pid =
              await CariPlasiyerHelper.getPlasiyerIdOrFirst(v.Id, _plasiyerler);
          final prid = await VarsayilanProjeHelper.pickFrom(_projeler);
          if (!mounted) return;
          setState(() {
            if (!_plasiyerKilitli) {
              _seciliPlasiyer =
                  _plasiyerler.where((p) => p.Id == pid).firstOrNull ??
                      _seciliPlasiyer;
            }
            _seciliProje = _projeler.where((p) => p.id == prid).firstOrNull ??
                _seciliProje;
          });
        },
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

  Widget _buildProjeDropdown() => _fieldRow(
      'Proje',
      DropdownSearch<ProjeDto>(
        items: _projeler,
        selectedItem: _seciliProje,
        itemAsString: (p) => '${p.kod ?? ''} - ${p.ad ?? ''}',
        compareFn: (a, b) => a.id == b.id,
        onChanged: (v) => setState(() => _seciliProje = v),
        popupProps: PopupProps.bottomSheet(
          title: const PopupKapatBasligi(),
          showSearchBox: true,
          searchFieldProps:
              TextFieldProps(decoration: _searchDec('Proje ara...')),
          bottomSheetProps: const BottomSheetProps(
              shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20))),
              constraints: BoxConstraints(maxHeight: 480)),
        ),
        dropdownDecoratorProps:
            DropDownDecoratorProps(dropdownSearchDecoration: _dec('Seçiniz')),
        clearButtonProps: const ClearButtonProps(isVisible: true),
      ));

  Widget _buildPlasiyerField() {
    if (_plasiyerKilitli) {
      // Plasiyer kullanıcısı: kendi plasiyeri sabit gelir, değiştirilemez.
      final ad = _seciliPlasiyer != null
          ? '${_seciliPlasiyer!.Kod ?? ''} - ${_seciliPlasiyer!.Adsoyad ?? ''}'
          : 'Plasiyer';
      return _fieldRow(
          'Plasiyer',
          Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            decoration: BoxDecoration(
              color: _scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _scheme.outlineVariant),
            ),
            child: Row(children: [
              Expanded(
                  child: Text(ad,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          color: _scheme.onSurfaceVariant))),
              Icon(Icons.lock_outline_rounded,
                  size: 16, color: _scheme.onSurfaceVariant),
            ]),
          ));
    }
    return _fieldRow(
        'Plasiyer',
        DropdownSearch<PlasiyerDto>(
          items: _plasiyerler,
          selectedItem: _seciliPlasiyer,
          itemAsString: (p) => '${p.Kod ?? ''} - ${p.Adsoyad ?? ''}',
          compareFn: (a, b) => a.Id == b.Id,
          onChanged: (v) => setState(() => _seciliPlasiyer = v),
          popupProps: PopupProps.bottomSheet(
            title: const PopupKapatBasligi(),
            showSearchBox: true,
            searchFieldProps:
                TextFieldProps(decoration: _searchDec('Plasiyer ara...')),
            bottomSheetProps: const BottomSheetProps(
                shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20))),
                constraints: BoxConstraints(maxHeight: 420)),
          ),
          dropdownDecoratorProps:
              DropDownDecoratorProps(dropdownSearchDecoration: _dec('Seçiniz')),
          clearButtonProps: const ClearButtonProps(isVisible: true),
        ));
  }
}
