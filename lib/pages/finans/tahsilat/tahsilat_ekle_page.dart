import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/entities/finans/banka/bankahesap_dto.dart';
import '../../../models/entities/finans/kasa_islem/kasa_dto.dart';
import '../../../models/entities/finans/tahsilat/tahsilat_dto.dart';
import '../../../models/entities/finans/tahsilat/tahsilat_create_dto.dart';
import '../../../models/entities/finans/tahsilat/tahsilat_update_dto.dart';
import '../../../models/entities/finans/tahsilat/kredikartisozlesme_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/yonetim/belge_seri_dto.dart';
import '../../../services/finans/bankahesap_service.dart';
import '../../../services/finans/kasa_tanim_service.dart';
import '../../../services/finans/tahsilat_service.dart';
import '../../../services/finans/kredikartisozlesme_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../services/plasiyer/plasiyer_service.dart';
import '../../../services/cari/cari_service.dart';
import '../../../services/yonetim/belgeseri_service.dart';
import '../../../services/yonetim/kur_service.dart';
import '../../../helpers/cari_plasiyer_helper.dart';
import '../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../helpers/plasiyer_kasa_helper.dart';
import '../../../widgets/cari_bakiye_satiri.dart';
import '../../../helpers/varsayilan_proje_helper.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/belge_turu_couples.dart';
import '../../../helpers/tahsilat_couples.dart';
import '../../../helpers/number_format_helper.dart';
import '../../../services/offline/offline_service.dart';

const _kRed = Color(0xFFD32F2F);

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

/// Bir Sipariş/Fatura üzerinden "Tahsilat" açıldığında kaynak belge bilgisini taşır.
/// Cari/Döviz/Proje/Plasiyer otomatik dolar; Tahsilat tutarı, bu belgenin
/// toplamından o belgeye daha önce yapılmış tahsilatlar düşülerek bulunan
/// bakiyeyi aşamaz (web'deki New.razor.cs ile aynı mantık).
class TahsilatKaynakBelge {
  final String belgeId;
  final int belgeturu;
  final String? belgeserino;
  final String? belgeno;
  final int? cariid;
  final int? dovizid;
  final int? projeid;
  final int? plasiyerid;
  final double toplamTutar;
  final double? dovizToplam;

  const TahsilatKaynakBelge({
    required this.belgeId,
    required this.belgeturu,
    this.belgeserino,
    this.belgeno,
    this.cariid,
    this.dovizid,
    this.projeid,
    this.plasiyerid,
    required this.toplamTutar,
    this.dovizToplam,
  });
}

class TahsilatEklePage extends StatefulWidget {
  final TahsilatDto? editTahsilat;
  final TahsilatKaynakBelge? kaynakBelge;

  const TahsilatEklePage({super.key, this.editTahsilat, this.kaynakBelge});

  @override
  State<TahsilatEklePage> createState() => _TahsilatEklePageState();
}

