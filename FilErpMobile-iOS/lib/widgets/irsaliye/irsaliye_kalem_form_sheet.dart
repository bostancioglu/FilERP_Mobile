import '../document_line_extras.dart';
import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/vergi_couples.dart';
import '../../helpers/number_format_helper.dart';
import '../../helpers/ui_feedback.dart';
import '../../helpers/varsayilan_depo_helper.dart';
import '../../helpers/varsayilan_proje_helper.dart';
import '../../helpers/fatura_hesap_helper.dart';
import '../../models/entities/irsaliye/irsaliyehareket_dto.dart';
import '../../models/entities/stok/stok_list_dto.dart';
import '../../models/entities/stok/stok_dto.dart';
import '../../models/entities/stok/stokozellik_dto.dart';
import '../../models/entities/depo/depo_dto.dart';
import '../../models/entities/depo/depoadres_dto.dart';
import '../../services/depo/depo_service.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../models/entities/proje/proje_dto.dart';
import '../../models/entities/olcubirimi/olcubr_dto.dart';
import '../../services/stok/stok_service.dart';
import '../../services/helper/olcubr_service.dart';
import '../../widgets/erp_selector.dart';
import '../../widgets/irsaliye/irsaliye_kalem_iskonto_sheet.dart';

Future<IrsaliyehareketDto?> showIrsaliyeKalemForm(
  BuildContext context, {
  IrsaliyehareketDto? kalem,
  required List<StokListDto> stoklar,
  required List<ProjeDto> projeler,
  required List<DepoDto> depolar,
  required bool kdvDahil,
}) {
  return showDialog<IrsaliyehareketDto>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: _IrsaliyeKalemForm(
          kalem: kalem,
          stoklar: stoklar,
          projeler: projeler,
          depolar: depolar,
          kdvDahil: kdvDahil),
    ),
  );
}

class _IrsaliyeKalemForm extends StatefulWidget {
  final IrsaliyehareketDto? kalem;
  final List<StokListDto> stoklar;
  final List<ProjeDto> projeler;
  final List<DepoDto> depolar;
  final bool kdvDahil;

  const _IrsaliyeKalemForm({
    this.kalem,
    required this.stoklar,
    required this.projeler,
    required this.depolar,
    required this.kdvDahil,
  });

  @override
  State<_IrsaliyeKalemForm> createState() => _IrsaliyeKalemFormState();
}

