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

import '../../../services/offline/offline_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/varsayilan_depo_helper.dart';
import '../../../helpers/varsayilan_proje_helper.dart';
import '../../../helpers/belge_turu_couples.dart';
import '../../../helpers/giriscikis_couples.dart';
import '../../../helpers/islemyeri_couples.dart';
import '../../../helpers/number_format_helper.dart';
import '../../../models/entities/depo/ambargc_dto.dart';
import '../../../models/entities/depo/ambargchareket_dto.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../../models/entities/yonetim/masraf_dto.dart';
import '../../../models/entities/referans/referans_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/stok/stok_list_dto.dart';
import '../../../models/entities/depo/depo_dto.dart';
import '../../../models/entities/yonetim/belge_seri_dto.dart';
import '../../../services/depo/ambargc/ambargc_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../services/plasiyer/plasiyer_service.dart';
import '../../../services/yonetim/masraf_service.dart';
import '../../../services/referans/referans_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../services/stok/stok_service.dart';
import '../../../services/yonetim/belgeseri_service.dart';
import '../../../services/yonetim/kur_service.dart';
import '../../../services/depo/depo_service.dart';
import '../../../widgets/erp_selector.dart';
import '../../../widgets/ambargc/ambargc_kalem_form_sheet.dart';
import '../../../models/entities/stok/stok_dto.dart';
import '../../../widgets/quick_barcode_scan_sheet.dart';
import '../../../widgets/barcode_scanner_sheet.dart';

class AmbargcEklePage extends StatefulWidget {
  final String? ambargcId;
  const AmbargcEklePage({super.key, this.ambargcId});

  @override
  State<AmbargcEklePage> createState() => _AmbargcEklePageState();
}

