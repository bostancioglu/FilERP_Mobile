import '../../../widgets/document_tracking_sheet.dart';
import '../../../models/entities/stok/document_tracking.dart';
import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:FilERP/widgets/document_action_ui.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/invoice_modern_ui.dart';
import 'package:flutter/material.dart';
import '../../../widgets/erp_ui.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/lookups.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/varsayilan_depo_helper.dart';
import '../../../helpers/plasiyer_depo_helper.dart';
import '../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../helpers/varsayilan_proje_helper.dart';
import '../../../helpers/stokhareket_couples.dart';
import '../../../models/entities/referans/referans_dto.dart';
import '../../../services/referans/referans_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../services/plasiyer/plasiyer_service.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../../models/entities/fatura/fatura_create_dto.dart';
import '../../../models/entities/fatura/fatura_update_dto.dart';
import '../../../models/entities/fatura/faturahareket_dto.dart';
import '../../../widgets/fatura/fatura_kalem_form_sheet.dart';
import '../../../widgets/erp_selector.dart';
import '../../../helpers/number_format_helper.dart';
import '../../../helpers/para_birimi_helper.dart';
import '../../../helpers/fatura_hesap_helper.dart';
import '../../../helpers/belge_turu_couples.dart';
import '../../../widgets/fatura/fatura_genel_iskonto_sheet.dart';
import '../../../services/cari/cari_service.dart';
import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/cari/cariadres_dto.dart';
import '../../../services/stok/stok_service.dart';
import '../../../models/entities/stok/stok_list_dto.dart';
import '../../../services/fatura/fatura_service.dart';
import '../../../models/entities/yonetim/belge_seri_dto.dart';
import '../../../services/yonetim/belgeseri_service.dart';
import '../../../services/yonetim/kur_service.dart';
import '../../../models/entities/stok/stok_dto.dart';
import '../../../widgets/quick_barcode_scan_sheet.dart';
import '../../../widgets/barcode_scanner_sheet.dart';
import '../../../services/offline/offline_service.dart';
import '../../finans/tahsilat/tahsilat_liste_page.dart';
import '../../finans/tahsilat/tahsilat_ekle_page.dart';
import '../../../services/yazici/bluetooth_print_service.dart';
import '../../../services/yazici/yazici_sablon_service.dart';

class FaturaEklePage extends StatefulWidget {
  final String? faturaId;
  final FaturaCreateDto? mevcutFatura;
  final List<FaturahareketDto>? mevcutKalemler;
  final List<StokListDto>?
      mevcutStoklar; // detay sayfasından geçirilirse yeniden yüklenmez

  const FaturaEklePage({
    super.key,
    this.faturaId,
    this.mevcutFatura,
    this.mevcutKalemler,
    this.mevcutStoklar,
  });

  @override
  State<FaturaEklePage> createState() => _FaturaEklePageState();
}

