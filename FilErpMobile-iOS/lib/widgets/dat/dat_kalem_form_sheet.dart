import '../../helpers/warehouse_line_fields.dart';
import '../warehouse_feature_field.dart';
import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/entities/depo/dathareket_dto.dart';
import '../../models/entities/depo/depo_dto.dart';
import '../../models/entities/depo/depoadres_dto.dart';
import '../../models/entities/stok/stok_list_dto.dart';
import '../../models/entities/stok/stok_dto.dart';
import '../../models/entities/proje/proje_dto.dart';
import '../../models/entities/olcubirimi/olcubr_dto.dart';
import '../../services/depo/depo_service.dart';
import '../../services/stok/stok_service.dart';
import '../../services/helper/olcubr_service.dart';
import '../../helpers/weighted_barcode_helper.dart';
import '../../helpers/ui_feedback.dart';
import '../../helpers/hata_sesi.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../widgets/erp_selector.dart';

Future<DathareketDto?> showDatKalemForm(
  BuildContext context, {
  DathareketDto? kalem,
  required List<StokListDto> stoklar,
  required List<ProjeDto> projeler,
  required List<DepoDto> cikisDepolar,
  required List<DepoDto> girisDepolar,
  DathareketDto? baslangic, // yeni kalem için hazır (varsayılan) değerler
  bool sade =
      false, // Araç Yükleme düzeni: Stok, Miktar+Ölçü br, Çıkış/Sevk depo, Açıklama
  bool hataSesi = false, // hata olunca yüksek sesli uyarı
}) {
  return showModalBottomSheet<DathareketDto>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DatKalemSheet(
      kalem: kalem,
      stoklar: stoklar,
      projeler: projeler,
      cikisDepolar: cikisDepolar,
      girisDepolar: girisDepolar,
      baslangic: baslangic,
      sade: sade,
      hataSesi: hataSesi,
    ),
  );
}

class _DatKalemSheet extends StatefulWidget {
  final DathareketDto? kalem;
  final List<StokListDto> stoklar;
  final List<ProjeDto> projeler;
  final List<DepoDto> cikisDepolar;
  final List<DepoDto> girisDepolar;
  final DathareketDto? baslangic;
  final bool sade;
  final bool hataSesi;

  const _DatKalemSheet({
    this.kalem,
    required this.stoklar,
    required this.projeler,
    required this.cikisDepolar,
    required this.girisDepolar,
    this.baslangic,
    this.sade = false,
    this.hataSesi = false,
  });

  @override
  State<_DatKalemSheet> createState() => _DatKalemSheetState();
}