class _IrsaliyeKalemFormState extends State<_IrsaliyeKalemForm> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _positive => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFF6EE7B7)
      : Color(0xFF16704A);
  Color get primaryDark => _scheme.onSurface;
  Color get accentPurple => _scheme.primary;
  Color get errorRed => _scheme.error;
  Color get warnOrange => _scheme.primary;

  late IrsaliyehareketDto k;
  final _miktarCtrl = TextEditingController();
  final _fiyatCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();

  List<OlcubrDto> _olcuBirimleri = [];
  List<StokozellikDto> _stokozellikler = [];
  List<DepoadresDto> _depoadresler = [];
  bool _adresYukleniyor = false;

  String _trFmt(double v, int d) => v.toStringAsFixed(d).replaceAll('.', ',');

  @override
  void initState() {
    super.initState();
    k = widget.kalem != null ? widget.kalem!.copy() : IrsaliyehareketDto();
    k.miktar ??= 1;
    k.fiyat ??= 0;
    k.kdvorani ??= 20.0;

    _miktarCtrl.text = widget.kalem != null ? _trFmt(k.miktar ?? 0, 4) : '';
    _fiyatCtrl.text = widget.kalem != null
        ? NumberFormatHelper.format(k.fiyat ?? 0, decimal: 4)
        : '';
    _aciklamaCtrl.text = k.aciklama ?? '';

    final ilkDepoAtandi = k.depoid == null && widget.depolar.isNotEmpty;
    if (ilkDepoAtandi) k.depoid = widget.depolar.first.id;
    final ilkProjeAtandi = k.projeid == null && widget.projeler.isNotEmpty;
    if (ilkProjeAtandi) k.projeid = widget.projeler.first.id;

    if (k.stokid != null)
      _loadOlcuBirimByStok(k.stokid!);
    else
      _loadOlcuBirimleri();
    _hesapla();
    // Düzenleme modunda depoid varsa adresleri yükle
    if (k.depoid != null) _loadDepoadresler(k.depoid!);
    if (ilkDepoAtandi) _applyVarsayilanDepo(k.depoid);
    if (ilkProjeAtandi) _applyVarsayilanProje(k.projeid);
  }

  /// Kullanıcının seçtiği varsayılan projeyi uygular (ilk proje henüz değiştirilmediyse).
  Future<void> _applyVarsayilanProje(int? ilkId) async {
    final pick = await VarsayilanProjeHelper.pickFrom(widget.projeler);
    if (!mounted || pick == null || pick == ilkId || k.projeid != ilkId) return;
    setState(() => k.projeid = pick);
  }

  /// Kullanıcının seçtiği varsayılan depoyu uygular (ilk depo henüz değiştirilmediyse).
  Future<void> _applyVarsayilanDepo(int? ilkId) async {
    final pick = await VarsayilanDepoHelper.pickFrom(widget.depolar);
    if (!mounted || pick == null || pick == ilkId || k.depoid != ilkId) return;
    setState(() => k.depoid = pick);
    _loadDepoadresler(pick);
  }

  @override
  void dispose() {
    _miktarCtrl.dispose();
    _fiyatCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadOlcuBirimByStok(int stokId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    try {
      final stok = await StokService().getStokById(token, stokId);
      if (!mounted || k.stokid != stokId) return;
      setState(() => k.stok = stok);
      final birimler = stok.Stokolcubr.where((s) => s.Olcubr != null)
          .map((s) => s.Olcubr!)
          .toList();
      if (stok.Temelolcubr != null) birimler.insert(0, stok.Temelolcubr!);
      final seen = <int>{};
      final tekBirim =
          birimler.where((o) => o.Id != null && seen.add(o.Id!)).toList();
      if (mounted && tekBirim.isNotEmpty) {
        setState(() {
          _olcuBirimleri = tekBirim;
          if (!tekBirim.any((o) => o.Id == k.olcubrid)) {
            k.olcubrid = tekBirim.first.Id;
            k.olcubr = tekBirim.first;
          }
          if (widget.kalem == null) {
            final kdvSatis = stok.Kdvsatis ?? 0;
            k.kdvorani = kdvSatis > 0
                ? (kdvSatis <= 1.0 ? kdvSatis * 100 : kdvSatis)
                : 20.0;
            final fiyatlar = stok.Stokfiyat;
            if (fiyatlar.isNotEmpty) {
              final satisfiyat = fiyatlar.first.Satisfiyat ?? 0;
              if (satisfiyat > 0) {
                k.fiyat = satisfiyat;
                _fiyatCtrl.text =
                    NumberFormatHelper.format(satisfiyat, decimal: 4);
              }
            }
            if ((stok.Tevkifatorani ?? 0) > 0)
              k.tevkifatorani = stok.Tevkifatorani;
            if (stok.Stokozelligesahip == true && stok.Stokozellik.isNotEmpty)
              _stokozellikler = stok.Stokozellik;
          }
        });
        _hesapla();
      } else {
        _loadOlcuBirimleri();
      }
    } catch (_) {
      _loadOlcuBirimleri();
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

  Future<void> _loadOlcuBirimleri() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    final list = await OlcubrService().getAll(token);
    if (mounted)
      setState(() {
        _olcuBirimleri = list;
        k.olcubrid ??= list.isNotEmpty ? list.first.Id : null;
      });
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

  // ─── BUILD ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: SingleChildScrollView(
        physics: BouncingScrollPhysics(),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _buildHeader(),
          SizedBox(height: 20),
          _buildStokSecici(),
          SizedBox(height: 20),
          _buildMiktarBirimKart(),
          SizedBox(height: 20),
          _buildFiyatKdvKart(),
          SizedBox(height: 20),
          _buildDepoProjeKart(),
          if (_stokozellikler.isNotEmpty) ...[
            SizedBox(height: 20),
            _buildOzellikDropdown(),
          ],
          SizedBox(height: 20),
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
                  }),
              stockDescription: k.stokadiaciklama,
              onStockDescription: (v) =>
                  k.stokadiaciklama = v.trim().isEmpty ? null : v),
          _buildAciklamaAlani(),
          SizedBox(height: 24),
          _buildToplamOzetKarti(),
          SizedBox(height: 24),
          _buildAksiyonButonlari(),
        ]),
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────
  Widget _buildHeader() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Kalem Detayı",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: primaryDark)),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: CircleAvatar(
                backgroundColor: _scheme.outlineVariant,
                radius: 15,
                child:
                    Icon(Icons.close_rounded, size: 18, color: Colors.black)),
          ),
        ],
      );

  // ─── STOK SEÇİCİ ─────────────────────────────────────────
  Widget _buildStokSecici() {
    return Row(children: [
      Expanded(
          child: Container(
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: Offset(0, 4))
            ]),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final s = await showErpSelector<StokListDto>(
                    context: context,
                    title: "Stok Seç",
                    hintText: "Stok Kodu, Adı veya Barkod...",
                    items: widget.stoklar,
                    itemText: (s) => "${s.Kod ?? ''} - ${s.Ad ?? ''}",
                    getBarcodes: (s) => s.getBarkodListesi(),
                    getUnit: (s) => s.TemelolcubrAd ?? '');
                if (s != null) {
                  setState(() {
                    k.stokid = s.Id;
                    k.stok = StokDto(Id: s.Id, Kod: s.Kod, Ad: s.Ad);
                  });
                  if (s.Id != null) _loadOlcuBirimByStok(s.Id!);
                }
              },
              child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: accentPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.inventory_2_rounded,
                            color: accentPurple, size: 20)),
                    SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            k.stokid != null
                                ? "${k.stok?.Kod} - ${k.stok?.Ad}"
                                : "Ürün Seçmek İçin Dokunun",
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                color: k.stokid == null
                                    ? _scheme.onSurfaceVariant
                                    : primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis)),
                    Icon(Icons.chevron_right_rounded,
                        color: _scheme.onSurfaceVariant, size: 18),
                  ])),
            )),
      )),
      SizedBox(width: 8),
      _scanBtn(Icons.qr_code_scanner_rounded, accentPurple,
          startWithCamera: true),
      SizedBox(width: 8),
      _scanBtn(Icons.barcode_reader, _positive, startWithScanner: true),
    ]);
  }

  Widget _scanBtn(IconData icon, Color color,
          {bool startWithCamera = false, bool startWithScanner = false}) =>
      Container(
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: Offset(0, 4))
            ]),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () async {
                final s = await showErpSelector<StokListDto>(
                    context: context,
                    title: startWithScanner
                        ? "Terminal ile Stok Seç"
                        : "Barkod ile Stok Seç",
                    hintText: startWithScanner
                        ? "Barkod okutun..."
                        : "Barkod okutun veya yazın...",
                    items: widget.stoklar,
                    itemText: (s) => "${s.Kod ?? ''} - ${s.Ad ?? ''}",
                    getBarcodes: (s) => s.getBarkodListesi(),
                    getUnit: (s) => s.TemelolcubrAd ?? '',
                    startWithCamera: startWithCamera,
                    startWithScanner: startWithScanner);
                if (s != null) {
                  setState(() {
                    k.stokid = s.Id;
                    k.stok = StokDto(Id: s.Id, Kod: s.Kod, Ad: s.Ad);
                  });
                  if (s.Id != null) _loadOlcuBirimByStok(s.Id!);
                }
              },
              child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Icon(icon, color: color, size: 24)),
            )),
      );

  // ─── MİKTAR & BİRİM ─────────────────────────────────────
  Widget _buildMiktarBirimKart() {
    return Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Expanded(
          flex: 2,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Miktar",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: _scheme.onSurfaceVariant)),
            SizedBox(height: 4),
            _modernInputKutusu(
                child: Row(children: [
              _miktarBtn(Icons.remove_rounded, errorRed, () {
                double v =
                    double.tryParse(_miktarCtrl.text.replaceAll(',', '.')) ?? 0;
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
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(border: InputBorder.none),
                onChanged: (_) => _hesapla(),
              )),
              _miktarBtn(Icons.add_rounded, _positive, () {
                double v =
                    double.tryParse(_miktarCtrl.text.replaceAll(',', '.')) ?? 0;
                _miktarCtrl.text = _trFmt(v + 1, 4);
                _hesapla();
              }),
            ])),
          ])),
      SizedBox(width: 12),
      Expanded(
          child: _modernDropdownField<int>(
              "Birim",
              _olcuBirimleri.any((o) => o.Id == k.olcubrid) ? k.olcubrid : null,
              _olcuBirimleri
                  .where((o) => o.Id != null)
                  .fold<Map<int, OlcubrDto>>({}, (map, o) {
                    map.putIfAbsent(o.Id!, () => o);
                    return map;
                  })
                  .values
                  .map((o) =>
                      DropdownMenuItem(value: o.Id, child: Text(o.Ad ?? '')))
                  .toList(),
              (v) => setState(() => k.olcubrid = v))),
    ]);
  }

  Widget _miktarBtn(IconData icon, Color color, VoidCallback tap) =>
      IconButton(onPressed: tap, icon: Icon(icon, color: color, size: 22));

  // ─── FİYAT & KDV ─────────────────────────────────────────
  Widget _buildFiyatKdvKart() {
    return Column(children: [
      // Fiyat
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Birim Fiyat",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
        SizedBox(height: 4),
        _modernInputKutusu(
            child: Row(children: [
          _miktarBtn(Icons.remove_rounded, errorRed, () {
            double v =
                double.tryParse(_fiyatCtrl.text.replaceAll(',', '.')) ?? 0;
            if (v > 0) {
              _fiyatCtrl.text = NumberFormatHelper.format(v - 1, decimal: 4);
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
            keyboardType: TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixText: "₺",
              prefixStyle: TextStyle(
                  fontFamily: 'Roboto',
                  color: accentPurple,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
            onChanged: (_) => _hesapla(),
          )),
          _miktarBtn(Icons.add_rounded, _positive, () {
            double v =
                double.tryParse(_fiyatCtrl.text.replaceAll(',', '.')) ?? 0;
            _fiyatCtrl.text = NumberFormatHelper.format(v + 1, decimal: 4);
            _hesapla();
          }),
        ])),
      ]),
      SizedBox(height: 12),
      // KDV + Tevkifat
      Row(children: [
        Expanded(
            child: _modernDropdownField<int>(
                "KDV %",
                k.kdvorani?.toInt(),
                [0, 1, 10, 20]
                    .map((o) => DropdownMenuItem(value: o, child: Text("$o")))
                    .toList(), (v) {
          setState(() {
            k.kdvorani = v?.toDouble();
            _hesapla();
          });
        })),
        SizedBox(width: 12),
        Expanded(
            flex: 2,
            child: _modernDropdownFieldStr(
                "Tevkifat Oranı",
                VergiCouples.adByOran(k.tevkifatorani),
                VergiCouples.tevkifatOranlari
                    .map(
                        (e) => DropdownMenuItem(value: e.ad, child: Text(e.ad)))
                    .toList(),
                (v) => setState(() {
                      k.tevkifatorani = VergiCouples.oranByAd(v);
                      _hesapla();
                    }))),
      ]),
    ]);
  }

  // ─── BARKOD İLE ADRES ARA (ID eşleştirme) ──────────────
  void _barkodIleAdresAra(String barkod) {
    final temiz = barkod.trim().toLowerCase();
    final bulunan = _depoadresler
        .where((a) => a.id != null && a.id!.toLowerCase() == temiz)
        .firstOrNull;

    if (bulunan != null) {
      setState(() => k.depoadresid = bulunan.id);
      final label = [bulunan.kod, bulunan.ad, bulunan.bolum]
          .where((s) => s != null && s.isNotEmpty)
          .join(' - ');
      UiFeedback.showSuccess(context, "Adres: $label");
    } else {
      // ID ile bulunamadıysa kod ile de dene (fallback)
      final bulunanKod = _depoadresler
          .where((a) => a.kod != null && a.kod!.toLowerCase() == temiz)
          .firstOrNull;
      if (bulunanKod != null) {
        setState(() => k.depoadresid = bulunanKod.id);
        final label = [bulunanKod.kod, bulunanKod.ad, bulunanKod.bolum]
            .where((s) => s != null && s.isNotEmpty)
            .join(' - ');
        UiFeedback.showSuccess(context, "Adres: $label");
      } else {
        UiFeedback.showError(context, "Depo adresi bulunamadı\n\"$barkod\"");
      }
    }
  }

  Future<void> _kameraBarkodIleAdresAra() async {
    final barcode = await Navigator.push<String>(
      context,
      PermissionMaterialPageRoute(builder: (_) => BarcodeScannerSheet()),
    );
    if (barcode != null && mounted) _barkodIleAdresAra(barcode);
  }

  Future<void> _terminalBarkodIleAdresAra() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text("Depo Adres",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            hintText: "Barkod",
            prefixIcon: Icon(Icons.barcode_reader, color: accentPurple),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
        actions: [
          ErpDialogAction(
              onPressed: () => Navigator.pop(context), child: Text("İptal")),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, ctrl.text),
            style: ElevatedButton.styleFrom(
                backgroundColor: accentPurple,
                foregroundColor: _scheme.onPrimary),
            child: Text("Ara"),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted)
      _barkodIleAdresAra(result);
  }

  // ─── DEPO & PROJE ────────────────────────────────────────
  Widget _buildDepoProjeKart() {
    final seciliDepo = widget.depolar
        .firstWhere((d) => d.id == k.depoid, orElse: () => DepoDto());
    final dinamikDepo = seciliDepo.dinamikdepo == true;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Depo",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: _scheme.onSurfaceVariant)),
          SizedBox(height: 4),
          _depoSecici(
            value: k.depoid,
            items: widget.depolar,
            onChanged: (v) {
              setState(() {
                k.depoid = v?.id;
                k.depoadresid = null;
                _depoadresler = [];
              });
              if (v?.id != null) _loadDepoadresler(v!.id!);
            },
          ),
        ])),
        SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            value: widget.projeler.any((p) => p.id == k.projeid)
                ? k.projeid
                : null,
            isExpanded: true,
            icon: Icon(Icons.folder_outlined, size: 18, color: accentPurple),
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: primaryDark),
            items: widget.projeler
                .where((p) => p.id != null)
                .fold<Map<int, ProjeDto>>({}, (map, p) {
                  map.putIfAbsent(p.id!, () => p);
                  return map;
                })
                .values
                .map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text("${p.kod ?? ''} - ${p.ad ?? ''}",
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontFamily: 'Roboto', fontSize: 12))))
                .toList(),
            onChanged: (v) => setState(() => k.projeid = v),
          ))),
        ])),
      ]),
      // Dinamik depo ise adres dropdown'ı göster
      if (dinamikDepo) ...[
        SizedBox(height: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
                      strokeWidth: 1.5, color: accentPurple)),
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
                            value:
                                _depoadresler.any((a) => a.id == k.depoadresid)
                                    ? k.depoadresid
                                    : null,
                            isExpanded: true,
                            hint: Text("Adres seçiniz",
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 13,
                                    color: _scheme.onSurfaceVariant)),
                            icon: Icon(Icons.keyboard_arrow_down_rounded,
                                size: 18, color: accentPurple),
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: primaryDark),
                            items: _depoadresler
                                .where((a) => a.id != null)
                                .fold<Map<String, DepoadresDto>>({}, (map, a) {
                                  map.putIfAbsent(a.id!, () => a);
                                  return map;
                                })
                                .values
                                .map((a) => DropdownMenuItem<String>(
                                      value: a.id,
                                      child: Text(
                                        [a.kod, a.ad, a.bolum]
                                            .where((s) =>
                                                s != null && s.isNotEmpty)
                                            .join(' - '),
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            fontFamily: 'Roboto', fontSize: 12),
                                      ),
                                    ))
                                .toList(),
                            onChanged: (v) => setState(() => k.depoadresid = v),
                          )))),
            SizedBox(width: 8),
            // Kamera barkod butonu
            Container(
              decoration: BoxDecoration(
                color: _scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 6)
                ],
              ),
              child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap:
                        _depoadresler.isEmpty ? null : _kameraBarkodIleAdresAra,
                    child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.qr_code_scanner_rounded,
                            color: _depoadresler.isEmpty
                                ? _scheme.outlineVariant
                                : _positive,
                            size: 22)),
                  )),
            ),
            SizedBox(width: 8),
            // Terminal barkod butonu
            Container(
              decoration: BoxDecoration(
                color: _scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _scheme.outlineVariant),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04), blurRadius: 6)
                ],
              ),
              child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: _depoadresler.isEmpty
                        ? null
                        : _terminalBarkodIleAdresAra,
                    child: Padding(
                        padding: EdgeInsets.all(14),
                        child: Icon(Icons.barcode_reader,
                            color: _depoadresler.isEmpty
                                ? _scheme.outlineVariant
                                : accentPurple,
                            size: 22)),
                  )),
            ),
          ]),
        ]),
      ],
    ]);
  }

  // ─── ÖZELLİK ─────────────────────────────────────────────
  Widget _buildOzellikDropdown() {
    final safeVal =
        _stokozellikler.any((e) => e.stokozelliksabitid == k.stokozelliksabitid)
            ? k.stokozelliksabitid
            : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
        value: safeVal,
        isExpanded: true,
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            size: 20, color: accentPurple),
        style: TextStyle(
            fontFamily: 'Roboto',
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: primaryDark),
        items: _stokozellikler
            .map((e) => DropdownMenuItem<int>(
                value: e.stokozelliksabitid,
                child: Text(e.displayAd, overflow: TextOverflow.ellipsis)))
            .toList(),
        onChanged: (v) => setState(() => k.stokozelliksabitid = v),
      ))),
    ]);
  }

  // ─── AÇIKLAMA ────────────────────────────────────────────
  Widget _buildAciklamaAlani() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _scheme.outlineVariant)),
        child: TextField(
          controller: _aciklamaCtrl,
          maxLines: 3,
          minLines: 1,
          onChanged: (v) => k.aciklama = v.isEmpty ? null : v,
          style:
              TextStyle(fontFamily: 'Roboto', fontSize: 14, color: primaryDark),
          decoration: InputDecoration(
              hintText: "Kalem açıklaması (opsiyonel)...",
              hintStyle: TextStyle(
                  fontFamily: 'Roboto',
                  color: _scheme.onSurfaceVariant,
                  fontSize: 13),
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none),
        ),
      ),
    ]);
  }

  // ─── ÖZET KARTI ──────────────────────────────────────────
  Widget _buildToplamOzetKarti() {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
              color: Colors.purple.withOpacity(0.3),
              blurRadius: 15,
              offset: Offset(0, 8))
        ],
      ),
      child: Column(children: [
        _ozetSatir("Ara Toplam", (k.miktar ?? 0) * (k.fiyat ?? 0)),
        if ((k.malfazlasiiskonto ?? 0) > 0)
          _ozetSatir("Mal Fazlası (${(k.malfazlasiiskonto ?? 0).toInt()} Br.)",
              k.malfazlasitutar ?? 0,
              isNeg: true),
        if ((k.iskontotutar ?? 0) > 0)
          _ozetSatir("İskonto", k.iskontotutar ?? 0, isNeg: true),
        if ((k.iskontotutar ?? 0) > 0 || (k.malfazlasiiskonto ?? 0) > 0) ...[
          Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: _scheme.onSurfaceVariant)),
          _ozetSatir("İskonto Sonrası", k.bruttutar ?? 0, isVurgu: true),
          Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: _scheme.onSurfaceVariant)),
        ],
        _ozetSatir("KDV %${(k.kdvorani ?? 0).toInt()}", k.kdvtutar ?? 0),
        if ((k.tevkifatorani ?? 0) > 0)
          _ozetSatir("Tevkifat ${VergiCouples.adByOran(k.tevkifatorani)}",
              k.tevkifattutar ?? 0,
              isNeg: true),
        Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: _scheme.onSurfaceVariant, thickness: 1)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("NET TOPLAM",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
          Text("${NumberFormatHelper.format(k.tutar ?? 0)} ₺",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  color: _scheme.onSurface,
                  fontSize: 24,
                  fontWeight: FontWeight.w900)),
        ]),
      ]),
    );
  }

  Widget _ozetSatir(String label, double val,
          {bool isNeg = false, bool isVurgu = false}) =>
      Padding(
          padding: EdgeInsets.symmetric(vertical: 2),
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: _scheme.onSurfaceVariant,
                    fontSize: 13,
                    fontWeight: isVurgu ? FontWeight.w700 : FontWeight.normal)),
            Text("${isNeg ? '-' : ''}${NumberFormatHelper.format(val)} ₺",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: _scheme.onSurface,
                    fontWeight: isVurgu ? FontWeight.w800 : FontWeight.w600,
                    fontSize: 13)),
          ]));

  // ─── AKSİYON BUTONLARI ───────────────────────────────────
  Widget _buildAksiyonButonlari() {
    return Row(children: [
      // İskonto butonu
      Expanded(
          flex: 2,
          child: OutlinedButton.icon(
            onPressed: () async {
              final brutAra = (k.miktar ?? 0) * (k.fiyat ?? 0);
              final res = await showIrsaliyeKalemIskontoSheet(context,
                  kalem: k, brutAra: brutAra, kdvDahil: widget.kdvDahil);
              if (res != null)
                setState(() {
                  k = res;
                  _hesapla();
                });
            },
            style: OutlinedButton.styleFrom(
              foregroundColor: warnOrange,
              side: BorderSide(color: warnOrange),
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            icon: Icon(Icons.percent_rounded, size: 16),
            label: Text(
                (k.iskontotutar ?? 0) > 0
                    ? "-${NumberFormatHelper.format(k.iskontotutar ?? 0)} ₺"
                    : "İskonto",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          )),
      SizedBox(width: 12),
      // Ekle / Güncelle butonu
      Expanded(
          flex: 3,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentPurple,
              foregroundColor: _scheme.onPrimary,
              padding: EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (k.stokid == null) {
                UiFeedback.showWarning(context, "Lütfen stok seçiniz!");
                return;
              }
              if ((k.miktar ?? 0) <= 0) {
                UiFeedback.showWarning(context, "Miktar giriniz!");
                return;
              }
              k.aciklama =
                  _aciklamaCtrl.text.isEmpty ? null : _aciklamaCtrl.text;
              k.olcubrcarpim =
                  k.stok?.multiplierFor(k.olcubrid) ?? k.olcubrcarpim;
              Navigator.pop(context, k);
            },
            child: Text(widget.kalem != null ? "GÜNCELLE" : "EKLE",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          )),
    ]);
  }

  // ─── YARDIMCI ────────────────────────────────────────────
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
        borderRadius: BorderRadius.circular(12),
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
          Icon(Icons.warehouse_rounded, size: 18, color: accentPurple),
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

  Widget _modernInputKutusu({required Widget child}) => Container(
        padding: EdgeInsets.symmetric(horizontal: 12),
        height: 54,
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _scheme.outlineVariant)),
        child: child,
      );

  Widget _modernDropdownField<T>(String label, T? value,
      List<DropdownMenuItem<T>> items, Function(T?) onChanged) {
    final safeValue = items.any((e) => e.value == value) ? value : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _scheme.onSurfaceVariant)),
      SizedBox(height: 4),
      _modernInputKutusu(
          child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
        isExpanded: true,
        value: safeValue,
        icon: Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        items: items,
        onChanged: onChanged,
      ))),
    ]);
  }

  Widget _modernDropdownFieldStr(String label, String? value,
      List<DropdownMenuItem<String>> items, Function(String?) onChanged) {
    final safeValue = items.any((e) => e.value == value)
        ? value
        : (items.isNotEmpty ? items.first.value : null);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
      ))),
    ]);
  }
}
