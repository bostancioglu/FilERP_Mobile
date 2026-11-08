import '../../helpers/warehouse_line_fields.dart';
import '../warehouse_feature_field.dart';
import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/number_format_helper.dart';
import '../../helpers/ui_feedback.dart';
import '../../helpers/varsayilan_depo_helper.dart';
import '../../helpers/varsayilan_proje_helper.dart';
import '../../models/entities/depo/ambargchareket_dto.dart';
import '../../models/entities/depo/depoadres_dto.dart';
import '../../models/entities/stok/stok_list_dto.dart';
import '../../models/entities/stok/stok_dto.dart';
import '../../models/entities/depo/depo_dto.dart';
import '../../models/entities/proje/proje_dto.dart';
import '../../models/entities/olcubirimi/olcubr_dto.dart';
import '../../services/depo/depo_service.dart';
import '../../services/stok/stok_service.dart';
import '../../widgets/barcode_scanner_sheet.dart';
import '../../widgets/erp_selector.dart';

Future<AmbargchareketDto?> showAmbargcKalemForm(
  BuildContext context, {
  AmbargchareketDto? kalem,
  required List<StokListDto> stoklar,
  required List<ProjeDto> projeler,
  required List<DepoDto> depolar,
  bool kdvDahil = false,
  bool dovizli = false,
  double kur = 1,
}) {
  return showDialog<AmbargchareketDto>(
    context: context,
    barrierDismissible: false,
    builder: (_) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: _AmbargcKalemForm(
          kalem: kalem,
          stoklar: stoklar,
          projeler: projeler,
          depolar: depolar,
          dovizli: dovizli,
          kur: kur),
    ),
  );
}

class _AmbargcKalemForm extends StatefulWidget {
  final AmbargchareketDto? kalem;
  final List<StokListDto> stoklar;
  final List<ProjeDto> projeler;
  final List<DepoDto> depolar;
  final bool dovizli;
  final double kur;

  const _AmbargcKalemForm({
    this.kalem,
    required this.stoklar,
    required this.projeler,
    required this.depolar,
    required this.dovizli,
    required this.kur,
  });

  @override
  State<_AmbargcKalemForm> createState() => _AmbargcKalemFormState();
}

