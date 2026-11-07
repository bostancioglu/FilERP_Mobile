import '../document_line_extras.dart';
import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../helpers/varsayilan_depo_helper.dart';
import '../../services/rapor/rapor_api.dart';
import '../../helpers/varsayilan_proje_helper.dart';
import '../../services/helper/olcubr_service.dart';
import '../../services/proje/proje_service.dart';
import '../../models/entities/proje/proje_dto.dart';
import '../../services/depo/depo_service.dart';
import '../../models/entities/depo/depo_dto.dart';
import '../../models/entities/depo/depoadres_dto.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../models/entities/olcubirimi/olcubr_dto.dart';
import '../../models/entities/fatura/faturahareket_dto.dart';
import '../../widgets/fatura/fatura_kalem_iskonto_sheet.dart';
import '../../helpers/lookups.dart';
import '../../helpers/para_birimi_helper.dart';
import '../../helpers/vergi_couples.dart';
import '../../helpers/number_format_helper.dart';
import '../../models/entities/stok/stok_list_dto.dart';
import '../../widgets/erp_selector.dart';
import '../../helpers/fatura_hesap_helper.dart';
import '../../models/entities/stok/stok_dto.dart';
import '../../models/entities/stok/stokozellik_dto.dart';
import '../../services/stok/stok_service.dart';
import '../../services/referans/referans_service.dart';
import '../../models/entities/referans/referans_dto.dart';

Future<FaturahareketDto?> showFaturaKalemForm(
  BuildContext context, {
  FaturahareketDto? kalem,
  required bool kdvDahil,
  int? dovizId,
  double? kur,
  required List<StokListDto> stoklar,
  bool cariTR = true,
  int?
      varsayilanDepoId, // yeni kalemde varsayılan depo (ör. plasiyerin kendi deposu)
  bool bakiyeUyar = false, // satış: depo bakiyesi miktardan azsa uyar
}) {
  return showDialog<FaturahareketDto>(
    context: context,
    barrierDismissible: false,
    builder: (context) {
      return Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: _FaturaKalemForm(
          kalem: kalem,
          kdvDahil: kdvDahil,
          dovizId: dovizId,
          kur: kur,
          stoklar: stoklar,
          cariTR: cariTR,
          varsayilanDepoId: varsayilanDepoId,
          bakiyeUyar: bakiyeUyar,
        ),
      );
    },
  );
}

class _FaturaKalemForm extends StatefulWidget {
  final FaturahareketDto? kalem;
  final List<StokListDto> stoklar;
  final bool kdvDahil;
  final int? dovizId;
  final double? kur;
  final bool cariTR;
  final int? varsayilanDepoId;
  final bool bakiyeUyar;

  const _FaturaKalemForm({
    this.kalem,
    required this.kdvDahil,
    required this.dovizId,
    this.kur,
    required this.stoklar,
    this.cariTR = true,
    this.varsayilanDepoId,
    this.bakiyeUyar = false,
  });

  @override
  State<_FaturaKalemForm> createState() => _FaturaKalemFormState();
}

