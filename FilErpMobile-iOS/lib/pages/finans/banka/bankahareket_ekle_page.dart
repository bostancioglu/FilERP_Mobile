import '../../../widgets/finance_extra_fields.dart';
import '../../../widgets/erp_record_fields.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../../widgets/popup_kapat_basligi.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dropdown_search/dropdown_search.dart';

import '../../../models/entities/finans/banka/bankahesap_dto.dart';
import '../../../models/entities/finans/banka/bankahareket_dto.dart';
import '../../../models/entities/finans/banka/bankahareket_create_dto.dart';
import '../../../models/entities/finans/banka/bankahareket_update_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/yonetim/belge_seri_dto.dart';
import '../../../services/finans/bankahesap_service.dart';
import '../../../services/finans/bankahareket_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../services/plasiyer/plasiyer_service.dart';
import '../../../services/cari/cari_service.dart';
import '../../../services/yonetim/belgeseri_service.dart';
import '../../../services/yonetim/kur_service.dart';
import '../../../helpers/cari_plasiyer_helper.dart';
import '../../../helpers/varsayilan_proje_helper.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/belge_turu_couples.dart';
import '../../../helpers/giriscikis_couples.dart';
import '../../../helpers/banka_couples.dart';
import '../../../helpers/number_format_helper.dart';
import '../../../services/offline/offline_service.dart';

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

class BankahareketEklePage extends StatefulWidget {
  final BankahesapDto? bankahesap;
  final BankahareketDto? editHareket;

  const BankahareketEklePage({super.key, this.bankahesap, this.editHareket});

  @override
  State<BankahareketEklePage> createState() => _BankahareketEklePageState();
}

