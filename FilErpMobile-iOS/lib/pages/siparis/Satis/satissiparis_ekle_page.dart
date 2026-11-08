import '../../../widgets/commercial_document_fields.dart';
import '../../../widgets/document_extra_notes.dart';
import '../../../widgets/fatura/fatura_genel_iskonto_sheet.dart';
import '../../../helpers/order_line_amounts.dart';
import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/erp_page_style.dart';
import '../../../widgets/erp_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../services/offline/offline_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/cari_plasiyer_helper.dart';
import '../../../helpers/varsayilan_depo_helper.dart';
import '../../../helpers/varsayilan_proje_helper.dart';
import '../../../helpers/belge_turu_couples.dart';
import '../../../helpers/number_format_helper.dart';
import '../../../helpers/fatura_hesap_helper.dart';
import '../../../helpers/lookups.dart';
import '../../../helpers/oncelik_couples.dart';
import '../../../helpers/stokhareket_couples.dart';
import '../../../models/entities/siparis/siparis_dto.dart';
import '../../../models/entities/siparis/siparishareket_dto.dart';
import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/cari/cariadres_dto.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../../models/entities/referans/referans_dto.dart';
import '../../../models/entities/stok/stok_list_dto.dart';
import '../../../models/entities/depo/depo_dto.dart';
import '../../../models/entities/yonetim/belge_seri_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../services/siparis/siparis_service.dart';
import '../../../services/cari/cari_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../services/plasiyer/plasiyer_service.dart';
import '../../../services/referans/referans_service.dart';
import '../../../services/stok/stok_service.dart';
import '../../../services/yonetim/belgeseri_service.dart';
import '../../../services/yonetim/kur_service.dart';
import '../../../services/depo/depo_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../models/entities/stok/stok_dto.dart';
//import '../../../models/entities/cari/cari_dto_full.dart';
import '../../../widgets/erp_selector.dart';
import '../../../widgets/siparis/siparis_kalem_form_sheet.dart';
import '../../../widgets/quick_barcode_scan_sheet.dart';
import '../../../widgets/barcode_scanner_sheet.dart';

class SatisSiparisEklePage extends StatefulWidget {
  final String? siparisId;
  const SatisSiparisEklePage({super.key, this.siparisId});

  @override
  State<SatisSiparisEklePage> createState() => _SatisSiparisEklePageState();
}