class _FaturaEklePageState extends State<FaturaEklePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _tarihCtrl;
  late TextEditingController _fiiliTarihCtrl;
  late TextEditingController _teslimTarihCtrl;
  late TextEditingController _tahsilatTarihCtrl;

  late FaturaCreateDto fatura;
  late List<FaturahareketDto> kalemler;

  bool get _isEditMode => widget.faturaId != null;

  // Stil Renkleri
  bool get _modern => ErpDesignStyle.modern(context);
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get primaryColor => _scheme.onSurface;
  Color get accentColor => _scheme.primary;

  List<DovizDto> dovizler = [];
  List<ProjeDto> projeler = [];
  List<PlasiyerDto> plasiyerler = [];
  List<CariDtoLite> cariler = [];
  CariDtoLite? seciliCari;
  List<StokListDto> stoklar = [];

  List<BelgeSeriDto> belgeSeriListesi = [];
  String? seciliSeri;
  late TextEditingController belgeNoController;
  late TextEditingController _vadeTarihCtrl;
  late TextEditingController _vadegununCtrl;
  late TextEditingController _kurCtrl;
  late TextEditingController _dovizTarihCtrl;
  List<ReferansDto> referanslar = [];
  List<CariadresDto> cariAdresler = [];
  bool _cariAdresManuelSecildi = false;
  bool _cariTR =
      true; // Seçili carinin TR olup olmadığı — full cariden güncellenir
  late List<TextEditingController> _aciklamaCtrlList;
  late TextEditingController _aciklamaCtrl;

  List<int> yilListesi = [];
  int seciliYil = DateTime.now().year;
  double? genelIskontoOrani = 0;
  double? genelIskontoTutari = 0;

  // Yeni fatura modunda ilk kalem eklenince faturaId buraya atanır
  String? _yeniFaturaId;

  // Bu oturumda offline (kuyruk) moduna en az bir kez düşüldüyse true olur.
  // Bir kez offline'a düşülünce, bağlantı geri gelse bile bu belge için
  // offline akış sürdürülür — yarısı online yarısı kuyrukta kalmasın diye.
  bool _offlineDraft = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);

    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) setState(() {});
    });

    final now = DateTime.now();
    yilListesi = List.generate(5, (i) => now.year - i);

    // Düzenleme modu: mevcut fatura verilerini yükle
    if (_isEditMode && widget.mevcutFatura != null) {
      fatura = widget.mevcutFatura!;
      kalemler = widget.mevcutKalemler ?? [];
      seciliYil = fatura.belgeyil ?? now.year;
      seciliSeri = fatura.belgeseri;
      genelIskontoOrani = fatura.geneliskontooran ?? 0;
      genelIskontoTutari = fatura.geneliskontotutar ?? 0;
    } else {
      // Yeni fatura modu
      fatura = FaturaCreateDto();
      kalemler = [];
      fatura.tarih = now;
      fatura.fiilitarih = now;
      fatura.teslimtarihi = now;
      fatura.tahsilattarihi = now;
      fatura.belgeyil = now.year;
      fatura.kdvdahil = true;
      fatura.belgeturu = BelgeTuruCouples.satisFaturasi;
      fatura.vadegunu = 0;
      fatura.vadetarihi = now;
      seciliYil = now.year;
    }

    final nowStr =
        "${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}";
    belgeNoController =
        TextEditingController(text: fatura.belgeno ?? "000000001");
    _tarihCtrl = TextEditingController(
        text: fatura.tarih != null ? _formatDate(fatura.tarih!) : nowStr);
    _fiiliTarihCtrl = TextEditingController(
        text: fatura.fiilitarih != null
            ? _formatDate(fatura.fiilitarih!)
            : nowStr);
    _teslimTarihCtrl = TextEditingController(
        text: fatura.teslimtarihi != null
            ? _formatDate(fatura.teslimtarihi!)
            : nowStr);
    _tahsilatTarihCtrl = TextEditingController(
        text: fatura.tahsilattarihi != null
            ? _formatDate(fatura.tahsilattarihi!)
            : nowStr);
    _vadegununCtrl =
        TextEditingController(text: (fatura.vadegunu ?? 0).toString());
    _vadeTarihCtrl = TextEditingController(
        text: fatura.vadetarihi != null
            ? _formatDate(fatura.vadetarihi!)
            : nowStr);
    _kurCtrl = TextEditingController(
        text: fatura.kur != null ? fatura.kur.toString() : '');
    _dovizTarihCtrl = TextEditingController(
        text: fatura.doviztarih != null
            ? _formatDate(fatura.doviztarih!)
            : nowStr);
    _aciklamaCtrl = TextEditingController(text: fatura.aciklama ?? '');
    _aciklamaCtrlList = List.generate(
        20, (i) => TextEditingController(text: _getAciklamaField(i + 1) ?? ''));

    _loadLookups();
  }

  @override
  void dispose() {
    _tarihCtrl.dispose();
    _fiiliTarihCtrl.dispose();
    _teslimTarihCtrl.dispose();
    _tahsilatTarihCtrl.dispose();
    _tabController.dispose();
    belgeNoController.dispose();
    _vadegununCtrl.dispose();
    _vadeTarihCtrl.dispose();
    _kurCtrl.dispose();
    _dovizTarihCtrl.dispose();
    _aciklamaCtrl.dispose();
    for (final c in _aciklamaCtrlList) c.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    dovizler = await DovizService().getDovizler(token);
    projeler = (await ProjeService().getProjeList(token))
        .where((p) => p.tur == 3)
        .toList()
      ..sort((a, b) => (a.kod ?? '').compareTo(b.kod ?? ''));
    plasiyerler = await PlasiyerService().getPlasiyerler(token);
    stoklar = widget.mevcutStoklar ?? await StokService().getStokList(token);
    cariler = await CariService().getCariler(token);
    belgeSeriListesi =
        await BelgeSeriService().getAll(token, BelgeTuruCouples.satisFaturasi);
    referanslar = (await ReferansService().getAll(token))
      ..sort((a, b) => (a.Kod ?? '').compareTo(b.Kod ?? ''));
    if (referanslar.isNotEmpty) fatura.referansid ??= referanslar.first.Id;

    if (dovizler.isNotEmpty) fatura.dovizid ??= _tlDovizId;
    if (projeler.isNotEmpty)
      fatura.projeid ??= await VarsayilanProjeHelper.pickFrom(projeler);
    _kp = await KullaniciPlasiyerHelper.getir();
    if (_kp.kilitli) {
      fatura.plasiyerid ??= _kp.plasiyerid;
      _plasiyerDepoId =
          await PlasiyerDepoHelper.getId(token, _kp.plasiyerid, kilitli: true);
    } else if (plasiyerler.isNotEmpty) {
      fatura.plasiyerid ??= plasiyerler.first.Id;
    }

    if (belgeSeriListesi.isNotEmpty && !_isEditMode) {
      seciliSeri = belgeSeriListesi.first.seri;
      fatura.belgeseri = seciliSeri;
      fatura.ebelgetip = belgeSeriListesi.first.ebelgetip ?? 0;
    } else if (_isEditMode && seciliSeri != null) {
      fatura.belgeseri = seciliSeri;
      // Düzenleme modunda mevcut serinin ebelgetip'ini bul
      final seri =
          belgeSeriListesi.where((e) => e.seri == seciliSeri).firstOrNull;
      fatura.ebelgetip ??= seri?.ebelgetip ?? 0;
    } else if (belgeSeriListesi.isNotEmpty) {
      seciliSeri ??= belgeSeriListesi.first.seri;
      fatura.ebelgetip ??= belgeSeriListesi.first.ebelgetip ?? 0;
    }

    fatura.belgetipi ??= LookupHelper.faturaBelgeTipleri.first.id;

    // Yeni fatura modunda belge no çek, düzenleme modunda mevcut no korunur
    if (!_isEditMode) await _fetchYeniFaturaNo(token);

    // Düzenleme modunda cari listeden seçili cariyi bul ve göster
    if (_isEditMode && fatura.cariid != null) {
      try {
        seciliCari = cariler.firstWhere((c) => c.Id == fatura.cariid);
      } catch (_) {}
    }

    // Düzenleme modunda döviz TL dışındaysa ve kur yoksa çek
    if (_isEditMode && fatura.dovizid != null) {
      final tlId = dovizler.isNotEmpty ? dovizler.first.Id : 1;
      if (fatura.dovizid != tlId && (fatura.kur == null || fatura.kur == 0)) {
        await _fetchKurByDoviz(fatura.dovizid!);
      } else {
        // Kur varsa controller'a yaz
        if (fatura.kur != null) {
          _kurCtrl.text = fatura.kur!.toStringAsFixed(4);
        }
      }
    }

    setState(() {});
  }

  Future<void> _fetchYeniFaturaNo([String? tokenOverride]) async {
    if (seciliSeri == null) return;
    final prefs = await SharedPreferences.getInstance();
    final token = tokenOverride ?? prefs.getString("token_final") ?? "";
    try {
      final no =
          await FaturaService().getNewFaturaNo(token, seciliSeri!, seciliYil);
      setState(() {
        fatura.belgeno = no;
        belgeNoController.text = no;
      });
    } catch (e) {
      debugPrint("BelgeNo alınamadı: $e");
    }
  }

  Future<void> _loadCariVadegunu(int cariId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final cariFull = await CariService().getCariFullById(token, cariId);
      final vg = cariFull.Vadegunu ?? 0;
      debugPrint("CariFull Vadegunu: $vg");
      final varsayilanProjeId = await VarsayilanProjeHelper.pickFrom(projeler);
      if (!mounted) return;
      setState(() {
        fatura.vadegunu = vg;
        _vadegununCtrl.text = vg.toString();
        _recalcVadeTarihi();

        // 1 - Plasiyer: cari kartındaki, yoksa listedeki ilk plasiyer
        fatura.plasiyerid = _kp.kilitli
            ? (fatura.plasiyerid ?? _kp.plasiyerid)
            : (cariFull.Plasiyerid ??
                plasiyerler.where((p) => p.Id != null).firstOrNull?.Id);
        // Proje: varsayılan proje
        if (varsayilanProjeId != null) fatura.projeid = varsayilanProjeId;

        // 2 - Döviz: CariFull'de dolu ise otomatik seç
        if (cariFull.Dovizid != null) {
          fatura.dovizid = cariFull.Dovizid;
        }

        // 3 - Ülke kontrolü: full DTO'dan (lite'da Ulkeid gelmeyebilir)
        final trCari = cariFull.Ulkeid == null || cariFull.Ulkeid == 1;
        _cariTR = trCari;
        if (trCari) {
          fatura.belgetipi = 1; // Açık
        } else {
          final isSatis = fatura.belgeturu == BelgeTuruCouples.satisFaturasi;
          fatura.belgetipi = isSatis ? 6 : 5; // 6=İhracat, 5=İthalat
          // Yabancı cari → mevcut kalemlerin tevkifatını sıfırla
          for (final k in kalemler) {
            k.tevkifatorani = null;
          }
        }
      });

      // Döviz TL dışındaysa kur çek
      if (cariFull.Dovizid != null) {
        await _fetchKurByDoviz(cariFull.Dovizid!);
      }

      // 3 - Cari adres: listeyi çek, ilkini teslim adresi olarak seç
      try {
        final adresler = await CariService().getCariAdres(token, cariId);
        if (adresler.isNotEmpty && mounted) {
          setState(() {
            cariAdresler = adresler;
            // Otomatik adres seçimi yok — kullanıcı isterse dropdown'dan seçer
            // (Düzenleme modunda cariadresid zaten mevcut faturadan gelir)
          });
        }
      } catch (e) {
        debugPrint("Cari adres alınamadı: $e");
      }
    } catch (e) {
      debugPrint("CariFull vadegunu alınamadı: $e");
    }
  }

  // --- HESAPLAMA MANTIKLARI ---

  // TRY (TL) tespiti: Birim TL / TRY / ₺
  bool _isTryId(int? id) {
    if (id == null) return true;
    final d = dovizler.where((x) => x.Id == id).firstOrNull;
    if (d == null) return id == (dovizler.isNotEmpty ? dovizler.first.Id : 1);
    final b = (d.Birim ?? '').trim().toUpperCase();
    return b == 'TL' || b == 'TRY' || b == '₺';
  }

  bool get _tryMi => _isTryId(fatura.dovizid);
  int? get _tlDovizId => (dovizler.where((x) => _isTryId(x.Id)).firstOrNull ??
          (dovizler.isNotEmpty ? dovizler.first : null))
      ?.Id;

  // Döviz değişince günün kurunu çek
  Future<void> _fetchKurByDoviz(int dovizId) async {
    // TL ise kur 1, temizle
    if (_isTryId(dovizId)) {
      setState(() {
        fatura.kur = null;
        _kurCtrl.text = '';
      });
      return;
    }
    final tarih = fatura.doviztarih ?? fatura.tarih ?? DateTime.now();
    setState(() {
      fatura.doviztarih = tarih;
      _dovizTarihCtrl.text = _formatDate(tarih);
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
          fatura.kur = yeniKur;
          _kurCtrl.text = yeniKur.toStringAsFixed(4);
        });
      }
    } catch (e) {
      debugPrint("Kur alınamadı: $e");
    }
  }

  void _recalcVadeTarihi() {
    final tarih = fatura.tarih ?? DateTime.now();
    final vg = fatura.vadegunu ?? 0;
    final vadeTarihi = tarih.add(Duration(days: vg));
    fatura.vadetarihi = vadeTarihi;
    _vadeTarihCtrl.text = _formatDate(vadeTarihi);
  }

  void _recalcFaturaToplam() {
    final sonuc = FaturaHesapHelper.hesaplaFaturaToplam(
      kalemler: kalemler
          .map((k) => KalemTutar(
                bruttutar: k.bruttutar ?? 0,
                kdvtutar: k.kdvtutar ?? 0,
                tevkifattutar: k.tevkifattutar,
              ))
          .toList(),
      genelIskontoOrani: genelIskontoOrani,
      genelIskontoTutar: genelIskontoTutari,
    );

    fatura.aratoplam = sonuc.aratoplam;
    fatura.kdvtoplam = sonuc.kdvtoplam;
    fatura.geneltoplam = sonuc.geneltoplam;
    // Genel iskonto tutarı varsa kaydet
    if (sonuc.iskontotutar > 0) fatura.geneliskontotutar = sonuc.iskontotutar;

    setState(() {});
  }

  void _recalcAllKalemler() {
    final kdvDahil = fatura.kdvdahil ?? true;
    for (final k in kalemler) {
      final sonuc = FaturaHesapHelper.hesaplaKalem(
        miktar: k.miktar ?? 0,
        fiyat: k.fiyat ?? 0,
        iskontoTutar: k.iskontotutar ?? 0,
        kdvOrani: k.kdvorani ?? 0,
        tevkifatOrani: k.tevkifatorani ?? 0,
        kdvDahil: kdvDahil,
        malFazlasiAdet: k.malfazlasiiskonto ?? 0,
      );
      k.bruttutar = sonuc.bruttutar;
      k.kdvtutar = sonuc.kdvtutar;
      k.tevkifatmatrahi = sonuc.tevkifatmatrahi;
      k.tevkifattutar = sonuc.tevkifattutar;
      k.tutar = sonuc.tutar;
    }
    _recalcFaturaToplam();
  }

  // --- AKSİYON METODLARI ---
  void _editKalem(int i) async {
    final res = await showFaturaKalemForm(context,
        kalem: kalemler[i],
        kdvDahil: fatura.kdvdahil ?? true,
        dovizId: fatura.dovizid,
        kur: fatura.kur,
        stoklar: stoklar,
        cariTR: _cariTR,
        bakiyeUyar: true);
    if (res == null) return;

    // Teslim tarihi faturadan al
    res.teslimtarihi ??= fatura.teslimtarihi;
    // Döviz alanlarını doldur
    _prepareDovizHareket(res);

    setState(() {
      kalemler[i] = res;
      _recalcFaturaToplam();
    });

    // Sadece id varsa API'ye gönder — id yoksa kalem DB'de var ama response'dan alınamadı
    if (res.id != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token_final") ?? "";
        res.faturaid = _isEditMode ? widget.faturaId : _yeniFaturaId;
        await FaturaService().saveOrUpdateRow(token, res);
        if (!mounted) return;
        UiFeedback.showUpdated(context, "Kalem güncellendi");
      } catch (e) {
        if (!mounted) return;
        UiFeedback.showException(context, e);
      }
    } else {
      // id yok — fatura kaydedilince id gelecek, şimdilik sadece local güncelleme
      UiFeedback.showUpdated(
          context, "Kalem güncellendi (kaydet'e basınca DB'ye yazılır)");
    }
  }

  void _removeKalem(int i) {
    setState(() {
      kalemler.removeAt(i);
      _recalcFaturaToplam();
    });
  }

  // Fatura alanlarını hesaplayıp fatura nesnesine yazar (kayıt öncesi çağrılır)
  double? _dovizGenelIskontoTutar;
  double? _dovizToplam;

  void _prepareFaturaFields() {
    final bool isDoviz = (fatura.dovizid != null && fatura.dovizid != 1);
    final double kur = fatura.kur ?? 1.0;

    fatura.geneliskontooran =
        (genelIskontoOrani ?? 0) > 0 ? genelIskontoOrani : null;
    fatura.geneliskontotutar =
        (genelIskontoTutari ?? 0) > 0 ? genelIskontoTutari : null;

    // Döviz tarihi: dövizli işlemde tarih ile aynı
    if (isDoviz && fatura.doviztarih == null) {
      fatura.doviztarih = fatura.tarih;
    }

    // bruttutar, satır iskontosu, mal fazlası topla
    double brutTutar = 0, satirIskontoTutar = 0, malFazlasiTutar = 0;
    for (final k in kalemler) {
      final miktar = k.miktar ?? 0;
      final fiyat = k.fiyat ?? 0;
      brutTutar += miktar * fiyat;
      satirIskontoTutar += k.iskontotutar ?? 0;
      malFazlasiTutar += (k.malfazlasiiskonto ?? 0) * fiyat;
    }
    fatura.bruttutar = brutTutar;
    fatura.iskontotutar = satirIskontoTutar;
    fatura.malfazlasitutar = malFazlasiTutar > 0 ? malFazlasiTutar : null;

    // Toplamları yeniden hesapla
    _recalcFaturaToplam();

    // Dövizli işlemlerde doviztoplam ve dovizgeneliskontotutar hesapla
    _dovizGenelIskontoTutar = null;
    _dovizToplam = null;
    if (isDoviz && kur > 0) {
      // doviztoplam = TL geneltoplam / kur
      _dovizToplam = (fatura.geneltoplam ?? 0) / kur;
      fatura.doviztoplam = _dovizToplam;

      // dovizgeneliskontotutar — her zaman taze hesapla
      if ((genelIskontoOrani ?? 0) > 0) {
        // _openIskonto ile aynı mantık: dovizfiyat varsa kullan, yoksa fiyat/kur
        final dovizAraToplam = kalemler.fold(0.0, (s, k) {
          final birimFiyat =
              (k.dovizfiyat ?? 0) > 0 ? k.dovizfiyat! : (k.fiyat ?? 0) / kur;
          final satirIsk = (k.iskontotutar ?? 0) / kur;
          return s + (k.miktar ?? 0) * birimFiyat - satirIsk;
        });
        _dovizGenelIskontoTutar = dovizAraToplam * (genelIskontoOrani! / 100);
        fatura.dovizgeneliskontotutar = _dovizGenelIskontoTutar;
      } else if (fatura.dovizgeneliskontotutar != null &&
          fatura.dovizgeneliskontotutar! > 0) {
        _dovizGenelIskontoTutar = fatura.dovizgeneliskontotutar;
      } else if ((genelIskontoTutari ?? 0) > 0) {
        _dovizGenelIskontoTutar = genelIskontoTutari! / kur;
        fatura.dovizgeneliskontotutar = _dovizGenelIskontoTutar;
      } else {
        _dovizGenelIskontoTutar = null;
        fatura.dovizgeneliskontotutar = null;
      }
    }

    fatura.gibbelgeno =
        "${fatura.belgeseri ?? ''}${fatura.belgeyil ?? ''}${fatura.belgeno ?? ''}";
  }

  Future<void> _saveFatura({bool pop = true}) async {
    _prepareFaturaFields();
    _showMiniLoading(
        _isEditMode ? "Fatura güncelleniyor..." : "Fatura güncelleniyor...");

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final svc = FaturaService();

      // Her iki modda da sadece üst bilgiyi güncelle
      // Yeni modda: _yeniFaturaId zaten var (ilk kalem eklenince oluşturuldu)
      // Edit modda: widget.faturaId var
      final faturaId = _isEditMode ? widget.faturaId! : _yeniFaturaId!;
      final updateDto = FaturaUpdateDto(id: faturaId)
        ..cariid = fatura.cariid
        ..cariadresid = fatura.cariadresid
        ..plasiyerid = fatura.plasiyerid
        ..dovizid = fatura.dovizid
        ..projeid = fatura.projeid
        ..referansid = fatura.referansid
        ..subeid = fatura.subeid
        ..belgeseri = fatura.belgeseri
        ..belgeyil = fatura.belgeyil
        ..belgeno = fatura.belgeno
        ..belgeserino = fatura.belgeserino
        ..gibbelgeno = fatura.gibbelgeno
        ..ebelgetip = fatura.ebelgetip
        ..tarih = fatura.tarih
        ..fiilitarih = fatura.fiilitarih
        ..teslimtarihi = fatura.teslimtarihi
        ..tahsilattarihi = fatura.tahsilattarihi
        ..vadetarihi = fatura.vadetarihi
        ..vadegunu = fatura.vadegunu
        ..belgetipi = fatura.belgetipi
        ..ithalatihracattipi = fatura.ithalatihracattipi
        ..odemesekli = fatura.odemesekli
        ..doviztarih = fatura.doviztarih
        ..kur = fatura.kur
        ..kdvdahil = fatura.kdvdahil
        ..belgeturu = fatura.belgeturu
        ..geneliskontooran = fatura.geneliskontooran
        ..geneliskontotutar = fatura.geneliskontotutar
        ..dovizgeneliskontotutar = fatura.dovizgeneliskontotutar
        ..bruttutar = fatura.bruttutar
        ..iskontotutar = fatura.iskontotutar
        ..malfazlasitutar = fatura.malfazlasitutar
        ..aratoplam = fatura.aratoplam
        ..kdvtoplam = fatura.kdvtoplam
        ..geneltoplam = fatura.geneltoplam
        ..doviztoplam = _dovizToplam
        ..aciklama = fatura.aciklama;
      await svc.updateSingle(token, updateDto);

      if (!mounted) return;
      Navigator.of(context).pop(); // loading kapat
      await _showResultDialog(success: true, faturaId: faturaId);
      if (!mounted) return;
      if (pop) Navigator.of(context).pop(faturaId);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      await _showResultDialog(success: false, errorMessage: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(_isEditMode ? "Fatura Düzenle" : "Fatura Ekle",
            style: TextStyle(
                color: _modern ? Colors.white : _scheme.onSurface,
                fontSize: _modern ? 18 : 20,
                fontWeight: FontWeight.w700)),
        backgroundColor: _modern ? const Color(0xFF14213D) : _scheme.surface,
        foregroundColor: _modern ? Colors.white : _scheme.onSurface,
        elevation: 0,
        toolbarHeight: 56,
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded, size: 20),
            tooltip: "Faturayı Yazdır",
            onPressed: () {
              final faturaId = _isEditMode ? widget.faturaId : _yeniFaturaId;
              if (faturaId == null) {
                UiFeedback.showWarning(context, "Önce faturayı kaydedin.");
                return;
              }
              if (kalemler.isEmpty) {
                UiFeedback.showWarning(context, "Yazdırılacak kalem yok.");
                return;
              }
              _yazdirFatura(faturaId);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // TabBar
          if (_modern)
            InvoiceEntryHeader(
                controller: _tabController, lines: kalemler.length)
          else
            Container(
              color: _scheme.surface,
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                indicator: BoxDecoration(
                    color: accentColor.withValues(alpha: .08),
                    borderRadius: BorderRadius.circular(14)),
                labelColor: accentColor,
                unselectedLabelColor: _scheme.onSurfaceVariant,
                indicatorColor: accentColor,
                indicatorWeight: 3,
                labelStyle:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                unselectedLabelStyle: const TextStyle(
                    fontWeight: FontWeight.normal, fontSize: 12),
                tabs: [
                  Tab(
                    height: 48,
                    icon: Icon(Icons.info_outline,
                        size: 16,
                        color: _tabController.index == 0
                            ? accentColor
                            : _scheme.onSurfaceVariant),
                    text: "Üst Bilgiler",
                    iconMargin: const EdgeInsets.only(bottom: 1),
                  ),
                  Tab(
                    height: 48,
                    icon: Icon(Icons.list_alt,
                        size: 16,
                        color: _tabController.index == 1
                            ? accentColor
                            : _scheme.onSurfaceVariant),
                    text: "Kalemler",
                    iconMargin: const EdgeInsets.only(bottom: 1),
                  ),
                  Tab(
                    height: 48,
                    icon: Icon(Icons.calculate_outlined,
                        size: 16,
                        color: _tabController.index == 2
                            ? accentColor
                            : _scheme.onSurfaceVariant),
                    text: "Özet",
                    iconMargin: const EdgeInsets.only(bottom: 1),
                  ),
                ],
              ),
            ),
          Expanded(
              child: TabBarView(controller: _tabController, children: [
            _ustBilgilerTab(),
            _kalemlerTab(),
            _ozetVeAciklamaTab()
          ])),
          AnimatedBuilder(
            animation: _tabController,
            builder: (context, _) => _bottomSummaryAndSave(),
          ),
        ],
      ),
    );
  }

  // --- TAB TASARIMLARI ---
  Widget _ustBilgilerTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildCariSelector(),
        const SizedBox(height: 12),
        _buildSectionCard(
          title: _modern ? 'Belge Bilgileri' : null,
          icon: _modern ? Icons.receipt_long_outlined : null,
          children: [
            // 1. Sıra: Seri - Yıl - Belge No
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    flex: 2,
                    child: _buildDropdown<String>(
                      label: "Seri",
                      value: seciliSeri,
                      items: belgeSeriListesi
                          .map((e) => DropdownMenuItem(
                              value: e.seri,
                              child: Text(e.seri ?? "",
                                  style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          seciliSeri = v;
                          fatura.belgeseri = v;
                          final seri = belgeSeriListesi
                              .where((e) => e.seri == v)
                              .firstOrNull;
                          fatura.ebelgetip = seri?.ebelgetip ?? 0;
                        });
                        _fetchYeniFaturaNo();
                      },
                    )),
                const SizedBox(width: 8),
                Expanded(
                    flex: 3,
                    child: _buildDropdown<int>(
                      label: "Yıl",
                      value: seciliYil,
                      items: yilListesi
                          .map((e) => DropdownMenuItem(
                              value: e,
                              child: Text(e.toString(),
                                  style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) {
                        setState(() {
                          seciliYil = v!;
                          fatura.belgeyil = v;
                        });
                        _fetchYeniFaturaNo();
                      },
                    )),
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
                              controller: belgeNoController,
                              inputFormatters: [
                                LengthLimitingTextInputFormatter(9)
                              ],
                              onChanged: (v) => fatura.belgeno = v,
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
                                        color: _scheme.outlineVariant)),
                              ),
                            )),
                      ],
                    )),
              ],
            ),
            const SizedBox(height: 10),

            // 2. Sıra: Belge Tipi (tam genişlik) + koşullu İth./İhr. Tipi
            Row(
              children: [
                Expanded(
                    child: _buildDropdown<int>(
                  label: "Belge Tipi",
                  value: fatura.belgetipi,
                  items: LookupHelper.faturaBelgeTipleri
                      .map((e) => DropdownMenuItem(
                          value: e.id,
                          child:
                              Text(e.ad, style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setState(() {
                    fatura.belgetipi = v;
                    if (!StokHareketCouples.isIhracatTipi(v))
                      fatura.ithalatihracattipi = null;
                  }),
                )),
                if (StokHareketCouples.isIhracatTipi(fatura.belgetipi)) ...[
                  const SizedBox(width: 12),
                  Expanded(
                      child: _buildDropdown<int>(
                    label: "İth./İhr. Tipi *",
                    value: fatura.ithalatihracattipi,
                    items: StokHareketCouples.ihracatTipleri
                        .map((e) => DropdownMenuItem(
                            value: e.value,
                            child: Text(e.text,
                                style: const TextStyle(fontSize: 13))))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => fatura.ithalatihracattipi = v),
                  )),
                ],
              ],
            ),
            const SizedBox(height: 10),

            // 3. Sıra: Tarih - Fiili Tarih
            Row(
              children: [
                Expanded(
                    child: _buildGenericDateField(
                  label: "Tarih",
                  icon: Icons.receipt_outlined,
                  controller: _tarihCtrl,
                  currentDate: fatura.tarih,
                  onPicked: (d) => setState(() {
                    fatura.tarih = d;
                    _tarihCtrl.text = _formatDate(d);
                    _recalcVadeTarihi();
                  }),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildGenericDateField(
                  label: "Fiili Tarih",
                  icon: Icons.event_available_outlined,
                  controller: _fiiliTarihCtrl,
                  currentDate: fatura.fiilitarih,
                  onPicked: (d) => setState(() {
                    fatura.fiilitarih = d;
                    _fiiliTarihCtrl.text = _formatDate(d);
                  }),
                )),
              ],
            ),
            const SizedBox(height: 10),

            // 4. Sıra: Teslim Tarihi - Teslim Adresi
            Row(
              children: [
                Expanded(
                    child: _buildGenericDateField(
                  label: "Teslim Tarihi",
                  icon: Icons.local_shipping_outlined,
                  controller: _teslimTarihCtrl,
                  currentDate: fatura.teslimtarihi,
                  onPicked: (d) => setState(() {
                    fatura.teslimtarihi = d;
                    _teslimTarihCtrl.text = _formatDate(d);
                  }),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDropdown<int>(
                  label: "Teslim Adresi",
                  value: fatura.cariadresid,
                  items: cariAdresler
                      .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.adres ?? '',
                                style: const TextStyle(fontSize: 12),
                                overflow: TextOverflow.ellipsis),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() {
                    fatura.cariadresid = v;
                    _cariAdresManuelSecildi = true;
                  }),
                )),
              ],
            ),
            const SizedBox(height: 10),

            // 5. Sıra: Vade Günü - Vade Tarihi
            _buildVadeRow(),
            const SizedBox(height: 10),

            // 6. Sıra: Tahsilat Tarihi - Ödeme Şekli
            Row(
              children: [
                Expanded(
                    child: _buildGenericDateField(
                  label: "Tahsilat Tarihi",
                  icon: Icons.payments_outlined,
                  controller: _tahsilatTarihCtrl,
                  currentDate: fatura.tahsilattarihi,
                  onPicked: (d) => setState(() {
                    fatura.tahsilattarihi = d;
                    _tahsilatTarihCtrl.text = _formatDate(d);
                  }),
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildDropdown<int>(
                  label: "Ödeme Şekli",
                  value: fatura.odemesekli,
                  items: StokHareketCouples.odemeSekilleri
                      .map((e) => DropdownMenuItem(
                          value: e.value,
                          child: Text(e.text,
                              style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setState(() => fatura.odemesekli = v),
                )),
              ],
            ),
            const SizedBox(height: 10),

            // 7. Sıra: Döviz - KDV Dahil/Hariç (yan yana)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                    flex: 2,
                    child: _buildDropdown<int>(
                      label: "Döviz",
                      value: fatura.dovizid,
                      items: dovizler
                          .map((e) => DropdownMenuItem(
                              value: e.Id,
                              child: Text(e.Ad ?? "",
                                  style: const TextStyle(fontSize: 13))))
                          .toList(),
                      onChanged: (v) {
                        setState(() => fatura.dovizid = v);
                        if (v != null) _fetchKurByDoviz(v);
                      },
                    )),
                const SizedBox(width: 12),
                Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _inputLabel("KDV"),
                        GestureDetector(
                          onTap: () => setState(() {
                            fatura.kdvdahil = !(fatura.kdvdahil ?? true);
                            _recalcAllKalemler();
                          }),
                          child: Container(
                            height: 45,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: (fatura.kdvdahil ?? true)
                                  ? Colors.green.shade50
                                  : Colors.orange.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: (fatura.kdvdahil ?? true)
                                      ? Colors.green.shade300
                                      : Colors.orange.shade300),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                    child: Text(
                                  (fatura.kdvdahil ?? true) ? "Dahil" : "Hariç",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: (fatura.kdvdahil ?? true)
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700),
                                )),
                                SizedBox(
                                    width: 38,
                                    height: 32,
                                    child: FittedBox(
                                      child: Switch(
                                        value: fatura.kdvdahil ?? true,
                                        activeColor: Colors.green.shade600,
                                        inactiveThumbColor:
                                            Colors.orange.shade600,
                                        inactiveTrackColor:
                                            Colors.orange.shade200,
                                        onChanged: (v) => setState(() {
                                          fatura.kdvdahil = v;
                                          _recalcAllKalemler();
                                        }),
                                      ),
                                    )),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )),
              ],
            ),
            const SizedBox(height: 10),

            // 8. Sıra: Döviz Tarihi - Kur (yalnız dövizli)
            if (!_tryMi) ...[
              Row(
                children: [
                  Expanded(
                      child: _buildGenericDateField(
                    label: "Döviz Tarihi",
                    icon: Icons.currency_exchange_outlined,
                    controller: _dovizTarihCtrl,
                    currentDate: fatura.doviztarih,
                    onPicked: (d) {
                      setState(() {
                        fatura.doviztarih = d;
                        _dovizTarihCtrl.text = _formatDate(d);
                      });
                      if (fatura.dovizid != null)
                        _fetchKurByDoviz(fatura.dovizid!);
                    },
                  )),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _inputLabel("Kur"),
                      SizedBox(
                          height: 45,
                          child: Row(
                            children: [
                              InkWell(
                                onTap: () {
                                  final v = double.tryParse(_kurCtrl.text) ?? 0;
                                  if (v > 0) {
                                    final n = (v - 1).clamp(0, double.infinity);
                                    setState(() {
                                      fatura.kur =
                                          double.parse(n.toStringAsFixed(4));
                                      _kurCtrl.text =
                                          fatura.kur!.toStringAsFixed(4);
                                    });
                                  }
                                },
                                child: Container(
                                    width: 36,
                                    height: 45,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: _scheme.outlineVariant),
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                                left: Radius.circular(8))),
                                    child: const Icon(Icons.remove,
                                        size: 16, color: Colors.grey)),
                              ),
                              Expanded(
                                  child: TextFormField(
                                controller: _kurCtrl,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                        decimal: true),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 13),
                                decoration: InputDecoration(
                                    isDense: true,
                                    contentPadding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    border: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide: BorderSide(
                                            color: _scheme.outlineVariant)),
                                    enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.zero,
                                        borderSide: BorderSide(
                                            color: _scheme.outlineVariant))),
                                onChanged: (v) =>
                                    fatura.kur = double.tryParse(v),
                              )),
                              InkWell(
                                onTap: () {
                                  final v = double.tryParse(_kurCtrl.text) ?? 0;
                                  final n = v + 1;
                                  setState(() {
                                    fatura.kur =
                                        double.parse(n.toStringAsFixed(4));
                                    _kurCtrl.text =
                                        fatura.kur!.toStringAsFixed(4);
                                  });
                                },
                                child: Container(
                                    width: 36,
                                    height: 45,
                                    decoration: BoxDecoration(
                                        border: Border.all(
                                            color: _scheme.outlineVariant),
                                        borderRadius:
                                            const BorderRadius.horizontal(
                                                right: Radius.circular(8))),
                                    child: const Icon(Icons.add,
                                        size: 16, color: Colors.grey)),
                              ),
                            ],
                          )),
                    ],
                  )),
                ],
              ),
              const SizedBox(height: 10),
            ],

            // 9-10. Sıra: Proje + Plasiyer (yan yana)
            Row(
              children: [
                Expanded(
                    child: _buildSelectorField(
                  label: "Proje",
                  value: projeler
                          .where((p) => p.id == fatura.projeid)
                          .firstOrNull
                          ?.ad ??
                      "Seçiniz",
                  onTap: () async {
                    final res = await showErpSelector(
                        context: context,
                        title: "Proje Seç",
                        hintText: "Proje adı veya kodu",
                        items: projeler,
                        itemText: (p) => p.ad!);
                    if (res != null) setState(() => fatura.projeid = res.id);
                  },
                )),
                const SizedBox(width: 12),
                Expanded(
                    child: _buildSelectorField(
                  label: "Plasiyer",
                  value: plasiyerler
                          .where((p) => p.Id == fatura.plasiyerid)
                          .firstOrNull
                          ?.Adsoyad ??
                      "Seçiniz",
                  onTap: () async {
                    final res = await showErpSelector(
                        context: context,
                        title: "Plasiyer Seç",
                        hintText: "Plasiyer adı",
                        items: plasiyerler,
                        itemText: (p) => p.Adsoyad ?? '');
                    if (res != null) setState(() => fatura.plasiyerid = res.Id);
                  },
                )),
              ],
            ),
            const SizedBox(height: 10),

            // 11. Sıra: Referans + Açıklamalar (yan yana)
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                    child: _buildDropdown<int>(
                  label: "Referans",
                  value: fatura.referansid,
                  items: referanslar
                      .map((e) => DropdownMenuItem(
                          value: e.Id,
                          child: Text("${e.Kod ?? ''} - ${e.Ad ?? ''}",
                              style: const TextStyle(fontSize: 13))))
                      .toList(),
                  onChanged: (v) => setState(() => fatura.referansid = v),
                )),
                const SizedBox(width: 12),
                Expanded(child: _buildAciklamalarButton()),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatDate(DateTime d) =>
      "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

  Widget _buildGenericDateField({
    required String label,
    IconData? icon, // artık kullanılmıyor, geriye dönük uyumluluk için tutuldu
    required TextEditingController controller,
    required DateTime? currentDate,
    required ValueChanged<DateTime> onPicked,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _inputLabel(label),
        InkWell(
          onTap: () async {
            final d = await showDatePicker(
              context: context,
              initialDate: currentDate ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100),
            );
            if (d != null) onPicked(d);
          },
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _scheme.outlineVariant),
              color: (_modern || _scheme.brightness == Brightness.dark)
                  ? _scheme.surfaceContainerLow
                  : Colors.white,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    controller.text,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _scheme.onSurface),
                  ),
                ),
                Icon(Icons.calendar_today_outlined,
                    size: 16, color: _scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _cariSec() async {
    final secilen = await showErpSelector<CariDtoLite>(
      context: context,
      title: "Cari Rehberi",
      hintText: "Cari Adı veya Kodu...",
      items: cariler,
      itemText: (c) => "${c.Kod} - ${c.Ad}",
    );
    if (secilen == null) return;
    setState(() {
      seciliCari = secilen;
      fatura.cariid = secilen.Id;
      _cariAdresManuelSecildi = false;
      // Belge tipi ve _cariTR → tam cariden güncellenir (_loadCariVadegunu içinde)
    });
    _loadCariVadegunu(secilen.Id!);
  }

  Widget _buildCariSelector() {
    if (_modern)
      return InvoiceCustomerSelector(
          name: seciliCari?.Ad, code: seciliCari?.Kod, onTap: _cariSec);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
        border: Border.all(
          color: seciliCari != null
              ? primaryColor.withValues(alpha: 0.25)
              : _scheme.outlineVariant,
        ),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          // Kompakt "Cari Seç" butonu
          OutlinedButton.icon(
            onPressed: _cariSec,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              side: BorderSide(color: primaryColor, width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: Icon(Icons.business_rounded, size: 15, color: primaryColor),
            label: Text("Cari Seç",
                style: TextStyle(
                    fontSize: 12,
                    color: primaryColor,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          // Seçili cari bilgisi
          Expanded(
            child: seciliCari != null
                ? GestureDetector(
                    onTap: _cariSec,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          seciliCari!.Kod ?? '',
                          style: TextStyle(
                              fontSize: 11,
                              color: _scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.4),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          seciliCari!.Ad ?? '',
                          style: TextStyle(
                              fontSize: 14,
                              color: primaryColor,
                              fontWeight: FontWeight.w800),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  )
                : GestureDetector(
                    onTap: _cariSec,
                    child: Text(
                      "Cari seçilmedi",
                      style: TextStyle(
                          color: _scheme.onSurfaceVariant,
                          fontSize: 13,
                          fontStyle: FontStyle.italic),
                    ),
                  ),
          ),
          if (seciliCari != null)
            Icon(Icons.check_circle_rounded,
                size: 18, color: Colors.green.shade500),
        ],
      ),
    );
  }

// KALEMLER TABI
  Widget _kalemlerTab() {
    if (kalemler.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: _scheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              "Henüz kalem eklenmedi",
              style: TextStyle(color: _scheme.onSurfaceVariant, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: kalemler.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final k = kalemler[i];
        final sembol = ParaBirimiHelper.sembolById(fatura.dovizid);
        final bool isDoviz = (fatura.dovizid != null && fatura.dovizid != 1);
        final double kur = fatura.kur ?? 1.0;
        // Gösterim fiyatı: dövizliyse dovizfiyat, değilse fiyat
        final double goruntuFiyat = isDoviz
            ? ((k.dovizfiyat ?? 0) > 0 ? k.dovizfiyat! : (k.fiyat ?? 0) / kur)
            : (k.fiyat ?? 0);
        // Gösterim tutarı: dövizliyse TL / kur
        final double goruntuTutar =
            isDoviz ? (k.tutar ?? 0) / kur : (k.tutar ?? 0);

        // İskonto hesaplama
        final bool hasIskonto =
            (k.iskontoorani1 ?? 0) > 0 || (k.iskontoorani2 ?? 0) > 0;
        String iskontoText = '';
        if (hasIskonto) {
          List<String> iskontolar = [];
          if ((k.iskontoorani1 ?? 0) > 0) iskontolar.add('%${k.iskontoorani1}');
          if ((k.iskontoorani2 ?? 0) > 0) iskontolar.add('%${k.iskontoorani2}');
          iskontoText = ' (İsk: ${iskontolar.join(' + ')})';
        }

        return Container(
          decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius:
                BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
            border: Border.all(color: _scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Üst Kısım: Ürün Adı ve Tutar
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            k.stok?.Ad ?? "Ürün",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            k.stok?.Kod ?? "",
                            style: TextStyle(
                              fontSize: 12,
                              color: _scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      "${NumberFormatHelper.format(goruntuTutar)} $sembol",
                      style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),

                // Alt Kısım: Miktar, Fiyat, İskonto, KDV
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Miktar × Fiyat + İskonto
                          RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 13,
                                color: _scheme.onSurfaceVariant,
                              ),
                              children: [
                                TextSpan(
                                  text: '${k.miktar} ${k.olcubr?.Kod ?? ""}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                const TextSpan(text: ' × '),
                                TextSpan(
                                  text:
                                      '${NumberFormatHelper.format(goruntuFiyat)} $sembol',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                if (hasIskonto)
                                  TextSpan(
                                    text: iskontoText,
                                    style: TextStyle(
                                      color: Colors.orange.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          // KDV Oranı
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                  color: Colors.blue.shade300, width: 1),
                            ),
                            child: Text(
                              'KDV: %${(k.kdvorani ?? 0).toInt()}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          DocumentTrackingButton(
                              mode: k.stok?.Partiseritakipmodu,
                              line: TrackingLine(
                                  document: TrackingDocument.salesInvoice,
                                  documentId: widget.faturaId ?? _yeniFaturaId,
                                  lineId: k.id,
                                  stockId: k.stokid,
                                  warehouseId: k.depoid,
                                  addressId: k.depoadresid,
                                  featureId: k.stokozelliksabitid,
                                  direction: k.giriscikis,
                                  quantity: k.miktar ?? 0,
                                  multiplier: k.olcubrcarpim ?? 0)),
                        ],
                      ),
                    ),
                    // Butonlar
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        PermissionAction(
                            modules: [301],
                            access: Access.write,
                            child: IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 20),
                              onPressed: () => _editKalem(i),
                              color: Colors.blue.shade600,
                            )),
                        PermissionAction(
                            modules: [301],
                            access: Access.write,
                            child: IconButton(
                              icon: const Icon(Icons.delete_outline, size: 20),
                              onPressed: () => _removeKalem(i),
                              color: Colors.red.shade600,
                            )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _ozetVeAciklamaTab() {
    final sembol = ParaBirimiHelper.sembolById(fatura.dovizid);
    final kdvDahil = fatura.kdvdahil ?? true;
    final bool isDoviz = (fatura.dovizid != null && fatura.dovizid != 1);
    final double kur = (fatura.kur ?? 1.0).clamp(0.001, double.infinity);

    // Dövizli işlemlerde tüm TL değerleri kura bölerek göster
    double _d(double v) => isDoviz ? v / kur : v;
    // Dövizliyse TRY alt satırı oluştur, değilse null (summaryRow'da gösterilmez)
    String? _try(double v) =>
        isDoviz ? "${NumberFormatHelper.format(v)} ₺" : null;

    // ── Brüt toplam: miktar × fiyat (ham, iskonto öncesi)
    final double brutToplam =
        kalemler.fold(0.0, (s, k) => s + ((k.miktar ?? 0) * (k.fiyat ?? 0)));

    // ── Satır iskontoları
    final double satirIskontoToplam =
        kalemler.fold(0.0, (s, k) => s + (k.iskontotutar ?? 0));
    final bool hasSatirIskonto = satirIskontoToplam > 0;

    // ── Mal fazlası
    final double malFazlasiToplam =
        kalemler.fold(0.0, (s, k) => s + (k.malfazlasitutar ?? 0));
    final bool hasMalFazlasi = malFazlasiToplam > 0;

    // ── Ara Toplam: brüt - satır iskontosu (mal fazlası hesaba dahil değil)
    final double araToplam = brutToplam - satirIskontoToplam;

    // ── Genel iskonto: matrah üzerinden uygulanır
    // KDV dahil modda: önce matrahı bul, iskontoyu matrah üzerinden hesapla
    // KDV hariç modda: araToplam zaten matrah
    final bool hasGenelIskonto =
        (genelIskontoOrani ?? 0) > 0 || (genelIskontoTutari ?? 0) > 0;

    // Ortalama KDV oranını hesapla — sadece KDV dahil modda gerekli
    final double toplamKdvOrani = (!kdvDahil || kalemler.isEmpty)
        ? 0
        : kalemler.fold(0.0,
                (s, k) => s + ((k.kdvorani ?? 0) / 100 * (k.bruttutar ?? 0))) /
            (kalemler
                .fold(0.0, (s, k) => s + (k.bruttutar ?? 0))
                .clamp(1, double.infinity));

    // KDV dahil modda araToplam KDV dahil → matrahı bul
    // KDV hariç modda araToplam zaten matrah
    final double araTotalMatrah =
        kdvDahil ? araToplam / (1 + toplamKdvOrani) : araToplam;

    double genIskontoTutar = 0;
    if (hasGenelIskonto) {
      if ((genelIskontoOrani ?? 0) > 0) {
        // Oran girilmişse her zaman orandan hesapla
        genIskontoTutar = araTotalMatrah * (genelIskontoOrani! / 100);
      } else if ((genelIskontoTutari ?? 0) > 0) {
        genIskontoTutar = genelIskontoTutari!;
      }
    }

    // Gösterim tutarı: KDV dahil modda KDV ekle, hariç modda aynı
    final double genIskontoTutarKdvDahil =
        kdvDahil ? genIskontoTutar * (1 + toplamKdvOrani) : genIskontoTutar;

    // ── KDV detayı: kalemlerden matrah, kdv, tevkifat topla
    // tevkifatorani field'ını kullan — kdvtutar null olsa bile çalışır
    Map<double, Map<String, double>> kdvDetay = {};
    for (final k in kalemler) {
      final kdvOran = (k.kdvorani ?? 0).toDouble();
      final matrah = k.bruttutar ?? 0;
      final kdv = k.kdvtutar ?? (matrah * kdvOran / 100);
      final tevkOran = (k.tevkifatorani ?? 0).toDouble(); // 0-1 arası
      final tevkifat = k.tevkifattutar ?? (kdv * tevkOran);
      if (!kdvDetay.containsKey(kdvOran)) {
        kdvDetay[kdvOran] = {
          "matrah": 0.0,
          "kdv": 0.0,
          "tevkifat": 0.0,
          "tevkOran": tevkOran
        };
      }
      kdvDetay[kdvOran]!["matrah"] =
          (kdvDetay[kdvOran]!["matrah"] ?? 0) + matrah;
      kdvDetay[kdvOran]!["kdv"] = (kdvDetay[kdvOran]!["kdv"] ?? 0) + kdv;
      kdvDetay[kdvOran]!["tevkifat"] =
          (kdvDetay[kdvOran]!["tevkifat"] ?? 0) + tevkifat;
      // Ağırlıklı tevkifat oranı (aynı KDV oranındaki kalemler için)
      if (tevkOran > 0) kdvDetay[kdvOran]!["tevkOran"] = tevkOran;
    }

    // Genel iskonto varsa oransal düzelt
    if (genIskontoTutar > 0 && araTotalMatrah > 0) {
      final oran = 1 - (genIskontoTutar / araTotalMatrah);
      kdvDetay = kdvDetay.map((k, v) => MapEntry(k, {
            "matrah": (v["matrah"] ?? 0) * oran,
            "kdv": (v["kdv"] ?? 0) * oran,
            "tevkifat": (v["tevkifat"] ?? 0) * oran,
            "tevkOran": v["tevkOran"] ?? 0,
          }));
    }

    // KDV dahil modda: iskonto sonrası KDV dahil tutardan yeniden hesapla
    final double iskontoSonrasiKdvDahil = araToplam - genIskontoTutarKdvDahil;

    if (kdvDahil && iskontoSonrasiKdvDahil > 0) {
      final toplamDuzeltilmisMatrah = kdvDetay.values
          .fold(0.0, (s, e) => s + (e["matrah"] ?? 0))
          .clamp(1.0, double.infinity);
      kdvDetay = kdvDetay.map((kdvOran, v) {
        final matrahPay = (v["matrah"] ?? 0) / toplamDuzeltilmisMatrah;
        final kalemKdvDahil = iskontoSonrasiKdvDahil * matrahPay;
        final yeniMatrah = kalemKdvDahil / (1 + kdvOran / 100);
        final yeniKdv = yeniMatrah * (kdvOran / 100);
        final tevkOran = v["tevkOran"] ?? 0.0;
        final yeniTevkifat = yeniKdv * tevkOran;
        return MapEntry(kdvOran, {
          "matrah": yeniMatrah,
          "kdv": yeniKdv,
          "tevkifat": yeniTevkifat,
          "tevkOran": tevkOran,
        });
      });
    }

    // KDV hariç modda + genel iskonto varsa: yeniden hesapla
    if (!kdvDahil && hasGenelIskonto && iskontoSonrasiKdvDahil > 0) {
      final toplamDuzeltilmisMatrah = kdvDetay.values
          .fold(0.0, (s, e) => s + (e["matrah"] ?? 0))
          .clamp(1.0, double.infinity);
      kdvDetay = kdvDetay.map((kdvOran, v) {
        final matrahPay = (v["matrah"] ?? 0) / toplamDuzeltilmisMatrah;
        final yeniMatrah = iskontoSonrasiKdvDahil * matrahPay;
        final yeniKdv = yeniMatrah * (kdvOran / 100);
        final tevkOran = v["tevkOran"] ?? 0.0;
        final yeniTevkifat = yeniKdv * tevkOran;
        return MapEntry(kdvOran, {
          "matrah": yeniMatrah,
          "kdv": yeniKdv,
          "tevkifat": yeniTevkifat,
          "tevkOran": tevkOran,
        });
      });
    }

    final double toplamKdv =
        kdvDetay.values.fold(0.0, (s, e) => s + (e["kdv"] ?? 0));
    final double toplamTevkifat =
        kdvDetay.values.fold(0.0, (s, e) => s + (e["tevkifat"] ?? 0));
    final double toplamNetKdv = toplamKdv - toplamTevkifat;

    // Genel toplam özet gösterimi — tevkifat her zaman düşülür
    final double ozetGenelToplam;
    if (hasGenelIskonto) {
      ozetGenelToplam = kdvDahil
          ? iskontoSonrasiKdvDahil - toplamTevkifat
          : iskontoSonrasiKdvDahil + toplamNetKdv;
    } else {
      // Genel iskonto yok
      // KDV dahil: araToplam (KDV dahil) - tevkifat
      // KDV hariç: matrah + (kdv - tevkifat)
      final double toplamMatrah =
          kdvDetay.values.fold(0.0, (s, e) => s + (e["matrah"] ?? 0));
      ozetGenelToplam =
          kdvDahil ? araToplam - toplamTevkifat : toplamMatrah + toplamNetKdv;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ara Toplam Kartı
          _buildSectionCard(
            title: "Toplam",
            icon: Icons.shopping_cart_outlined,
            children: [
              _summaryRow(
                "Brüt Toplam",
                "${NumberFormatHelper.format(_d(brutToplam))} $sembol",
                isBold: true,
                fontSize: 16,
                subValue: _try(brutToplam),
              ),
            ],
          ),

          // Satır İskontosu Kartı
          if (hasSatirIskonto)
            _buildSectionCard(
              title: "Satır İskontosu",
              icon: Icons.remove_circle_outline_rounded,
              iconColor: const Color(0xFFEA580C),
              children: [
                _summaryRow(
                  "Toplam Satır İskontosu",
                  "-${NumberFormatHelper.format(_d(satirIskontoToplam))} $sembol",
                  isBold: true,
                  fontSize: 15,
                  color: const Color(0xFFEA580C),
                  subValue: _try(satirIskontoToplam),
                ),
                const Divider(height: 16),
                _summaryRow(
                  "Ara Toplam",
                  "${NumberFormatHelper.format(_d(araToplam))} $sembol",
                  isBold: true,
                  fontSize: 15,
                  color: Colors.green.shade700,
                  subValue: _try(araToplam),
                ),
              ],
            ),

          // Mal Fazlası Kartı — sadece bilgi, hesaplamaya dahil değil
          if (hasMalFazlasi)
            _buildSectionCard(
              title: "Mal Fazlası (Bilgi)",
              icon: Icons.card_giftcard_outlined,
              iconColor: const Color(0xFF7C3AED),
              children: [
                _summaryRow(
                  "Toplam Mal Fazlası",
                  "${NumberFormatHelper.format(_d(malFazlasiToplam))} $sembol",
                  isBold: true,
                  fontSize: 15,
                  color: const Color(0xFF7C3AED),
                  subValue: _try(malFazlasiToplam),
                ),
                const SizedBox(height: 4),
                Text("* Mal fazlası tutara dahil edilmez",
                    style: TextStyle(
                        fontSize: 11,
                        color: _scheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic)),
              ],
            ),

          // Genel İskonto Kartı
          if (hasGenelIskonto)
            _buildSectionCard(
              title: "Genel İskonto",
              icon: Icons.discount_outlined,
              children: [
                if (genelIskontoOrani != null && genelIskontoOrani! > 0)
                  _summaryRow("İskonto Oranı", "%${genelIskontoOrani}"),
                _summaryRow(
                  "İskonto Tutarı",
                  "-${NumberFormatHelper.format(_d(genIskontoTutarKdvDahil))} $sembol",
                  color: Colors.orange.shade700,
                  isBold: true,
                  subValue: _try(genIskontoTutarKdvDahil),
                ),
                const Divider(height: 20),
                _summaryRow(
                  "İskonto Sonrası",
                  "${NumberFormatHelper.format(_d(araToplam - genIskontoTutarKdvDahil))} $sembol",
                  isBold: true,
                  fontSize: 15,
                  color: Colors.green.shade700,
                  subValue: _try(araToplam - genIskontoTutarKdvDahil),
                ),
              ],
            ),

          // KDV Kartı
          _buildSectionCard(
            title: "KDV Detayı",
            icon: Icons.receipt_long_outlined,
            children: [
              if (kdvDetay.length > 1) ...[
                ...kdvDetay.entries.map((entry) {
                  final kdvOran = entry.key.toInt();
                  final matrah = entry.value["matrah"] ?? 0;
                  final kdvTutar = entry.value["kdv"] ?? 0;
                  return Column(
                    children: [
                      _summaryRow(
                        "KDV (%$kdvOran) Matrah",
                        "${NumberFormatHelper.format(_d(matrah))} $sembol",
                        fontSize: 13,
                        subValue: _try(matrah),
                      ),
                      _summaryRow(
                        "KDV Tutarı",
                        "${NumberFormatHelper.format(_d(kdvTutar))} $sembol",
                        fontSize: 13,
                        color: Colors.blue.shade700,
                        subValue: _try(kdvTutar),
                      ),
                      if (entry != kdvDetay.entries.last)
                        const Divider(height: 16),
                    ],
                  );
                }).toList(),
                const Divider(height: 20, thickness: 2),
              ],
              _summaryRow(
                "Toplam KDV",
                "${NumberFormatHelper.format(_d(toplamKdv))} $sembol",
                isBold: true,
                fontSize: 16,
                color: Colors.blue.shade700,
                subValue: _try(toplamKdv),
              ),
            ],
          ),

          // Tevkifat Kartı — sadece tevkifatlı kalem varsa
          if (toplamTevkifat <= 0)
            const SizedBox.shrink()
          else
            _buildSectionCard(
              title: "Tevkifat",
              icon: Icons.account_balance_outlined,
              iconColor: const Color(0xFF7C3AED),
              children: [
                _summaryRow(
                  "Toplam Tevkifat",
                  "-${NumberFormatHelper.format(_d(toplamTevkifat))} $sembol",
                  isBold: true,
                  fontSize: 15,
                  color: const Color(0xFF7C3AED),
                  subValue: _try(toplamTevkifat),
                ),
              ],
            ),
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF17243B), Color(0xFF293E5B)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "GENEL TOPLAM",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${NumberFormatHelper.format(_d(ozetGenelToplam))} $sembol",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    if (isDoviz)
                      Text(
                        "${NumberFormatHelper.format(ozetGenelToplam)} ₺",
                        style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 13,
                            fontWeight: FontWeight.w400),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Açıklama Kartı
          _buildSectionCard(
            title: "Açıklama",
            icon: Icons.note_alt_outlined,
            children: [
              TextField(
                controller: _aciklamaCtrl,
                maxLines: 4,
                onChanged: (v) => fatura.aciklama = v,
                decoration: InputDecoration(
                  hintText: "Açıklama",
                  hintStyle:
                      TextStyle(color: _scheme.onSurfaceVariant, fontSize: 13),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _scheme.outlineVariant),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: _scheme.outlineVariant),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor, width: 2),
                  ),
                  filled: true,
                  fillColor: _scheme.surfaceContainerLow,
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bottomSummaryAndSave() {
    final hasGenelIskonto =
        (genelIskontoOrani ?? 0) > 0 || (genelIskontoTutari ?? 0) > 0;
    return Container(
      color: _scheme.surface,
      child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: _tabController.index == 2
                ? _buildButtonRow(hasGenelIskonto)
                : ErpEntryActions(
                    onAdd: _addKalem,
                    onBarcode: _addHizliBarkodKalemler,
                    onCamera: () => _addDirekBarkodKalem(camera: true),
                    onManual: () => _addDirekBarkodKalem(camera: false),
                  ),
          )),
    );
  }

  Widget _buildButtonRow(bool hasGenelIskonto) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: OutlinedButton(
            onPressed: _openIskonto,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: hasGenelIskonto
                    ? Colors.orange.shade600
                    : _scheme.onSurfaceVariant,
                width: hasGenelIskonto ? 2 : 1.5,
              ),
              backgroundColor:
                  hasGenelIskonto ? _scheme.primaryContainer : _scheme.surface,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.percent,
                        size: 18,
                        color: hasGenelIskonto
                            ? Colors.orange.shade700
                            : _scheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(
                      "Genel İskonto",
                      style: TextStyle(
                        color: hasGenelIskonto
                            ? Colors.orange.shade700
                            : _scheme.onSurfaceVariant,
                        fontWeight:
                            hasGenelIskonto ? FontWeight.bold : FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    if (hasGenelIskonto) ...[
                      const SizedBox(width: 4),
                      Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: Colors.orange.shade600,
                              shape: BoxShape.circle)),
                    ],
                  ],
                )),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 3,
          child: PermissionAction(
              modules: [301],
              access: Access.write,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _scheme.primary,
                  foregroundColor: _scheme.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                onPressed: _showKaydetDialog,
                child: const Text("Kaydet",
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              )),
        ),
      ],
    );
  }

  Future<void> _showKaydetDialog() async {
    // Validasyon önce
    if (seciliCari == null) {
      UiFeedback.showWarning(context, "Lütfen cari seçiniz!");
      return;
    }
    if (kalemler.isEmpty) {
      UiFeedback.showWarning(context, "En az bir kalem eklemelisiniz!");
      return;
    }
    if (!_isEditMode && !_offlineDraft && _yeniFaturaId == null) {
      UiFeedback.showWarning(context, "Lütfen önce kalem ekleyiniz!");
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                    color: primaryColor.withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: Icon(Icons.save_outlined, size: 36, color: primaryColor),
              ),
              const SizedBox(height: 16),
              const Text("Faturayı Kaydet",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text("Faturayı nasıl kaydetmek istersiniz?",
                  style:
                      TextStyle(color: _scheme.onSurfaceVariant, fontSize: 13),
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              // Belgeyi Tamamla
              SizedBox(
                width: double.infinity,
                child: PermissionAction(
                    modules: [301],
                    access: Access.create,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _scheme.primary,
                        foregroundColor: _scheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.check_circle_outline_rounded),
                      label: const Text("Belgeyi Tamamla",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _saveFaturaTamamla();
                      },
                    )),
              ),
              const SizedBox(height: 10),
              // Taslak Kaydet
              SizedBox(
                width: double.infinity,
                child: PermissionAction(
                    modules: [301],
                    access: Access.write,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _scheme.onSurfaceVariant,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: _scheme.outlineVariant),
                      ),
                      icon: const Icon(Icons.save_outlined),
                      label: const Text("Taslak Kaydet",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _saveFatura();
                      },
                    )),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("İptal",
                    style: TextStyle(color: _scheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveFaturaTamamla() async {
    // pop: false — liste sayfasına ancak belge durumu da "tamamlandı" olarak
    // güncellendikten SONRA döneceğiz, aksi halde liste taslak durumuyla
    // yenilenip kullanıcı "tamamlandı" belgeyi taslak olarak görüyordu.
    await _saveFatura(pop: false);
    if (!mounted) return;
    // _saveFatura başarılıysa faturaId ile belgeyi tamamla
    final faturaId = _isEditMode ? widget.faturaId! : _yeniFaturaId;
    if (faturaId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await FaturaService().belgeDurumGuncelle(token, faturaId, 1);
      if (!mounted) return;
      await _tamamlandiSonrasiSor(faturaId);
      if (!mounted) return;
      Navigator.of(context).pop(faturaId);
    } catch (e) {
      if (!mounted) return;
      UiFeedback.showException(context, e);
    }
  }

  /// Fatura tamamlandıktan sonra "tahsilat yapılacak mı?" diye sorar.
  /// "Tahsilat Yap" → Tahsilat ekranına gider, "Yazdır" → mevcut yazıcı
  /// ayarlarıyla faturayı basar, "Kapat" → hiçbir şey yapmadan devam eder.
  Future<void> _tamamlandiSonrasiSor(String faturaId) async {
    final secim = await InvoiceCompletedDialog.show(context);
    if (!mounted) return;

    if (secim == 'tahsilat') {
      await _tahsilataGit(faturaId);
    } else if (secim == 'yazdir') {
      await _yazdirFatura(faturaId);
    }
  }

  Future<void> _tahsilataGit(String faturaId) async {
    final kaynak = TahsilatKaynakBelge(
      belgeId: faturaId,
      belgeturu: fatura.belgeturu ?? BelgeTuruCouples.satisFaturasi,
      belgeserino: fatura.belgeserino,
      belgeno: fatura.belgeno,
      cariid: fatura.cariid,
      dovizid: fatura.dovizid,
      projeid: fatura.projeid,
      plasiyerid: fatura.plasiyerid,
      toplamTutar: fatura.geneltoplam ?? 0,
      dovizToplam: _dovizToplam,
    );
    if (!mounted) return;
    await Navigator.push(
        context,
        PermissionMaterialPageRoute(
            builder: (_) => TahsilatListePage(kaynakBelge: kaynak)));
  }

  Future<void> _yazdirFatura(String faturaId) async {
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

      final plasiyerAd = plasiyerler
          .where((p) => p.Id == fatura.plasiyerid)
          .firstOrNull
          ?.Adsoyad;

      final fisKalemler = kalemler
          .map((k) => FaturaFisKalem(
                ad: k.stok?.Ad ?? '-',
                miktar: k.miktar ?? 0,
                birimFiyat: k.fiyat ?? 0,
              ))
          .toList();

      final satirGen = await YaziciSablonService.instance.getSatirGenisligi();
      final prefs = await SharedPreferences.getInstance();
      final kullaniciAdi = prefs.getString('kullanici_adi');

      final bytes = svc.buildFaturaFisi(
        belgeNo: fatura.belgeserino ?? fatura.belgeno ?? '-',
        tarih: fatura.tarih ?? DateTime.now(),
        cariAd: seciliCari?.Ad ?? '-',
        plasiyerAd: plasiyerAd,
        kalemler: fisKalemler,
        araToplam: fatura.aratoplam ?? 0,
        kdvToplam: fatura.kdvtoplam ?? 0,
        genelToplam: fatura.geneltoplam ?? 0,
        satirGenisligi: satirGen,
        kullaniciAdi: kullaniciAdi,
      );
      final ok = await svc.printBytes(bytes);
      if (!mounted) return;
      if (ok) {
        UiFeedback.showSuccess(context, "Fatura yazıcıya gönderildi.");
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
    final internetYok = !OfflineService.instance.isOnline.value;
    _prepareFaturaFields();
    final payload = {
      'headerEndpoint': '/Fatura/SaveSingle',
      'hareketEndpoint': '/Faturahareket/SaveSingle',
      'headerIdField': 'faturaid',
      'header': fatura.toJson(),
      'kalemler': kalemler.map((k) => k.toJson()).toList(),
    };
    await OfflineService.instance.enqueue('header_hareket_full', payload);
    if (!mounted) return;
    final mesaj = internetYok
        ? "İnternet yok — belge kuyruğa alındı, bağlantı gelince gönderilecek"
        : "Belge kuyruğa eklendi — online olunca gönderilecek";
    UiFeedback.showSuccess(context, mesaj);
    Navigator.of(context).pop(true);
  }

  Future<void> _showResultDialog(
      {required bool success, String? faturaId, String? errorMessage}) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        elevation: 0,
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // İkon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: success
                      ? const Color(0xFFE8F5E9)
                      : const Color(0xFFFFEBEE),
                ),
                child: Icon(
                  success ? Icons.check_rounded : Icons.error_outline_rounded,
                  size: 44,
                  color: success
                      ? const Color(0xFF2E7D32)
                      : const Color(0xFFC62828),
                ),
              ),
              const SizedBox(height: 24),

              // Başlık
              Text(
                success
                    ? (_isEditMode ? "Fatura Güncellendi" : "Fatura Kaydedildi")
                    : (_isEditMode
                        ? "Güncelleme Başarısız"
                        : "Kayıt Başarısız"),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: success ? _scheme.onSurface : const Color(0xFFC62828),
                ),
              ),
              const SizedBox(height: 12),

              // Alt mesaj
              if (success)
                Text(
                  _isEditMode
                      ? "Fatura başarıyla güncellendi."
                      : "Fatura başarıyla kaydedildi.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 14,
                      color: _scheme.onSurfaceVariant,
                      height: 1.5),
                )
              else ...[
                Container(
                  constraints: const BoxConstraints(maxHeight: 200),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8F8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      errorMessage ?? "Beklenmeyen bir hata oluştu.",
                      style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFC62828),
                          height: 1.5,
                          fontFamily: 'monospace'),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () => Clipboard.setData(
                      ClipboardData(text: errorMessage ?? '')),
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text("Kopyala"),
                ),
              ],

              if (success && faturaId != null && faturaId.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.tag_rounded,
                          size: 16, color: _scheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        "${fatura.belgeseri ?? ''}${fatura.belgeyil ?? ''}${fatura.belgeno ?? ''}",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Buton
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        success ? const Color(0xFF2E7D32) : _scheme.onSurface,
                    foregroundColor: _scheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    success ? "Tamam" : "Kapat",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addKalem() async {
    if (seciliCari == null) {
      UiFeedback.showWarning(context, "Önce cari seçiniz!");
      return;
    }

    final k = await showFaturaKalemForm(context,
        kdvDahil: fatura.kdvdahil ?? true,
        dovizId: fatura.dovizid,
        kur: fatura.kur,
        stoklar: stoklar,
        cariTR: _cariTR,
        varsayilanDepoId: _plasiyerDepoId,
        bakiyeUyar: true);
    if (k == null || !mounted) return;

    // Edit modda direkt kaydet
    if (_isEditMode) {
      k.faturaid = widget.faturaId;
      k.teslimtarihi ??= fatura.teslimtarihi;
      _prepareDovizHareket(k);
      _showMiniLoading("Kalem kaydediliyor...");
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token_final") ?? "";
        final savedId = await FaturaService().saveRowSingle(token, k);
        if (savedId != null) k.id = savedId;
        if (!mounted) return;
        Navigator.of(context).pop();
        setState(() {
          kalemler.add(k);
          _recalcFaturaToplam();
        });
        _tabController.animateTo(1);
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        UiFeedback.showException(context, e);
      }
      return;
    }

    // Offline mod kontrolü — bir kez offline'a düşülürse bu belge için oturum boyunca offline devam
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (_offlineDraft || manuelOffline || internetYok) {
      _offlineDraft = true;
      k.teslimtarihi ??= fatura.teslimtarihi;
      _prepareDovizHareket(k);
      if (!mounted) return;
      setState(() {
        kalemler.add(k);
        _recalcFaturaToplam();
      });
      _tabController.animateTo(1);
      return;
    }

    // Yeni fatura modu
    final svc = FaturaService();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";

    // Fatura henüz kaydedilmemişse önce kaydet
    if (_yeniFaturaId == null) {
      _showMiniLoading("Fatura kaydediliyor...");
      try {
        _prepareFaturaFields();
        _yeniFaturaId = await svc.saveSingle(token, fatura);
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        UiFeedback.showException(context, e);
        return;
      }
    } else {
      // Fatura zaten var — üst bilgiyi güncelle
      _showMiniLoading("Fatura güncelleniyor...");
      try {
        _prepareFaturaFields();
        final updateDto = FaturaUpdateDto(id: _yeniFaturaId)
          ..cariid = fatura.cariid
          ..cariadresid = fatura.cariadresid
          ..plasiyerid = fatura.plasiyerid
          ..dovizid = fatura.dovizid
          ..projeid = fatura.projeid
          ..referansid = fatura.referansid
          ..subeid = fatura.subeid
          ..belgeseri = fatura.belgeseri
          ..belgeyil = fatura.belgeyil
          ..belgeno = fatura.belgeno
          ..belgeserino = fatura.belgeserino
          ..gibbelgeno = fatura.gibbelgeno
          ..ebelgetip = fatura.ebelgetip
          ..tarih = fatura.tarih
          ..fiilitarih = fatura.fiilitarih
          ..teslimtarihi = fatura.teslimtarihi
          ..tahsilattarihi = fatura.tahsilattarihi
          ..vadetarihi = fatura.vadetarihi
          ..vadegunu = fatura.vadegunu
          ..belgetipi = fatura.belgetipi
          ..ithalatihracattipi = fatura.ithalatihracattipi
          ..odemesekli = fatura.odemesekli
          ..doviztarih = fatura.doviztarih
          ..kur = fatura.kur
          ..kdvdahil = fatura.kdvdahil
          ..belgeturu = fatura.belgeturu
          ..geneliskontooran = fatura.geneliskontooran
          ..geneliskontotutar = fatura.geneliskontotutar
          ..bruttutar = fatura.bruttutar
          ..iskontotutar = fatura.iskontotutar
          ..aratoplam = fatura.aratoplam
          ..kdvtoplam = fatura.kdvtoplam
          ..geneltoplam = fatura.geneltoplam
          ..aciklama = fatura.aciklama;
        await svc.updateSingle(token, updateDto);
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        // Hata olsa bile kalemi kaydetmeye devam et
      }
    }

    // Kalemi kaydet
    k.faturaid = _yeniFaturaId;
    k.teslimtarihi ??= fatura.teslimtarihi;
    _prepareDovizHareket(k);
    _showMiniLoading("Kalem kaydediliyor...");
    try {
      final savedId = await svc.saveRowSingle(token, k);
      if (savedId != null) k.id = savedId;
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {
        kalemler.add(k);
        _recalcFaturaToplam();
      });
      _tabController.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showException(context, e);
    }
  }

  // Plasiyer kullanıcı: fatura kendi plasiyerine yazılır, kalem deposu kendi (araç) deposu olarak gelir.
  KullaniciPlasiyer _kp = const KullaniciPlasiyer();
  int? _plasiyerDepoId;

  // ── Hızlı Barkod Okut ────────────────────────────────────────────────────
  Future<void> _addHizliBarkodKalemler() async {
    if (seciliCari == null) {
      UiFeedback.showWarning(context, "Önce cari seçiniz!");
      return;
    }

    final result = await showQuickBarcodeScanSheet(
      context,
      stoklar: stoklar,
      title: "Hızlı Barkod Okut",
    );
    if (result == null || result.lines.isEmpty || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final svc = FaturaService();

    _showMiniLoading("Kalemler hazırlanıyor...");

    final yeniKalemler = <FaturahareketDto>[];
    final varsayilanDepoId =
        _plasiyerDepoId ?? await VarsayilanDepoHelper.getId(token);
    final varsayilanProjeId =
        fatura.projeid ?? await VarsayilanProjeHelper.getId(token);

    for (final line in result.lines) {
      final stokListDto = line.stok;
      if (stokListDto == null || stokListDto.Id == null) continue;

      final k = FaturahareketDto();
      k.depoid ??= varsayilanDepoId;
      k.projeid ??= varsayilanProjeId;
      k.stokid = stokListDto.Id;
      k.stok =
          StokDto(Id: stokListDto.Id, Kod: stokListDto.Kod, Ad: stokListDto.Ad);
      k.miktar = line.quantity;
      k.kdvorani = 20.0;
      k.fiyat = 0.0;
      k.teslimtarihi = fatura.teslimtarihi;

      // Full stok: KDV, satış fiyatı, ölçü birimi, tevkifat
      try {
        final sf = await StokService().getStokById(token, stokListDto.Id!);
        final kdvSatis = sf.Kdvsatis ?? 0;
        k.kdvorani =
            kdvSatis > 0 ? (kdvSatis <= 1.0 ? kdvSatis * 100 : kdvSatis) : 20.0;

        final fiyatlar = sf.Stokfiyat;
        if (fiyatlar.isNotEmpty) {
          final eslesen =
              fiyatlar.where((f) => f.Dovizid == fatura.dovizid).firstOrNull;
          final fd = eslesen ?? fiyatlar.first;
          k.fiyat = fd.Satisfiyat ?? 0;
        }

        // Ölçü birimi
        final birimler = sf.Stokolcubr.where((s) => s.Olcubr != null)
            .map((s) => s.Olcubr!)
            .toList();
        if (sf.Temelolcubr != null) birimler.insert(0, sf.Temelolcubr!);
        final gorulen = <int>{};
        final tekBirimler =
            birimler.where((o) => o.Id != null && gorulen.add(o.Id!)).toList();
        if (tekBirimler.isNotEmpty) k.olcubrid = tekBirimler.first.Id;

        // Tevkifat
        if (_cariTR && (sf.Tevkifatorani ?? 0) > 0) {
          k.tevkifatorani = sf.Tevkifatorani;
        }
      } catch (_) {
        // Full stok yüklenemezse varsayılanlarla devam et
      }

      // Hesapla
      final sonuc = FaturaHesapHelper.hesaplaKalem(
        miktar: k.miktar ?? 1,
        fiyat: k.fiyat ?? 0,
        iskontoTutar: 0,
        kdvOrani: k.kdvorani ?? 0,
        tevkifatOrani: k.tevkifatorani ?? 0,
        kdvDahil: fatura.kdvdahil ?? true,
        malFazlasiAdet: 0,
      );
      k.bruttutar = sonuc.bruttutar;
      k.kdvtutar = sonuc.kdvtutar;
      k.tevkifatmatrahi = sonuc.tevkifatmatrahi;
      k.tevkifattutar = sonuc.tevkifattutar;
      k.tutar = sonuc.tutar;
      _prepareDovizHareket(k);

      yeniKalemler.add(k);
    }

    if (yeniKalemler.isEmpty) {
      if (mounted) Navigator.of(context).pop();
      if (mounted)
        UiFeedback.showWarning(context, "Eklenecek stok bulunamadı!");
      return;
    }

    // Edit modda direkt ekle
    if (_isEditMode) {
      int savedCount = 0;
      String? ilkHata;
      final kaydedilenler = <FaturahareketDto>[];
      for (final k in yeniKalemler) {
        k.faturaid = widget.faturaId;
        try {
          final savedId = await svc.saveRowSingle(token, k);
          if (savedId != null) k.id = savedId;
          kaydedilenler.add(k);
          savedCount++;
        } catch (e) {
          ilkHata ??= e.toString();
        }
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {
        kalemler.addAll(kaydedilenler);
        _recalcFaturaToplam();
        _tabController.animateTo(1);
      });
      if (ilkHata != null) {
        UiFeedback.showError(context,
            "$savedCount kalem eklendi, ${yeniKalemler.length - savedCount} kalem kaydedilemedi: $ilkHata");
      } else {
        UiFeedback.showSuccess(context, "$savedCount kalem eklendi");
      }
      return;
    }

    // Offline mod kontrolü
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (_offlineDraft || manuelOffline || internetYok) {
      _offlineDraft = true;
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {
        kalemler.addAll(yeniKalemler);
        _recalcFaturaToplam();
        _tabController.animateTo(1);
      });
      UiFeedback.showSuccess(
          context, "${yeniKalemler.length} kalem eklendi (offline)");
      return;
    }

    // Yeni fatura modu: gerekirse önce fatura header kaydet
    if (_yeniFaturaId == null) {
      try {
        _prepareFaturaFields();
        _yeniFaturaId = await svc.saveSingle(token, fatura);
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        UiFeedback.showException(context, e);
        return;
      }
    }

    // Kalemleri sırayla kaydet
    int savedCount = 0;
    String? ilkHata;
    final kaydedilenler = <FaturahareketDto>[];
    for (final k in yeniKalemler) {
      k.faturaid = _yeniFaturaId;
      try {
        final savedId = await svc.saveRowSingle(token, k);
        if (savedId != null) k.id = savedId;
        kaydedilenler.add(k);
        savedCount++;
      } catch (e) {
        ilkHata ??= e.toString();
      }
    }

    if (!mounted) return;
    Navigator.of(context).pop();
    setState(() {
      kalemler.addAll(kaydedilenler);
      _recalcFaturaToplam();
      _tabController.animateTo(1);
    });
    if (ilkHata != null) {
      UiFeedback.showError(context,
          "$savedCount kalem eklendi, ${yeniKalemler.length - savedCount} kalem kaydedilemedi: $ilkHata");
    } else {
      UiFeedback.showSuccess(context, "$savedCount kalem eklendi");
    }
  }

  // ── Tek Barkod ile Kalem Ekle (kamera veya terminal) ─────────────────────
  Future<void> _addDirekBarkodKalem({bool camera = false}) async {
    if (seciliCari == null) {
      UiFeedback.showWarning(context, "Önce cari seçiniz!");
      return;
    }

    String? barcode;

    if (camera) {
      barcode = await Navigator.push<String>(
        context,
        PermissionMaterialPageRoute(
            builder: (_) => const BarcodeScannerSheet()),
      );
    } else {
      final ctrl = TextEditingController();
      barcode = await showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Barkod Okut",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          content: TextField(
            controller: ctrl,
            autofocus: true,
            decoration: InputDecoration(
              hintText: "Barkod",
              prefixIcon: const Icon(Icons.barcode_reader),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          actions: [
            ErpDialogAction(
                onPressed: () => Navigator.pop(context),
                child: const Text("İptal")),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: const Text("Ara"),
            ),
          ],
        ),
      );
    }

    if (barcode == null || barcode.trim().isEmpty || !mounted) return;

    // Stok listesinde barkodla ara
    final normalized = barcode.trim().toLowerCase();
    StokListDto? bulunan;
    for (final s in stoklar) {
      if (s.getBarkodListesi().any((b) => b.toLowerCase() == normalized)) {
        bulunan = s;
        break;
      }
    }
    if (bulunan == null) {
      if (mounted) UiFeedback.showWarning(context, "Stok bulunamadı: $barcode");
      return;
    }

    // Kalem formunu bulunan stokla pre-fill ederek aç
    final preK = FaturahareketDto();
    preK.stokid = bulunan.Id;
    preK.stok = StokDto(Id: bulunan.Id, Kod: bulunan.Kod, Ad: bulunan.Ad);

    if (!mounted) return;
    final res = await showFaturaKalemForm(
      context,
      kalem: preK,
      kdvDahil: fatura.kdvdahil ?? true,
      dovizId: fatura.dovizid,
      kur: fatura.kur,
      stoklar: stoklar,
      cariTR: _cariTR,
      varsayilanDepoId: _plasiyerDepoId,
      bakiyeUyar: true,
    );
    if (res == null || !mounted) return;

    // Aynı _addKalem kaydetme akışı
    res.teslimtarihi ??= fatura.teslimtarihi;
    _prepareDovizHareket(res);

    if (_isEditMode) {
      res.faturaid = widget.faturaId;
      _showMiniLoading("Kalem kaydediliyor...");
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token_final") ?? "";
        final savedId = await FaturaService().saveRowSingle(token, res);
        if (savedId != null) res.id = savedId;
        if (!mounted) return;
        Navigator.of(context).pop();
        setState(() {
          kalemler.add(res);
          _recalcFaturaToplam();
        });
        _tabController.animateTo(1);
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        UiFeedback.showException(context, e);
      }
      return;
    }

    // Offline mod kontrolü
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (_offlineDraft || manuelOffline || internetYok) {
      _offlineDraft = true;
      if (!mounted) return;
      setState(() {
        kalemler.add(res);
        _recalcFaturaToplam();
      });
      _tabController.animateTo(1);
      return;
    }

    final svc = FaturaService();
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";

    if (_yeniFaturaId == null) {
      _showMiniLoading("Fatura kaydediliyor...");
      try {
        _prepareFaturaFields();
        _yeniFaturaId = await svc.saveSingle(token, fatura);
        if (!mounted) return;
        Navigator.of(context).pop();
      } catch (e) {
        if (!mounted) return;
        Navigator.of(context).pop();
        UiFeedback.showException(context, e);
        return;
      }
    }

    res.faturaid = _yeniFaturaId;
    _showMiniLoading("Kalem kaydediliyor...");
    try {
      final savedId = await svc.saveRowSingle(token, res);
      if (savedId != null) res.id = savedId;
      if (!mounted) return;
      Navigator.of(context).pop();
      setState(() {
        kalemler.add(res);
        _recalcFaturaToplam();
      });
      _tabController.animateTo(1);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showException(context, e);
    }
  }

  // ── Yuvarlak Aksiyon Butonu ───────────────────────────────────────────────
  void _prepareDovizHareket(FaturahareketDto k) {
    final bool isDoviz = (fatura.dovizid != null && fatura.dovizid != 1);
    final double kur = (fatura.kur ?? 1.0).clamp(0.001, double.infinity);

    if (!isDoviz) return; // TL işlemde bir şey yapma

    // dovizfiyat: kalem formundan zaten geliyor
    // fiyat: TL karşılığı (dovizfiyat × kur) — kalem formunda set edilmiş
    // Eğer dovizfiyat set edilmemişse fiyat TL'dir, dovize çevir
    if ((k.dovizfiyat ?? 0) <= 0 && (k.fiyat ?? 0) > 0) {
      k.dovizfiyat = k.fiyat! / kur;
    }

    // tevkifattutar null kontrolü
    k.tevkifattutar = (k.tevkifattutar ?? 0) > 0 ? k.tevkifattutar : null;

    // malfazlasitutar (TL) ve dovizmalfazlasitutar (döviz)
    if ((k.malfazlasiiskonto ?? 0) > 0) {
      k.malfazlasitutar = (k.malfazlasiiskonto ?? 0) * (k.fiyat ?? 0); // TL
      k.dovizmalfazlasitutar =
          (k.malfazlasiiskonto ?? 0) * (k.dovizfiyat ?? 0); // döviz
    }

    // iskontotutari1-6: TL cinsinden → doviziskontotutari = TL / kur
    // Eğer iskontotutari1-6 hepsi null ama iskontotutar doluysa → iskontotutari1'e yaz
    final hepsNull = (k.iskontotutari1 ?? 0) == 0 &&
        (k.iskontotutari2 ?? 0) == 0 &&
        (k.iskontotutari3 ?? 0) == 0 &&
        (k.iskontotutari4 ?? 0) == 0 &&
        (k.iskontotutari5 ?? 0) == 0 &&
        (k.iskontotutari6 ?? 0) == 0;
    if (hepsNull && (k.iskontotutar ?? 0) > 0) {
      k.iskontotutari1 = k.iskontotutar;
    }
    if ((k.iskontotutari1 ?? 0) > 0)
      k.doviziskontotutari1 = k.iskontotutari1! / kur;
    if ((k.iskontotutari2 ?? 0) > 0)
      k.doviziskontotutari2 = k.iskontotutari2! / kur;
    if ((k.iskontotutari3 ?? 0) > 0)
      k.doviziskontotutari3 = k.iskontotutari3! / kur;
    if ((k.iskontotutari4 ?? 0) > 0)
      k.doviziskontotutari4 = k.iskontotutari4! / kur;
    if ((k.iskontotutari5 ?? 0) > 0)
      k.doviziskontotutari5 = k.iskontotutari5! / kur;
    if ((k.iskontotutari6 ?? 0) > 0)
      k.doviziskontotutari6 = k.iskontotutari6! / kur;

    // Diğer tüm alanlar (bruttutar, kdvtutar, tutar vs.) zaten TL — dokunma
  }

  void _showMiniLoading(String msg) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: Card(
          shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(20))),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(msg,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500)),
            ]),
          ),
        ),
      ),
    );
  }

  void _openIskonto() async {
    final bool isDoviz = (fatura.dovizid != null && fatura.dovizid != 1);
    final double kur = (fatura.kur ?? 1.0).clamp(0.001, double.infinity);

    // araToplam: miktar × fiyat - satır iskontosu (genel iskonto ÖNCESİ)
    // Dövizli: dovizfiyat varsa döviz cinsinden direkt hesapla, yoksa TL / kur
    double araToplam;
    if (isDoviz) {
      araToplam = kalemler.fold(0.0, (s, k) {
        final birimFiyat =
            (k.dovizfiyat ?? 0) > 0 ? k.dovizfiyat! : (k.fiyat ?? 0) / kur;
        final satirIsk =
            (k.iskontotutar ?? 0) / kur; // satır iskonto da TL → döviz
        return s + (k.miktar ?? 0) * birimFiyat - satirIsk;
      });
    } else {
      araToplam = kalemler.fold(
          0.0,
          (s, k) =>
              s + ((k.miktar ?? 0) * (k.fiyat ?? 0)) - (k.iskontotutar ?? 0));
    }

    // Mevcut tutar: TL cinsinden saklanıyor → sheet'e döviz olarak geç
    final double? mevcutTutar = isDoviz && (genelIskontoTutari ?? 0) > 0
        ? genelIskontoTutari! / kur
        : genelIskontoTutari;

    final res = await showFaturaGenelIskontoSheet(
      context,
      oran: genelIskontoOrani,
      tutar: mevcutTutar,
      araToplam: araToplam,
      isDoviz: isDoviz,
      kur: kur,
      dovizId: fatura.dovizid,
      title: "Genel İskonto (Ara: ${araToplam.toStringAsFixed(2)})",
    );
    if (res != null) {
      setState(() {
        genelIskontoOrani = res.oran;
        if ((res.tutar ?? 0) > 0) {
          if (isDoviz) {
            // Sheet döviz tutarı döndü → TL'ye çevir
            genelIskontoTutari = res.tutar! * kur;
            fatura.dovizgeneliskontotutar = res.tutar;
          } else {
            genelIskontoTutari = res.tutar;
            fatura.dovizgeneliskontotutar = null;
          }
        } else {
          genelIskontoOrani = null;
          genelIskontoTutari = null;
          fatura.dovizgeneliskontotutar = null;
          fatura.geneliskontotutar = null;
          fatura.geneliskontooran = null;
        }
        _recalcFaturaToplam();
      });
    }
  }

  // --- YARDIMCI WIDGETLAR ---
  Widget _inputLabel(String label) => Padding(
      padding: const EdgeInsets.only(left: 2, bottom: 4),
      child: Text(label,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: _scheme.onSurfaceVariant)));

  Widget _buildSectionCard({
    String? title,
    IconData? icon,
    Color? iconColor,
    required List<Widget> children,
  }) {
    final bool hasHeader = (title != null && title.isNotEmpty) || icon != null;

    return Container(
      padding: EdgeInsets.all(_modern ? 16 : 12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: _scheme.surface,
        border:
            Border.all(color: _scheme.outlineVariant.withValues(alpha: .45)),
        borderRadius: BorderRadius.circular(_modern ? 18 : 16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: _modern ? 0 : .015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 18, color: iconColor ?? primaryColor),
                  const SizedBox(width: 8),
                ],
                if (title != null && title.isNotEmpty)
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: iconColor ?? primaryColor,
                    ),
                  ),
              ],
            ),
            const Divider(height: 20, thickness: 0.5),
          ],
          ...children,
        ],
      ),
    );
  }

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
                        size: 20, color: Colors.grey)
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
              border: Border.all(color: _scheme.outlineVariant)),
          child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
                  value: safeValue,
                  items: items,
                  onChanged: onChanged,
                  isExpanded: true,
                  isDense: true,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: _scheme.onSurface)))),
    ]);
  }

