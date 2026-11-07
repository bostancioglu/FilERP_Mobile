import '../../../helpers/warehouse_line_fields.dart';
import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../models/entities/depo/dat_dto.dart';
import '../../../models/entities/depo/dathareket_dto.dart';
import '../../../models/entities/depo/depo_dto.dart';
import '../../../models/entities/stok/stok_list_dto.dart';
import '../../../models/entities/stok/stok_dto.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../../models/entities/referans/referans_dto.dart';
import '../../../models/entities/yonetim/belge_seri_dto.dart';
import '../../../services/depo/depo_service.dart';
import '../../../services/depo/dat/dat_service.dart';
import '../../../services/yonetim/belgeseri_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../services/plasiyer/plasiyer_service.dart';
import '../../../services/referans/referans_service.dart';
import '../../../services/stok/stok_service.dart';
import '../../../services/offline/offline_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/arac_yukleme_fis_helper.dart';
import '../../../helpers/varsayilan_proje_helper.dart';
import '../../../helpers/varsayilan_depo_helper.dart';
import '../../../helpers/plasiyer_depo_helper.dart';
import '../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../helpers/hata_sesi.dart';
import '../../../helpers/number_format_helper.dart';
import '../../../helpers/belge_turu_couples.dart';
import '../../../widgets/dat/dat_kalem_form_sheet.dart';
import '../../../widgets/quick_barcode_scan_sheet.dart';
import '../../../widgets/barcode_scanner_sheet.dart';
import '../../../widgets/erp_selector.dart';
import '../../../services/yazici/bluetooth_print_service.dart';

class AracYukleEklePage extends StatefulWidget {
  final String? datId;

  /// Offline kuyruktaki bir kaydı düzenlemek için kullanılır
  final OfflineQueueItem? queueItem;
  const AracYukleEklePage({super.key, this.datId, this.queueItem});
  @override
  State<AracYukleEklePage> createState() => _AracYukleEklePageState();
}

