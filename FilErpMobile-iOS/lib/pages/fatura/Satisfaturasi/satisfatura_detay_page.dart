import 'package:FilERP/widgets/document_line_amount.dart';
import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:FilERP/widgets/document_action_ui.dart';
import 'package:FilERP/config/api_config.dart';
import 'package:FilERP/services/ebelge/ebelge_service.dart';
import 'package:FilERP/services/ebelge/portal_service.dart';
import '../../../widgets/erp_page_style.dart';
import '../../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/entities/fatura/fatura_dto.dart';
import '../../../models/entities/fatura/fatura_create_dto.dart';
import '../../../models/entities/fatura/faturahareket_dto.dart';
//import '../../../models/entities/fatura/fatura_hareket_create_dto.dart';
import '../../../services/fatura/fatura_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/para_birimi_helper.dart';
import '../../../helpers/belge_durum_helper.dart';
import '../../../helpers/kdv_helper.dart';
import '../../../widgets/fatura/fatura_kalem_form_sheet.dart';
import '../../../models/entities/stok/stok_list_dto.dart';
import '../../../services/stok/stok_service.dart';
import '../../../helpers/belge_turu_couples.dart';
import '../../finans/tahsilat/tahsilat_liste_page.dart';
import '../../finans/tahsilat/tahsilat_ekle_page.dart';
import '../../../services/yazici/bluetooth_print_service.dart';
import '../../../services/yazici/yazici_sablon_service.dart';
import 'fatura_ekle_page.dart';

class SatisFaturaDetayPage extends StatefulWidget {
  const SatisFaturaDetayPage({super.key});
  @override
  State<SatisFaturaDetayPage> createState() => _SatisFaturaDetayPageState();
}