// ─── Açıklama alanı yardımcıları ─────────────────────────────────────────
  String? _getAciklamaField(int n) {
    switch (n) {
      case 1:
        return fatura.aciklama1;
      case 2:
        return fatura.aciklama2;
      case 3:
        return fatura.aciklama3;
      case 4:
        return fatura.aciklama4;
      case 5:
        return fatura.aciklama5;
      case 6:
        return fatura.aciklama6;
      case 7:
        return fatura.aciklama7;
      case 8:
        return fatura.aciklama8;
      case 9:
        return fatura.aciklama9;
      case 10:
        return fatura.aciklama10;
      case 11:
        return fatura.aciklama11;
      case 12:
        return fatura.aciklama12;
      case 13:
        return fatura.aciklama13;
      case 14:
        return fatura.aciklama14;
      case 15:
        return fatura.aciklama15;
      case 16:
        return fatura.aciklama16;
      case 17:
        return fatura.aciklama17;
      case 18:
        return fatura.aciklama18;
      case 19:
        return fatura.aciklama19;
      case 20:
        return fatura.aciklama20;
      default:
        return null;
    }
  }

  void _setAciklamaField(int n, String v) {
    switch (n) {
      case 1:
        fatura.aciklama1 = v;
        break;
      case 2:
        fatura.aciklama2 = v;
        break;
      case 3:
        fatura.aciklama3 = v;
        break;
      case 4:
        fatura.aciklama4 = v;
        break;
      case 5:
        fatura.aciklama5 = v;
        break;
      case 6:
        fatura.aciklama6 = v;
        break;
      case 7:
        fatura.aciklama7 = v;
        break;
      case 8:
        fatura.aciklama8 = v;
        break;
      case 9:
        fatura.aciklama9 = v;
        break;
      case 10:
        fatura.aciklama10 = v;
        break;
      case 11:
        fatura.aciklama11 = v;
        break;
      case 12:
        fatura.aciklama12 = v;
        break;
      case 13:
        fatura.aciklama13 = v;
        break;
      case 14:
        fatura.aciklama14 = v;
        break;
      case 15:
        fatura.aciklama15 = v;
        break;
      case 16:
        fatura.aciklama16 = v;
        break;
      case 17:
        fatura.aciklama17 = v;
        break;
      case 18:
        fatura.aciklama18 = v;
        break;
      case 19:
        fatura.aciklama19 = v;
        break;
      case 20:
        fatura.aciklama20 = v;
        break;
    }
  }

  Widget _buildAciklamalarButton() {
    final count = _aciklamaCtrlList.where((c) => c.text.isNotEmpty).length;
    return OutlinedButton.icon(
      onPressed: _showAciklamalarPage,
      style: OutlinedButton.styleFrom(
        foregroundColor: count > 0 ? _scheme.primary : _scheme.onSurfaceVariant,
        backgroundColor: _scheme.surface,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 13),
        side: BorderSide(color: _scheme.outlineVariant),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.notes_rounded, size: 17),
      label: Text(count > 0 ? 'Açıklamalar ($count)' : 'Açıklamalar',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
    );
  }

  void _showAciklamalarPage() {
    Navigator.push(
      context,
      PermissionMaterialPageRoute(
        builder: (ctx) => Scaffold(
          appBar: AppBar(
            title: const Text("Açıklamalar"),
            backgroundColor: _scheme.primary,
            foregroundColor: _scheme.onPrimary,
            elevation: 0,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Tamam",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: 20,
            itemBuilder: (_, i) {
              final n = i + 1;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                decoration: BoxDecoration(
                  color: _scheme.surface,
                  borderRadius: BorderRadius.circular(
                      ErpDesignStyle.modern(context) ? 18 : 12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Açıklama $n",
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _scheme.onSurfaceVariant,
                            letterSpacing: 0.3)),
                    const SizedBox(height: 6),
                    TextFormField(
                      controller: _aciklamaCtrlList[i],
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8)),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: _scheme.outlineVariant)),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide:
                                BorderSide(color: primaryColor, width: 1.5)),
                      ),
                      onChanged: (v) => _setAciklamaField(n, v),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    ).then((_) => setState(() {})); // Geri dönünce badge güncellenir
  }

  Widget _buildVadeRow() {
    return Row(
      children: [
        // Vade Günü
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inputLabel("Vade Günü"),
              SizedBox(
                height: 45,
                child: TextFormField(
                  controller: _vadegununCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(fontSize: 13),
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _scheme.outlineVariant),
                    ),
                  ),
                  onChanged: (v) {
                    final vg = int.tryParse(v) ?? 0;
                    setState(() {
                      fatura.vadegunu = vg;
                      _recalcVadeTarihi();
                    });
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Vade Tarihi
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _inputLabel("Vade Tarihi"),
              InkWell(
                onTap: () async {
                  final d = await showDatePicker(
                    context: context,
                    initialDate: fatura.vadetarihi ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (d != null) {
                    setState(() {
                      fatura.vadetarihi = d;
                      _vadeTarihCtrl.text = _formatDate(d);
                      // Vade tarihinden gün farkını hesapla
                      final tarih = fatura.tarih ?? DateTime.now();
                      final fark = d.difference(tarih).inDays;
                      fatura.vadegunu = fark < 0 ? 0 : fark;
                      _vadegununCtrl.text = fatura.vadegunu.toString();
                    });
                  }
                },
                child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _scheme.outlineVariant),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_vadeTarihCtrl.text,
                          style: const TextStyle(fontSize: 13)),
                      const Icon(Icons.calendar_month,
                          size: 18, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value,
      {bool isBold = false,
      double fontSize = 14,
      Color? color,
      String? subValue}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: color),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
                    color: color),
              ),
              if (subValue != null)
                Text(
                  subValue,
                  style: TextStyle(
                      fontSize: (fontSize - 2).clamp(9.0, 14.0),
                      color: _scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w400),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
