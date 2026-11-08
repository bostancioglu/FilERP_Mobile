import '../document_line_extras.dart';
import '../../services/siparis/order_link_service.dart';
import '../../models/entities/siparis/siparis_dto.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/vergi_couples.dart';
import '../../helpers/number_format_helper.dart';
import '../../helpers/ui_feedback.dart';
import '../../helpers/varsayilan_depo_helper.dart';
import '../../helpers/varsayilan_proje_helper.dart';
import '../../helpers/fatura_hesap_helper.dart';
import '../../models/entities/siparis/siparishareket_dto.dart';
import '../../models/entities/stok/stok_list_dto.dart';
import '../../models/entities/stok/stok_dto.dart';
import '../../models/entities/stok/stokozellik_dto.dart';
import '../../models/entities/depo/depo_dto.dart';
import '../../models/entities/proje/proje_dto.dart';
import '../../models/entities/olcubirimi/olcubr_dto.dart';
import '../../services/stok/stok_service.dart';
import '../../services/helper/olcubr_service.dart';
import '../../widgets/erp_selector.dart';
import 'siparis_kalem_iskonto_sheet.dart';

Future<SiparishareketDto?> showSiparisKalemForm(
  BuildContext context, {
  SiparishareketDto? kalem,
  String? actionLabel,
  bool orderFields = false,
  OrderLinkContext? linkContext,
  required List<StokListDto> stoklar,
  required List<ProjeDto> projeler,
  required List<DepoDto> depolar,
  required bool kdvDahil,
}) {
  return showDialog<SiparishareketDto>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: _SiparisKalemForm(
          kalem: kalem,
          actionLabel: actionLabel,
          orderFields: orderFields,
          linkContext: linkContext,
          stoklar: stoklar,
          projeler: projeler,
          depolar: depolar,
          kdvDahil: kdvDahil),
    ),
  );
}

class _SiparisKalemForm extends StatefulWidget {
  final SiparishareketDto? kalem;
  final String? actionLabel;
  final bool orderFields;
  final OrderLinkContext? linkContext;
  final List<StokListDto> stoklar;
  final List<ProjeDto> projeler;
  final List<DepoDto> depolar;
  final bool kdvDahil;

  const _SiparisKalemForm({
    this.kalem,
    this.actionLabel,
    this.orderFields = false,
    this.linkContext,
    required this.stoklar,
    required this.projeler,
    required this.depolar,
    required this.kdvDahil,
  });

  @override
  State<_SiparisKalemForm> createState() => _SiparisKalemFormState();
}