class _AracYukleEklePageState extends State<AracYukleEklePage>
    with SingleTickerProviderStateMixin {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _positive => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFF6EE7B7)
      : Color(0xFF16704A);
  Color get _primary => _scheme.onSurface;
  Color get _accent => _scheme.primary;

  static const _kalemKaydetBekleme = Duration(milliseconds: 700);

  late TabController _tabCtrl;
  final _svc = DatService();

  bool _loading = true;
  String? _yeniDatId;
  final _dat = DatDto();
  String? _seciliSeri;
  int _seciliYil = DateTime.now().year;
  List<int> _yilListesi = [];

  List<BelgeSeriDto> _belgeSeriListesi = [];
  List<DepoDto> _depolar = []; // çıkacağı depolar (kendi şubesi)
  List<DepoDto> _gidecekDepolar = []; // gideceği depolar (seçilen şube)
  List<ProjeDto> _projeler = [];
  List<PlasiyerDto> _plasiyerler = [];
  List<ReferansDto> _referanslar = [];
  List<StokListDto> _stoklar = [];
  final List<DathareketDto> _kalemler = [];

  // Terminal barkod
  final StringBuffer _barkodBuffer = StringBuffer();
  DateTime? _sonTus;
  static const _barkodTimeout = Duration(milliseconds: 80);

  final _belgeNoCtrl = TextEditingController();
  final _tarihCtrl = TextEditingController();
  final _teslimTarihCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();

  KullaniciPlasiyer _kp = KullaniciPlasiyer();
  int? _merkezDepoId; // çıkış (merkez) deposu varsayılanı
  int? _plasiyerDepoId; // sevk (plasiyer / araç) deposu varsayılanı

  /// Bu ekranda hata olunca yüksek sesli uyarı da çalar (gürültülü ortam / el terminali).
  void _hata(String m) {
    HataSesi.cal();
    UiFeedback.showError(context, m);
  }

  void _uyari(String m) {
    HataSesi.cal();
    UiFeedback.showWarning(context, m);
  }

  // ── Çıkış uyarısı: yanlışlıkla geri basınca girilen bilgiler gitmesin ───────────
  String _ilkImza = '';
  static const _ayirac = '\u0001'; // kullanıcı metninde geçmeyen ayırıcı

  /// Üst bilgi + kalemlerin özeti. Yükleme / kayıt sonrası alınan özetten farklıysa değişiklik var demektir.
  String _imza() => [
        _tarihCtrl.text,
        _seciliSeri,
        _seciliYil,
        _dat.projeid,
        _dat.referansid,
        _dat.plasiyerid,
        _aciklamaCtrl.text,
        _kalemler
            .map((k) =>
                '${k.id}|${k.stokid}|${k.stokozelliksabitid}|${k.miktar}|${k.olcubrid}|${k.cikacagidepoid}|${k.gidecegidepoid}|${k.aciklama}')
            .join(';'),
      ].join(_ayirac);

  bool get _degisiklikVar =>
      !_loading && _ilkImza.isNotEmpty && _imza() != _ilkImza;

  /// Sunucuya henüz yazılmamış bir şey var mı (kaydedilmemiş kalem veya üst bilgi değişikliği)?
  bool get _kaydedilmemisVar =>
      _kalemler.any((k) => k.id == null) || _ustBilgiDegisti;

  bool get _ustBilgiDegisti {
    final k = _imza().split(_ayirac);
    final i = _ilkImza.split(_ayirac);
    // son parça kalem özeti: üst bilgi = ilk 7 parça
    for (var x = 0; x < 7 && x < k.length && x < i.length; x++) {
      if (k[x] != i[x]) return true;
    }
    return false;
  }

  Future<void> _cikisSor() async {
    final kaybolur = _kaydedilmemisVar;
    final cik = await UiFeedback.confirm(
      context,
      title: 'Sayfadan Çık',
      message: kaybolur
          ? 'Kaydedilmemiş bilgiler var. Çıkarsanız kaybolacak. Çıkmak istiyor musunuz?'
          : 'Araç yükleme taslak olarak kaydedildi ancak tamamlanmadı. Çıkmak istiyor musunuz?',
      confirmLabel: 'Çık',
      cancelLabel: 'Kal',
      destructive: kaybolur,
    );
    if (cik == true && mounted) Navigator.of(context).pop();
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _yilListesi = List.generate(5, (i) => DateTime.now().year - i);
    _dat.belgeturu = BelgeTuruCouples.depolarArasiTransfer;
    _dat.tarih = DateTime.now();
    _dat.teslimtarihi = DateTime.now();
    _tarihCtrl.text = _fmtDate(DateTime.now());
    _teslimTarihCtrl.text = _fmtDate(DateTime.now());
    _aciklamaCtrl.addListener(() {
      if (mounted) setState(() {});
    });
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
    _teslimTarihCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime? d) =>
      d == null ? '' : DateFormat('dd.MM.yyyy').format(d);

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final subeId = prefs.getInt("sube_id") ?? 0;

      List<BelgeSeriDto> belgeSeriListesi = [];
      List<DepoDto> depolar = [];
      List<ProjeDto> projeler = [];
      List<PlasiyerDto> plasiyerler = [];
      List<ReferansDto> referanslar = [];
      List<StokListDto> stoklar = [];

      try {
        belgeSeriListesi = await BelgeSeriService()
            .getAll(token, BelgeTuruCouples.depolarArasiTransfer);
      } catch (e) {
        debugPrint(">>> belgeSeri HATA: $e");
      }
      try {
        depolar = await _svc.getDepoListBySubeId(token, subeId);
      } catch (e) {
        debugPrint(">>> depolar HATA: $e");
      }
      try {
        projeler = (await ProjeService().getProjeList(token))
            .where((p) => p.tur == 3)
            .toList()
          ..sort((a, b) => (a.kod ?? '').compareTo(b.kod ?? ''));
      } catch (e) {
        debugPrint(">>> projeler HATA: $e");
      }
      try {
        plasiyerler = await PlasiyerService().getPlasiyerler(token);
      } catch (e) {
        debugPrint(">>> plasiyerler HATA: $e");
      }
      try {
        referanslar = await ReferansService().getAll(token);
      } catch (e) {
        debugPrint(">>> referanslar HATA: $e");
      }
      try {
        stoklar = await StokService().getStokList(token);
      } catch (e) {
        debugPrint(">>> stoklar HATA: $e");
      }

      final belgeSeriListesiF = belgeSeriListesi;
      final depolarF = depolar;
      final projelerF = projeler;
      final plasiyerlerF = plasiyerler;
      final referanslarF = referanslar;
      final stoklarF = stoklar;

      _kp = await KullaniciPlasiyerHelper.getir();
      final varsayilanProjeId = await VarsayilanProjeHelper.pickFrom(projelerF);
      if (!mounted) return;
      setState(() {
        _belgeSeriListesi = belgeSeriListesiF;
        _depolar = depolarF;
        _projeler = projelerF;
        _plasiyerler = plasiyerlerF;
        _referanslar = referanslarF;
        _stoklar = stoklarF;
        _loading = false;
        if (projelerF.isNotEmpty && _dat.projeid == null)
          _dat.projeid = varsayilanProjeId;
        // Plasiyer kullanıcıda kendi plasiyeri (kilitli); diğerlerinde ilk plasiyer ATANMAZ, seçilir.
        if (_kp.kilitli && _dat.plasiyerid == null)
          _dat.plasiyerid = _kp.plasiyerid;
        if (_belgeSeriListesi.isNotEmpty && _seciliSeri == null) {
          _seciliSeri = _belgeSeriListesi.first.seri;
          _dat.belgeseri = _seciliSeri;
        }
        // Gideceği şube default: girişteki kendi şubesi
        if (_dat.gidecegisubeid == null && subeId > 0) {
          _dat.gidecegisubeid = subeId;
        }
      });

      if (widget.queueItem != null) {
        // Offline kuyruk kaydını düzenle
        await _loadFromQueueItem(widget.queueItem!);
      } else if (widget.datId != null) {
        await _loadMevcutDat(token);
      } else {
        if (_seciliSeri != null) _fetchYeniDatNo();
        // Gideceği şube default seçildiyse depolarını yükle
        if (_dat.gidecegisubeid != null) {
          await _loadGidecekDepolar(_dat.gidecegisubeid!);
        }
      }
      // Kayıtlı belge açıldıysa varsayılan depolar belgenin kendi kalemlerinden alınır
      await _depoVarsayilanlariniBelirle(token,
          kalemlerdenAl: widget.datId != null || widget.queueItem != null);
      if (mounted) setState(() => _ilkImza = _imza());
    } catch (e, stack) {
      debugPrint(">>> loadLookups HATA: $e\n$stack");
      if (mounted) {
        setState(() => _loading = false);
        _hata(e.toString());
      }
    }
  }

  /// Çıkış deposu = merkez, Sevk (giriş) deposu = plasiyerin deposu.
  /// Plasiyer deposu: depo kartında "Plasiyer deposu" işaretli ve plasiyeri bu kişi olan depo (tam depo listesi yetki
  /// ister); yoksa plasiyer kullanıcının Ayarlar > Varsayılan Depo seçimi kullanılır.
  Future<void> _depoVarsayilanlariniBelirle(String token,
      {bool kalemlerdenAl = false}) async {
    final pid = _dat.plasiyerid;
    int? plasiyerDepo;
    if (pid != null) {
      // Tam depo listesi → yetki yoksa Depo/Search ile okunur (Ayarlar yedeği aşağıda)
      plasiyerDepo = await PlasiyerDepoHelper.getId(token, pid);
    }
    final varsayilan = await VarsayilanDepoHelper.getSecilenId();
    if (plasiyerDepo == null &&
        _kp.kilitli &&
        varsayilan != null &&
        _gidecekDepolar.any((d) => d.id == varsayilan)) {
      plasiyerDepo = varsayilan;
    }
    int? merkez;
    if (varsayilan != null &&
        varsayilan != plasiyerDepo &&
        _depolar.any((d) => d.id == varsayilan)) {
      merkez = varsayilan;
    }
    merkez ??= _depolar
        .where((d) => d.id != null && d.id != plasiyerDepo)
        .firstOrNull
        ?.id;
    if (kalemlerdenAl) {
      // Kayıtlı taslakta çıkış / sevk deposu belgenin kendi kalemlerinde yazılıdır; yetki ya da
      // şube filtresi yüzünden otomatik bulunamasa da bunlar esas alınır.
      final cikis =
          _kalemler.map((k) => k.cikacagidepoid).whereType<int>().firstOrNull;
      final sevk =
          _kalemler.map((k) => k.gidecegidepoid).whereType<int>().firstOrNull;
      if (cikis != null) merkez = cikis;
      if (sevk != null) plasiyerDepo = sevk;
    }
    if (mounted) {
      setState(() {
        _plasiyerDepoId = plasiyerDepo;
        _merkezDepoId = merkez;
      });
    }
  }

  Future<void> _plasiyerDegisti() async {
    final prefs = await SharedPreferences.getInstance();
    await _depoVarsayilanlariniBelirle(prefs.getString("token_final") ?? "");
  }

  DathareketDto _yeniKalemSablonu() => DathareketDto()
    ..belgeturu = _dat.belgeturu ?? BelgeTuruCouples.depolarArasiTransfer
    ..projeid = _dat.projeid
    ..cikacagidepoid = _merkezDepoId
    ..gidecegidepoid = _plasiyerDepoId;

  bool _dinamikMi(List<DepoDto> liste, int? id) =>
      liste.any((d) => d.id == id && d.dinamikdepo == true);

  /// Hızlı / barkodla ekleme kalem formunu atladığı için depolar önceden belli olmalı.
  bool _depoVarsayilanlariHazir() {
    if (_merkezDepoId != null && _plasiyerDepoId != null) return true;
    _hata(
        'Plasiyer deposu bulunamadı. Önce plasiyeri seçin ya da "Kalem Ekle" ile depoları elle seçin.');
    return false;
  }

  Future<void> _loadMevcutDat(String token) async {
    try {
      debugPrint(">>> loadMevcutDat: ${widget.datId}");
      final mevcut = await _svc.getById(token, widget.datId!);
      debugPrint(
          ">>> loadMevcutDat OK: ${mevcut.id}, kalem: ${mevcut.dathareket.length}");
      if (!mounted) return;
      setState(() {
        // Üst bilgiler
        _yeniDatId = mevcut.id;
        _dat.gidecegisubeid = mevcut.gidecegisubeid;
        _dat.projeid = mevcut.projeid;
        _dat.plasiyerid = mevcut.plasiyerid;
        _dat.referansid = mevcut.referansid;
        _dat.belgeseri = mevcut.belgeseri;
        _dat.belgeturu =
            mevcut.belgeturu ?? BelgeTuruCouples.depolarArasiTransfer;
        _dat.belgeyil = mevcut.belgeyil;
        _dat.belgeno = mevcut.belgeno;
        _dat.tarih = mevcut.tarih;
        _dat.teslimtarihi = mevcut.teslimtarihi;
        _dat.aciklama = mevcut.aciklama;

        _seciliSeri = mevcut.belgeseri;
        _seciliYil = mevcut.belgeyil ?? DateTime.now().year;

        _belgeNoCtrl.text = mevcut.belgeno ?? '';
        _tarihCtrl.text = _fmtDate(mevcut.tarih);
        _teslimTarihCtrl.text = _fmtDate(mevcut.teslimtarihi);
        _aciklamaCtrl.text = mevcut.aciklama ?? '';

        // Kalemler
        _kalemler.clear();
        _kalemler.addAll(mevcut.dathareket);
      });

      // Gideceği şubenin depolarını yükle
      if (mevcut.gidecegisubeid != null) {
        await _loadGidecekDepolar(mevcut.gidecegisubeid!);
      }
      _kalemDepolariniListeyeEkle();
    } catch (e, stack) {
      debugPrint(">>> loadMevcutDat HATA: $e\n$stack");
      if (mounted) _hata("Araç yükleme yüklenemedi: $e");
    }
  }

  /// Kayıtlı belge açılırken: kalemlerin depoları liste lookup'larında yoksa (yetki / şube / plasiyer
  /// filtresi) sunucudan gelen iç içe depo bilgisiyle listelere eklenir. Böylece kalem kartı ve kalem
  /// formu çıkış / sevk depolarını boş göstermez.
  void _kalemDepolariniListeyeEkle() {
    if (!mounted) return;
    final cikis = [..._depolar];
    final giris = [..._gidecekDepolar];
    for (final k in _kalemler) {
      final c = k.cikacagidepo;
      if (c?.id != null && !cikis.any((d) => d.id == c!.id)) cikis.add(c!);
      final g = k.gidecegidepo;
      if (g?.id != null && !giris.any((d) => d.id == g!.id)) giris.add(g!);
    }
    if (cikis.length != _depolar.length ||
        giris.length != _gidecekDepolar.length) {
      setState(() {
        _depolar = cikis;
        _gidecekDepolar = giris;
      });
    }
  }

  Future<void> _loadFromQueueItem(OfflineQueueItem item) async {
    final dat = item.payload['dat'] as Map<String, dynamic>;
    final kalemlerR = item.payload['kalemler'] as List<dynamic>;

    if (!mounted) return;
    setState(() {
      _dat.gidecegisubeid = dat['gidecegisubeid'] as int?;
      _dat.projeid = dat['projeid'] as int?;
      _dat.plasiyerid = dat['plasiyerid'] as int?;
      _dat.referansid = dat['referansid'] as int?;
      _dat.belgeseri = dat['belgeseri'] as String?;
      _dat.belgeturu =
          dat['belgeturu'] as int? ?? BelgeTuruCouples.depolarArasiTransfer;
      _seciliSeri = dat['belgeseri'] as String?;
      _seciliYil = dat['belgeyil'] as int? ?? DateTime.now().year;
      _dat.belgeno = dat['belgeno'] as String?;
      _dat.tarih = dat['tarih'] != null
          ? DateTime.tryParse(dat['tarih'] as String)
          : DateTime.now();
      _dat.teslimtarihi = dat['teslimtarihi'] != null
          ? DateTime.tryParse(dat['teslimtarihi'] as String)
          : DateTime.now();
      _dat.aciklama = dat['aciklama'] as String?;

      _belgeNoCtrl.text = _dat.belgeno ?? '';
      _tarihCtrl.text = _fmtDate(_dat.tarih);
      _teslimTarihCtrl.text = _fmtDate(_dat.teslimtarihi);
      _aciklamaCtrl.text = _dat.aciklama ?? '';

      // Kalemleri yükle — stok adını _stoklar listesinden bul
      _kalemler.clear();
      for (final raw in kalemlerR) {
        final km = Map<String, dynamic>.from(raw as Map);
        final k = DathareketDto.fromJson(warehouseDraftJson(km));
        // Stok adını _stoklar listesinden bul
        if (k.stokid != null) {
          final s = _stoklar.where((s) => s.Id == k.stokid).firstOrNull;
          if (s != null) k.stok = StokDto(Id: s.Id, Kod: s.Kod, Ad: s.Ad);
        }
        _kalemler.add(k);
      }
    });

    if (_dat.gidecegisubeid != null) {
      await _loadGidecekDepolar(_dat.gidecegisubeid!);
    }
  }

  Future<void> _loadGidecekDepolar(int subeId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final list = await _svc.getDepoListBySubeId(token, subeId);
      if (mounted) setState(() => _gidecekDepolar = list);
    } catch (e) {}
  }

  // TODO(arac-yukle): Belge no burada DAT ile aynı mantıkla (seri+yıl
  // sıradaki no) çekiliyor — kullanıcı Araç Yükleme için farklı bir belge no
  // kaynağı tarif edecek, o geldiğinde bu metod güncellenecek.
  Future<void> _fetchYeniDatNo() async {
    if (_seciliSeri == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final no = await _svc.getNewDatNo(token, _seciliSeri!, _seciliYil);
      if (mounted)
        setState(() {
          _dat.belgeno = no;
          _belgeNoCtrl.text = no;
        });
    } catch (_) {}
  }

  Future<void> _pickDate(
      DateTime? current, void Function(DateTime) onPicked) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) onPicked(picked);
  }

  Map<String, dynamic> _hareketToInsertJson(DathareketDto k, String datId) =>
      k.toWarehouseJson(datId);
  Map<String, dynamic> _hareketToUpdateJson(DathareketDto k, String datId) =>
      k.toWarehouseJson(datId, includeId: true);

  Map<String, dynamic> _datToDto(int subeId) => <String, dynamic>{
        "subeid": subeId,
        "gidecegisubeid": _dat.gidecegisubeid,
        "projeid": _dat.projeid,
        "plasiyerid": _dat.plasiyerid,
        "referansid": _dat.referansid,
        "belgeseri": _dat.belgeseri,
        "belgeyil": _seciliYil,
        "belgeno": _dat.belgeno,
        "belgeturu": _dat.belgeturu ?? BelgeTuruCouples.depolarArasiTransfer,
        "tarih": _dat.tarih?.toIso8601String(),
        "teslimtarihi": _dat.teslimtarihi?.toIso8601String(),
        "aciklama": _dat.aciklama,
        "ebelgetip": 0,
        "kayityeri": _dat.kayityeri,
      };

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
    final barkod = await Navigator.push<String>(context,
        PermissionMaterialPageRoute(builder: (_) => BarcodeScannerSheet()));
    if (barkod != null && barkod.isNotEmpty && mounted) {
      _barkodIleStokveBulKalemAc(barkod);
    }
  }

  Future<void> _addDirekBarkodKalem() async {
    // Handler diyalog açıkken eventleri tüketir → geçici kapat
    HardwareKeyboard.instance.removeHandler(_terminalBarkodHandler);
    String barkod = '';
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text("Barkod Gir",
            style: TextStyle(fontFamily: 'Roboto', fontSize: 15)),
        content: TextField(
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(hintText: "Barkod veya stok kodu"),
          onChanged: (v) => barkod = v,
          onSubmitted: (v) {
            barkod = v;
            Navigator.pop(ctx);
          },
        ),
        actions: [
          ErpDialogAction(
              onPressed: () => Navigator.pop(ctx), child: Text("İptal")),
          ErpDialogAction(
              onPressed: () => Navigator.pop(ctx), child: Text("Ekle")),
        ],
      ),
    );
    HardwareKeyboard.instance.addHandler(_terminalBarkodHandler);
    if (barkod.trim().isNotEmpty && mounted) {
      _barkodIleStokveBulKalemAc(barkod.trim());
    }
  }

  Future<void> _barkodIleStokveBulKalemAc(String barkod) async {
    if (!_depoVarsayilanlariHazir()) return;
    if (_dat.gidecegisubeid == null) {
      if (mounted) _uyari("Kalem eklemeden önce gideceği şubeyi seçiniz!");
      return;
    }
    final eslesme = _stoklar
        .where((s) =>
            s
                .getBarkodListesi()
                .any((b) => b.toLowerCase() == barkod.toLowerCase()) ||
            (s.Kod ?? '').toLowerCase() == barkod.toLowerCase())
        .firstOrNull;
    if (eslesme == null) {
      if (mounted) _uyari("Barkod eşleşmedi: $barkod");
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final subeId = prefs.getInt("sube_id") ?? 0;
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;

    final k = DathareketDto()
      ..stokid = eslesme.Id
      ..stok = StokDto(Id: eslesme.Id, Kod: eslesme.Kod, Ad: eslesme.Ad)
      ..belgeturu = _dat.belgeturu ?? BelgeTuruCouples.depolarArasiTransfer
      ..projeid =
          _dat.projeid ?? (await VarsayilanProjeHelper.pickFrom(_projeler))
      ..miktar = 1
      ..cikacagisubeid = subeId
      ..gidecegisubeid = _dat.gidecegisubeid;

    await _applyQuickModeDefaults(
      k,
      token: token,
      manuelOffline: manuelOffline,
      internetYok: internetYok,
      cikisAdresCache: {},
      girisAdresCache: {},
    );
    if (!manuelOffline && !internetYok) {
      await _tryFillOlcuBirim(k, token);
    }

    if (manuelOffline || internetYok) {
      if (mounted) {
        setState(() {
          _kalemler.add(k);
          _tabCtrl.animateTo(1);
        });
        UiFeedback.showSuccess(
            context, "${eslesme.Ad ?? barkod} eklendi (offline)");
      }
      return;
    }

    if (_yeniDatId == null) {
      try {
        _yeniDatId = await _svc.saveSingle(token, _datToDto(subeId));
      } catch (e) {
        if (mounted) _hata("Araç yükleme kaydedilemedi: $e");
        return;
      }
    }
    try {
      final hId =
          await _svc.saveHareket(token, _hareketToInsertJson(k, _yeniDatId!));
      if (hId != null) k.id = hId;
      if (mounted) {
        setState(() {
          _kalemler.add(k);
          _tabCtrl.animateTo(1);
        });
        UiFeedback.showSuccess(context, "${eslesme.Ad ?? barkod} eklendi");
      }
    } catch (e) {
      if (mounted) _hata("Kalem kaydedilemedi: $e");
    }
  }

  Future<void> _addKalem() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final subeId = prefs.getInt("sube_id") ?? 0;

    final k = await showDatKalemForm(context,
        stoklar: _stoklar,
        projeler: _projeler,
        cikisDepolar: _depolar,
        girisDepolar: _gidecekDepolar,
        baslangic: _yeniKalemSablonu(),
        sade: true,
        hataSesi: true);
    if (k == null || !mounted) return;

    // ── Offline mod (manuel VEYA internet yok) ───────────────────────────
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (manuelOffline || internetYok) {
      if (_dat.gidecegisubeid == null) {
        _uyari("Kalem eklemeden önce gideceği şubeyi seçiniz!");
        return;
      }
      k.cikacagisubeid = subeId;
      k.gidecegisubeid = _dat.gidecegisubeid;
      if (mounted)
        setState(() {
          _kalemler.add(k);
          _tabCtrl.animateTo(1);
        });
      UiFeedback.showSuccess(context, "Kalem eklendi (offline)");
      return;
    }
    // ── Online mod ───────────────────────────────────────────────────────

    if (_yeniDatId == null) {
      if (_dat.gidecegisubeid == null) {
        _uyari("Kalem eklemeden önce gideceği şubeyi seçiniz!");
        return;
      }
      try {
        _yeniDatId = await _svc.saveSingle(token, _datToDto(subeId));
      } catch (e) {
        if (mounted) _hata("Araç yükleme kaydedilemedi: $e");
        return;
      }
    }

    try {
      // Şube id'lerini kalem'e set et
      k.cikacagisubeid = subeId;
      k.gidecegisubeid = _dat.gidecegisubeid;
      final hId =
          await _svc.saveHareket(token, _hareketToInsertJson(k, _yeniDatId!));
      if (hId != null) k.id = hId;
      if (mounted)
        setState(() {
          _kalemler.add(k);
          _tabCtrl.animateTo(1);
        });
    } catch (e) {
      if (mounted) _hata("Kalem kaydedilemedi: $e");
    }
  }

  Future<void> _addHizliBarkodKalemler() async {
    if (!_depoVarsayilanlariHazir()) return;
    if (_dat.gidecegisubeid == null) {
      _uyari("Kalem eklemeden önce gideceği şubeyi seçiniz!");
      return;
    }

    final result = await showQuickBarcodeScanSheet(
      context,
      stoklar: _stoklar,
      title: "Hızlı Barkod Okut",
      hataSesi: true,
    );
    if (result == null || result.lines.isEmpty || !mounted) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final subeId = prefs.getInt("sube_id") ?? 0;
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    final yeniKalemler = <DathareketDto>[];
    final cikisAdresCache = <int, String?>{};
    final girisAdresCache = <int, String?>{};

    for (final line in result.lines) {
      final stok = line.stok;
      if (stok == null || stok.Id == null) {
        continue;
      }

      final k = DathareketDto();
      k.stokid = stok.Id;
      k.stok = StokDto(Id: stok.Id, Kod: stok.Kod, Ad: stok.Ad);
      k.belgeturu = _dat.belgeturu ?? BelgeTuruCouples.depolarArasiTransfer;
      k.projeid =
          _dat.projeid ?? (await VarsayilanProjeHelper.pickFrom(_projeler));
      k.miktar = line.quantity;
      k.cikacagisubeid = subeId;
      k.gidecegisubeid = _dat.gidecegisubeid;
      await _applyQuickModeDefaults(
        k,
        token: token,
        manuelOffline: manuelOffline,
        internetYok: internetYok,
        cikisAdresCache: cikisAdresCache,
        girisAdresCache: girisAdresCache,
      );

      if (!manuelOffline && !internetYok) {
        await _tryFillOlcuBirim(k, token);
      }
      yeniKalemler.add(k);
    }

    await OfflineService.instance.saveBarcodeScanHistory(
      belgeTuru: _dat.belgeturu ?? BelgeTuruCouples.depolarArasiTransfer,
      moduleKey: 'dat',
      belgeNo: _dat.belgeno,
      rawBarcodes: result.rawBarcodes,
      summary: _buildBarcodeHistorySummary(result.lines),
    );

    if (yeniKalemler.isEmpty) {
      if (!mounted) {
        return;
      }
      _uyari("Eklenecek stok bulunamadı!");
      return;
    }

    if (manuelOffline || internetYok) {
      if (mounted) {
        setState(() {
          _kalemler.addAll(yeniKalemler);
          _tabCtrl.animateTo(1);
        });
      }
      if (mounted) {
        UiFeedback.showSuccess(
            context, "${yeniKalemler.length} kalem eklendi (offline)");
      }
      return;
    }

    if (_yeniDatId == null) {
      try {
        _yeniDatId = await _svc.saveSingle(token, _datToDto(subeId));
      } catch (e) {
        if (mounted) _hata("Araç yükleme kaydedilemedi: $e");
        return;
      }
    }

    try {
      for (int i = 0; i < yeniKalemler.length; i++) {
        final k = yeniKalemler[i];
        final hId =
            await _svc.saveHareket(token, _hareketToInsertJson(k, _yeniDatId!));
        if (hId != null) {
          k.id = hId;
        }
        await _waitBeforeNextKalemSave(i, yeniKalemler.length);
      }
      if (mounted) {
        setState(() {
          _kalemler.addAll(yeniKalemler);
          _tabCtrl.animateTo(1);
        });
      }
      if (mounted) {
        UiFeedback.showSuccess(context, "${yeniKalemler.length} kalem eklendi");
      }
    } catch (e) {
      if (mounted) _hata("Kalemler kaydedilemedi: $e");
    }
  }

  Future<void> _applyQuickModeDefaults(
    DathareketDto k, {
    required String token,
    required bool manuelOffline,
    required bool internetYok,
    required Map<int, String?> cikisAdresCache,
    required Map<int, String?> girisAdresCache,
  }) async {
    k.cikacagidepoid = _merkezDepoId;
    k.gidecegidepoid = _plasiyerDepoId;

    if (manuelOffline || internetYok || token.isEmpty) {
      return;
    }

    if (k.cikacagidepoid != null && _dinamikMi(_depolar, k.cikacagidepoid)) {
      k.cikacagidepoadresid = await _firstDepoAdresId(
        token,
        k.cikacagidepoid!,
        cikisAdresCache,
      );
    }
    if (k.gidecegidepoid != null &&
        _dinamikMi(_gidecekDepolar, k.gidecegidepoid)) {
      k.gidecegidepoadresid = await _firstDepoAdresId(
        token,
        k.gidecegidepoid!,
        girisAdresCache,
      );
    }
  }

  Future<String?> _firstDepoAdresId(
    String token,
    int depoId,
    Map<int, String?> cache,
  ) async {
    if (cache.containsKey(depoId)) {
      return cache[depoId];
    }
    try {
      final adresler = await DepoService().getDepoadresByDepoId(token, depoId);
      final firstId = adresler
          .where((a) => a.id != null && a.id!.isNotEmpty)
          .map((a) => a.id!)
          .firstOrNull;
      cache[depoId] = firstId;
      return firstId;
    } catch (_) {
      cache[depoId] = null;
      return null;
    }
  }

  List<Map<String, dynamic>> _buildBarcodeHistorySummary(
    List<QuickBarcodeLine> lines,
  ) {
    return lines
        .map((line) => <String, dynamic>{
              'barcode': line.barcode,
              'quantity': line.quantity,
              'stokId': line.stok?.Id,
              'stokKod': line.stok?.Kod,
              'stokAd': line.stok?.Ad,
            })
        .toList();
  }

  Future<void> _waitBeforeNextKalemSave(int index, int total) async {
    if (index >= total - 1) {
      return;
    }
    await Future.delayed(_kalemKaydetBekleme);
  }

  Future<void> _tryFillOlcuBirim(DathareketDto k, String token) async {
    if (k.stokid == null ||
        token.isEmpty ||
        !OfflineService.instance.isOnline.value) {
      return;
    }
    try {
      final stok = await StokService().getStokById(token, k.stokid!);
      k.stok = stok;
      k.stokozelliksabitid = warehouseFeatureId(stok, k.stokozelliksabitid);
      final temel = stok.Temelolcubr;
      if (temel != null) {
        k.olcubrid = temel.Id;
        k.olcubr = temel;
        return;
      }
      final ekBirim = stok.Stokolcubr.where((s) => s.Olcubr != null)
          .map((s) => s.Olcubr!)
          .firstOrNull;
      if (ekBirim != null) {
        k.olcubrid = ekBirim.Id;
        k.olcubr = ekBirim;
      }
    } catch (_) {
      // Offline veya stok detay hatasinda olcu birimi bos kalabilir.
    }
  }

  Future<void> _editKalem(int i) async {
    final res = await showDatKalemForm(context,
        kalem: _kalemler[i],
        stoklar: _stoklar,
        projeler: _projeler,
        cikisDepolar: _depolar,
        girisDepolar: _gidecekDepolar,
        sade: true,
        hataSesi: true);
    if (res == null || !mounted) return;
    setState(() => _kalemler[i] = res);
    if (res.id != null && _yeniDatId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token_final") ?? "";
        final subeId = prefs.getInt("sube_id") ?? 0;
        res.cikacagisubeid = subeId;
        res.gidecegisubeid = _dat.gidecegisubeid;
        await _svc.updateHareket(token, _hareketToUpdateJson(res, _yeniDatId!));
        if (mounted) UiFeedback.showUpdated(context, "Kalem güncellendi");
      } catch (e) {
        if (mounted) _hata(e.toString());
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
        if (mounted) _hata(e.toString());
        return;
      }
    }
    if (mounted) {
      setState(() => _kalemler.removeAt(i));
      UiFeedback.showDeleted(context, "Kalem silindi");
    }
  }

  Future<void> _showKaydetDialog() async {
    if (_dat.gidecegisubeid == null) {
      _uyari("Lütfen gideceği şubeyi seçiniz!");
      return;
    }
    if (_kalemler.isEmpty) {
      _uyari("En az bir kalem eklemelisiniz!");
      return;
    }

    // ── Offline mod kontrolü ─────────────────────────────────────────────
    // Kuyruk kaydı düzenleniyor → daima offline kaydet
    // Manuel offline mod VEYA internet yoksa kuyruğa al
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (widget.queueItem != null || manuelOffline || internetYok) {
      await _kaydetOffline(internetYok: internetYok);
      return;
    }

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.save_outlined, size: 36, color: _primary),
            ),
            SizedBox(height: 16),
            Text("Araç Yüklemeyi Kaydet",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text("Nasıl kaydetmek istersiniz?",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: _scheme.onSurfaceVariant,
                    fontSize: 13),
                textAlign: TextAlign.center),
            SizedBox(height: 24),
            // Belgeyi Tamamla
            SizedBox(
                width: double.infinity,
                child: PermissionAction(
                    modules: [801],
                    access: Access.write,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2E7D32),
                        foregroundColor: _scheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: Icon(Icons.check_circle_outline_rounded),
                      label: Text("Belgeyi Tamamla",
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _kaydetTamamla();
                      },
                    ))),
            SizedBox(height: 10),
            // Taslak Kaydet
            SizedBox(
                width: double.infinity,
                child: PermissionAction(
                    modules: [801],
                    access: Access.write,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _scheme.onSurfaceVariant,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        side: BorderSide(color: _scheme.outlineVariant),
                      ),
                      icon: Icon(Icons.save_outlined),
                      label: Text("Taslak Kaydet",
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _kaydet();
                      },
                    ))),
            SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text("İptal",
                  style: TextStyle(
                      fontFamily: 'Roboto', color: _scheme.onSurfaceVariant)),
            ),
          ]),
        ),
      ),
    );
  }

  Future<void> _kaydetOffline({bool internetYok = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final subeId = prefs.getInt("sube_id") ?? 0;

    final yeniPayload = {
      'dat': _datToDto(subeId),
      'kalemler': _kalemler.map((k) => _hareketToInsertJson(k, '')).toList(),
    };

    if (widget.queueItem != null) {
      // Mevcut kuyruk kaydını güncelle
      await OfflineService.instance
          .updateQueueItem(widget.queueItem!.localId, yeniPayload);
    } else {
      // Yeni kuyruk kaydı oluştur
      await OfflineService.instance.enqueue('dat_full', yeniPayload);
    }

    if (!mounted) return;
    final mesaj = widget.queueItem != null
        ? "Offline kayıt güncellendi"
        : internetYok
            ? "İnternet yok — Araç yükleme kuyruğa alındı, bağlantı gelince gönderilecek"
            : "Araç yükleme kuyruğa eklendi — online olunca gönderilecek";
    UiFeedback.showSuccess(context, mesaj);
    Navigator.pop(context, true);
  }

  Future<void> _kaydetTamamla() async {
    // pop: false — liste sayfasına ancak belge durumu da "tamamlandı" olarak
    // güncellendikten SONRA döneceğiz, aksi halde liste taslak durumuyla
    // yenilenip kullanıcı "tamamlandı" belgeyi taslak olarak görüyordu.
    await _kaydet(pop: false);
    if (!mounted) return;
    final datId = _yeniDatId;
    if (datId == null)
      return; // kayıt başarısız — hata zaten gösterildi, sayfada kal
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await _svc.belgeDurumGuncelle(token, datId, 1);
      if (!mounted) return;
      await _teslimFisiSor();
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      _hata("Tamamlama hatası: $e");
    }
  }

  /// Belge tamamlandıktan sonra teslim fişi ÖNCE EKRANDA gösterilir; yazdırmak için "Yazdır"a basılır.
  Future<void> _teslimFisiSor() async {
    await _yazdirTeslimFisi();
  }

  /// Teslim fişini ekranda gösterir (yazıcı bağlı/yakın olmasa da); "Yazdır" ile yazıcıya gönderilir.
  Future<void> _yazdirTeslimFisi() async {
    final depoAd = _kalemler.isNotEmpty
        ? (_gidecekDepolar
                .where((d) => d.id == _kalemler.first.gidecegidepoid)
                .firstOrNull
                ?.ad ??
            _kalemler.first.gidecegidepo?.ad)
        : null;
    final plasiyerAd =
        _plasiyerler.where((p) => p.Id == _dat.plasiyerid).firstOrNull?.Adsoyad;
    final satirlar = _kalemler
        .map((k) => AracYuklemeSatir(
              ad: k.stok?.Ad ?? '-',
              miktar: k.miktar ?? 0,
              olcubr: k.olcubr?.Ad ?? '',
            ))
        .toList();

    await AracYuklemeFisHelper.onizleVeYazdir(
      context,
      belgeNo: _dat.belgeserino ?? _dat.belgeno ?? '-',
      tarih: _dat.tarih ?? DateTime.now(),
      depoAd: depoAd ?? '-',
      plasiyerAd: plasiyerAd ?? '-',
      satirlar: satirlar,
    );
  }

  Future<void> _kaydet({bool pop = true}) async {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => Center(
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
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w500)),
                  ])),
            )));
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final subeId = prefs.getInt("sube_id") ?? 0;

      String datId;
      if (_yeniDatId != null) {
        // Güncelleme — üst bilgiyi güncelle
        datId = _yeniDatId!;
        final dto = _datToDto(subeId);
        dto["id"] = datId;
        await _svc.updateSingle(token, dto);
      } else {
        // Yeni kayıt
        datId = await _svc.saveSingle(token, _datToDto(subeId));
        _yeniDatId = datId;
      }

      for (int i = 0; i < _kalemler.length; i++) {
        final k = _kalemler[i];
        if (k.id == null) {
          final hId =
              await _svc.saveHareket(token, _hareketToInsertJson(k, datId));
          if (hId != null) k.id = hId;
          await _waitBeforeNextKalemSave(i, _kalemler.length);
        }
      }

      _ilkImza = _imza();
      if (!mounted) return;
      Navigator.of(context).pop(); // loading kapat
      UiFeedback.showSaved(context, "Araç yükleme kaydedildi");
      if (pop) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // loading kapat
      _hata(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
        canPop: !_degisiklikVar,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _cikisSor();
        },
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: ErpPageAppBar(
            context: context,
            backgroundColor: _scheme.surface,
            foregroundColor: _scheme.onSurface,
            elevation: 0,
            toolbarHeight: 44,
            title: Text(
                widget.datId == null
                    ? "Yeni Araç Yükleme"
                    : "Araç Yükleme Düzenle",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    fontSize: 15)),
            actions: [
              IconButton(
                icon: Icon(Icons.print_rounded, size: 20),
                tooltip: "Teslim Fişi Yazdır",
                onPressed: () {
                  if (_kalemler.isEmpty) {
                    _uyari("Yazdırılacak kalem yok.");
                    return;
                  }
                  _yazdirTeslimFisi();
                },
              ),
            ],
          ),
          body: _loading
              ? Center(child: CircularProgressIndicator())
              : Column(children: [
                  _buildTabBar(),
                  Expanded(
                      child: TabBarView(
                          controller: _tabCtrl,
                          children: [_ustBilgilerTab(), _kalemlerTab()])),
                  _buildBottomBar(),
                ]),
        ));
  }

  Widget _buildTabBar() => Container(
        color: _scheme.surface,
        child: ErpAdaptiveTabs(
            context: context,
            tabBar: TabBar(
              controller: _tabCtrl,
              indicatorColor: _accent,
              labelColor: _scheme.primary,
              unselectedLabelColor: _scheme.onSurfaceVariant,
              indicatorWeight: 3,
              labelStyle: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 12),
              unselectedLabelStyle: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.normal,
                  fontSize: 11),
              tabs: [
                Tab(
                    icon: Icon(Icons.info_outline_rounded, size: 16),
                    text: "Üst Bilgiler"),
                Tab(
                    child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                      Icon(Icons.inventory_2_outlined, size: 16),
                      SizedBox(width: 6),
                      Text("Kalemler"),
                      if (_kalemler.isNotEmpty) ...[
                        SizedBox(width: 6),
                        Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 1),
                            decoration: BoxDecoration(
                                color: _accent,
                                borderRadius: BorderRadius.circular(10)),
                            child: Text("${_kalemler.length}",
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold))),
                      ],
                    ])),
              ],
            )),
      );

  Widget _ustBilgilerTab() => ListView(padding: EdgeInsets.all(12), children: [
        _buildSectionCard(children: [
          // Tarih (tek satır, varsayılan günün tarihi; teslim tarihi aynı gün)
          _buildDateField(
              label: "Tarih",
              icon: Icons.calendar_today_outlined,
              ctrl: _tarihCtrl,
              current: _dat.tarih,
              onPicked: (d) => setState(() {
                    _dat.tarih = d;
                    _dat.teslimtarihi = d;
                    _tarihCtrl.text = _fmtDate(d);
                    _teslimTarihCtrl.text = _fmtDate(d);
                  })),
          SizedBox(height: 12),
          // Belge Seri / Yıl / No (aynı satır)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                flex: 2,
                child: _buildDropdown<String>(
                    label: "Seri",
                    value: _seciliSeri,
                    items: _belgeSeriListesi
                        .where((e) => (e.seri ?? '').trim().isNotEmpty)
                        .fold<Map<String, BelgeSeriDto>>({}, (map, e) {
                          map.putIfAbsent(e.seri!.trim(), () => e);
                          return map;
                        })
                        .values
                        .map((e) => DropdownMenuItem(
                              value: e.seri,
                              child: Text(e.seri ?? ''),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _seciliSeri = v;
                        _dat.belgeseri = v;
                      });
                      _fetchYeniDatNo();
                    })),
            SizedBox(width: 8),
            Expanded(
                flex: 3,
                child: _buildDropdown<int>(
                    label: "Yıl",
                    value: _seciliYil,
                    items: _yilListesi
                        .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.toString(),
                                style: TextStyle(
                                    fontFamily: 'Roboto', fontSize: 13))))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _seciliYil = v!;
                        _dat.belgeyil = v;
                      });
                      _fetchYeniDatNo();
                    })),
            SizedBox(width: 8),
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
                            onChanged: (v) => _dat.belgeno = v,
                            style:
                                TextStyle(fontFamily: 'Roboto', fontSize: 13),
                            decoration: InputDecoration(
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
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
          SizedBox(height: 12),
          // Proje Kodu (tek satır)
          _buildSelector<ProjeDto>(
              label: "Proje Kodu",
              value: _dat.projeid,
              items: _projeler,
              getId: (e) => e.id,
              itemText: (e) => "${e.kod ?? ''} - ${e.ad ?? ''}",
              onChanged: (v) => setState(() => _dat.projeid = v?.id)),
          SizedBox(height: 12),
          // Referans Kodu (tek satır)
          _buildSelector<ReferansDto>(
              label: "Referans Kodu",
              value: _dat.referansid,
              items: _referanslar,
              getId: (e) => e.Id,
              itemText: (e) => "${e.Kod ?? ''} - ${e.Ad ?? ''}",
              onChanged: (v) => setState(() => _dat.referansid = v?.Id)),
          // Plasiyer: plasiyer kullanıcıda otomatik (kendisi, ekranda görünmez);
          // diğer kullanıcılar seçer (sevk deposu buna göre gelir)
          if (!_kp.kilitli) ...[
            SizedBox(height: 12),
            _buildSelector<PlasiyerDto>(
                label: "Plasiyer *",
                value: _dat.plasiyerid,
                items: _plasiyerler,
                getId: (e) => e.Id,
                itemText: (e) => "${e.Kod ?? ''} - ${e.Adsoyad ?? ''}",
                onChanged: (v) {
                  setState(() => _dat.plasiyerid = v?.Id);
                  _plasiyerDegisti();
                }),
          ],
          SizedBox(height: 12),
          // Açıklama
          _inputLabel("Açıklama"),
          TextFormField(
            controller: _aciklamaCtrl,
            maxLines: 2,
            minLines: 1,
            onChanged: (v) => _dat.aciklama = v.isEmpty ? null : v,
            style: TextStyle(fontFamily: 'Roboto', fontSize: 13),
            decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _scheme.outlineVariant)),
                hintText: "Açıklama",
                hintStyle: TextStyle(
                    fontFamily: 'Roboto',
                    color: _scheme.onSurfaceVariant,
                    fontSize: 13)),
          ),
          // Depo bilgisi (kalemlere varsayılan olarak yazılır)
          SizedBox(height: 10),
          _depoBilgiSatiri(),
        ]),
      ]);

  Widget _depoBilgiSatiri() {
    String ad(List<DepoDto> l, int? id) =>
        l
            .where((d) => d.id == id)
            .map((d) => "${d.kod ?? ''} ${d.ad ?? ''}".trim())
            .firstOrNull ??
        '-';
    if (_dat.plasiyerid == null) {
      return Text("Plasiyer seçilince çıkış ve sevk depoları otomatik gelir.",
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 11.5,
              color: _scheme.onSurfaceVariant));
    }
    if (_plasiyerDepoId == null) {
      return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.warning_amber_rounded, size: 15, color: Color(0xFFEF6C00)),
        SizedBox(width: 6),
        Expanded(
            child: Text(
                "Plasiyer deposu otomatik bulunamadı. Kalem eklerken Sevk deposunu seçin.",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11.5,
                    color: Color(0xFF8D4E00)))),
      ]);
    }
    return Text(
        "Çıkış deposu: ${ad(_depolar, _merkezDepoId)}   -   Sevk deposu: ${ad(_gidecekDepolar, _plasiyerDepoId)}",
        style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 11.5,
            color: _scheme.onSurfaceVariant));
  }

  Widget _kalemlerTab() => _kalemler.isEmpty
      ? Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: _scheme.outlineVariant),
          SizedBox(height: 12),
          Text("Henüz kalem eklenmedi",
              style: TextStyle(
                  fontFamily: 'Roboto', color: _scheme.onSurfaceVariant)),
        ]))
      : ListView.builder(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 80),
          itemCount: _kalemler.length,
          itemBuilder: (_, i) {
            final k = _kalemler[i];
            final stokAd = k.stok?.Ad ?? k.stokid?.toString() ?? '-';
            final cikisDepo = _depolar
                    .where((d) => d.id == k.cikacagidepoid)
                    .firstOrNull
                    ?.ad ??
                k.cikacagidepo?.ad ??
                '-';
            final girisDepo = _gidecekDepolar
                    .where((d) => d.id == k.gidecegidepoid)
                    .firstOrNull
                    ?.ad ??
                k.gidecegidepo?.ad ??
                '-';
            return Container(
              margin: EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                  color: _scheme.surface,
                  borderRadius: BorderRadius.circular(
                      ErpDesignStyle.modern(context) ? 18 : 12),
                  boxShadow: [
                    BoxShadow(
                        color: _scheme.onSurface.withOpacity(0.04),
                        blurRadius: 8,
                        offset: Offset(0, 2))
                  ]),
              child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(children: [
                    Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: _accent.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: Icon(Icons.inventory_2_outlined,
                            color: _accent, size: 20)),
                    SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(stokAd,
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14)),
                          SizedBox(height: 2),
                          Text(
                              "${NumberFormatHelper.format(k.miktar ?? 0, decimal: 4)} ${k.olcubr?.Ad ?? ''}",
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: _scheme.onSurfaceVariant)),
                          SizedBox(height: 4),
                          Row(children: [
                            Icon(Icons.output_rounded,
                                size: 12, color: _scheme.error),
                            SizedBox(width: 3),
                            Flexible(
                                child: Text(cikisDepo,
                                    style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 11,
                                        color: _scheme.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis)),
                            SizedBox(width: 6),
                            Icon(Icons.arrow_forward_rounded,
                                size: 12, color: _scheme.onSurfaceVariant),
                            SizedBox(width: 3),
                            Icon(Icons.input_rounded,
                                size: 12, color: _positive),
                            SizedBox(width: 3),
                            Flexible(
                                child: Text(girisDepo,
                                    style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 11,
                                        color: _scheme.onSurfaceVariant),
                                    overflow: TextOverflow.ellipsis)),
                          ]),
                        ])),
                    Row(mainAxisSize: MainAxisSize.min, children: [
                      PermissionAction(
                          modules: [801],
                          access: Access.write,
                          child: IconButton(
                              icon: Icon(Icons.edit_outlined,
                                  size: 20, color: _scheme.primary),
                              onPressed: () => _editKalem(i))),
                      PermissionAction(
                          modules: [801],
                          access: Access.write,
                          child: IconButton(
                              icon: Icon(Icons.delete_outline,
                                  size: 20, color: _scheme.error),
                              onPressed: () => _deleteKalem(i))),
                    ]),
                  ])),
            );
          });

  Widget _buildBottomBar() {
    final isKalemlerTab = _tabCtrl.index == 1;

    // Kalemler sekmesi → 4 FAB + Kaydet
    if (isKalemlerTab) {
      return Container(
        padding: EdgeInsets.fromLTRB(16, 10, 16, 16),
        decoration: BoxDecoration(color: _scheme.surface, boxShadow: [
          BoxShadow(
              color: _scheme.onSurface.withOpacity(0.07),
              blurRadius: 12,
              offset: Offset(0, -3))
        ]),
        child: SafeArea(
            child: Row(children: [
          _roundActionButton(
              icon: Icons.add_shopping_cart, color: _accent, onTap: _addKalem),
          SizedBox(width: 8),
          _roundActionButton(
              icon: Icons.barcode_reader,
              color: Colors.deepOrange.shade600,
              onTap: _addDirekBarkodKalem),
          SizedBox(width: 8),
          _roundActionButton(
              icon: Icons.qr_code_scanner,
              color: Colors.indigo.shade600,
              onTap: _kameraIleBarkodOku),
          SizedBox(width: 8),
          _roundActionButton(
              icon: Icons.keyboard_alt_outlined,
              color: _positive,
              onTap: _addHizliBarkodKalemler),
          SizedBox(width: 12),
          Expanded(
              child: PermissionAction(
                  modules: [801],
                  access: Access.write,
                  child: ElevatedButton.icon(
                    onPressed: _showKaydetDialog,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF2E7D32),
                        foregroundColor: _scheme.onPrimary,
                        padding: EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2),
                    icon: Icon(Icons.save_outlined, size: 18),
                    label: Text("Kaydet",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.bold,
                            fontSize: 15)),
                  ))),
        ])),
      );
    }

    // Üst Bilgiler sekmesi → 4 FAB ortalanmış
    return Container(
      color: Colors.transparent,
      padding: EdgeInsets.only(bottom: 16, top: 8),
      child: SafeArea(
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _roundActionButton(
            icon: Icons.add_shopping_cart, color: _accent, onTap: _addKalem),
        SizedBox(width: 16),
        _roundActionButton(
            icon: Icons.barcode_reader,
            color: Colors.deepOrange.shade600,
            onTap: _addDirekBarkodKalem),
        SizedBox(width: 16),
        _roundActionButton(
            icon: Icons.qr_code_scanner,
            color: Colors.indigo.shade600,
            onTap: _kameraIleBarkodOku),
        SizedBox(width: 16),
        _roundActionButton(
            icon: Icons.keyboard_alt_outlined,
            color: _positive,
            onTap: _addHizliBarkodKalemler),
      ])),
    );
  }

  Widget _roundActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    double padding = 14,
    double iconSize = 24,
  }) {
    return Material(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _scheme.outlineVariant)),
      color: _scheme.surface,
      child: InkWell(
        customBorder: CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Icon(icon, color: _scheme.primary, size: iconSize),
        ),
      ),
    );
  }

  Widget _buildSectionCard({required List<Widget> children}) =>
      ErpDesignStyle.modern(context)
          ? ErpFormSection(children: children)
          : Container(
              padding: EdgeInsets.all(12),
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: _scheme.surface,
                  borderRadius: BorderRadius.circular(
                      ErpDesignStyle.modern(context) ? 18 : 12),
                  boxShadow: [
                    BoxShadow(
                        color: _scheme.onSurface.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 4))
                  ]),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: children),
            );

  Widget _inputLabel(String label) => Padding(
        padding: EdgeInsets.only(left: 2, bottom: 4),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
      );

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
          padding: EdgeInsets.symmetric(horizontal: 8),
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

  /// Rehber tarzı, tam ekran, kod/ad ile aranabilir seçici (Şube, Referans vb.)
  Widget _buildSelector<T>(
      {required String label,
      required int? value,
      required List<T> items,
      required int? Function(T) getId,
      required String Function(T) itemText,
      required ValueChanged<T?> onChanged}) {
    T? selected;
    for (final e in items) {
      if (getId(e) == value) {
        selected = e;
        break;
      }
    }
    final text = selected != null ? itemText(selected) : null;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _inputLabel(label),
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final secilen = await showErpSelector<T>(
              context: context,
              title: label,
              hintText: "$label Kodu veya Adı...",
              items: items,
              itemText: itemText,
            );
            if (secilen != null) onChanged(secilen);
          },
          child: Container(
            height: 45,
            padding: EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _scheme.outlineVariant)),
            child: Row(children: [
              Expanded(
                  child: Text(text ?? "Seçiniz",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: text != null
                              ? _scheme.onSurface
                              : _scheme.onSurfaceVariant),
                      overflow: TextOverflow.ellipsis)),
              Icon(Icons.search_rounded,
                  size: 18, color: _scheme.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _buildDateField(
      {required String label,
      required IconData icon,
      required TextEditingController ctrl,
      required DateTime? current,
      required void Function(DateTime) onPicked}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _inputLabel(label),
      SizedBox(
          height: 45,
          child: TextFormField(
              controller: ctrl,
              readOnly: true,
              style: TextStyle(fontFamily: 'Roboto', fontSize: 13),
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: _scheme.outlineVariant)),
                  suffixIcon:
                      Icon(icon, size: 18, color: _scheme.onSurfaceVariant)),
              onTap: () => _pickDate(current, onPicked))),
    ]);
  }
}
