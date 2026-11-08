import '../../widgets/document_tracking_sheet.dart';
import '../../models/entities/stok/document_tracking.dart';
import '../../widgets/document_extra_notes.dart';
import '../../widgets/fatura/fatura_genel_iskonto_sheet.dart';
import '../../helpers/irsaliye_hesap_helper.dart';
import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../theme/app_theme.dart';
import '../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../widgets/erp_ui.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/ui_feedback.dart';
import '../../helpers/cari_plasiyer_helper.dart';
import '../../helpers/varsayilan_depo_helper.dart';
import '../../helpers/varsayilan_proje_helper.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../widgets/quick_barcode_scan_sheet.dart';
//import '../../../models/entities/cari/cari_dto_full.dart';
import '../../helpers/belge_turu_couples.dart';
import '../../helpers/number_format_helper.dart';
import '../../helpers/fatura_hesap_helper.dart';
import '../../helpers/lookups.dart';
import '../../helpers/stokhareket_couples.dart';
import '../../models/entities/irsaliye/irsaliye_dto.dart';
import '../../models/entities/irsaliye/irsaliyehareket_dto.dart';
import '../../models/entities/cari/cari_dto_lite.dart';
import '../../models/entities/cari/cariadres_dto.dart';
import '../../models/entities/proje/proje_dto.dart';
import '../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../models/entities/referans/referans_dto.dart';
import '../../models/entities/stok/stok_list_dto.dart';
import '../../models/entities/stok/stok_dto.dart';
import '../../models/entities/depo/depo_dto.dart';
import '../../models/entities/yonetim/belge_seri_dto.dart';
import '../../models/entities/helper/doviz_dto.dart';
import '../../services/irsaliye/irsaliye_service.dart';
import '../../services/cari/cari_service.dart';
import '../../services/proje/proje_service.dart';
import '../../services/plasiyer/plasiyer_service.dart';
import '../../services/referans/referans_service.dart';
import '../../services/stok/stok_service.dart';
import '../../services/yonetim/belgeseri_service.dart';
import '../../services/yonetim/kur_service.dart';
import '../../services/depo/depo_service.dart';
import '../../services/helper/doviz_service.dart';
import '../../widgets/erp_selector.dart';
import '../../widgets/irsaliye/irsaliye_kalem_form_sheet.dart';
import '../../models/entities/lojistik/arac_dto.dart';
import '../../models/entities/lojistik/surucu_dto.dart';
import '../../services/lojistik/arac_service.dart';
import '../../services/lojistik/surucu_service.dart';
import '../../helpers/tasimafazi_couples.dart';
import '../../services/offline/offline_service.dart';
import '../../services/yazici/bluetooth_print_service.dart';
import '../../services/yazici/yazici_sablon_service.dart';

class IrsaliyeEklePage extends StatefulWidget {
  final String? irsaliyeId;
  const IrsaliyeEklePage({super.key, this.irsaliyeId});

  @override
  State<IrsaliyeEklePage> createState() => _IrsaliyeEklePageState();
}

