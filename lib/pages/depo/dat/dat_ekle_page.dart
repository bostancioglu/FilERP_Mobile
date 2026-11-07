import '../../../helpers/warehouse_line_fields.dart';
import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/erp_page_style.dart';
import '../../../widgets/erp_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../models/entities/depo/dat_dto.dart';
import '../../../models/entities/depo/dathareket_dto.dart';
import '../../../models/entities/depo/depo_dto.dart';
import '../../../models/entities/firma/sube_dto.dart';
import '../../../models/entities/stok/stok_list_dto.dart';
import '../../../models/entities/stok/stok_dto.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../../models/entities/referans/referans_dto.dart';
import '../../../models/entities/yonetim/belge_seri_dto.dart';
import '../../../services/depo/depo_service.dart';
import '../../../services/depo/dat/dat_service.dart';
import '../../../services/yonetim/sube_service.dart';
import '../../../services/yonetim/belgeseri_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../services/plasiyer/plasiyer_service.dart';
import '../../../services/referans/referans_service.dart';
import '../../../services/stok/stok_service.dart';
import '../../../services/offline/offline_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/arac_yukleme_fis_helper.dart';
import '../../../helpers/varsayilan_proje_helper.dart';
import '../../../helpers/number_format_helper.dart';
import '../../../helpers/belge_turu_couples.dart';
import '../../../widgets/dat/dat_kalem_form_sheet.dart';
import '../../../widgets/quick_barcode_scan_sheet.dart';
import '../../../widgets/barcode_scanner_sheet.dart';
import '../../../widgets/erp_selector.dart';
import '../../../services/yazici/bluetooth_print_service.dart';

class DatEklePage extends StatefulWidget {
  final String? datId;

  /// Offline kuyruktaki bir kaydı düzenlemek için kullanılır
  final OfflineQueueItem? queueItem;
  const DatEklePage({super.key, this.datId, this.queueItem});
  @override
  State<DatEklePage> createState() => _DatEklePageState();
}