class _AmbargcEklePageState extends State<AmbargcEklePage>
    with SingleTickerProviderStateMixin {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.primary;
  Color get _accent => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;

  bool get _isEditMode => widget.ambargcId != null;

  late TabController _tabCtrl;
  final _svc = AmbargcService();

  bool _loading = false;
  final _ambargc = AmbargcDto();
  final List<AmbargchareketDto> _kalemler = [];
  String? _yeniAmbargcId;
  // Bu oturumda offline (manuel offline ya da internet yok) modda en az bir
  // kalem eklendiyse true olur; bir kez true olduktan sonra oturum boyunca
  // öyle kalır — online/offline yarı-kayıtlı karışık durum oluşmasın diye.
  bool _offlineDraft = false;

  // Lookups
  List<MasrafDto> _masraflar = [];
  List<ReferansDto> _referanslar = [];
  List<ProjeDto> _projeler = [];
  List<PlasiyerDto> _plasiyerler = [];
  List<DovizDto> _dovizler = [];
  List<StokListDto> _stoklar = [];
  List<DepoDto> _depolar = [];
  List<BelgeSeriDto> _belgeSeriListesi = [];
  List<int> _yilListesi = [];

  String? _seciliSeri;
  int _seciliYil = DateTime.now().year;

  // Controllers
  late TextEditingController _belgeNoCtrl;
  late TextEditingController _tarihCtrl;
  late TextEditingController _dovizTarihCtrl;
  late TextEditingController _kurCtrl;
  late TextEditingController _aciklamaCtrl;

  // Barkod
  final StringBuffer _barkodBuffer = StringBuffer();
  DateTime? _sonTus;
  static const _barkodTimeout = Duration(milliseconds: 80);
  bool _barkodHandlerEklendi = false;

  String _fmtDate(DateTime? d) => d == null
      ? ''
      : "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";

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
    _ambargc
      ..tarih = now
      ..belgeyil = now.year
      ..giriscikis = 1 // default: Giriş
      ..islemyeri = 3 // default: Masraf Merkezi
      ..dovizid = 1
      ..kur = 1.0
      ..belgeturu = BelgeTuruCouples.ambarGirisFisi;

    _belgeNoCtrl = TextEditingController();
    _tarihCtrl = TextEditingController(text: _fmtDate(now));
    _dovizTarihCtrl = TextEditingController();
    _kurCtrl = TextEditingController(text: '1,0000');
    _aciklamaCtrl = TextEditingController();

    _loadLookups();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_barkodHandlerEklendi) {
      HardwareKeyboard.instance.addHandler(_handleBarkodTus);
      _barkodHandlerEklendi = true;
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleBarkodTus);
    _tabCtrl.dispose();
    _belgeNoCtrl.dispose();
    _tarihCtrl.dispose();
    _dovizTarihCtrl.dispose();
    _kurCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final subeId = prefs.getInt("sube_id") ?? 0;

      List<MasrafDto> masraflar = [];
      List<ProjeDto> projeler = [];
      List<PlasiyerDto> plasiyerler = [];
      List<DovizDto> dovizler = [];
      List<StokListDto> stoklar = [];
      List<DepoDto> depolar = [];
      List<BelgeSeriDto> seriListGiris = [];
      List<BelgeSeriDto> seriListCikis = [];
      List<ReferansDto> referanslar = [];

      try {
        masraflar = await MasrafService().getAll(token);
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
        dovizler = await DovizService().getDovizler(token);
      } catch (_) {}
      try {
        stoklar = await StokService().getStokList(token);
      } catch (_) {}
      try {
        depolar = await DepoService().getAllBySubeId(token, subeId);
      } catch (_) {}
      try {
        seriListGiris = await BelgeSeriService()
            .getAll(token, BelgeTuruCouples.ambarGirisFisi);
      } catch (_) {}
      try {
        referanslar = await ReferansService().getAll(token);
      } catch (_) {}
      try {
        seriListCikis = await BelgeSeriService()
            .getAll(token, BelgeTuruCouples.ambarCikisFisi);
      } catch (_) {}

      final varsayilanProjeId = await VarsayilanProjeHelper.pickFrom(projeler);
      if (!mounted) return;
      setState(() {
        _masraflar = masraflar;
        _referanslar = referanslar;
        _projeler = projeler;
        _plasiyerler = plasiyerler;
        _dovizler = dovizler;
        _stoklar = stoklar;
        _depolar = depolar;
        _loading = false;

        // Defaults
        if (masraflar.isNotEmpty && _ambargc.masrafid == null)
          _ambargc.masrafid = masraflar.first.id;
        if (referanslar.isNotEmpty && _ambargc.referansid == null)
          _ambargc.referansid = referanslar.first.Id;
        if (projeler.isNotEmpty && _ambargc.projeid == null)
          _ambargc.projeid = varsayilanProjeId;
        if (plasiyerler.isNotEmpty && _ambargc.plasiyerid == null)
          _ambargc.plasiyerid = plasiyerler.first.Id;

        // Seri: giriş için giriş serisi
        final seriList =
            (_ambargc.giriscikis ?? 1) == 1 ? seriListGiris : seriListCikis;
        _belgeSeriListesi = seriList;
        if (seriList.isNotEmpty && _seciliSeri == null) {
          _seciliSeri = seriList.first.seri;
          _ambargc.belgeseri = _seciliSeri;
        }
      });

      if (!_isEditMode && _seciliSeri != null) {
        await _fetchYeniNo(token);
      }
      if (_isEditMode) await _loadMevcut(token);
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        UiFeedback.showError(context, e.toString());
      }
    }
  }

  Future<void> _fetchYeniNo(String token) async {
    if (_seciliSeri == null) return;
    try {
      final no = await _svc.getNewNo(token, _seciliSeri!, _seciliYil);
      if (mounted)
        setState(() {
          _ambargc.belgeno = no;
          _belgeNoCtrl.text = no;
        });
    } catch (_) {}
  }

  Future<void> _loadMevcut(String token) async {
    try {
      final mevcut = await _svc.getById(token, widget.ambargcId!);
      if (!mounted) return;
      setState(() {
        _yeniAmbargcId = mevcut.id;
        _ambargc.giriscikis = mevcut.giriscikis;
        _ambargc.islemyeri = mevcut.islemyeri;
        _ambargc.masrafid = mevcut.masrafid;
        _ambargc.referansid = mevcut.referansid;
        _ambargc.stokid = mevcut.stokid;
        _ambargc.projeid = mevcut.projeid;
        _ambargc.plasiyerid = mevcut.plasiyerid;
        _ambargc.dovizid = mevcut.dovizid;
        _ambargc.doviztarih = mevcut.doviztarih;
        _ambargc.kur = mevcut.kur;
        _ambargc.belgeseri = mevcut.belgeseri;
        _ambargc.belgeyil = mevcut.belgeyil;
        _ambargc.belgeno = mevcut.belgeno;
        _ambargc.tarih = mevcut.tarih;
        _ambargc.aciklama = mevcut.aciklama;
        _ambargc.belgeturu = mevcut.belgeturu;
        _seciliSeri = mevcut.belgeseri;
        _seciliYil = mevcut.belgeyil ?? DateTime.now().year;
        _belgeNoCtrl.text = mevcut.belgeno ?? '';
        _tarihCtrl.text = _fmtDate(mevcut.tarih);
        _dovizTarihCtrl.text = _fmtDate(mevcut.doviztarih);
        _kurCtrl.text =
            (mevcut.kur ?? 1.0).toStringAsFixed(4).replaceAll('.', ',');
        _aciklamaCtrl.text = mevcut.aciklama ?? '';
        _kalemler
          ..clear()
          ..addAll(mevcut.ambargchareket);
      });
    } catch (e) {
      if (mounted) UiFeedback.showError(context, "Kayıt yüklenemedi: $e");
    }
  }

  // ─── GİRİŞ/ÇIKIŞ DEĞİŞİNCE ──────────────────────────────
  Future<void> _onGirisCikisChanged(int? val) async {
    if (val == null) return;
    setState(() {
      _ambargc.giriscikis = val;
      _ambargc.belgeturu = val == 1
          ? BelgeTuruCouples.ambarGirisFisi
          : BelgeTuruCouples.ambarCikisFisi;
      _seciliSeri = null;
      _ambargc.belgeseri = null;
      _belgeSeriListesi = [];
    });
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    try {
      final belgeTuru = val == 1
          ? BelgeTuruCouples.ambarGirisFisi
          : BelgeTuruCouples.ambarCikisFisi;
      final seriList = await BelgeSeriService().getAll(token, belgeTuru);
      if (!mounted) return;
      setState(() {
        _belgeSeriListesi = seriList;
        if (seriList.isNotEmpty) {
          _seciliSeri = seriList.first.seri;
          _ambargc.belgeseri = _seciliSeri;
        }
      });
      if (_seciliSeri != null) await _fetchYeniNo(token);
    } catch (_) {}
  }

  // ─── KALEM İŞLEMLERİ ─────────────────────────────────────
  Future<void> _addKalem() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final subeId = prefs.getInt("sube_id") ?? 0;

    final k = await showAmbargcKalemForm(context,
        stoklar: _stoklar,
        projeler: _projeler,
        depolar: _depolar,
        kdvDahil: false,
        dovizli: !_tryMi,
        kur: _ambargc.kur ?? 0);
    if (k == null || !mounted) return;

    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (manuelOffline || internetYok) _offlineDraft = true;

    if (_offlineDraft) {
      if (_seciliSeri == null) {
        UiFeedback.showWarning(context, "Lütfen seri seçiniz!");
        return;
      }
      if (mounted)
        setState(() {
          _kalemler.add(k);
          _tabCtrl.animateTo(1);
        });
      UiFeedback.showSuccess(context, "Kalem eklendi (offline)");
      return;
    }

    if (_yeniAmbargcId == null) {
      if (_seciliSeri == null) {
        UiFeedback.showWarning(context, "Lütfen seri seçiniz!");
        return;
      }
      try {
        _yeniAmbargcId = await _svc.saveSingle(token, _ambargcToDto(subeId));
      } catch (e) {
        if (mounted) UiFeedback.showError(context, "Kayıt oluşturulamadı: $e");
        return;
      }
    }

    try {
      k.ambargcid = _yeniAmbargcId;
      final hId =
          await _svc.saveHareket(token, _hareketToJson(k, _yeniAmbargcId!));
      if (hId != null) k.id = hId;
      if (mounted)
        setState(() {
          _kalemler.add(k);
          _tabCtrl.animateTo(1);
        });
    } catch (e) {
      if (mounted) UiFeedback.showError(context, "Kalem eklenemedi: $e");
    }
  }

  Future<void> _editKalem(int i) async {
    final res = await showAmbargcKalemForm(context,
        kalem: _kalemler[i],
        stoklar: _stoklar,
        projeler: _projeler,
        depolar: _depolar,
        kdvDahil: false,
        dovizli: !_tryMi,
        kur: _ambargc.kur ?? 0);
    if (res == null || !mounted) return;
    setState(() => _kalemler[i] = res);
    if (res.id != null && _yeniAmbargcId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token_final") ?? "";
        await _svc.updateHareket(
            token, {'id': res.id, ..._hareketToJson(res, _yeniAmbargcId!)});
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

  // ─── DTO ─────────────────────────────────────────────────
  // TRY (TL) mi? Kur / Döviz Tarihi yalnızca dövizli (TL dışı) kayıtta gösterilir.
  bool get _tryMi {
    final id = _ambargc.dovizid;
    if (id == null || id == 1) return true;
    final d = _dovizler.where((x) => x.Id == id).firstOrNull;
    final b = (d?.Birim ?? '').trim().toUpperCase();
    return b == 'TL' || b == 'TRY' || b == '₺';
  }

  void _repriceKalemler() => repriceWarehouseLines(_kalemler,
      foreign: !_tryMi, rate: _ambargc.kur ?? 0);

  Future<void> _kurGetir() async {
    final dovizId = _ambargc.dovizid;
    if (dovizId == null || dovizId == 1) {
      setState(() {
        _ambargc.kur = 1.0;
        _kurCtrl.text = '1,0000';
        _repriceKalemler();
      });
      return;
    }

    final tarih = _ambargc.doviztarih ?? _ambargc.tarih ?? DateTime.now();
    setState(() {
      _ambargc.doviztarih = tarih;
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
      if (!mounted || _ambargc.dovizid != dovizId) return;
      setState(() {
        _ambargc.kur = yeniKur;
        _kurCtrl.text = yeniKur.toStringAsFixed(4).replaceAll('.', ',');
        _repriceKalemler();
      });
    } catch (e) {
      if (mounted) UiFeedback.showError(context, "Kur alınamadı: $e");
    }
  }

  Map<String, dynamic> _ambargcToDto(int subeId) => {
        "subeid": subeId,
        "giriscikis": _ambargc.giriscikis,
        "islemyeri": _ambargc.islemyeri,
        "masrafid": _ambargc.islemyeri == 3 ? _ambargc.masrafid : null,
        "referansid": _ambargc.islemyeri == 1 ? _ambargc.referansid : null,
        "stokid": _ambargc.islemyeri == 2 ? _ambargc.stokid : null,
        "projeid": _ambargc.projeid,
        "plasiyerid": _ambargc.plasiyerid,
        "dovizid": _ambargc.dovizid ?? 1,
        "doviztarih": _ambargc.doviztarih?.toIso8601String(),
        "kur": _ambargc.kur ?? 1.0,
        "belgeseri": _ambargc.belgeseri,
        "belgeyil": _seciliYil,
        "belgeno": _ambargc.belgeno,
        "belgeserino":
            "${_ambargc.belgeseri ?? ''}${_seciliYil}${_ambargc.belgeno ?? ''}",
        "tarih": _ambargc.tarih?.toIso8601String(),
        "belgeturu": _ambargc.belgeturu,
        "aciklama": _ambargc.aciklama,
        "doviztoplam": _kalemler.fold(
            0.0, (s, k) => s + (k.miktar ?? 0) * (k.dovizfiyat ?? 0)),
        "geneltoplam": _kalemler.fold(0.0, (s, k) => s + (k.tutar ?? 0)),
      };

  Map<String, dynamic> _hareketToJson(AmbargchareketDto k, String ambargcId) =>
      k.toWarehouseJson(ambargcId);

  // ─── KAYDET ──────────────────────────────────────────────
  Future<void> _showKaydetDialog() async {
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
              const Text("Ambar G/Ç Kaydet",
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
              SizedBox(
                  width: double.infinity,
                  child: PermissionAction(
                      modules: [1301],
                      access: Access.create,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _scheme.primary,
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
                      modules: [1301],
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
    if (!await _kaydet(pop: false)) return;
    if (!mounted) return;
    final id = _yeniAmbargcId;
    if (id == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await _svc.belgeDurumGuncelle(token, id, 1);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (mounted) UiFeedback.showError(context, "Tamamlama hatası: \$e");
    }
  }

  Future<void> _kaydetOffline({bool internetYok = false}) async {
    if (!_tryMi && (_ambargc.kur ?? 0) <= 0) {
      UiFeedback.showWarning(context, 'Geçerli bir kur giriniz.');
      return;
    }
    _repriceKalemler();
    final prefs = await SharedPreferences.getInstance();
    final subeId = prefs.getInt("sube_id") ?? 0;

    final payload = {
      'headerEndpoint': '/Ambargc/SaveSingle',
      'hareketEndpoint': '/Ambargchareket/SaveSingle',
      'headerIdField': 'ambargcid',
      'header': _ambargcToDto(subeId),
      'kalemler': _kalemler.map((k) => _hareketToJson(k, '')).toList(),
    };

    await OfflineService.instance.enqueue('header_hareket_full', payload);

    if (!mounted) return;
    final mesaj = internetYok
        ? "İnternet yok — belge kuyruğa alındı, bağlantı gelince gönderilecek"
        : "Belge kuyruğa eklendi — online olunca gönderilecek";
    UiFeedback.showSuccess(context, mesaj);
    Navigator.pop(context, true);
  }

  Future<bool> _kaydet({bool pop = true}) async {
    if (!_tryMi && (_ambargc.kur ?? 0) <= 0) {
      UiFeedback.showWarning(context, 'Geçerli bir kur giriniz.');
      return false;
    }
    _repriceKalemler();
    if (_kalemler.isEmpty) {
      UiFeedback.showWarning(context, "En az bir kalem ekleyiniz!");
      return false;
    }
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
      if (_yeniAmbargcId != null) {
        final dto = _ambargcToDto(subeId);
        dto["id"] = _yeniAmbargcId;
        await _svc.updateSingle(token, dto);
      } else {
        _yeniAmbargcId = await _svc.saveSingle(token, _ambargcToDto(subeId));
      }
      if (!mounted) return false;
      Navigator.of(context).pop();
      UiFeedback.showUpdated(context, "Ambar G/Ç kaydedildi");
      if (pop) Navigator.of(context).pop(true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      Navigator.of(context).pop();
      UiFeedback.showError(context, "Kayıt hatası: $e");
      return false;
    }
  }

  // ─── BARKOD ──────────────────────────────────────────────
  bool _handleBarkodTus(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final ch = event.character;
    if (ch == null) return false;
    final now = DateTime.now();
    if (_sonTus != null && now.difference(_sonTus!) > _barkodTimeout) {
      _barkodBuffer.clear();
    }
    _sonTus = now;
    if (ch == '\n' || ch == '\r') {
      final barkod = _barkodBuffer.toString().trim();
      _barkodBuffer.clear();
      _sonTus = null;
      if (barkod.length >= 4) {
        Future.microtask(() => _barkodIleStokveBulKalemAc(barkod));
      }
      return true;
    }
    _barkodBuffer.write(ch);
    return false;
  }

  Future<void> _kameraIleBarkodOku() async {
    final barkod = await Navigator.push<String>(
        context,
        PermissionMaterialPageRoute(
            builder: (_) => const BarcodeScannerSheet()));
    if (!mounted || barkod == null || barkod.isEmpty) return;
    await _barkodIleStokveBulKalemAc(barkod);
  }

  Future<void> _addDirekBarkodKalem() async {
    // Handler diyalog açıkken Enter eventini tüketir → geçici kapat
    HardwareKeyboard.instance.removeHandler(_handleBarkodTus);
    final ctrl = TextEditingController();
    final barkod = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Barkod Gir",
            style: TextStyle(fontFamily: 'Roboto', fontSize: 16)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          textInputAction: TextInputAction.done,
          decoration: const InputDecoration(hintText: "Barkod veya ürün kodu"),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          ErpDialogAction(
              onPressed: () => Navigator.pop(ctx), child: const Text("İptal")),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text("Ekle"),
          ),
        ],
      ),
    );
    HardwareKeyboard.instance.addHandler(_handleBarkodTus);
    if (!mounted || barkod == null || barkod.isEmpty) return;
    await _barkodIleStokveBulKalemAc(barkod);
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

    final kalem = AmbargchareketDto()
      ..stokid = eslesme.Id
      ..stok = StokDto(Id: eslesme.Id, Ad: eslesme.Ad, Kod: eslesme.Kod)
      ..miktar = 1.0
      ..fiyat = 0.0
      ..tutar = 0.0
      ..tarih = DateTime.now();

    final k = await showAmbargcKalemForm(context,
        kalem: kalem,
        stoklar: _stoklar,
        projeler: _projeler,
        depolar: _depolar,
        kdvDahil: false,
        dovizli: !_tryMi,
        kur: _ambargc.kur ?? 0);
    if (k == null || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final subeId = prefs.getInt("sube_id") ?? 0;

    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (manuelOffline || internetYok) _offlineDraft = true;

    if (_offlineDraft) {
      if (_seciliSeri == null) {
        UiFeedback.showWarning(context, "Lütfen seri seçiniz!");
        return;
      }
      if (mounted)
        setState(() {
          _kalemler.add(k);
          _tabCtrl.animateTo(1);
        });
      UiFeedback.showSuccess(context, "Kalem eklendi (offline)");
      return;
    }

    if (_yeniAmbargcId == null) {
      if (_seciliSeri == null) {
        UiFeedback.showWarning(context, "Lütfen seri seçiniz!");
        return;
      }
      try {
        _yeniAmbargcId = await _svc.saveSingle(token, _ambargcToDto(subeId));
      } catch (e) {
        if (mounted) UiFeedback.showError(context, "Kayıt oluşturulamadı: $e");
        return;
      }
    }

    try {
      k.ambargcid = _yeniAmbargcId;
      final hId =
          await _svc.saveHareket(token, _hareketToJson(k, _yeniAmbargcId!));
      if (hId != null) k.id = hId;
      if (mounted)
        setState(() {
          _kalemler.add(k);
          _tabCtrl.animateTo(1);
        });
    } catch (e) {
      if (mounted) UiFeedback.showError(context, "Kalem eklenemedi: $e");
    }
  }

  Future<void> _addHizliBarkodKalemler() async {
    final result = await showQuickBarcodeScanSheet(context, stoklar: _stoklar);
    if (result == null || !mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final subeId = prefs.getInt("sube_id") ?? 0;
    final varsayilanDepoId = await VarsayilanDepoHelper.getId(token);
    final varsayilanProjeId =
        _ambargc.projeid ?? await VarsayilanProjeHelper.getId(token);

    final manuelOffline = await OfflineService.instance.getOfflineMode();
    final internetYok = !OfflineService.instance.isOnline.value;
    if (manuelOffline || internetYok) _offlineDraft = true;

    if (_offlineDraft) {
      if (_seciliSeri == null) {
        UiFeedback.showWarning(context, "Lütfen seri seçiniz!");
        return;
      }
      final yeniKalemler = <AmbargchareketDto>[];
      for (final line in result.lines) {
        final stok = line.stok;
        if (stok == null) continue;
        yeniKalemler.add(AmbargchareketDto()
          ..depoid = varsayilanDepoId
          ..projeid = varsayilanProjeId
          ..stokid = stok.Id
          ..stok = StokDto(Id: stok.Id, Ad: stok.Ad, Kod: stok.Kod)
          ..miktar = line.quantity
          ..fiyat = 0.0
          ..tutar = 0.0
          ..tarih = DateTime.now());
      }
      if (mounted && yeniKalemler.isNotEmpty) {
        setState(() => _kalemler.addAll(yeniKalemler));
        _tabCtrl.animateTo(1);
        UiFeedback.showSuccess(
            context, "${yeniKalemler.length} kalem eklendi (offline)");
      }
      return;
    }

    int eklenen = 0;
    for (final line in result.lines) {
      final stok = line.stok;
      if (stok == null) continue;

      if (_yeniAmbargcId == null) {
        if (_seciliSeri == null) {
          if (mounted) UiFeedback.showWarning(context, "Lütfen seri seçiniz!");
          return;
        }
        try {
          _yeniAmbargcId = await _svc.saveSingle(token, _ambargcToDto(subeId));
        } catch (e) {
          if (mounted)
            UiFeedback.showError(context, "Kayıt oluşturulamadı: $e");
          return;
        }
      }

      final kalem = AmbargchareketDto()
        ..depoid = varsayilanDepoId
        ..projeid = varsayilanProjeId
        ..stokid = stok.Id
        ..stok = StokDto(Id: stok.Id, Ad: stok.Ad, Kod: stok.Kod)
        ..miktar = line.quantity
        ..fiyat = 0.0
        ..tutar = 0.0
        ..ambargcid = _yeniAmbargcId
        ..tarih = DateTime.now();

      try {
        final full = await StokService().getStokById(token, stok.Id!);
        kalem.stok = full;
        kalem.stokozelliksabitid = warehouseFeatureId(full, null);
        kalem.olcubrid = full.Temelolcubrid;
        kalem.olcubr = full.Temelolcubr;
        kalem.dovizfiyat = 0;
        final hId = await _svc.saveHareket(
            token, _hareketToJson(kalem, _yeniAmbargcId!));
        if (hId != null) kalem.id = hId;
        if (mounted) setState(() => _kalemler.add(kalem));
        eklenen++;
      } catch (e) {
        if (mounted) UiFeedback.showError(context, "Kalem eklenemedi: $e");
      }
    }

    if (mounted && eklenen > 0) {
      _tabCtrl.animateTo(1);
      UiFeedback.showSuccess(context, "$eklenen kalem eklendi");
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: _surface,
        appBar: ErpPageAppBar(
            context: context,
            title: Text(_isEditMode ? 'Ambar Fişi Düzenle' : 'Yeni Ambar Fişi',
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
                    labelColor: _accent,
                    indicatorColor: _accent,
                    unselectedLabelColor: _scheme.onSurfaceVariant,
                    tabs: [
                      Tab(height: 40, text: 'Belge'),
                      Tab(height: 40, text: 'Kalemler'),
                      Tab(height: 40, text: 'Özet')
                    ]))),
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
                    onBarcode: _addHizliBarkodKalemler,
                    onCamera: _kameraIleBarkodOku,
                    onManual: _addDirekBarkodKalem),
                if (_tabCtrl.index > 0) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: PermissionAction(
                          modules: [1301],
                          access: Access.write,
                          child: FilledButton.icon(
                              onPressed: _showKaydetDialog,
                              icon: const Icon(Icons.save_outlined, size: 18),
                              label: const Text('Kaydet'))))
                ],
              ]))));

  Widget _ustBilgilerTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSectionCard(children: [
          // 1. Giriş / Çıkış
          _buildDropdown<int>(
              label: "Giriş / Çıkış",
              value: _ambargc.giriscikis,
              items: GiriscikisCouples.list
                  .map((e) => DropdownMenuItem(
                      value: e.value,
                      child: Text(e.text,
                          style: const TextStyle(
                              fontFamily: 'Roboto', fontSize: 13))))
                  .toList(),
              onChanged: (v) => _onGirisCikisChanged(v)),
          const SizedBox(height: 12),

          // 2. İşlem Yeri
          _buildDropdown<int>(
              label: "İşlem Yeri",
              value: _ambargc.islemyeri,
              items: IslemyeriCouples.list
                  .map((e) => DropdownMenuItem(
                      value: e.value,
                      child: Text(e.text,
                          style: const TextStyle(
                              fontFamily: 'Roboto', fontSize: 13))))
                  .toList(),
              onChanged: (v) => setState(() {
                    _ambargc.islemyeri = v;
                    // İşlem yeri değişince ilgili alanları sıfırla
                    _ambargc.masrafid = v == 3 && _masraflar.isNotEmpty
                        ? _masraflar.first.id
                        : null;
                    _ambargc.referansid = v == 1 && _referanslar.isNotEmpty
                        ? _referanslar.first.Id
                        : null;
                    _ambargc.stokid = v == 2 ? null : _ambargc.stokid;
                  })),
          const SizedBox(height: 12),

          // 3. İşlem Yerine Göre: Masraf / Referans / Stok / (Maliyet=boş)
          _buildIslemYeriWidget(),
          const SizedBox(height: 12),

          // 4. Proje
          _buildSelectorField(
            label: "Proje",
            value: _projeler
                    .where((p) => p.id == _ambargc.projeid)
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
              if (res != null) setState(() => _ambargc.projeid = res.id);
            },
          ),
          const SizedBox(height: 12),

          // 5. Tarih
          _buildDateField(
              "Tarih",
              _tarihCtrl,
              _ambargc.tarih,
              (d) => setState(() {
                    _ambargc.tarih = d;
                    _tarihCtrl.text = _fmtDate(d);
                  })),
          const SizedBox(height: 12),

          // 6. Seri / Yıl / Belge No
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
                flex: 2,
                child: _buildDropdown<String>(
                    label: "Seri",
                    value: _belgeSeriListesi.any((e) => e.seri == _seciliSeri)
                        ? _seciliSeri
                        : null,
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
                    onChanged: (v) async {
                      setState(() {
                        _seciliSeri = v;
                        _ambargc.belgeseri = v;
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
                          _ambargc.belgeyil = v;
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
                            onChanged: (v) => _ambargc.belgeno = v,
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

          // 7. Plasiyer
          _buildDropdown<int>(
              label: "Plasiyer",
              value: _ambargc.plasiyerid,
              items: _plasiyerler
                  .map((e) => DropdownMenuItem(
                      value: e.Id,
                      child: Text(e.Adsoyad ?? '',
                          style: const TextStyle(
                              fontFamily: 'Roboto', fontSize: 13),
                          overflow: TextOverflow.ellipsis)))
                  .toList(),
              onChanged: (v) => setState(() => _ambargc.plasiyerid = v)),
          const SizedBox(height: 12),

          // 8. Döviz / Döviz Tarihi
          Row(children: [
            Expanded(
                child: _buildDropdown<int>(
                    label: "Döviz",
                    value: _ambargc.dovizid,
                    items: _dovizler
                        .map((e) => DropdownMenuItem(
                            value: e.Id,
                            child: Text(e.Ad ?? '',
                                style: const TextStyle(
                                    fontFamily: 'Roboto', fontSize: 13))))
                        .toList(),
                    onChanged: (v) {
                      final wasLocal = _tryMi;
                      setState(() {
                        _ambargc.dovizid = v;
                        if (wasLocal && !_tryMi) {
                          for (final k in _kalemler) {
                            k.dovizfiyat = null;
                          }
                        }
                      });
                      _kurGetir();
                    })),
            if (!_tryMi) ...[
              const SizedBox(width: 12),
              Expanded(
                  child: _buildDateField(
                      "Döviz Tarihi", _dovizTarihCtrl, _ambargc.doviztarih,
                      (d) {
                setState(() {
                  _ambargc.doviztarih = d;
                  _dovizTarihCtrl.text = _fmtDate(d);
                });
                _kurGetir();
              })),
            ],
          ]),
          const SizedBox(height: 12),

          // 9. Kur
          if (!_tryMi) ...[
            _inputLabel("Kur"),
            SizedBox(
                height: 45,
                child: Row(children: [
                  InkWell(
                    onTap: () {
                      final v =
                          double.tryParse(_kurCtrl.text.replaceAll(',', '.')) ??
                              0;
                      if (v > 0) {
                        final n = (v - 1).clamp(0.0, double.infinity);
                        setState(() {
                          _ambargc.kur = n;
                          _repriceKalemler();
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
                    style: const TextStyle(fontFamily: 'Roboto', fontSize: 13),
                    onChanged: (v) => setState(() {
                      _ambargc.kur = double.tryParse(v.replaceAll(',', '.'));
                      _repriceKalemler();
                    }),
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
                      final v =
                          double.tryParse(_kurCtrl.text.replaceAll(',', '.')) ??
                              0;
                      final n = v + 1;
                      setState(() {
                        _ambargc.kur = n;
                        _repriceKalemler();
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
            const SizedBox(height: 12),
          ],

          // 10. Açıklama
          _inputLabel("Açıklama"),
          SizedBox(
              height: 45,
              child: TextFormField(
                controller: _aciklamaCtrl,
                onChanged: (v) => _ambargc.aciklama = v.isEmpty ? null : v,
                maxLines: 1,
                style: const TextStyle(fontFamily: 'Roboto', fontSize: 13),
                decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 12),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: _scheme.outlineVariant)),
                    hintText: "Açıklama",
                    hintStyle: TextStyle(
                        fontFamily: 'Roboto',
                        color: _scheme.onSurfaceVariant,
                        fontSize: 13)),
              )),
        ]),
      ],
    );
  }

  // ─── KALEMLER TAB ────────────────────────────────────────
  Widget _kalemlerTab() {
    if (_kalemler.isEmpty)
      return Center(
          child: Text('Henüz kalem yok',
              style: TextStyle(
                  fontFamily: 'Roboto', color: _scheme.onSurfaceVariant)));
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
                '${NumberFormatHelper.format(k.miktar ?? 0)} ${k.olcubr?.Ad ?? ''} × ${NumberFormatHelper.format(k.fiyat ?? 0)} ₺'
              ],
              amount: '${NumberFormatHelper.format(k.tutar ?? 0)} ₺',
              onTap: () => _editKalem(i),
              onDelete: () => _deleteKalem(i));
        });
  }

  Widget _ozetTab() {
    final genelToplam = _kalemler.fold(0.0, (s, k) => s + (k.tutar ?? 0));
    final isDoviz = (_ambargc.dovizid ?? 1) != 1;
    final dovizAd = isDoviz
        ? (_dovizler
                .where((d) => d.Id == _ambargc.dovizid)
                .firstOrNull
                ?.Birim ??
            '?')
        : '₺';
    final tryToplam = genelToplam;
    final dovizToplam = _kalemler.fold(
        0.0, (s, k) => s + (k.miktar ?? 0) * (k.dovizfiyat ?? 0));

    return ListView(padding: const EdgeInsets.all(12), children: [
      _buildSectionCard(children: [
        Text('Genel Toplam',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: _scheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        Text(
            '${NumberFormatHelper.format(isDoviz ? dovizToplam : genelToplam)} $dovizAd',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: _accent)),
        if (isDoviz) ...[
          const SizedBox(height: 4),
          Text('≈ ${NumberFormatHelper.format(tryToplam)} ₺',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  color: _scheme.onSurfaceVariant))
        ],
      ])
    ]);
  }

  Widget _buildIslemYeriWidget() {
    final islemyeri = _ambargc.islemyeri ?? 3;
    switch (islemyeri) {
      case 1: // Referans Kodu
        return _buildDropdown<int>(
            label: "Referans",
            value: _referanslar.any((e) => e.Id == _ambargc.referansid)
                ? _ambargc.referansid
                : null,
            items: _referanslar
                .map((e) => DropdownMenuItem(
                    value: e.Id,
                    child: Text("${e.Kod ?? ''} - ${e.Ad ?? ''}",
                        style:
                            const TextStyle(fontFamily: 'Roboto', fontSize: 13),
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _ambargc.referansid = v));

      case 2: // Stok Kodu
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _inputLabel("Stok"),
          Row(children: [
            Expanded(
                child: InkWell(
              onTap: () async {
                final s = await showErpSelector<StokListDto>(
                    context: context,
                    title: "Stok Seç",
                    hintText: "Stok Kodu, Adı veya Barkod...",
                    items: _stoklar,
                    itemText: (s) => "${s.Kod ?? ''} - ${s.Ad ?? ''}",
                    getBarcodes: (s) => s.getBarkodListesi(),
                    getUnit: (s) => s.TemelolcubrAd ?? '');
                if (s != null)
                  setState(() {
                    _ambargc.stokid = s.Id;
                  });
              },
              child: Container(
                  height: 45,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _scheme.outlineVariant)),
                  child: Row(children: [
                    Expanded(
                        child: Text(
                            _ambargc.stokid != null
                                ? "${_stoklar.where((s) => s.Id == _ambargc.stokid).firstOrNull?.Kod ?? ''} - ${_stoklar.where((s) => s.Id == _ambargc.stokid).firstOrNull?.Ad ?? ''}"
                                : "Stok seçiniz...",
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 13,
                                color: _ambargc.stokid == null
                                    ? _scheme.onSurfaceVariant
                                    : _scheme.onSurface),
                            overflow: TextOverflow.ellipsis)),
                    const Icon(Icons.chevron_right,
                        size: 20, color: Colors.grey),
                  ])),
            )),
            const SizedBox(width: 8),
            _buildScanBtn(Icons.qr_code_scanner_rounded, _accent,
                startWithCamera: true),
            const SizedBox(width: 8),
            _buildScanBtn(Icons.barcode_reader, Colors.green.shade600,
                startWithScanner: true),
          ]),
        ]);

      case 4: // Maliyet — hiçbir şey gösterme
        return const SizedBox.shrink();

      default: // 3 - Masraf Merkezi
        return _buildDropdown<int>(
            label: "Masraf Merkezi",
            value: _masraflar.any((e) => e.id == _ambargc.masrafid)
                ? _ambargc.masrafid
                : null,
            items: _masraflar
                .map((e) => DropdownMenuItem(
                    value: e.id,
                    child: Text("${e.kod ?? ''} - ${e.ad ?? ''}",
                        style:
                            const TextStyle(fontFamily: 'Roboto', fontSize: 13),
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _ambargc.masrafid = v));
    }
  }

  Widget _buildScanBtn(IconData icon, Color color,
          {bool startWithCamera = false, bool startWithScanner = false}) =>
      Container(
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _scheme.outlineVariant),
            color: _scheme.surface),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: () async {
            final s = await showErpSelector<StokListDto>(
                context: context,
                title: startWithScanner
                    ? "Terminal ile Stok Seç"
                    : "Barkod ile Stok Seç",
                hintText: "Barkod",
                items: _stoklar,
                itemText: (s) => "${s.Kod ?? ''} - ${s.Ad ?? ''}",
                getBarcodes: (s) => s.getBarkodListesi(),
                getUnit: (s) => s.TemelolcubrAd ?? '',
                startWithCamera: startWithCamera,
                startWithScanner: startWithScanner);
            if (s != null) setState(() => _ambargc.stokid = s.Id);
          },
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Icon(icon, color: color, size: 22)),
        ),
      );

  Widget _buildSectionCard({required List<Widget> children}) =>
      ErpDesignStyle.modern(context)
          ? ErpFormSection(children: children)
          : Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _scheme.surface,
                  borderRadius: BorderRadius.circular(
                      ErpDesignStyle.modern(context) ? 18 : 12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2))
                  ]),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children),
            );

  Widget _inputLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                fontWeight: FontWeight.w600,
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

  Widget _buildDateField(String label, TextEditingController ctrl,
      DateTime? current, Function(DateTime) onPicked) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _inputLabel(label),
      InkWell(
        onTap: () async {
          final d = await showDatePicker(
              context: context,
              initialDate: current ?? DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2100));
          if (d != null) onPicked(d);
        },
        child: Container(
            height: 45,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _scheme.outlineVariant)),
            child: Row(children: [
              Icon(Icons.calendar_today_outlined,
                  size: 16, color: _scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Text(ctrl.text.isEmpty ? "Seçiniz" : ctrl.text,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: ctrl.text.isEmpty
                          ? _scheme.onSurfaceVariant
                          : _scheme.onSurface)),
            ])),
      ),
    ]);
  }
}
