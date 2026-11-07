import '../../../widgets/erp_page_style.dart';
import '../../../widgets/erp_ui.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../helpers/ui_feedback.dart';
import '../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../helpers/plasiyer_depo_helper.dart';
// import '../../../helpers/number_format_helper.dart';
import '../../../models/entities/rapor/stok/view_stokhareket.dart';
import '../../../models/entities/stok/stok_list_dto.dart';
import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../models/entities/depo/depo_dto.dart';
import '../../../services/rapor/rapor_service.dart';
import '../../../services/rapor/rapor_aktar_service.dart';
import '../../../services/stok/stok_service.dart';
import '../../../services/cari/cari_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../services/depo/depo_service.dart';
import '../../../widgets/erp_selector.dart';

class StokHareketRaporu extends StatefulWidget {
  /// Stok Bakiye raporundan detay olarak açılırken hazır gelen stok / depo.
  final StokListDto? baslangicStok;
  final DepoDto? baslangicDepo;

  const StokHareketRaporu({super.key, this.baslangicStok, this.baslangicDepo});
  @override
  State<StokHareketRaporu> createState() => _StokHareketRaporuState();
}

class _StokHareketRaporuState extends State<StokHareketRaporu> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.primary;
  Color get _accent => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;
  Color get _girisRenk => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFF6EE7B7)
      : Color(0xFF16704A);
  Color get _cikisRenk => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFFFF9C9C)
      : Color(0xFFB3261E);

  final _svc = RaporService();
  bool _loading = false;
  bool _querying = false;

  List<ViewStokhareket> _data = [];
  String? _gcFilter; // null=tümü, 'G'=girişler, 'Ç'=çıkışlar
  List<StokListDto> _stoklar = [];
  List<CariDtoLite> _cariler = [];
  List<ProjeDto> _projeler = [];
  List<DepoDto> _depolar = [];

  // Filtreler
  StokListDto? _seciliStok;
  CariDtoLite? _seciliCari;
  ProjeDto? _seciliProje;
  DepoDto? _seciliDepo;
  bool _depoKilitli =
      false; // plasiyer kullanıcı: depo kendi (araç) deposu, değiştirilemez
  late DateTime _tarih1;
  late DateTime _tarih2;

  final _dateFmt = DateFormat('dd.MM.yyyy');
  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');
  final _miktarFmt = NumberFormat('#,##0.####', 'tr_TR');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Varsayılan tarih aralığı günün tarihi; Stok Bakiye'den detay olarak açılırsa (stok hazır) ay başı → bugün
    final bugun = DateTime(now.year, now.month, now.day);
    _tarih1 =
        widget.baslangicStok == null ? bugun : DateTime(now.year, now.month, 1);
    _tarih2 = widget.baslangicStok == null ? bugun : now;
    _seciliStok = widget.baslangicStok;
    _seciliDepo = widget.baslangicDepo;
    _loadLookups().then((_) async {
      await _plasiyerVarsayilanlari();
      if (widget.baslangicStok != null && mounted) _sorgula();
    });
  }

  /// Plasiyer kullanıcıda: depo kendi (araç) deposu olarak seçili gelir ve değiştirilemez
  /// (başka rapordan detay olarak açılmışsa dokunulmaz).
  Future<void> _plasiyerVarsayilanlari() async {
    final kp = await KullaniciPlasiyerHelper.getir();
    if (!kp.kilitli || !mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final depoId = await PlasiyerDepoHelper.getId(
        prefs.getString("token_final") ?? "", kp.plasiyerid,
        kilitli: true, mevcutDepolar: _depolar);
    final depo = _depolar.where((d) => d.id == depoId).firstOrNull;
    setState(() {
      if (depo != null && widget.baslangicDepo == null) {
        _seciliDepo = depo;
        _depoKilitli = true;
      }
    });
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final subeId = prefs.getInt("sube_id") ?? 0;

      List<StokListDto> stoklar = [];
      List<ProjeDto> projeler = [];
      List<DepoDto> depolar = [];

      try {
        stoklar = await StokService().getStokList(token);
      } catch (_) {}
      try {
        projeler = await ProjeService().getProjeList(token);
      } catch (_) {}
      try {
        depolar = await DepoService().getAllBySubeId(token, subeId);
      } catch (_) {}

      if (mounted)
        setState(() {
          _stoklar = stoklar;
          _projeler = projeler;
          _depolar = depolar;
          _loading = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        UiFeedback.showError(context, e.toString());
      }
    }
  }

  Future<void> _sorgula() async {
    setState(() => _querying = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final data = await _svc.getStokHareket(
        token,
        tarih1: _tarih1,
        tarih2: _tarih2,
        stokid: _seciliStok?.Id,
        cariid: _seciliCari?.Id,
        projeid: _seciliProje?.id,
        depoid: _seciliDepo?.id,
      );
      if (mounted)
        setState(() {
          _data = data;
          _querying = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _querying = false);
        UiFeedback.showError(context, e.toString());
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final aktifFiltreAdet = [
      _seciliStok,
      _seciliCari,
      _seciliProje,
      _seciliDepo
    ].where((f) => f != null).length;

    return Scaffold(
      backgroundColor: _surface,
      appBar: ErpPageAppBar(
        context: context,
        title: Text("Stok Hareket Raporu",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        actions: [
          Stack(children: [
            IconButton(
              icon: Icon(Icons.tune_rounded),
              tooltip: "Filtreler",
              onPressed: _showFiltreSheet,
            ),
            if (aktifFiltreAdet > 0)
              Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: _primary, width: 1.5)),
                    child: Center(
                        child: Text("$aktifFiltreAdet",
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: _scheme.onSurface))),
                  )),
          ]),
          if (_data.isNotEmpty)
            PopupMenuButton<bool>(
                tooltip: 'Dışa Aktar',
                icon: Icon(Icons.ios_share_rounded, size: 21),
                onSelected: (excel) async {
                  try {
                    if (excel) {
                      await RaporAktarService.stokExcel(
                          context, _filtered, _tarih1, _tarih2);
                    } else {
                      await RaporAktarService.stokPdf(
                          context, _filtered, _tarih1, _tarih2);
                    }
                  } catch (e) {
                    if (mounted)
                      UiFeedback.showError(context, 'Aktarım hatası: $e');
                  }
                },
                itemBuilder: (_) => [
                      PopupMenuItem(value: true, child: Text("Excel'e Aktar")),
                      PopupMenuItem(value: false, child: Text("PDF'e Aktar"))
                    ]),
          IconButton(
            icon: _querying
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _scheme.primary))
                : Icon(Icons.search_rounded),
            tooltip: "Sorgula",
            onPressed: _querying ? null : _sorgula,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(children: [
              // ── Tarih şeridi ──────────────────────────────
              GestureDetector(
                onTap: _showFiltreSheet,
                child: Container(
                  color: _scheme.surface,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(children: [
                    Icon(Icons.date_range_rounded,
                        size: 15, color: _scheme.onSurfaceVariant),
                    SizedBox(width: 6),
                    Text(
                        "${_dateFmt.format(_tarih1)}  -  ${_dateFmt.format(_tarih2)}",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _scheme.onSurface)),
                    Spacer(),
                    if (aktifFiltreAdet > 0) ...[
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _accent.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _accent.withOpacity(0.6)),
                        ),
                        child: Text("$aktifFiltreAdet filtre aktif",
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: _scheme.onSurface,
                                fontWeight: FontWeight.w600)),
                      ),
                    ] else
                      Text("Filtre ekle",
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              color: _scheme.onSurfaceVariant)),
                    SizedBox(width: 4),
                    Icon(Icons.expand_more_rounded,
                        size: 16, color: _scheme.onSurfaceVariant),
                  ]),
                ),
              ),
              if (_data.isNotEmpty) _buildOzetBar(),
              Expanded(
                  child: _querying
                      ? Center(child: CircularProgressIndicator())
                      : _data.isEmpty
                          ? _buildBos()
                          : _buildListe()),
            ]),
    );
  }

  bool get _herhangiFiltre =>
      _seciliStok != null ||
      _seciliCari != null ||
      _seciliProje != null ||
      _seciliDepo != null;

  void _showFiltreSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            // Handle
            Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: _scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2))),
            // Başlık
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Filtreler",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              if (_herhangiFiltre)
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _seciliStok = null;
                      _seciliCari = null;
                      _seciliProje = null;
                      if (!_depoKilitli) _seciliDepo = null;
                    });
                    setSheetState(() {});
                  },
                  icon: Icon(Icons.clear_all_rounded, size: 16),
                  label: Text("Temizle",
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 13)),
                  style: TextButton.styleFrom(
                      foregroundColor: Colors.red.shade600),
                ),
            ]),
            Divider(),
            SizedBox(height: 8),
            // Tarih
            Row(children: [
              Expanded(
                  child: _tarihSecici("Başlangıç", _tarih1, (d) {
                setState(() => _tarih1 = d);
                setSheetState(() {});
              })),
              SizedBox(width: 8),
              Expanded(
                  child: _tarihSecici("Bitiş", _tarih2, (d) {
                setState(() => _tarih2 = d);
                setSheetState(() {});
              })),
            ]),
            SizedBox(height: 12),
            // Stok
            _sheetSecici(
              label: "Stok",
              value: _seciliStok != null
                  ? "${_seciliStok!.Kod ?? ''} - ${_seciliStok!.Ad ?? ''}"
                  : null,
              icon: Icons.inventory_2_outlined,
              onTap: () async {
                final s = await showErpSelector<StokListDto>(
                    context: context,
                    title: "Stok Seç",
                    hintText: "Stok adı veya kodu",
                    items: _stoklar,
                    itemText: (s) => "${s.Kod ?? ''} - ${s.Ad ?? ''}",
                    getBarcodes: (s) => s.getBarkodListesi(),
                    getUnit: (s) => s.TemelolcubrAd ?? '');
                if (s != null) {
                  setState(() => _seciliStok = s);
                  setSheetState(() {});
                }
              },
              onClear: _seciliStok != null
                  ? () {
                      setState(() => _seciliStok = null);
                      setSheetState(() {});
                    }
                  : null,
            ),
            SizedBox(height: 10),
            // Cari
            _sheetSecici(
              label: "Cari",
              value: _seciliCari != null
                  ? "${_seciliCari!.Kod ?? ''} - ${_seciliCari!.Ad ?? ''}"
                  : null,
              icon: Icons.business_outlined,
              onTap: () async {
                if (_cariler.isEmpty) {
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString("token_final") ?? "";
                  try {
                    _cariler = await CariService().getCariler(token);
                  } catch (_) {}
                }
                final s = await showErpSelector<CariDtoLite>(
                    context: context,
                    title: "Cari Seç",
                    hintText: "Cari adı veya kodu",
                    items: _cariler,
                    itemText: (c) => "${c.Kod ?? ''} - ${c.Ad ?? ''}");
                if (s != null) {
                  setState(() => _seciliCari = s);
                  setSheetState(() {});
                }
              },
              onClear: _seciliCari != null
                  ? () {
                      setState(() => _seciliCari = null);
                      setSheetState(() {});
                    }
                  : null,
            ),
            SizedBox(height: 10),
            // Proje
            _sheetSecici(
              label: "Proje",
              value: _seciliProje?.kod,
              icon: Icons.folder_outlined,
              onTap: () async {
                final s = await showErpSelector<ProjeDto>(
                    context: context,
                    title: "Proje Seç",
                    hintText: "Proje adı veya kodu",
                    items: _projeler,
                    itemText: (p) => "${p.kod ?? ''} - ${p.ad ?? ''}");
                if (s != null) {
                  setState(() => _seciliProje = s);
                  setSheetState(() {});
                }
              },
              onClear: _seciliProje != null
                  ? () {
                      setState(() => _seciliProje = null);
                      setSheetState(() {});
                    }
                  : null,
            ),
            SizedBox(height: 10),
            // Depo
            _sheetSecici(
              label: _depoKilitli ? "Depo (plasiyer deposu)" : "Depo",
              value: _seciliDepo != null
                  ? (_seciliDepo!.kod ?? _seciliDepo!.ad)
                  : null,
              icon: Icons.warehouse_outlined,
              onTap: _depoKilitli
                  ? () {}
                  : () async {
                      final s = await showErpSelector<DepoDto>(
                          context: context,
                          title: "Depo Seç",
                          hintText: "Depo adı",
                          items: _depolar,
                          itemText: (d) => d.ad ?? '');
                      if (s != null) {
                        setState(() => _seciliDepo = s);
                        setSheetState(() {});
                      }
                    },
              onClear: (_seciliDepo != null && !_depoKilitli)
                  ? () {
                      setState(() => _seciliDepo = null);
                      setSheetState(() {});
                    }
                  : null,
            ),
            SizedBox(height: 12),
            // Sorgula
            SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _querying
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _sorgula();
                        },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: _scheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                  icon: Icon(Icons.search_rounded, size: 20),
                  label: Text("Sorgula",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                )),
          ])),
        ),
      ),
    );
  }

  Widget _sheetSecici(
      {required String label,
      String? value,
      required IconData icon,
      required VoidCallback onTap,
      VoidCallback? onClear}) {
    final selected = value != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: selected
                  ? _primary.withOpacity(0.5)
                  : _scheme.outlineVariant),
          color: selected
              ? _primary.withOpacity(0.04)
              : _scheme.surfaceContainerLow,
        ),
        child: Row(children: [
          Icon(icon,
              size: 18, color: selected ? _primary : _scheme.onSurfaceVariant),
          SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        color: _scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600)),
                Text(selected ? value : "Tümü",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? _primary : _scheme.onSurfaceVariant),
                    overflow: TextOverflow.ellipsis),
              ])),
          if (onClear != null)
            GestureDetector(
                onTap: onClear,
                child: Icon(Icons.close_rounded,
                    size: 18, color: _scheme.onSurfaceVariant))
          else
            Icon(Icons.chevron_right_rounded,
                size: 18, color: _scheme.onSurfaceVariant),
        ]),
      ),
    );
  }

  // ─── ÖZET BAR ────────────────────────────────────────────
  Widget _buildOzetBar() {
    final topGiris = _data.fold(0.0, (s, r) => s + (r.girismiktar ?? 0));
    final topCikis = _data.fold(0.0, (s, r) => s + (r.cikismiktar ?? 0));
    final topGTutar = _data.fold(0.0, (s, r) => s + (r.giristutar ?? 0));
    final topCTutar = _data.fold(0.0, (s, r) => s + (r.cikistutar ?? 0));

    return Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(
                    _gcFilter == null
                        ? '${_data.length} kayıt'
                        : '${_filtered.length} / ${_data.length} kayıt',
                    style: TextStyle(
                        fontSize: 12, color: _scheme.onSurfaceVariant))),
            if (_gcFilter != null)
              IconButton(
                  tooltip: 'Filtreyi Temizle',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _gcFilter = null),
                  icon: Icon(Icons.close_rounded, size: 18))
          ]),
          SizedBox(height: 6),
          Row(children: [
            Expanded(
                child: _gcChip(
                    label: 'Giriş',
                    miktar: _miktarFmt.format(topGiris),
                    tutar: _moneyFmt.format(topGTutar),
                    renk: _girisRenk,
                    arkaRenk: _scheme.surfaceContainerLow,
                    borderRenk: _scheme.outlineVariant,
                    aktif: _gcFilter == 'G',
                    onTap: () => setState(
                        () => _gcFilter = _gcFilter == 'G' ? null : 'G'))),
            SizedBox(width: 8),
            Expanded(
                child: _gcChip(
                    label: 'Çıkış',
                    miktar: _miktarFmt.format(topCikis),
                    tutar: _moneyFmt.format(topCTutar),
                    renk: _cikisRenk,
                    arkaRenk: _scheme.surfaceContainerLow,
                    borderRenk: _scheme.outlineVariant,
                    aktif: _gcFilter == 'Ç',
                    onTap: () => setState(
                        () => _gcFilter = _gcFilter == 'Ç' ? null : 'Ç')))
          ]),
        ]));
  }

  Widget _gcChip(
          {required String label,
          required String miktar,
          required String tutar,
          required Color renk,
          required Color arkaRenk,
          required Color borderRenk,
          required bool aktif,
          required VoidCallback onTap}) =>
      Material(
          color: aktif ? renk.withValues(alpha: .10) : _scheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: aktif ? renk : borderRenk)),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: onTap,
              child: Padding(
                  padding: EdgeInsets.all(10),
                  child: Row(children: [
                    Icon(
                        label == 'Giriş'
                            ? Icons.input_rounded
                            : Icons.output_rounded,
                        size: 15,
                        color: renk),
                    SizedBox(width: 6),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text(label,
                              style: TextStyle(
                                  fontSize: 10,
                                  color: _scheme.onSurfaceVariant)),
                          FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(miktar,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: renk)))
                        ])),
                    SizedBox(width: 6),
                    Flexible(
                        child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text('$tutar ₺',
                                style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _scheme.onSurface)))),
                  ]))));

  List<ViewStokhareket> get _filtered {
    if (_gcFilter == null) return _data;
    if (_gcFilter == 'G')
      return _data.where((r) => (r.girismiktar ?? 0) > 0).toList();
    return _data.where((r) => (r.cikismiktar ?? 0) > 0).toList();
  }

  // ─── LİSTE ───────────────────────────────────────────────
  Widget _buildListe() {
    final liste = _filtered;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 20),
      itemCount: liste.length,
      itemBuilder: (_, i) => _buildSatir(liste[i]),
    );
  }

  Widget _buildSatir(ViewStokhareket r) {
    final isGiris = (r.girismiktar ?? 0) > 0;
    final miktar = isGiris ? r.girismiktar : r.cikismiktar;
    final tutar = isGiris ? r.giristutar : r.cikistutar;
    final gcRenk = isGiris ? _girisRenk : _cikisRenk;

    return ErpFinanceCard(
        title: r.ad ?? r.kod ?? '-',
        icon: isGiris ? Icons.input_rounded : Icons.output_rounded,
        metadata: [
          r.tarih == null ? '-' : _dateFmt.format(r.tarih!),
          r.belgeno ?? '-',
          if (r.kod?.isNotEmpty == true) r.kod!,
          if (r.belge?.isNotEmpty == true) r.belge!,
          '${_miktarFmt.format(miktar ?? 0)} ${r.olcubr ?? ''}${(r.fiyat ?? 0) > 0 ? ' × ${_moneyFmt.format(r.fiyat)} ₺' : ''}'
        ],
        amount: '${_moneyFmt.format(tutar ?? 0)} ₺',
        amountColor: gcRenk,
        secondaryAmount: isGiris ? 'Giriş' : 'Çıkış');
  }

  Widget _buildBos() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.bar_chart_rounded, size: 64, color: _scheme.outlineVariant),
        SizedBox(height: 12),
        Text("Henüz sorgu yapılmadı",
            style: TextStyle(
                fontFamily: 'Roboto',
                color: _scheme.onSurfaceVariant,
                fontSize: 15,
                fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Text("${_dateFmt.format(_tarih1)} - ${_dateFmt.format(_tarih2)}",
            style: TextStyle(
                fontFamily: 'Roboto',
                color: _scheme.onSurfaceVariant,
                fontSize: 13)),
        SizedBox(height: 12),
        ElevatedButton.icon(
          onPressed: _querying ? null : _sorgula,
          style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              foregroundColor: _scheme.onPrimary,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12))),
          icon: Icon(Icons.search_rounded, size: 18),
          label: Text("Sorgula",
              style:
                  TextStyle(fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
        ),
      ]));

  // ─── YARDIMCI WİDGETLER ──────────────────────────────────
  Widget _tarihSecici(
      String label, DateTime tarih, Function(DateTime) onChanged) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
            context: context,
            initialDate: tarih,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100));
        if (d != null) onChanged(d);
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _scheme.outlineVariant),
            color: _scheme.surfaceContainerLow),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined,
              size: 14, color: _primary.withOpacity(0.7)),
          SizedBox(width: 6),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 9,
                    color: _scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
            Text(_dateFmt.format(tarih),
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primary)),
          ]),
        ]),
      ),
    );
  }

  // Widget _seciciChip({required String label, String? value, required IconData icon,
  //  required VoidCallback onTap, VoidCallback? onClear}) {
  //   final selected = value != null;
  //   return InkWell(
  //     onTap: onTap,
  //     child: Container(
  //       padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(8),
  //         border: Border.all(color: selected ? _primary.withOpacity(0.5) : _scheme.outlineVariant),
  //         color: selected ? _primary.withOpacity(0.05) : _scheme.surfaceContainerLow,
  //       ),
  //       child: Row(children: [
  //         Icon(icon, size: 14, color: selected ? _primary : _scheme.onSurfaceVariant),
  //         SizedBox(width: 6),
  //         Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
  //           Text(label, style: TextStyle(fontFamily: 'Roboto', fontSize: 9, color: _scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
  //           Text(selected ? value : "Tümü",
  //               style: TextStyle(fontFamily: 'Roboto', fontSize: 12, fontWeight: FontWeight.w700,
  //                   color: selected ? _primary : _scheme.onSurfaceVariant),
  //               overflow: TextOverflow.ellipsis),
  //         ])),
  //         if (onClear != null)
  //           GestureDetector(onTap: onClear,
  //               child: Icon(Icons.close_rounded, size: 14, color: _scheme.onSurfaceVariant)),
  //       ]),
  //     ),
  //   );
  // }
}