class _TahsilatEklePageState extends State<TahsilatEklePage>
    with SingleTickerProviderStateMixin {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  final _svc = TahsilatService();
  final _form = GlobalKey<FormState>();
  late final TabController _tabs;

  bool _loading = true;
  bool _saving = false;

  bool get _isEdit => widget.editTahsilat != null;

  List<CariDtoLite> _cariler = [];
  List<DovizDto> _dovizler = [];
  List<ProjeDto> _projeler = [];
  List<PlasiyerDto> _plasiyerler = [];
  List<KasaDto> _kasalar = [];
  List<BankahesapDto> _hesaplar = [];
  List<BelgeSeriDto> _seriler = [];

  CariDtoLite? _seciliCari;
  DovizDto? _seciliDoviz;
  ProjeDto? _seciliProje;
  PlasiyerDto? _seciliPlasiyer;
  KasaDto? _seciliKasa;
  BankahesapDto? _seciliHesap;
  KredikartisozlesmeDto? _seciliSozlesme;

  int _seciliTip = 1; // 1=Nakit varsayılan
  int _seciliYil = DateTime.now().year;
  String? _seciliSeri;
  int? _seciliTaksit;

  bool _sozlesmeLoading = false;
  List<KredikartisozlesmeDto> _sozlesmeler = [];

  double _yapilmisTahsilat = 0;
  double _yapilmisDovizTahsilat = 0;

  bool _plasiyerKilitli =
      false; // Plasiyer kullanıcısı: kendi plasiyeri, değiştirilemez
  bool _kasaKilitli = false; // Plasiyer kasası bulunduysa kasa değiştirilemez
  KasaDto? _plasiyerKasa;
  String _ilkImza = ''; // çıkışta "kaydedilmemiş değişiklik" kontrolü için

  /// Kaynak belgenin gösterilecek belge numarası (seri-no boşsa belge no).
  String get _kaynakBelgeNo {
    final k = widget.kaynakBelge;
    if (k == null) return '-';
    if ((k.belgeserino ?? '').trim().isNotEmpty) return k.belgeserino!.trim();
    if ((k.belgeno ?? '').trim().isNotEmpty) return k.belgeno!.trim();
    return '-';
  }

  double? get _bakiye => widget.kaynakBelge != null
      ? widget.kaynakBelge!.toplamTutar - _yapilmisTahsilat
      : null;
  double? get _dovizBakiye => widget.kaynakBelge?.dovizToplam != null
      ? widget.kaynakBelge!.dovizToplam! - _yapilmisDovizTahsilat
      : null;

  late final TextEditingController _tarihCtrl;
  late final TextEditingController _belgeNoCtrl;
  late final TextEditingController _kurCtrl;
  late final TextEditingController _dovizTarihCtrl;
  late final TextEditingController _tutarCtrl;
  late final TextEditingController _dovizTutarCtrl;
  late final TextEditingController _aciklamaCtrl;

  final _fmt = DateFormat('dd.MM.yyyy');

  static bool _birimTL(String? birim) {
    final v = (birim ?? '').trim().toUpperCase();
    return v == 'TL' || v == 'TRY' || v == '₺';
  }

  bool get _isDovizli => _seciliDoviz != null && !_birimTL(_seciliDoviz!.Birim);
  bool get _kasaGerekli => _seciliTip == 1;
  bool get _hesapGerekli => _seciliTip == 2 || _seciliTip == 3;
  bool get _krediKartiMi => _seciliTip == 3;

  List<int> get _taksitSecenekleri {
    final bas = _seciliSozlesme?.Baslangictaksit;
    final bit = _seciliSozlesme?.Bitistaksit;
    if (bas == null || bit == null || bit < bas) return [];
    return List.generate(bit - bas + 1, (i) => bas + i);
  }

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _tabs.addListener(() {
      if (mounted) setState(() {});
    });
    final now = DateTime.now();
    _tarihCtrl = TextEditingController(text: _fmt.format(now));
    _belgeNoCtrl = TextEditingController();
    _kurCtrl = TextEditingController();
    _dovizTarihCtrl = TextEditingController(text: _fmt.format(now));
    _tutarCtrl = TextEditingController();
    _dovizTutarCtrl = TextEditingController();
    _aciklamaCtrl = TextEditingController();

    _tutarCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    _loadLookups();
  }

  @override
  void dispose() {
    _tabs.dispose();
    _tarihCtrl.dispose();
    _belgeNoCtrl.dispose();
    _kurCtrl.dispose();
    _dovizTarihCtrl.dispose();
    _tutarCtrl.dispose();
    _dovizTutarCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    final now = DateTime.now();

    final results = await Future.wait([
      CariService().getCariler(token).catchError((_) => <CariDtoLite>[]),
      DovizService().getDovizler(token).catchError((_) => <DovizDto>[]),
      ProjeService().getProjeList(token).catchError((_) => <ProjeDto>[]),
      PlasiyerService()
          .getPlasiyerler(token)
          .catchError((_) => <PlasiyerDto>[]),
      KasaTanimService()
          .getAllWithoutAuth(token)
          .catchError((_) => <KasaDto>[]),
      BankahesapService()
          .getAllWithoutAuth(token)
          .catchError((_) => <BankahesapDto>[]),
      BelgeSeriService()
          .getAll(token, BelgeTuruCouples.tahsilat)
          .catchError((_) => <BelgeSeriDto>[]),
    ]);

    if (!mounted) return;
    _cariler = results[0] as List<CariDtoLite>;
    _dovizler = results[1] as List<DovizDto>;
    _projeler = results[2] as List<ProjeDto>;
    _plasiyerler = results[3] as List<PlasiyerDto>;
    _kasalar = results[4] as List<KasaDto>;
    _hesaplar = results[5] as List<BankahesapDto>;
    _seriler = results[6] as List<BelgeSeriDto>;

    if (_isEdit) {
      await _fillEdit(token);
    } else {
      final kaynak = widget.kaynakBelge;

      _seciliDoviz = kaynak?.dovizid != null
          ? (_dovizler.where((d) => d.Id == kaynak!.dovizid).firstOrNull ??
              _dovizler.where((d) => _birimTL(d.Birim)).firstOrNull)
          : _dovizler.where((d) => _birimTL(d.Birim)).firstOrNull;
      _seciliCari = kaynak?.cariid != null
          ? _cariler.where((c) => c.Id == kaynak!.cariid).firstOrNull
          : null;
      _seciliProje = kaynak?.projeid != null
          ? _projeler.where((p) => p.id == kaynak!.projeid).firstOrNull
          : _projeler.firstOrNull;
      _seciliPlasiyer = kaynak?.plasiyerid != null
          ? _plasiyerler.where((p) => p.Id == kaynak!.plasiyerid).firstOrNull
          : _plasiyerler.firstOrNull;

      // Liste sunucuda plasiyere göre süzülür (AllWithoutAuth); ilk kayıt varsayılan seçilir.
      _seciliKasa = _kasalar.firstOrNull;

      if (_seriler.isNotEmpty) {
        _seciliSeri = _seriler.first.seri;
        try {
          final no = await _svc.getNewTahsilatNo(token, _seciliSeri!, now.year);
          if (mounted) _belgeNoCtrl.text = no;
        } catch (_) {}
      }

      if (kaynak != null) {
        try {
          final mevcutlar = await _svc.getAllByBelgeid(token, kaynak.belgeId);
          _yapilmisTahsilat =
              mevcutlar.fold(0.0, (s, e) => s + (e.Tahsilattutari ?? 0));
          _yapilmisDovizTahsilat =
              mevcutlar.fold(0.0, (s, e) => s + (e.Doviztutar ?? 0));
        } catch (_) {}
      }
    }

    // Plasiyer kullanıcısı ise plasiyer kendisi olarak gelir ve değiştirilemez.
    final kp = await KullaniciPlasiyerHelper.getir();
    if (kp.kilitli) {
      _plasiyerKilitli = true;
      final own = _plasiyerler.where((p) => p.Id == kp.plasiyerid).firstOrNull;
      if (own != null) _seciliPlasiyer = own;
    }
    if (kp.kilitli) {
      _plasiyerKasa = await PlasiyerKasaHelper.getir(token, kp.plasiyerid,
          mevcutKasalar: _kasalar, kilitli: true);
      if (_plasiyerKasa != null) {
        _kasaKilitli = true;
        if (!_isEdit && _seciliTip == 1)
          _seciliKasa =
              _kasalar.where((k) => k.Id == _plasiyerKasa!.Id).firstOrNull ??
                  _plasiyerKasa;
      }
    }

    _ilkImza = _imza();
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _fillEdit(String token) async {
    final t = widget.editTahsilat!;

    _seciliCari = _cariler.where((c) => c.Id == t.Cariid).firstOrNull;
    _seciliDoviz = _dovizler.where((d) => d.Id == t.Dovizid).firstOrNull;
    _seciliProje = _projeler.where((p) => p.id == t.Projeid).firstOrNull;
    _seciliPlasiyer =
        _plasiyerler.where((p) => p.Id == t.Plasiyerid).firstOrNull;
    _seciliKasa = _kasalar.where((k) => k.Id == t.Kasaid).firstOrNull;
    _seciliHesap = _hesaplar.where((h) => h.Id == t.Bankahesapid).firstOrNull;
    _seciliTip = t.Tip ?? 1;
    _seciliSeri = t.Belgeseri;
    _seciliYil = t.Belgeyil ?? DateTime.now().year;

    _tarihCtrl.text = t.Tarih != null ? _fmt.format(t.Tarih!) : '';
    _belgeNoCtrl.text = t.Belgeno ?? '';
    _tutarCtrl.text = t.Tahsilattutari != null
        ? NumberFormatHelper.format(t.Tahsilattutari!)
        : '';
    _kurCtrl.text =
        t.Kur != null ? NumberFormatHelper.format(t.Kur!, decimal: 4) : '';
    _dovizTarihCtrl.text = t.Doviztarih != null
        ? _fmt.format(t.Doviztarih!)
        : _fmt.format(DateTime.now());
    _dovizTutarCtrl.text =
        t.Doviztutar != null ? NumberFormatHelper.format(t.Doviztutar!) : '';
    _aciklamaCtrl.text = t.Aciklama ?? '';

    if (_krediKartiMi && t.Bankahesapid != null) {
      try {
        final list = await KredikartisozlesmeService()
            .getAllByBankahesapidWithoutAuth(token, t.Bankahesapid!);
        if (mounted) {
          _sozlesmeler = list;
          _seciliSozlesme =
              list.where((s) => s.Id == t.Kredikartisozlesmeid).firstOrNull ??
                  list.firstOrNull;
          _seciliTaksit = t.Taksitsayisi;
        }
      } catch (_) {}
    }
  }

  Future<void> _fetchNewBelgeNo() async {
    if (_seciliSeri == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    try {
      final no = await _svc.getNewTahsilatNo(token, _seciliSeri!, _seciliYil);
      if (mounted)
        setState(() {
          _belgeNoCtrl.text = no;
        });
    } catch (_) {}
  }

  Future<void> _fetchSozlesmeler() async {
    if (_seciliHesap?.Id == null) {
      setState(() {
        _sozlesmeler = [];
        _seciliSozlesme = null;
        _seciliTaksit = null;
      });
      return;
    }
    setState(() => _sozlesmeLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    try {
      final list = await KredikartisozlesmeService()
          .getAllByBankahesapidWithoutAuth(token, _seciliHesap!.Id!);
      if (!mounted) return;
      setState(() {
        _sozlesmeler = list;
        _seciliSozlesme = list.firstOrNull;
        _seciliTaksit = _taksitSecenekleri.firstOrNull;
        _sozlesmeLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sozlesmeler = [];
        _seciliSozlesme = null;
        _seciliTaksit = null;
        _sozlesmeLoading = false;
      });
    }
  }

  Future<void> _fetchKur(DateTime? date) async {
    if (!_isDovizli || _seciliDoviz?.Id == null || date == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token_final') ?? '';
    try {
      final kurDto = await KurService()
          .getByDovizIdAndDate(token, _seciliDoviz!.Id!, date);
      final kur = kurDto?.Dovizsatis ?? kurDto?.Dovizalis;
      if (kur != null && mounted)
        setState(() {
          _kurCtrl.text = NumberFormatHelper.format(kur, decimal: 4);
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

  Future<void> _save() async {
    // Not: Form alanları sekmelere dağıldığı için Form.validate() görünmeyen
    // sekmedeki hatayı sessizce yutar. Bu yüzden zorunlu alanlar burada elle,
    // kullanıcıya görünür bir uyarıyla kontrol ediliyor.
    if (_seciliCari == null) {
      UiFeedback.showError(context, 'Lütfen cari seçiniz.');
      return;
    }
    if (_seciliDoviz == null) {
      UiFeedback.showError(context, 'Lütfen döviz tipi seçiniz.');
      return;
    }
    if (_seciliProje == null) {
      UiFeedback.showError(context, 'Lütfen proje seçiniz.');
      return;
    }
    if (_seciliPlasiyer == null) {
      UiFeedback.showError(context, 'Lütfen plasiyer seçiniz.');
      return;
    }
    if (_kasaGerekli && _seciliKasa == null) {
      UiFeedback.showError(context, 'Lütfen kasa seçiniz.');
      return;
    }
    if (_hesapGerekli && _seciliHesap == null) {
      UiFeedback.showError(context, 'Lütfen banka hesabı seçiniz.');
      return;
    }
    if (_krediKartiMi && _seciliSozlesme == null) {
      UiFeedback.showError(context, 'Lütfen kredi kartı sözleşmesi seçiniz.');
      return;
    }
    if (_krediKartiMi && _seciliTaksit == null) {
      UiFeedback.showError(context, 'Lütfen taksit sayısı seçiniz.');
      return;
    }
    if (_tutarCtrl.text.trim().isEmpty) {
      UiFeedback.showError(context, 'Tahsilat tutarı giriniz.');
      return;
    }
    if (_isDovizli && _kurCtrl.text.trim().isEmpty) {
      UiFeedback.showError(context, 'Döviz tipi TL olmadığından kur giriniz.');
      return;
    }

    if (!_isEdit && widget.kaynakBelge != null) {
      final girilenTutar = NumberFormatHelper.parse(_tutarCtrl.text);
      if (_bakiye != null && girilenTutar > _bakiye! + 0.01) {
        UiFeedback.showError(context,
            'Tahsilat tutarı bakiyeden fazla olamaz! (Bakiye: ${NumberFormatHelper.format(_bakiye!)})');
        return;
      }
      if (_isDovizli && _dovizBakiye != null) {
        final girilenDoviz = NumberFormatHelper.parse(_dovizTutarCtrl.text);
        if (girilenDoviz > _dovizBakiye! + 0.01) {
          UiFeedback.showError(context,
              'Tahsilat döviz tutarı döviz bakiyesinden fazla olamaz!');
          return;
        }
      }
    }

    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';

      final tarih = _parseDate(_tarihCtrl.text);
      final dovizTarih = _parseDate(_dovizTarihCtrl.text);
      final kur = NumberFormatHelper.parse(_kurCtrl.text);
      final dovizTutar = NumberFormatHelper.parse(_dovizTutarCtrl.text);
      final tutar = NumberFormatHelper.parse(_tutarCtrl.text);

      if (_isEdit) {
        final upd = TahsilatUpdateDto()
          ..id = widget.editTahsilat!.Id
          ..cariid = _seciliCari!.Id
          ..dovizid = _seciliDoviz!.Id
          ..projeid = _seciliProje!.id
          ..plasiyerid = _seciliPlasiyer!.Id
          ..kasaid = _kasaGerekli ? _seciliKasa!.Id : null
          ..bankahesapid = _hesapGerekli ? _seciliHesap!.Id : null
          ..kredikartisozlesmeid = _krediKartiMi ? _seciliSozlesme!.Id : null
          ..taksitsayisi = _krediKartiMi ? _seciliTaksit : null
          ..tarih = tarih
          ..tip = _seciliTip
          ..tahsilattutari = tutar
          ..kur = _isDovizli ? kur : null
          ..doviztarih = _isDovizli ? dovizTarih : null
          ..doviztutar = _isDovizli ? dovizTutar : null
          ..aciklama = _aciklamaCtrl.text.trim().isEmpty
              ? null
              : _aciklamaCtrl.text.trim();

        // ── Offline mod kontrolü ─────────────────────────────────────────
        final manuelOfflineUpd = await OfflineService.instance.getOfflineMode();
        final internetYokUpd = !OfflineService.instance.isOnline.value;
        if (manuelOfflineUpd || internetYokUpd) {
          await OfflineService.instance.enqueue('single_full', {
            'endpoint': '/Tahsilat',
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
        final dto = TahsilatCreateDto()
          ..cariid = _seciliCari!.Id
          ..dovizid = _seciliDoviz!.Id
          ..projeid = _seciliProje!.id
          ..plasiyerid = _seciliPlasiyer!.Id
          ..kasaid = _kasaGerekli ? _seciliKasa!.Id : null
          ..bankahesapid = _hesapGerekli ? _seciliHesap!.Id : null
          ..kredikartisozlesmeid = _krediKartiMi ? _seciliSozlesme!.Id : null
          ..taksitsayisi = _krediKartiMi ? _seciliTaksit : null
          ..belgeseri = _seciliSeri
          ..belgeyil = _seciliYil
          ..belgeno = _belgeNoCtrl.text.trim()
          ..belgeserino = '${_seciliSeri ?? ''}$_seciliYil'
          ..tarih = tarih
          ..tip = _seciliTip
          ..tahsilattutari = tutar
          ..kur = _isDovizli ? kur : null
          ..doviztarih = _isDovizli ? dovizTarih : null
          ..doviztutar = _isDovizli ? dovizTutar : null
          ..islembelgeid = widget.kaynakBelge?.belgeId
          ..islembelgeturu = widget.kaynakBelge?.belgeturu
          ..aciklama = _aciklamaCtrl.text.trim().isEmpty
              ? null
              : _aciklamaCtrl.text.trim();

        // ── Offline mod kontrolü ─────────────────────────────────────────
        final manuelOffline = await OfflineService.instance.getOfflineMode();
        final internetYok = !OfflineService.instance.isOnline.value;
        if (manuelOffline || internetYok) {
          await OfflineService.instance.enqueue('single_full', {
            'endpoint': '/Tahsilat',
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

        await _svc.create(token, dto);
      }

      if (!mounted) return;
      UiFeedback.showSuccess(
          context, _isEdit ? 'Tahsilat güncellendi.' : 'Tahsilat kaydedildi.',
          autoPop: true);
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openCariArama() async {
    final secilen = await Navigator.push<CariDtoLite>(
      context,
      PermissionMaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => _AramaSayfasi<CariDtoLite>(
                baslik: 'Cari Seç',
                items: _cariler,
                secili: _seciliCari,
                itemLabel: (c) => '${c.Ad ?? ''} (${c.Kod ?? ''})',
                filtre: (c, q) =>
                    (c.Ad ?? '').toLowerCase().contains(q) ||
                    (c.Kod ?? '').toLowerCase().contains(q),
              )),
    );
    if (secilen != null && mounted) {
      setState(() => _seciliCari = secilen);
      if (widget.kaynakBelge == null) {
        final pid = await CariPlasiyerHelper.getPlasiyerIdOrFirst(
            secilen.Id, _plasiyerler);
        final prid = await VarsayilanProjeHelper.pickFrom(_projeler);
        if (!mounted) return;
        setState(() {
          _seciliPlasiyer = _plasiyerKilitli
              ? _seciliPlasiyer
              : (_plasiyerler.where((p) => p.Id == pid).firstOrNull ??
                  _seciliPlasiyer);
          _seciliProje =
              _projeler.where((p) => p.id == prid).firstOrNull ?? _seciliProje;
        });
      }
    }
  }

  // ── Sekme geçişi: alanlar doldurulmadan ilerlenemez ─────────────────────────────
  /// [i]. sekmedeki eksik zorunlu alanın mesajı; eksik yoksa null.
  String? _sekmeHatasi(int i) {
    switch (i) {
      case 0:
        if (_parseDate(_tarihCtrl.text) == null) return 'Lütfen tarih seçiniz.';
        if (_seriler.isNotEmpty && _seciliSeri == null)
          return 'Lütfen belge serisi seçiniz.';
        if (_seriler.isNotEmpty && _belgeNoCtrl.text.trim().isEmpty)
          return 'Belge numarası alınamadı, seriyi yeniden seçiniz.';
        return null;
      case 1:
        if (_kasaGerekli && _seciliKasa == null) return 'Lütfen kasa seçiniz.';
        if (_hesapGerekli && _seciliHesap == null)
          return 'Lütfen banka hesabı seçiniz.';
        if (_krediKartiMi && _seciliSozlesme == null)
          return 'Lütfen kredi kartı sözleşmesi seçiniz.';
        if (_krediKartiMi && _seciliTaksit == null)
          return 'Lütfen taksit sayısı seçiniz.';
        if (_seciliCari == null) return 'Lütfen cari seçiniz.';
        if (_seciliPlasiyer == null) return 'Lütfen plasiyer seçiniz.';
        if (_seciliDoviz == null) return 'Lütfen döviz tipi seçiniz.';
        if (_isDovizli && NumberFormatHelper.parse(_kurCtrl.text) <= 0)
          return 'Döviz tipi TL olmadığından kur giriniz.';
        if (NumberFormatHelper.parse(_tutarCtrl.text) <= 0)
          return 'Lütfen tutar giriniz.';
        return null;
      case 2:
        if (_seciliProje == null) return 'Lütfen proje seçiniz.';
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

  /// Sekme başlığına dokunarak ileri atlamayı da engeller; eksik sekmeye döndürür.
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
        _seciliKasa?.Id,
        _seciliHesap?.Id,
        _seciliTip,
        _seciliSozlesme?.Id,
        _seciliTaksit,
        _tarihCtrl.text,
        _seciliCari?.Id,
        _seciliPlasiyer?.Id,
        _seciliProje?.id,
        _seciliDoviz?.Id,
        _kurCtrl.text,
        _dovizTarihCtrl.text,
        _dovizTutarCtrl.text,
        _tutarCtrl.text,
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
                _isEdit ? Icons.edit_note_rounded : Icons.add_card_rounded,
                size: 17,
                color: _scheme.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _kaynakVar
                        ? '$_kaynakBelgeNo nolu belgenin tahsilat detayları'
                        : (_isEdit ? 'Tahsilat Düzenle' : 'Yeni Tahsilat'),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        fontSize: _kaynakVar ? 14 : 15.5,
                        color: _scheme.onSurface,
                        height: 1.2),
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
              isScrollable: false,
              onTap: _sekmeTikla,
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
                    modules: [1025],
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
  // (Tarih | İşlem Tipi) • Belge Seri / Yıl / No
  Widget _tabBelge() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _pairRow(
          _fieldRow(
              'Tarih',
              _kaynakVar
                  ? _sabitTarihKutusu()
                  : _buildDateField(_tarihCtrl, onChanged: (_) {})),
          _buildTipDropdown(),
        ),
        const SizedBox(height: 12),
        _buildSeriTable(),
      ]);

  /// Şimdilik yalnızca Nakit ve Kredi Kartı. (Eski bir banka tahsilatı düzenlenirken kendi tipi de listelenir.)
  Widget _buildTipDropdown() {
    final secenekler = TahsilattipiCouples.list
        .where((e) =>
            e.value == 1 || e.value == 3 || (_isEdit && e.value == _seciliTip))
        .toList();
    return _fieldRow(
        'İşlem Tipi',
        DropdownButtonFormField<int>(
          initialValue: _seciliTip,
          isExpanded: true,
          decoration: _dec('İşlem Tipi', readOnly: _isEdit),
          style: _style,
          onChanged: _isEdit
              ? null
              : (v) {
                  if (v == null) return;
                  setState(() {
                    _seciliTip = v;
                    _seciliKasa = null;
                    _seciliHesap = null;
                    _seciliSozlesme = null;
                    _seciliTaksit = null;
                    _sozlesmeler = [];
                    if (v == 1)
                      _seciliKasa = _plasiyerKasa ?? _kasalar.firstOrNull;
                  });
                },
          items: secenekler
              .map((e) => DropdownMenuItem(
                  value: e.value,
                  child: Text(e.text,
                      style:
                          const TextStyle(fontFamily: 'Roboto', fontSize: 13))))
              .toList(),
        ));
  }

  Widget _sabitTarihKutusu() => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
            color: _scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _scheme.outlineVariant)),
        child: Row(children: [
          Icon(Icons.event_available_rounded,
              size: 16, color: _scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Flexible(
              child: Text(_tarihCtrl.text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13.5,
                      color: _scheme.onSurfaceVariant))),
        ]),
      );

  // ── Tab 2: İşlem ────────────────────────────────────────────────────────────────
  // Kasa (veya banka hesabı) • Cari • Plasiyer • (Döviz | Kur) • Tutar • Bakiye
  Widget _tabIslem() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_kasaGerekli)
          _buildKasaDropdown()
        else ...[
          _buildHesapDropdown(),
          if (_krediKartiMi) ...[
            const SizedBox(height: 12),
            _buildSozlesmeDropdown(),
            const SizedBox(height: 12),
            _buildTaksitDropdown(),
          ],
        ],
        const SizedBox(height: 12),
        _buildCariField(),
        const SizedBox(height: 12),
        _buildPlasiyerDropdown(),
        const SizedBox(height: 12),
        if (_isDovizli)
          _pairRow(
              _buildDovizRow(),
              _fieldRow(
                  'Kur *', _buildTutarField(_kurCtrl, 'Kur', required: true)))
        else
          _buildDovizRow(),
        if (_isDovizli) ...[
          const SizedBox(height: 12),
          _pairRow(
            _fieldRow(
                'Kur Tarihi',
                _buildDateField(_dovizTarihCtrl, onChanged: (d) {
                  _fetchKur(d);
                })),
            _fieldRow('Döviz Tutar',
                _buildTutarField(_dovizTutarCtrl, 'Döviz Tutar')),
          ),
        ],
        const SizedBox(height: 12),
        _fieldRow(
            'Tutar *', _buildTutarField(_tutarCtrl, 'Tutar', required: true)),
        if (_kaynakVar) _belgeBakiyeNotu(),
        if (_seciliCari != null) ...[
          const SizedBox(height: 10),
          _buildBakiyeKutusu(),
        ],
      ]);

  /// Kaynak belgenin kalan tahsilat tutarı (üst sınır) — Tutar alanının altında küçük not.
  Widget _belgeBakiyeNotu() => Padding(
        padding: const EdgeInsets.only(top: 6, left: 2),
        child: Text(
          'Belge $_kaynakBelgeNo • Toplam ${NumberFormatHelper.format(widget.kaynakBelge!.toplamTutar)}'
          ' • Tahsil edilen ${NumberFormatHelper.format(_yapilmisTahsilat)}'
          ' • Kalan ${NumberFormatHelper.format(_bakiye ?? 0)}',
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11,
              color: _scheme.onSurfaceVariant),
        ),
      );

  /// Tahsilatta cari borcu azalır: değişim = −tutar. Düzenlemede kaydın eski etkisi geri eklenir
  /// (güncel bakiye zaten onu içeriyor).
  double? get _bakiyeDegisim {
    if (_seciliCari == null) return null;
    var d = -NumberFormatHelper.parse(_tutarCtrl.text);
    if (_isEdit) {
      final t = widget.editTahsilat!;
      if (t.Cariid == _seciliCari!.Id) d += (t.Tahsilattutari ?? 0);
    }
    return d;
  }

  /// Cari bakiyesi + bu tahsilatla oluşacak bakiye (tutar girildikçe güncellenir).
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
          CariBakiyeSatiri(cariId: _seciliCari!.Id, degisim: _bakiyeDegisim),
        ]),
      );

  // ── Tab 3: Detay ────────────────────────────────────────────────────────────────
  // Proje • Açıklama   (Tahsilat kaydında Evrak Tarihi / Evrak No alanı yok)
  Widget _tabDetay() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _buildProjeDropdown(),
        const SizedBox(height: 12),
        _fieldRow(
            'Açıklama',
            TextFormField(
                controller: _aciklamaCtrl,
                style: _style,
                decoration: _dec('Açıklama'),
                maxLines: 4,
                maxLength: 255)),
      ]);

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

  InputDecoration _dec(String hint, {bool readOnly = false}) => InputDecoration(
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
      );

  bool get _kaynakVar => widget.kaynakBelge != null;

  /// Değiştirilemeyen alan (kaynak belgeden gelen cari/proje, plasiyer kullanıcısının plasiyeri).
  Widget _kilitliKutu(String? deger, String bosMetin) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
            color: _scheme.surfaceContainerLow,
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
                      ? _scheme.onSurfaceVariant
                      : _scheme.onSurfaceVariant),
            ),
          ),
          Icon(Icons.lock_outline_rounded,
              size: 16, color: _scheme.onSurfaceVariant),
        ]),
      );

  Widget _buildCariField() {
    final deger = _seciliCari != null
        ? '${_seciliCari!.Kod ?? ''} - ${_seciliCari!.Ad ?? ''}'
        : null;
    return _fieldRow(
        'Cari *',
        _kaynakVar
            ? _kilitliKutu(deger, 'Cari')
            : InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _openCariArama,
                child: _seciliAlanKutusu(deger, 'Cari seçiniz'),
              ));
  }

  Widget _buildProjeDropdown() {
    final deger = _seciliProje != null
        ? '${_seciliProje!.kod ?? ''} - ${_seciliProje!.ad ?? ''}'
        : null;
    return _fieldRow(
        'Proje *',
        _kaynakVar
            ? _kilitliKutu(deger, 'Proje')
            : InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final secilen = await Navigator.push<ProjeDto>(
                    context,
                    PermissionMaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => _AramaSayfasi<ProjeDto>(
                              baslik: 'Proje Seç',
                              items: _projeler,
                              secili: _seciliProje,
                              itemLabel: (p) =>
                                  '${p.kod ?? ''} - ${p.ad ?? ''}',
                              filtre: (p, q) =>
                                  (p.ad ?? '').toLowerCase().contains(q) ||
                                  (p.kod ?? '').toLowerCase().contains(q),
                            )),
                  );
                  if (secilen != null) setState(() => _seciliProje = secilen);
                },
                child: _seciliAlanKutusu(deger, 'Proje seçiniz'),
              ));
  }

  Widget _buildPlasiyerDropdown() {
    final deger = _seciliPlasiyer != null
        ? '${_seciliPlasiyer!.Kod ?? ''} - ${_seciliPlasiyer!.Adsoyad ?? ''}'
        : null;
    return _fieldRow(
        'Plasiyer *',
        _plasiyerKilitli
            // Plasiyer kullanıcısı: kendi plasiyeri sabit gelir, değiştirilemez.
            ? _kilitliKutu(deger, 'Plasiyer')
            : InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () async {
                  final secilen = await Navigator.push<PlasiyerDto>(
                    context,
                    PermissionMaterialPageRoute(
                        fullscreenDialog: true,
                        builder: (_) => _AramaSayfasi<PlasiyerDto>(
                              baslik: 'Plasiyer Seç',
                              items: _plasiyerler,
                              secili: _seciliPlasiyer,
                              itemLabel: (p) =>
                                  '${p.Kod ?? ''} - ${p.Adsoyad ?? ''}',
                              filtre: (p, q) =>
                                  (p.Adsoyad ?? '').toLowerCase().contains(q) ||
                                  (p.Kod ?? '').toLowerCase().contains(q),
                            )),
                  );
                  if (secilen != null)
                    setState(() => _seciliPlasiyer = secilen);
                },
                child: _seciliAlanKutusu(deger, 'Plasiyer seçiniz'),
              ));
  }

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

  Widget _buildKasaDropdown() => _fieldRow(
      'Kasa *',
      _kasaKilitli
          // Plasiyer kullanıcı: yalnızca kendi plasiyer kasası, değiştirilemez.
          ? _kilitliKutu(
              _seciliKasa != null
                  ? '${_seciliKasa!.Kod ?? ''} - ${_seciliKasa!.Ad ?? ''}'
                  : null,
              'Kasa')
          : InkWell(
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
                            itemLabel: (k) => '${k.Ad ?? ''} (${k.Kod ?? ''})',
                            filtre: (k, q) =>
                                (k.Ad ?? '').toLowerCase().contains(q) ||
                                (k.Kod ?? '').toLowerCase().contains(q),
                          )),
                );
                if (secilen != null) setState(() => _seciliKasa = secilen);
              },
              child: _seciliAlanKutusu(
                  _seciliKasa != null
                      ? '${_seciliKasa!.Ad ?? ''} (${_seciliKasa!.Kod ?? ''})'
                      : null,
                  'Kasa seçiniz'),
            ));

  Widget _buildHesapDropdown() {
    // Kredi kartı tahsilatında sadece "Kredi Kartı" tipi banka hesapları listelenir.
    final hesapListesi = _krediKartiMi
        ? (_hesaplar.where((h) => h.Hesaptipi == 18).toList().isNotEmpty
            ? _hesaplar.where((h) => h.Hesaptipi == 18).toList()
            : _hesaplar)
        : _hesaplar;
    return _fieldRow(
        'Banka Hesabı *',
        InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () async {
            final secilen = await Navigator.push<BankahesapDto>(
              context,
              PermissionMaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => _AramaSayfasi<BankahesapDto>(
                        baslik: 'Hesap Seç',
                        items: hesapListesi,
                        secili: _seciliHesap,
                        itemLabel: (b) => '${b.Ad ?? ''} (${b.Kod ?? ''})',
                        filtre: (b, q) =>
                            (b.Ad ?? '').toLowerCase().contains(q) ||
                            (b.Kod ?? '').toLowerCase().contains(q),
                      )),
            );
            if (secilen != null) {
              setState(() => _seciliHesap = secilen);
              if (_krediKartiMi) _fetchSozlesmeler();
            }
          },
          child: _seciliAlanKutusu(
              _seciliHesap != null
                  ? '${_seciliHesap!.Ad ?? ''} (${_seciliHesap!.Kod ?? ''})'
                  : null,
              'Hesap seçiniz'),
        ));
  }

  Widget _buildSozlesmeDropdown() => _fieldRow(
      'Kredi Kartı Sözleşmesi *',
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: _sozlesmeLoading
            ? null
            : () async {
                final secilen = await Navigator.push<KredikartisozlesmeDto>(
                  context,
                  PermissionMaterialPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => _AramaSayfasi<KredikartisozlesmeDto>(
                            baslik: 'Sözleşme Seç',
                            items: _sozlesmeler,
                            secili: _seciliSozlesme,
                            itemLabel: (s) => s.Sozlesmeno ?? '-',
                            filtre: (s, q) =>
                                (s.Sozlesmeno ?? '').toLowerCase().contains(q),
                          )),
                );
                if (secilen != null)
                  setState(() {
                    _seciliSozlesme = secilen;
                    _seciliTaksit = _taksitSecenekleri.firstOrNull;
                  });
              },
        child: _seciliAlanKutusu(
          _seciliSozlesme?.Sozlesmeno,
          _sozlesmeLoading
              ? 'Yükleniyor...'
              : (_seciliHesap == null
                  ? 'Önce banka hesabı seçiniz'
                  : 'Sözleşme seçiniz'),
        ),
      ));

  Widget _buildTaksitDropdown() => _fieldRow(
      'Taksit Sayısı *',
      DropdownButtonFormField<int>(
        isExpanded: true,
        initialValue:
            _taksitSecenekleri.contains(_seciliTaksit) ? _seciliTaksit : null,
        decoration: _dec('Taksit Sayısı'),
        style: _style,
        onChanged: (v) => setState(() => _seciliTaksit = v),
        items: _taksitSecenekleri
            .map((t) => DropdownMenuItem(
                value: t,
                child: Text('$t Taksit',
                    style:
                        const TextStyle(fontFamily: 'Roboto', fontSize: 13))))
            .toList(),
      ));

  Widget _buildDovizRow() => _fieldRow(
      'Döviz *',
      DropdownButtonFormField<DovizDto>(
        initialValue: _seciliDoviz,
        decoration: _dec('Döviz'),
        style: _style,
        isExpanded: true,
        items: _dovizler
            .map((d) => DropdownMenuItem(
                value: d,
                child: Text(d.Birim ?? '',
                    style:
                        const TextStyle(fontFamily: 'Roboto', fontSize: 13))))
            .toList(),
        onChanged: (v) => setState(() {
          _seciliDoviz = v;
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
            lastDate: DateTime.now(),
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
            ? (v) => (v == null || v.trim().isEmpty) ? 'Zorunlu alan' : null
            : null,
      );

  Widget _buildSeriTable() =>
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
              items: _seriler.map((s) => s.seri ?? '-').toList(),
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
              items: List.generate(7, (i) => DateTime.now().year - i),
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
              readOnly: true,
              style: _style.copyWith(color: _scheme.onSurfaceVariant),
              decoration: _dec('Belge No', readOnly: true),
            ),
          ),
        ]),
      ]);

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
}

/// Genel amaçlı, herhangi bir tip için tam ekran arama sayfası (Cari/Proje/Plasiyer/Kasa/Hesap/Sözleşme).
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