class _FaturaKalemFormState extends State<_FaturaKalemForm> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  final _formKey = GlobalKey<FormState>();
  late FaturahareketDto k;

  final _miktarCtrl = TextEditingController();
  final _fiyatCtrl = TextEditingController();
  final _dovizFiyatCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();
  final _stokAdiAciklamaCtrl = TextEditingController();
  late final OlcubrService _olcuBrService;
  List<OlcubrDto> _olcuBirimleri = [];
  late final String sembol;
  late final bool _isTL; // TL ise true (dovizId == 1 veya null)

  List<DepoDto> _depoList = [];
  List<ProjeDto> _projeList = [];
  List<ReferansDto> _referanslar = [];
  List<StokozellikDto> _stokozellikler = [];
  int? _seciliOzellikId;
  List<DepoadresDto> _depoadresler = [];
  bool _adresYukleniyor = false;

  // ── Depo bakiyesi (seçili stok + depo) ────────────────────────────────────────
  String? _bakiyeKey;
  double? _depoBakiye;
  String _bakiyeBirim = '';
  bool _bakiyeYukleniyor = false;

  /// Stok veya depo değiştiyse bakiyeyi yeniden getirir (build içinden çağrılır, yalnızca değişimde istek atar).
  void _bakiyeKontrol() {
    final key = '${k.stokid}|${k.depoid}';
    if (key == _bakiyeKey) return;
    _bakiyeKey = key;
    _depoBakiye = null;
    _bakiyeBirim = '';
    if (k.stokid == null || k.depoid == null) {
      _bakiyeYukleniyor = false;
      return;
    }
    _bakiyeYukleniyor = true;
    final stokid = k.stokid!;
    final depoid = k.depoid!;
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _depoBakiyeYukle(key, stokid, depoid));
  }

  Future<void> _depoBakiyeYukle(String key, int stokid, int depoid) async {
    try {
      final satirlar = await RaporApi.post(
        'VW_Stokbakiyesubedepo/Query',
        RaporApi.filtre(stokid: stokid, depoid: depoid),
      );
      if (!mounted || _bakiyeKey != key) return;
      setState(() {
        _depoBakiye = satirlar.fold<double>(0, (s, r) => s + r.d('bakiye'));
        _bakiyeBirim = satirlar.isNotEmpty ? satirlar.first.s('olcubr') : '';
        _bakiyeYukleniyor = false;
      });
    } catch (_) {
      // Çevrimdışı / yetki sorunu: bakiye satırı sessizce gizlenir
      if (mounted && _bakiyeKey == key) {
        setState(() {
          _depoBakiye = null;
          _bakiyeYukleniyor = false;
        });
      }
    }
  }

  String _miktarYazi(double v) {
    var s = NumberFormatHelper.format(v, decimal: 4);
    if (s.contains(',')) s = s.replaceFirst(RegExp(r',?0+$'), '');
    return s;
  }

  Widget _buildDepoBakiyeSatiri() {
    _bakiyeKontrol();
    if (k.stokid == null || k.depoid == null) return SizedBox.shrink();
    final depo = _depoList.where((d) => d.id == k.depoid).firstOrNull;
    final depoAd = depo == null ? '' : (depo.kod ?? depo.ad ?? '');

    Color renk = _scheme.onSurfaceVariant;
    Widget icerik;
    if (_bakiyeYukleniyor) {
      icerik = Row(children: [
        SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 1.8)),
        SizedBox(width: 8),
        Text('Depo bakiyesi alınıyor...',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: _scheme.onSurfaceVariant)),
      ]);
    } else if (_depoBakiye == null) {
      return SizedBox.shrink();
    } else {
      final b = _depoBakiye!;
      final yetersiz = widget.bakiyeUyar && b < (k.miktar ?? 0);
      renk = yetersiz ? errorRed : (b > 0 ? Color(0xFF059669) : warnOrange);
      icerik = Row(children: [
        Icon(Icons.warehouse_rounded, size: 16, color: renk),
        SizedBox(width: 8),
        Text('Depo bakiyesi${depoAd.isNotEmpty ? ' ($depoAd)' : ''}: ',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12,
                color: _scheme.onSurfaceVariant)),
        Flexible(
          child: Text('${_miktarYazi(b)} $_bakiyeBirim'.trim(),
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: renk)),
        ),
        if (yetersiz) ...[
          SizedBox(width: 8),
          Text('Yetersiz',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: errorRed)),
        ],
      ]);
    }
    return Padding(
      padding: EdgeInsets.only(top: 8),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: renk.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: renk.withOpacity(0.25)),
        ),
        child: icerik,
      ),
    );
  }

  // Kurumsal Renkler
  Color get primaryDark => _scheme.onSurface;
  Color get accentBlue => _scheme.primary;
  Color get errorRed => _scheme.error;
  Color get warnOrange => _scheme.primary;

  /// double → Türkçe ondalık string (nokta → virgül). DB'ye göndermeden önce parse edilir.
  String _trFmt(double v, int decimals) =>
      v.toStringAsFixed(decimals).replaceAll('.', ',');

  @override
  void initState() {
    super.initState();
    sembol = ParaBirimiHelper.sembolById(widget.dovizId);
    _isTL = widget.dovizId == null || widget.dovizId == 1;
    k = widget.kalem?.copy() ?? FaturahareketDto();
    _olcuBrService = OlcubrService();

    k.miktar ??= 1;
    k.fiyat ??= 0;
    k.kdvorani ??= 20.0;

    _miktarCtrl.text = widget.kalem != null ? _trFmt(k.miktar ?? 0, 4) : '';
    _fiyatCtrl.text = widget.kalem != null
        ? NumberFormatHelper.format(k.fiyat ?? 0, decimal: 4)
        : '';
    // Düzenleme modunda doviz fiyatı varsa göster
    _dovizFiyatCtrl.text = widget.kalem != null && k.dovizfiyat != null
        ? NumberFormatHelper.format(k.dovizfiyat!, decimal: 4)
        : '';
    _aciklamaCtrl.text = k.aciklama ?? '';
    _stokAdiAciklamaCtrl.text = k.stokadiaciklama ?? '';
    // Yabancı cari: düzenleme modunda bile tevkifat uygulanmaz
    if (!widget.cariTR) k.tevkifatorani = null;

    _loadLookups();
    if (k.depoid != null) _loadDepoadresler(k.depoid!);
    // Düzenleme modunda stok zaten seçili → o stoğa ait birimleri yükle
    if (k.stokid != null) {
      _loadOlcuBirimByStok(k.stokid!);
    } else {
      _loadOlcuBirimleri();
    }
    // Döviz modunda dovizfiyat varsa TL fiyatı yeniden hesapla
    if (!_isTL && k.dovizfiyat != null && k.dovizfiyat! > 0) {
      _hesaplaDoviz();
    } else {
      _hesapla();
    }
  }

  @override
  void dispose() {
    _miktarCtrl.dispose();
    _fiyatCtrl.dispose();
    _dovizFiyatCtrl.dispose();
    _aciklamaCtrl.dispose();
    _stokAdiAciklamaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";

    List<DepoDto> dList = await DepoService().getDepoList(token);
    List<ProjeDto> pList = (await ProjeService().getProjeList(token))
        .where((p) => p.tur == 3)
        .toList()
      ..sort((a, b) => (a.kod ?? '').compareTo(b.kod ?? ''));
    List<ReferansDto> rList = (await ReferansService().getAll(token))
      ..sort((a, b) => (a.Kod ?? '').compareTo(b.Kod ?? ''));

    final tercihDepo = widget.varsayilanDepoId;
    final varsayilanDepoId =
        (tercihDepo != null && dList.any((d) => d.id == tercihDepo))
            ? tercihDepo
            : await VarsayilanDepoHelper.pickFrom(dList);
    final varsayilanProjeId = await VarsayilanProjeHelper.pickFrom(pList);

    if (mounted) {
      setState(() {
        _depoList = dList;
        _projeList = pList;
        _referanslar = rList;

        if (_depoList.isNotEmpty) k.depoid ??= varsayilanDepoId;
        if (_projeList.isNotEmpty) k.projeid ??= varsayilanProjeId;
        if (_referanslar.isNotEmpty) k.referansid ??= _referanslar.first.Id;
      });
    }
  }

  Future<void> _loadDepoadresler(int depoId) async {
    final mevcutId = k.depoadresid; // düzenleme modunda seçili adresi koru
    setState(() {
      _adresYukleniyor = true;
      _depoadresler = [];
      k.depoadresid = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final list = await DepoService().getDepoadresByDepoId(token, depoId);
      if (mounted)
        setState(() {
          _depoadresler = list;
          _adresYukleniyor = false;
          // Yüklenen listede varsa önceki seçimi geri getir
          if (mevcutId != null && list.any((a) => a.id == mevcutId)) {
            k.depoadresid = mevcutId;
          }
        });
    } catch (_) {
      if (mounted) setState(() => _adresYukleniyor = false);
    }
  }

  void _barkodIleAdresAra(String barkod) {
    final temiz = barkod.trim().toLowerCase();
    final bulunan = _depoadresler
            .where((a) => a.id != null && a.id!.toLowerCase() == temiz)
            .firstOrNull ??
        _depoadresler
            .where((a) => a.kod != null && a.kod!.toLowerCase() == temiz)
            .firstOrNull;
    if (bulunan != null) {
      setState(() => k.depoadresid = bulunan.id);
      final label = [bulunan.kod, bulunan.ad, bulunan.bolum]
          .where((s) => s != null && s.isNotEmpty)
          .join(' - ');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Adres: $label"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2)));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text("Depo adresi bulunamadı: $barkod"),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2)));
    }
  }

  Future<void> _kameraBarkodIleAdresAra() async {
    final barcode = await Navigator.push<String>(context,
        PermissionMaterialPageRoute(builder: (_) => BarcodeScannerSheet()));
    if (barcode != null && mounted) _barkodIleAdresAra(barcode);
  }

  Future<void> _terminalBarkodIleAdresAra() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("Depo Adresi",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
              hintText: "Barkod",
              prefixIcon: Icon(Icons.barcode_reader),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10))),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          ErpDialogAction(
              onPressed: () => Navigator.pop(context), child: Text("İptal")),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text),
              child: Text("Ara")),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted)
      _barkodIleAdresAra(result);
  }

  Future<void> _loadOlcuBirimByStok(int stokId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    try {
      final stok = await StokService().getStokById(token, stokId);
      if (!mounted || k.stokid != stokId) return;
      setState(() => k.stok = stok);

      // C# mantığı: Stokolcubr'dan Olcubr'ları al, başa Temelolcubr'u ekle
      final birimler = stok.Stokolcubr.where((s) => s.Olcubr != null)
          .map((s) => s.Olcubr!)
          .toList();

      if (stok.Temelolcubr != null) {
        birimler.insert(0, stok.Temelolcubr!);
      }

      // Duplicate temizle (Temelolcubr zaten Stokolcubr içinde olabilir)
      final gorulenler = <int>{};
      final tekBirimler =
          birimler.where((o) => o.Id != null && gorulenler.add(o.Id!)).toList();

      if (mounted && tekBirimler.isNotEmpty) {
        setState(() {
          _olcuBirimleri = tekBirimler;
          final mevcutVar = tekBirimler.any((o) => o.Id == k.olcubrid);
          if (!mevcutVar) k.olcubrid = tekBirimler.first.Id;

          // ── Yeni kalem: stoktan KDV / Fiyat / Tevkifat oto doldur ──
          final yeniKalem = widget.kalem == null;
          if (yeniKalem) {
            // 1) KDV oranı — stokta tanımlıysa al (API 0.20 gönderir → %20 yapıyoruz), yoksa %20
            final kdvSatis = stok.Kdvsatis ?? 0;
            k.kdvorani = kdvSatis > 0
                ? (kdvSatis <= 1.0 ? kdvSatis * 100 : kdvSatis)
                : 20.0;
            // 2) Satış fiyatı — fatura dövizi ile eşleşen fiyat kaydı, yoksa ilk kayıt
            final fiyatlar = stok.Stokfiyat;
            if (fiyatlar.isNotEmpty) {
              final eslesen = fiyatlar
                  .where((f) => f.Dovizid == widget.dovizId)
                  .firstOrNull;
              final fiyatDto = eslesen ?? fiyatlar.first;
              final satisfiyat = fiyatDto.Satisfiyat ?? 0;
              if (satisfiyat > 0) {
                k.fiyat = satisfiyat;
                _fiyatCtrl.text =
                    NumberFormatHelper.format(satisfiyat, decimal: 4);
              }
            }
            // 3) Tevkifat oranı — ürün değişince sıfırla, sonra stoktan al.
            //    Yabancı cari ise tevkifat hiç uygulanmaz.
            k.tevkifatorani = (widget.cariTR && (stok.Tevkifatorani ?? 0) > 0)
                ? stok.Tevkifatorani
                : null;
            // 4) İskonto sıfırla (önceki üründen kalmasın)
            k.iskontotutar = null;
            k.iskontoorani1 = null;
            k.iskontotutari1 = null;
            k.iskontoorani2 = null;
            k.iskontotutari2 = null;
          }

          // Stok özellik
          if (stok.Stokozelligesahip == true && stok.Stokozellik.isNotEmpty) {
            _stokozellikler = stok.Stokozellik;
            // Düzenleme modunda: mevcut stokozelliksabitid ile eşleş
            final mevcutSabitId = k.stokozelliksabitid;
            final eslesen = mevcutSabitId != null
                ? _stokozellikler
                    .where((o) => o.stokozelliksabitid == mevcutSabitId)
                    .firstOrNull
                : null;
            _seciliOzellikId = eslesen?.id ?? _stokozellikler.first.id;
          } else {
            _stokozellikler = [];
            _seciliOzellikId = null;
          }
        });
        // Stoktan fiyat/kdv geldiyse yeniden hesapla
        if (widget.kalem == null) {
          _isTL ? _hesapla() : _hesaplaDoviz();
        }
      } else {
        // API'den hiç birim gelmediyse genel listeyi kullan
        _loadOlcuBirimleri();
      }
    } catch (e) {
      debugPrint("Stok ölçü birimi yüklenemedi: $e");
      _loadOlcuBirimleri();
    }
  }

  Future<void> _loadOlcuBirimleri() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final list = await _olcuBrService.getAll(token);
    if (mounted) {
      setState(() {
        _olcuBirimleri = list;
        k.olcubrid ??=
            _olcuBirimleri.isNotEmpty ? _olcuBirimleri.first.Id : null;
      });
    }
  }

  void _hesapla() {
    final miktar = NumberFormatHelper.parse(_miktarCtrl.text);
    final fiyat = NumberFormatHelper.parse(_fiyatCtrl.text);

    final sonuc = FaturaHesapHelper.hesaplaKalem(
      miktar: miktar,
      fiyat: fiyat,
      iskontoTutar: k.iskontotutar ?? 0,
      kdvOrani: k.kdvorani ?? 0,
      tevkifatOrani: k.tevkifatorani ?? 0,
      kdvDahil: widget.kdvDahil,
      malFazlasiAdet: k.malfazlasiiskonto ?? 0,
    );

    setState(() {
      k.miktar = miktar;
      k.fiyat = fiyat;
      k.bruttutar = sonuc.bruttutar;
      k.kdvtutar = sonuc.kdvtutar;
      k.tevkifatmatrahi = sonuc.tevkifatmatrahi;
      k.tevkifattutar = sonuc.tevkifattutar;
      k.tutar = sonuc.tutar;
    });
  }

