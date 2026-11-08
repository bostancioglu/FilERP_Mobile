import '../../../widgets/finance_extra_fields.dart';
import '../../../widgets/erp_record_fields.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/entities/finans/kasa_islem/kasa_dto.dart';
import '../../../models/entities/finans/kasa_islem/bankahesap_dto.dart';
import '../../../models/entities/finans/kasa_islem/kasahareket_create_dto.dart';
import '../../../models/entities/finans/kasa_islem/kasahareket_update_dto.dart';
import '../../../models/entities/finans/kasa_islem/kasahareket_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../widgets/cari_bakiye_satiri.dart';
import '../../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/yonetim/belge_seri_dto.dart';
import '../../../services/finans/kasa_islem_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../services/plasiyer/plasiyer_service.dart';
import '../../../services/cari/cari_service.dart';
import '../../../services/yonetim/belgeseri_service.dart';
import '../../../services/yonetim/kur_service.dart';
import '../../../helpers/cari_plasiyer_helper.dart';
import '../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../helpers/varsayilan_proje_helper.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/belge_turu_couples.dart';
import '../../../helpers/number_format_helper.dart';
import '../../../services/offline/offline_service.dart';

const _kRed = Color(0xFFD32F2F);

// ── Binlik Formatlı Tutar Formatter ──────────────────────────────────────────
class _TutarFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final raw = newValue.text;
    if (raw.isEmpty) return newValue;
    final cleaned = raw.replaceAll(RegExp(r'[^\d,]'), '');
    final parts = cleaned.split(',');
    final intPart = parts[0];
    final decPart = parts.length > 1 ? parts[1] : null;
    final n = int.tryParse(intPart) ?? 0;
    final formatted = NumberFormat('#,##0', 'tr_TR').format(n);
    final result = decPart != null ? '$formatted,$decPart' : formatted;
    return TextEditingValue(
        text: result,
        selection: TextSelection.collapsed(offset: result.length));
  }
}

// ── İşlem Yönü: Tahsil (Giriş) / Tediye (Çıkış) ─────────────────────────────
class _GirisCikisCouples {
  const _GirisCikisCouples._();
  static const list = [_GC(1, 'Tahsil'), _GC(2, 'Tediye')];
}

class _GC {
  final int value;
  final String text;
  const _GC(this.value, this.text);
}

// ── Kasa İşlem Tipi ───────────────────────────────────────────────────────────
class _IslemTipi {
  final int value;
  final String label;
  const _IslemTipi(this.value, this.label);
}

const _islemTipleri = [
  _IslemTipi(1, 'Cari'),
  _IslemTipi(2, 'Banka'),
  _IslemTipi(3, 'Kasa Transfer'),
  _IslemTipi(4, 'Devir'),
  _IslemTipi(5, 'Tahsilat'),
  _IslemTipi(6, 'Ödeme'),
  _IslemTipi(7, 'Masraf'),
];

class KasahareketEklePage extends StatefulWidget {
  final KasahareketDto? editHareket;

  const KasahareketEklePage({super.key, this.editHareket});

  @override
  State<KasahareketEklePage> createState() => _KasahareketEklePageState();
}