class _DatEklePageState extends State<DatEklePage>
    with SingleTickerProviderStateMixin {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.primary;
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

  List<SubeDto> _subeler = [];
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

      List<SubeDto> subeler = [];
      List<BelgeSeriDto> belgeSeriListesi = [];
      List<DepoDto> depolar = [];
      List<ProjeDto> projeler = [];
      List<PlasiyerDto> plasiyerler = [];
      List<ReferansDto> referanslar = [];
      List<StokListDto> stoklar = [];

      try {
        subeler = await SubeService().getAll(token);
      } catch (e) {
        debugPrint(">>> subeler HATA: $e");
      }
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

      final subelerF = subeler;
      final belgeSeriListesiF = belgeSeriListesi;
      final depolarF = depolar;
      final projelerF = projeler;
      final plasiyerlerF = plasiyerler;
      final referanslarF = referanslar;
      final stoklarF = stoklar;

      final varsayilanProjeId = await VarsayilanProjeHelper.pickFrom(projelerF);
      if (!mounted) return;
      setState(() {
        _subeler = subelerF;
        _belgeSeriListesi = belgeSeriListesiF;
        _depolar = depolarF;
        _projeler = projelerF;
        _plasiyerler = plasiyerlerF;
        _referanslar = referanslarF;
        _stoklar = stoklarF;
        _loading = false;
        if (projelerF.isNotEmpty && _dat.projeid == null)
          _dat.projeid = varsayilanProjeId;
        if (plasiyerlerF.isNotEmpty && _dat.plasiyerid == null)
          _dat.plasiyerid = plasiyerlerF.first.Id;
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
    } catch (e, stack) {
      debugPrint(">>> loadLookups HATA: $e\n$stack");
      if (mounted) {
        setState(() => _loading = false);
        UiFeedback.showError(context, e.toString());
      }
    }
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
      // Kalemlerin depoları lookup listelerinde yoksa (yetki / şube filtresi) sunucudan gelen
      // iç içe depo bilgisiyle eklenir; kalem kartı ve kalem formu depoyu boş göstermesin.
      if (mounted) {
        final cikis = [..._depolar];
        final giris = [..._gidecekDepolar];
        for (final k in _kalemler) {
          final c = k.cikacagidepo;
          if (c?.id != null && !cikis.any((d) => d.id == c!.id)) cikis.add(c!);
          final g = k.gidecegidepo;
          if (g?.id != null && !giris.any((d) => d.id == g!.id)) giris.add(g!);
        }
        setState(() {
          _depolar = cikis;
          _gidecekDepolar = giris;
        });
      }
    } catch (e, stack) {
      debugPrint(">>> loadMevcutDat HATA: $e\n$stack");
      if (mounted) UiFeedback.showError(context, "DAT yüklenemedi: $e");
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
    final barkod = await Navigator.push<String>(
        context,
        PermissionMaterialPageRoute(
            builder: (_) => const BarcodeScannerSheet()));
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
              onPressed: () => Navigator.pop(ctx), child: const Text("Ekle")),
        ],
      ),
    );
    HardwareKeyboard.instance.addHandler(_terminalBarkodHandler);
    if (barkod.trim().isNotEmpty && mounted) {
      _barkodIleStokveBulKalemAc(barkod.trim());
    }
  }

  Future<void> _barkodIleStokveBulKalemAc(String barkod) async {
    if (_dat.gidecegisubeid == null) {
      if (mounted)
        UiFeedback.showWarning(
            context, "Kalem eklemeden önce gideceği şubeyi seçiniz!");
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
      if (mounted) UiFeedback.showWarning(context, "Barkod eşleşmedi: $barkod");
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
        if (mounted) UiFeedback.showError(context, "DAT kaydedilemedi: $e");
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
      if (mounted) UiFeedback.showError(context, "Kalem kaydedilemedi: $e");
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
        girisDepolar: _gidecekDepolar);
    if (k == null || !mounted) return;

    // ── Offline mod (manuel VEYA internet yok) ───────────────────────────
    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (manuelOffline || internetYok) {
      if (_dat.gidecegisubeid == null) {
        UiFeedback.showWarning(
            context, "Kalem eklemeden önce gideceği şubeyi seçiniz!");
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
        UiFeedback.showWarning(
            context, "Kalem eklemeden önce gideceği şubeyi seçiniz!");
        return;
      }
      try {
        _yeniDatId = await _svc.saveSingle(token, _datToDto(subeId));
      } catch (e) {
        if (mounted) UiFeedback.showError(context, "DAT kaydedilemedi: $e");
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
      if (mounted) UiFeedback.showError(context, "Kalem kaydedilemedi: $e");
    }
  }

  Future<void> _addHizliBarkodKalemler() async {
    if (_dat.gidecegisubeid == null) {
      UiFeedback.showWarning(
          context, "Kalem eklemeden Ã¶nce gideceÄŸi ÅŸubeyi seÃ§iniz!");
      return;
    }

    final result = await showQuickBarcodeScanSheet(
      context,
      stoklar: _stoklar,
      title: "Hızlı Barkod Okut",
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
      UiFeedback.showWarning(context, "Eklenecek stok bulunamadÄ±!");
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
        if (mounted) UiFeedback.showError(context, "DAT kaydedilemedi: $e");
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
      if (mounted) UiFeedback.showError(context, "Kalemler kaydedilemedi: $e");
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
    k.cikacagidepoid = _depolar.isNotEmpty ? _depolar.first.id : null;
    k.gidecegidepoid =
        _gidecekDepolar.isNotEmpty ? _gidecekDepolar.first.id : null;

    if (manuelOffline || internetYok || token.isEmpty) {
      return;
    }

    // Depo adresi yalnızca dinamik depolarda anlamlı
    if (k.cikacagidepoid != null &&
        _depolar
            .any((d) => d.id == k.cikacagidepoid && d.dinamikdepo == true)) {
      k.cikacagidepoadresid = await _firstDepoAdresId(
        token,
        k.cikacagidepoid!,
        cikisAdresCache,
      );
    }
    if (k.gidecegidepoid != null &&
        _gidecekDepolar
            .any((d) => d.id == k.gidecegidepoid && d.dinamikdepo == true)) {
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
        girisDepolar: _gidecekDepolar);
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
      setState(() => _kalemler.removeAt(i));
      UiFeedback.showDeleted(context, "Kalem silindi");
    }
  }

  Future<void> _showKaydetDialog() async {
    if (_dat.gidecegisubeid == null) {
      UiFeedback.showWarning(context, "Lütfen gideceği şubeyi seçiniz!");
      return;
    }
    if (_kalemler.isEmpty) {
      UiFeedback.showWarning(context, "En az bir kalem eklemelisiniz!");
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
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08), shape: BoxShape.circle),
              child: Icon(Icons.save_outlined, size: 36, color: _primary),
            ),
            const SizedBox(height: 12),
            const Text("DAT'ı Kaydet",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Nasıl kaydetmek istersiniz?",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: _scheme.onSurfaceVariant,
                    fontSize: 13),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            // Belgeyi Tamamla
            SizedBox(
                width: double.infinity,
                child: PermissionAction(
                    modules: [801],
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
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _kaydetTamamla();
                      },
                    ))),
            const SizedBox(height: 10),
            // Taslak Kaydet
            SizedBox(
                width: double.infinity,
                child: PermissionAction(
                    modules: [801],
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
            ? "İnternet yok — DAT kuyruğa alındı, bağlantı gelince gönderilecek"
            : "DAT kuyruğa eklendi — online olunca gönderilecek";
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
      UiFeedback.showError(context, "Tamamlama hatası: $e");
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

      if (!mounted) return;
      Navigator.of(context).pop(); // loading kapat
      UiFeedback.showSaved(context, "DAT kaydedildi");
      if (pop) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop(); // loading kapat
      UiFeedback.showError(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: ErpPageAppBar(
            context: context,
            title: Text(
                widget.datId == null ? 'Yeni Transfer' : 'Transfer Düzenle',
                style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.w700)),
            backgroundColor: _scheme.surface,
            foregroundColor: _scheme.onSurface,
            actions: [
              IconButton(
                  tooltip: 'Teslim Fişi Yazdır',
                  icon: const Icon(Icons.print_rounded, size: 20),
                  onPressed: () {
                    if (_kalemler.isEmpty) {
                      UiFeedback.showWarning(
                          context, 'Yazdırılacak kalem yok.');
                      return;
                    }
                    _yazdirTeslimFisi();
                  })
            ],
            bottom: PreferredSize(
                preferredSize: const Size.fromHeight(40),
                child: _buildTabBar())),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabCtrl,
                children: [_ustBilgilerTab(), _kalemlerTab()]),
        bottomNavigationBar: _loading ? null : _buildBottomBar(),
      );

  Widget _buildTabBar() => ErpAdaptiveTabs(
      context: context,
      tabBar: TabBar(
          controller: _tabCtrl,
          labelColor: _accent,
          indicatorColor: _accent,
          unselectedLabelColor: _scheme.onSurfaceVariant,
          tabs: [
            Tab(height: 40, text: 'Belge'),
            Tab(height: 40, text: 'Kalemler')
          ]));

  Widget _ustBilgilerTab() =>
      ListView(padding: const EdgeInsets.all(12), children: [
        _buildSectionCard(children: [
          _buildSelector<SubeDto>(
              label: "Gideceği Şube *",
              value: _dat.gidecegisubeid,
              items: _subeler,
              getId: (e) => e.id,
              itemText: (e) => "${e.kod ?? ''} - ${e.ad ?? ''}",
              onChanged: (v) {
                setState(() {
                  _dat.gidecegisubeid = v?.id;
                  _gidecekDepolar = [];
                });
                if (v?.id != null) _loadGidecekDepolar(v!.id!);
              }),
          const SizedBox(height: 12),
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
                    onChanged: (v) {
                      setState(() {
                        _seciliYil = v!;
                        _dat.belgeyil = v;
                      });
                      _fetchYeniDatNo();
                    })),
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
                            onChanged: (v) => _dat.belgeno = v,
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
          Row(children: [
            Expanded(
                child: _buildDateField(
                    label: "Tarih",
                    icon: Icons.calendar_today_outlined,
                    ctrl: _tarihCtrl,
                    current: _dat.tarih,
                    onPicked: (d) => setState(() {
                          _dat.tarih = d;
                          _tarihCtrl.text = _fmtDate(d);
                        }))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildDateField(
                    label: "Teslim Tarihi",
                    icon: Icons.local_shipping_outlined,
                    ctrl: _teslimTarihCtrl,
                    current: _dat.teslimtarihi,
                    onPicked: (d) => setState(() {
                          _dat.teslimtarihi = d;
                          _teslimTarihCtrl.text = _fmtDate(d);
                        }))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _buildDropdown<int>(
                    label: "Proje",
                    value: _dat.projeid,
                    items: _projeler
                        .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Text("${e.kod ?? ''} - ${e.ad ?? ''}",
                                style: const TextStyle(
                                    fontFamily: 'Roboto', fontSize: 12),
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _dat.projeid = v))),
            const SizedBox(width: 12),
            Expanded(
                child: _buildDropdown<int>(
                    label: "Plasiyer",
                    value: _dat.plasiyerid,
                    items: _plasiyerler
                        .map((e) => DropdownMenuItem(
                            value: e.Id,
                            child: Text(e.Adsoyad ?? '',
                                style: const TextStyle(
                                    fontFamily: 'Roboto', fontSize: 13),
                                overflow: TextOverflow.ellipsis)))
                        .toList(),
                    onChanged: (v) => setState(() => _dat.plasiyerid = v))),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
                child: _buildSelector<ReferansDto>(
                    label: "Referans",
                    value: _dat.referansid,
                    items: _referanslar,
                    getId: (e) => e.Id,
                    itemText: (e) => "${e.Kod ?? ''} - ${e.Ad ?? ''}",
                    onChanged: (v) => setState(() => _dat.referansid = v?.Id))),
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
                        onChanged: (v) => _dat.aciklama = v.isEmpty ? null : v,
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
        ]),
      ]);

  Widget _kalemlerTab() => _kalemler.isEmpty
      ? Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.inventory_2_outlined,
              size: 56, color: _scheme.outlineVariant),
          const SizedBox(height: 12),
          Text("Henüz kalem eklenmedi",
              style: TextStyle(
                  fontFamily: 'Roboto', color: _scheme.onSurfaceVariant)),
        ]))
      : ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
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
            return ErpFinanceCard(
                title: stokAd,
                icon: Icons.inventory_2_outlined,
                metadata: ['Çıkış: $cikisDepo', 'Giriş: $girisDepo'],
                amount:
                    '${NumberFormatHelper.format(k.miktar ?? 0, decimal: 4)} ${k.olcubr?.Ad ?? ''}',
                onTap: () => _editKalem(i),
                onDelete: () => _deleteKalem(i));
          });

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
                          modules: [801],
                          access: Access.write,
                          child: FilledButton.icon(
                              onPressed: _showKaydetDialog,
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: const Text('Kaydet'))))
                ],
              ]))));

  Widget _buildSectionCard({required List<Widget> children}) =>
      ErpDesignStyle.modern(context)
          ? ErpFormSection(children: children)
          : Container(
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: _scheme.surface,
                  borderRadius: BorderRadius.circular(
                      ErpDesignStyle.modern(context) ? 18 : 16),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4))
                  ]),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
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
              style: const TextStyle(fontFamily: 'Roboto', fontSize: 13),
              decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
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