class _BankahareketEklePageState extends State<BankahareketEklePage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  final _svc = BankahareketService();
  final _dto = BankahareketCreateDto();
  final _form = GlobalKey<FormState>();

  bool get _isEdit => widget.editHareket != null;

  late final _expense = RecordFieldsController([
    expenseField
  ], initial: {
    'Islemmasrafid': widget.editHareket?.Islemmasrafid,
    if (widget.editHareket?.IslemmasrafAd != null)
      'Islemmasraf': {'Ad': widget.editHareket?.IslemmasrafAd}
  })
    ..addListener(_extraChanged);
  void _extraChanged() {
    if (mounted) setState(() {});
  }

  bool get _isExpense => _seciliGirisCikis == 2 && _seciliIslemTipi == 8;
  Widget _expenseField() => ErpRecordFields(
      controller: _expense, lookup: financeFieldChoices, prefix: 'movement');
  bool _loading = true;
  bool _saving = false;

  List<BankahesapDto> _hesaplar = [];
  List<DovizDto> _dovizler = [];
  List<ProjeDto> _projeler = [];
  List<PlasiyerDto> _plasiyerler = [];
  List<BelgeSeriDto> _seriListesi = [];
  List<CariDtoLite> _cariler = [];

  BankahesapDto? _seciliHesap;
  BankahesapDto? _seciliIslemBanka;
  CariDtoLite? _seciliIslemCari;
  DovizDto? _seciliDoviz;
  ProjeDto? _seciliProje;
  PlasiyerDto? _seciliPlasiyer;

  int _seciliGirisCikis = 1;
  int _seciliIslemTipi = 5;
  int _seciliYil = DateTime.now().year;
  String? _seciliSeri;

  late List<int> _yilListesi;

  late final TextEditingController _tarihCtrl;
  late final TextEditingController _evrakTarihCtrl;
  late final TextEditingController _valorTarihCtrl;
  late final TextEditingController _belgeNoCtrl;
  late final TextEditingController _kurCtrl;
  late final TextEditingController _dovizTarihCtrl;
  late final TextEditingController _tutarCtrl;
  late final TextEditingController _dovizTutarCtrl;
  late final _charges = BankChargesController(initial: {
    'Faiz': widget.editHareket?.Faiz,
    'Kkdf': widget.editHareket?.Kkdf,
    'Ceza': widget.editHareket?.Ceza,
    'Komisyon': widget.editHareket?.Komisyon,
    'Bsmv': widget.editHareket?.Bsmv,
    'Digerucretler': widget.editHareket?.Digerucretler,
    'Faizdoviz': widget.editHareket?.Faizdoviz,
    'Kkdfdoviz': widget.editHareket?.Kkdfdoviz,
    'Cezadoviz': widget.editHareket?.Cezadoviz,
    'Dovizkomisyon': widget.editHareket?.Dovizkomisyon,
    'Dovizbsmv': widget.editHareket?.Dovizbsmv,
    'Dovizdigerucretler': widget.editHareket?.Dovizdigerucretler
  });
  TextEditingController get _komisyonCtrl => _charges.text['Komisyon']!;
  TextEditingController get _bsmvCtrl => _charges.text['Bsmv']!;
  TextEditingController get _digerCtrl => _charges.text['Digerucretler']!;
  late final TextEditingController _evrakNoCtrl;
  late final TextEditingController _aciklamaCtrl;

  final _belgeNoFocus = FocusNode();
  final _fmt = DateFormat('dd.MM.yyyy');

  static bool _birimTL(String? birim) {
    final b = (birim ?? '').trim().toUpperCase();
    return b == 'TL' || b == 'TRY' || b == '₺';
  }

  bool get _isDovizli => _seciliDoviz != null && !_birimTL(_seciliDoviz!.Birim);
  bool get _showIslemBanka => _seciliIslemTipi == 2 || _seciliIslemTipi == 3;
  bool get _showIslemCari => _seciliIslemTipi == 1;
  bool get _showKomisyon => _seciliGirisCikis == 2;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _yilListesi = List.generate(7, (i) => now.year - i);
    _dto.belgeturu = BelgeTuruCouples.bankaHareket;
    _dto.islemtipi = _seciliIslemTipi;
    _dto.giriscikis = _seciliGirisCikis;
    _dto.tarih = now;
    _dto.evraktarih = now;
    _dto.valortarihi = now;
    _dto.belgeyil = now.year;

    _tarihCtrl = TextEditingController(text: _fmt.format(now));
    _evrakTarihCtrl = TextEditingController(text: _fmt.format(now));
    _valorTarihCtrl = TextEditingController(text: _fmt.format(now));
    _belgeNoCtrl = TextEditingController();
    _kurCtrl = TextEditingController();
    _dovizTarihCtrl = TextEditingController(text: _fmt.format(now));
    _tutarCtrl = TextEditingController();
    _dovizTutarCtrl = TextEditingController();
    _evrakNoCtrl = TextEditingController();
    _aciklamaCtrl = TextEditingController();

    _belgeNoFocus.addListener(() {
      if (!_belgeNoFocus.hasFocus) _normalizeBelgeNo();
    });
    _kurCtrl.addListener(_currencyChanged);
    _dovizTutarCtrl.addListener(_amountChanged);
    _loadLookups();
  }

  @override
  void dispose() {
    _charges.dispose();
    _expense.dispose();
    _tarihCtrl.dispose();
    _evrakTarihCtrl.dispose();
    _valorTarihCtrl.dispose();
    _belgeNoCtrl.dispose();
    _kurCtrl.dispose();
    _dovizTarihCtrl.dispose();
    _tutarCtrl.dispose();
    _dovizTutarCtrl.dispose();
    _evrakNoCtrl.dispose();
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
      BankahesapService()
          .getAllWithoutAuth(token)
          .catchError((_) => <BankahesapDto>[]),
      DovizService().getDovizler(token).catchError((_) => <DovizDto>[]),
      ProjeService().getProjeList(token).catchError((_) => <ProjeDto>[]),
      PlasiyerService()
          .getPlasiyerler(token)
          .catchError((_) => <PlasiyerDto>[]),
      BelgeSeriService()
          .getAll(token, BelgeTuruCouples.bankaHareket)
          .catchError((_) => <BelgeSeriDto>[]),
      CariService().getCariler(token).catchError((_) => <CariDtoLite>[]),
    ]);

    if (!mounted) return;
    _hesaplar = results[0] as List<BankahesapDto>;
    _dovizler = results[1] as List<DovizDto>;
    _projeler = results[2] as List<ProjeDto>;
    _plasiyerler = results[3] as List<PlasiyerDto>;
    _seriListesi = results[4] as List<BelgeSeriDto>;
    _cariler = results[5] as List<CariDtoLite>;

    if (_isEdit) {
      _fillEdit();
    } else {
      // Pre-select bankahesap if provided
      if (widget.bankahesap != null) {
        _seciliHesap =
            _hesaplar.where((h) => h.Id == widget.bankahesap!.Id).firstOrNull ??
                widget.bankahesap;
        _dto.bankahesapid = _seciliHesap?.Id;
      }
      // Pre-select TL doviz
      _seciliDoviz = _dovizler.where((d) => _birimTL(d.Birim)).firstOrNull;
      _dto.dovizid = _seciliDoviz?.Id;
      // Auto belge no
      if (_seriListesi.isNotEmpty) {
        _seciliSeri = _seriListesi.first.seri;
        _dto.belgeseri = _seciliSeri;
        _dto.belgeserino = '${_seciliSeri ?? ''}${now.year}';
        try {
          final no = await _svc.getNewBelgeNo(token, _seciliSeri!, now.year);
          if (mounted) {
            _dto.belgeno = no;
            _belgeNoCtrl.text = no;
          }
        } catch (_) {}
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  void _fillEdit() {
    final h = widget.editHareket!;
    _seciliGirisCikis = h.Giriscikis ?? 1;
    _seciliIslemTipi = h.Islemtipi ?? 5;
    _seciliYil = h.Belgeyil ?? DateTime.now().year;
    _seciliSeri = h.Belgeseri;

    _seciliHesap = _hesaplar.where((x) => x.Id == h.Bankahesapid).firstOrNull ??
        (h.Bankahesapid == null
            ? null
            : BankahesapDto(Id: h.Bankahesapid, Ad: h.BankahesapAd));
    _seciliDoviz = _dovizler.where((d) => d.Id == h.Dovizid).firstOrNull;

    _seciliIslemCari =
        _cariler.where((c) => c.Id == h.Islemcariid).firstOrNull ??
            (h.Islemcariid == null
                ? null
                : CariDtoLite(Id: h.Islemcariid, Ad: h.IslemcariAd));
    _seciliIslemBanka = _hesaplar
            .where((b) => b.Id == h.Islembankahesapid)
            .firstOrNull ??
        (h.Islembankahesapid == null
            ? null
            : BankahesapDto(Id: h.Islembankahesapid, Ad: h.IslembankahesapAd));
    _seciliProje = _projeler.where((p) => p.id == h.Projeid).firstOrNull;
    _seciliPlasiyer =
        _plasiyerler.where((p) => p.Id == h.Plasiyerid).firstOrNull;
    _dto.projeid = h.Projeid;
    _dto.plasiyerid = h.Plasiyerid;
    _charges.currency(_isDovizli, h.Kur ?? 0, reprice: false);
    _tarihCtrl.text = h.Tarih != null ? _fmt.format(h.Tarih!) : '';
    _evrakTarihCtrl.text =
        h.Evraktarih != null ? _fmt.format(h.Evraktarih!) : '';
    _valorTarihCtrl.text =
        h.Valortarihi != null ? _fmt.format(h.Valortarihi!) : '';
    _dovizTarihCtrl.text =
        h.Doviztarih != null ? _fmt.format(h.Doviztarih!) : '';
    _belgeNoCtrl.text = h.Belgeno ?? '';
    _evrakNoCtrl.text = h.Evrakno ?? '';
    _aciklamaCtrl.text = h.Aciklama ?? '';
    _tutarCtrl.text =
        h.Tutar != null ? h.Tutar!.toString().replaceAll('.', ',') : '';
    _dovizTutarCtrl.text = h.Doviztutar != null
        ? h.Doviztutar!.toString().replaceAll('.', ',')
        : '';
    _kurCtrl.text = h.Kur != null ? h.Kur!.toString().replaceAll('.', ',') : '';
    _komisyonCtrl.text =
        h.Komisyon != null ? h.Komisyon!.toString().replaceAll('.', ',') : '';
    _bsmvCtrl.text =
        h.Bsmv != null ? h.Bsmv!.toString().replaceAll('.', ',') : '';
    _digerCtrl.text = h.Digerucretler != null
        ? h.Digerucretler!.toString().replaceAll('.', ',')
        : '';
  }

  void _currencyChanged() {
    if (_loading) return;
    _charges.currency(_isDovizli, NumberFormatHelper.parse(_kurCtrl.text));
    _amountChanged();
  }

  void _amountChanged() {
    if (_loading || !_isDovizli || _dovizTutarCtrl.text.trim().isEmpty) return;
    final rate = NumberFormatHelper.parse(_kurCtrl.text);
    if (rate > 0)
      _tutarCtrl.text = (NumberFormatHelper.parse(_dovizTutarCtrl.text) * rate)
          .toString()
          .replaceAll('.', ',');
  }

  void _normalizeBelgeNo() {
    final raw = _belgeNoCtrl.text.trim();
    if (raw.isEmpty) return;
    final n = int.tryParse(raw.replaceAll(RegExp(r'[^\d]'), ''));
    if (n != null) {
      final fmt = n.toString().padLeft(8, '0');
      _belgeNoCtrl.text = fmt;
    }
  }

  Future<void> _fetchNewBelgeNo() async {
    if (_seciliSeri == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    try {
      final no = await _svc.getNewBelgeNo(token, _seciliSeri!, _seciliYil);
      if (mounted)
        setState(() {
          _belgeNoCtrl.text = no;
        });
    } catch (_) {}
  }

  Future<void> _fetchKur(DateTime? date) async {
    if (!_isDovizli || _seciliDoviz?.Id == null || date == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    try {
      final kurDto = await KurService()
          .getByDovizIdAndDate(token, _seciliDoviz!.Id!, date);
      final kur = kurDto?.Dovizsatis ?? kurDto?.Dovizalis;
      if (kur != null && mounted) {
        setState(() {
          _kurCtrl.text = NumberFormatHelper.format(kur, decimal: 4);
        });
      }
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    if (_isExpense && _expense.values['Islemmasrafid'] == null) {
      UiFeedback.showError(context, 'Masraf seçiniz.');
      return;
    }
    if (_seciliHesap == null) {
      UiFeedback.showError(context, 'Lütfen banka hesabı seçiniz.');
      return;
    }
    if (_isDovizli && NumberFormatHelper.parse(_kurCtrl.text) <= 0) {
      UiFeedback.showError(context, 'Geçerli bir kur giriniz.');
      return;
    }
    if (_tutarCtrl.text.trim().isEmpty) {
      UiFeedback.showError(context, 'Tutar giriniz.');
      return;
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';

      final tutar = NumberFormatHelper.parse(_tutarCtrl.text);
      final doviztutar = NumberFormatHelper.parse(_dovizTutarCtrl.text);
      final kur = NumberFormatHelper.parse(_kurCtrl.text);

      final tarih = _parseDate(_tarihCtrl.text);
      final evraktarih = _parseDate(_evrakTarihCtrl.text);
      final valortarihi = _parseDate(_valorTarihCtrl.text);
      final doviztarih = _parseDate(_dovizTarihCtrl.text);

      if (_isEdit) {
        final upd = BankahareketUpdateDto()
          ..id = widget.editHareket!.Id
          ..islemmasrafid = _isExpense ? _expense.values['Islemmasrafid'] : null
          ..projeid = _dto.projeid
          ..plasiyerid = _dto.plasiyerid
          ..bankahesapid = _seciliHesap!.Id
          ..islemcariid = _seciliIslemCari?.Id
          ..islembankahesapid = _seciliIslemBanka?.Id
          ..dovizid = _seciliDoviz?.Id
          ..kur = _isDovizli ? kur : null
          ..doviztarih = _isDovizli ? doviztarih : null
          ..doviztutar = _isDovizli ? doviztutar : null
          ..tutar = tutar
          ..faiz = _charges.amount('Faiz', outgoing: _showKomisyon)
          ..kkdf = _charges.amount('Kkdf', outgoing: _showKomisyon)
          ..ceza = _charges.amount('Ceza', outgoing: _showKomisyon)
          ..komisyon = _charges.amount('Komisyon', outgoing: _showKomisyon)
          ..bsmv = _charges.amount('Bsmv', outgoing: _showKomisyon)
          ..digerucretler =
              _charges.amount('Digerucretler', outgoing: _showKomisyon)
          ..faizdoviz =
              _charges.amount('Faizdoviz', outgoing: _showKomisyon, fx: true)
          ..kkdfdoviz =
              _charges.amount('Kkdfdoviz', outgoing: _showKomisyon, fx: true)
          ..cezadoviz =
              _charges.amount('Cezadoviz', outgoing: _showKomisyon, fx: true)
          ..dovizkomisyon = _charges.amount('Dovizkomisyon',
              outgoing: _showKomisyon, fx: true)
          ..dovizbsmv =
              _charges.amount('Dovizbsmv', outgoing: _showKomisyon, fx: true)
          ..dovizdigerucretler = _charges.amount('Dovizdigerucretler',
              outgoing: _showKomisyon, fx: true)
          ..aciklama = _aciklamaCtrl.text.trim().isEmpty
              ? null
              : _aciklamaCtrl.text.trim()
          ..tarih = tarih
          ..evraktarih = evraktarih
          ..valortarihi = valortarihi
          ..evrakno = _evrakNoCtrl.text.trim().isEmpty
              ? null
              : _evrakNoCtrl.text.trim();

        // ── Offline mod kontrolü ─────────────────────────────────────────
        final manuelOfflineUpd = await OfflineService.instance.getOfflineMode();
        final internetYokUpd = !OfflineService.instance.isOnline.value;
        if (manuelOfflineUpd || internetYokUpd) {
          await OfflineService.instance.enqueue('single_full', {
            'endpoint': '/Bankahareket',
            'method': 'PUT',
            'body': upd.toJson(),
          });
          if (!mounted) return;
          UiFeedback.showSuccess(
            context,
            internetYokUpd
                ? "İnternet yok — kayıt kuyruğa alındı, bağlantı gelince gönderilecek"
                : "Kayıt kuyruğa eklendi — online olunca gönderilecek",
            autoPop: true,
          );
          return;
        }

        await _svc.update(token, upd);
      } else {
        _dto
          ..islemmasrafid = _isExpense ? _expense.values['Islemmasrafid'] : null
          ..projeid = _dto.projeid
          ..plasiyerid = _dto.plasiyerid
          ..bankahesapid = _seciliHesap!.Id
          ..islemcariid = _seciliIslemCari?.Id
          ..islembankahesapid = _seciliIslemBanka?.Id
          ..dovizid = _seciliDoviz?.Id
          ..giriscikis = _seciliGirisCikis
          ..islemtipi = _seciliIslemTipi
          ..belgeseri = _seciliSeri
          ..belgeyil = _seciliYil
          ..belgeno = _belgeNoCtrl.text.trim()
          ..belgeserino = '${_seciliSeri ?? ''}$_seciliYil'
          ..belgeturu = BelgeTuruCouples.bankaHareket
          ..originalflag = true
          ..kur = _isDovizli ? kur : null
          ..doviztarih = _isDovizli ? doviztarih : null
          ..doviztutar = _isDovizli ? doviztutar : null
          ..tutar = tutar
          ..faiz = _charges.amount('Faiz', outgoing: _showKomisyon)
          ..kkdf = _charges.amount('Kkdf', outgoing: _showKomisyon)
          ..ceza = _charges.amount('Ceza', outgoing: _showKomisyon)
          ..komisyon = _charges.amount('Komisyon', outgoing: _showKomisyon)
          ..bsmv = _charges.amount('Bsmv', outgoing: _showKomisyon)
          ..digerucretler =
              _charges.amount('Digerucretler', outgoing: _showKomisyon)
          ..faizdoviz =
              _charges.amount('Faizdoviz', outgoing: _showKomisyon, fx: true)
          ..kkdfdoviz =
              _charges.amount('Kkdfdoviz', outgoing: _showKomisyon, fx: true)
          ..cezadoviz =
              _charges.amount('Cezadoviz', outgoing: _showKomisyon, fx: true)
          ..dovizkomisyon = _charges.amount('Dovizkomisyon',
              outgoing: _showKomisyon, fx: true)
          ..dovizbsmv =
              _charges.amount('Dovizbsmv', outgoing: _showKomisyon, fx: true)
          ..dovizdigerucretler = _charges.amount('Dovizdigerucretler',
              outgoing: _showKomisyon, fx: true)
          ..aciklama = _aciklamaCtrl.text.trim().isEmpty
              ? null
              : _aciklamaCtrl.text.trim()
          ..tarih = tarih
          ..evraktarih = evraktarih
          ..valortarihi = valortarihi
          ..evrakno = _evrakNoCtrl.text.trim().isEmpty
              ? null
              : _evrakNoCtrl.text.trim();

        // ── Offline mod kontrolü ─────────────────────────────────────────
        final manuelOffline = await OfflineService.instance.getOfflineMode();
        final internetYok = !OfflineService.instance.isOnline.value;
        if (manuelOffline || internetYok) {
          await OfflineService.instance.enqueue('single_full', {
            'endpoint': '/Bankahareket',
            'method': 'POST',
            'body': _dto.toJson(),
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

        await _svc.create(token, _dto);
      }

      if (!mounted) return;
      UiFeedback.showSuccess(
          context, _isEdit ? 'Hareket güncellendi.' : 'Hareket kaydedildi.',
          autoPop: true);
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  DateTime? _parseDate(String s) {
    try {
      return DateFormat('dd.MM.yyyy').parse(s);
    } catch (_) {
      return null;
    }
  }

  // ── Build ──────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      bottomNavigationBar: _loading
          ? null
          : Container(
              color: _scheme.surface,
              child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
                    child: _buildSaveButton(),
                  )),
            ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(12),
                children: [
                  _buildSection('İşlem Bilgileri', Icons.swap_horiz_rounded, [
                    if (_isExpense) _expenseField(),
                    _buildHesapDropdown(),
                    const SizedBox(height: 10),
                    _pairRow(_buildGCRow(), _buildIslemTipiDropdown()),
                    if (_showIslemCari) ...[
                      const SizedBox(height: 10),
                      _buildCariDropdown()
                    ],
                    if (_showIslemBanka) ...[
                      const SizedBox(height: 10),
                      _buildIslemBankaDropdown()
                    ],
                  ]),
                  const SizedBox(height: 10),
                  _buildSection('Tarih & Belge', Icons.event_note_rounded, [
                    _buildBelgeSeriTable(),
                    const SizedBox(height: 10),
                    _pairRow(
                      _fieldRow(
                          'Tarih',
                          _buildDateField(_tarihCtrl, onChanged: (d) {
                            _dto.tarih = d;
                          })),
                      _fieldRow(
                          'Evrak Tarihi',
                          _buildDateField(_evrakTarihCtrl, onChanged: (d) {
                            _dto.evraktarih = d;
                          })),
                    ),
                    const SizedBox(height: 10),
                    _pairRow(
                      _fieldRow('Valor Tarihi',
                          _buildDateField(_valorTarihCtrl, onChanged: (_) {})),
                      _fieldRow(
                          'Evrak No',
                          TextFormField(
                              controller: _evrakNoCtrl,
                              style: _style,
                              decoration: _dec('Evrak No'))),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  _buildSection('Tutar Bilgileri', Icons.payments_rounded, [
                    _buildDovizRow(),
                    if (_isDovizli) ...[
                      const SizedBox(height: 10),
                      _pairRow(
                        _fieldRow(
                            'Kur Tarihi',
                            _buildDateField(_dovizTarihCtrl, onChanged: (d) {
                              _fetchKur(d);
                            })),
                        _fieldRow('Kur', _buildTutarField(_kurCtrl, 'Kur')),
                      ),
                      const SizedBox(height: 10),
                      _fieldRow('Döviz Tutar',
                          _buildTutarField(_dovizTutarCtrl, 'Döviz Tutar')),
                    ],
                    const SizedBox(height: 10),
                    _fieldRow('Tutar *',
                        _buildTutarField(_tutarCtrl, 'Tutar', required: true)),
                    if (_showKomisyon)
                      BankChargesSection(
                          controller: _charges, foreign: _isDovizli),
                  ]),
                  const SizedBox(height: 10),
                  _buildSection('Detay', Icons.notes_rounded, [
                    _pairRow(_buildProjeDropdown(), _buildPlasiyerDropdown()),
                    const SizedBox(height: 10),
                    _fieldRow(
                        'Açıklama',
                        TextFormField(
                            controller: _aciklamaCtrl,
                            style: _style,
                            decoration: _dec('Açıklama'),
                            maxLines: 2)),
                  ]),
                  const SizedBox(height: 4),
                ],
              ),
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(_isEdit ? 'Banka Hareketi Düzenle' : 'Yeni Banka Hareketi',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _scheme.onSurface)),
          if (widget.editHareket?.Belgeserino?.trim().isNotEmpty == true)
            Text(widget.editHareket!.Belgeserino!,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: _scheme.onSurfaceVariant)),
        ]),
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _scheme.surfaceContainerLow)),
      );

  Widget _buildSection(String title, IconData icon, List<Widget> children) =>
      Container(
        decoration: BoxDecoration(
          color: _scheme.surface,
          borderRadius:
              BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: .015),
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
                  color: _scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, size: 14, color: _scheme.primary),
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
          const SizedBox(height: 10),
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
          const SizedBox(height: 6),
          field,
        ],
      );

  Widget _pairRow(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 12),
          Expanded(child: b),
        ],
      );

  TextStyle get _style =>
      TextStyle(fontFamily: 'Roboto', fontSize: 14, color: _scheme.onSurface);

  InputDecoration _dec(String hint, {bool readOnly = false}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 13,
            color: _scheme.onSurfaceVariant),
        filled: true,
        fillColor: readOnly ? _scheme.surfaceContainerLow : _scheme.surface,
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
            borderSide: BorderSide(color: _scheme.primary, width: 1.5)),
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

  Widget _buildHesapDropdown() => _fieldRow(
      'Banka Hesabı *',
      DropdownSearch<BankahesapDto>(
        items: _hesaplar,
        selectedItem: _seciliHesap,
        itemAsString: (b) => '${b.Ad ?? ''} (${b.Kod ?? ''})',
        compareFn: (a, b) => a.Id == b.Id,
        onChanged: _isEdit
            ? null
            : (v) => setState(() {
                  _seciliHesap = v;
                  _dto.bankahesapid = v?.Id;
                }),
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
            dropdownSearchDecoration: _dec('Hesap seçiniz', readOnly: _isEdit)),
      ));

  Widget _buildGCRow() => _fieldRow(
      'Giriş / Çıkış',
      DropdownButtonFormField<int>(
        isExpanded: true,
        value: _seciliGirisCikis,
        decoration: _dec('G/Ç'),
        style: _style,
        onChanged: _isEdit
            ? null
            : (v) {
                if (v != null)
                  setState(() {
                    _seciliGirisCikis = v;
                    if (v != 2 && _seciliIslemTipi == 8) _seciliIslemTipi = 5;
                    if (!_isExpense)
                      _expense.choose('Islemmasrafid', null, null);
                  });
              },
        items: GiriscikisCouples.list
            .map((g) => DropdownMenuItem(value: g.value, child: Text(g.text)))
            .toList(),
      ));

  Widget _buildIslemTipiDropdown() => _fieldRow(
      'İşlem Tipi',
      DropdownButtonFormField<int>(
        isExpanded: true,
        value: _seciliIslemTipi,
        decoration: _dec('İşlem tipi'),
        style: _style,
        onChanged: _isEdit
            ? null
            : (v) {
                if (v == null) return;
                setState(() {
                  _seciliIslemTipi = v;
                  if (!_isExpense) _expense.choose('Islemmasrafid', null, null);
                  if (!_showIslemBanka) _seciliIslemBanka = null;
                  if (!_showIslemCari) _seciliIslemCari = null;
                });
              },
        key: ValueKey('bank-operation-$_seciliGirisCikis-$_seciliIslemTipi'),
        items: BankaIslemtipiCouples.list
            .where((t) => _isEdit
                ? t.value != 8 || _seciliGirisCikis == 2
                : ![6, 7].contains(t.value) &&
                    (_seciliGirisCikis == 2 || t.value != 8))
            .map((t) => DropdownMenuItem(
                value: t.value,
                child: Text(t.text,
                    style:
                        const TextStyle(fontFamily: 'Roboto', fontSize: 13))))
            .toList(),
      ));

  Widget _buildCariDropdown() => _fieldRow(
      'İşlem Cari',
      DropdownSearch<CariDtoLite>(
        items: _cariler,
        selectedItem: _seciliIslemCari,
        itemAsString: (c) => '${c.Ad ?? ''} (${c.Kod ?? ''})',
        compareFn: (a, b) => a.Id == b.Id,
        filterFn: (c, q) =>
            (c.Ad ?? '').toLowerCase().contains(q.toLowerCase()) ||
            (c.Kod ?? '').toLowerCase().contains(q.toLowerCase()),
        onChanged: (v) async {
          setState(() => _seciliIslemCari = v);
          if (v == null) return;
          final pid =
              await CariPlasiyerHelper.getPlasiyerIdOrFirst(v.Id, _plasiyerler);
          final prid = await VarsayilanProjeHelper.pickFrom(_projeler);
          if (!mounted) return;
          setState(() {
            _seciliPlasiyer =
                _plasiyerler.where((p) => p.Id == pid).firstOrNull ??
                    _seciliPlasiyer;
            _dto.plasiyerid = _seciliPlasiyer?.Id;
            _seciliProje = _projeler.where((p) => p.id == prid).firstOrNull ??
                _seciliProje;
            _dto.projeid = _seciliProje?.id;
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
            dropdownSearchDecoration: _dec('İşlem cari seçiniz')),
        clearButtonProps: const ClearButtonProps(isVisible: true),
      ));

  Widget _buildIslemBankaDropdown() => _fieldRow(
      'İşlem Banka Hesabı',
      DropdownSearch<BankahesapDto>(
        items: _hesaplar.where((h) => h.Id != _seciliHesap?.Id).toList(),
        selectedItem: _seciliIslemBanka,
        itemAsString: (b) => '${b.Ad ?? ''} (${b.Kod ?? ''})',
        compareFn: (a, b) => a.Id == b.Id,
        onChanged: (v) => setState(() => _seciliIslemBanka = v),
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
            dropdownSearchDecoration: _dec('İşlem banka hesabı')),
        clearButtonProps: const ClearButtonProps(isVisible: true),
      ));

  Widget _buildBelgeSeriTable() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Belge Seri / Yıl / No',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: _scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: _pickerField<String>(
              value: _seciliSeri,
              items: _seriListesi.map((s) => s.seri ?? '-').toList(),
              itemLabel: (v) => v,
              enabled: !_isEdit,
              onSelected: (v) {
                setState(() => _seciliSeri = v);
                _fetchNewBelgeNo();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: _pickerField<int>(
              value: _seciliYil,
              items: _yilListesi,
              itemLabel: (v) => '$v',
              enabled: !_isEdit,
              onSelected: (v) {
                setState(() => _seciliYil = v);
                _fetchNewBelgeNo();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: _belgeNoCtrl,
              readOnly: _isEdit,
              focusNode: _belgeNoFocus,
              style: _style,
              decoration: _dec('Belge No').copyWith(
                suffixIcon: _isEdit
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        onPressed: _fetchNewBelgeNo,
                      ),
              ),
            ),
          ),
        ]),
      ]);

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
                    color:
                        enabled ? _scheme.onSurface : _scheme.onSurfaceVariant),
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

  Widget _buildDovizRow() => _fieldRow(
      'Döviz',
      DropdownButtonFormField<DovizDto>(
        value: _seciliDoviz,
        decoration: _dec('Döviz'),
        style: _style,
        isExpanded: true,
        items: _dovizler
            .map((d) => DropdownMenuItem(
                value: d,
                child: Text('${d.Birim ?? ''} — ${d.Ad ?? ''}',
                    style:
                        const TextStyle(fontFamily: 'Roboto', fontSize: 13))))
            .toList(),
        onChanged: (v) => setState(() {
          _seciliDoviz = v;
          _charges.currency(_isDovizli, NumberFormatHelper.parse(_kurCtrl.text),
              reprice: false);
          _dto.dovizid = v?.Id;
          if (!_isDovizli) {
            _kurCtrl.clear();
            _dovizTutarCtrl.clear();
          } else
            _fetchKur(_parseDate(_dovizTarihCtrl.text));
        }),
      ));

  Widget _buildDateField(TextEditingController ctrl,
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

  Widget _buildTutarField(TextEditingController ctrl, String hint,
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

  Widget _buildProjeDropdown() => _fieldRow(
      'Proje',
      DropdownSearch<ProjeDto>(
        items: _projeler,
        selectedItem: _seciliProje,
        itemAsString: (p) => '${p.ad ?? ''} (${p.kod ?? ''})',
        compareFn: (a, b) => a.id == b.id,
        onChanged: (v) => setState(() {
          _seciliProje = v;
          _dto.projeid = v?.id;
        }),
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
        dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: _dec('Proje seçiniz')),
        clearButtonProps: const ClearButtonProps(isVisible: true),
      ));

  Widget _buildPlasiyerDropdown() => _fieldRow(
      'Plasiyer',
      DropdownSearch<PlasiyerDto>(
        items: _plasiyerler,
        selectedItem: _seciliPlasiyer,
        itemAsString: (p) => p.Adsoyad ?? '',
        compareFn: (a, b) => a.Id == b.Id,
        onChanged: (v) => setState(() {
          _seciliPlasiyer = v;
          _dto.plasiyerid = v?.Id;
        }),
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
        dropdownDecoratorProps: DropDownDecoratorProps(
            dropdownSearchDecoration: _dec('Plasiyer seçiniz')),
        clearButtonProps: const ClearButtonProps(isVisible: true),
      ));

  Widget _buildSaveButton() => SizedBox(
        width: double.infinity,
        height: 52,
        child: PermissionAction(
            modules: [1004],
            access: Access.write,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: _scheme.primary,
                foregroundColor: _scheme.onPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Icon(_isEdit ? Icons.save_rounded : Icons.add_rounded,
                      size: 20),
              label: Text(
                  _saving
                      ? 'Kaydediliyor...'
                      : (_isEdit ? 'Güncelle' : 'Kaydet'),
                  style: const TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.w600)),
              onPressed: _saving ? null : _save,
            )),
      );
}
