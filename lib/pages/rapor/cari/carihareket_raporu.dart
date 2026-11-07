import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../helpers/ui_feedback.dart';
//import '../../../helpers/number_format_helper.dart';
import '../../../models/entities/rapor/cari/view_carihareket.dart';
import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../services/rapor/rapor_service.dart';
import '../../../services/rapor/rapor_aktar_service.dart';
import '../../../services/cari/cari_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../widgets/erp_selector.dart';
import '../../fatura/Satisfaturasi/fatura_ekle_page.dart';
import '../../fatura/Alisfaturasi/alisfatura_ekle_page.dart';
import '../../irsaliye/irsaliye_ekle_page.dart';
import '../../irsaliye/Alis/alisirsaliye_ekle_page.dart';

class CariHareketRaporu extends StatefulWidget {
  /// Başka bir rapordan (ör. Cari Borç/Alacak) detay olarak açılırken hazır gelen filtreler.
  final CariDtoLite? baslangicCari;
  final DateTime? baslangicTarih1;
  final DateTime? baslangicTarih2;
  final DovizDto? baslangicDoviz;

  const CariHareketRaporu(
      {super.key,
      this.baslangicCari,
      this.baslangicTarih1,
      this.baslangicTarih2,
      this.baslangicDoviz});
  @override
  State<CariHareketRaporu> createState() => _CariHareketRaporuState();
}