class _KasahareketEklePageState extends State<KasahareketEklePage>
    with SingleTickerProviderStateMixin {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  final _svc = KasaIslemService();
  final _dto = KasahareketCreateDto();
  final _form = GlobalKey<FormState>();
  late final TabController _tabs;

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

  bool get _isExpense => _seciliGirisCikis == 2 && _seciliIslemTipi == 7;
  Widget _expenseField() => ErpRecordFields(
      controller: _expense, lookup: financeFieldChoices, prefix: 'movement');
  bool _loading = true;
  bool _saving = false;

  // Listeler
  List<KasaDto> _kasalar = [];
  List<DovizDto> _dovizler = [];
  List<ProjeDto> _projeler = [];
  List<PlasiyerDto> _plasiyerler = [];
  List<BelgeSeriDto> _seriListesi = [];
  List<CariDtoLite> _cariler = [];
  List<BankahesapDto> _bankaHesaplar = [];

  // Seçili değerler
  KasaDto? _seciliKasa;
  KasaDto? _seciliIslemKasa;
  CariDtoLite? _seciliIslemCari;
  BankahesapDto? _seciliIslemBanka;
  int _seciliGirisCikis = 1; // 1=Tahsil(Giriş) 2=Tediye(Çıkış)
  int _seciliIslemTipi = 1; // default Cari
  int _seciliYil = DateTime.now().year;
  String? _seciliSeri;

  bool _plasiyerKilitli =
      false; // Plasiyer kullanıcısı: kendi plasiyeri, değiştirilemez
  String _ilkImza = ''; // çıkışta "kaydedilmemiş değişiklik" kontrolü için

  late List<int> _yilListesi;

  // Controller'lar
  late final TextEditingController _tarihCtrl;
  late final TextEditingController _evrakTarihCtrl;
  late final TextEditingController _belgeNoCtrl;
  late final TextEditingController _kurCtrl;
  late final TextEditingController _dovizTarihCtrl;
  late final TextEditingController _tutarCtrl;
  late final TextEditingController _dovizTutarCtrl;
  late final TextEditingController _evrakNoCtrl;
  late final TextEditingController _aciklamaCtrl;

  final _fmt = DateFormat('dd.MM.yyyy');

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });

    final now = DateTime.now();
    _yilListesi = List.generate(7, (i) => now.year - i);

    _dto.belgeturu = BelgeTuruCouples.kasaHareket;
    _dto.islemtipi = _seciliIslemTipi;
    _dto.giriscikis = _seciliGirisCikis;
    _dto.tarih = now;
    _dto.evraktarih = now;
    _dto.belgeyil = now.year;

    _tarihCtrl = TextEditingController(text: _fmt.format(now));
    _evrakTarihCtrl = TextEditingController(text: _fmt.format(now));
    _belgeNoCtrl = TextEditingController();
    _kurCtrl = TextEditingController();
    _dovizTarihCtrl = TextEditingController(text: _fmt.format(now));
    _tutarCtrl = TextEditingController();
    _dovizTutarCtrl = TextEditingController();
    _evrakNoCtrl = TextEditingController();
    _aciklamaCtrl = TextEditingController();

    _tutarCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    // Çıkış uyarısı (PopScope) metin değişikliklerini de görsün diye
    for (final c in [_evrakNoCtrl, _aciklamaCtrl, _dovizTutarCtrl, _kurCtrl]) {
      c.addListener(() {
        if (mounted) setState(() {});
      });
    }

    _loadLookups();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _expense.dispose();
    _tarihCtrl.dispose();
    _evrakTarihCtrl.dispose();
    _belgeNoCtrl.dispose();
    _kurCtrl.dispose();
    _dovizTarihCtrl.dispose();
    _tutarCtrl.dispose();
    _dovizTutarCtrl.dispose();
    _evrakNoCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  static bool _birimTL(String? birim) {
    final b = (birim ?? '').trim().toUpperCase();
    return b == 'TL' || b == 'TRY' || b == '₺';
  }

  int? get _tlId {
    final tl = _dovizler.where((d) => _birimTL(d.Birim)).firstOrNull;
    return tl?.Id ?? (_dovizler.isNotEmpty ? _dovizler.first.Id : 1);
  }

  bool get _isDoviz {
    if (_dto.dovizid == null) return false;
    final d = _dovizler.where((x) => x.Id == _dto.dovizid).firstOrNull;
    if (d == null) return _dto.dovizid != _tlId;
    return !_birimTL(d.Birim);
  }

  // Web tarafındaki tutarHesapla mantığı: Tutar = Doviztutar * Kur (dövizliyse)
  void _recalcTutar() {
    if (!_isDoviz) return;
    final dovizTutar = NumberFormatHelper.parse(_dovizTutarCtrl.text);
    final kur = _dto.kur ?? 0;
    final tutar = dovizTutar * kur;
    _dto.doviztutar = dovizTutar;
    _dto.tutar = tutar;
    _tutarCtrl.text = NumberFormatHelper.format(tutar);
  }

  // ── Veri Yükleme ─────────────────────────────────────────────────────────────
  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";

      final results = await Future.wait([
        _svc.getKasalar(token),
        DovizService().getDovizler(token),
        ProjeService().getProjeList(token),
        PlasiyerService().getPlasiyerler(token),
        BelgeSeriService().getAll(token, BelgeTuruCouples.kasaHareket),
        CariService().getCariler(token),
        _svc.getBankaHesaplar(token),
      ]);

      _kasalar = results[0] as List<KasaDto>;
      _dovizler = results[1] as List<DovizDto>;
      _projeler = (results[2] as List<ProjeDto>)
          .where((p) => p.tur == 3)
          .toList()
        ..sort((a, b) => (a.kod ?? '').compareTo(b.kod ?? ''));
      _plasiyerler = results[3] as List<PlasiyerDto>;
      _seriListesi = results[4] as List<BelgeSeriDto>;
      _cariler = results[5] as List<CariDtoLite>;
      _bankaHesaplar = results[6] as List<BankahesapDto>;

      // Defaults
      if (_isEdit) {
        _fillEdit();
      } else {
        if (_kasalar.isNotEmpty) {
          _seciliKasa = _kasalar.first;
          _dto.kasaid = _seciliKasa!.Id;
        }
        if (_dovizler.isNotEmpty) _dto.dovizid = _tlId;
        if (_projeler.isNotEmpty) _dto.projeid = _projeler.first.id;
        if (_plasiyerler.isNotEmpty) _dto.plasiyerid = _plasiyerler.first.Id;
        if (_seriListesi.isNotEmpty) {
          _seciliSeri = _seriListesi.first.seri;
          _dto.belgeseri = _seciliSeri;
          await _fetchBelgeNo(token);
        }
      }

      // Plasiyer kullanıcısı ise plasiyer kendisi olarak gelir ve değiştirilemez.
      final kp = await KullaniciPlasiyerHelper.getir();
      if (kp.kilitli) {
        _plasiyerKilitli = true;
        if (!_isEdit) _dto.plasiyerid = kp.plasiyerid;
      }

      _ilkImza = _imza();
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        UiFeedback.showError(context, "Veriler yüklenemedi: $e");
      }
    }
  }

  void _fillEdit() {
    final h = widget.editHareket!;

    _seciliGirisCikis = h.Giriscikis ?? 1;
    _seciliIslemTipi = h.Islemtipi ?? 3;
    _seciliYil = h.Belgeyil ?? DateTime.now().year;
    _seciliSeri = h.Belgeseri;

    _seciliKasa = _kasalar.where((k) => k.Id == h.Kasaid).firstOrNull;
    _seciliIslemKasa = h.Islemtipi == 3
        ? _kasalar.where((k) => k.Id == h.Islemkasaid).firstOrNull
        : null;
    _seciliIslemCari = h.Islemtipi == 1
        ? _cariler.where((c) => c.Id == h.Islemcariid).firstOrNull
        : null;
    _seciliIslemBanka = h.Islemtipi == 2
        ? _bankaHesaplar.where((b) => b.Id == h.Islembankahesapid).firstOrNull
        : null;

    _dto
      ..islemmasrafid = h.Islemmasrafid
      ..masraf = h.Masraf
      ..kasaid = h.Kasaid
      ..islemkasaid = h.Islemkasaid
      ..islemcariid = h.Islemcariid
      ..islembankahesapid = h.Islembankahesapid
      ..dovizid = h.Dovizid
      ..projeid = h.Projeid
      ..plasiyerid = h.Plasiyerid
      ..belgeseri = h.Belgeseri
      ..belgeyil = h.Belgeyil
      ..belgeno = h.Belgeno
      ..belgeserino = h.Belgeserino
      ..belgeturu = h.Belgeturu
      ..giriscikis = h.Giriscikis
      ..islemtipi = h.Islemtipi
      ..kur = h.Kur
      ..doviztarih = h.Doviztarih
      ..doviztutar = h.Doviztutar
      ..tutar = h.Tutar
      ..aciklama = h.Aciklama
      ..tarih = h.Tarih
      ..evraktarih = h.Evraktarih
      ..evrakno = h.Evrakno;

    if (h.Tarih != null) _tarihCtrl.text = _fmt.format(h.Tarih!);
    if (h.Evraktarih != null) _evrakTarihCtrl.text = _fmt.format(h.Evraktarih!);
    if (h.Doviztarih != null) _dovizTarihCtrl.text = _fmt.format(h.Doviztarih!);
    _belgeNoCtrl.text = h.Belgeno ?? '';
    _kurCtrl.text = h.Kur != null ? h.Kur!.toStringAsFixed(4) : '';
    _tutarCtrl.text =
        h.Tutar != null ? NumberFormatHelper.format(h.Tutar!) : '';
    _dovizTutarCtrl.text =
        h.Doviztutar != null ? NumberFormatHelper.format(h.Doviztutar!) : '';
    _evrakNoCtrl.text = h.Evrakno ?? '';
    _aciklamaCtrl.text = h.Aciklama ?? '';
  }

  Future<void> _fetchBelgeNo([String? tokenOverride]) async {
    if (_seciliSeri == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = tokenOverride ?? prefs.getString("token_final") ?? "";
      final no = await _svc.getNewBelgeNo(token, _seciliSeri!, _seciliYil);
      if (mounted) {
        setState(() {
          _dto.belgeno = no;
          _belgeNoCtrl.text = no;
        });
      }
    } catch (e) {
      debugPrint("BelgeNo alınamadı: $e");
    }
  }

  Future<void> _fetchKur(int dovizId) async {
    if (!_isDoviz) {
      setState(() {
        _dto.kur = null;
        _kurCtrl.text = '';
        _dto.doviztarih = null;
        _dto.doviztutar = null;
        _dovizTutarCtrl.clear();
      });
      return;
    }
    final tarih = _dto.doviztarih ?? _dto.tarih ?? DateTime.now();
    setState(() {
      _dto.doviztarih = tarih;
      _dovizTarihCtrl.text = _fmt.format(tarih);
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final kur = await KurService().getByDovizIdAndDate(token, dovizId, tarih);
      final yeniKur = kur?.Dovizsatis ??
          kur?.Dovizalis ??
          kur?.Dovizefektifsatis ??
          kur?.Dovizefektifalis;
      if (yeniKur != null && yeniKur > 0 && mounted) {
        setState(() {
          _dto.kur = yeniKur;
          _kurCtrl.text = yeniKur.toStringAsFixed(4);
          _recalcTutar();
        });
      }
    } catch (e) {
      debugPrint("Kur alınamadı: $e");
    }
  }

  Future<void> _save() async {
    // Not: Form alanları sekmelere dağıldığı için Form.validate() görünmeyen
    // sekmedeki hatayı sessizce yutar. Bu yüzden zorunlu alanlar burada elle,
    // kullanıcıya görünür bir uyarıyla kontrol ediliyor.
    if (_dto.kasaid == null) {
      UiFeedback.showError(context, "Lütfen bir kasa seçin.");
      return;
    }
    if (_seciliIslemTipi == 1 && _seciliIslemCari == null) {
      UiFeedback.showError(context, "Lütfen işlem cari seçin.");
      return;
    }
    if (_seciliIslemTipi == 2 && _seciliIslemBanka == null) {
      UiFeedback.showError(context, "Lütfen işlem banka hesabı seçin.");
      return;
    }
    if (_seciliIslemTipi == 3 && _seciliIslemKasa == null) {
      UiFeedback.showError(context, "Lütfen işlem kasa seçin.");
      return;
    }
    if (_tutarCtrl.text.trim().isEmpty) {
      UiFeedback.showError(context, "Lütfen tutar giriniz.");
      return;
    }
    if (_isDoviz && _dovizTutarCtrl.text.trim().isEmpty) {
      UiFeedback.showError(context, "Lütfen döviz tutar giriniz.");
      return;
    }

    if (_isExpense && _expense.values['Islemmasrafid'] == null) {
      UiFeedback.showError(context, 'Masraf seçiniz.');
      return;
    }
    _dto.islemmasrafid = _isExpense ? _expense.values['Islemmasrafid'] : null;
    _form.currentState?.save();

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";

      if (_isEdit) {
        final update = KasahareketUpdateDto()
          ..id = widget.editHareket!.Id
          ..islemmasrafid = _isExpense ? _expense.values['Islemmasrafid'] : null
          ..masraf = _dto.masraf
          ..kasaid = _dto.kasaid
          ..dovizid = _dto.dovizid
          ..islemcariid = _dto.islemcariid
          ..islemkasaid = _dto.islemkasaid
          ..islembankahesapid = _dto.islembankahesapid
          ..projeid = _dto.projeid
          ..plasiyerid = _dto.plasiyerid
          ..kur = _dto.kur
          ..doviztarih = _dto.doviztarih
          ..doviztutar = _dto.doviztutar
          ..tutar = _dto.tutar
          ..aciklama = _dto.aciklama
          ..tarih = _dto.tarih
          ..evraktarih = _dto.evraktarih
          ..evrakno = _dto.evrakno;

        // ── Offline mod kontrolü ─────────────────────────────────────────
        final manuelOfflineUpd = await OfflineService.instance.getOfflineMode();
        final internetYokUpd = !OfflineService.instance.isOnline.value;
        if (manuelOfflineUpd || internetYokUpd) {
          await OfflineService.instance.enqueue('single_full', {
            'endpoint': '/Kasahareket',
            'method': 'PUT',
            'body': update.toJson(),
          });
          if (!mounted) return;
          UiFeedback.showSuccess(
            context,
            internetYokUpd
                ? "İnternet yok — kayıt kuyruğa alındı, bağlantı gelince gönderilecek"
                : "Kayıt kuyruğa eklendi — online olunca gönderilecek",
          );
          Navigator.pop(context, true);
          return;
        }

        await _svc.updateKasahareket(token, update);
        if (!mounted) return;
        UiFeedback.showSuccess(context, "Kasa hareketi güncellendi.");
      } else {
        _dto.belgeno = _belgeNoCtrl.text.trim();
        _dto.belgeserino =
            '${_dto.belgeseri ?? ''}${_dto.belgeyil ?? ''}${_dto.belgeno ?? ''}';

        // ── Offline mod kontrolü ─────────────────────────────────────────
        final manuelOffline = await OfflineService.instance.getOfflineMode();
        final internetYok = !OfflineService.instance.isOnline.value;
        if (manuelOffline || internetYok) {
          await OfflineService.instance.enqueue('single_full', {
            'endpoint': '/Kasahareket',
            'method': 'POST',
            'body': _dto.toJson(),
          });
          if (!mounted) return;
          UiFeedback.showSuccess(
            context,
            internetYok
                ? "İnternet yok — kayıt kuyruğa alındı, bağlantı gelince gönderilecek"
                : "Kayıt kuyruğa eklendi — online olunca gönderilecek",
          );
          Navigator.pop(context, true);
          return;
        }

        await _svc.saveKasahareket(token, _dto);
        if (!mounted) return;
        UiFeedback.showSuccess(context, "Kasa hareketi kaydedildi.");
      }

      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      UiFeedback.showError(context, "Kayıt hatası: $e");
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Tarih Seçici ──────────────────────────────────────────────────────────────
  Future<DateTime?> _pickDate(DateTime? initial) async {
    return showDatePicker(
      context: context,
      initialDate: initial ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
  }

  // ── Sekme geçişi: alanlar doldurulmadan ilerlenemez ─────────────────────────────
  /// [i]. sekmedeki eksik zorunlu alanın mesajı; eksik yoksa null.
  String? _sekmeHatasi(int i) {
    switch (i) {
      case 0:
        if (_dto.kasaid == null) return 'Lütfen bir kasa seçin.';
        if (_tarihCtrl.text.trim().isEmpty) return 'Lütfen tarih seçin.';
        if (_seriListesi.isNotEmpty && _seciliSeri == null)
          return 'Lütfen belge serisi seçin.';
        return null;
      case 1:
        if (_seciliIslemTipi == 1 && _seciliIslemCari == null)
          return 'Lütfen işlem cari seçin.';
        if (_seciliIslemTipi == 2 && _seciliIslemBanka == null)
          return 'Lütfen işlem banka hesabı seçin.';
        if (_seciliIslemTipi == 3 && _seciliIslemKasa == null)
          return 'Lütfen işlem kasa seçin.';
        if (_dto.dovizid == null) return 'Lütfen döviz seçin.';
        if (_isDoviz && (_dto.kur ?? 0) <= 0)
          return 'Döviz TL olmadığından kur giriniz.';
        if (_isDoviz && NumberFormatHelper.parse(_dovizTutarCtrl.text) <= 0)
          return 'Lütfen döviz tutar giriniz.';
        if (NumberFormatHelper.parse(_tutarCtrl.text) <= 0)
          return 'Lütfen tutar giriniz.';
        return null;
    }
    return null;
  }

  /// [hedef] sekmeye geçmeden önce tamamlanması gereken ilk eksik sekme: (sekme, mesaj).
  (int, String)? _ilerlemeEngeli(int hedef) {
    for (var i = 0; i < hedef; i++) {
      final h = _sekmeHatasi(i);
      if (h != null) return (i, h);
    }
    return null;
  }

  /// Sekme başlığına dokunarak ileri atlamayı da engeller; eksik sekmeye döndürür.
  void _sekmeTikla(int hedef) {
    if (hedef <= _tabs.previousIndex) return;
    final e = _ilerlemeEngeli(hedef);
    if (e != null) {
      UiFeedback.showError(context, e.$2);
      _tabs.animateTo(e.$1);
    }
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

  // ── Kaydedilmemiş değişiklik kontrolü ────────────────────────────────────────
  /// Kullanıcının girdiği/seçtiği alanların özeti; yükleme bitince alınan özetle
  /// karşılaştırılır. Farklıysa sayfadan çıkarken uyarı verilir.
  String _imza() => [
        _dto.kasaid,
        _seciliGirisCikis,
        _seciliIslemTipi,
        _tarihCtrl.text,
        _evrakTarihCtrl.text,
        _evrakNoCtrl.text,
        _dto.islemcariid,
        _dto.islembankahesapid,
        _dto.islemkasaid,
        _expense.values['Islemmasrafid'],
        _dto.plasiyerid,
        _dto.projeid,
        _dto.dovizid,
        _kurCtrl.text,
        _tutarCtrl.text,
        _dovizTutarCtrl.text,
        _aciklamaCtrl.text,
        _seciliSeri,
        _seciliYil,
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

  /// İşlem tipi Cari ise bu işlemin carinin bakiyesine etkisi (borç +, alacak −).
  /// Tahsil (giriş): cari borcu azalır → −tutar. Tediye (çıkış): cari borçlanır → +tutar.
  /// Düzenlemede, kaydın eski etkisi çıkarılır (bakiye zaten onu içeriyor).
  double? get _bakiyeDegisim {
    if (_seciliIslemTipi != 1 || _seciliIslemCari == null) return null;
    double isaret(int gc) => gc == 1 ? -1 : 1;
    var d =
        isaret(_seciliGirisCikis) * NumberFormatHelper.parse(_tutarCtrl.text);
    if (_isEdit) {
      final h = widget.editHareket!;
      if (h.Islemtipi == 1 && h.Islemcariid == _seciliIslemCari!.Id) {
        d -= isaret(h.Giriscikis ?? 1) * (h.Tutar ?? 0);
      }
    }
    return d;
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_degisti,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _cikisSor();
      },
      child: Scaffold(
        backgroundColor: _background,
        appBar: _buildAppBar(),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _form,
                child: Column(children: [
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabs,
                      // Kaydırarak sekme atlamayı kapat: ilerleme yalnızca Sonraki / sekme başlığı ile ve kontrollü.
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _tabPadding(_tabBelge()),
                        _tabPadding(_tabIslem()),
                        _tabPadding(_tabDetay()),
                      ],
                    ),
                  ),
                  _buildBottomBar(),
                ]),
              ),
      ),
    );
  }

  Widget _tabPadding(Widget child) => SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: child,
      );

  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: _scheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(
                _isEdit
                    ? Icons.edit_note_rounded
                    : Icons.account_balance_wallet_rounded,
                size: 17,
                color: _scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_isEdit ? 'Kasa Hareketi Düzenle' : 'Yeni Kasa Hareketi',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w700,
                          fontSize: 15.5,
                          color: _scheme.onSurface)),
                  Text(
                    _isEdit
                        ? 'FİNANS • ${widget.editHareket!.Belgeserino ?? ''}'
                        : 'FİNANS',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        color: _scheme.onSurfaceVariant,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w600),
                  ),
                ]),
          ),
        ]),
      );

  Widget _buildTabBar() => Container(
        color: _scheme.surface,
        child: ErpAdaptiveTabs(
            context: context,
            tabBar: TabBar(
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              indicator: BoxDecoration(
                  color: _scheme.primary.withValues(alpha: .08),
                  borderRadius: BorderRadius.circular(12)),
              controller: _tabs,
              onTap: _sekmeTikla,
              isScrollable: false,
              labelColor: _scheme.primary,
              unselectedLabelColor: _scheme.onSurfaceVariant,
              indicatorColor: _scheme.primary,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w700),
              unselectedLabelStyle: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w600),
              labelPadding: const EdgeInsets.symmetric(horizontal: 2),
              tabs: [
                Tab(
                    height: 48,
                    icon: Icon(Icons.description_rounded, size: 17),
                    text: 'Belge'),
                Tab(
                    height: 48,
                    icon: Icon(Icons.swap_horiz_rounded, size: 17),
                    text: 'İşlem'),
                Tab(
                    height: 48,
                    icon: Icon(Icons.notes_rounded, size: 17),
                    text: 'Detay'),
              ],
            )),
      );

  Widget _buildBottomBar() => Container(
        decoration: BoxDecoration(
            color: _scheme.surface,
            border: Border(top: BorderSide(color: _scheme.outlineVariant))),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: SafeArea(
          top: false,
          child: Row(children: [
            if (_tabs.index > 0) ...[
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _saving ? null : _geri,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _kRed,
                      side: const BorderSide(color: _kRed),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(11)),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text('Önceki',
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 44,
                child: PermissionAction(
                    modules: [1003],
                    access: Access.write,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _scheme.primary,
                        foregroundColor: _scheme.onPrimary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(11)),
                        elevation: 0,
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : Icon(
                              _tabs.index == _tabs.length - 1
                                  ? (_isEdit
                                      ? Icons.save_rounded
                                      : Icons.check_rounded)
                                  : Icons.arrow_forward_rounded,
                              size: 18),
                      label: Text(
                        _saving
                            ? 'Kaydediliyor...'
                            : (_tabs.index == _tabs.length - 1
                                ? (_isEdit ? 'Güncelle' : 'Kaydet')
                                : 'Sonraki'),
                        style: const TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                      ),
                      onPressed: _saving ? null : _ileri,
                    )),
              ),
            ),
          ]),
        ),
      );

  // ── Tab 1: Belge ────────────────────────────────────────────────────────────────
  // Kasa • İşlem Yönü • (Tarih | İşlem Tipi) • (Seri | Yıl | No)
  Widget _tabBelge() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildKasaField(),
        const SizedBox(height: 12),
        _buildGirisCikisDropdown(),
        const SizedBox(height: 12),
        _pairRow(
          _buildDateField("Tarih", _tarihCtrl, (d) {
            _dto.tarih = d;
          }),
          _buildIslemTipiDropdown(),
        ),
        const SizedBox(height: 12),
        _buildSeriYilNoTable(),
      ]);

  // ── Tab 2: İşlem ────────────────────────────────────────────────────────────────
  // Cari/Banka/Kasa • Plasiyer • (Döviz | Kur) • Tutar • Bakiye
  Widget _tabIslem() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_isExpense) _expenseField(),
        if (_seciliIslemTipi == 3) _buildIslemKasaField(),
        if (_seciliIslemTipi == 2) _buildIslemBankaField(),
        if (_seciliIslemTipi == 1) _buildIslemCariField(),
        const SizedBox(height: 12),
        _buildPlasiyerDropdown(),
        const SizedBox(height: 12),
        if (_isDoviz)
          _pairRow(_buildDovizDropdown(kisa: true), _buildKurField())
        else
          _buildDovizDropdown(),
        if (_isDoviz) ...[
          const SizedBox(height: 12),
          _pairRow(_buildKurTarihField(), _buildDovizTutarField()),
        ],
        const SizedBox(height: 12),
        _buildTutarField(),
        if (_seciliIslemTipi == 1 && _seciliIslemCari != null) ...[
          const SizedBox(height: 10),
          _buildBakiyeKutusu(),
        ],
      ]);

  // ── Tab 3: Detay ────────────────────────────────────────────────────────────────
  // (Evrak Tarihi | Evrak No) • Proje • Açıklama
  Widget _tabDetay() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pairRow(
          _buildDateField("Evrak Tarihi", _evrakTarihCtrl, (d) {
            _dto.evraktarih = d;
          }),
          _buildTextField("Evrak No", _evrakNoCtrl, (v) => _dto.evrakno = v,
              required: false),
        ),
        const SizedBox(height: 12),
        _buildProjeDropdown(),
        const SizedBox(height: 12),
        _buildTextField("Açıklama", _aciklamaCtrl, (v) => _dto.aciklama = v,
            required: false, maxLines: 4),
      ]);

  /// Cari bakiyesi + bu işlemle oluşacak bakiye (tutar girildikçe güncellenir).
  Widget _buildBakiyeKutusu() => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _scheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _scheme.outlineVariant),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Bakiye',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11.5,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          CariBakiyeSatiri(
              cariId: _seciliIslemCari!.Id, degisim: _bakiyeDegisim),
        ]),
      );

  // ── Alan Bileşenleri ──────────────────────────────────────────────────────────

  Widget _buildKasaField() => _fieldRow(
      "Kasa *",
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final secilen = await Navigator.push<KasaDto>(
            context,
            PermissionMaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => _AramaSayfasi<KasaDto>(
                      baslik: 'Kasa Seç',
                      items: _kasalar,
                      secili: _seciliKasa,
                      itemLabel: (k) => '${k.Kod ?? ''} - ${k.Ad ?? ''}',
                      filtre: (k, q) =>
                          (k.Ad ?? '').toLowerCase().contains(q) ||
                          (k.Kod ?? '').toLowerCase().contains(q),
                    )),
          );
          if (secilen != null)
            setState(() {
              _seciliKasa = secilen;
              _dto.kasaid = secilen.Id;
            });
        },
        child: _seciliAlanKutusu(
            _seciliKasa != null
                ? '${_seciliKasa!.Kod ?? ''} - ${_seciliKasa!.Ad ?? ''}'
                : null,
            'Kasa seçiniz'),
      ));

  Widget _buildIslemKasaField() => _fieldRow(
      "İşlem Kasa *",
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final secilen = await Navigator.push<KasaDto>(
            context,
            PermissionMaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => _AramaSayfasi<KasaDto>(
                      baslik: 'İşlem Kasa Seç',
                      items: _kasalar,
                      secili: _seciliIslemKasa,
                      itemLabel: (k) => '${k.Kod ?? ''} - ${k.Ad ?? ''}',
                      filtre: (k, q) =>
                          (k.Ad ?? '').toLowerCase().contains(q) ||
                          (k.Kod ?? '').toLowerCase().contains(q),
                    )),
          );
          if (secilen != null)
            setState(() {
              _seciliIslemKasa = secilen;
              _dto.islemkasaid = secilen.Id;
            });
        },
        child: _seciliAlanKutusu(
            _seciliIslemKasa != null
                ? '${_seciliIslemKasa!.Kod ?? ''} - ${_seciliIslemKasa!.Ad ?? ''}'
                : null,
            'İşlem kasa seçiniz'),
      ));

  Widget _buildGirisCikisDropdown() => _fieldRow(
      "İşlem Yönü",
      DropdownButtonFormField<int>(
        isExpanded: true,
        initialValue: _seciliGirisCikis,
        decoration: _dec(readOnly: _isEdit),
        style: _style,
        items: _GirisCikisCouples.list
            .map((e) => DropdownMenuItem(
                value: e.value,
                child: Text(e.text,
                    style:
                        const TextStyle(fontFamily: 'Roboto', fontSize: 13))))
            .toList(),
        // edit modunda değiştirilemez
        onChanged: _isEdit
            ? null
            : (v) => setState(() {
                  _seciliGirisCikis = v!;
                  _dto.giriscikis = v;
                  if (v != 2 && _seciliIslemTipi == 7) {
                    _seciliIslemTipi = 4;
                    _dto.islemtipi = 4;
                  }
                  if (!_isExpense) _expense.choose('Islemmasrafid', null, null);
                }),
      ));

  Widget _buildIslemTipiDropdown() => _fieldRow(
      "İşlem Tipi",
      DropdownButtonFormField<int>(
        initialValue: _seciliIslemTipi,
        decoration: _dec(readOnly: _isEdit),
        style: _style,
        isExpanded: true,
        key: ValueKey('cash-operation-$_seciliGirisCikis-$_seciliIslemTipi'),
        items: _islemTipleri
            .where((t) =>
                (_isEdit || ![5, 6].contains(t.value)) &&
                (_seciliGirisCikis == 2 || t.value != 7))
            .map((t) => DropdownMenuItem(
                value: t.value,
                child: Text(t.label,
                    style:
                        const TextStyle(fontFamily: 'Roboto', fontSize: 13))))
            .toList(),
        // edit modunda değiştirilemez
        onChanged: _isEdit
            ? null
            : (v) => setState(() {
                  _seciliIslemTipi = v!;
                  _dto.islemtipi = v;
                  if (!_isExpense) _expense.choose('Islemmasrafid', null, null);
                  if (v != 3) {
                    _seciliIslemKasa = null;
                    _dto.islemkasaid = null;
                  }
                  if (v != 1) {
                    _seciliIslemCari = null;
                    _dto.islemcariid = null;
                  }
                  if (v != 2) {
                    _seciliIslemBanka = null;
                    _dto.islembankahesapid = null;
                  }
                }),
      ));

  Widget _buildIslemCariField() => _fieldRow(
      "İşlem Cari *",
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final secilen = await Navigator.push<CariDtoLite>(
              context,
              PermissionMaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => _AramaSayfasi<CariDtoLite>(
                        baslik: 'Cari Seç',
                        items: _cariler,
                        secili: _seciliIslemCari,
                        itemLabel: (c) => '${c.Kod ?? ''} - ${c.Ad ?? ''}',
                        filtre: (c, q) =>
                            (c.Ad ?? '').toLowerCase().contains(q) ||
                            (c.Kod ?? '').toLowerCase().contains(q),
                      )),
            );
            if (secilen != null) {
              setState(() {
                _seciliIslemCari = secilen;
                _dto.islemcariid = secilen.Id;
              });
              final pid = await CariPlasiyerHelper.getPlasiyerIdOrFirst(
                  secilen.Id, _plasiyerler);
              final prid = await VarsayilanProjeHelper.pickFrom(_projeler);
              if (!mounted) return;
              setState(() {
                if (pid != null && !_plasiyerKilitli) _dto.plasiyerid = pid;
                if (prid != null) _dto.projeid = prid;
              });
            }
          },
          child: _seciliAlanKutusu(
              _seciliIslemCari != null
                  ? '${_seciliIslemCari!.Kod ?? ''} - ${_seciliIslemCari!.Ad ?? ''}'
                  : null,
              'Cari seçiniz'),
        ),
      ]));

  Widget _buildIslemBankaField() => _fieldRow(
      "İşlem Banka *",
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final secilen = await Navigator.push<BankahesapDto>(
            context,
            PermissionMaterialPageRoute(
                fullscreenDialog: true,
                builder: (_) => _AramaSayfasi<BankahesapDto>(
                      baslik: 'Banka Hesabı Seç',
                      items: _bankaHesaplar,
                      secili: _seciliIslemBanka,
                      itemLabel: (b) => '${b.Kod ?? ''} - ${b.Ad ?? ''}',
                      filtre: (b, q) =>
                          (b.Ad ?? '').toLowerCase().contains(q) ||
                          (b.Kod ?? '').toLowerCase().contains(q),
                    )),
          );
          if (secilen != null)
            setState(() {
              _seciliIslemBanka = secilen;
              _dto.islembankahesapid = secilen.Id;
            });
        },
        child: _seciliAlanKutusu(
            _seciliIslemBanka != null
                ? '${_seciliIslemBanka!.Kod ?? ''} - ${_seciliIslemBanka!.Ad ?? ''}'
                : null,
            'Banka hesabı seçiniz'),
      ));

  Widget _buildSeriYilNoTable() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Belge Seri / Yıl / No',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11.5,
                color: _scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            flex: 3,
            child: _pickerField<String>(
              value: _seciliSeri,
              items: _seriListesi.map((s) => s.seri ?? '-').toList(),
              itemLabel: (v) => v,
              enabled: !_isEdit,
              onSelected: (v) {
                setState(() {
                  _seciliSeri = v;
                  _dto.belgeseri = v;
                });
                _fetchBelgeNo();
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
                setState(() {
                  _seciliYil = v;
                  _dto.belgeyil = v;
                });
                _fetchBelgeNo();
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 5,
            child: TextFormField(
              controller: _belgeNoCtrl,
              readOnly: true,
              style: _style.copyWith(color: _scheme.onSurfaceVariant),
              decoration: _dec(readOnly: true, hint: 'Belge No'),
            ),
          ),
        ]),
      ]);

  Widget _buildDovizDropdown({bool kisa = false}) => _fieldRow(
      "Döviz",
      DropdownButtonFormField<int>(
        initialValue: _dto.dovizid,
        decoration: _dec(),
        style: _style,
        isExpanded: true,
        items: _dovizler
            .map((d) => DropdownMenuItem(
                value: d.Id,
                child: Text(
                    kisa
                        ? (d.Birim ?? d.Ad ?? '')
                        : '${d.Ad ?? ''} (${d.Birim ?? ''})',
                    style:
                        const TextStyle(fontFamily: 'Roboto', fontSize: 13))))
            .toList(),
        onChanged: (v) {
          setState(() => _dto.dovizid = v);
          if (v != null) _fetchKur(v);
        },
      ));

  Widget _buildKurTarihField() => _fieldRow(
      "Kur Tarihi",
      TextFormField(
        controller: _dovizTarihCtrl,
        readOnly: true,
        style: _style,
        decoration: _dec().copyWith(
            suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18)),
        onTap: () async {
          final d = await _pickDate(_dto.doviztarih);
          if (d != null) {
            setState(() {
              _dto.doviztarih = d;
              _dovizTarihCtrl.text = _fmt.format(d);
            });
            if (_dto.dovizid != null) _fetchKur(_dto.dovizid!);
          }
        },
      ));

  Widget _buildKurField() => _fieldRow(
      "Kur",
      TextFormField(
        controller: _kurCtrl,
        style: _style,
        textAlign: TextAlign.right,
        decoration: _dec(hint: 'Kur'),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        onChanged: (v) => setState(() {
          _dto.kur = double.tryParse(v.replaceAll(',', '.'));
          _recalcTutar();
        }),
      ));

  Widget _buildProjeDropdown() => _fieldRow(
      "Proje",
      DropdownButtonFormField<int>(
        key: ValueKey('proje-${_dto.projeid}'),
        initialValue: _dto.projeid,
        isExpanded: true,
        decoration: _dec(),
        style: _style,
        items: [
          const DropdownMenuItem<int>(
              value: null,
              child: Text("— Seçiniz —",
                  style: TextStyle(fontFamily: 'Roboto', fontSize: 13))),
          ..._projeler.map((p) => DropdownMenuItem(
              value: p.id,
              child: Text("${p.kod ?? ''} - ${p.ad ?? ''}",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 13)))),
        ],
        onChanged: (v) => setState(() => _dto.projeid = v),
      ));

  Widget _buildPlasiyerDropdown() => _fieldRow(
      "Plasiyer",
      DropdownButtonFormField<int>(
        key: ValueKey('plasiyer-${_dto.plasiyerid}'),
        initialValue: _dto.plasiyerid,
        isExpanded: true,
        decoration: _dec(readOnly: _plasiyerKilitli),
        style: _style,
        items: [
          const DropdownMenuItem<int>(
              value: null,
              child: Text("— Seçiniz —",
                  style: TextStyle(fontFamily: 'Roboto', fontSize: 13))),
          ..._plasiyerler.map((p) => DropdownMenuItem(
              value: p.Id,
              child: Text("${p.Kod ?? ''} - ${p.Adsoyad ?? ''}",
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontFamily: 'Roboto', fontSize: 13)))),
        ],
        // Plasiyer kullanıcısı: kendi plasiyeri sabit, değiştirilemez
        onChanged: _plasiyerKilitli
            ? null
            : (v) => setState(() => _dto.plasiyerid = v),
      ));

  Widget _buildDovizTutarField() => _fieldRow(
      "Döviz Tutar",
      TextFormField(
        controller: _dovizTutarCtrl,
        style: _style,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [_TutarFormatter()],
        textAlign: TextAlign.right,
        decoration: _dec(hint: '0,00'),
        validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu alan' : null,
        onChanged: (v) => setState(_recalcTutar),
      ));

  Widget _buildTutarField() {
    final readOnly = _isDoviz;
    return _fieldRow(
        "Tutar",
        TextFormField(
          controller: _tutarCtrl,
          readOnly: readOnly,
          style: _style,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: readOnly ? null : [_TutarFormatter()],
          textAlign: TextAlign.right,
          decoration: _dec(readOnly: readOnly, hint: '0,00'),
          validator: (v) => (v == null || v.isEmpty) ? 'Zorunlu alan' : null,
          onSaved: (v) {
            if (!readOnly) _dto.tutar = NumberFormatHelper.parse(v ?? '');
          },
        ));
  }

  Widget _buildDateField(String label, TextEditingController ctrl,
          void Function(DateTime) onPick) =>
      _fieldRow(
          label,
          TextFormField(
            controller: ctrl,
            readOnly: true,
            style: _style,
            decoration: _dec().copyWith(
                suffixIcon: const Icon(Icons.calendar_today_rounded, size: 18)),
            onTap: () async {
              final d = await _pickDate(null);
              if (d != null) {
                setState(() => ctrl.text = _fmt.format(d));
                onPick(d);
              }
            },
          ));

  Widget _buildTextField(
    String label,
    TextEditingController ctrl,
    void Function(String?) onSave, {
    bool required = true,
    int maxLines = 1,
  }) =>
      _fieldRow(
          label,
          TextFormField(
            controller: ctrl,
            maxLines: maxLines,
            style: _style,
            decoration: _dec(),
            validator: required
                ? (v) => (v == null || v.isEmpty) ? 'Zorunlu alan' : null
                : null,
            onSaved: onSave,
          ));

  Widget _seciliAlanKutusu(String? deger, String bosMetin) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _scheme.outlineVariant)),
        child: Row(children: [
          Expanded(
            child: Text(
              deger?.isNotEmpty == true ? deger! : bosMetin,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13.5,
                  color: deger?.isNotEmpty == true
                      ? _scheme.onSurface
                      : _scheme.onSurfaceVariant),
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              size: 18, color: _scheme.onSurfaceVariant),
        ]),
      );

  Widget _pickerField<T>({
    required T? value,
    required List<T> items,
    required String Function(T) itemLabel,
    required ValueChanged<T> onSelected,
    bool enabled = true,
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
                        const TextStyle(fontFamily: 'Roboto', fontSize: 13.5))))
            .toList(),
        child: Container(
          decoration: BoxDecoration(
              color: enabled ? _scheme.surface : _scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _scheme.outlineVariant)),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Flexible(
                child: Text(value != null ? itemLabel(value) : '-',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13.5,
                        color: enabled
                            ? _scheme.onSurface
                            : _scheme.onSurfaceVariant))),
            const SizedBox(width: 2),
            if (enabled)
              Icon(Icons.expand_more_rounded,
                  size: 16, color: _scheme.onSurfaceVariant),
          ]),
        ),
      );

  Widget _fieldRow(String label, Widget field) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11.5,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 5),
          field,
        ],
      );

  Widget _pairRow(Widget a, Widget b) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: a),
          const SizedBox(width: 10),
          Expanded(child: b)
        ],
      );

  TextStyle get _style =>
      TextStyle(fontFamily: 'Roboto', fontSize: 13.5, color: _scheme.onSurface);

  InputDecoration _dec({bool readOnly = false, String? hint}) =>
      InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 12.5,
            color: _scheme.onSurfaceVariant),
        filled: true,
        fillColor: readOnly ? _scheme.surfaceContainerLow : _scheme.surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _scheme.primary, width: 1.4)),
        disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 1.2)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Colors.red, width: 1.4)),
      );
}