class _SiparisKalemFormState extends State<_SiparisKalemForm> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get primaryDark => _scheme.onSurface;
  Color get accentPurple => _scheme.primary;
  Color get errorRed => _scheme.error;
  Color get warnOrange => _scheme.primary;

  late SiparishareketDto k;
  final _miktarCtrl = TextEditingController();
  final _fiyatCtrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();
  final _costCtrl = TextEditingController();

  List<OlcubrDto> _olcuBirimleri = [];
  List<StokozellikDto> _stokozellikler = [];

  String _trFmt(double v, int d) => v.toStringAsFixed(d).replaceAll('.', ',');

  @override
  void initState() {
    super.initState();
    k = widget.kalem != null ? _copy(widget.kalem!) : SiparishareketDto();
    _costCtrl.text = k.ekmaliyet == null
        ? ''
        : NumberFormatHelper.format(k.ekmaliyet!, decimal: 4);
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
  }

  @override
  void dispose() {
    _miktarCtrl.dispose();
    _fiyatCtrl.dispose();
    _aciklamaCtrl.dispose();
    _costCtrl.dispose();
    super.dispose();
  }

  SiparishareketDto _copy(SiparishareketDto s) => s.copy();

  Widget _buildOrderLink() => Column(children: [
        SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Bağlantı Kullan'),
            value: k.baglantikullan ?? false,
            onChanged: (enabled) async {
              if (!enabled) {
                setState(() {
                  k.baglantikullan = false;
                  k.baglantisiparishareketid = null;
                  k.baglantisiparishareket = null;
                });
                return;
              }
              await _pickOrderLink();
            }),
        if (k.baglantikullan == true)
          OutlinedButton.icon(
              onPressed: _pickOrderLink,
              icon: const Icon(Icons.link_rounded, size: 16),
              label: Text(
                  k.baglantisiparishareket?.stok?.Ad ??
                      'Bağlantı Kalemini Değiştir',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis)),
      ]);

  Future<void> _pickOrderLink() async {
    if (k.stokid == null) {
      UiFeedback.showWarning(context, 'Önce stok seçiniz.');
      return;
    }
    final stockId = k.stokid!;
    final linkContext = widget.linkContext!;
    try {
      final token =
          (await SharedPreferences.getInstance()).getString('token_final') ??
              '';
      final service = OrderLinkService();
      final orders = await service.orders(token, linkContext);
      if (!mounted) return;
      final order = await showErpSelector<SiparisDto>(
          context: context,
          title: 'Bağlantı Siparişi',
          hintText: 'Belge No',
          items: orders,
          itemText: (o) => o.belgeserino ?? 'Sipariş ${o.id}');
      if (order?.id == null || !mounted) return;
      final rows = await service.lines(token, order!.id!, stockId);
      if (!mounted) return;
      final row = await showErpSelector<SiparishareketDto>(
          context: context,
          title: 'Bağlantı Kalemi',
          hintText: 'Stok',
          items: rows,
          itemText: (o) =>
              '${o.stok?.Ad ?? 'Stok #${o.stokid}'} · ${NumberFormatHelper.format(o.miktar ?? 0)} ${o.olcubr?.Kod ?? ''}');
      if (row == null || !mounted || k.stokid != stockId) return;
      setState(() {
        k.baglantikullan = true;
        k.baglantisiparishareketid = int.tryParse(row.id ?? '');
        k.baglantisiparishareket = row;
        k.olcubrid = row.olcubrid;
        k.olcubr = row.olcubr;
        k.olcubrcarpim = row.olcubrcarpim;
        k.miktar = row.miktar;
        k.fiyat = linkContext.currencyId != 1
            ? (row.dovizfiyat ?? (row.fiyat ?? 0) / linkContext.rate)
            : row.fiyat;
        _miktarCtrl.text = NumberFormatHelper.format(k.miktar ?? 0, decimal: 4);
        _fiyatCtrl.text = NumberFormatHelper.format(k.fiyat ?? 0, decimal: 4);
      });
      _hesapla();
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
  }

  Future<void> _loadOlcuBirimByStok(int stokId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    try {
      final stok = await StokService().getStokById(token, stokId);
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
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          _buildHeader(),
          const SizedBox(height: 12),
          _buildStokSecici(),
          const SizedBox(height: 12),
          _buildMiktarBirimKart(),
          const SizedBox(height: 12),
          _buildFiyatKdvKart(),
          const SizedBox(height: 12),
          _buildDepoProjeKart(),
          if (widget.linkContext != null) _buildOrderLink(),
          if (_stokozellikler.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildOzellikDropdown(),
          ],
          const SizedBox(height: 12),
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
              onStockDescription: (v) => k.stokadiaciklama = v),
          if (widget.orderFields)
            Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                    key: const ValueKey('orderLineExtraCost'),
                    controller: _costCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Ek Maliyet'),
                    onChanged: (v) => k.ekmaliyet =
                        v.trim().isEmpty ? null : NumberFormatHelper.parse(v))),
          _buildAciklamaAlani(),
          const SizedBox(height: 12),
          _buildToplamOzetKarti(),
          const SizedBox(height: 12),
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
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: primaryDark)),
          IconButton(
            onPressed: () => Navigator.pop(context),
            tooltip: 'Kapat',
            icon: CircleAvatar(
                backgroundColor: _scheme.outlineVariant,
                radius: 15,
                child: Icon(Icons.close_rounded,
                    size: 18, color: _scheme.onSurface)),
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
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
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
                    if (k.stokid != s.Id) {
                      k.baglantikullan = false;
                      k.baglantisiparishareketid = null;
                      k.baglantisiparishareket = null;
                    }
                    k.stokid = s.Id;
                    k.stok = StokDto(Id: s.Id, Kod: s.Kod, Ad: s.Ad);
                  });
                  if (s.Id != null) _loadOlcuBirimByStok(s.Id!);
                }
              },
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: accentPurple.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.inventory_2_rounded,
                            color: accentPurple, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            k.stokid != null
                                ? "${k.stok?.Kod} - ${k.stok?.Ad}"
                                : "Stok",
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                color: k.stokid == null
                                    ? Colors.grey
                                    : primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis)),
                    Icon(Icons.chevron_right_rounded,
                        color: _scheme.onSurfaceVariant, size: 18),
                  ])),
            )),
      )),
      const SizedBox(width: 8),
      _scanBtn(Icons.qr_code_scanner_rounded, accentPurple,
          startWithCamera: true),
      const SizedBox(width: 8),
      _scanBtn(Icons.barcode_reader, Colors.green.shade600,
          startWithScanner: true),
    ]);
  }

  Widget _scanBtn(IconData icon, Color color,
          {bool startWithCamera = false, bool startWithScanner = false}) =>
      Container(
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ]),
        child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final s = await showErpSelector<StokListDto>(
                    context: context,
                    title: startWithScanner
                        ? "Terminal ile Stok Seç"
                        : "Barkod ile Stok Seç",
                    hintText: "Barkod",
                    items: widget.stoklar,
                    itemText: (s) => "${s.Kod ?? ''} - ${s.Ad ?? ''}",
                    getBarcodes: (s) => s.getBarkodListesi(),
                    getUnit: (s) => s.TemelolcubrAd ?? '',
                    startWithCamera: startWithCamera,
                    startWithScanner: startWithScanner);
                if (s != null) {
                  setState(() {
                    if (k.stokid != s.Id) {
                      k.baglantikullan = false;
                      k.baglantisiparishareketid = null;
                      k.baglantisiparishareket = null;
                    }
                    k.stokid = s.Id;
                    k.stok = StokDto(Id: s.Id, Kod: s.Kod, Ad: s.Ad);
                  });
                  if (s.Id != null) _loadOlcuBirimByStok(s.Id!);
                }
              },
              child: Padding(
                  padding: const EdgeInsets.all(14),
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
            const SizedBox(height: 4),
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
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(border: InputBorder.none),
                onChanged: (_) => _hesapla(),
              )),
              _miktarBtn(Icons.add_rounded, Colors.green.shade600, () {
                double v =
                    double.tryParse(_miktarCtrl.text.replaceAll(',', '.')) ?? 0;
                _miktarCtrl.text = _trFmt(v + 1, 4);
                _hesapla();
              }),
            ])),
          ])),
      const SizedBox(width: 12),
      Expanded(
          child: _modernDropdownField<int>(
              "Birim",
              _olcuBirimleri.any((o) => o.Id == k.olcubrid) ? k.olcubrid : null,
              _olcuBirimleri
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
        const SizedBox(height: 4),
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
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
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
          _miktarBtn(Icons.add_rounded, Colors.green.shade600, () {
            double v =
                double.tryParse(_fiyatCtrl.text.replaceAll(',', '.')) ?? 0;
            _fiyatCtrl.text = NumberFormatHelper.format(v + 1, decimal: 4);
            _hesapla();
          }),
        ])),
      ]),
      const SizedBox(height: 12),
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
        const SizedBox(width: 12),
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

  // ─── DEPO & PROJE ────────────────────────────────────────
  Widget _buildDepoProjeKart() {
    return Row(children: [
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Depo",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        _depoSecici(
          value: k.depoid,
          items: widget.depolar,
          onChanged: (v) => setState(() => k.depoid = v?.id),
        ),
      ])),
      const SizedBox(width: 12),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Proje",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        _modernInputKutusu(
            child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
          value:
              widget.projeler.any((p) => p.id == k.projeid) ? k.projeid : null,
          isExpanded: true,
          icon: Icon(Icons.folder_outlined, size: 18, color: accentPurple),
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: primaryDark),
          items: widget.projeler
              .map((p) => DropdownMenuItem(
                  value: p.id,
                  child: Text("${p.kod ?? ''} - ${p.ad ?? ''}",
                      overflow: TextOverflow.ellipsis,
                      style:
                          const TextStyle(fontFamily: 'Roboto', fontSize: 12))))
              .toList(),
          onChanged: (v) => setState(() => k.projeid = v),
        ))),
      ])),
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
        const SizedBox(width: 4),
        Text("Stok Özelliği",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: 4),
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
        const SizedBox(width: 4),
        Text("Açıklama",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
      ]),
      const SizedBox(height: 4),
      Container(
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _scheme.outlineVariant)),
        child: TextField(
          controller: _aciklamaCtrl,
          maxLines: 3,
          minLines: 1,
          onChanged: (v) => k.aciklama = v.isEmpty ? null : v,
          style:
              TextStyle(fontFamily: 'Roboto', fontSize: 14, color: primaryDark),
          decoration: InputDecoration(
              hintText: "Açıklama",
              hintStyle: TextStyle(
                  fontFamily: 'Roboto',
                  color: _scheme.onSurfaceVariant,
                  fontSize: 13),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: InputBorder.none),
        ),
      ),
    ]);
  }

  // ─── ÖZET KARTI ──────────────────────────────────────────
  Widget _buildToplamOzetKarti() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [BoxShadow(color: Colors.transparent)],
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
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: _scheme.outlineVariant)),
          _ozetSatir("İskonto Sonrası", k.bruttutar ?? 0, isVurgu: true),
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: _scheme.outlineVariant)),
        ],
        _ozetSatir("KDV %${(k.kdvorani ?? 0).toInt()}", k.kdvtutar ?? 0),
        if ((k.tevkifatorani ?? 0) > 0)
          _ozetSatir("Tevkifat ${VergiCouples.adByOran(k.tevkifatorani)}",
              k.tevkifattutar ?? 0,
              isNeg: true),
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: _scheme.outlineVariant, thickness: 1)),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text("Net Toplam",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1)),
          Text("${NumberFormatHelper.format(k.tutar ?? 0)} ₺",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  color: _scheme.onSurface,
                  fontSize: 20,
                  fontWeight: FontWeight.w900)),
        ]),
      ]),
    );
  }

  Widget _ozetSatir(String label, double val,
          {bool isNeg = false, bool isVurgu = false}) =>
      Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
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
              final res = await showSiparisKalemIskontoSheet(context,
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
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            icon: const Icon(Icons.percent_rounded, size: 16),
            label: Text(
                (k.iskontotutar ?? 0) > 0
                    ? "-${NumberFormatHelper.format(k.iskontotutar ?? 0)} ₺"
                    : "İskonto",
                style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          )),
      const SizedBox(width: 12),
      // Ekle / Güncelle butonu
      Expanded(
          flex: 3,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentPurple,
              foregroundColor: _scheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
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
              if (widget.orderFields)
                k.ekmaliyet = _costCtrl.text.trim().isEmpty
                    ? null
                    : NumberFormatHelper.parse(_costCtrl.text);
              Navigator.pop(context, k);
            },
            child: Text(
                widget.actionLabel ??
                    (widget.kalem != null ? "Güncelle" : "Ekle"),
                style: const TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w900,
                    fontSize: 16)),
          )),
    ]);
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
          Icon(Icons.warehouse_rounded, size: 18, color: accentPurple),
          const SizedBox(width: 8),
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

  // ─── YARDIMCI ────────────────────────────────────────────
  Widget _modernInputKutusu({required Widget child}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        height: 54,
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(16),
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
      const SizedBox(height: 4),
      _modernInputKutusu(
          child: DropdownButtonHideUnderline(
              child: DropdownButton<T>(
        isExpanded: true,
        value: safeValue,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
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
      const SizedBox(height: 4),
      _modernInputKutusu(
          child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
        isExpanded: true,
        value: safeValue,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
        items: items,
        onChanged: onChanged,
      ))),
    ]);
  }
}