class _DatKalemSheetState extends State<_DatKalemSheet> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get primaryDark => _scheme.onSurface;
  Color get accentBlue => _scheme.primary;

  late DathareketDto _k;
  bool _stokYukleniyor = false;
  List<OlcubrDto> _olcuBirimleri = [];
  List<DepoadresDto> _cikisDepoadresler = [];
  List<DepoadresDto> _girisDepoadresler = [];
  bool _cikisAdresYukleniyor = false;
  bool _girisAdresYukleniyor = false;

  final _miktarCtrl = TextEditingController();
  final _miktar2Ctrl = TextEditingController();
  final _aciklamaCtrl = TextEditingController();

  String _trFmt(double? v, int d) =>
      v == null ? '' : v.toStringAsFixed(d).replaceAll('.', ',');
  double _parse(String v) => double.tryParse(v.replaceAll(',', '.')) ?? 0;

  /// Depo adresleri yalnızca DİNAMİK depolarda anlamlı: dinamik değilse alanlar gizlenir.
  bool get _cikisDinamik => widget.cikisDepolar
      .any((d) => d.id == _k.cikacagidepoid && d.dinamikdepo == true);
  bool get _girisDinamik => widget.girisDepolar
      .any((d) => d.id == _k.gidecegidepoid && d.dinamikdepo == true);

  void _hata(String m) {
    if (widget.hataSesi) HataSesi.cal();
    UiFeedback.showError(context, m);
  }

  void _uyari(String m) {
    if (widget.hataSesi) HataSesi.cal();
    UiFeedback.showWarning(context, m);
  }

  @override
  void initState() {
    super.initState();
    WeightedBarcodeHelper.ensureLoaded();
    _k = widget.kalem != null
        ? _copy(widget.kalem!)
        : (widget.baslangic != null
            ? _copy(widget.baslangic!)
            : DathareketDto());
    _miktarCtrl.text = widget.kalem != null ? _trFmt(_k.miktar, 4) : '';
    _miktar2Ctrl.text = widget.kalem != null ? _trFmt(_k.miktar2, 4) : '';
    _aciklamaCtrl.text = _k.aciklama ?? '';
    // Default proje
    if (_k.projeid == null && widget.projeler.isNotEmpty) {
      _k.projeid = widget.projeler.first.id;
    }
    if (_k.stokid != null) _loadOlcuBirim(_k.stokid!);
    if (_k.cikacagidepoid != null && _cikisDinamik)
      _loadCikisDepoadresler(_k.cikacagidepoid!);
    if (_k.gidecegidepoid != null && _girisDinamik)
      _loadGirisDepoadresler(_k.gidecegidepoid!);
  }

  @override
  void dispose() {
    _miktarCtrl.dispose();
    _miktar2Ctrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  DathareketDto _copy(DathareketDto s) {
    final c = DathareketDto();
    c.id = s.id;
    c.datid = s.datid;
    c.stokid = s.stokid;
    c.stokozelliksabitid = s.stokozelliksabitid;
    c.cikacagisubeid = s.cikacagisubeid;
    c.gidecegisubeid = s.gidecegisubeid;
    c.olcubrcarpim = s.olcubrcarpim;
    c.belgeturu = s.belgeturu;
    c.tarih = s.tarih;
    c.stok = s.stok;
    c.olcubrid = s.olcubrid;
    c.olcubr = s.olcubr;
    c.projeid = s.projeid;
    c.miktar = s.miktar;
    c.miktar2 = s.miktar2;
    c.cikacagidepoid = s.cikacagidepoid;
    c.cikacagidepoadresid = s.cikacagidepoadresid;
    c.gidecegidepoid = s.gidecegidepoid;
    c.gidecegidepoadresid = s.gidecegidepoadresid;
    c.aciklama = s.aciklama;
    return c;
  }

  Future<void> _loadCikisDepoadresler(int depoId) async {
    // Mevcut seçimi sakla — düzenleme modunda kaybetmemek için
    final mevcutId = _k.cikacagidepoadresid;
    setState(() {
      _cikisAdresYukleniyor = true;
      _cikisDepoadresler = [];
      _k.cikacagidepoadresid = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await DepoService()
          .getDepoadresByDepoId(prefs.getString("token_final") ?? "", depoId);
      if (mounted)
        setState(() {
          _cikisDepoadresler = list;
          _cikisAdresYukleniyor = false;
          // Yüklenen listede varsa önceki seçimi geri getir
          if (mevcutId != null && list.any((a) => a.id == mevcutId)) {
            _k.cikacagidepoadresid = mevcutId;
          }
        });
    } catch (_) {
      if (mounted) setState(() => _cikisAdresYukleniyor = false);
    }
  }

  Future<void> _loadGirisDepoadresler(int depoId) async {
    // Mevcut seçimi sakla — düzenleme modunda kaybetmemek için
    final mevcutId = _k.gidecegidepoadresid;
    setState(() {
      _girisAdresYukleniyor = true;
      _girisDepoadresler = [];
      _k.gidecegidepoadresid = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = await DepoService()
          .getDepoadresByDepoId(prefs.getString("token_final") ?? "", depoId);
      if (mounted)
        setState(() {
          _girisDepoadresler = list;
          _girisAdresYukleniyor = false;
          // Yüklenen listede varsa önceki seçimi geri getir
          if (mevcutId != null && list.any((a) => a.id == mevcutId)) {
            _k.gidecegidepoadresid = mevcutId;
          }
        });
    } catch (_) {
      if (mounted) setState(() => _girisAdresYukleniyor = false);
    }
  }

  void _barkodIleCikisAdresAra(String barkod) => _barkodIleAdresAra(barkod,
      _cikisDepoadresler, (id) => setState(() => _k.cikacagidepoadresid = id));

  void _barkodIleGirisAdresAra(String barkod) => _barkodIleAdresAra(barkod,
      _girisDepoadresler, (id) => setState(() => _k.gidecegidepoadresid = id));

  void _barkodIleAdresAra(
      String barkod, List<DepoadresDto> liste, Function(String) onBulundu) {
    final temiz = barkod.trim().toLowerCase();
    final b = liste
            .where((a) => a.id != null && a.id!.toLowerCase() == temiz)
            .firstOrNull ??
        liste
            .where((a) => a.kod != null && a.kod!.toLowerCase() == temiz)
            .firstOrNull;
    if (b != null) {
      onBulundu(b.id!);
      UiFeedback.showSuccess(
          context,
          "Adres: ${[
            b.kod,
            b.ad,
            b.bolum
          ].where((s) => s != null && s.isNotEmpty).join(' - ')}");
    } else {
      _hata("Depo adresi bulunamadı: $barkod");
    }
  }

  Future<String?> _kameraBarkod() async => Navigator.push<String>(context,
      PermissionMaterialPageRoute(builder: (_) => const BarcodeScannerSheet()));

  Future<String?> _terminalBarkod() async {
    final ctrl = TextEditingController();
    return showDialog<String>(
        context: context,
        builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: const Text("Depo Adresi",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
              content: TextField(
                  controller: ctrl,
                  autofocus: true,
                  decoration: InputDecoration(
                      hintText: "Barkod",
                      prefixIcon: const Icon(Icons.barcode_reader),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10))),
                  onSubmitted: (v) => Navigator.pop(context, v)),
              actions: [
                ErpDialogAction(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("İptal")),
                ElevatedButton(
                    onPressed: () => Navigator.pop(context, ctrl.text),
                    child: const Text("Ara")),
              ],
            ));
  }

  Future<void> _loadOlcuBirim(int stokId) async {
    setState(() => _stokYukleniyor = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final stok = await StokService().getStokById(token, stokId);
      if (!mounted || _k.stokid != stokId) return;
      setState(() {
        _k.stok = stok;
        _k.stokozelliksabitid = warehouseFeatureId(stok, _k.stokozelliksabitid);
      });
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
          if (!tekBirim.any((o) => o.Id == _k.olcubrid)) {
            _k.olcubrid = tekBirim.first.Id;
            _k.olcubr = tekBirim.first;
          }
        });
      }
    } catch (_) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString("token_final") ?? "";
        final list = await OlcubrService().getAll(token);
        if (mounted && _k.stokid == stokId)
          setState(() => _olcuBirimleri = list);
      } catch (_) {}
    } finally {
      if (mounted && _k.stokid == stokId)
        setState(() => _stokYukleniyor = false);
    }
  }

  ({StokListDto? stok, double? quantity}) _resolveStokByBarcode(String barkod) {
    final normalized = barkod.trim().toLowerCase();
    for (final stok in widget.stoklar) {
      if (stok.getBarkodListesi().any((b) => b.toLowerCase() == normalized)) {
        return (stok: stok, quantity: null);
      }
    }

    final weighted = WeightedBarcodeHelper.tryParse(barkod);
    if (weighted == null) {
      return (stok: null, quantity: null);
    }

    final weightedKey = weighted.stockBarcode.toLowerCase();
    for (final stok in widget.stoklar) {
      if (stok.getBarkodListesi().any((b) => b.toLowerCase() == weightedKey)) {
        return (stok: stok, quantity: weighted.quantity);
      }
    }

    return (stok: null, quantity: null);
  }

  Future<void> _applyScannedStok(String barkod) async {
    final result = _resolveStokByBarcode(barkod);
    final secilen = result.stok;
    if (secilen == null) {
      _uyari("Barkod bulunamadi: $barkod");
      return;
    }

    setState(() {
      if (_k.stokid != secilen.Id) _k.stokozelliksabitid = null;
      _k.stokid = secilen.Id;
      _k.stok = StokDto(Id: secilen.Id, Kod: secilen.Kod, Ad: secilen.Ad);
      if (result.quantity != null) {
        _k.miktar = result.quantity;
        _miktarCtrl.text = _trFmt(result.quantity, 4);
      }
    });

    if (secilen.Id != null) {
      await _loadOlcuBirim(secilen.Id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: BoxDecoration(
        color: _scheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom + 12),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.92,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (_, ctrl) => SingleChildScrollView(
          controller: ctrl,
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Handle
              Center(
                  child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                          color: _scheme.outlineVariant,
                          borderRadius: BorderRadius.circular(2)))),

              // Başlık
              _buildHeader(),
              const SizedBox(height: 8),

              // Stok Seçici
              _buildStokSecici(),
              WarehouseFeatureField(
                  stock: _k.stok,
                  value: _k.stokozelliksabitid,
                  onChanged: (v) => setState(() => _k.stokozelliksabitid = v)),
              const SizedBox(height: 10),

              if (_stokYukleniyor) const LinearProgressIndicator(),
              // Miktar / Miktar2 yanyana, Ölçü Birimi altlarında
              _buildMiktarKarti(),
              const SizedBox(height: 10),

              // Proje + Çıkacağı Depo + Gideceği Depo
              _buildDepoProjeKarti(),
              const SizedBox(height: 10),

              // Açıklama
              _buildAciklamaAlani(),
              const SizedBox(height: 8),

              // Butonlar
              _buildAksiyonButonlari(),
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
  }

  Widget _buildStokSecici() {
    return Row(
      children: [
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
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () async {
                  final secilen = await showErpSelector<StokListDto>(
                    context: context,
                    title: "Stok Seçim",
                    hintText: "Stok Kodu, Adı veya Barkodu...",
                    items: widget.stoklar,
                    itemText: (s) => "${s.Kod ?? ''} - ${s.Ad ?? ''}",
                    getBarcodes: (s) => s.getBarkodListesi(),
                    getUnit: (s) => s.TemelolcubrAd ?? '',
                  );
                  if (secilen != null) {
                    setState(() {
                      if (_k.stokid != secilen.Id) _k.stokozelliksabitid = null;
                      _k.stokid = secilen.Id;
                      _k.stok = StokDto(
                          Id: secilen.Id, Kod: secilen.Kod, Ad: secilen.Ad);
                    });
                    if (secilen.Id != null) _loadOlcuBirim(secilen.Id!);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: Row(children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                          color: accentBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(Icons.inventory_2_rounded,
                          color: accentBlue, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                      _k.stokid != null
                          ? "${_k.stok?.Kod} - ${_k.stok?.Ad}"
                          : "Stok",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          color: _k.stokid == null ? Colors.grey : primaryDark,
                          fontWeight: FontWeight.w700,
                          fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    )),
                    Icon(Icons.chevron_right_rounded,
                        color: _scheme.onSurfaceVariant, size: 18),
                  ]),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Barkod butonu (kamera)
        Container(
          decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final barkod = await _kameraBarkod();
                if (barkod != null && mounted) {
                  await _applyScannedStok(barkod);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Icon(Icons.qr_code_scanner_rounded,
                    color: accentBlue, size: 24),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Terminal barkod butonu
        Container(
          decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () async {
                final barkod = await _terminalBarkod();
                if (barkod != null && mounted) {
                  await _applyScannedStok(barkod);
                }
              },
              child: Padding(
                padding: const EdgeInsets.all(11),
                child: Icon(Icons.barcode_reader,
                    color: Colors.green.shade600, size: 24),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiktarKarti() {
    if (widget.sade) return _buildMiktarKartiSade();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        // Miktar + Miktar2 yanyana
        Row(children: [
          Expanded(
              child: _miktarAlani("Miktar", _miktarCtrl,
                  (v) => setState(() => _k.miktar = _parse(v)))),
          const SizedBox(width: 12),
          Expanded(
              child: _miktarAlani("Miktar 2", _miktar2Ctrl,
                  (v) => setState(() => _k.miktar2 = _parse(v)))),
        ]),
        const SizedBox(height: 8),

        _modernDropdown<int>(
          "Ölçü Birimi",
          _olcuBirimleri.any((o) => o.Id == _k.olcubrid) ? _k.olcubrid : null,
          _olcuBirimleri
              .map((o) => DropdownMenuItem(
                    value: o.Id,
                    child: Text(o.Ad ?? '',
                        style: const TextStyle(
                            fontFamily: 'Roboto', fontSize: 13)),
                  ))
              .toList(),
          (v) => setState(() {
            _k.olcubrid = v;
            _k.olcubr = _olcuBirimleri.where((o) => o.Id == v).firstOrNull;
          }),
        ),
      ]),
    );
  }

  /// Araç Yükleme düzeni: Miktar ve Ölçü birimi aynı satırda (Miktar 2 yok).
  Widget _buildMiktarKartiSade() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Expanded(
            flex: 5,
            child: _miktarAlani("Miktar", _miktarCtrl,
                (v) => setState(() => _k.miktar = _parse(v)))),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: _modernDropdown<int>(
            "Ölçü Br",
            _olcuBirimleri.any((o) => o.Id == _k.olcubrid) ? _k.olcubrid : null,
            _olcuBirimleri
                .map((o) => DropdownMenuItem(
                      value: o.Id,
                      child: Text(o.Ad ?? '',
                          style: const TextStyle(
                              fontFamily: 'Roboto', fontSize: 13)),
                    ))
                .toList(),
            (v) => setState(() {
              _k.olcubrid = v;
              _k.olcubr = _olcuBirimleri.where((o) => o.Id == v).firstOrNull;
            }),
          ),
        ),
      ]),
    );
  }

  Widget _miktarAlani(
      String label, TextEditingController ctrl, Function(String) onChange) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _scheme.onSurfaceVariant)),
      const SizedBox(height: 4),
      Row(children: [
        GestureDetector(
          onTap: () {
            final v = _parse(ctrl.text);
            if (v > 0) {
              ctrl.text = (v - 1).toStringAsFixed(4).replaceAll('.', ',');
              onChange(ctrl.text);
              setState(() {});
            }
          },
          child: Container(
              width: 36,
              height: 48,
              decoration: BoxDecoration(
                color: _scheme.surfaceContainerLow,
                borderRadius:
                    const BorderRadius.horizontal(left: Radius.circular(12)),
                border: Border.all(color: _scheme.outlineVariant),
              ),
              child: const Icon(Icons.remove, size: 16, color: Colors.grey)),
        ),
        Expanded(
            child: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          style: const TextStyle(
              fontFamily: 'Roboto', fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            border: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: _scheme.outlineVariant)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: _scheme.outlineVariant)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.zero,
                borderSide: BorderSide(color: accentBlue)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
          onChanged: (v) {
            onChange(v);
            setState(() {});
          },
        )),
        GestureDetector(
          onTap: () {
            final v = _parse(ctrl.text);
            ctrl.text = (v + 1).toStringAsFixed(4).replaceAll('.', ',');
            onChange(ctrl.text);
            setState(() {});
          },
          child: Container(
              width: 36,
              height: 48,
              decoration: BoxDecoration(
                color: _scheme.surfaceContainerLow,
                borderRadius:
                    const BorderRadius.horizontal(right: Radius.circular(12)),
                border: Border.all(color: _scheme.outlineVariant),
              ),
              child: const Icon(Icons.add, size: 16, color: Colors.grey)),
        ),
      ]),
    ]);
  }

  Widget _buildDepoProjeKarti() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(children: [
        // Proje tam genişlik
        if (!widget.sade) ...[
          _modernDropdown<int>(
            "Proje",
            widget.projeler.any((p) => p.id == _k.projeid) ? _k.projeid : null,
            widget.projeler
                .map((p) => DropdownMenuItem(
                      value: p.id,
                      child: Text("${p.kod ?? ''} - ${p.ad ?? ''}",
                          style: const TextStyle(
                              fontFamily: 'Roboto', fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            (v) => setState(() => _k.projeid = v),
          ),
          const SizedBox(height: 8),
        ],
        // Çıkacağı + Gideceği Depo yanyana
        Row(children: [
          Expanded(
              child: _modernDepoSecici(
            widget.sade ? "Çıkış Deposu" : "Çıkacağı Depo",
            _k.cikacagidepoid,
            widget.cikisDepolar,
            (v) {
              setState(() {
                _k.cikacagidepoid = v?.id;
                _k.cikacagidepoadresid = null;
                _cikisDepoadresler = [];
              });
              if (v?.id != null && v!.dinamikdepo == true)
                _loadCikisDepoadresler(v.id!);
            },
          )),
          const SizedBox(width: 12),
          Expanded(
              child: _modernDepoSecici(
            widget.sade ? "Sevk Deposu" : "Gideceği Depo",
            _k.gidecegidepoid,
            widget.girisDepolar,
            (v) {
              setState(() {
                _k.gidecegidepoid = v?.id;
                _k.gidecegidepoadresid = null;
                _girisDepoadresler = [];
              });
              if (v?.id != null && v!.dinamikdepo == true)
                _loadGirisDepoadresler(v.id!);
            },
          )),
        ]),

        if (_cikisDinamik) const SizedBox(height: 8),
        if (_cikisDinamik)
          _buildDepoadresRow(
            label: "Çıkacağı Depo Adresi",
            yukleniyor: _cikisAdresYukleniyor,
            adresler: _cikisDepoadresler,
            seciliId: _k.cikacagidepoadresid,
            onChanged: (v) => setState(() => _k.cikacagidepoadresid = v),
            onKameraBarkod: () async {
              final b = await _kameraBarkod();
              if (b != null && mounted) _barkodIleCikisAdresAra(b);
            },
            onTerminalBarkod: () async {
              final b = await _terminalBarkod();
              if (b != null && mounted) _barkodIleCikisAdresAra(b);
            },
          ),

        if (_girisDinamik) const SizedBox(height: 8),
        if (_girisDinamik)
          _buildDepoadresRow(
            label: "Gideceği Depo Adresi",
            yukleniyor: _girisAdresYukleniyor,
            adresler: _girisDepoadresler,
            seciliId: _k.gidecegidepoadresid,
            onChanged: (v) => setState(() => _k.gidecegidepoadresid = v),
            onKameraBarkod: () async {
              final b = await _kameraBarkod();
              if (b != null && mounted) _barkodIleGirisAdresAra(b);
            },
            onTerminalBarkod: () async {
              final b = await _terminalBarkod();
              if (b != null && mounted) _barkodIleGirisAdresAra(b);
            },
          ),
      ]),
    );
  }

  Widget _buildDepoadresRow({
    required String label,
    required bool yukleniyor,
    required List<DepoadresDto> adresler,
    required String? seciliId,
    required ValueChanged<String?> onChanged,
    required VoidCallback onKameraBarkod,
    required VoidCallback onTerminalBarkod,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.location_on_outlined,
            size: 12, color: _scheme.onSurfaceVariant),
        const SizedBox(width: 4),
        Text(label,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
        if (yukleniyor) ...[
          const SizedBox(width: 8),
          SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                  strokeWidth: 1.5, color: accentBlue)),
        ],
      ]),
      const SizedBox(height: 4),
      Row(children: [
        Expanded(
            child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: _scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _scheme.outlineVariant),
          ),
          child: yukleniyor
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text("Yükleniyor...",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: Colors.grey)))
              : DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                  isExpanded: true,
                  value:
                      adresler.any((a) => a.id == seciliId) ? seciliId : null,
                  hint: Text("Adres seçiniz...",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          color: _scheme.onSurfaceVariant)),
                  icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                  items: adresler
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
                                  .where((s) => s != null && s.isNotEmpty)
                                  .join(' - '),
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontFamily: 'Roboto', fontSize: 12),
                            ),
                          ))
                      .toList(),
                  onChanged: adresler.isEmpty ? null : onChanged,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: _scheme.onSurface),
                )),
        )),
        const SizedBox(width: 8),
        // Kamera barkod butonu
        Container(
          decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _scheme.outlineVariant),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
            ],
          ),
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: adresler.isEmpty ? null : onKameraBarkod,
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.qr_code_scanner_rounded,
                        color: adresler.isEmpty
                            ? _scheme.outlineVariant
                            : Colors.green.shade600,
                        size: 20)),
              )),
        ),
        const SizedBox(width: 8),
        // Terminal barkod butonu
        Container(
          decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _scheme.outlineVariant),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)
            ],
          ),
          child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(14),
                onTap: adresler.isEmpty ? null : onTerminalBarkod,
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(Icons.barcode_reader,
                        color: adresler.isEmpty
                            ? _scheme.outlineVariant
                            : accentBlue,
                        size: 20)),
              )),
        ),
      ]),
    ]);
  }

  Widget _buildAciklamaAlani() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("Açıklama",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: _scheme.onSurfaceVariant)),
        const SizedBox(height: 6),
        TextField(
          controller: _aciklamaCtrl,
          maxLines: 2,
          style: const TextStyle(fontFamily: 'Roboto', fontSize: 13),
          onChanged: (v) => _k.aciklama = v.isEmpty ? null : v,
          decoration: InputDecoration(
            border: InputBorder.none,
            hintText: "Açıklama",
            hintStyle: TextStyle(
                fontFamily: 'Roboto',
                color: _scheme.onSurfaceVariant,
                fontSize: 13),
          ),
        ),
      ]),
    );
  }

  Widget _buildAksiyonButonlari() {
    return Row(children: [
      Expanded(
          flex: 2,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: _scheme.onSurface,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("İptal",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w800,
                    fontSize: 14)),
          )),
      const SizedBox(width: 12),
      Expanded(
          flex: 3,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: accentBlue,
              foregroundColor: _scheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 13),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: () {
              if (_stokYukleniyor) {
                _uyari('Stok bilgileri yükleniyor.');
                return;
              }
              if (_k.stok?.Stokozelligesahip == true &&
                  _k.stokozelliksabitid == null) {
                _uyari('Stok özelliği seçiniz.');
                return;
              }
              if (_k.stokid == null) {
                _uyari("Lütfen stok seçiniz!");
                return;
              }
              if ((_k.miktar ?? 0) <= 0) {
                _uyari("Miktar giriniz!");
                return;
              }
              if (_k.cikacagidepoid != null &&
                  _k.gidecegidepoid != null &&
                  _k.cikacagidepoid == _k.gidecegidepoid) {
                _uyari("Çıkacağı ve gideceği depo aynı olamaz!");
                return;
              }
              _k.aciklama =
                  _aciklamaCtrl.text.isEmpty ? null : _aciklamaCtrl.text;
              Navigator.pop(context, _k);
            },
            child: Text(
              widget.kalem != null ? "Güncelle" : "Ekle",
              style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w900,
                  fontSize: 16),
            ),
          )),
    ]);
  }

  // â”€â”€â”€ YARDIMCI: Modern Dropdown â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  /// Depo seçimi — rehber tarzı, tam ekran, kod/ad ile aranabilir seçici.
  Widget _modernDepoSecici(String label, int? value, List<DepoDto> items,
      ValueChanged<DepoDto?> onChanged) {
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

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _scheme.onSurfaceVariant)),
      const SizedBox(height: 4),
      Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () async {
            final secilen = await showErpSelector<DepoDto>(
              context: context,
              title: label,
              hintText: "Depo Kodu veya Adı...",
              items: items,
              itemText: (d) => "${d.kod ?? ''} - ${d.ad ?? ''}",
            );
            if (secilen != null) onChanged(secilen);
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: _scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _scheme.outlineVariant),
            ),
            child: Row(children: [
              Expanded(
                  child: Text(
                text ?? "Seçiniz",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: text != null
                        ? _scheme.onSurface
                        : _scheme.onSurfaceVariant),
                overflow: TextOverflow.ellipsis,
              )),
              Icon(Icons.search_rounded,
                  size: 18, color: _scheme.onSurfaceVariant),
            ]),
          ),
        ),
      ),
    ]);
  }

  Widget _modernDropdown<T>(String label, T? value,
      List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged) {
    final safeValue = items.any((e) => e.value == value) ? value : null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: _scheme.onSurfaceVariant)),
      const SizedBox(height: 4),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: _scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _scheme.outlineVariant),
        ),
        child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
          isExpanded: true,
          value: safeValue,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          items: items,
          onChanged: onChanged,
          style: TextStyle(
              fontFamily: 'Roboto', fontSize: 13, color: _scheme.onSurface),
        )),
      ),
    ]);
  }
}