/// Genel amaçlı, herhangi bir tip için tam ekran arama sayfası (Kasa/Cari/Banka).
class _AramaSayfasi<T> extends StatefulWidget {
  final String baslik;
  final List<T> items;
  final T? secili;
  final String Function(T) itemLabel;
  final bool Function(T, String) filtre;

  const _AramaSayfasi({
    required this.baslik,
    required this.items,
    required this.itemLabel,
    required this.filtre,
    this.secili,
  });

  @override
  State<_AramaSayfasi<T>> createState() => _AramaSayfasiState<T>();
}

class _AramaSayfasiState<T> extends State<_AramaSayfasi<T>> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  late List<T> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.items;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filtrele(String q) {
    final query = q.trim().toLowerCase();
    setState(() {
      _filtered = query.isEmpty
          ? widget.items
          : widget.items.where((it) => widget.filtre(it, query)).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        titleSpacing: 0,
        title: Text(widget.baslik,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.w700,
                fontSize: 15.5,
                color: _scheme.onSurface)),
        actions: [
          IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Kapat',
              onPressed: () => Navigator.pop(context)),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: SizedBox(
              height: 42,
              child: TextField(
                controller: _searchCtrl,
                autofocus: true,
                onChanged: _filtrele,
                style: const TextStyle(fontFamily: 'Roboto', fontSize: 13.5),
                decoration: InputDecoration(
                  hintText: 'Ara...',
                  hintStyle: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: _scheme.onSurfaceVariant),
                  prefixIcon: const Icon(Icons.search_rounded, size: 19),
                  filled: true,
                  fillColor: _background,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _scheme.outlineVariant)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: _scheme.outlineVariant)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide:
                          BorderSide(color: _scheme.primary, width: 1.4)),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _filtered.isEmpty
          ? Center(
              child: Text('Sonuç bulunamadı',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      color: _scheme.onSurfaceVariant,
                      fontSize: 13)))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 6),
              itemCount: _filtered.length,
              separatorBuilder: (_, __) =>
                  Divider(height: 1, color: _scheme.outlineVariant),
              itemBuilder: (context, i) {
                final it = _filtered[i];
                final secili = it == widget.secili;
                return ListTile(
                  dense: true,
                  title: Text(widget.itemLabel(it),
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: _scheme.onSurface)),
                  trailing: secili
                      ? Icon(Icons.check_circle_rounded,
                          color: _scheme.primary, size: 20)
                      : null,
                  onTap: () => Navigator.pop(context, it),
                );
              },
            ),
    );
  }
}