class _CariHareketRaporuState extends State<CariHareketRaporu> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.primary;
  Color get _accent => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;
  Color get _borcRenk => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFFFF9C9C)
      : Color(0xFFB3261E);
  Color get _alacakRenk => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFF6EE7B7)
      : Color(0xFF16704A);

  final _svc = RaporService();
  bool _loading = false;
  bool _querying = false;

  List<ViewCarihareket> _data = [];
  String? _baFilter; // null=tümü, 'B'=borç, 'A'=alacak
  List<CariDtoLite> _cariler = [];
  List<ProjeDto> _projeler = [];

  CariDtoLite? _seciliCari;
  ProjeDto? _seciliProje;
  DovizDto? _seciliDoviz;
  List<DovizDto> _dovizler = [];
  late DateTime _tarih1;
  late DateTime _tarih2;

  final _dateFmt = DateFormat('dd.MM.yyyy');
  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final bugun = DateTime(now.year, now.month, now.day);
    // Varsayılan tarih aralığı günün tarihi (başka rapordan detay olarak açılmışsa gelen aralık kullanılır)
    _tarih1 = widget.baslangicTarih1 ?? bugun;
    _tarih2 = widget.baslangicTarih2 ??
        (widget.baslangicTarih1 == null ? bugun : now);
    _seciliCari = widget.baslangicCari;
    _seciliDoviz = widget.baslangicDoviz;
    _loadLookups().then((_) {
      if (widget.baslangicCari != null && mounted) _sorgula();
    });
  }

  Future<void> _loadLookups() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      List<ProjeDto> projeler = [];
      try {
        projeler = await ProjeService().getProjeList(token);
      } catch (_) {}
      List<DovizDto> dovizler = [];
      try {
        dovizler = await DovizService().getDovizler(token);
      } catch (_) {}
      if (mounted)
        setState(() {
          _projeler = projeler;
          _dovizler = dovizler;
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
      final data = await _svc.getCariHareket(token,
          tarih1: _tarih1,
          tarih2: _tarih2,
          cariid: _seciliCari?.Id,
          projeid: _seciliProje?.id,
          dovizid: _seciliDoviz?.Id);
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

  bool get _herhangiFiltre =>
      _seciliCari != null || _seciliProje != null || _seciliDoviz != null;

  void _showFiltreSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSheetState) => Container(
          decoration: BoxDecoration(
              color: _scheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: _scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2))),
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
                      _seciliCari = null;
                      _seciliProje = null;
                      _seciliDoviz = null;
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
            _sheetSecici(
              label: "Cari *",
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
            _sheetSecici(
              label: "Para Birimi",
              value: _seciliDoviz != null
                  ? "${_seciliDoviz!.Birim ?? ''} - ${_seciliDoviz!.Ad ?? ''}"
                  : null,
              icon: Icons.currency_exchange_rounded,
              onTap: () async {
                final s = await showErpSelector<DovizDto>(
                    context: context,
                    title: "Para Birimi Seç",
                    hintText: "Birim veya ad",
                    items: _dovizler,
                    itemText: (d) => "${d.Birim ?? ''} - ${d.Ad ?? ''}");
                if (s != null) {
                  setState(() => _seciliDoviz = s);
                  setSheetState(() {});
                }
              },
              onClear: _seciliDoviz != null
                  ? () {
                      setState(() => _seciliDoviz = null);
                      setSheetState(() {});
                    }
                  : null,
            ),
            SizedBox(height: 12),
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
                      backgroundColor: _scheme.surface,
                      foregroundColor: _scheme.onSurface,
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
                Text(
                  selected ? value : "Seçiniz",
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected ? _primary : _scheme.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: ErpPageAppBar(
        context: context,
        title: Text("Cari Hareket Raporu",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        actions: [
          if (_data.isNotEmpty)
            PopupMenuButton<bool>(
                tooltip: 'Dışa Aktar',
                icon: Icon(Icons.ios_share_rounded, size: 21),
                onSelected: (excel) async {
                  try {
                    if (excel) {
                      await RaporAktarService.cariExcel(
                          context, _data, _tarih1, _tarih2);
                    } else {
                      await RaporAktarService.cariPdf(
                          context,
                          _data,
                          _tarih1,
                          _tarih2,
                          _seciliCari == null
                              ? null
                              : '${_seciliCari!.Kod ?? ''} - ${_seciliCari!.Ad ?? ''}');
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
          Stack(children: [
            IconButton(
                icon: Icon(Icons.tune_rounded),
                tooltip: "Filtreler",
                onPressed: _showFiltreSheet),
            if (_herhangiFiltre)
              Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                        color: _accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: _primary, width: 1.5)),
                  )),
          ]),
          IconButton(
            icon: _querying
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _scheme.primary))
                : Icon(Icons.search_rounded),
            tooltip: 'Sorgula',
            onPressed: _querying ? null : _sorgula,
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : Column(children: [
              // Tarih şeridi
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
                        "${DateFormat('dd.MM.yyyy').format(_tarih1)}  -  ${DateFormat('dd.MM.yyyy').format(_tarih2)}",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _scheme.onSurface)),
                    Spacer(),
                    if (_seciliCari != null)
                      Text(_seciliCari!.Kod ?? '',
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

  // ─── ÖZET BAR ────────────────────────────────────────────
  Widget _buildOzetBar() {
    final topBorc = _data.fold(0.0, (s, r) => s + (r.borctutar ?? 0));
    final topAlacak = _data.fold(0.0, (s, r) => s + (r.alacaktutar ?? 0));
    final topKayit = _filtered.length;
    final last = _data.isNotEmpty ? _data.last : null;
    final sonBakiye =
        (last?.borcbakiye ?? 0) > 0 ? last?.borcbakiye : last?.alacakbakiye;
    final bakiyeIsBorc = (last?.borcbakiye ?? 0) > 0;
    final bakiyeRenk = bakiyeIsBorc ? _borcRenk : _alacakRenk;
    final bakiyeLabel = bakiyeIsBorc ? "B" : "A";

    return Padding(
        padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Column(children: [
          Row(children: [
            Expanded(
                child: Text(
                    _baFilter == null
                        ? '${_data.length} kayıt'
                        : '$topKayit / ${_data.length} kayıt',
                    style: TextStyle(
                        fontSize: 12, color: _scheme.onSurfaceVariant))),
            if (_baFilter != null)
              IconButton(
                  tooltip: 'Filtreyi Temizle',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _baFilter = null),
                  icon: Icon(Icons.close_rounded, size: 18)),
            if (sonBakiye != null)
              Flexible(
                  child: Text(
                      'Bakiye ${_moneyFmt.format(sonBakiye)} ₺ $bakiyeLabel',
                      textAlign: TextAlign.end,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: bakiyeRenk)))
          ]),
          SizedBox(height: 6),
          Row(children: [
            Expanded(
                child: _baChip(
                    label: 'Borç',
                    tutar: _moneyFmt.format(topBorc),
                    renk: _borcRenk,
                    arkaRenk: _scheme.surfaceContainerLow,
                    borderRenk: _scheme.outlineVariant,
                    aktif: _baFilter == 'B',
                    icon: Icons.arrow_upward_rounded,
                    onTap: () => setState(
                        () => _baFilter = _baFilter == 'B' ? null : 'B'))),
            SizedBox(width: 8),
            Expanded(
                child: _baChip(
                    label: 'Alacak',
                    tutar: _moneyFmt.format(topAlacak),
                    renk: _alacakRenk,
                    arkaRenk: _scheme.surfaceContainerLow,
                    borderRenk: _scheme.outlineVariant,
                    aktif: _baFilter == 'A',
                    icon: Icons.arrow_downward_rounded,
                    onTap: () => setState(
                        () => _baFilter = _baFilter == 'A' ? null : 'A')))
          ]),
        ]));
  }

  Widget _baChip(
          {required String label,
          required String tutar,
          required Color renk,
          required Color arkaRenk,
          required Color borderRenk,
          required bool aktif,
          required IconData icon,
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
                    Icon(icon, size: 15, color: renk),
                    SizedBox(width: 8),
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
                              child: Text('$tutar ₺',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: renk)))
                        ])),
                  ]))));

  List<ViewCarihareket> get _filtered {
    if (_baFilter == null) return _data;
    if (_baFilter == 'B')
      return _data.where((r) => (r.borctutar ?? 0) > 0).toList();
    return _data.where((r) => (r.alacaktutar ?? 0) > 0).toList();
  }

  // ─── LİSTE ───────────────────────────────────────────────
  Widget _buildListe() {
    // Cari kod - isme göre gruplanır (grup içinde tarih sırası korunur); her grubun başlığında cari ve toplamlar
    final gruplar = <String, List<ViewCarihareket>>{};
    for (final r in _filtered) {
      gruplar
          .putIfAbsent('${r.carikod ?? ''}|${r.cariisim ?? ''}', () => [])
          .add(r);
    }
    final anahtarlar = gruplar.keys.toList()..sort();
    final oge = <Object>[];
    for (final k in anahtarlar) {
      oge.add(gruplar[k]!);
      oge.addAll(gruplar[k]!);
    }
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 20),
      itemCount: oge.length,
      itemBuilder: (_, i) {
        final o = oge[i];
        return o is List<ViewCarihareket>
            ? _buildCariBaslik(o)
            : _buildSatir(o as ViewCarihareket);
      },
    );
  }

  Widget _buildCariBaslik(List<ViewCarihareket> g) {
    final borc = g.fold(0.0, (s, r) => s + (r.borctutar ?? 0));
    final alacak = g.fold(0.0, (s, r) => s + (r.alacaktutar ?? 0));
    final net = borc - alacak;
    final renk = net >= 0 ? _borcRenk : _alacakRenk;
    return Container(
      margin: EdgeInsets.only(top: 8, bottom: 6),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
          color: _scheme.primaryContainer,
          borderRadius: BorderRadius.circular(10)),
      child: Row(children: [
        Icon(Icons.business_rounded, size: 16, color: _scheme.onSurfaceVariant),
        SizedBox(width: 8),
        Expanded(
            child: Text('${g.first.carikod ?? ''} - ${g.first.cariisim ?? ''}',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: _scheme.onSurface,
                    fontWeight: FontWeight.w700,
                    fontSize: 13),
                overflow: TextOverflow.ellipsis)),
        Text('${_moneyFmt.format(net.abs())} ${net >= 0 ? 'B' : 'A'}',
            style: TextStyle(
                fontFamily: 'Roboto',
                color: renk,
                fontWeight: FontWeight.w800,
                fontSize: 12.5)),
      ]),
    );
  }

  /// Satıra dokununca ilgili belgeyi açar (fatura / irsaliye).
  void _detayaGit(ViewCarihareket r) {
    final id = r.belgeid;
    Widget? sayfa;
    if (id != null && id.isNotEmpty) {
      switch (r.belgeturu) {
        case 1:
          sayfa = FaturaEklePage(faturaId: id);
          break;
        case 2:
          sayfa = AlisFaturaEklePage(faturaId: id);
          break;
        case 3:
          sayfa = IrsaliyeEklePage(irsaliyeId: id);
          break;
        case 4:
          sayfa = AlisIrsaliyeEklePage(irsaliyeId: id);
          break;
      }
    }
    if (sayfa == null) {
      UiFeedback.showWarning(context,
          'Bu hareket türü (${r.belgeno ?? ''}) için detay ekranı yok.');
      return;
    }
    Navigator.push(
        context, PermissionMaterialPageRoute(builder: (_) => sayfa!));
  }

  Widget _buildSatir(ViewCarihareket r) {
    final isBorc = (r.borctutar ?? 0) > 0;
    final tutar = isBorc ? r.borctutar : r.alacaktutar;
    final bakiye = (r.borcbakiye ?? 0) > 0 ? r.borcbakiye : r.alacakbakiye;
    final bakiyeIsBorc = (r.borcbakiye ?? 0) > 0;
    final tutarRenk = isBorc ? _borcRenk : _alacakRenk;
    final bakiyeRenk = bakiyeIsBorc ? _borcRenk : _alacakRenk;
    final tutarLabel = isBorc ? "B" : "A";
    final bakiyeLabel = bakiyeIsBorc ? "B" : "A";
    final hasDoviz =
        (r.dovizbirim != null && r.dovizbirim != "TL" && r.dovizbirim != "TRY");
    final dovizTutar = isBorc ? r.dovizborctutar : r.dovizalacaktutar;
    final dovizBakiye =
        (r.dovizborcbakiye ?? 0) > 0 ? r.dovizborcbakiye : r.dovizalacakbakiye;
    final dovizBakiyeIsBorc = (r.dovizborcbakiye ?? 0) > 0;

    return Padding(
        padding: EdgeInsets.only(bottom: 8),
        child: Material(
          color: _scheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                  color: _scheme.outlineVariant.withValues(alpha: .45))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: () => _detayaGit(r),
              child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          Expanded(
                              child: Text(r.belgeno ?? '-',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600))),
                          SizedBox(width: 8),
                          Text(
                              r.tarih == null ? '-' : _dateFmt.format(r.tarih!),
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11,
                                  color: _scheme.onSurfaceVariant)),
                          SizedBox(width: 4),
                          Icon(Icons.chevron_right_rounded,
                              size: 17, color: _scheme.onSurfaceVariant)
                        ]),
                        if (r.aciklama?.isNotEmpty == true) ...[
                          SizedBox(height: 4),
                          Text(r.aciklama!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 12,
                                  color: _scheme.onSurfaceVariant))
                        ],
                        if (r.vadetarih != null) ...[
                          SizedBox(height: 3),
                          Text('Vade ${_dateFmt.format(r.vadetarih!)}',
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 10,
                                  color: _scheme.onSurfaceVariant))
                        ],
                        SizedBox(height: 8),
                        Row(children: [
                          Expanded(
                              child: _tutarKart(isBorc ? 'Borç' : 'Alacak',
                                  tutar, tutarLabel, tutarRenk)),
                          SizedBox(width: 12),
                          Expanded(
                              child: _tutarKart(
                                  'Bakiye', bakiye, bakiyeLabel, bakiyeRenk))
                        ]),
                        if (hasDoviz) ...[
                          SizedBox(height: 8),
                          Wrap(spacing: 12, runSpacing: 4, children: [
                            if (r.kur != null)
                              Text('Kur ${_moneyFmt.format(r.kur)}',
                                  style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontSize: 11,
                                      color: _scheme.onSurfaceVariant)),
                            Text(
                                'Tutar ${_moneyFmt.format(dovizTutar ?? 0)} ${r.dovizbirim} $tutarLabel',
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 11,
                                    color: tutarRenk)),
                            Text(
                                'Bakiye ${_moneyFmt.format(dovizBakiye ?? 0)} ${r.dovizbirim} ${dovizBakiyeIsBorc ? 'B' : 'A'}',
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 11,
                                    color: dovizBakiyeIsBorc
                                        ? _borcRenk
                                        : _alacakRenk)),
                          ])
                        ],
                      ]))),
        ));
  }

  Widget _tutarKart(String label, double? tutar, String tip, Color renk) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 10,
                color: _scheme.onSurfaceVariant)),
        SizedBox(height: 3),
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('${_moneyFmt.format(tutar ?? 0)} ₺ $tip',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: renk))),
      ]);

  Widget _buildBos() => Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.account_balance_wallet_outlined,
            size: 64, color: _scheme.outlineVariant),
        SizedBox(height: 12),
        Text("Henüz sorgu yapılmadı",
            style: TextStyle(
                fontFamily: 'Roboto',
                color: _scheme.onSurfaceVariant,
                fontSize: 15,
                fontWeight: FontWeight.w500)),
        SizedBox(height: 8),
        Text(
            "${DateFormat('dd.MM.yyyy').format(_tarih1)} - ${DateFormat('dd.MM.yyyy').format(_tarih2)}",
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
            Text(DateFormat('dd.MM.yyyy').format(tarih),
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
}