class _SatisSiparisEklePageState extends State<SatisSiparisEklePage>
    with SingleTickerProviderStateMixin {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;

  bool get _isEditMode => widget.siparisId != null;

  late TabController _tabCtrl;
  final _svc = SiparisService();

  bool _loading = false;
  final _siparis = SiparisDto();
  final List<SiparishareketDto> _kalemler = [];
  String? _yeniSiparisId;
  // Bu oturumda offline (manuel offline ya da internet yok) modda en az bir
  // kalem eklendiyse true olur; bir kez true olduktan sonra oturum boyunca
  // öyle kalır — online/offline yarı-kayıtlı karışık durum oluşmasın diye.
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

  bool _cariAdresManuelSecildi = false;
  bool _cariTR = true;

  // Terminal barkod
  final StringBuffer _barkodBuffer = StringBuffer();
  DateTime? _sonTus;
  static const _barkodTimeout = Duration(milliseconds: 80);

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

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });

    _yilListesi = List.generate(5, (i) => DateTime.now().year - i);
    _seciliYil = DateTime.now().year;

    final now = DateTime.now();
    _siparis
      ..tarih = now
      ..fiilitarih = now
      ..teslimtarihi = now
      ..vadetarihi = now
      ..vadegunu = 0
      ..tahsilattarihi = now
      ..belgeyil = now.year
      ..kdvdahil = false
      ..belgeturu = BelgeTuruCouples.satisSiparis;

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
    _siparis.dovizid = 1; // TL varsayılan
    _siparis.kur = 1.0;

    _loadLookups();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    HardwareKeyboard.instance.addHandler(_terminalBarkodHandler);
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
    super.dispose();
  }

  String _fmtDate(DateTime? d) => d == null
      ? ''
      : "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

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
            .getAll(token, BelgeTuruCouples.satisSiparis);
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
      try {
        dovizler = await DovizService().getDovizler(token);
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
        _belgeSeriListesi = seriList;
        _loading = false;

        if (projeler.isNotEmpty && _siparis.projeid == null)
          _siparis.projeid = varsayilanProjeId;
        if (plasiyerler.isNotEmpty && _siparis.plasiyerid == null)
          _siparis.plasiyerid = plasiyerler.first.Id;
        if (seriList.isNotEmpty && _seciliSeri == null) {
          _seciliSeri = seriList.first.seri;
          _siparis.belgeseri = _seciliSeri;
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
      final mevcut = await _svc.getSatisById(token, widget.siparisId!);
      if (!mounted) return;
      setState(() {
        _yeniSiparisId = mevcut.id;
        _siparis.cariid = mevcut.cariid;
        _siparis.cariadresid = mevcut.cariadresid;
        _siparis.projeid = mevcut.projeid;
        _siparis.plasiyerid = mevcut.plasiyerid;
        _siparis.referansid = mevcut.referansid;
        _siparis.oncelik = mevcut.oncelik;
        _siparis.belgeseri = mevcut.belgeseri;
        _siparis.belgeyil = mevcut.belgeyil;
        _siparis.belgeno = mevcut.belgeno;
        _siparis.tarih = mevcut.tarih;
        _siparis.fiilitarih = mevcut.fiilitarih;
        _siparis.teslimtarihi = mevcut.teslimtarihi;
        _siparis.aciklama = mevcut.aciklama;
        _siparis.kdvdahil = mevcut.kdvdahil;
        _siparis.belgetipi = mevcut.belgetipi;
        _siparis.ithalatihracattipi = mevcut.ithalatihracattipi;
        _siparis.odemesekli = mevcut.odemesekli;
        _siparis.vadegunu = mevcut.vadegunu;
        _siparis.vadetarihi = mevcut.vadetarihi;
        _siparis.tahsilattarihi = mevcut.tahsilattarihi;
        _siparis.dovizid = mevcut.dovizid ?? 1;
        _siparis.doviztarih = mevcut.doviztarih;
        _siparis.kur = mevcut.kur;
        _siparis.extraNotes = mevcut.extraNotes;
        _siparis.teslimattipi = mevcut.teslimattipi;
        _siparis.referansbelgeno = mevcut.referansbelgeno;
        _siparis.baglanti = mevcut.baglanti;
        _siparis.baglantituru = mevcut.baglantituru;
        _siparis.belgeturu = mevcut.belgeturu;
        _siparis.geneliskontooran = mevcut.geneliskontooran;
        _siparis.geneliskontotutar = mevcut.geneliskontotutar;
        _siparis.dovizgeneliskontotutar = mevcut.dovizgeneliskontotutar;
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
          ..addAll(mevcut.siparishareket);
        if (mevcut.cari != null) {
          _seciliCari = CariDtoLite(
              Id: mevcut.cariid, Ad: mevcut.cari?.Ad, Kod: mevcut.cari?.Kod);
        }
      });
      _recalcToplam();
    } catch (e, s) {
      debugPrint(">>> loadMevcut HATA: $e\n$s");
      if (mounted) UiFeedback.showError(context, "Sipariş yüklenemedi: $e");
    }
  }

  Future<void> _fetchYeniNo(String token) async {
    if (_seciliSeri == null) return;
    try {
      final no = await _svc.getNewSatisNo(token, _seciliSeri!, _seciliYil);
      if (mounted)
        setState(() {
          _siparis.belgeno = no;
          _belgeNoCtrl.text = no;
        });
    } catch (_) {}
  }

  void _recalcVadeTarihi() {
    final tarih = _siparis.tarih ?? DateTime.now();
    final vg = _siparis.vadegunu ?? 0;
    final vt = tarih.add(Duration(days: vg));
    setState(() {
      _siparis.vadetarihi = vt;
      _vadeTarihCtrl.text = _fmtDate(vt);
      // Teslim tarihi vade tarihi ile aynı
      _siparis.teslimtarihi = vt;
      _teslimTarihCtrl.text = _fmtDate(vt);
    });
  }

  void _recalcToplam() {
    final sonuc = FaturaHesapHelper.hesaplaFaturaToplam(
      kalemler: _kalemler
          .map((k) => KalemTutar(
                bruttutar: k.bruttutar ?? 0,
                kdvtutar: k.kdvtutar ?? 0,
                tevkifattutar: k.tevkifattutar,
              ))
          .toList(),
      genelIskontoOrani: _siparis.geneliskontooran,
      genelIskontoTutar: (_siparis.geneliskontooran ?? 0) > 0
          ? null
          : _siparis.geneliskontotutar,
    );
    setState(() {
      _siparis.geneliskontotutar = sonuc.iskontotutar;
      _siparis.dovizgeneliskontotutar =
          sonuc.iskontotutar / (_isDoviz ? _aktifKur : 1);
      _siparis.aratoplam = sonuc.aratoplam;
      _siparis.kdvtoplam = sonuc.kdvtoplam;
      _siparis.geneltoplam = sonuc.geneltoplam;
      _siparis.doviztoplam = _isDoviz ? sonuc.geneltoplam / _aktifKur : null;
    });
  }

  bool get _isDoviz => (_siparis.dovizid != null && _siparis.dovizid != 1);

  double get _aktifKur {
    final kur = _siparis.kur ?? 1.0;
    return kur <= 0 ? 1.0 : kur;
  }

  String get _seciliDovizAdi =>
      _dovizler.where((e) => e.Id == _siparis.dovizid).firstOrNull?.Ad ??
      'Döviz';

  // TRY (TL) mi? Kur / Döviz Tarihi yalnızca dövizli (TL dışı) kayıtta gösterilir.
  bool get _tryMi {
    final id = _siparis.dovizid;
    if (id == null || id == 1) return true;
    final d = _dovizler.where((x) => x.Id == id).firstOrNull;
    final b = (d?.Birim ?? '').trim().toUpperCase();
    return b == 'TL' || b == 'TRY' || b == '₺';
  }

  Future<void> _kurGetir({bool bilgiVer = true}) async {
    final dovizId = _siparis.dovizid;
    if (dovizId == null || dovizId == 1) {
      final eskiKur = _aktifKur;
      setState(() {
        _siparis.kur = 1.0;
        _kurCtrl.text = '1,0000';
      });
      _kurDegisiminiKalemlereUygula(eskiKur: eskiKur);
      return;
    }

    final tarih = _siparis.doviztarih ?? _siparis.tarih ?? DateTime.now();
    setState(() {
      _siparis.doviztarih = tarih;
      _dovizTarihCtrl.text = _fmtDate(tarih);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final eskiKur = _aktifKur;
      final kur = await KurService().getByDovizIdAndDate(token, dovizId, tarih);
      final yeniKur = kur?.Dovizsatis ??
          kur?.Dovizalis ??
          kur?.Dovizefektifsatis ??
          kur?.Dovizefektifalis;
      if (yeniKur == null || yeniKur <= 0) {
        if (mounted) {
          UiFeedback.showWarning(context, "$_seciliDovizAdi kuru bulunamadı.");
        }
        return;
      }
      if (!mounted) return;
      setState(() {
        _siparis.kur = yeniKur;
        _kurCtrl.text = yeniKur.toStringAsFixed(4).replaceAll('.', ',');
      });
      _kurDegisiminiKalemlereUygula(eskiKur: eskiKur);
      if (bilgiVer && mounted) {
        UiFeedback.showSuccess(
          context,
          "$_seciliDovizAdi kuru ${_kurCtrl.text} olarak alındı.",
        );
      }
    } catch (e) {
      if (mounted) UiFeedback.showError(context, "Kur alınamadı: $e");
    }
  }

  void _kurDegisiminiKalemlereUygula({double? eskiKur}) {
    final kur = _isDoviz ? _aktifKur : 1.0;
    setState(() {
      for (final k in _kalemler) {
        _kalemiKuraGoreHesapla(k, kur, eskiKur: eskiKur);
      }
    });
    _recalcToplam();
  }

  SiparishareketDto _kalemFormKopya(SiparishareketDto source) =>
      OrderLineAmounts.editor(source, _aktifKur, _isDoviz);

  void _yeniKalemiAktifDovizeUygula(SiparishareketDto k) {
    OrderLineAmounts.fromEditor(k, _aktifKur, _isDoviz);
    if (_isDoviz) {
      k.dovizfiyat = k.fiyat ?? 0;
      _kalemiKuraGoreHesapla(k, _aktifKur);
    } else {
      k.dovizfiyat = null;
      _kalemiKuraGoreHesapla(k, 1);
    }
  }

  void _kalemiKuraGoreHesapla(
    SiparishareketDto k,
    double kur, {
    double? eskiKur,
  }) {
    if (_isDoviz) {
      final kaynakKur = (eskiKur != null && eskiKur > 0) ? eskiKur : kur;
      OrderLineAmounts.revalue(k, kur, kaynakKur);
      final dovizFiyat = (k.dovizfiyat ?? 0) > 0
          ? k.dovizfiyat!
          : ((k.fiyat ?? 0) / kaynakKur);
      k.dovizfiyat = dovizFiyat;
      k.fiyat = dovizFiyat * kur;
      k.kur = kur;
    } else {
      if ((k.dovizfiyat ?? 0) > 0) {
        OrderLineAmounts.toLocal(k, eskiKur ?? k.kur ?? 1);
        k.fiyat = k.dovizfiyat;
      }
      k.dovizfiyat = null;
      k.kur = 1;
    }

    final sonuc = FaturaHesapHelper.hesaplaKalem(
      miktar: k.miktar ?? 0,
      fiyat: k.fiyat ?? 0,
      iskontoTutar: k.iskontotutar ?? 0,
      kdvOrani: k.kdvorani ?? 0,
      tevkifatOrani: k.tevkifatorani ?? 0,
      kdvDahil: _siparis.kdvdahil ?? false,
      malFazlasiAdet: k.malfazlasiiskonto ?? 0,
    );
    k.bruttutar = sonuc.bruttutar;
    k.aratoplam = sonuc.bruttutar;
    k.sonaratoplam = sonuc.bruttutar;
    k.kdvmatrahi = sonuc.bruttutar;
    k.kdvtutar = sonuc.kdvtutar;
    k.netaratoplam = sonuc.bruttutar;
    k.geneltoplam = sonuc.tutar;
    k.tevkifatmatrahi = sonuc.tevkifatmatrahi;
    k.tevkifattutar = sonuc.tevkifattutar;
    k.songeneltoplam = sonuc.tutar;
    k.tutar = sonuc.tutar;
  }

  Future<void> _loadCariAdresler(String token, int cariId) async {
    try {
      final list = await CariService().getCariAdres(token, cariId);
      if (mounted)
        setState(() {
          _cariAdresler = list;
          if (!_cariAdresManuelSecildi) _siparis.cariadresid = null;
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
          _siparis.belgetipi = 1;
        } else {
          _siparis.belgetipi = 6; // İhracat
          for (final k in _kalemler) {
            k.tevkifatorani = null;
          }
        }
        if (cariFull.Vadegunu != null) {
          _siparis.vadegunu = cariFull.Vadegunu;
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
    if (secilen != null && mounted) {
      setState(() {
        _seciliCari = secilen;
        _siparis.cariid = secilen.Id;
        _siparis.cariadresid = null;
        _cariAdresManuelSecildi = false;
      });
      // Cari kartında plasiyer tanımlıysa belgenin plasiyerini ona çevir (bloklamadan)
      CariPlasiyerHelper.getPlasiyerIdOrFirst(secilen.Id, _plasiyerler)
          .then((pid) async {
        final projeId = await VarsayilanProjeHelper.pickFrom(_projeler);
        if (!mounted) return;
        setState(() {
          if (pid != null) _siparis.plasiyerid = pid;
          if (projeId != null) _siparis.projeid = projeId;
        });
      });
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      if (secilen.Id != null) {
        await _loadCariAdresler(token, secilen.Id!);
        await _loadCariVadegunu(token, secilen.Id!);
      }
    }
  }

  bool _terminalBarkodHandler(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final now = DateTime.now();
    if (_sonTus != null && now.difference(_sonTus!) > _barkodTimeout) {
      _barkodBuffer.clear();
    }
    _sonTus = now;
    final label = event.logicalKey.keyLabel;
    if (label == 'Enter') {
      final barkod = _barkodBuffer.toString().trim();
      _barkodBuffer.clear();
      if (barkod.isNotEmpty) _barkodIleStokveBulKalemAc(barkod);
      return true;
    }
    if (label.length == 1) {
      _barkodBuffer.write(label);
      return true;
    }
    return false;
  }

  Future<void> _kameraIleBarkodOku() async {
    final barkod = await Navigator.push<String>(
        context,
        PermissionMaterialPageRoute(
            builder: (_) => const BarcodeScannerSheet()));
    if (barkod != null && barkod.isNotEmpty && mounted) {
      _barkodIleStokveBulKalemAc(barkod);
    }
  }

  Future<void> _barkodIleStokveBulKalemAc(String barkod) async {
    final eslesme = _stoklar
        .where((s) =>
            s
                .getBarkodListesi()
                .any((b) => b.toLowerCase() == barkod.toLowerCase()) ||
            (s.Kod ?? '').toLowerCase() == barkod.toLowerCase())
        .firstOrNull;
    if (eslesme == null) {
      if (mounted) UiFeedback.showWarning(context, "Barkod eşleşmedi: $barkod");
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";

    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (manuelOffline || internetYok) _offlineDraft = true;

    double fiyat = 0;
    double kdvOrani = 0;
    int? olcuBrId;
    if (!_offlineDraft) {
      StokDto? stokFull;
      if (eslesme.Id != null) {
        try {
          stokFull = await StokService().getStokById(token, eslesme.Id!);
        } catch (_) {}
      }
      if (stokFull != null) {
        if (stokFull.Stokfiyat.isNotEmpty) {
          final eslesen = stokFull.Stokfiyat.where(
              (f) => f.Dovizid == (_siparis.dovizid ?? 1)).firstOrNull;
          final fd = eslesen ?? stokFull.Stokfiyat.first;
          fiyat = fd.Satisfiyat ?? 0;
        }
        final kdvRaw = stokFull.Kdvsatis ?? 0;
        kdvOrani = kdvRaw <= 1.0 ? kdvRaw * 100 : kdvRaw;
        final olcuList = stokFull.Stokolcubr;
        if (olcuList.isNotEmpty) {
          olcuBrId = olcuList.first.Olcubrid;
        } else if (stokFull.Temelolcubr != null) {
          olcuBrId = stokFull.Temelolcubr!.Id;
        }
      }
    }

    final k = SiparishareketDto()
      ..stokid = eslesme.Id
      ..stok = StokDto(Id: eslesme.Id, Ad: eslesme.Ad, Kod: eslesme.Kod)
      ..miktar = 1
      ..fiyat = fiyat
      ..kdvorani = kdvOrani
      ..tevkifatorani = _cariTR ? 0 : null
      ..iskontotutar = 0
      ..olcubrid = olcuBrId;
    _yeniKalemiAktifDovizeUygula(k);

    if (_offlineDraft) {
      if (_seciliCari == null) {
        if (mounted)
          UiFeedback.showWarning(context, "Lütfen önce cari seçiniz!");
        return;
      }
      if (mounted) {
        setState(() {
          _kalemler.add(k);
          _recalcToplam();
          _tabCtrl.animateTo(1);
        });
        UiFeedback.showSuccess(
            context, "${eslesme.Ad ?? barkod} eklendi (offline)");
      }
      return;
    }

    if (_yeniSiparisId == null) {
      if (_seciliCari == null) {
        if (mounted)
          UiFeedback.showWarning(context, "Lütfen önce cari seçiniz!");
        return;
      }
      final subeId = prefs.getInt("sube_id") ?? 0;
      try {
        _yeniSiparisId =
            await _svc.saveSatisSingle(token, _siparisToDto(subeId));
      } catch (e) {
        if (mounted) UiFeedback.showError(context, "Sipariş kaydedilemedi: $e");
        return;
      }
    }
    try {
      k.siparisid = _yeniSiparisId;
      final hId = await _svc.saveSatisHareket(
          token, _hareketToInsertJson(k, _yeniSiparisId!));
      if (hId != null) k.id = hId;
      if (mounted) {
        setState(() {
          _kalemler.add(k);
          _recalcToplam();
          _tabCtrl.animateTo(1);
        });
        UiFeedback.showSuccess(context, "${eslesme.Ad ?? barkod} eklendi");
      }
    } catch (e) {
      if (mounted) UiFeedback.showError(context, "Kalem kaydedilemedi: $e");
    }
  }

  Future<void> _addHizliBarkodKalemler() async {
    if (_stoklar.isEmpty) {
      UiFeedback.showWarning(context, "Stok listesi yüklenmedi.");
      return;
    }
    final sonuc = await showQuickBarcodeScanSheet(context, stoklar: _stoklar);
    if (sonuc == null || sonuc.lines.isEmpty || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final subeId = prefs.getInt("sube_id") ?? 0;
    final varsayilanDepoId = await VarsayilanDepoHelper.getId(token);
    final varsayilanProjeId =
        _siparis.projeid ?? await VarsayilanProjeHelper.getId(token);

    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (manuelOffline || internetYok) _offlineDraft = true;

    if (_offlineDraft) {
      if (_seciliCari == null) {
        UiFeedback.showWarning(context, "Lütfen önce cari seçiniz!");
        return;
      }
      final yeniKalemler = <SiparishareketDto>[];
      for (final line in sonuc.lines) {
        if (line.stok == null || line.stok!.Id == null) continue;
        final lineStok = line.stok!;
        final k = SiparishareketDto()
          ..depoid = varsayilanDepoId
          ..projeid = varsayilanProjeId
          ..stokid = lineStok.Id
          ..stok = StokDto(Id: lineStok.Id, Ad: lineStok.Ad, Kod: lineStok.Kod)
          ..miktar = line.quantity
          ..fiyat = 0
          ..kdvorani = 0
          ..tevkifatorani = _cariTR ? 0 : null
          ..iskontotutar = 0;
        _yeniKalemiAktifDovizeUygula(k);
        yeniKalemler.add(k);
      }
      if (mounted) {
        setState(() => _kalemler.addAll(yeniKalemler));
        _recalcToplam();
        _tabCtrl.animateTo(1);
        UiFeedback.showSuccess(
            context, "${yeniKalemler.length} kalem eklendi (offline)");
      }
      return;
    }

    if (_yeniSiparisId == null) {
      if (_seciliCari == null) {
        UiFeedback.showWarning(context, "Lütfen önce cari seçiniz!");
        return;
      }
      try {
        _yeniSiparisId =
            await _svc.saveSatisSingle(token, _siparisToDto(subeId));
      } catch (e) {
        if (mounted) UiFeedback.showError(context, "Sipariş kaydedilemedi: $e");
        return;
      }
    }
    int ok = 0, fail = 0;
    String? ilkHata;
    for (final line in sonuc.lines) {
      if (line.stok == null) continue;
      final lineStok = line.stok!;
      if (lineStok.Id == null) continue;
      StokDto? sf;
      try {
        sf = await StokService().getStokById(token, lineStok.Id!);
      } catch (_) {}
      double fiyat = 0;
      double kdvOrani = 0;
      int? olcuBrId;
      if (sf != null) {
        if (sf.Stokfiyat.isNotEmpty) {
          final eslesen =
              sf.Stokfiyat.where((f) => f.Dovizid == (_siparis.dovizid ?? 1))
                  .firstOrNull;
          final fd = eslesen ?? sf.Stokfiyat.first;
          fiyat = fd.Satisfiyat ?? 0;
        }
        final kdvRaw = sf.Kdvsatis ?? 0;
        kdvOrani = kdvRaw <= 1.0 ? kdvRaw * 100 : kdvRaw;
        final olcuList = sf.Stokolcubr;
        if (olcuList.isNotEmpty) {
          olcuBrId = olcuList.first.Olcubrid;
        } else if (sf.Temelolcubr != null) {
          olcuBrId = sf.Temelolcubr!.Id;
        }
      }
      final k = SiparishareketDto()
        ..depoid = varsayilanDepoId
        ..projeid = varsayilanProjeId
        ..stokid = lineStok.Id
        ..stok = StokDto(Id: lineStok.Id, Ad: lineStok.Ad, Kod: lineStok.Kod)
        ..miktar = line.quantity
        ..fiyat = fiyat
        ..kdvorani = kdvOrani
        ..tevkifatorani = _cariTR ? 0 : null
        ..iskontotutar = 0
        ..olcubrid = olcuBrId;
      _yeniKalemiAktifDovizeUygula(k);
      try {
        k.siparisid = _yeniSiparisId;
        final hId = await _svc.saveSatisHareket(
            token, _hareketToInsertJson(k, _yeniSiparisId!));
        if (hId != null) k.id = hId;
        if (mounted) setState(() => _kalemler.add(k));
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
      } else {
        UiFeedback.showSuccess(context, "$ok kalem eklendi");
      }
    }
  }

  Future<void> _addDirekBarkodKalem() async {
    // Handler diyalog açıkken eventleri tüketir → geçici kapat
    HardwareKeyboard.instance.removeHandler(_terminalBarkodHandler);
    String barkod = '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Barkod Gir",
            style: TextStyle(fontFamily: 'Roboto', fontSize: 15)),
        content: TextField(
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: "Barkod veya stok kodu"),
          onChanged: (v) => barkod = v,
          onSubmitted: (v) {
            barkod = v;
            Navigator.pop(ctx);
          },
        ),
        actions: [
          ErpDialogAction(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ErpDialogAction(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Ekle"),
          ),
        ],
      ),
    );
    HardwareKeyboard.instance.addHandler(_terminalBarkodHandler);
    if (barkod.trim().isNotEmpty && mounted) {
      _barkodIleStokveBulKalemAc(barkod.trim());
    }
  }

  Future<void> _addKalem() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final subeId = prefs.getInt("sube_id") ?? 0;

    final k = await showSiparisKalemForm(context,
        orderFields: true,
        stoklar: _stoklar,
        projeler: _projeler,
        depolar: _depolar,
        kdvDahil: _siparis.kdvdahil ?? false);
    if (k == null || !mounted) return;
    _yeniKalemiAktifDovizeUygula(k);

    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (manuelOffline || internetYok) _offlineDraft = true;

    if (_offlineDraft) {
      if (_seciliCari == null) {
        UiFeedback.showWarning(context, "Lütfen Önce cari seçiniz!");
        return;
      }
      if (mounted)
        setState(() {
          _kalemler.add(k);
          _recalcToplam();
          _tabCtrl.animateTo(1);
        });
      UiFeedback.showSuccess(context, "Kalem eklendi (offline)");
      return;
    }

    if (_yeniSiparisId == null) {
      if (_seciliCari == null) {
        UiFeedback.showWarning(context, "Lütfen Önce cari seçiniz!");
        return;
      }
      try {
        _yeniSiparisId =
            await _svc.saveSatisSingle(token, _siparisToDto(subeId));
      } catch (e) {
        if (mounted) UiFeedback.showError(context, "Sipariş kaydedilemedi: $e");
        return;
      }
    }

    try {
      k.siparisid = _yeniSiparisId;
      final hId = await _svc.saveSatisHareket(
          token, _hareketToInsertJson(k, _yeniSiparisId!));
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
    final res = await showSiparisKalemForm(context,
        orderFields: true,
        kalem: _kalemFormKopya(_kalemler[i]),
        stoklar: _stoklar,
        projeler: _projeler,
        depolar: _depolar,
        kdvDahil: _siparis.kdvdahil ?? false);
    if (res == null || !mounted) return;
    _yeniKalemiAktifDovizeUygula(res);
    setState(() {
      _kalemler[i] = res;
      _recalcToplam();
    });
    if (res.id != null && _yeniSiparisId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token_final") ?? "";
        await _svc.updateSatisHareket(
            token, _hareketToUpdateJson(res, _yeniSiparisId!));
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
        await _svc.deleteSatisHareket(token, k.id!);
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

  Map<String, dynamic> _siparisToDto(int subeId) => <String, dynamic>{
        "subeid": subeId,
        "cariid": _siparis.cariid,
        "dovizid": _siparis.dovizid ?? 1, // TL varsayılan
        "cariadresid": _siparis.cariadresid,
        "projeid": _siparis.projeid,
        "plasiyerid": _siparis.plasiyerid,
        "referansid": _siparis.referansid,
        "oncelik": _siparis.oncelik,
        "belgeseri": _siparis.belgeseri,
        "belgeyil": _seciliYil,
        "belgeno": _siparis.belgeno,
        "belgeserino":
            "${_siparis.belgeseri ?? ''}${_seciliYil}${_siparis.belgeno ?? ''}",
        "gibbelgeno":
            "${_siparis.belgeseri ?? ''}${_seciliYil}${_siparis.belgeno ?? ''}",
        "tarih": _siparis.tarih?.toIso8601String(),
        "fiilitarih": _siparis.fiilitarih?.toIso8601String(),
        "teslimtarihi": _siparis.teslimtarihi?.toIso8601String(),
        "kdvdahil": _siparis.kdvdahil,
        "belgeturu": _siparis.belgeturu,
        "belgetipi": _siparis.belgetipi,
        "ithalatihracattipi": _siparis.ithalatihracattipi,
        "odemesekli": _siparis.odemesekli,
        "vadegunu": _siparis.vadegunu,
        "vadetarihi": _siparis.vadetarihi?.toIso8601String(),
        "tahsilattarihi": _siparis.tahsilattarihi?.toIso8601String(),
        "doviztarih": _siparis.doviztarih?.toIso8601String(),
        "kur": _siparis.kur ?? 1.0,
        "kayityeri": _siparis.kayityeri,
        "aciklama": _siparis.aciklama,
        ..._siparis.extraNotesJson,
        "teslimattipi": _siparis.teslimattipi,
        "referansbelgeno": _siparis.referansbelgeno,
        "baglanti": _siparis.baglanti ?? false,
        "baglantituru": _siparis.baglantituru,
        "geneliskontooran": _siparis.geneliskontooran,
        "geneliskontotutar": _siparis.geneliskontotutar,
        "dovizgeneliskontotutar": _siparis.dovizgeneliskontotutar,
        // Tutarlar
        "bruttutar": _kalemler.fold(
            0.0, (s, k) => s + ((k.miktar ?? 0) * (k.fiyat ?? 0))),
        "malfazlasitutar":
            _kalemler.fold(0.0, (s, k) => s + (k.malfazlasitutar ?? 0)),
        "iskontotutar":
            _kalemler.fold(0.0, (s, k) => s + (k.iskontotutar ?? 0)),
        "aratoplam": _siparis.aratoplam ?? 0,
        "sonaratoplam": _siparis.aratoplam ?? 0,
        "netaratoplam": _siparis.aratoplam ?? 0,
        "kdvtoplam": _siparis.kdvtoplam ?? 0,
        "geneltoplam": _siparis.geneltoplam ?? 0,
        "doviztoplam": _siparis.doviztoplam,
        "tevkifattutar":
            _kalemler.fold(0.0, (s, k) => s + (k.tevkifattutar ?? 0)),
        "songeneltoplam": _siparis.geneltoplam ?? 0,
      };

  Map<String, dynamic> _hareketToInsertJson(
          SiparishareketDto k, String siparisId) =>
      <String, dynamic>{
        "siparisid": siparisId,
        "stokid": k.stokid,
        "depoid": k.depoid,
        "olcubrid": k.olcubrid,
        "olcubr2id": k.olcubr2id,
        "istisnaId": k.istisnaId,
        "stokadiaciklama": k.stokadiaciklama,
        "ekmaliyet": k.ekmaliyet,
        "dovizekmaliyet": k.dovizekmaliyet,
        "baglantikullan": k.baglantikullan ?? false,
        "baglantisiparishareketid": k.baglantisiparishareketid,
        "projeid": k.projeid,
        "miktar": k.miktar,
        "miktar2": k.miktar2,
        "fiyat": k.fiyat ?? 0,
        "dovizfiyat": k.dovizfiyat,
        "kdvorani": (k.kdvorani ?? 0) / 100,
        "tevkifatorani": k.tevkifatorani ?? 0,
        "iskontoorani1": k.iskontoorani1,
        "iskontotutari1": k.iskontotutari1,
        "doviziskontotutari1": k.doviziskontotutari1,
        "iskontoorani2": k.iskontoorani2,
        "iskontotutari2": k.iskontotutari2,
        "doviziskontotutari2": k.doviziskontotutari2,
        "iskontoorani3": k.iskontoorani3,
        "iskontotutari3": k.iskontotutari3,
        "doviziskontotutari3": k.doviziskontotutari3,
        "iskontoorani4": k.iskontoorani4,
        "iskontotutari4": k.iskontotutari4,
        "doviziskontotutari4": k.doviziskontotutari4,
        "iskontoorani5": k.iskontoorani5,
        "iskontotutari5": k.iskontotutari5,
        "doviziskontotutari5": k.doviziskontotutari5,
        "iskontoorani6": k.iskontoorani6,
        "iskontotutari6": k.iskontotutari6,
        "doviziskontotutari6": k.doviziskontotutari6,
        "malfazlasiiskonto": k.malfazlasiiskonto,
        "malfazlasitutar": k.malfazlasitutar ?? 0,
        "bruttutar": k.bruttutar ?? 0,
        "aratoplam": k.aratoplam ?? k.bruttutar ?? 0,
        "sonaratoplam": k.sonaratoplam ?? k.bruttutar ?? 0,
        "kdvmatrahi": k.kdvmatrahi ?? k.bruttutar ?? 0,
        "kdvtutar": k.kdvtutar ?? 0,
        "netaratoplam": k.netaratoplam ?? k.bruttutar ?? 0,
        "geneltoplam": k.geneltoplam ?? k.tutar ?? 0,
        "tevkifattutar": k.tevkifattutar ?? 0,
        "songeneltoplam": k.songeneltoplam ?? k.tutar ?? 0,
        "tutar": k.tutar ?? 0,
        "kur": k.kur ?? 1,
        "aciklama": k.aciklama,
        "teslimtarihi": k.teslimtarihi?.toIso8601String(),
        "stokozelliksabitid": k.stokozelliksabitid,
      };

  Map<String, dynamic> _hareketToUpdateJson(
          SiparishareketDto k, String siparisId) =>
      <String, dynamic>{
        "id": k.id,
        ..._hareketToInsertJson(k, siparisId),
      };

  Future<void> _showKaydetDialog() async {
    if (_seciliCari == null) {
      UiFeedback.showWarning(context, "Lütfen cari seçiniz!");
      return;
    }
    if (_kalemler.isEmpty) {
      UiFeedback.showWarning(context, "En az bir kalem eklemelisiniz!");
      return;
    }

    // ── Offline mod kontrolü ─────────────────────────────────────────────
    // Bu oturumda hiçbir şey online kaydedilmediyse (ilk kalemden itibaren
    // offline eklenmişse) ya da şu an offline ise, tamamını kuyruğa al.
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (_offlineDraft || manuelOffline || internetYok) {
      await _kaydetOffline(internetYok: internetYok);
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
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      shape: BoxShape.circle),
                  child: Icon(Icons.save_outlined, size: 36, color: _primary)),
              const SizedBox(height: 12),
              const Text("Sipariş Kaydet",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const SizedBox(height: 24),
              SizedBox(
                  width: double.infinity,
                  child: PermissionAction(
                      modules: [401],
                      access: Access.write,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _primary,
                            foregroundColor: _scheme.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text("Belgeyi Tamamla",
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _kaydetTamamla();
                        },
                      ))),
              const SizedBox(height: 10),
              SizedBox(
                  width: double.infinity,
                  child: PermissionAction(
                      modules: [401],
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
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        onPressed: () {
                          Navigator.pop(ctx);
                          _kaydet();
                        },
                      ))),
              const SizedBox(height: 8),
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("İptal",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          color: _scheme.onSurfaceVariant))),
            ])),
      ),
    );
  }

  Future<void> _kaydetTamamla() async {
    // pop: false — liste sayfasına ancak belge durumu da "tamamlandı" olarak
    // güncellendikten SONRA döneceğiz, aksi halde liste taslak durumuyla
    // yenilenip kullanıcı "tamamlandı" belgeyi taslak olarak görüyordu.
    await _kaydet(pop: false);
    if (!mounted) return;
    final id = _yeniSiparisId;
    if (id == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await _svc.satisBelgeDurumGuncelle(token, id, 1);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) UiFeedback.showError(context, "Tamamlama hatası: $e");
    }
  }

  Future<void> _kaydetOffline({bool internetYok = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final subeId = prefs.getInt("sube_id") ?? 0;

    final payload = {
      'headerEndpoint': '/Siparis/SaveSingle',
      'hareketEndpoint': '/Siparishareket/SaveSingle',
      'headerIdField': 'siparisid',
      'header': _siparisToDto(subeId),
      'kalemler': _kalemler.map((k) => _hareketToInsertJson(k, '')).toList(),
    };

    await OfflineService.instance.enqueue('header_hareket_full', payload);

    if (!mounted) return;
    final mesaj = internetYok
        ? "İnternet yok — belge kuyruğa alındı, bağlantı gelince gönderilecek"
        : "Belge kuyruğa eklendi — online olunca gönderilecek";
    UiFeedback.showSuccess(context, mesaj);
    Navigator.pop(context, true);
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
                    SizedBox(height: 12),
                    Text("Kaydediliyor...",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ])),
            )));
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final subeId = prefs.getInt("sube_id") ?? 0;

      if (_yeniSiparisId != null) {
        final dto = _siparisToDto(subeId);
        dto["id"] = _yeniSiparisId;
        await _svc.updateSatisSingle(token, dto);
      } else {
        _yeniSiparisId =
            await _svc.saveSatisSingle(token, _siparisToDto(subeId));
      }

      if (_yeniSiparisId != null) {
        for (final k in _kalemler.where((e) => e.id != null)) {
          await _svc.updateSatisHareket(
            token,
            _hareketToUpdateJson(k, _yeniSiparisId!),
          );
        }
      }

      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showUpdated(context, "Sipariş kaydedildi");
      if (pop) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showError(context, "Kayıt hatası: $e");
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _surface,
        appBar: ErpPageAppBar(
          context: context,
          title: Text(
              _isEditMode ? 'Satış Siparişi Düzenle' : 'Yeni Satış Siparişi',
              style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 18,
                  fontWeight: FontWeight.w700)),
          backgroundColor: _scheme.surface,
          foregroundColor: _scheme.onSurface,
          bottom: ErpAdaptiveTabs(
              context: context,
              tabBar: TabBar(
                  controller: _tabCtrl,
                  labelColor: _primary,
                  indicatorColor: _primary,
                  unselectedLabelColor: _scheme.onSurfaceVariant,
                  tabs: [
                    Tab(height: 40, text: 'Belge'),
                    Tab(height: 40, text: 'Kalemler'),
                    Tab(height: 40, text: 'Özet')
                  ])),
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabCtrl,
                children: [_ustBilgilerTab(), _kalemlerTab(), _ozetTab()]),
        bottomNavigationBar: _loading ? null : _buildBottomBar(),
      );

  Widget _buildBottomBar() => Material(
      color: _scheme.surface,
      child: SafeArea(
        child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ErpEntryActions(
                  onAdd: _addKalem,
                  onBarcode: _addDirekBarkodKalem,
                  onCamera: _kameraIleBarkodOku,
                  onManual: _addHizliBarkodKalemler),
              if (_tabCtrl.index > 0) ...[
                const SizedBox(height: 8),
                SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: PermissionAction(
                        modules: [401],
                        access: Access.write,
                        child: FilledButton.icon(
                            onPressed: _showKaydetDialog,
                            icon: const Icon(Icons.save_outlined, size: 18),
                            label: const Text('Kaydet')))),
              ],
            ])),
      ));

  Widget _ustBilgilerTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildCariSecici(),
        const SizedBox(height: 4),
        _buildSectionCard(children: [
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
                                style: const TextStyle(
                                    fontFamily: 'Roboto', fontSize: 13))))
                        .toList(),
                    onChanged: (v) async {
                      setState(() {
                        _seciliSeri = v;
                        _siparis.belgeseri = v;
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
                                style: const TextStyle(
                                    fontFamily: 'Roboto', fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() {
                          _seciliYil = v!;
                          _siparis.belgeyil = v;
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
                            onChanged: (v) => _siparis.belgeno = v,
                            style: const TextStyle(
                                fontFamily: 'Roboto', fontSize: 13),
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
          const SizedBox(height: 12),

          // 2. Belge Tipi / İth.-İhr. Tipi
          Row(children: [
            Expanded(
                child: _buildDropdown<int>(
                    label: "Belge Tipi",
                    value: _siparis.belgetipi,
                    items: LookupHelper.faturaBelgeTipleri
                        .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.ad,
                                style: const TextStyle(
                                    fontFamily: 'Roboto', fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() {
                          _siparis.belgetipi = v;
                          if (!StokHareketCouples.isIhracatTipi(v))
                            _siparis.ithalatihracattipi = null;
                        }))),
            if (StokHareketCouples.isIhracatTipi(_siparis.belgetipi)) ...[
              const SizedBox(width: 12),
              Expanded(
                  child: _buildDropdown<int>(
                      label: "İth./İhr. Tipi",
                      value: _siparis.ithalatihracattipi,
                      items: StokHareketCouples.ihracatTipleri
                          .map((e) => DropdownMenuItem(
                              value: e.value,
                              child: Text(e.text,
                                  style: const TextStyle(
                                      fontFamily: 'Roboto', fontSize: 13))))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _siparis.ithalatihracattipi = v))),
            ],
          ]),
          const SizedBox(height: 12),

          // 3. Tarih / Fiili Tarih
          Row(children: [
            Expanded(
                child:
                    _buildDateField("Tarih", _tarihCtrl, _siparis.tarih, (d) {
              setState(() {
                _siparis.tarih = d;
                _tarihCtrl.text = _fmtDate(d);
              });
              _recalcVadeTarihi();
            })),
            const SizedBox(width: 12),
            Expanded(
                child: _buildDateField(
                    "Fiili Tarih",
                    _fiiliTarihCtrl,
                    _siparis.fiilitarih,
                    (d) => setState(() {
                          _siparis.fiilitarih = d;
                          _fiiliTarihCtrl.text = _fmtDate(d);
                        }))),
          ]),
          const SizedBox(height: 12),

          // 4. Teslim Tarihi / Teslim Adresi
          Row(children: [
            Expanded(
                child: _buildDateField(
                    "Teslim Tarihi",
                    _teslimTarihCtrl,
                    _siparis.teslimtarihi,
                    (d) => setState(() {
                          _siparis.teslimtarihi = d;
                          _teslimTarihCtrl.text = _fmtDate(d);
                        }))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildDropdown<int>(
                    label: "Teslim Adresi",
                    value: _siparis.cariadresid,
                    items: _cariAdresler
                        .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.adres ?? '',
                                style: const TextStyle(
                                    fontFamily: 'Roboto', fontSize: 12),
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() {
                          _siparis.cariadresid = v;
                          _cariAdresManuelSecildi = true;
                        }))),
          ]),
          const SizedBox(height: 12),

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
                            initialValue: _siparis.vadegunu?.toString(),
                            keyboardType: TextInputType.number,
                            onChanged: (v) {
                              _siparis.vadegunu = int.tryParse(v) ?? 0;
                              _recalcVadeTarihi();
                            },
                            style: const TextStyle(
                                fontFamily: 'Roboto', fontSize: 13),
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
                    _siparis.vadetarihi,
                    (d) => setState(() {
                          _siparis.vadetarihi = d;
                          _vadeTarihCtrl.text = _fmtDate(d);
                        }))),
          ]),
          const SizedBox(height: 12),

          // 6. Ödeme Şekli / Tahsilat Tarihi
          Row(children: [
            Expanded(
                child: _buildDropdown<int>(
                    label: "Ödeme Şekli",
                    value: _siparis.odemesekli,
                    items: StokHareketCouples.odemeSekilleri
                        .map((e) => DropdownMenuItem(
                            value: e.value,
                            child: Text(e.text,
                                style: const TextStyle(
                                    fontFamily: 'Roboto', fontSize: 13))))
                        .toList(),
                    onChanged: (v) => setState(() => _siparis.odemesekli = v))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildDateField(
                    "Tahsilat Tarihi",
                    _tahsilatTarihCtrl,
                    _siparis.tahsilattarihi,
                    (d) => setState(() {
                          _siparis.tahsilattarihi = d;
                          _tahsilatTarihCtrl.text = _fmtDate(d);
                        }))),
          ]),
          const SizedBox(height: 12),

          // 7. Döviz / Döviz Tarihi
          Row(children: [
            Expanded(
                child: _buildDropdown<int>(
                    label: "Döviz",
                    value: _siparis.dovizid,
                    items: _dovizler
                        .map((e) => DropdownMenuItem(
                            value: e.Id,
                            child: Text(e.Ad ?? '',
                                style: const TextStyle(
                                    fontFamily: 'Roboto', fontSize: 13))))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _siparis.dovizid = v;
                      });
                      _kurGetir();
                    })),
            if (!_tryMi) ...[
              const SizedBox(width: 12),
              Expanded(
                  child: _buildDateField(
                      "Döviz Tarihi", _dovizTarihCtrl, _siparis.doviztarih,
                      (d) {
                setState(() {
                  _siparis.doviztarih = d;
                  _dovizTarihCtrl.text = _fmtDate(d);
                });
                _kurGetir();
              })),
            ],
          ]),
          const SizedBox(height: 12),

          // 8. Kur (tek başına)
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
                          final eskiKur = _aktifKur;
                          final n = (v - 1).clamp(0.0, double.infinity);
                          setState(() {
                            _siparis.kur = n;
                            _kurCtrl.text =
                                n.toStringAsFixed(4).replaceAll('.', ',');
                          });
                          _kurDegisiminiKalemlereUygula(eskiKur: eskiKur);
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
                      style:
                          const TextStyle(fontFamily: 'Roboto', fontSize: 13),
                      onChanged: (v) {
                        final eskiKur = _aktifKur;
                        _siparis.kur = double.tryParse(v.replaceAll(',', '.'));
                        _kurDegisiminiKalemlereUygula(eskiKur: eskiKur);
                      },
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
                        final eskiKur = _aktifKur;
                        final n = v + 1;
                        setState(() {
                          _siparis.kur = n;
                          _kurCtrl.text =
                              n.toStringAsFixed(4).replaceAll('.', ',');
                        });
                        _kurDegisiminiKalemlereUygula(eskiKur: eskiKur);
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
            const SizedBox(height: 12),
          ],

          // 8b. Referans / Açıklama
          Row(children: [
            Expanded(
                child: _buildDropdown<int>(
                    label: "Referans",
                    value: _siparis.referansid,
                    items: _referanslar
                        .map((e) => DropdownMenuItem(
                            value: e.Id,
                            child: Text("${e.Kod ?? ''} - ${e.Ad ?? ''}",
                                style: const TextStyle(
                                    fontFamily: 'Roboto', fontSize: 13),
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _siparis.referansid = v))),
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
                            _siparis.aciklama = v.isEmpty ? null : v,
                        style:
                            const TextStyle(fontFamily: 'Roboto', fontSize: 13),
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
                                fontFamily: 'Roboto',
                                color: _scheme.onSurfaceVariant,
                                fontSize: 13)),
                      )),
                ])),
          ]),
          const SizedBox(height: 12),

          // 9. Öncelik
          _buildDropdown<int>(
              label: "Öncelik",
              value: _siparis.oncelik,
              items: OncelikCouples.list
                  .map((e) => DropdownMenuItem(
                      value: e.value,
                      child: Text(e.text,
                          style: const TextStyle(
                              fontFamily: 'Roboto', fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() => _siparis.oncelik = v)),
          const SizedBox(height: 12),

          // 10. Proje / Plasiyer
          Row(children: [
            Expanded(
                child: _buildSelectorField(
              label: "Proje",
              value: _projeler
                      .where((p) => p.id == _siparis.projeid)
                      .firstOrNull
                      ?.ad ??
                  "SeÃ§iniz",
              onTap: () async {
                final res = await showErpSelector(
                    context: context,
                    title: "Proje Seç",
                    hintText: "Proje adı veya kodu",
                    items: _projeler,
                    itemText: (p) => "${p.kod ?? ''} - ${p.ad ?? ''}");
                if (res != null) setState(() => _siparis.projeid = res.id);
              },
            )),
            const SizedBox(width: 12),
            Expanded(
                child: _buildSelectorField(
              label: "Plasiyer",
              value: _plasiyerler
                      .where((p) => p.Id == _siparis.plasiyerid)
                      .firstOrNull
                      ?.Adsoyad ??
                  "Seçiniz",
              onTap: () async {
                final res = await showErpSelector(
                    context: context,
                    title: "Plasiyer Seç",
                    hintText: "Plasiyer",
                    items: _plasiyerler,
                    itemText: (p) => p.Adsoyad ?? '');
                if (res != null) setState(() => _siparis.plasiyerid = res.Id);
              },
            )),
          ]),
          const SizedBox(height: 12),

          // 10. KDV Toggle
          _buildKdvToggle(),
          CommercialDocumentFields(
              sales: true,
              quote: false,
              deliveryType: _siparis.teslimattipi,
              referenceNumber: _siparis.referansbelgeno,
              linked: _siparis.baglanti ?? false,
              linkType: _siparis.baglantituru,
              linkLocked: _yeniSiparisId != null,
              onDelivery: (v) => setState(() => _siparis.teslimattipi = v),
              onTrade: (v) => {},
              onReference: (v) =>
                  _siparis.referansbelgeno = v.trim().isEmpty ? null : v,
              onLinked: (v) => setState(() {
                    _siparis.baglanti = v;
                    _siparis.baglantituru = v ? 1 : null;
                    _siparis.belgeturu = v ? 36 : 5;
                  }),
              onLinkType: (v) => setState(() => _siparis.baglantituru = v)),
          DocumentExtraNotesButton(
              values: _siparis.extraNotes,
              onChanged: (v) => setState(() => _siparis.extraNotes = v)),
        ]),
      ],
    );
  }

  Widget _kalemlerTab() {
    if (_kalemler.isEmpty)
      return Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.inventory_2_outlined,
            size: 48, color: _scheme.outlineVariant),
        const SizedBox(height: 12),
        Text('Henüz kalem yok',
            style: TextStyle(
                fontFamily: 'Roboto', color: _scheme.onSurfaceVariant))
      ]));
    return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: _kalemler.length,
        itemBuilder: (_, i) {
          final k = _kalemler[i];
          return ErpFinanceCard(
              title: k.stok?.Ad ?? '-',
              icon: Icons.inventory_2_outlined,
              metadata: [
                if (k.stok?.Kod != null) k.stok!.Kod!,
                '${NumberFormatHelper.format(k.miktar ?? 0)} ${k.olcubr?.Ad ?? ''} × ${NumberFormatHelper.format(k.fiyat ?? 0)} ₺',
                if ((k.kdvorani ?? 0) > 0) 'KDV %${(k.kdvorani ?? 0).toInt()}'
              ],
              amount: '${NumberFormatHelper.format(k.tutar ?? 0)} ₺',
              onTap: () => _editKalem(i),
              onDelete: () => _deleteKalem(i));
        });
  }

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
    final discount = _siparis.geneliskontotutar ?? 0;
    final base = _kalemler.fold<double>(0, (s, k) => s + (k.bruttutar ?? 0));
    final factor = base > 0 ? (base - discount) / base : 1.0;
    final double genelToplam = _siparis.geneltoplam ?? 0;

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

    final bool isDoviz = (_siparis.dovizid ?? 1) != 1;
    final double kur = _siparis.kur ?? 1.0;
    final String dovizSembol =
        _dovizler.where((d) => d.Id == _siparis.dovizid).firstOrNull?.Birim ??
            '₺';

    return ListView(padding: const EdgeInsets.all(12), children: [
      OutlinedButton.icon(
          onPressed: _genelIskontoSec,
          icon: const Icon(Icons.percent_rounded, size: 18),
          label: const Text('Genel İskonto')),
      const SizedBox(height: 12),
      _buildSectionCard(children: [
        _ozetSatir('Brüt Toplam', brutToplam),
        if (satirIskontoToplam > 0)
          _ozetSatir('Satır İskontosu', satirIskontoToplam, isNeg: true),
        if (satirIskontoToplam > 0)
          _ozetSatir('Ara Toplam', araToplam, bold: true),
        if (discount > 0) _ozetSatir('Genel İskonto', discount, isNeg: true),
        if (malFazlasiToplam > 0) _ozetSatir('Mal Fazlası', malFazlasiToplam),
        ...kdvDetay.entries
            .where((e) => e.key > 0)
            .map((e) => _ozetSatir('KDV %${e.key}', e.value['kdv']! * factor)),
        if (toplamTevkifat > 0)
          _ozetSatir('Tevkifat', toplamTevkifat * factor, isNeg: true),
        Divider(height: 24, color: _scheme.outlineVariant),
        Text('Genel Toplam',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: _scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        Text('${NumberFormatHelper.format(genelToplam)} ₺',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _primary)),
        if (isDoviz)
          Text(
              '${NumberFormatHelper.format(kur > 0 ? genelToplam / kur : 0)} $dovizSembol',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: _scheme.onSurfaceVariant)),
      ]),
    ]);
  }

  Widget _ozetSatir(String label, double val,
          {bool isNeg = false, bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(children: [
          Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      color: _scheme.onSurfaceVariant,
                      fontSize: 13))),
          const SizedBox(width: 8),
          Text('${isNeg ? '-' : ''}${NumberFormatHelper.format(val)} ₺',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 13)),
        ]),
      );

  Widget _buildCariSecici() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _scheme.surface,
          borderRadius:
              BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
          border: Border.all(
              color: _seciliCari != null
                  ? _primary.withOpacity(0.25)
                  : _scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          OutlinedButton.icon(
            onPressed: _cariSec,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              side: BorderSide(color: _primary, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(Icons.business_rounded, size: 15, color: _primary),
            label: Text("Cari Seç",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: _primary,
                    fontWeight: FontWeight.w700)),
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
                                  fontFamily: 'Roboto',
                                  fontSize: 11,
                                  color: _scheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.4)),
                          const SizedBox(height: 2),
                          Text(_seciliCari!.Ad ?? '',
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                  color: _primary,
                                  fontWeight: FontWeight.w800),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2),
                        ]),
                  )
                : GestureDetector(
                    onTap: _cariSec,
                    child: Text("Cari seçilmedi",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            color: _scheme.onSurfaceVariant,
                            fontSize: 13,
                            fontStyle: FontStyle.italic)),
                  ),
          ),
        ]),
      ),
    ]);
  }

  Widget _buildKdvToggle() {
    final kdvDahil = _siparis.kdvdahil ?? false;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _inputLabel('KDV'),
      Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
            color: kdvDahil
                ? _scheme.primaryContainer
                : _scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _scheme.outlineVariant)),
        child: Row(children: [
          Expanded(
              child: Text(kdvDahil ? 'KDV Dahil' : 'KDV Hariç',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _scheme.onSurface))),
          Switch(
              value: kdvDahil,
              onChanged: (v) => setState(() => _siparis.kdvdahil = v)),
        ]),
      ),
    ]);
  }

  Widget _buildSectionCard({required List<Widget> children}) =>
      ErpDesignStyle.modern(context)
          ? ErpFormSection(children: children)
          : Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: _scheme.surface,
                  borderRadius: BorderRadius.circular(
                      ErpDesignStyle.modern(context) ? 18 : 16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
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
                fontFamily: 'Roboto',
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
                            style: const TextStyle(
                                fontFamily: 'Roboto', fontSize: 13),
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
    final safeValue = items.any((e) => e.value == value) ? value : null;
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
          items: items,
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
            color: _scheme.surface,
          ),
          child: Row(children: [
            Expanded(
                child: Text(ctrl.text.isEmpty ? 'Seçiniz' : ctrl.text,
                    style: TextStyle(
                        fontFamily: 'Roboto',
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

  Future<void> _genelIskontoSec() async {
    final rate = _isDoviz ? _aktifKur : 1.0;
    final base = _kalemler.fold<double>(0, (s, k) => s + (k.bruttutar ?? 0));
    final result = await showFaturaGenelIskontoSheet(context,
        oran: _siparis.geneliskontooran,
        tutar: (_siparis.geneliskontotutar ?? 0) / rate,
        araToplam: base / rate,
        isDoviz: _isDoviz,
        kur: rate,
        dovizId: _siparis.dovizid);
    if (result == null || !mounted) return;
    _siparis.geneliskontooran = result.oran ??
        ((result.tutar ?? 0) > 0 && base > 0
            ? result.tutar! * rate / base * 100
            : null);
    _siparis.geneliskontotutar = (result.tutar ?? 0) * rate;
    _recalcToplam();
  }
}