class _AmbargcKalemFormState extends State<_AmbargcKalemForm> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.primary;
  Color get _accent => _scheme.primary;
  Color get _primaryDark => _scheme.onSurface;

  late AmbargchareketDto _k;
  bool _stokYukleniyor = false;

  List<OlcubrDto> _olcuBirimleri = [];
  List<DepoadresDto> _depoadresler = [];
  bool _adresYukleniyor = false;

  late TextEditingController _miktarCtrl;
  late TextEditingController _fiyatCtrl;
  late TextEditingController _dovizFiyatCtrl;
  late TextEditingController _tutarCtrl;
  late TextEditingController _aciklamaCtrl;

  @override
  void initState() {
    super.initState();
    final s = widget.kalem;
    _k = AmbargchareketDto();

    if (s != null) {
      _k.id = s.id;
      _k.ambargcid = s.ambargcid;
      _k.stokid = s.stokid;
      _k.stokozelliksabitid = s.stokozelliksabitid;
      _k.stokozelliksabit = s.stokozelliksabit;
      _k.dovizfiyat = s.dovizfiyat;
      _k.miktar2 = s.miktar2;
      _k.tarih = s.tarih;
      _k.stok = s.stok;
      _k.depoid = s.depoid;
      _k.depoadresid = s.depoadresid;
      _k.projeid = s.projeid;
      _k.olcubrid = s.olcubrid;
      _k.olcubr = s.olcubr;
      _k.miktar = s.miktar;
      _k.fiyat = s.fiyat;
      _k.tutar = s.tutar;
      _k.aciklama = s.aciklama;
      if (s.olcubr != null) _olcuBirimleri = [s.olcubr!];
      if (s.stokid != null) _loadOlcuBirimByStok(s.stokid!);
    }

    final ilkDepoAtandi = _k.depoid == null && widget.depolar.isNotEmpty;
    if (ilkDepoAtandi) _k.depoid = widget.depolar.first.id;
    final ilkProjeAtandi = _k.projeid == null && widget.projeler.isNotEmpty;
    if (ilkProjeAtandi) _k.projeid = widget.projeler.first.id;
    if (_k.depoid != null) _loadDepoadresler(_k.depoid!);
    if (ilkDepoAtandi) _applyVarsayilanDepo(_k.depoid);
    if (ilkProjeAtandi) _applyVarsayilanProje(_k.projeid);

    _miktarCtrl = TextEditingController(
        text: s?.miktar != null
            ? s!.miktar!.toString().replaceAll('.', ',')
            : '');
    _fiyatCtrl = TextEditingController(
        text:
            s?.fiyat != null ? s!.fiyat!.toString().replaceAll('.', ',') : '');
    _dovizFiyatCtrl = TextEditingController(
        text: (s?.dovizfiyat ??
                    (widget.dovizli && widget.kur > 0 && s?.fiyat != null
                        ? s!.fiyat! / widget.kur
                        : null))
                ?.toString()
                .replaceAll('.', ',') ??
            '');
    _tutarCtrl = TextEditingController(
        text: s?.tutar != null
            ? NumberFormatHelper.format(s!.tutar!, decimal: 2)
            : '');
    _aciklamaCtrl = TextEditingController(text: s?.aciklama ?? '');
  }

  @override
  void dispose() {
    _miktarCtrl.dispose();
    _fiyatCtrl.dispose();
    _dovizFiyatCtrl.dispose();
    _tutarCtrl.dispose();
    _aciklamaCtrl.dispose();
    super.dispose();
  }

  // ─── DEPO ADRESİ ────────────────────────────────────────
  /// Kullanıcının seçtiği varsayılan projeyi uygular (ilk proje henüz değiştirilmediyse).
  Future<void> _applyVarsayilanProje(int? ilkId) async {
    final pick = await VarsayilanProjeHelper.pickFrom(widget.projeler);
    if (!mounted || pick == null || pick == ilkId || _k.projeid != ilkId)
      return;
    setState(() => _k.projeid = pick);
  }

  /// Kullanıcının seçtiği varsayılan depoyu uygular (ilk depo henüz değiştirilmediyse).
  Future<void> _applyVarsayilanDepo(int? ilkId) async {
    final pick = await VarsayilanDepoHelper.pickFrom(widget.depolar);
    if (!mounted || pick == null || pick == ilkId || _k.depoid != ilkId) return;
    setState(() => _k.depoid = pick);
    _loadDepoadresler(pick);
  }

  Future<void> _loadDepoadresler(int depoId) async {
    final mevcutId = _k.depoadresid; // düzenleme modunda seçili adresi koru
    setState(() {
      _adresYukleniyor = true;
      _depoadresler = [];
      _k.depoadresid = null;
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
            _k.depoadresid = mevcutId;
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
      setState(() => _k.depoadresid = bulunan.id);
      UiFeedback.showSuccess(
          context,
          "Adres: ${[
            bulunan.kod,
            bulunan.ad,
            bulunan.bolum
          ].where((s) => s != null && s.isNotEmpty).join(' - ')}");
    } else {
      UiFeedback.showError(context, "Depo adresi bulunamadı: $barkod");
    }
  }

  Future<void> _kameraBarkodIleAdresAra() async {
    final v = await Navigator.push<String>(
        context,
        PermissionMaterialPageRoute(
            builder: (_) => const BarcodeScannerSheet()));
    if (v != null && mounted) _barkodIleAdresAra(v);
  }

  Future<void> _terminalBarkodIleAdresAra() async {
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
              style: ElevatedButton.styleFrom(backgroundColor: _accent),
              child: const Text("Ara")),
        ],
      ),
    );
    if (result != null && result.isNotEmpty && mounted)
      _barkodIleAdresAra(result);
  }

  // ─── ÖLÇÜ BİRİMİ YÜKLEMEsini ────────────────────────────
  Future<void> _loadOlcuBirimByStok(int stokId) async {
    setState(() => _stokYukleniyor = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    try {
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
      if (!mounted) return;
      setState(() {
        _olcuBirimleri = tekBirim;
        if (tekBirim.isNotEmpty && !tekBirim.any((o) => o.Id == _k.olcubrid)) {
          _k.olcubrid = tekBirim.first.Id;
          _k.olcubr = tekBirim.first;
        }
        // Yeni kalem ise fiyat doldur
        if (widget.kalem == null && stok.Stokfiyat.isNotEmpty) {
          final satisfiyat = stok.Stokfiyat.first.Satisfiyat ?? 0;
          if (satisfiyat > 0) {
            _k.fiyat = satisfiyat;
            _fiyatCtrl.text = NumberFormatHelper.format(satisfiyat, decimal: 4);
            if (widget.dovizli && widget.kur > 0)
              _dovizFiyatCtrl.text =
                  (satisfiyat / widget.kur).toString().replaceAll('.', ',');
            _recalcTutar();
          }
        }
      });
    } catch (_) {
    } finally {
      if (mounted && _k.stokid == stokId)
        setState(() => _stokYukleniyor = false);
    }
  }

  void _onStokSecildi(StokListDto s) {
    setState(() {
      if (_k.stokid != s.Id) _k.stokozelliksabitid = null;
      _k.stokid = s.Id;
      _k.stok = StokDto(Id: s.Id, Kod: s.Kod, Ad: s.Ad);
      _olcuBirimleri = [];
      _k.olcubrid = null;
      _k.olcubr = null;
    });
    if (s.Id != null) _loadOlcuBirimByStok(s.Id!);
  }

  void _recalcTutar() {
    _k.miktar = NumberFormatHelper.parse(_miktarCtrl.text);
    _k.fiyat = NumberFormatHelper.parse(_fiyatCtrl.text);
    _k.dovizfiyat = _dovizFiyatCtrl.text.trim().isEmpty
        ? null
        : NumberFormatHelper.parse(_dovizFiyatCtrl.text);
    priceWarehouseLine(_k, foreign: widget.dovizli, rate: widget.kur);
    if (widget.dovizli)
      _fiyatCtrl.text = _k.fiyat!.toString().replaceAll('.', ',');
    _tutarCtrl.text = NumberFormatHelper.format(_k.tutar, decimal: 2);
  }

  void _kaydet() {
    if (_stokYukleniyor) {
      UiFeedback.showWarning(context, 'Stok bilgileri yükleniyor.');
      return;
    }
    if (_k.stok?.Stokozelligesahip == true && _k.stokozelliksabitid == null) {
      UiFeedback.showWarning(context, 'Stok özelliği seçiniz.');
      return;
    }
    if (widget.dovizli &&
        (widget.kur <= 0 || _dovizFiyatCtrl.text.trim().isEmpty)) {
      UiFeedback.showWarning(context, 'Döviz fiyatı ve kur giriniz.');
      return;
    }
    if (NumberFormatHelper.parse(
            widget.dovizli ? _dovizFiyatCtrl.text : _fiyatCtrl.text) <
        0) {
      UiFeedback.showWarning(context, 'Fiyat negatif olamaz.');
      return;
    }

    if (_k.stokid == null) {
      UiFeedback.showWarning(context, "Stok seçiniz!");
      return;
    }
    if (_k.depoid == null) {
      UiFeedback.showWarning(context, "Depo seçiniz!");
      return;
    }
    if ((_k.miktar ?? 0) <= 0) {
      UiFeedback.showWarning(context, "Miktar giriniz!");
      return;
    }
    _recalcTutar();
    _k.aciklama =
        _aciklamaCtrl.text.trim().isEmpty ? null : _aciklamaCtrl.text.trim();
    _k.stokozelliksabit = _k.stok?.Stokozellik
        .where((f) => f.stokozelliksabitid == _k.stokozelliksabitid)
        .firstOrNull
        ?.stokozelliksabit;
    Navigator.pop(context, _k);
  }

  // ─── BUILD ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(widget.kalem == null ? "Kalem Ekle" : "Kalemi Düzenle",
              style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 17,
                  fontWeight: FontWeight.bold)),
          IconButton(
              tooltip: 'Kapat',
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context)),
        ]),
        const Divider(),
        const SizedBox(height: 8),

        // 1. Stok + Barkod butonları
        _buildStokSecici(),
        const SizedBox(height: 12),

        // 2. Depo
        _inputLabel("Depo *"),
        _depoSecici(
            value: _k.depoid,
            items: widget.depolar,
            onChanged: (v) {
              setState(() {
                _k.depoid = v?.id;
                _k.depoadresid = null;
                _depoadresler = [];
              });
              if (v?.id != null) _loadDepoadresler(v!.id!);
            }),
        // Dinamik depo ise adres satırı
        if ((widget.depolar
                .firstWhere((d) => d.id == _k.depoid, orElse: () => DepoDto())
                .dinamikdepo) ==
            true) ...[
          const SizedBox(height: 8),
          _inputLabel("Depo Adresi"),
          Row(children: [
            Expanded(
                child: _adresYukleniyor
                    ? const SizedBox(
                        height: 45,
                        child: Center(child: LinearProgressIndicator()))
                    : _buildDropdown<String>(
                        value: _depoadresler.any((a) => a.id == _k.depoadresid)
                            ? _k.depoadresid
                            : null,
                        items: _depoadresler
                            .where((a) => a.id != null)
                            .map((a) => DropdownMenuItem<String>(
                                  value: a.id,
                                  child: Text(
                                      [a.kod, a.ad, a.bolum]
                                          .where(
                                              (s) => s != null && s.isNotEmpty)
                                          .join(' - '),
                                      style: const TextStyle(
                                          fontFamily: 'Roboto', fontSize: 12),
                                      overflow: TextOverflow.ellipsis),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _k.depoadresid = v))),
            const SizedBox(width: 8),
            _adresBtn(Icons.qr_code_scanner_rounded, Colors.green.shade600,
                _kameraBarkodIleAdresAra),
            const SizedBox(width: 8),
            _adresBtn(
                Icons.barcode_reader, _accent, _terminalBarkodIleAdresAra),
          ]),
        ],
        const SizedBox(height: 12),

        WarehouseFeatureField(
            stock: _k.stok,
            value: _k.stokozelliksabitid,
            onChanged: (v) => setState(() => _k.stokozelliksabitid = v)),
        if (_stokYukleniyor) const LinearProgressIndicator(),
        // 3. Proje
        _inputLabel("Proje"),
        _buildDropdown<int>(
            value: _k.projeid,
            items: widget.projeler
                .map((e) => DropdownMenuItem(
                    value: e.id,
                    child: Text("${e.kod ?? ''} - ${e.ad ?? ''}",
                        style:
                            const TextStyle(fontFamily: 'Roboto', fontSize: 13),
                        overflow: TextOverflow.ellipsis)))
                .toList(),
            onChanged: (v) => setState(() => _k.projeid = v)),
        const SizedBox(height: 12),

        // 4. Miktar
        _inputLabel("Miktar *"),
        TextFormField(
          controller: _miktarCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontFamily: 'Roboto', fontSize: 13),
          decoration: _inputDeco("0,0000"),
          onChanged: (_) => setState(() => _recalcTutar()),
        ),
        const SizedBox(height: 12),

        // 5. Ölçü Birimi
        _inputLabel("Ölçü Birimi"),
        _buildDropdown<int>(
            value: _k.olcubrid,
            items: _olcuBirimleri
                .map((e) => DropdownMenuItem(
                    value: e.Id,
                    child: Text(e.Ad ?? '',
                        style: const TextStyle(
                            fontFamily: 'Roboto', fontSize: 13))))
                .toList(),
            onChanged: (v) {
              final ob = _olcuBirimleri.where((e) => e.Id == v).firstOrNull;
              setState(() {
                _k.olcubrid = v;
                _k.olcubr = ob;
              });
            }),
        const SizedBox(height: 12),

        if (widget.dovizli) ...[
          _inputLabel('Döviz Fiyatı'),
          TextFormField(
              key: const ValueKey('warehouse-fx-price'),
              controller: _dovizFiyatCtrl,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: _inputDeco(''),
              onChanged: (_) => setState(_recalcTutar)),
          const SizedBox(height: 12),
        ],
        // 6. Birim Fiyat
        _inputLabel("Birim Fiyat"),
        TextFormField(
          controller: _fiyatCtrl,
          readOnly: widget.dovizli,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(fontFamily: 'Roboto', fontSize: 13),
          decoration: _inputDeco("0,0000"),
          onChanged: (_) => setState(() => _recalcTutar()),
        ),
        const SizedBox(height: 12),

        // 7. Tutar (readonly)
        _inputLabel("Tutar"),
        TextFormField(
          controller: _tutarCtrl,
          readOnly: true,
          style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _primary),
          decoration: _inputDeco("0,00")
              .copyWith(filled: true, fillColor: _scheme.primaryContainer),
        ),
        const SizedBox(height: 12),

        // Açıklama
        _inputLabel("Açıklama"),
        TextFormField(
          controller: _aciklamaCtrl,
          maxLines: 2,
          style: const TextStyle(fontFamily: 'Roboto', fontSize: 13),
          onChanged: (v) => _k.aciklama = v.isEmpty ? null : v,
          decoration: _inputDeco("Açıklama"),
        ),
        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: _kaydet,
          style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: _scheme.onPrimary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          icon: const Icon(Icons.check, size: 18),
          label: Text(widget.kalem == null ? "Kalemi Ekle" : "Güncelle",
              style: const TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 15)),
        ),
        const SizedBox(height: 8),
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("İptal",
                style: TextStyle(
                    fontFamily: 'Roboto', color: _scheme.onSurfaceVariant))),
      ]),
    );
  }

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
                if (s != null) _onStokSecildi(s);
              },
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                            color: _primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10)),
                        child: Icon(Icons.inventory_2_rounded,
                            color: _primary, size: 20)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Text(
                            _k.stokid != null
                                ? "${_k.stok?.Kod} - ${_k.stok?.Ad}"
                                : "Stok",
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                color: _k.stokid == null
                                    ? Colors.grey
                                    : _primaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 13),
                            overflow: TextOverflow.ellipsis)),
                    Icon(Icons.chevron_right_rounded,
                        color: _scheme.onSurfaceVariant, size: 18),
                  ])),
            )),
      )),
      const SizedBox(width: 8),
      _scanBtn(Icons.qr_code_scanner_rounded, _accent, startWithCamera: true),
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
                if (s != null) _onStokSecildi(s);
              },
              child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Icon(icon, color: color, size: 24)),
            )),
      );

  // ─── YARDIMCILAR ─────────────────────────────────────────
  Widget _inputLabel(String label) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(label,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: _scheme.onSurfaceVariant)),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        hintText: hint,
        hintStyle: TextStyle(
            fontFamily: 'Roboto',
            color: _scheme.onSurfaceVariant,
            fontSize: 13),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: _scheme.outlineVariant)),
      );

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
        borderRadius: BorderRadius.circular(8),
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
        child: Container(
          height: 45,
          padding: const EdgeInsets.symmetric(horizontal: 10),
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
    );
  }

  Widget _buildDropdown<T>(
      {required T? value,
      required List<DropdownMenuItem<T>> items,
      required ValueChanged<T?> onChanged}) {
    final safeValue = items.any((e) => e.value == value) ? value : null;
    return Container(
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
                    color: _scheme.onSurface))));
  }

  Widget _adresBtn(IconData icon, Color color, VoidCallback onTap) => SizedBox(
        width: 44,
        height: 45,
        child: Material(
          color: _scheme.surface,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: _depoadresler.isEmpty ? null : onTap,
              child: Container(
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _scheme.outlineVariant)),
                  child: Icon(icon,
                      size: 20,
                      color: _depoadresler.isEmpty
                          ? _scheme.outlineVariant
                          : color))),
        ),
      );
}