class _IrsaliyeEklePageState extends State<IrsaliyeEklePage>
    with SingleTickerProviderStateMixin {
  // ─── Renkler ─────────────────────────────────────────────
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.onSurface;
  Color get _accent => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;

  bool get _isEditMode => widget.irsaliyeId != null;

  late TabController _tabCtrl;
  final _svc = IrsaliyeService();

  // ─── State ───────────────────────────────────────────────
  bool _loading = false;
  final _irsaliye = IrsaliyeDto();
  final List<IrsaliyehareketDto> _kalemler = [];
  String? _yeniIrsaliyeId;

  // Bu oturumda offline (kuyruk) moduna en az bir kez düşüldüyse true olur.
  // Bir kez offline'a düşülünce, bağlantı geri gelse bile bu belge için
  // offline akış sürdürülür — yarısı online yarısı kuyrukta kalmasın diye.
  bool _offlineDraft = false;

  // Cari
  CariDtoLite? _seciliCari;
  List<CariDtoLite> _cariler = [];
  List<CariadresDto> _cariAdresler = [];

  // Lookup
  List<ProjeDto> _projeler = [];
  List<PlasiyerDto> _plasiyerler = [];
  List<ReferansDto> _referanslar = [];
  List<StokListDto> _stoklar = [];
  List<DepoDto> _depolar = [];
  List<int> _yilListesi = [];
  List<DovizDto> _dovizler = [];
  List<BelgeSeriDto> _belgeSeriListesi = [];

  // Taşıyıcı
  List<AracDto> _araclar = [];
  String? _lojistikCariAd;
  List<SurucuDto> _suruculer = [];

  bool _cariAdresManuelSecildi = false;
  bool _cariTR = true;
  final _tKantarCtrl = TextEditingController();
  final _teslimKantarCtrl = TextEditingController();
  final _kapMiktarCtrl = TextEditingController();

  String? _seciliSeri;
  int _seciliYil = DateTime.now().year;

  // Controllers
  late TextEditingController _belgeNoCtrl;
  late TextEditingController _tarihCtrl;
  late TextEditingController _fiiliTarihCtrl;
  late TextEditingController _teslimTarihCtrl;
  late TextEditingController _aciklamaCtrl;
  late TextEditingController _vadeTarihCtrl;
  late TextEditingController _tahsilatTarihCtrl;
  late TextEditingController _dovizTarihCtrl;
  late TextEditingController _kurCtrl;

  // ─── INIT ────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    _yilListesi = List.generate(5, (i) => DateTime.now().year - i);
    _seciliYil = DateTime.now().year;

    final now = DateTime.now();
    _irsaliye
      ..tarih = now
      ..fiilitarih = now
      ..teslimtarihi = now
      ..vadetarihi = now
      ..vadegunu = 0
      ..tahsilattarihi = now
      ..belgeyil = now.year
      ..kdvdahil = false
      ..belgeturu = BelgeTuruCouples.satisIrsaliyesi
      ..ebelgetip = 0;

    _belgeNoCtrl = TextEditingController();
    _tarihCtrl = TextEditingController(text: _fmtDate(now));
    _fiiliTarihCtrl = TextEditingController(text: _fmtDate(now));
    _teslimTarihCtrl = TextEditingController(text: _fmtDate(now));
    _vadeTarihCtrl = TextEditingController(text: _fmtDate(now));
    _aciklamaCtrl = TextEditingController();
    _vadeTarihCtrl = TextEditingController();
    _tahsilatTarihCtrl = TextEditingController(text: _fmtDate(now));
    _dovizTarihCtrl = TextEditingController();
    _kurCtrl = TextEditingController(text: '1,0000');
    _irsaliye.dovizid = 1; // TL varsayılan
    _irsaliye.kur = 1.0;

    _loadLookups();
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_terminalBarkodHandler);
    _tabCtrl.dispose();
    _belgeNoCtrl.dispose();
    _tarihCtrl.dispose();
    _fiiliTarihCtrl.dispose();
    _teslimTarihCtrl.dispose();
    _aciklamaCtrl.dispose();
    _vadeTarihCtrl.dispose();
    _tahsilatTarihCtrl.dispose();
    _dovizTarihCtrl.dispose();
    _kurCtrl.dispose();
    _tKantarCtrl.dispose();
    _teslimKantarCtrl.dispose();
    _kapMiktarCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime? d) => d == null
      ? ''
      : "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

  // ─── LOOKUP ──────────────────────────────────────────────
  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final subeId = prefs.getInt("sube_id") ?? 0;

      List<BelgeSeriDto> seriList = [];
      List<ProjeDto> projeler = [];
      List<PlasiyerDto> plasiyerler = [];
      List<ReferansDto> referanslar = [];
      List<StokListDto> stoklar = [];
      List<DepoDto> depolar = [];

      try {
        seriList = await BelgeSeriService()
            .getAll(token, BelgeTuruCouples.satisIrsaliyesi);
      } catch (_) {}
      try {
        projeler = (await ProjeService().getProjeList(token))
            .where((p) => p.tur == 3)
            .toList()
          ..sort((a, b) => (a.kod ?? '').compareTo(b.kod ?? ''));
      } catch (_) {}
      try {
        plasiyerler = await PlasiyerService().getPlasiyerler(token);
      } catch (_) {}
      try {
        referanslar = await ReferansService().getAll(token);
      } catch (_) {}
      try {
        stoklar = await StokService().getStokList(token);
      } catch (_) {}
      try {
        depolar = await DepoService().getAllBySubeId(token, subeId);
      } catch (_) {}
      List<DovizDto> dovizler = [];
      List<AracDto> araclar = [];
      List<SurucuDto> suruculer = [];
      try {
        dovizler = await DovizService().getDovizler(token);
      } catch (_) {}
      try {
        araclar = await AracService().getAll(token);
      } catch (_) {}
      try {
        suruculer = await SurucuService().getAll(token);
      } catch (_) {}

      final varsayilanProjeId = await VarsayilanProjeHelper.pickFrom(projeler);
      if (!mounted) return;
      setState(() {
        _projeler = projeler;
        _plasiyerler = plasiyerler;
        _referanslar = referanslar;
        _stoklar = stoklar;
        _depolar = depolar;
        _dovizler = dovizler;
        _araclar = araclar;
        _suruculer = suruculer;
        _belgeSeriListesi = seriList;
        _loading = false;

        if (projeler.isNotEmpty && _irsaliye.projeid == null)
          _irsaliye.projeid = varsayilanProjeId;
        if (plasiyerler.isNotEmpty && _irsaliye.plasiyerid == null)
          _irsaliye.plasiyerid = plasiyerler.first.Id;
        if (seriList.isNotEmpty && _seciliSeri == null) {
          _seciliSeri = seriList.first.seri;
          _irsaliye.belgeseri = _seciliSeri;
        }
      });

      if (_isEditMode) {
        await _loadMevcut(token);
      } else {
        if (_seciliSeri != null) await _fetchYeniNo(token);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        UiFeedback.showError(context, e.toString());
      }
    }
  }

  Future<void> _loadMevcut(String token) async {
    try {
      final mevcut = await _svc.getById(token, widget.irsaliyeId!);
      if (!mounted) return;
      setState(() {
        _yeniIrsaliyeId = mevcut.id;
        _irsaliye.cariid = mevcut.cariid;
        _irsaliye.cariadresid = mevcut.cariadresid;
        _irsaliye.projeid = mevcut.projeid;
        _irsaliye.plasiyerid = mevcut.plasiyerid;
        _irsaliye.referansid = mevcut.referansid;
        _irsaliye.belgeseri = mevcut.belgeseri;
        _irsaliye.belgeyil = mevcut.belgeyil;
        _irsaliye.belgeno = mevcut.belgeno;
        _irsaliye.tarih = mevcut.tarih;
        _irsaliye.fiilitarih = mevcut.fiilitarih;
        _irsaliye.teslimtarihi = mevcut.teslimtarihi;
        _irsaliye.aciklama = mevcut.aciklama;
        _irsaliye.kdvdahil = mevcut.kdvdahil;
        _irsaliye.belgetipi = mevcut.belgetipi;
        _irsaliye.ithalatihracattipi = mevcut.ithalatihracattipi;
        _irsaliye.odemesekli = mevcut.odemesekli;
        _irsaliye.vadegunu = mevcut.vadegunu;
        _irsaliye.vadetarihi = mevcut.vadetarihi;
        _irsaliye.tahsilattarihi = mevcut.tahsilattarihi;
        _irsaliye.dovizid = mevcut.dovizid ?? 1;
        _irsaliye.doviztarih = mevcut.doviztarih;
        _irsaliye.kur = mevcut.kur;
        _irsaliye.extraNotes = mevcut.extraNotes;
        _irsaliye.geneliskontooran = mevcut.geneliskontooran;
        _irsaliye.geneliskontotutar = mevcut.geneliskontotutar;
        _irsaliye.dovizgeneliskontotutar = mevcut.dovizgeneliskontotutar;
        _irsaliye.aracid = mevcut.aracid;
        _irsaliye.surucuid = mevcut.surucuid;
        _irsaliye.lojistikcariid = mevcut.lojistikcariid;
        _irsaliye.tedarikcikantarmiktar = mevcut.tedarikcikantarmiktar;
        _irsaliye.teslimalinankantarmiktar = mevcut.teslimalinankantarmiktar;
        _irsaliye.kapadet = mevcut.kapadet;
        _irsaliye.tasimafazi = mevcut.tasimafazi;
        if (mevcut.lojistikcariid != null)
          _loadLojistikCari(mevcut.lojistikcariid!);
        _tKantarCtrl.text = mevcut.tedarikcikantarmiktar != null
            ? NumberFormatHelper.format(mevcut.tedarikcikantarmiktar!,
                decimal: 4)
            : '';
        _teslimKantarCtrl.text = mevcut.teslimalinankantarmiktar != null
            ? NumberFormatHelper.format(mevcut.teslimalinankantarmiktar!,
                decimal: 4)
            : '';
        _kapMiktarCtrl.text = mevcut.kapadet != null
            ? NumberFormatHelper.format(mevcut.kapadet!, decimal: 4)
            : '';
        _seciliSeri = mevcut.belgeseri;
        _seciliYil = mevcut.belgeyil ?? DateTime.now().year;
        _belgeNoCtrl.text = mevcut.belgeno ?? '';
        _vadeTarihCtrl.text = _fmtDate(mevcut.vadetarihi);
        _tahsilatTarihCtrl.text = _fmtDate(mevcut.tahsilattarihi);
        _dovizTarihCtrl.text = _fmtDate(mevcut.doviztarih);
        _kurCtrl.text =
            (mevcut.kur ?? 1.0).toStringAsFixed(4).replaceAll('.', ',');
        _tarihCtrl.text = _fmtDate(mevcut.tarih);
        _fiiliTarihCtrl.text = _fmtDate(mevcut.fiilitarih);
        _teslimTarihCtrl.text = _fmtDate(mevcut.teslimtarihi);
        _aciklamaCtrl.text = mevcut.aciklama ?? '';
        _kalemler
          ..clear()
          ..addAll(mevcut.irsaliyehareket);
        if (mevcut.cari != null) {
          _seciliCari = CariDtoLite(
              Id: mevcut.cariid, Ad: mevcut.cari?.Ad, Kod: mevcut.cari?.Kod);
        }
      });
      _recalcToplam();
    } catch (e, s) {
      debugPrint(">>> loadMevcut HATA: $e\n$s");
      if (mounted) UiFeedback.showError(context, "İrsaliye yüklenemedi: $e");
    }
  }

  Future<void> _fetchYeniNo(String token) async {
    if (_seciliSeri == null) return;
    try {
      final no = await _svc.getNewIrsaliyeNo(token, _seciliSeri!, _seciliYil);
      if (mounted)
        setState(() {
          _irsaliye.belgeno = no;
          _belgeNoCtrl.text = no;
        });
    } catch (_) {}
  }

  // ─── VADE ────────────────────────────────────────────────
  void _recalcVadeTarihi() {
    final tarih = _irsaliye.tarih ?? DateTime.now();
    final vg = _irsaliye.vadegunu ?? 0;
    final vt = tarih.add(Duration(days: vg));
    setState(() {
      _irsaliye.vadetarihi = vt;
      _vadeTarihCtrl.text = _fmtDate(vt);
      // Teslim tarihi vade tarihi ile aynı
      _irsaliye.teslimtarihi = vt;
      _teslimTarihCtrl.text = _fmtDate(vt);
    });
  }

  // ─── HESAP ───────────────────────────────────────────────
  // TRY (TL) mi? Kur / Döviz Tarihi yalnızca dövizli (TL dışı) kayıtta gösterilir.
  bool get _tryMi {
    final id = _irsaliye.dovizid;
    if (id == null || id == 1) return true;
    final d = _dovizler.where((x) => x.Id == id).firstOrNull;
    final b = (d?.Birim ?? '').trim().toUpperCase();
    return b == 'TL' || b == 'TRY' || b == '₺';
  }

  Future<void> _kurGetir() async {
    final dovizId = _irsaliye.dovizid;
    if (dovizId == null || dovizId == 1) {
      setState(() {
        _irsaliye.kur = 1.0;
        _kurCtrl.text = '1,0000';
      });
      return;
    }

    final tarih = _irsaliye.doviztarih ?? _irsaliye.tarih ?? DateTime.now();
    setState(() {
      _irsaliye.doviztarih = tarih;
      _dovizTarihCtrl.text = _fmtDate(tarih);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final kur = await KurService().getByDovizIdAndDate(token, dovizId, tarih);
      final yeniKur = kur?.Dovizsatis ??
          kur?.Dovizalis ??
          kur?.Dovizefektifsatis ??
          kur?.Dovizefektifalis;
      if (yeniKur == null || yeniKur <= 0) {
        if (mounted) UiFeedback.showWarning(context, "Kur bulunamadı.");
        return;
      }
      if (!mounted) return;
      setState(() {
        _irsaliye.kur = yeniKur;
        _kurCtrl.text = yeniKur.toStringAsFixed(4).replaceAll('.', ',');
      });
    } catch (e) {
      if (mounted) UiFeedback.showError(context, "Kur alınamadı: $e");
    }
  }

  void _recalcToplam() {
    setState(() => IrsaliyeHesapHelper.recalculate(_irsaliye, _kalemler));
  }

  Future<void> _genelIskontoSec() async {
    final rate = IrsaliyeHesapHelper.rate(_irsaliye);
    final result = await showFaturaGenelIskontoSheet(context,
        oran: _irsaliye.geneliskontooran,
        tutar: (_irsaliye.geneliskontotutar ?? 0) / rate,
        araToplam:
            _kalemler.fold<double>(0, (s, k) => s + (k.bruttutar ?? 0)) / rate,
        isDoviz: (_irsaliye.dovizid ?? 1) != 1,
        kur: rate,
        dovizId: _irsaliye.dovizid);
    if (result == null || !mounted) return;
    final base = _kalemler.fold<double>(0, (s, k) => s + (k.bruttutar ?? 0));
    _irsaliye.geneliskontooran = result.oran ??
        ((result.tutar ?? 0) > 0 && base > 0
            ? result.tutar! * rate / base * 100
            : null);
    _irsaliye.geneliskontotutar = (result.tutar ?? 0) * rate;
    _recalcToplam();
  }

  // ─── CARİ ────────────────────────────────────────────────
  Future<void> _loadCariAdresler(String token, int cariId) async {
    try {
      final list = await CariService().getCariAdres(token, cariId);
      if (mounted)
        setState(() {
          _cariAdresler = list;
        });
    } catch (_) {}
  }

  Future<void> _loadCariVadegunu(String token, int cariId) async {
    try {
      final cariFull = await CariService().getCariFullById(token, cariId);
      if (!mounted) return;
      final trCari = cariFull.Ulkeid == null || cariFull.Ulkeid == 1;
      setState(() {
        _cariTR = trCari;
        if (trCari) {
          _irsaliye.belgetipi = 1;
        } else {
          _irsaliye.belgetipi = 6; // İhracat
          for (final k in _kalemler) {
            k.tevkifatorani = null;
          }
        }
        if (cariFull.Vadegunu != null) {
          _irsaliye.vadegunu = cariFull.Vadegunu;
          _recalcVadeTarihi();
        }
      });
    } catch (_) {}
  }

  Future<void> _cariSec() async {
    if (_cariler.isEmpty) {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      try {
        _cariler = await CariService().getCariler(token);
      } catch (_) {}
    }
    final secilen = await showErpSelector<CariDtoLite>(
      context: context,
      title: "Cari Seç",
      hintText: "Cari kodu veya adı...",
      items: _cariler,
      itemText: (c) => "${c.Kod ?? ''} - ${c.Ad ?? ''}",
    );
    if (secilen == null || !mounted) return;
    setState(() {
      _seciliCari = secilen;
      _irsaliye.cariid = secilen.Id;
      _cariAdresManuelSecildi = false;
      _irsaliye.cariadresid = null;
      _cariAdresler = [];
    });
    // Cari kartında plasiyer tanımlıysa belgenin plasiyerini ona çevir (bloklamadan)
    CariPlasiyerHelper.getPlasiyerIdOrFirst(secilen.Id, _plasiyerler)
        .then((pid) async {
      final projeId = await VarsayilanProjeHelper.pickFrom(_projeler);
      if (!mounted) return;
      setState(() {
        if (pid != null) _irsaliye.plasiyerid = pid;
        if (projeId != null) _irsaliye.projeid = projeId;
      });
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    if (secilen.Id != null) {
      await _loadCariAdresler(token, secilen.Id!);
      await _loadCariVadegunu(token, secilen.Id!);
    }
  }

  Future<void> _loadLojistikCari(int cariId) async {
    // Önce mevcut listeden bul
    final mevcut = _cariler.where((c) => c.Id == cariId).firstOrNull;
    if (mevcut != null) {
      setState(() =>
          _lojistikCariAd = "${mevcut.Kod ?? ''} - ${mevcut.Ad ?? ''}".trim());
      return;
    }
    // Listede yoksa tüm carileri yükle
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      if (_cariler.isEmpty) {
        _cariler = await CariService().getCariler(token);
      }
      final c = _cariler.where((c) => c.Id == cariId).firstOrNull;
      if (mounted)
        setState(() => _lojistikCariAd = c != null
            ? "${c.Kod ?? ''} - ${c.Ad ?? ''}".trim()
            : "Cari #$cariId");
    } catch (_) {
      if (mounted) setState(() => _lojistikCariAd = "Cari #$cariId");
    }
  }

  // ─── KALEM ───────────────────────────────────────────────
  // ─── TERMİNAL BARKOD DİNLEYİCİ ────────────────────────
  final StringBuffer _barkodBuffer = StringBuffer();
  DateTime? _sonTus;
  static const _barkodTimeout = Duration(milliseconds: 80);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    HardwareKeyboard.instance.addHandler(_terminalBarkodHandler);
  }

  bool _terminalBarkodHandler(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final now = DateTime.now();
    // Timeout geçtiyse buffer sıfırla
    if (_sonTus != null && now.difference(_sonTus!) > _barkodTimeout) {
      _barkodBuffer.clear();
    }
    _sonTus = now;
    final karakter = event.character;
    if (karakter != null && karakter.isNotEmpty) {
      _barkodBuffer.write(karakter);
    } else if (event.logicalKey == LogicalKeyboardKey.enter) {
      final barkod = _barkodBuffer.toString().trim();
      _barkodBuffer.clear();
      _sonTus = null;
      if (barkod.isNotEmpty) {
        _barkodIleStokveBulKalemAc(barkod);
      }
    }
    return false;
  }

  Future<void> _kameraIleBarkodOku() async {
    final barkod = await Navigator.push<String>(
        context,
        PermissionMaterialPageRoute(
            builder: (_) => const BarcodeScannerSheet()));
    if (barkod == null || barkod.isEmpty || !mounted) return;
    _barkodIleStokveBulKalemAc(barkod);
  }

  Future<void> _barkodIleStokveBulKalemAc(String barkod) async {
    // Barkoda göre stok bul
    StokListDto? bulunan;
    for (final s in _stoklar) {
      final barkodlar = s.getBarkodListesi();
      if (barkodlar.any((b) => b.toLowerCase() == barkod.toLowerCase())) {
        bulunan = s;
        break;
      }
      // Stok koduna göre de ara
      if ((s.Kod ?? '').toLowerCase() == barkod.toLowerCase()) {
        bulunan = s;
        break;
      }
    }
    if (bulunan == null) {
      if (mounted)
        UiFeedback.showWarning(context, 'Barkod bulunamadı: $barkod');
      return;
    }
    if (!mounted) return;
    // Kalem formunu stok seçili aç
    final oncekiKalem = IrsaliyehareketDto()
      ..stokid = bulunan.Id
      ..stok = StokDto(Id: bulunan.Id, Kod: bulunan.Kod, Ad: bulunan.Ad);
    final k = await showIrsaliyeKalemForm(context,
        kalem: oncekiKalem,
        stoklar: _stoklar,
        projeler: _projeler,
        depolar: _depolar,
        kdvDahil: _irsaliye.kdvdahil ?? false);
    if (k == null || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final subeId = prefs.getInt("sube_id") ?? 0;

    // Offline mod kontrolü
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (_offlineDraft || manuelOffline || internetYok) {
      if (_seciliCari == null) {
        UiFeedback.showWarning(context, "Lütfen önce cari seçiniz!");
        return;
      }
      _offlineDraft = true;
      if (!mounted) return;
      setState(() {
        _kalemler.add(k);
        _recalcToplam();
        _tabCtrl.animateTo(1);
      });
      return;
    }

    if (_yeniIrsaliyeId == null) {
      if (_seciliCari == null) {
        UiFeedback.showWarning(context, "Lütfen önce cari seçiniz!");
        return;
      }
      try {
        _yeniIrsaliyeId = await _svc.saveSingle(token, _irsaliyeToDto(subeId));
      } catch (e) {
        if (mounted)
          UiFeedback.showError(context, "İrsaliye kaydedilemedi: $e");
        return;
      }
    }
    try {
      k.irsaliyeid = _yeniIrsaliyeId;
      final hId = await _svc.saveHareket(
          token, _hareketToInsertJson(k, _yeniIrsaliyeId!));
      if (hId != null) k.id = hId;
      if (mounted)
        setState(() {
          _kalemler.add(k);
          _recalcToplam();
          _tabCtrl.animateTo(1);
        });
    } catch (e) {
      if (mounted) UiFeedback.showError(context, "Kalem kaydedilemedi: $e");
    }
  }

  // Future<void> _kameraBarkodOku() async {
  //   final barcode = await Navigator.push<String>(
  //     context,
  //     PermissionMaterialPageRoute(builder: (_) => BarcodeScannerSheet()),
  //   );
  //   if (barcode != null && mounted) {
  //     _barkodIleStokveBulKalemAc(barcode);
  //   }
  // }

  Future<void> _addKalem() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final subeId = prefs.getInt("sube_id") ?? 0;

    final k = await showIrsaliyeKalemForm(context,
        stoklar: _stoklar,
        projeler: _projeler,
        depolar: _depolar,
        kdvDahil: _irsaliye.kdvdahil ?? false);
    if (k == null || !mounted) return;

    // Offline mod kontrolü
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (_offlineDraft || manuelOffline || internetYok) {
      if (_seciliCari == null) {
        UiFeedback.showWarning(context, "Lütfen önce cari seçiniz!");
        return;
      }
      _offlineDraft = true;
      if (!mounted) return;
      setState(() {
        _kalemler.add(k);
        _recalcToplam();
        _tabCtrl.animateTo(1);
      });
      return;
    }

    // İlk kalemlerde irsaliye header'ı kaydet
    if (_yeniIrsaliyeId == null) {
      if (_seciliCari == null) {
        UiFeedback.showWarning(context, "Lütfen önce cari seçiniz!");
        return;
      }
      try {
        _yeniIrsaliyeId = await _svc.saveSingle(token, _irsaliyeToDto(subeId));
      } catch (e) {
        if (mounted)
          UiFeedback.showError(context, "İrsaliye kaydedilemedi: $e");
        return;
      }
    }

    try {
      k.irsaliyeid = _yeniIrsaliyeId;
      final hId = await _svc.saveHareket(
          token, _hareketToInsertJson(k, _yeniIrsaliyeId!));
      if (hId != null) k.id = hId;
      if (mounted)
        setState(() {
          _kalemler.add(k);
          _recalcToplam();
          _tabCtrl.animateTo(1);
        });
    } catch (e) {
      if (mounted) UiFeedback.showError(context, "Kalem kaydedilemedi: $e");
    }
  }

  Future<void> _editKalem(int i) async {
    final res = await showIrsaliyeKalemForm(context,
        kalem: _kalemler[i],
        stoklar: _stoklar,
        projeler: _projeler,
        depolar: _depolar,
        kdvDahil: _irsaliye.kdvdahil ?? false);
    if (res == null || !mounted) return;
    setState(() {
      _kalemler[i] = res;
      _recalcToplam();
    });
    if (res.id != null && _yeniIrsaliyeId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token_final") ?? "";
        await _svc.updateHareket(
            token, _hareketToUpdateJson(res, _yeniIrsaliyeId!));
        if (mounted) UiFeedback.showUpdated(context, "Kalem güncellendi");
      } catch (e) {
        if (mounted) UiFeedback.showError(context, e.toString());
      }
    }
  }

  Future<void> _deleteKalem(int i) async {
    final k = _kalemler[i];
    final confirm = await UiFeedback.confirm(context,
        title: "Kalemi Sil",
        message: "${k.stok?.Ad ?? 'Kalem'} silinecek. Emin misiniz?",
        destructive: true);
    if (confirm != true || !mounted) return;
    if (k.id != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token_final") ?? "";
        await _svc.deleteHareket(token, k.id!);
      } catch (e) {
        if (mounted) UiFeedback.showError(context, e.toString());
        return;
      }
    }
    if (mounted) {
      setState(() {
        _kalemler.removeAt(i);
        _recalcToplam();
      });
      UiFeedback.showDeleted(context, "Kalem silindi");
    }
  }

  Future<void> _addHizliBarkodKalemler() async {
    final result = await showQuickBarcodeScanSheet(context, stoklar: _stoklar);
    if (result == null || result.lines.isEmpty || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final subeId = prefs.getInt("sube_id") ?? 0;
    final varsayilanDepoId = await VarsayilanDepoHelper.getId(token);
    final varsayilanProjeId =
        _irsaliye.projeid ?? await VarsayilanProjeHelper.getId(token);

    // Offline mod kontrolü
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    final isOffline = _offlineDraft || manuelOffline || internetYok;
    if (isOffline) _offlineDraft = true;

    if (isOffline) {
      if (_seciliCari == null) {
        UiFeedback.showWarning(context, "Lütfen önce cari seçiniz!");
        return;
      }
    } else if (_yeniIrsaliyeId == null) {
      if (_seciliCari == null) {
        UiFeedback.showWarning(context, "Lütfen önce cari seçiniz!");
        return;
      }
      try {
        _yeniIrsaliyeId = await _svc.saveSingle(token, _irsaliyeToDto(subeId));
      } catch (e) {
        if (mounted)
          UiFeedback.showError(context, "İrsaliye kaydedilemedi: $e");
        return;
      }
    }

    int ok = 0, fail = 0;
    String? ilkHata;
    for (final line in result.lines) {
      if (line.stok == null) continue;
      final stokId = line.stok!.Id;
      if (stokId == null) continue;
      try {
        final sf = await StokService().getStokById(token, stokId);
        final miktar = line.quantity;

        // KDV oranı
        final kdvRaw = sf.Kdvsatis ?? 0;
        final kdvOrani =
            kdvRaw > 0 ? (kdvRaw <= 1.0 ? kdvRaw * 100 : kdvRaw) : 20.0;

        // Satış fiyatı (dövize göre eşleştir, yoksa ilki)
        double fiyat = 0;
        if (sf.Stokfiyat.isNotEmpty) {
          final eslesen =
              sf.Stokfiyat.where((f) => f.Dovizid == _irsaliye.dovizid)
                  .firstOrNull;
          final fd = eslesen ?? sf.Stokfiyat.first;
          fiyat = fd.Satisfiyat ?? 0;
        }

        // Ölçü birimi
        int? olcubrid;
        final birimler = sf.Stokolcubr.where((s) => s.Olcubr != null)
            .map((s) => s.Olcubr!)
            .toList();
        if (sf.Temelolcubr != null) birimler.insert(0, sf.Temelolcubr!);
        final gorulen = <int>{};
        final tekBirim =
            birimler.where((o) => o.Id != null && gorulen.add(o.Id!)).toList();
        if (tekBirim.isNotEmpty) olcubrid = tekBirim.first.Id;

        final k = IrsaliyehareketDto()
          ..irsaliyeid = _yeniIrsaliyeId
          ..stokid = line.stok!.Id
          ..stok =
              StokDto(Id: line.stok!.Id, Kod: line.stok!.Kod, Ad: line.stok!.Ad)
          ..miktar = miktar
          ..fiyat = fiyat
          ..kdvorani = kdvOrani
          ..olcubrid = olcubrid
          ..depoid = varsayilanDepoId
          ..projeid = varsayilanProjeId;

        // Tevkifat (sadece TR cari)
        if (_cariTR && (sf.Tevkifatorani ?? 0) > 0) {
          k.tevkifatorani = sf.Tevkifatorani;
        }

        // Hesapla
        final sonuc = FaturaHesapHelper.hesaplaKalem(
          miktar: miktar,
          fiyat: fiyat,
          iskontoTutar: 0,
          kdvOrani: kdvOrani,
          tevkifatOrani: k.tevkifatorani ?? 0,
          kdvDahil: _irsaliye.kdvdahil ?? false,
        );
        k
          ..bruttutar = sonuc.bruttutar
          ..aratoplam = sonuc.bruttutar
          ..sonaratoplam = sonuc.bruttutar
          ..netaratoplam = sonuc.bruttutar
          ..kdvmatrahi = sonuc.bruttutar
          ..kdvtutar = sonuc.kdvtutar
          ..tevkifattutar = sonuc.tevkifattutar
          ..geneltoplam = sonuc.tutar
          ..songeneltoplam = sonuc.tutar
          ..tutar = sonuc.tutar;

        if (isOffline) {
          if (mounted) setState(() => _kalemler.add(k));
        } else {
          final hId = await _svc.saveHareket(
              token, _hareketToInsertJson(k, _yeniIrsaliyeId!));
          if (hId != null) k.id = hId;
          if (mounted) setState(() => _kalemler.add(k));
        }
        ok++;
      } catch (e) {
        fail++;
        ilkHata ??= e.toString();
      }
    }
    if (mounted) {
      _recalcToplam();
      _tabCtrl.animateTo(1);
      if (fail > 0) {
        UiFeedback.showError(
            context, "$ok kalem eklendi, $fail kalem kaydedilemedi: $ilkHata");
      }
    }
  }

  Future<void> _addDirekBarkodKalem() async {
    final ctrl = TextEditingController();
    final barkod = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Barkod Gir",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: "Barkod veya stok kodu...",
            border: OutlineInputBorder(),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          ErpDialogAction(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text("Ara"),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (barkod == null || barkod.isEmpty || !mounted) return;
    _barkodIleStokveBulKalemAc(barkod);
  }

  // ─── JSON ────────────────────────────────────────────────
  Map<String, dynamic> _irsaliyeToDto(int subeId) {
    IrsaliyeHesapHelper.recalculate(_irsaliye, _kalemler);
    return <String, dynamic>{
      "subeid": subeId,
      "cariid": _irsaliye.cariid,
      "dovizid": _irsaliye.dovizid ?? 1, // TL varsayılan
      "cariadresid": _irsaliye.cariadresid,
      "projeid": _irsaliye.projeid,
      "plasiyerid": _irsaliye.plasiyerid,
      "referansid": _irsaliye.referansid,
      "belgeseri": _irsaliye.belgeseri,
      "belgeyil": _seciliYil,
      "belgeno": _irsaliye.belgeno,
      "belgeserino":
          "${_irsaliye.belgeseri ?? ''}${_seciliYil}${_irsaliye.belgeno ?? ''}",
      "gibbelgeno":
          "${_irsaliye.belgeseri ?? ''}${_seciliYil}${_irsaliye.belgeno ?? ''}",
      "tarih": _irsaliye.tarih?.toIso8601String(),
      "fiilitarih": _irsaliye.fiilitarih?.toIso8601String(),
      "teslimtarihi": _irsaliye.teslimtarihi?.toIso8601String(),
      "kdvdahil": _irsaliye.kdvdahil,
      "belgeturu": _irsaliye.belgeturu,
      "belgetipi": _irsaliye.belgetipi,
      "ithalatihracattipi": _irsaliye.ithalatihracattipi,
      "odemesekli": _irsaliye.odemesekli,
      "vadegunu": _irsaliye.vadegunu,
      "vadetarihi": _irsaliye.vadetarihi?.toIso8601String(),
      "tahsilattarihi": _irsaliye.tahsilattarihi?.toIso8601String(),
      "doviztarih": _irsaliye.doviztarih?.toIso8601String(),
      "kur": _irsaliye.kur ?? 1.0,
      "ebelgetip": 0,
      "kayityeri": _irsaliye.kayityeri,
      "aciklama": _irsaliye.aciklama,
      ..._irsaliye.extraNotesJson,
      "geneliskontooran": _irsaliye.geneliskontooran,
      "geneliskontotutar": _irsaliye.geneliskontotutar,
      "dovizgeneliskontotutar": _irsaliye.dovizgeneliskontotutar,
      // Tutarlar
      "bruttutar":
          _kalemler.fold(0.0, (s, k) => s + ((k.miktar ?? 0) * (k.fiyat ?? 0))),
      "malfazlasitutar":
          _kalemler.fold(0.0, (s, k) => s + (k.malfazlasitutar ?? 0)),
      "iskontotutar": _kalemler.fold(0.0, (s, k) => s + (k.iskontotutar ?? 0)),
      "aratoplam": _irsaliye.aratoplam ?? 0,
      "sonaratoplam": _irsaliye.aratoplam ?? 0,
      "netaratoplam": _irsaliye.aratoplam ?? 0,
      "kdvtoplam": _irsaliye.kdvtoplam ?? 0,
      "geneltoplam": _irsaliye.geneltoplam ?? 0,
      "tevkifattutar":
          _kalemler.fold(0.0, (s, k) => s + (k.tevkifattutar ?? 0)),
      "songeneltoplam": _irsaliye.geneltoplam ?? 0,
      "aracid": _irsaliye.aracid,
      "surucuid": _irsaliye.surucuid,
      "lojistikcariid": _irsaliye.lojistikcariid,
      "tedarikcikantarmiktar": _irsaliye.tedarikcikantarmiktar,
      "teslimalinankantarmiktar": _irsaliye.teslimalinankantarmiktar,
      "kapadet": _irsaliye.kapadet,
      "tasimafazi": _irsaliye.tasimafazi,
    };
  }

  Map<String, dynamic> _hareketToInsertJson(
          IrsaliyehareketDto k, String irsaliyeId) =>
      k.toInsertJson(irsaliyeId);

  Map<String, dynamic> _hareketToUpdateJson(
          IrsaliyehareketDto k, String irsaliyeId) =>
      <String, dynamic>{
        "id": k.id,
        ..._hareketToInsertJson(k, irsaliyeId),
      };

  // ─── KAYDET ──────────────────────────────────────────────
  Future<void> _showKaydetDialog() async {
    if (_seciliCari == null) {
      UiFeedback.showWarning(context, "Lütfen cari seçiniz!");
      return;
    }
    if (_kalemler.isEmpty) {
      UiFeedback.showWarning(context, "En az bir kalem eklemelisiniz!");
      return;
    }

    // Offline taslak: header ve kalemler henüz sunucuya hiç gönderilmedi —
    // DAT'taki gibi tek seferde tüm belgeyi kuyruğa al, tamamla/taslak ayrımı yok.
    if (_offlineDraft) {
      await _kaydetOfflineFull();
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: _primary.withValues(alpha: 0.08),
                      shape: BoxShape.circle),
                  child: Icon(Icons.save_outlined, size: 36, color: _primary)),
              const SizedBox(height: 16),
              const Text("İrsaliyeyi Kaydet",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Nasıl kaydetmek istersiniz?",
                  style:
                      TextStyle(color: _scheme.onSurfaceVariant, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: PermissionAction(
                      modules: [501],
                      access: Access.create,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _scheme.primary,
                            foregroundColor:
                                Theme.of(context).colorScheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text("Belgeyi Tamamla",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _kaydetTamamla();
                        },
                      ))),
              const SizedBox(height: 10),
              SizedBox(
                  width: double.infinity,
                  child: PermissionAction(
                      modules: [501],
                      access: Access.write,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                            foregroundColor: _scheme.onSurfaceVariant,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            side: BorderSide(color: _scheme.outlineVariant)),
                        icon: const Icon(Icons.save_outlined),
                        label: const Text("Taslak Kaydet",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _kaydet();
                        },
                      ))),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("İptal",
                      style: TextStyle(color: _scheme.onSurfaceVariant))),
            ])),
      ),
    );
  }

  Future<void> _kaydetTamamla() async {
    await _kaydet(pop: false);
    if (!mounted) return;
    final id = _yeniIrsaliyeId;
    if (id == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await _svc.belgeDurumGuncelle(token, id, 1);
      if (!mounted) return;
      await _tamamlandiSonrasiSor(id);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) UiFeedback.showError(context, "Tamamlama hatası: $e");
    }
  }

  /// İrsaliye tamamlandıktan sonra yazdırmak isteyip istemediğini sorar —
  /// mevcut yazıcı ayarları (Ayarlar > Yazıcı Ayarları) kullanılır.
  Future<void> _tamamlandiSonrasiSor(String irsaliyeId) async {
    final yazdir = await UiFeedback.confirm(
      context,
      title: "İrsaliye Tamamlandı",
      message: "İrsaliye yazdırılsın mı?",
      confirmLabel: "Yazdır",
      cancelLabel: "Vazgeç",
    );
    if (yazdir != true || !mounted) return;
    await _yazdirIrsaliye(irsaliyeId);
  }

  Future<void> _yazdirIrsaliye(String irsaliyeId) async {
    try {
      final svc = BluetoothPrintService.instance;
      var connected = await svc.isConnected;
      if (!connected) {
        final mac = await svc.getSavedMac();
        if (mac == null) {
          if (mounted) {
            UiFeedback.showError(context,
                "Kayıtlı yazıcı yok. Ayarlar > Yazıcı Ayarları'ndan bir yazıcı seçin.");
          }
          return;
        }
        connected = await svc.connect(mac);
        if (!connected) {
          if (mounted) UiFeedback.showError(context, "Yazıcıya bağlanılamadı.");
          return;
        }
      }

      final plasiyerAd = _plasiyerler
          .where((p) => p.Id == _irsaliye.plasiyerid)
          .firstOrNull
          ?.Adsoyad;

      final fisKalemler = _kalemler
          .map((k) => IrsaliyeFisKalem(
                ad: k.stok?.Ad ?? '-',
                miktar: k.miktar ?? 0,
                olcubr: k.olcubr?.Ad ?? '',
              ))
          .toList();

      final satirGen = await YaziciSablonService.instance.getSatirGenisligi();
      final prefs = await SharedPreferences.getInstance();
      final kullaniciAdi = prefs.getString('kullanici_adi');

      final bytes = svc.buildIrsaliyeFisi(
        belgeNo: _irsaliye.belgeserino ?? _irsaliye.belgeno ?? '-',
        tarih: _irsaliye.tarih ?? DateTime.now(),
        cariAd: _seciliCari?.Ad ?? '-',
        plasiyerAd: plasiyerAd,
        kalemler: fisKalemler,
        satirGenisligi: satirGen,
        kullaniciAdi: kullaniciAdi,
      );
      final ok = await svc.printBytes(bytes);
      if (!mounted) return;
      if (ok) {
        UiFeedback.showSuccess(context, "İrsaliye yazıcıya gönderildi.");
      } else {
        UiFeedback.showError(context, "Yazdırma başarısız.");
      }
    } catch (e) {
      if (mounted) UiFeedback.showError(context, e.toString());
    }
  }

  // Offline taslakta hiçbir şey sunucuya kaydedilmedi — header + tüm kalemleri
  // tek seferde generic 'header_hareket_full' kuyruğuna ekle (DAT ile aynı mantık).
  Future<void> _kaydetOfflineFull() async {
    final prefs = await SharedPreferences.getInstance();
    final subeId = prefs.getInt("sube_id") ?? 0;
    final internetYok = !OfflineService.instance.isOnline.value;
    final payload = {
      'headerEndpoint': '/Irsaliye/SaveSingle',
      'hareketEndpoint': '/Irsaliyehareket/SaveSingle',
      'headerIdField': 'irsaliyeid',
      'header': _irsaliyeToDto(subeId),
      'kalemler': _kalemler.map((k) => _hareketToInsertJson(k, '')).toList(),
    };
    await OfflineService.instance.enqueue('header_hareket_full', payload);
    if (!mounted) return;
    final mesaj = internetYok
        ? "İnternet yok — belge kuyruğa alındı, bağlantı gelince gönderilecek"
        : "Belge kuyruğa eklendi — online olunca gönderilecek";
    UiFeedback.showSuccess(context, mesaj);
    Navigator.of(context).pop(true);
  }

  Future<void> _kaydet({bool pop = true}) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
                child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),
              child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text("Kaydediliyor...",
                        style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w500)),
                  ])),
            )));
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final subeId = prefs.getInt("sube_id") ?? 0;

      if (_yeniIrsaliyeId != null) {
        final dto = _irsaliyeToDto(subeId);
        dto["id"] = _yeniIrsaliyeId;
        await _svc.updateSingle(token, dto);
      } else {
        _yeniIrsaliyeId = await _svc.saveSingle(token, _irsaliyeToDto(subeId));
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showUpdated(context, "İrsaliye kaydedildi");
      if (pop) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showError(context, "Kayıt hatası: $e");
    }
  }

  // ─── BUILD ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: ErpPageAppBar(
        context: context,
        title: Text(_isEditMode ? "İrsaliye Düzenle" : "Yeni İrsaliye",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 20)),
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        toolbarHeight: 56,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, size: 20),
            tooltip: "İrsaliyeyi Yazdır",
            onPressed: () {
              final irsaliyeId = widget.irsaliyeId ?? _yeniIrsaliyeId;
              if (irsaliyeId == null) {
                UiFeedback.showWarning(context, "Önce irsaliyeyi kaydedin.");
                return;
              }
              if (_kalemler.isEmpty) {
                UiFeedback.showWarning(context, "Yazdırılacak kalem yok.");
                return;
              }
              _yazdirIrsaliye(irsaliyeId);
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              // TabBar
              Container(
                color: _scheme.surface,
                child: ErpAdaptiveTabs(
                    context: context,
                    tabBar: TabBar(
                      controller: _tabCtrl,
                      indicatorSize: TabBarIndicatorSize.tab,
                      dividerColor: Colors.transparent,
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                      indicator: BoxDecoration(
                          color: _accent.withValues(alpha: .08),
                          borderRadius: BorderRadius.circular(14)),
                      labelColor: _accent,
                      unselectedLabelColor: _scheme.onSurfaceVariant,
                      indicatorColor: _accent,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 12),
                      unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.normal, fontSize: 12),
                      tabs: [
                        Tab(
                            height: 48,
                            icon: Icon(Icons.info_outline,
                                size: 16,
                                color: _tabCtrl.index == 0
                                    ? _accent
                                    : _scheme.onSurfaceVariant),
                            text: "Üst Bilgiler",
                            iconMargin: const EdgeInsets.only(bottom: 2)),
                        Tab(
                            height: 48,
                            icon: Icon(Icons.list_alt,
                                size: 16,
                                color: _tabCtrl.index == 1
                                    ? _accent
                                    : _scheme.onSurfaceVariant),
                            text: "Kalemler",
                            iconMargin: const EdgeInsets.only(bottom: 2)),
                        Tab(
                            height: 48,
                            icon: Icon(Icons.calculate_outlined,
                                size: 16,
                                color: _tabCtrl.index == 2
                                    ? _accent
                                    : _scheme.onSurfaceVariant),
                            text: "Özet",
                            iconMargin: const EdgeInsets.only(bottom: 2)),
                        Tab(
                            height: 48,
                            icon: Icon(Icons.local_shipping_outlined,
                                size: 16,
                                color: _tabCtrl.index == 3
                                    ? _accent
                                    : _scheme.onSurfaceVariant),
                            text: "Taşıyıcı",
                            iconMargin: const EdgeInsets.only(bottom: 2)),
                      ],
                    )),
              ),
              Expanded(
                  child: TabBarView(controller: _tabCtrl, children: [
                _ustBilgilerTab(),
                _kalemlerTab(),
                _ozetTab(),
                _tasiyiciTab(),
              ])),

              _buildBottomBar(),
            ]),
    );
  }

  // ─── BOTTOM BAR ──────────────────────────────────────────
  Widget _buildBottomBar() => Container(
        color: _scheme.surface,
        child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ErpEntryActions(
                    onAdd: _addKalem,
                    onBarcode: _addHizliBarkodKalemler,
                    onCamera: _kameraIleBarkodOku,
                    onManual: _addDirekBarkodKalem),
                if (_tabCtrl.index != 0) ...[
                  const SizedBox(height: 12),
                  PermissionAction(
                      modules: [501],
                      access: Access.write,
                      child: FilledButton.icon(
                          onPressed: _showKaydetDialog,
                          style: FilledButton.styleFrom(
                              minimumSize: const Size(double.infinity, 48)),
                          icon: const Icon(Icons.save_outlined),
                          label: const Text('Kaydet'))),
                ],
              ]),
            )),
      );

  Widget _ustBilgilerTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionCard(children: [
          _buildCariSecici(),
          const SizedBox(height: 10),

          // 1. Seri / Yıl / Belge No
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                flex: 2,
                child: _buildDropdown<String>(
                    label: "Seri",
                    value: _seciliSeri,
                    items: _belgeSeriListesi
                        .map((e) => DropdownMenuItem(
                            value: e.seri,
                            child: Text(e.seri ?? '',
                                style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) async {
                      setState(() {
                        _seciliSeri = v;
                        _irsaliye.belgeseri = v;
                      });
                      final prefs = await SharedPreferences.getInstance();
                      await _fetchYeniNo(prefs.getString("token_final") ?? "");
                    })),
            const SizedBox(width: 8),
            Expanded(
                flex: 3,
                child: _buildDropdown<int>(
                    label: "Yıl",
                    value: _seciliYil,
                    items: _yilListesi
                        .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toString(),
                                style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() {
                          _seciliYil = v!;
                          _irsaliye.belgeyil = v;
                        }))),
            const SizedBox(width: 8),
            Expanded(
                flex: 3,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _inputLabel("Belge No"),
                      SizedBox(
                          height: 45,
                          child: TextFormField(
                            controller: _belgeNoCtrl,
                            inputFormatters: [
                              LengthLimitingTextInputFormatter(9)
                            ],
                            onChanged: (v) => _irsaliye.belgeno = v,
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: _scheme.outlineVariant))),
                          )),
                    ])),
          ]),
          const SizedBox(height: 10),

          // 2. Belge Tipi / İth-İhr Tipi
          Row(children: [
            Expanded(
                child: _buildDropdown<int>(
                    label: "Belge Tipi",
                    value: _irsaliye.belgetipi,
                    items: LookupHelper.faturaBelgeTipleri
                        .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.ad,
                                style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() {
                          _irsaliye.belgetipi = v;
                          if (!StokHareketCouples.isIhracatTipi(v))
                            _irsaliye.ithalatihracattipi = null;
                        }))),
            if (StokHareketCouples.isIhracatTipi(_irsaliye.belgetipi)) ...[
              const SizedBox(width: 12),
              Expanded(
                  child: _buildDropdown<int>(
                      label: "İth./İhr. Tipi",
                      value: _irsaliye.ithalatihracattipi,
                      items: StokHareketCouples.ihracatTipleri
                          .map((e) => DropdownMenuItem(
                              value: e.value,
                              child: Text(e.text,
                                  style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _irsaliye.ithalatihracattipi = v))),
            ],
          ]),
          const SizedBox(height: 10),

          _buildDropdown<int>(
            label: "Taşıma Fazı",
            value: _irsaliye.tasimafazi,
            items: TasimafaziCouples.list
                .map((e) => DropdownMenuItem(
                      value: e.value,
                      child: Text('${e.text} (${e.value})',
                          style: const TextStyle(fontSize: 13)),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _irsaliye.tasimafazi = v),
          ),
          const SizedBox(height: 10),

          // 3. Tarih / Fiili Tarih
          Row(children: [
            Expanded(
                child:
                    _buildDateField("Tarih", _tarihCtrl, _irsaliye.tarih, (d) {
              setState(() {
                _irsaliye.tarih = d;
                _tarihCtrl.text = _fmtDate(d);
              });
              _recalcVadeTarihi();
            })),
            const SizedBox(width: 12),
            Expanded(
                child: _buildDateField(
                    "Fiili Tarih",
                    _fiiliTarihCtrl,
                    _irsaliye.fiilitarih,
                    (d) => setState(() {
                          _irsaliye.fiilitarih = d;
                          _fiiliTarihCtrl.text = _fmtDate(d);
                        }))),
          ]),
          const SizedBox(height: 10),

          // 4. Teslim Tarihi / Teslim Adresi
          Row(children: [
            Expanded(
                child: _buildDateField(
                    "Teslim Tarihi",
                    _teslimTarihCtrl,
                    _irsaliye.teslimtarihi,
                    (d) => setState(() {
                          _irsaliye.teslimtarihi = d;
                          _teslimTarihCtrl.text = _fmtDate(d);
                        }))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildDropdown<int>(
                    label: "Teslim Adresi",
                    value: _irsaliye.cariadresid,
                    items: _cariAdresler
                        .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.adres ?? '',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() {
                          _irsaliye.cariadresid = v;
                          _cariAdresManuelSecildi = true;
                        }))),
          ]),
          const SizedBox(height: 10),

          // 5. Vade Günü / Vade Tarihi
          Row(children: [
            Expanded(
                flex: 2,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _inputLabel("Vade Günü"),
                      SizedBox(
                          height: 45,
                          child: TextFormField(
                            initialValue: _irsaliye.vadegunu?.toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              _irsaliye.vadegunu = int.tryParse(v) ?? 0;
                              _recalcVadeTarihi();
                            },
                            style: const TextStyle(fontSize: 13),
                            decoration: InputDecoration(
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 12),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                        color: _scheme.outlineVariant))),
                          )),
                    ])),
            const SizedBox(width: 12),
            Expanded(
                flex: 3,
                child: _buildDateField(
                    "Vade Tarihi",
                    _vadeTarihCtrl,
                    _irsaliye.vadetarihi,
                    (d) => setState(() {
                          _irsaliye.vadetarihi = d;
                          _vadeTarihCtrl.text = _fmtDate(d);
                        }))),
          ]),
          const SizedBox(height: 10),

          // 6. Ödeme Şekli / Tahsilat Tarihi
          Row(children: [
            Expanded(
                child: _buildDropdown<int>(
                    label: "Ödeme Şekli",
                    value: _irsaliye.odemesekli,
                    items: StokHareketCouples.odemeSekilleri
                        .map((e) => DropdownMenuItem(
                            value: e.value,
                            child: Text(e.text,
                                style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _irsaliye.odemesekli = v))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildDateField(
                    "Tahsilat Tarihi",
                    _tahsilatTarihCtrl,
                    _irsaliye.tahsilattarihi,
                    (d) => setState(() {
                          _irsaliye.tahsilattarihi = d;
                          _tahsilatTarihCtrl.text = _fmtDate(d);
                        }))),
          ]),
          const SizedBox(height: 10),

          // 7. Döviz / Döviz Tarihi
          Row(children: [
            Expanded(
                child: _buildDropdown<int>(
                    label: "Döviz",
                    value: _irsaliye.dovizid,
                    items: _dovizler
                        .map((e) => DropdownMenuItem(
                            value: e.Id,
                            child: Text(e.Ad ?? '',
                                style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _irsaliye.dovizid = v;
                      });
                      _kurGetir();
                    })),
            if (!_tryMi) ...[
              const SizedBox(width: 12),
              Expanded(
                  child: _buildDateField(
                      "Döviz Tarihi", _dovizTarihCtrl, _irsaliye.doviztarih,
                      (d) {
                setState(() {
                  _irsaliye.doviztarih = d;
                  _dovizTarihCtrl.text = _fmtDate(d);
                });
                _kurGetir();
              })),
            ],
          ]),
          const SizedBox(height: 10),

          // 8. Kur (tam genişlik)
          if (!_tryMi) ...[
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _inputLabel("Kur"),
              SizedBox(
                  height: 45,
                  child: Row(children: [
                    InkWell(
                      onTap: () {
                        final v = double.tryParse(
                                _kurCtrl.text.replaceAll(',', '.')) ??
                            0;
                        if (v > 0) {
                          final n = (v - 1).clamp(0.0, double.infinity);
                          setState(() {
                            _irsaliye.kur = n;
                            _kurCtrl.text =
                                n.toStringAsFixed(4).replaceAll('.', ',');
                          });
                        }
                      },
                      child: Container(
                          width: 36,
                          height: 45,
                          decoration: BoxDecoration(
                              border: Border.all(color: _scheme.outlineVariant),
                              borderRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(8))),
                          child: const Icon(Icons.remove,
                              size: 16, color: Colors.grey)),
                    ),
                    Expanded(
                        child: TextFormField(
                      controller: _kurCtrl,
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13),
                      onChanged: (v) => _irsaliye.kur =
                          double.tryParse(v.replaceAll(',', '.')),
                      decoration: InputDecoration(
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide:
                                  BorderSide(color: _scheme.outlineVariant)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.zero,
                              borderSide:
                                  BorderSide(color: _scheme.outlineVariant))),
                    )),
                    InkWell(
                      onTap: () {
                        final v = double.tryParse(
                                _kurCtrl.text.replaceAll(',', '.')) ??
                            0;
                        final n = v + 1;
                        setState(() {
                          _irsaliye.kur = n;
                          _kurCtrl.text =
                              n.toStringAsFixed(4).replaceAll('.', ',');
                        });
                      },
                      child: Container(
                          width: 36,
                          height: 45,
                          decoration: BoxDecoration(
                              border: Border.all(color: _scheme.outlineVariant),
                              borderRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(8))),
                          child: const Icon(Icons.add,
                              size: 16, color: Colors.grey)),
                    ),
                  ])),
            ]),
            const SizedBox(height: 10),
          ],

          // 8b. Referans / Açıklama
          Row(children: [
            Expanded(
                child: _buildDropdown<int>(
                    label: "Referans",
                    value: _irsaliye.referansid,
                    items: _referanslar
                        .map((e) => DropdownMenuItem(
                            value: e.Id,
                            child: Text("${e.Kod ?? ''} - ${e.Ad ?? ''}",
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _irsaliye.referansid = v))),
            const SizedBox(width: 12),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  _inputLabel("Açıklama"),
                  SizedBox(
                      height: 45,
                      child: TextFormField(
                        controller: _aciklamaCtrl,
                        onChanged: (v) =>
                            _irsaliye.aciklama = v.isEmpty ? null : v,
                        maxLines: 1,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 12),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide:
                                    BorderSide(color: _scheme.outlineVariant)),
                            hintText: "Açıklama",
                            hintStyle: TextStyle(
                                color: _scheme.onSurfaceVariant, fontSize: 13)),
                      )),
                ])),
          ]),
          const SizedBox(height: 10),

          // 9. Proje / Plasiyer
          Row(children: [
            Expanded(
                child: _buildSelectorField(
              label: "Proje",
              value: _projeler
                      .where((p) => p.id == _irsaliye.projeid)
                      .firstOrNull
                      ?.ad ??
                  "Seçiniz",
              onTap: () async {
                final res = await showErpSelector(
                    context: context,
                    title: "Proje Seç",
                    hintText: "Proje adı veya kodu",
                    items: _projeler,
                    itemText: (p) => "${p.kod ?? ''} - ${p.ad ?? ''}");
                if (res != null) setState(() => _irsaliye.projeid = res.id);
              },
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSelectorField(
              label: "Plasiyer",
              value: _plasiyerler
                      .where((p) => p.Id == _irsaliye.plasiyerid)
                      .firstOrNull
                      ?.Adsoyad ??
                  "Seçiniz",
              onTap: () async {
                final res = await showErpSelector(
                    context: context,
                    title: "Plasiyer Seç",
                    hintText: "Plasiyer adı",
                    items: _plasiyerler,
                    itemText: (p) => p.Adsoyad ?? '');
                if (res != null) setState(() => _irsaliye.plasiyerid = res.Id);
              },
            )),
          ]),
          const SizedBox(height: 10),

          // 10. KDV Toggle
          _buildKdvToggle(),
          DocumentExtraNotesButton(
              values: _irsaliye.extraNotes,
              onChanged: (values) =>
                  setState(() => _irsaliye.extraNotes = values)),
          const SizedBox(height: 10),
        ]),
      ],
    );
  }

  // ─── TAŞIYICI TAB ────────────────────────────────────────
  Widget _tasiyiciTab() {
    // Seçili aracın plaka + tip bilgisi
    //final seciliArac = _araclar.where((a) => a.id == _irsaliye.aracid).firstOrNull;
    // Lojistik cari: aracın kendi lojistikcari navigation'ından ya da cariler listesinden
    final lojistikCariAd = _lojistikCariAd;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSectionCard(children: [
          // 1. Araç — plaka + tip göster
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _inputLabel("Araç"),
            Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _scheme.outlineVariant),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _araclar.any((a) => a.id == _irsaliye.aracid)
                      ? _irsaliye.aracid
                      : null,
                  isExpanded: true,
                  isDense: true,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: _scheme.onSurface),
                  hint: Text("Araç seçiniz",
                      style: TextStyle(
                          fontSize: 13, color: _scheme.onSurfaceVariant)),
                  items: _araclar.map((a) {
                    final label = [a.plaka, a.tip]
                        .where((s) => s != null && s.isNotEmpty)
                        .join(' — ');
                    return DropdownMenuItem(
                      value: a.id,
                      child: Text(label.isEmpty ? 'Araç #${a.id}' : label,
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (v) async {
                    setState(() {
                      _irsaliye.aracid = v;
                      _irsaliye.lojistikcariid = null;
                      _irsaliye.surucuid = null;
                      _lojistikCariAd = null;
                    });
                    if (v == null) return;
                    // C# gibi: seçilince detayını çek (Lojistikcari navigation dahil)
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString("token_final") ?? "";
                    AracDto? detay;
                    try {
                      detay = await AracService().getByIdWithoutAuth(v, token);
                    } catch (error) {
                      if (mounted) UiFeedback.showException(context, error);
                      return;
                    }
                    final selectedVehicle = detay;
                    if (selectedVehicle != null &&
                        mounted &&
                        _irsaliye.aracid == v) {
                      setState(() {
                        _irsaliye.lojistikcariid =
                            selectedVehicle.lojistikcariid;
                        if (selectedVehicle.lojistikcari != null) {
                          _lojistikCariAd =
                              "${selectedVehicle.lojistikcari!.Kod ?? ''} - ${selectedVehicle.lojistikcari!.Ad ?? ''}"
                                  .trim();
                        } else if (selectedVehicle.lojistikcariid != null) {
                          _loadLojistikCari(selectedVehicle.lojistikcariid!);
                        }
                      });
                    }
                  },
                ),
              ),
            ),
          ]),
          const SizedBox(height: 16),

          // 2. Lojistik Cari (araçtan otomatik - readonly)
          _inputLabel("Lojistik Cari"),
          Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _scheme.outlineVariant),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                lojistikCariAd ?? "Araç seçilince dolacak",
                style: TextStyle(
                  fontSize: 13,
                  color: lojistikCariAd != null
                      ? Colors.black87
                      : _scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Sürücü
          _buildDropdown<int>(
            label: "Sürücü",
            value: _irsaliye.surucuid,
            items: _suruculer
                .map((s) => DropdownMenuItem(
                      value: s.id,
                      child: Text(s.adsoyad ?? '',
                          style: const TextStyle(fontSize: 13),
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _irsaliye.surucuid = v),
          ),
          const SizedBox(height: 16),

          // 4. T. Kantar Miktar
          _buildSayisalAlan(
            label: "T. Kantar Miktar",
            ctrl: _tKantarCtrl,
            onChanged: (v) => _irsaliye.tedarikcikantarmiktar = v,
          ),
          const SizedBox(height: 16),

          // 5. Teslim A. Kantar Miktar
          _buildSayisalAlan(
            label: "Teslim A. Kantar Miktar",
            ctrl: _teslimKantarCtrl,
            onChanged: (v) => _irsaliye.teslimalinankantarmiktar = v,
          ),
          const SizedBox(height: 16),

          // 6. Kap Miktarı
          _buildSayisalAlan(
            label: "Kap Miktarı",
            ctrl: _kapMiktarCtrl,
            onChanged: (v) => _irsaliye.kapadet = v,
          ),
          const SizedBox(height: 16),
        ]),
      ],
    );
  }

  Widget _buildSayisalAlan({
    required String label,
    required TextEditingController ctrl,
    required ValueChanged<double?> onChanged,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _inputLabel(label),
      SizedBox(
          height: 45,
          child: Row(children: [
            InkWell(
              onTap: () {
                final v = NumberFormatHelper.parse(ctrl.text);
                final n = (v - 1).clamp(0.0, double.infinity);
                ctrl.text = NumberFormatHelper.format(n, decimal: 4);
                onChanged(n);
              },
              child: Container(
                  width: 36,
                  height: 45,
                  decoration: BoxDecoration(
                      border: Border.all(color: _scheme.outlineVariant),
                      borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8))),
                  child:
                      const Icon(Icons.remove, size: 16, color: Colors.grey)),
            ),
            Expanded(
                child: TextFormField(
              controller: ctrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13),
              onChanged: (v) => onChanged(NumberFormatHelper.parse(v)),
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: _scheme.outlineVariant)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.zero,
                      borderSide: BorderSide(color: _scheme.outlineVariant))),
            )),
            InkWell(
              onTap: () {
                final v = NumberFormatHelper.parse(ctrl.text);
                final n = v + 1;
                ctrl.text = NumberFormatHelper.format(n, decimal: 4);
                onChanged(n);
              },
              child: Container(
                  width: 36,
                  height: 45,
                  decoration: BoxDecoration(
                      border: Border.all(color: _scheme.outlineVariant),
                      borderRadius: const BorderRadius.horizontal(
                          right: Radius.circular(8))),
                  child: const Icon(Icons.add, size: 16, color: Colors.grey)),
            ),
          ])),
    ]);
  }

  // ─── KALEMLER TAB ────────────────────────────────────────
  Widget _kalemlerTab() {
    if (_kalemler.isEmpty) {
      return Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.inventory_2_outlined,
            size: 56, color: _scheme.outlineVariant),
        const SizedBox(height: 12),
        Text("Henüz kalem yok",
            style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 15)),
        const SizedBox(height: 8),
        Text("Sepet butonuna basarak kalem ekleyin",
            style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 13)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
      itemCount: _kalemler.length,
      itemBuilder: (_, i) {
        final k = _kalemler[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 1,
          child: ListTile(
            contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
            title: Text("${k.stok?.Kod ?? ''} - ${k.stok?.Ad ?? '-'}",
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            subtitle:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 4),
              Text(
                  "${NumberFormatHelper.format(k.miktar ?? 0)} ${k.olcubr?.Ad ?? ''}  ×  ${NumberFormatHelper.format(k.fiyat ?? 0)} ₺",
                  style:
                      TextStyle(fontSize: 12, color: _scheme.onSurfaceVariant)),
              if ((k.kdvorani ?? 0) > 0)
                Text(
                    "KDV %${(k.kdvorani ?? 0).toInt()}  →  ${NumberFormatHelper.format(k.tutar ?? 0)} ₺",
                    style: TextStyle(
                        fontSize: 12, color: _scheme.onSurfaceVariant)),
              DocumentTrackingButton(
                  mode: k.stok?.Partiseritakipmodu,
                  line: TrackingLine(
                      document: TrackingDocument.salesWaybill,
                      documentId: _yeniIrsaliyeId,
                      lineId: k.id,
                      stockId: k.stokid,
                      warehouseId: k.depoid,
                      addressId: k.depoadresid,
                      featureId: k.stokozelliksabitid,
                      direction: k.giriscikis,
                      quantity: k.miktar ?? 0,
                      multiplier: k.olcubrcarpim ?? 0)),
            ]),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              PermissionAction(
                  modules: [501],
                  access: Access.write,
                  child: IconButton(
                      icon: Icon(Icons.edit_outlined,
                          size: 20, color: Colors.blue.shade600),
                      onPressed: () => _editKalem(i))),
              PermissionAction(
                  modules: [501],
                  access: Access.write,
                  child: IconButton(
                      icon: Icon(Icons.delete_outline,
                          size: 20, color: Colors.red.shade600),
                      onPressed: () => _deleteKalem(i))),
            ]),
          ),
        );
      },
    );
  }

  // ─── ÖZET TAB ────────────────────────────────────────────
  Widget _ozetTab() {
    final double brutToplam =
        _kalemler.fold(0.0, (s, k) => s + ((k.miktar ?? 0) * (k.fiyat ?? 0)));
    final double satirIskontoToplam =
        _kalemler.fold(0.0, (s, k) => s + (k.iskontotutar ?? 0));
    final double malFazlasiToplam =
        _kalemler.fold(0.0, (s, k) => s + (k.malfazlasitutar ?? 0));
    final double araToplam = brutToplam - satirIskontoToplam;
    final double toplamTevkifat =
        _kalemler.fold(0.0, (s, k) => s + (k.tevkifattutar ?? 0));
    final double genelToplam = _irsaliye.geneltoplam ?? 0;
    final bool isDoviz = (_irsaliye.dovizid ?? 1) != 1;
    final double kur = IrsaliyeHesapHelper.rate(_irsaliye);
    final discount = _irsaliye.geneliskontotutar ?? 0;
    final base = _kalemler.fold<double>(0, (s, k) => s + (k.bruttutar ?? 0));
    final factor = base > 0 ? (base - discount) / base : 1.0;
    final String dovizSembol =
        _dovizler.where((d) => d.Id == _irsaliye.dovizid).firstOrNull?.Ad ??
            '₺';

    final Map<int, Map<String, double>> kdvDetay = {};
    for (final k in _kalemler) {
      final oran = (k.kdvorani ?? 0).toInt();
      kdvDetay[oran] ??= {'matrah': 0, 'kdv': 0};
      kdvDetay[oran]!['matrah'] =
          (kdvDetay[oran]!['matrah']! + (k.bruttutar ?? 0));
      kdvDetay[oran]!['kdv'] = (kdvDetay[oran]!['kdv']! +
          (k.kdvtutar ?? 0) -
          (k.tevkifattutar ?? 0));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        OutlinedButton.icon(
            onPressed: _genelIskontoSec,
            icon: const Icon(Icons.percent_rounded, size: 18),
            label: const Text('Genel İskonto')),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF17243B), Color(0xFF293E5B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                  color: Colors.purple.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8))
            ],
          ),
          child: Column(children: [
            _ozetSatir("Brüt Toplam", brutToplam),
            if (satirIskontoToplam > 0) ...[
              _ozetSatir("Satır İskontosu", satirIskontoToplam,
                  isNeg: true, color: Colors.orange.shade300),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(color: Colors.white10)),
              _ozetSatir("Ara Toplam", araToplam, bold: true),
              const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(color: Colors.white10)),
            ],
            if (discount > 0)
              _ozetSatir("Genel İskonto", discount,
                  isNeg: true, color: Colors.orange.shade300),
            if (malFazlasiToplam > 0)
              _ozetSatir("Mal Fazlası (bilgi)", malFazlasiToplam,
                  color: Colors.blue.shade200),
            ...kdvDetay.entries.where((e) => e.key > 0).map((e) => _ozetSatir(
                "KDV %${e.key}", e.value['kdv']! * factor,
                color: Colors.lightBlue.shade200)),
            if (toplamTevkifat > 0)
              _ozetSatir("Tevkifat", toplamTevkifat * factor,
                  isNeg: true, color: Colors.amber.shade300),
            const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Divider(color: Colors.white24, thickness: 1)),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Text("GENEL TOPLAM",
                  style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                  isDoviz
                      ? "${NumberFormatHelper.format(genelToplam / kur)} $dovizSembol"
                      : "${NumberFormatHelper.format(genelToplam)} ₺",
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900),
                ),
                if (isDoviz)
                  Text("${NumberFormatHelper.format(genelToplam)} ₺",
                      style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
              ]),
            ]),
          ]),
        ),
      ]),
    );
  }

  Widget _ozetSatir(String label, double val,
          {bool isNeg = false, bool bold = false, Color? color}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label,
              style: TextStyle(color: color ?? Colors.white70, fontSize: 13)),
          Text("${isNeg ? '-' : ''}${NumberFormatHelper.format(val)} ₺",
              style: TextStyle(
                  color: color ?? Colors.white,
                  fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                  fontSize: 13)),
        ]),
      );

  // ─── CARİ SEÇİCİ ─────────────────────────────────────────
  Widget _buildCariSecici() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
        border: Border.all(
            color: _seciliCari != null
                ? _accent.withValues(alpha: 0.25)
                : _scheme.outlineVariant),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Row(children: [
        OutlinedButton.icon(
          onPressed: _cariSec,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            side: BorderSide(color: _accent, width: 1.5),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          icon: Icon(Icons.business_rounded, size: 15, color: _accent),
          label: Text("Cari Seç",
              style: TextStyle(
                  fontSize: 12, color: _accent, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _seciliCari != null
              ? GestureDetector(
                  onTap: _cariSec,
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_seciliCari!.Kod ?? '',
                            style: TextStyle(
                                fontSize: 11,
                                color: _scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.4)),
                        const SizedBox(height: 2),
                        Text(_seciliCari!.Ad ?? '',
                            style: TextStyle(
                                fontSize: 14,
                                color: _accent,
                                fontWeight: FontWeight.w800),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 2),
                      ]),
                )
              : GestureDetector(
                  onTap: _cariSec,
                  child: Text("Cari seçilmedi",
                      style: TextStyle(
                          color: _scheme.onSurfaceVariant,
                          fontSize: 13,
                          fontStyle: FontStyle.italic)),
                ),
        ),
      ]),
    );
  }

  // ─── KDV TOGGLE ──────────────────────────────────────────
  Widget _buildKdvToggle() {
    final kdvDahil = _irsaliye.kdvdahil ?? false;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _inputLabel("KDV"),
      Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: kdvDahil ? Colors.green.shade50 : Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: kdvDahil ? Colors.green.shade300 : Colors.orange.shade300),
        ),
        child:
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(
            kdvDahil ? "KDV Dahil" : "KDV Hariç",
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    kdvDahil ? Colors.green.shade700 : Colors.orange.shade700),
          ),
          SizedBox(
              width: 38,
              height: 32,
              child: FittedBox(
                child: Switch(
                  value: kdvDahil,
                  activeColor: Colors.green.shade600,
                  inactiveThumbColor: Colors.orange.shade600,
                  inactiveTrackColor: Colors.orange.shade200,
                  onChanged: (v) => setState(() {
                    _irsaliye.kdvdahil = v;
                  }),
                ),
              )),
        ]),
      ),
    ]);
  }

  // ─── YARDIMCI WİDGET'LAR ─────────────────────────────────
  Widget _buildSectionCard({required List<Widget> children}) =>
      ErpDesignStyle.modern(context)
          ? ErpFormSection(children: children)
          : Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                  color: _scheme.surface,
                  border: Border.all(
                      color: _scheme.outlineVariant.withValues(alpha: .45)),
                  borderRadius: BorderRadius.circular(
                      ErpDesignStyle.modern(context) ? 18 : 16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3))
                  ]),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children),
            );

  Widget _inputLabel(String label) => Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 4),
        child: Text(label,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
      );

  Widget _buildSelectorField(
      {required String label,
      required String value,
      required VoidCallback onTap}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _inputLabel(label),
      InkWell(
          onTap: onTap,
          child: Container(
              height: 45,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _scheme.outlineVariant)),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                        child: Text(value,
                            style: const TextStyle(fontSize: 13),
                            overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.chevron_right,
                        size: 20, color: Colors.grey),
                  ]))),
    ]);
  }

  Widget _buildDropdown<T>(
      {required String label,
      required T? value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged}) {
    // Duplicate value'ları temizle
    final seen = <T?>{};
    final safeItems =
        items.where((e) => e.value != null && seen.add(e.value)).toList();
    final safeValue = safeItems.any((e) => e.value == value) ? value : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _inputLabel(label),
      Container(
        height: 45,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _scheme.outlineVariant),
        ),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
          value: safeValue,
          items: safeItems,
          onChanged: onChanged,
          isExpanded: true,
          isDense: true,
          style: TextStyle(
              fontFamily: 'Roboto', fontSize: 13, color: _scheme.onSurface),
        )),
      ),
    ]);
  }

  Widget _buildDateField(String label, TextEditingController ctrl,
      DateTime? current, Function(DateTime) onPicked) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _inputLabel(label),
      InkWell(
        onTap: () async {
          final picked = await showDatePicker(
              context: context,
              initialDate: current ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100));
          if (picked != null) onPicked(picked);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _scheme.outlineVariant),
            color: (ErpDesignStyle.modern(context) ||
                    _scheme.brightness == Brightness.dark)
                ? _scheme.surfaceContainerLow
                : Colors.white,
          ),
          child: Row(children: [
            Expanded(
                child: Text(ctrl.text.isEmpty ? 'Seçiniz' : ctrl.text,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _scheme.onSurface))),
            Icon(Icons.calendar_today_outlined,
                size: 16, color: _scheme.onSurfaceVariant),
          ]),
        ),
      ),
    ]);
  }
}