class _SatisFaturaDetayPageState extends State<SatisFaturaDetayPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.onSurface;
  Color get _accent => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;

  final service = FaturaService();
  bool loading = true;
  bool _portalBusy = false;
  String? _faturaId;
  FaturaDto? fatura;
  List<StokListDto> stoklar = [];

  final NumberFormat moneyFmt =
      NumberFormat.currency(locale: 'tr_TR', symbol: '', decimalDigits: 2);

  bool get _isDoviz => (fatura?.dovizid != null && fatura?.dovizid != 1);
  double get _kur => (fatura?.kur ?? 1.0).clamp(0.001, double.infinity);
  double _d(double v) => _isDoviz ? v / _kur : v;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = ModalRoute.of(context)?.settings.arguments as String?;
      if (id != null) {
        _faturaId = id;
        load(id);
      }
    });
  }

  Future<void> load(String id) async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      fatura = await service.getFaturaDetay(token, id);
    } catch (e) {
      UiFeedback.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<List<StokListDto>> _getStoklar() async {
    if (stoklar.isNotEmpty) return stoklar;
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString("token_final") ?? "";
    stoklar = await StokService().getStokList(token);
    return stoklar;
  }

  String fmtDate(DateTime? d) {
    if (d == null) return "-";
    return "${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}";
  }

  // ===================== BUILD =====================
  @override
  Widget build(BuildContext context) {
    if (loading)
      return Scaffold(
          backgroundColor: _surface,
          body: Center(child: CircularProgressIndicator()));
    if (fatura == null)
      return Scaffold(body: Center(child: Text("Fatura bulunamadı")));

    final para = ParaBirimiHelper.sembolById(fatura!.dovizid);
    final durumRenk = BelgeDurumHelper.renkById(fatura!.belgedurum);

    return Scaffold(
      backgroundColor: _surface,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(durumRenk, para),
          SliverToBoxAdapter(child: _buildInfoCards()),
          SliverToBoxAdapter(child: _buildKalemlerSection(para)),
          SliverToBoxAdapter(child: SizedBox(height: 180)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(para),
    );
  }

  // ===================== SLIVER APP BAR =====================
  Widget _buildSliverAppBar(Color durumRenk, String para) =>
      ErpPageSliverAppBar(
        context: context,
        pinned: true,
        toolbarHeight: 68,
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(fatura!.belgeserino ?? '-',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _scheme.onSurface)),
          GestureDetector(
              onTap: () => Navigator.pushNamed(context, '/cari-detay',
                  arguments: fatura!.cari?.Id),
              child: Text(
                  '${fatura!.cari?.Kod ?? ''} ${fatura!.cari?.Ad ?? ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontSize: 11, color: _scheme.onSurfaceVariant))),
          Text(BelgeDurumHelper.adById(fatura!.belgedurum),
              style: TextStyle(fontSize: 10, color: _scheme.onSurfaceVariant)),
        ]),
        actions: [
          IconButton(
              tooltip: 'Belge İşlemleri',
              icon: const Icon(Icons.more_vert_rounded),
              onPressed: _showIslemlerMenu)
        ],
      );

  // ===================== BİLGİ KARTLARI =====================
  Widget _buildInfoCards() {
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
      child: Row(
        children: [
          _infoChip(
              Icons.calendar_today_outlined, "Fatura", fmtDate(fatura!.tarih)),
          SizedBox(width: 8),
          _infoChip(Icons.event_available_outlined, "Vade",
              fmtDate(fatura!.vadetarihi)),
          SizedBox(width: 8),
          _infoChip(Icons.local_shipping_outlined, "Teslim",
              fmtDate(fatura!.teslimtarihi)),
        ],
      ),
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: _scheme.surface,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 12, color: _scheme.onSurfaceVariant),
              SizedBox(width: 4),
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: _scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ]),
            SizedBox(height: 3),
            Text(value,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: _primary)),
          ],
        ),
      ),
    );
  }

  // ===================== KALEMLER =====================
  Widget _buildKalemlerSection(String para) {
    final kalemler = fatura!.faturahareket ?? [];
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Row(
              children: [
                Container(
                    width: 3,
                    height: 18,
                    decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(2))),
                SizedBox(width: 8),
                Text("Fatura Kalemleri",
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _primary)),
                SizedBox(width: 6),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                      color: _primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text("${kalemler.length}",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _primary)),
                ),
              ],
            ),
          ),
          if (kalemler.isEmpty)
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                  color: _scheme.surface,
                  borderRadius: BorderRadius.circular(
                      ErpDesignStyle.modern(context) ? 18 : 12)),
              child: Center(
                  child: Text("Kalem bulunamadı",
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          color: _scheme.onSurfaceVariant))),
            )
          else
            ...kalemler.asMap().entries.map(
                (e) => _buildKalemCard(e.value, e.key, para, kalemler.length)),
        ],
      ),
    );
  }

  Widget _buildKalemCard(
      FaturahareketDto k, int index, String para, int total) {
    return Dismissible(
      key: Key(k.id ?? index.toString()),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await _silKalem(k);
        return false; // _silKalem zaten load() yapıyor, Dismissible'ın kaldırmasına gerek yok
      },
      background: Container(
        margin: EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: _scheme.error,
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.delete_outline_rounded,
                color: _scheme.onSurface, size: 22),
            SizedBox(height: 4),
            Text("Sil",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    color: _scheme.onSurface,
                    fontSize: 11,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
      child: GestureDetector(
        onTap: () => _showKalemDetay(k),
        child: Container(
          margin: EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 6,
                  offset: Offset(0, 2))
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // Sıra no
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                      color: _surface, borderRadius: BorderRadius.circular(6)),
                  child: Center(
                      child: Text("${index + 1}",
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: _primary))),
                ),
                SizedBox(width: 10),
                // Stok bilgisi
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        k.stok?.Ad ?? "-",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _primary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2),
                      Text(
                        "${k.miktar ?? 0} ${k.olcubr?.Ad ?? 'Adet'}  ×  ${moneyFmt.format(_isDoviz ? ((k.dovizfiyat ?? 0) > 0 ? k.dovizfiyat! : (k.fiyat ?? 0) / _kur) : (k.fiyat ?? 0))} $para  •  KDV ${KdvHelper.yuzdeText(k.kdvorani)}",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 11,
                            color: _scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8),
                // Tutar
                DocumentLineAmount(
                  amount: moneyFmt.format(_d(k.tutar ?? 0)),
                  currency: para,
                  color: _primary,
                  currencyColor: _scheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===================== KALEM DETAY =====================
  void _showKalemDetay(FaturahareketDto k) {
    final para = ParaBirimiHelper.sembolById(fatura!.dovizid);
    final double birimFiyat = _isDoviz
        ? ((k.dovizfiyat ?? 0) > 0 ? k.dovizfiyat! : (k.fiyat ?? 0) / _kur)
        : (k.fiyat ?? 0);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("${k.stok?.Kod ?? "-"}  ${k.stok?.Ad ?? ""}",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.bold,
                    fontSize: 16),
                maxLines: 2),
            SizedBox(height: 12),
            Divider(),
            _sheetRow("Miktar", "${k.miktar ?? 0} ${k.olcubr?.Ad ?? 'Adet'}"),
            _sheetRow("Birim Fiyat", "${moneyFmt.format(birimFiyat)} $para"),
            _sheetRow("KDV Oranı", KdvHelper.yuzdeText(k.kdvorani)),
            _sheetRow(
                "KDV Tutarı", "${moneyFmt.format(_d(k.kdvtutar ?? 0))} $para"),
            _sheetRow(
                "İskonto", "${moneyFmt.format(_d(k.iskontotutar ?? 0))} $para"),
            Divider(),
            _sheetRow(
                "Satır Toplamı", "${moneyFmt.format(_d(k.tutar ?? 0))} $para",
                bold: true),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: PermissionAction(
                  modules: [301],
                  access: Access.update,
                  child: ElevatedButton.icon(
                    icon: Icon(Icons.edit_outlined, size: 18),
                    label: Text("Kalemi Düzenle",
                        style: TextStyle(
                            fontFamily: 'Roboto', fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _scheme.surface,
                      foregroundColor: _scheme.onPrimary,
                      padding: EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      _editKalem(k);
                    },
                  )),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sheetRow(String label, String value, {bool bold = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  color: _scheme.onSurfaceVariant)),
          Text(value,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: bold ? FontWeight.bold : FontWeight.w600,
                  color: _primary)),
        ],
      ),
    );
  }

  Future<void> _editKalem(FaturahareketDto k) async {
    final stoklarLoaded = await _getStoklar();
    final kopya = FaturahareketDto();
    kopya.id = k.id;
    kopya.faturaid = k.faturaid;
    kopya.depoid = k.depoid;
    kopya.stokid = k.stokid;
    kopya.olcubrid = k.olcubrid;
    kopya.projeid = k.projeid;
    kopya.miktar = k.miktar;
    kopya.fiyat = k.fiyat;
    // kdvorani: API 0.2 gönderiyorsa *100=20, 20 gönderiyorsa olduğu gibi al
    final rawKdv = k.kdvorani ?? 0;
    kopya.kdvorani = rawKdv <= 1.0 && rawKdv > 0 ? rawKdv * 100 : rawKdv;
    kopya.tevkifatorani = k.tevkifatorani;
    kopya.referansid = k.referansid;
    kopya.dovizfiyat = k.dovizfiyat;
    kopya.iskontoorani1 = k.iskontoorani1;
    kopya.iskontotutari1 = k.iskontotutari1;
    kopya.bruttutar = k.bruttutar;
    kopya.iskontotutar = k.iskontotutar;
    kopya.kdvtutar = k.kdvtutar;
    kopya.tutar = k.tutar;
    kopya.aratoplam = k.aratoplam;
    kopya.sira = k.sira;
    kopya.aciklama = k.aciklama;
    kopya.malfazlasiiskonto = k.malfazlasiiskonto;
    kopya.malfazlasitutar = k.malfazlasitutar;
    kopya.stokozelliksabitid = k.stokozelliksabitid;
    kopya.stok = k.stok;

    final guncellendi = await showFaturaKalemForm(context,
        kalem: kopya,
        kdvDahil: fatura!.kdvdahil ?? true,
        stoklar: stoklarLoaded);
    if (guncellendi == null || !mounted) return;

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
            Text("Kalem güncelleniyor...",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      )),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      guncellendi.faturaid = fatura!.id;
      await service.saveOrUpdateRow(token, guncellendi);
      if (!mounted) return;
      Navigator.of(context).pop();
      load(_faturaId!);
      UiFeedback.showUpdated(context, "Kalem güncellendi");
    } catch (e, stack) {
      debugPrint("=== KALEM GÜNCELLE HATA ===\n$e\n$stack");
      if (!mounted) return;
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: Row(children: [
            Icon(Icons.error_outline, color: Colors.red),
            SizedBox(width: 8),
            Text("Güncelleme Hatası",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
          ]),
          content: SingleChildScrollView(
            child: SelectableText(
              e.toString(),
              style: TextStyle(fontSize: 12, fontFamily: 'monospace'),
            ),
          ),
          actions: [
            ErpDialogAction(
                onPressed: () => Navigator.pop(context), child: Text("Tamam")),
          ],
        ),
      );
    }
  }

  // ===================== KALEM SİL =====================
  Future<void> _silKalem(FaturahareketDto k) async {
    if (k.id == null) return;

    final onay = await UiFeedback.confirm(
      context,
      title: "Kalemi Sil",
      message: "\"${k.stok?.Ad ?? 'Bu kalem'}\" silinecek. Emin misiniz?",
      confirmLabel: "Sil",
      destructive: true,
    );

    if (onay != true || !mounted) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await service.removeKalem(token, k.id!);
      if (!mounted) return;
      load(_faturaId!);
      UiFeedback.showDeleted(context, "Kalem silindi");
    } catch (e) {
      if (!mounted) return;
      UiFeedback.showError(context, "Hata: $e");
    }
  }

  // ===================== BOTTOM BAR =====================
  Widget _buildBottomBar(String para) {
    return Container(
      decoration: BoxDecoration(
        color: _scheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: Offset(0, -4))
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Toplamlar
              Row(
                children: [
                  Expanded(
                      child: _totalChip(
                          "Ara Toplam", _d(fatura!.aratoplam ?? 0), para)),
                  SizedBox(width: 6),
                  Expanded(
                      child: _totalChip("KDV", () {
                    final kalemler = fatura!.faturahareket ?? [];
                    return kalemler.fold<double>(
                        0.0,
                        (sum, k) =>
                            sum +
                            _d((k.kdvtutar ?? 0) - (k.tevkifattutar ?? 0)));
                  }(), para)),
                  SizedBox(width: 6),
                  Expanded(
                      child: _totalChip(
                          "İskonto", _d(fatura!.iskontotutar ?? 0), para)),
                ],
              ),
              Builder(builder: (_) {
                final satirIskonto = (fatura!.faturahareket ?? []).fold<double>(
                    0.0, (sum, k) => sum + _d(k.iskontotutar ?? 0));
                if (satirIskonto <= 0) return SizedBox.shrink();
                return Column(children: [
                  SizedBox(height: 6),
                  Row(children: [
                    Expanded(
                        child: _totalChip("Satır İskontosu", satirIskonto, para,
                            accentColor: Color(0xFFEA580C))),
                  ]),
                ]);
              }),
              if ((fatura!.malfazlasitutar ?? 0) > 0) ...[
                SizedBox(height: 6),
                Row(children: [
                  Expanded(
                      child: _totalChip(
                          "Mal Fazlası", _d(fatura!.malfazlasitutar ?? 0), para,
                          accentColor: Color(0xFF7C3AED))),
                ]),
              ],
              SizedBox(height: 10),
              // Genel toplam + işlemler butonu
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _scheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Genel Toplam",
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  color: _scheme.onSurfaceVariant,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
                          Text(
                            "${moneyFmt.format(_d(fatura!.geneltoplam ?? 0))} $para",
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                color: _scheme.onSurface,
                                fontSize: 16,
                                fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(width: 10),
                  Material(
                    color: _scheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showIslemlerMenu,
                      child: Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.more_horiz_rounded,
                            color: _scheme.onSurface, size: 26),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _totalChip(String label, double value, String para,
      {Color? accentColor}) {
    final textColor = accentColor ?? _primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: accentColor != null ? accentColor.withOpacity(0.07) : _surface,
        borderRadius: BorderRadius.circular(8),
        border: accentColor != null
            ? Border.all(color: accentColor.withOpacity(0.25))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10,
                  color: accentColor != null
                      ? accentColor.withOpacity(0.7)
                      : _scheme.onSurfaceVariant)),
          SizedBox(height: 2),
          Text("${moneyFmt.format(value)} $para",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: textColor)),
        ],
      ),
    );
  }

  // ===================== İŞLEMLER MENÜ =====================
  void _showIslemlerMenu() {
    if (_portalBusy || fatura == null) return;
    final taslak = (fatura!.belgedurum ?? 0) == 0;
    void close() => Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DocumentActionsSheet(
        moduleId: 301,
        canModify: fatura!.belgedurum == 0,
        actions: [
          DocumentAction(
              'Faturayı Düzenle', Icons.edit_outlined, const Color(0xFF2563EB),
              () {
            close();
            _duzenle();
          }),
          DocumentAction(
              taslak ? 'Belgeyi Tamamla' : 'Belgeyi Taslağa Çek',
              taslak ? Icons.check_circle_outline_rounded : Icons.undo_rounded,
              taslak ? const Color(0xFF16A34A) : const Color(0xFFD97706), () {
            close();
            _belgeDurumDegistir(taslak ? 1 : 0);
          }),
          DocumentAction(
              'Tahsilat Yap', Icons.payments_outlined, const Color(0xFF16A34A),
              () {
            close();
            if (taslak) {
              UiFeedback.showWarning(
                  context, 'Taslak fatura üzerinde tahsilat yapılamaz.');
              return;
            }
            _tahsilat();
          }),
          DocumentAction(
              'Fişi Yazdır', Icons.print_outlined, const Color(0xFF0891B2), () {
            close();
            _yazdirFatura();
          }),
          DocumentAction('PDF Paylaş', Icons.share_outlined,
              const Color(0xFFDB2777), close),
        ],
        electronicActions: fatura!.belgedurum == 1
            ? [
                DocumentAction('Portala Gönder', Icons.cloud_upload_outlined,
                    const Color(0xFF7C3AED), () {
                  close();
                  _portalaGonder();
                }),
                DocumentAction('E-Fatura Oluştur ve Gönder',
                    Icons.send_outlined, const Color(0xFF0D9488), () {
                  close();
                  _eBelgeGonder();
                }),
              ]
            : const [],
        deleteAction: DocumentAction(
            'Faturayı Sil', Icons.delete_outline_rounded, _scheme.error, () {
          close();
          _silOnay();
        }),
      ),
    );
  }

  // ===================== TAHSİLAT =====================
  Future<void> _tahsilat() async {
    if (fatura?.id == null) return;
    final kaynak = TahsilatKaynakBelge(
      belgeId: fatura!.id!,
      belgeturu: fatura!.belgeturu ?? BelgeTuruCouples.satisFaturasi,
      belgeserino: fatura!.belgeserino,
      belgeno: fatura!.belgeno,
      cariid: fatura!.cariid,
      dovizid: fatura!.dovizid,
      projeid: fatura!.projeid,
      plasiyerid: fatura!.plasiyerid,
      toplamTutar: fatura!.geneltoplam ?? 0,
      dovizToplam: _isDoviz ? fatura!.doviztoplam : null,
    );
    if (!mounted) return;
    await Navigator.push(
        context,
        PermissionMaterialPageRoute(
            builder: (_) => TahsilatListePage(kaynakBelge: kaynak)));
  }

  /// Fatura tamamlandıktan sonra "tahsilat yapılacak mı?" diye sorar.
  /// "Tahsilat Yap" → Tahsilat ekranına gider, "Yazdır" → mevcut yazıcı
  /// ayarlarıyla faturayı basar, "Kapat" → hiçbir şey yapmadan devam eder.
  Future<void> _tamamlandiSonrasiSor() async {
    final secim = await InvoiceCompletedDialog.show(context);
    if (!mounted) return;

    if (secim == 'tahsilat') {
      await _tahsilat();
    } else if (secim == 'yazdir') {
      await _yazdirFatura();
    }
  }

  Future<void> _yazdirFatura() async {
    if (fatura == null) return;
    try {
      final svc = BluetoothPrintService.instance;
      var connected = await svc.isConnected;
      if (!connected) {
        final mac = await svc.getSavedMac();
        if (mac == null) {
          if (mounted) {
            UiFeedback.showError(context,
                "Kayıtlı yazıcı yok. Ayarlar > Yazıcı Ayarları'ndan bir yazıcı seçin.");
          }
          return;
        }
        connected = await svc.connect(mac);
        if (!connected) {
          if (mounted) UiFeedback.showError(context, "Yazıcıya bağlanılamadı.");
          return;
        }
      }

      final fisKalemler = (fatura!.faturahareket ?? [])
          .map((k) => FaturaFisKalem(
                ad: k.stok?.Ad ?? '-',
                miktar: k.miktar ?? 0,
                birimFiyat: k.fiyat ?? 0,
              ))
          .toList();

      final satirGen = await YaziciSablonService.instance.getSatirGenisligi();
      final prefs = await SharedPreferences.getInstance();
      final kullaniciAdi = prefs.getString('kullanici_adi');

      final bytes = svc.buildFaturaFisi(
        belgeNo: fatura!.belgeserino ?? fatura!.belgeno ?? '-',
        tarih: fatura!.tarih ?? DateTime.now(),
        cariAd: fatura!.cari?.Ad ?? '-',
        plasiyerAd: fatura!.plasiyer?.Adsoyad,
        kalemler: fisKalemler,
        araToplam: fatura!.aratoplam ?? 0,
        kdvToplam: fatura!.kdvtoplam ?? 0,
        genelToplam: fatura!.geneltoplam ?? 0,
        satirGenisligi: satirGen,
        kullaniciAdi: kullaniciAdi,
      );
      final ok = await svc.printBytes(bytes);
      if (!mounted) return;
      if (ok) {
        UiFeedback.showSuccess(context, "Fatura yazıcıya gönderildi.");
      } else {
        UiFeedback.showError(context, "Yazdırma başarısız.");
      }
    } catch (e) {
      if (mounted) UiFeedback.showError(context, e.toString());
    }
  }

  // ===================== BELGE DURUM =====================
  Future<void> _belgeDurumDegistir(int yeniDurum) async {
    final taslakaMi = yeniDurum == 0;
    final onay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: taslakaMi
                      ? _scheme.primary.withValues(alpha: .08)
                      : Color(0xFFE8F5E9),
                ),
                child: Icon(
                  taslakaMi
                      ? Icons.undo_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 36,
                  color: taslakaMi ? _scheme.primary : Color(0xFF2E7D32),
                ),
              ),
              SizedBox(height: 20),
              Text(
                taslakaMi ? "Taslağa Çek" : "Belgeyi Tamamla",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 18,
                    fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              Text(
                taslakaMi
                    ? "${fatura!.belgeserino ?? ''} faturası taslak durumuna alınacak."
                    : "${fatura!.belgeserino ?? ''} faturası tamamlandı olarak işaretlenecek.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: _scheme.onSurfaceVariant,
                    height: 1.5),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text("Vazgeç"),
                  )),
                  SizedBox(width: 12),
                  Expanded(
                      child: PermissionAction(
                          modules: [301],
                          access: Access.create,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: taslakaMi
                                  ? _scheme.primary
                                  : Color(0xFF2E7D32),
                              foregroundColor: _scheme.onPrimary,
                              padding: EdgeInsets.symmetric(vertical: 13),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              elevation: 0,
                            ),
                            child: Text(taslakaMi ? "Taslağa Çek" : "Tamamla",
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold)),
                          ))),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (onay != true || !mounted) return;

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
            Text(taslakaMi ? "Taslağa alınıyor..." : "Tamamlanıyor...",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      )),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await service.belgeDurumGuncelle(token, fatura!.id!, yeniDurum);
      if (!mounted) return;
      Navigator.of(context).pop(); // loading kapat
      if (!mounted) return;
      if (taslakaMi) {
        UiFeedback.showWarning(context, "Fatura taslağa alındı");
      } else {
        UiFeedback.showUpdated(context, "Fatura tamamlandı");
        await _tamamlandiSonrasiSor();
      }
      if (!mounted) return;
      Navigator.of(context).pop(true); // listeye dön + yenile
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showError(context, "Hata: $e");
    }
  }

  // ===================== PORTALA GÖNDER =====================
  Future<void> _eBelgeGonder() async {
    if (_portalBusy || fatura?.id == null) return;
    _portalBusy = true;
    OverlayEntry? progress;
    try {
      final environment =
          ApiConfig.serverType == ServerType.canli ? 'CANLI' : 'TEST';
      final onay = await DocumentSendDialog.show(
        context,
        title: "E-Fatura Gönder · $environment",
        documentNumber: fatura!.belgeserino ?? 'Belge',
        portal: false,
      );
      if (!onay || !mounted) return;
      progress =
          UiFeedback.showLoading(context, text: "E-Fatura gönderiliyor...");
      final prefs = await SharedPreferences.getInstance();
      await EBelgeService().send(
        token: prefs.getString('token_final') ?? '',
        id: fatura!.id!,
        companyId: prefs.getInt('sirket_id') ?? 0,
        document: PortalDocument.invoice,
      );
      UiFeedback.hideLoading(progress);
      progress = null;
      if (!mounted) return;
      await load(_faturaId!);
      if (!mounted) return;
      UiFeedback.showSent(context, "E-Fatura gönderildi");
    } catch (e) {
      if (progress != null) {
        UiFeedback.hideLoading(progress);
        progress = null;
      }
      if (!mounted) return;
      if (e is EBelgeUncertain) {
        await load(_faturaId!);
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Gönderim Sonucu'),
            content: Text(e.toString()),
            actions: [
              ErpDialogAction(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Tamam'))
            ],
          ),
        );
        return;
      }
      UiFeedback.showException(context, e);
    } finally {
      if (progress != null) UiFeedback.hideLoading(progress);
      _portalBusy = false;
    }
  }

  Future<void> _portalaGonder() async {
    if (_portalBusy || fatura?.id == null) return;
    _portalBusy = true;
    OverlayEntry? progress;
    try {
      final onay = await DocumentSendDialog.show(
        context,
        title: "Portala Gönder",
        documentNumber: fatura!.belgeserino ?? 'Belge',
        portal: true,
      );
      if (!onay || !mounted) return;
      progress =
          UiFeedback.showLoading(context, text: "Portala gönderiliyor...");
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await service.portalaGonder(token, fatura!.id!);
      UiFeedback.hideLoading(progress);
      progress = null;
      if (!mounted) return;
      await load(_faturaId!);
      if (!mounted) return;
      UiFeedback.showSent(context, "Fatura portala gönderildi");
    } catch (e) {
      if (progress != null) {
        UiFeedback.hideLoading(progress);
        progress = null;
      }
      if (!mounted) return;
      UiFeedback.showException(context, e);
    } finally {
      if (progress != null) UiFeedback.hideLoading(progress);
      _portalBusy = false;
    }
  }

  Future<void> _duzenle() async {
    try {
      final stoklarLoaded = await _getStoklar();
      final createDto = FaturaCreateDto.fromFaturaDto(fatura!);
      final kalemler = (fatura!.faturahareket ?? []).map((k) {
        final kopya = FaturahareketDto();
        kopya.id = k.id;
        kopya.faturaid = k.faturaid;
        kopya.depoid = k.depoid;
        kopya.stokid = k.stokid;
        kopya.olcubrid = k.olcubrid;
        kopya.projeid = k.projeid;
        kopya.referansid = k.referansid;
        kopya.miktar = k.miktar;
        kopya.fiyat = k.fiyat;
        kopya.dovizfiyat = k.dovizfiyat;
        final rawKdv2 = k.kdvorani ?? 0;
        kopya.kdvorani =
            rawKdv2 <= 1.0 && rawKdv2 > 0 ? rawKdv2 * 100 : rawKdv2;
        kopya.tevkifatorani = k.tevkifatorani;
        kopya.iskontoorani1 = k.iskontoorani1;
        kopya.iskontotutari1 = k.iskontotutari1;
        kopya.bruttutar = k.bruttutar;
        kopya.iskontotutar = k.iskontotutar;
        kopya.kdvtutar = k.kdvtutar;
        kopya.tutar = k.tutar;
        kopya.aratoplam = k.aratoplam;
        kopya.sira = k.sira;
        kopya.aciklama = k.aciklama;
        kopya.malfazlasiiskonto = k.malfazlasiiskonto;
        kopya.malfazlasitutar = k.malfazlasitutar;
        kopya.stokozelliksabitid = k.stokozelliksabitid;
        kopya.stok = k.stok;
        return kopya;
      }).toList();

      if (!mounted) return;
      final result = await Navigator.push(
        context,
        PermissionMaterialPageRoute(
            builder: (_) => FaturaEklePage(
                  faturaId: _faturaId,
                  mevcutFatura: createDto,
                  mevcutKalemler: kalemler,
                  mevcutStoklar: stoklarLoaded,
                )),
      );
      if (result != null && mounted) {
        await load(_faturaId!);
        if (mounted) Navigator.of(context).pop(true); // listeye dön + yenile
      }
    } catch (e) {
      if (!mounted) return;
      UiFeedback.showError(context, "Hata: $e");
    }
  }

  // ===================== SİL =====================
  Future<void> _silOnay() async {
    final onay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: Color(0xFFFFEBEE)),
                child: Icon(Icons.delete_outline_rounded,
                    size: 36, color: Color(0xFFC62828)),
              ),
              SizedBox(height: 20),
              Text("Faturayı Sil",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(
                "${fatura!.belgeserino ?? ''} numaralı fatura kalıcı olarak silinecek.",
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: _scheme.onSurfaceVariant,
                    height: 1.5),
              ),
              SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12))),
                    child: Text("Vazgeç"),
                  )),
                  SizedBox(width: 12),
                  Expanded(
                      child: PermissionAction(
                          modules: [301],
                          access: Access.delete,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFFC62828),
                                foregroundColor: _scheme.onPrimary,
                                padding: EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12)),
                                elevation: 0),
                            child: Text("Sil",
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold)),
                          ))),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (onay != true || !mounted) return;

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
            SizedBox(height: 20),
            Text("Fatura siliniyor...",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ]),
        ),
      )),
    );

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await service.deleteFatura(token, fatura!.id!);
      if (!mounted) return;
      Navigator.of(context).pop(); // loading kapat
      Navigator.of(context).pop(true); // listeye dön + yenile
      UiFeedback.showDeleted(
          context, "${fatura!.belgeserino ?? 'Fatura'} silindi");
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showError(context, "Hata: $e");
    }
  }
}
