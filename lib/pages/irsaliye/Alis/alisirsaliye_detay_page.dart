import 'package:FilERP/widgets/document_line_amount.dart';
import 'package:FilERP/widgets/erp_dialog_action.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import '../../../theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../models/entities/irsaliye/irsaliye_dto.dart';

import '../../../models/entities/irsaliye/irsaliyehareket_dto.dart';
//import '../../../models/entities/fatura/fatura_hareket_create_dto.dart';
import '../../../services/irsaliye/irsaliye_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/para_birimi_helper.dart';
import '../../../helpers/belge_durum_helper.dart';
import '../../../helpers/kdv_helper.dart';
import '../../../widgets/irsaliye/irsaliye_kalem_form_sheet.dart';
import '../../../models/entities/stok/stok_list_dto.dart';
import '../../../services/stok/stok_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../services/depo/depo_service.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../models/entities/depo/depo_dto.dart';
import 'alisirsaliye_ekle_page.dart';

class AlisIrsaliyeDetayPage extends StatefulWidget {
  const AlisIrsaliyeDetayPage({super.key});
  @override
  State<AlisIrsaliyeDetayPage> createState() => _AlisIrsaliyeDetayPageState();
}

class _AlisIrsaliyeDetayPageState extends State<AlisIrsaliyeDetayPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.onSurface;
  Color get _accent => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;

  final service = IrsaliyeService();
  bool loading = true;
  String? _irsaliyeId;
  IrsaliyeDto? fatura;
  List<StokListDto> stoklar = [];
  List<ProjeDto> _projeler = [];
  List<DepoDto> _depolar = [];

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
        _irsaliyeId = id;
        load(id);
      }
    });
  }

  Future<void> load(String id) async {
    setState(() => loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      fatura = await service.getAlisById(token, id);
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
    final subeId = prefs.getInt("sube_id") ?? 0;
    stoklar = await StokService().getStokList(token);
    try {
      _projeler = await ProjeService().getProjeList(token);
    } catch (_) {}
    try {
      _depolar = await DepoService().getAllBySubeId(token, subeId);
    } catch (_) {}
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
          _infoChip(Icons.calendar_today_outlined, "İrsaliye",
              fmtDate(fatura!.tarih)),
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
    final kalemler = fatura!.irsaliyehareket;
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
                Text("İrsaliye Kalemleri",
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
      IrsaliyehareketDto k, int index, String para, int total) {
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
  void _showKalemDetay(IrsaliyehareketDto k) {
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
                  modules: [502],
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

  Future<void> _editKalem(IrsaliyehareketDto k) async {
    final stoklarLoaded = await _getStoklar();
    final kopya = IrsaliyehareketDto();
    kopya.id = k.id;
    kopya.irsaliyeid = k.irsaliyeid;
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

    final guncellendi = await showIrsaliyeKalemForm(context,
        kalem: kopya,
        kdvDahil: fatura!.kdvdahil ?? false,
        stoklar: stoklarLoaded,
        projeler: _projeler,
        depolar: _depolar);
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
      guncellendi.irsaliyeid = fatura!.id;
      await service.updateAlisHareket(token, {
        "id": guncellendi.id,
        "irsaliyeid": guncellendi.irsaliyeid ?? fatura!.id,
        "stokid": guncellendi.stokid,
        "depoid": guncellendi.depoid,
        "olcubrid": guncellendi.olcubrid,
        "projeid": guncellendi.projeid,
        "miktar": guncellendi.miktar,
        "miktar2": guncellendi.miktar2,
        "fiyat": guncellendi.fiyat ?? 0,
        "kdvorani": (guncellendi.kdvorani ?? 0) / 100,
        "tevkifatorani": guncellendi.tevkifatorani ?? 0,
        "iskontotutar": guncellendi.iskontotutar ?? 0,
        "malfazlasiiskonto": guncellendi.malfazlasiiskonto,
        "malfazlasitutar": guncellendi.malfazlasitutar ?? 0,
        "bruttutar": guncellendi.bruttutar ?? 0,
        "aratoplam": guncellendi.aratoplam ?? guncellendi.bruttutar ?? 0,
        "sonaratoplam": guncellendi.sonaratoplam ?? guncellendi.bruttutar ?? 0,
        "kdvmatrahi": guncellendi.kdvmatrahi ?? guncellendi.bruttutar ?? 0,
        "kdvtutar": guncellendi.kdvtutar ?? 0,
        "netaratoplam": guncellendi.netaratoplam ?? guncellendi.bruttutar ?? 0,
        "geneltoplam": guncellendi.geneltoplam ?? guncellendi.tutar ?? 0,
        "tevkifattutar": guncellendi.tevkifattutar ?? 0,
        "songeneltoplam": guncellendi.songeneltoplam ?? guncellendi.tutar ?? 0,
        "tutar": guncellendi.tutar ?? 0,
        "kur": guncellendi.kur ?? 1,
        "aciklama": guncellendi.aciklama,
        "teslimtarihi": guncellendi.teslimtarihi?.toIso8601String(),
        "stokozelliksabitid": guncellendi.stokozelliksabitid,
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      load(_irsaliyeId!);
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
  Future<void> _silKalem(IrsaliyehareketDto k) async {
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
      await service.deleteAlisHareket(token, k.id!);
      if (!mounted) return;
      load(_irsaliyeId!);
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
                    final kalemler = fatura!.irsaliyehareket;
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
                final satirIskonto = (fatura!.irsaliyehareket).fold<double>(
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
    final taslak = (fatura!.belgedurum ?? 0) == 0;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text("İşlemler",
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _scheme.onSurfaceVariant)),
          ),
          _menuItem(Icons.edit_outlined, "İrsaliyeyi Düzenle", _scheme.primary,
              () {
            Navigator.pop(context);
            _duzenle();
          }),
          // Belge durum: taslaksa tamamla, tamamlandıysa taslağa çek
          taslak
              ? _menuItem(Icons.check_circle_outline_rounded, "Belgeyi Tamamla",
                  Color(0xFF2E7D32), () {
                  Navigator.pop(context);
                  _belgeDurumDegistir(1);
                })
              : _menuItem(
                  Icons.undo_rounded, "Belgeyi Taslağa Çek", _scheme.primary,
                  () {
                  Navigator.pop(context);
                  _belgeDurumDegistir(0);
                }),
          _menuItem(
              Icons.picture_as_pdf_outlined, "PDF Yazdır", _scheme.primary, () {
            Navigator.pop(context);
          }),
          _menuItem(
              Icons.share_outlined, "PDF Paylaş", _scheme.onSurfaceVariant, () {
            Navigator.pop(context);
          }),
          Divider(height: 1, indent: 16, endIndent: 16),
          _menuItem(
              Icons.delete_outline_rounded, "İrsaliyeyi Sil", _scheme.error,
              () {
            Navigator.pop(context);
            _silOnay();
          }),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _menuItem(
      IconData icon, String title, Color color, VoidCallback onTap) {
    if (!ActionAccess.allowed([502], title,
        allowChanges: fatura?.belgedurum == 0)) return const SizedBox.shrink();

    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title,
          style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.w600,
              color: color == _scheme.onSurfaceVariant ? _primary : color,
              fontSize: 14)),
      trailing: Icon(Icons.chevron_right_rounded,
          color: _scheme.outlineVariant, size: 20),
      onTap: onTap,
    );
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
                          modules: [502],
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
      await service.alisBelgeDurumGuncelle(token, fatura!.id!, yeniDurum);
      if (!mounted) return;
      Navigator.of(context).pop(); // loading kapat
      if (!mounted) return;
      Navigator.of(context).pop(true); // listeye dön + yenile
      if (taslakaMi) {
        UiFeedback.showWarning(context, "Fatura taslağa alındı");
      } else {
        UiFeedback.showUpdated(context, "Fatura tamamlandı");
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showError(context, "Hata: $e");
    }
  }

  // ===================== PORTALA GÖNDER =====================

  Future<void> _duzenle() async {
    if (_irsaliyeId == null) return;
    try {
      final result = await Navigator.push(
        context,
        PermissionMaterialPageRoute(
            builder: (_) => AlisIrsaliyeEklePage(irsaliyeId: _irsaliyeId)),
      );
      if (result != null && mounted) load(_irsaliyeId!);
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
              Text("İrsaliyeyi Sil",
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
                          modules: [502],
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
      await service.removeAlisWithItems(token, fatura!.id!);
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