// Döviz fiyat girilince: kur ile çarp → birim fiyat, sonra normal hesapla
  void _hesaplaDoviz() {
    final dovizFiyat = NumberFormatHelper.parse(_dovizFiyatCtrl.text);
    final kur = widget.kur ?? 1.0;
    final tlFiyat = dovizFiyat * kur;

    setState(() {
      k.dovizfiyat = dovizFiyat;
      _fiyatCtrl.text = NumberFormatHelper.format(tlFiyat, decimal: 4);
    });
    _hesapla();
  }

  // EN ÜST KATMAN (OVERLAY) UYARI MESAJI
  void _showOverlayMessenger(
      String title, String message, IconData icon, Color color) {
    OverlayState? overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            duration: Duration(
                milliseconds: 600), // Biraz daha yumuşak olması için artırıldı
            curve: Curves.easeOutBack, // Hata veren yer burasıydı, düzeltildi
            tween: Tween(begin: -100.0, end: 0.0),
            builder: (context, value, child) =>
                Transform.translate(offset: Offset(0, value), child: child),
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                      color: color.withOpacity(0.4),
                      blurRadius: 15,
                      offset: Offset(0, 8))
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: _scheme.surface, size: 28),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(title,
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.w900,
                                color: _scheme.onSurface,
                                fontSize: 14)),
                        Text(message,
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                color: _scheme.onSurfaceVariant,
                                fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlayState.insert(overlayEntry);
    Future.delayed(Duration(seconds: 3), () {
      if (overlayEntry.mounted) overlayEntry.remove();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Başlık (sadece başlık + kapat)
            _buildHeader(),
            SizedBox(height: 12),

            // Kaydırılabilir form alanları
            Expanded(
              child: SingleChildScrollView(
                physics: BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Ürün Seçimi
                    _buildStokSecici(),
                    _buildDepoBakiyeSatiri(),
                    SizedBox(height: 10),

                    // 2. Miktar, Birim
                    _buildMiktarBirimKart(),
                    SizedBox(height: 10),

                    // 3. Döviz Fiyat, Birim Fiyat
                    _buildFiyatSatiri(),
                    SizedBox(height: 10),

                    // 4. KDV, Tevkifat
                    _buildKdvTevkifatSatiri(),
                    SizedBox(height: 10),

                    // 5. Depo, Ambalaj Türü
                    _buildDepoAmbalajSatiri(),
                    _buildDepoadresRow(),
                    DocumentLineExtras(
                        exemptionId: k.istisnaId,
                        exemption: k.istisna,
                        packageUnitId: k.olcubr2id,
                        packageUnit: k.olcubr2,
                        onExemption: (v) => setState(() {
                              k.istisnaId = v?.id;
                              k.istisna = v;
                            }),
                        onPackageUnit: (v) => setState(() {
                              k.olcubr2id = v?.Id;
                              k.olcubr2 = v;
                            })),
                    SizedBox(height: 10),

                    // Stok özelliği (varsa)
                    if (_stokozellikler.isNotEmpty) ...[
                      _buildOzellikDropdown(),
                      SizedBox(height: 10),
                    ],

                    // 6. Stok Adı Açıklama
                    _buildStokAdiAciklama(),
                    SizedBox(height: 10),

                    // 7-8. Proje + Referans (yan yana)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(child: _buildProjeRow()),
                        SizedBox(width: 12),
                        Expanded(child: _buildReferansRow()),
                      ],
                    ),
                    SizedBox(height: 10),

                    // 9. Açıklama
                    _buildAciklamaAlani(),
                    SizedBox(height: 16),

                    // Toplam özet kartı
                    _buildToplamOzetKarti(),
                    SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // ── Yapışık alt butonlar ────────────────────────────────────────
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Text(widget.kalem != null ? "Kalem Düzenle" : "Kalem Ekle",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: primaryDark)),
        Spacer(),
        IconButton(
          onPressed: () => Navigator.pop(context),
          padding: EdgeInsets.zero,
          constraints: BoxConstraints(),
          icon: CircleAvatar(
              backgroundColor: _scheme.outlineVariant,
              radius: 13,
              child: Icon(Icons.close_rounded, size: 15, color: Colors.black)),
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: EdgeInsets.fromLTRB(0, 10, 0, 16),
      decoration: BoxDecoration(
        color: _scheme.surfaceContainerLow,
        border:
            Border(top: BorderSide(color: _scheme.outlineVariant, width: 1)),
      ),
      child: Row(
        children: [
          // İskonto butonu
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: warnOrange,
                side: BorderSide(color: warnOrange, width: 1.5),
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              icon: Icon(Icons.percent_rounded, size: 16),
              label: Text("İskonto",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
              onPressed: () async {
                final res = await showKalemIskontoSheet(
                  context,
                  kalem: k,
                  dovizId: widget.dovizId,
                  kdvDahil: widget.kdvDahil,
                  brutAra: (NumberFormatHelper.parse(_miktarCtrl.text)) *
                      (NumberFormatHelper.parse(_fiyatCtrl.text)),
                );
                if (res != null)
                  setState(() {
                    k = res;
                    _hesapla();
                  });
              },
            ),
          ),
          SizedBox(width: 8),
          // Kalemi Kaydet butonu
          Expanded(
            flex: 3,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: accentBlue,
                foregroundColor: _scheme.onPrimary,
                padding: EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: Icon(
                  widget.kalem != null
                      ? Icons.check_rounded
                      : Icons.add_rounded,
                  size: 16),
              label: Text(
                widget.kalem != null ? "Güncelle" : "Kalemi Kaydet",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 13),
              ),
              onPressed: () {
                if (k.stokid == null) {
                  _showOverlayMessenger(
                      "Stok Seçilmedi",
                      "Devam etmek için bir ürün seçiniz.",
                      Icons.inventory_2_outlined,
                      errorRed);
                  return;
                }
                final fiyat = NumberFormatHelper.parse(_fiyatCtrl.text);
                if (fiyat <= 0) {
                  _showOverlayMessenger(
                      "Fiyat Eksik",
                      "Birim fiyat sıfırdan büyük olmalıdır.",
                      Icons.payments_outlined,
                      warnOrange);
                  return;
                }
                if (_seciliOzellikId != null) {
                  final secilen = _stokozellikler
                      .where((o) => o.id == _seciliOzellikId)
                      .firstOrNull;
                  k.stokozelliksabitid = secilen?.stokozelliksabitid;
                }
                k.olcubrcarpim =
                    k.stok?.multiplierFor(k.olcubrid) ?? k.olcubrcarpim;
                Navigator.pop(context, k);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Widget _buildSectionTitle(String title) {
  //   return Padding(
  //     padding: EdgeInsets.only(bottom: 8, left: 4),
  //     child: Text(title, style: TextStyle(fontFamily: 'Roboto', fontSize: 10, fontWeight: FontWeight.w800, color: _scheme.onSurfaceVariant, letterSpacing: 1)),
  //   );
  // }

  Widget _buildStokSecici() {
    return Row(
      children: [
        // Ürün seç butonu
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: _scheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: Offset(0, 4))
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final secilen = await showErpSelector<StokListDto>(
                    context: context,
                    title: "Stok Seç",
                    hintText: "Stok Kodu, Adı veya Barkod...",
                    items: widget.stoklar,
                    itemText: (s) => "${s.Kod ?? ''} - ${s.Ad ?? ''}",
                    getBarcodes: (s) => s.getBarkodListesi(),
                    getUnit: (s) => s.TemelolcubrAd ?? '',
                  );
                  if (secilen != null) {
                    setState(() {
                      k.stokid = secilen.Id;
                      k.stok = StokDto(
                          Id: secilen.Id, Kod: secilen.Kod, Ad: secilen.Ad);
                      _hesapla();
                    });
                    if (secilen.Id != null) _loadOlcuBirimByStok(secilen.Id!);
                  }
                },
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: accentBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.inventory_2_rounded,
                            color: accentBlue, size: 20),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: k.stokid != null
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(k.stok?.Kod ?? '',
                                      style: TextStyle(
                                          fontFamily: 'Roboto',
                                          fontSize: 11,
                                          color: _scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.3)),
                                  SizedBox(height: 1),
                                  Text(k.stok?.Ad ?? '',
                                      style: TextStyle(
                                          fontFamily: 'Roboto',
                                          fontSize: 13,
                                          color: primaryDark,
                                          fontWeight: FontWeight.w700),
                                      overflow: TextOverflow.ellipsis),
                                ],
                              )
                            : Text("Ürün Seçmek İçin Dokunun",
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    color: _scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 13)),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: _scheme.onSurfaceVariant, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 8),
        // Barkod okuma butonu
        Container(
          decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: Offset(0, 4))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final secilen = await showErpSelector<StokListDto>(
                  context: context,
                  title: "Barkod ile Stok Seç",
                  hintText: "Barkod",
                  items: widget.stoklar,
                  itemText: (s) => "${s.Kod ?? ''} - ${s.Ad ?? ''}",
                  getBarcodes: (s) => s.getBarkodListesi(),
                  getUnit: (s) => s.TemelolcubrAd ?? '',
                  startWithCamera: true,
                );
                if (secilen != null) {
                  setState(() {
                    k.stokid = secilen.Id;
                    k.stok = StokDto(
                        Id: secilen.Id, Kod: secilen.Kod, Ad: secilen.Ad);
                    _hesapla();
                  });
                  if (secilen.Id != null) _loadOlcuBirimByStok(secilen.Id!);
                }
              },
              child: Padding(
                padding: EdgeInsets.all(14),
                child: Icon(Icons.qr_code_scanner_rounded,
                    color: accentBlue, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiktarBirimKart() {
    return Row(
      crossAxisAlignment:
          CrossAxisAlignment.end, // Alt hizalamayı eşitlemek için
      children: [
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Miktar",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _scheme.onSurfaceVariant)),
              SizedBox(height: 4),
              _modernInputKutusu(
                child: Row(
                  children: [
                    _miktarButonu(Icons.remove_rounded, errorRed, () {
                      double v = NumberFormatHelper.parse(_miktarCtrl.text);
                      if (v > 0) {
                        _miktarCtrl.text = _trFmt(v - 1, 4);
                        _hesapla();
                      }
                    }),
                    Expanded(
                      child: TextField(
                        controller: _miktarCtrl,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: primaryDark),
                        keyboardType:
                            TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(border: InputBorder.none),
                        onChanged: (_) => _hesapla(),
                      ),
                    ),
                    _miktarButonu(Icons.add_rounded, Colors.green.shade600, () {
                      double v = NumberFormatHelper.parse(_miktarCtrl.text);
                      _miktarCtrl.text = _trFmt(v + 1, 4);
                      _hesapla();
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
        Expanded(
            child: _modernDropdownField(
                "Birim",
                _olcuBirimleri.any((o) => o.Id == k.olcubrid)
                    ? k.olcubrid
                    : null,
                _olcuBirimleri
                    .map((o) =>
                        DropdownMenuItem(value: o.Id, child: Text(o.Ad ?? '')))
                    .toList(),
                (v) => setState(() => k.olcubrid = v))),
      ],
    );
  }

  Widget _miktarButonu(IconData icon, Color color, VoidCallback tap) =>
      IconButton(onPressed: tap, icon: Icon(icon, color: color, size: 22));

  // 3. Satır: Döviz Fiyat + Birim Fiyat
  Widget _buildFiyatSatiri() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!_isTL) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Döviz Fiyat ($sembol)",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: _scheme.onSurfaceVariant)),
                SizedBox(height: 4),
                _modernInputKutusu(
                  child: TextField(
                    controller: _dovizFiyatCtrl,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: primaryDark),
                    keyboardType:
                        TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        prefixText: sembol,
                        prefixStyle: TextStyle(
                            fontFamily: 'Roboto',
                            color: accentBlue,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    onChanged: (_) => _hesaplaDoviz(),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Birim Fiyat (₺)",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _isTL
                          ? _scheme.onSurfaceVariant
                          : _scheme.onSurfaceVariant)),
              SizedBox(height: 4),
              _modernInputKutusu(
                child: _isTL
                    ? Row(children: [
                        _miktarButonu(Icons.remove_rounded, errorRed, () {
                          double v = NumberFormatHelper.parse(_fiyatCtrl.text);
                          if (v > 0) {
                            _fiyatCtrl.text =
                                NumberFormatHelper.format(v - 1, decimal: 4);
                            _hesapla();
                          }
                        }),
                        Expanded(
                            child: TextField(
                          controller: _fiyatCtrl,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: primaryDark),
                          keyboardType:
                              TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(
                              border: InputBorder.none,
                              prefixText: "₺",
                              prefixStyle: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: accentBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13)),
                          onChanged: (_) => _hesapla(),
                        )),
                        _miktarButonu(Icons.add_rounded, Colors.green.shade600,
                            () {
                          double v = NumberFormatHelper.parse(_fiyatCtrl.text);
                          _fiyatCtrl.text =
                              NumberFormatHelper.format(v + 1, decimal: 4);
                          _hesapla();
                        }),
                      ])
                    : TextField(
                        controller: _fiyatCtrl,
                        enabled: false,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: _scheme.onSurfaceVariant),
                        decoration: InputDecoration(
                            border: InputBorder.none,
                            prefixText: "₺",
                            prefixStyle: TextStyle(
                                fontFamily: 'Roboto',
                                color: _scheme.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4. Satır: KDV + Tevkifat (yabancı cari ise tevkifat gösterilmez)
  Widget _buildKdvTevkifatSatiri() {
    return Row(
      children: [
        Expanded(
          child: _modernDropdownField(
            "KDV %",
            k.kdvorani?.toInt(),
            LookupHelper.kdvOranlari
                .map((x) =>
                    DropdownMenuItem(value: x.oran, child: Text("${x.oran}")))
                .toList(),
            (v) {
              k.kdvorani = v?.toDouble();
              _isTL ? _hesapla() : _hesaplaDoviz();
            },
          ),
        ),
        if (widget.cariTR) ...[
          SizedBox(width: 12),
          Expanded(
            child: _modernDropdownFieldStr(
              "Tevkifat",
              VergiCouples.adByOran(k.tevkifatorani),
              VergiCouples.tevkifatOranlari
                  .map((e) => DropdownMenuItem(value: e.ad, child: Text(e.ad)))
                  .toList(),
              (v) => setState(() {
                k.tevkifatorani = VergiCouples.oranByAd(v);
                _hesapla();
              }),
            ),
          ),
        ],
      ],
    );
  }

  // 5. Satır: Depo + Ambalaj Türü
  Widget _buildDepoAmbalajSatiri() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Depo",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: _scheme.onSurfaceVariant)),
              SizedBox(height: 4),
              _depoSecici(
                value: k.depoid,
                items: _depoList,
                onChanged: (v) {
                  setState(() {
                    k.depoid = v?.id;
                    k.depoadresid = null;
                    _depoadresler = [];
                  });
                  if (v?.id != null) _loadDepoadresler(v!.id!);
                },
              ),
            ],
          ),
        ),
        SizedBox(width: 12),
      ],
    );
  }

  // 6. Satır: Stok Adı Açıklama (yeni alan)
  Widget _buildStokAdiAciklama() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Stok Adı Açıklama",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
              color: _scheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _scheme.outlineVariant)),
          child: TextField(
            controller: _stokAdiAciklamaCtrl,
            style: TextStyle(
                fontFamily: 'Roboto', fontSize: 13, color: primaryDark),
            decoration: InputDecoration(
              hintText: "Stok adı / açıklama...",
              hintStyle: TextStyle(
                  fontFamily: 'Roboto',
                  color: _scheme.onSurfaceVariant,
                  fontSize: 13),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: InputBorder.none,
            ),
            onChanged: (v) => k.stokadiaciklama = v.isEmpty ? null : v,
          ),
        ),
      ],
    );
  }

  // 7. Satır: Proje
  Widget _buildProjeRow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Proje",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
        SizedBox(height: 4),
        _modernInputKutusu(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value:
                  _projeList.any((e) => e.id == k.projeid) ? k.projeid : null,
              isExpanded: true,
              icon: Icon(Icons.assignment_rounded, size: 18, color: accentBlue),
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryDark),
              items: _projeList
                  .map((e) => DropdownMenuItem(
                        value: e.id,
                        child:
                            Text(e.ad ?? "", overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => k.projeid = v),
            ),
          ),
        ),
      ],
    );
  }

  // 8. Satır: Referans
  Widget _buildReferansRow() {
    final safeRef =
        _referanslar.any((e) => e.Id == k.referansid) ? k.referansid : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Referans",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
        SizedBox(height: 4),
        _modernInputKutusu(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: safeRef,
              isExpanded: true,
              icon: Icon(Icons.bookmark_outline_rounded,
                  size: 18, color: accentBlue),
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primaryDark),
              items: _referanslar
                  .map((e) => DropdownMenuItem(
                        value: e.Id,
                        child: Text("${e.Kod ?? ''} - ${e.Ad ?? ''}",
                            overflow: TextOverflow.ellipsis,
                            style:
                                TextStyle(fontFamily: 'Roboto', fontSize: 12)),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => k.referansid = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDepoadresRow() {
    final seciliDepo =
        _depoList.firstWhere((d) => d.id == k.depoid, orElse: () => DepoDto());
    if (seciliDepo.dinamikdepo != true) return SizedBox.shrink();

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: 12),
      Row(children: [
        Icon(Icons.location_on_outlined,
            size: 12, color: _scheme.onSurfaceVariant),
        SizedBox(width: 4),
        Text("Depo Adresi",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
        if (_adresYukleniyor) ...[
          SizedBox(width: 8),
          SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: accentBlue)),
        ],
      ]),
      SizedBox(height: 4),
      Row(children: [
        Expanded(
            child: _modernInputKutusu(
          child: _adresYukleniyor
              ? Center(
                  child: Text("Yükleniyor...",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: _scheme.onSurfaceVariant)))
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                  value: _depoadresler.any((a) => a.id == k.depoadresid)
                      ? k.depoadresid
                      : null,
                  isExpanded: true,
                  hint: Text("Adres seçiniz",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: _scheme.onSurfaceVariant)),
                  icon: Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18, color: accentBlue),
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: primaryDark),
                  items: _depoadresler
                      .where((a) => a.id != null)
                      .map((a) => DropdownMenuItem<String>(
                            value: a.id,
                            child: Text(
                                [a.kod, a.ad, a.bolum]
                                    .where((s) => s != null && s.isNotEmpty)
                                    .join(' - '),
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontFamily: 'Roboto', fontSize: 12)),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => k.depoadresid = v),
                )),
        )),
        SizedBox(width: 8),
        _adresBtn(Icons.qr_code_scanner_rounded, Colors.green.shade600,
            _kameraBarkodIleAdresAra),
        SizedBox(width: 8),
        _adresBtn(Icons.barcode_reader, accentBlue, _terminalBarkodIleAdresAra),
      ]),
    ]);
  }

  Widget _adresBtn(IconData icon, Color color, VoidCallback onTap) => Container(
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _scheme.outlineVariant),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
            ]),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: _depoadresler.isEmpty ? null : onTap,
              child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(icon,
                      color: _depoadresler.isEmpty
                          ? _scheme.outlineVariant
                          : color,
                      size: 22)),
            )),
      );

  Widget _buildAciklamaAlani() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.notes_rounded, size: 14, color: _scheme.onSurfaceVariant),
          SizedBox(width: 4),
          Text("Açıklama",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _scheme.onSurfaceVariant)),
        ]),
        SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _scheme.outlineVariant),
          ),
          child: TextField(
            controller: _aciklamaCtrl,
            maxLines: 3,
            minLines: 1,
            onChanged: (v) => k.aciklama = v.isEmpty ? null : v,
            style: TextStyle(
                fontFamily: 'Roboto', fontSize: 14, color: primaryDark),
            decoration: InputDecoration(
              hintText: "Kalem açıklaması (opsiyonel)...",
              hintStyle: TextStyle(
                  fontFamily: 'Roboto',
                  color: _scheme.onSurfaceVariant,
                  fontSize: 13),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOzellikDropdown() {
    final safeValue = _stokozellikler.any((e) => e.id == _seciliOzellikId)
        ? _seciliOzellikId
        : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(Icons.tune_rounded, size: 14, color: _scheme.onSurfaceVariant),
          SizedBox(width: 4),
          Text("Stok Özelliği",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _scheme.onSurfaceVariant)),
        ]),
        SizedBox(height: 4),
        _modernInputKutusu(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: safeValue,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  size: 20, color: accentBlue),
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primaryDark),
              items: _stokozellikler
                  .map((e) => DropdownMenuItem<int>(
                        value: e.id,
                        child:
                            Text(e.displayAd, overflow: TextOverflow.ellipsis),
                      ))
                  .toList(),
              onChanged: (v) => setState(() => _seciliOzellikId = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _modernDropdownField(String label, int? value,
      List<DropdownMenuItem<int>> items, Function(int?) onChanged) {
    // items henüz yüklenmemişse veya value listede yoksa null kullan
    final safeValue = items.any((e) => e.value == value) ? value : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
        SizedBox(height: 4),
        _modernInputKutusu(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              isExpanded: true,
              value: safeValue,
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _modernDropdownFieldStr(String label, String? value,
      List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    final safeValue =
        items.any((e) => e.value == value) ? value : items.first.value;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
        SizedBox(height: 4),
        _modernInputKutusu(
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: safeValue,
              icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20),
              items: items,
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _modernInputKutusu({required Widget child}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12),
      height: 54,
      decoration: BoxDecoration(
          color: _scheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _scheme.outlineVariant)),
      child: child,
    );
  }

  /// Depo seçimi — rehber tarzı, tam ekran, kod/ad ile aranabilir seçici.
  Widget _depoSecici({
    required int? value,
    required List<DepoDto> items,
    required ValueChanged<DepoDto?> onChanged,
  }) {
    DepoDto? selected;
    for (final d in items) {
      if (d.id == value) {
        selected = d;
        break;
      }
    }
    final text = selected != null
        ? "${selected.kod ?? ''} - ${selected.ad ?? ''}"
        : null;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          final secilen = await showErpSelector<DepoDto>(
            context: context,
            title: "Depo Seç",
            hintText: "Depo Kodu veya Adı...",
            items: items,
            itemText: (d) => "${d.kod ?? ''} - ${d.ad ?? ''}",
          );
          if (secilen != null) onChanged(secilen);
        },
        child: _modernInputKutusu(
            child: Row(children: [
          Icon(Icons.warehouse_rounded, size: 18, color: accentBlue),
          SizedBox(width: 8),
          Expanded(
              child: Text(text ?? "Seçiniz",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: text != null
                          ? primaryDark
                          : _scheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis)),
          Icon(Icons.search_rounded, size: 16, color: _scheme.onSurfaceVariant),
        ])),
      ),
    );
  }

  Widget _buildToplamOzetKarti() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: primaryDark.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          _ozetSatir("Ara Toplam", (k.miktar ?? 0) * (k.fiyat ?? 0)),
          if ((k.iskontotutar ?? 0) > 0)
            _ozetSatir("İskonto", k.iskontotutar ?? 0, isNeg: true),
          if ((k.iskontotutar ?? 0) > 0) ...[
            Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child:
                    Divider(color: _scheme.onSurfaceVariant, thickness: 0.5)),
            _ozetSatir("İskonto Sonrası", k.bruttutar ?? 0, isVurgu: true),
            Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child:
                    Divider(color: _scheme.onSurfaceVariant, thickness: 0.5)),
          ],
          if ((k.malfazlasiiskonto ?? 0) > 0)
            _ozetSatir(
                "Mal Fazlası (${(k.malfazlasiiskonto ?? 0).toInt()} Birim)",
                k.malfazlasitutar ?? 0,
                isNeg: false),
          _ozetSatir("KDV %${k.kdvorani?.toInt() ?? 0}", k.kdvtutar ?? 0),
          if ((k.tevkifatorani ?? 0) > 0)
            _ozetSatir("Tevkifat ${VergiCouples.adByOran(k.tevkifatorani)}",
                k.tevkifattutar ?? 0,
                isNeg: true),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Divider(color: _scheme.onSurfaceVariant, thickness: 1)),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("NET TOPLAM",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      color: _scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${NumberFormatHelper.format(_isTL ? (k.tutar ?? 0) : (k.tutar ?? 0) / (widget.kur ?? 1.0))} $sembol",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        color: _scheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w900),
                  ),
                  if (!_isTL)
                    Text(
                      "${NumberFormatHelper.format(k.tutar ?? 0)} ₺",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          color: _scheme.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w400),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ozetSatir(String label, double val,
      {bool isNeg = false, bool isVurgu = false}) {
    final double dovizGosterim = _isTL ? val : val / (widget.kur ?? 1.0);
    final String prefix = isNeg ? '-' : '';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
              fontFamily: 'Roboto',
              color: isVurgu ? _scheme.surface : _scheme.onSurfaceVariant,
              fontSize: isVurgu ? 14 : 13,
              fontWeight: isVurgu ? FontWeight.w700 : FontWeight.normal,
            )),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "$prefix${NumberFormatHelper.format(dovizGosterim)} $sembol",
              style: TextStyle(
                fontFamily: 'Roboto',
                color: _scheme.onSurface,
                fontWeight: isVurgu ? FontWeight.w800 : FontWeight.w600,
                fontSize: isVurgu ? 14 : 13,
              ),
            ),
            if (!_isTL)
              Text(
                "$prefix${NumberFormatHelper.format(val)} ₺",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: _scheme.onSurfaceVariant,
                    fontSize: 10,
                    fontWeight: FontWeight.w400),
              ),
          ],
        ),
      ],
    );
  }

  // Widget _buildAksiyonButonlari() {
  //   return Row(
  //     children: [
  //       Expanded(
  //         flex: 2,
  //         child: ElevatedButton(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: warnOrange,
  //             foregroundColor: _scheme.onPrimary,
  //             padding: EdgeInsets.symmetric(vertical: 16),
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //           ),
  //           onPressed: () async {
  //             final res = await showKalemIskontoSheet(
  //               context,
  //               kalem: k,
  //               dovizId: widget.dovizId,
  //               kdvDahil: widget.kdvDahil,
  //               brutAra: (NumberFormatHelper.parse(_miktarCtrl.text)) *
  //                        (NumberFormatHelper.parse(_fiyatCtrl.text)),
  //             );
  //             if (res != null) setState(() { k = res; _hesapla(); });
  //           },
  //           child: Row(
  //             mainAxisAlignment: MainAxisAlignment.center,
  //             children: [
  //               Icon(Icons.percent_rounded, size: 18),
  //               SizedBox(width: 6),
  //               Text("İskonto", style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w800, fontSize: 14)),
  //             ],
  //           ),
  //         ),
  //       ),
  //       SizedBox(width: 12),
  //       Expanded(
  //         flex: 3,
  //         child: ElevatedButton(
  //           style: ElevatedButton.styleFrom(
  //             backgroundColor: accentBlue,
  //             foregroundColor: _scheme.onPrimary,
  //             padding: EdgeInsets.symmetric(vertical: 16),
  //             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  //           ),
  //           onPressed: () {
  //             if (k.stokid == null) {
  //               _showOverlayMessenger("Stok Seçilmedi", "Devam etmek için bir ürün seçiniz.", Icons.inventory_2_outlined, errorRed);
  //               return;
  //             }
  //             final fiyat = NumberFormatHelper.parse(_fiyatCtrl.text);
  //             if (fiyat <= 0) {
  //               _showOverlayMessenger("Fiyat Eksik", "Birim fiyat sıfırdan büyük olmalıdır.", Icons.payments_outlined, warnOrange);
  //               return;
  //             }
  //             // Stok özellik seçildiyse dto'ya yaz
  //             if (_seciliOzellikId != null) {
  //               final secilen = _stokozellikler.where((o) => o.id == _seciliOzellikId).firstOrNull;
  //               k.stokozelliksabitid = secilen?.stokozelliksabitid;
  //             }
  //             Navigator.pop(context, k);
  //           },
  //           child: Text(
  //             widget.kalem != null ? "GÜNCELLE" : "EKLE",
  //             style: TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.w900, fontSize: 16),
  //           ),
  //         ),
  //       ),
  //     ],
  //   );
  // }
}
