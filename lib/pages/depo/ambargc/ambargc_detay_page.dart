import '../../../helpers/warehouse_line_fields.dart';
import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../helpers/ui_feedback.dart';
import '../../../helpers/belge_durum_helper.dart';
import '../../../helpers/number_format_helper.dart';
import '../../../helpers/giriscikis_couples.dart';
import '../../../helpers/islemyeri_couples.dart';
import '../../../models/entities/depo/ambargc_dto.dart';
import '../../../models/entities/depo/ambargchareket_dto.dart';
import '../../../models/entities/stok/stok_list_dto.dart';
import '../../../models/entities/depo/depo_dto.dart';
import '../../../models/entities/proje/proje_dto.dart';
import '../../../services/depo/ambargc/ambargc_service.dart';
import '../../../services/stok/stok_service.dart';
import '../../../services/depo/depo_service.dart';
import '../../../services/proje/proje_service.dart';
import '../../../widgets/ambargc/ambargc_kalem_form_sheet.dart';
import 'ambargc_ekle_page.dart';

class AmbargcDetayPage extends StatefulWidget {
  const AmbargcDetayPage({super.key});

  @override
  State<AmbargcDetayPage> createState() => _AmbargcDetayPageState();
}

class _AmbargcDetayPageState extends State<AmbargcDetayPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.onSurface;
  Color get _accent => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;

  String? _ambargcId;
  AmbargcDto? _ambargc;
  bool _loading = false;

  List<StokListDto> _stoklar = [];
  List<DepoDto> _depolar = [];
  List<ProjeDto> _projeler = [];

  final _dateFmt = DateFormat('dd.MM.yyyy');
  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final id = ModalRoute.of(context)?.settings.arguments as String?;
      if (id != null) {
        _ambargcId = id;
        _load(id);
      }
    });
  }

  Future<void> _load(String id) async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final subeId = prefs.getInt("sube_id") ?? 0;
      final ambargc = await AmbargcService().getById(token, id);
      List<StokListDto> stoklar = [];
      List<DepoDto> depolar = [];
      List<ProjeDto> projeler = [];
      try {
        stoklar = await StokService().getStokList(token);
      } catch (_) {}
      try {
        depolar = await DepoService().getAllBySubeId(token, subeId);
      } catch (_) {}
      try {
        projeler = (await ProjeService().getProjeList(token))
            .where((p) => p.tur == 3)
            .toList();
      } catch (_) {}
      if (!mounted) return;
      setState(() {
        _ambargc = ambargc;
        _stoklar = stoklar;
        _depolar = depolar;
        _projeler = projeler;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        UiFeedback.showError(context, e.toString());
      }
    }
  }

  String _fmtDate(DateTime? d) => d == null ? '-' : _dateFmt.format(d);

  // ─── BELGE DURUM ─────────────────────────────────────────
  Future<void> _belgeDurumDegistir(int yeniDurum) async {
    if (_ambargcId == null) return;
    final taslakaMi = yeniDurum == 0;
    final onay = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
            padding: EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: taslakaMi
                          ? _scheme.primary.withValues(alpha: .08)
                          : Color(0xFFE8F5E9)),
                  child: Icon(
                      taslakaMi
                          ? Icons.undo_rounded
                          : Icons.check_circle_outline_rounded,
                      size: 36,
                      color: taslakaMi ? _scheme.primary : Color(0xFF2E7D32))),
              SizedBox(height: 20),
              Text(taslakaMi ? "Taslağa Çek" : "Belgeyi Tamamla",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 18,
                      fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Text(
                  taslakaMi
                      ? "${_ambargc?.belgeserino ?? 'Bu kayıt'} taslak durumuna alınacak."
                      : "${_ambargc?.belgeserino ?? 'Bu kayıt'} tamamlandı olarak işaretlenecek.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: _scheme.onSurfaceVariant,
                      height: 1.5)),
              SizedBox(height: 24),
              Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 13),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12))),
                        child: Text("Vazgeç"))),
                SizedBox(width: 12),
                Expanded(
                    child: PermissionAction(
                        modules: [1301],
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
                                elevation: 0),
                            child: Text(taslakaMi ? "Taslağa Çek" : "Tamamla",
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontWeight: FontWeight.bold))))),
              ]),
            ])),
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
                  ])),
            )));
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await AmbargcService().belgeDurumGuncelle(token, _ambargcId!, yeniDurum);
      if (!mounted) return;
      Navigator.of(context).pop();
      taslakaMi
          ? UiFeedback.showWarning(context, "Taslağa alındı")
          : UiFeedback.showUpdated(context, "Tamamlandı");
      _load(_ambargcId!);
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      UiFeedback.showError(context, "Hata: $e");
    }
  }

  // ─── SİL ─────────────────────────────────────────────────
  Future<void> _sil() async {
    if (_ambargcId == null) return;
    final confirm = await UiFeedback.confirm(context,
        title: "Sil",
        message:
            "${_ambargc?.belgeserino ?? 'Bu kayıt'} silinecek. Emin misiniz?",
        destructive: true);
    if (confirm != true || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await AmbargcService().removeWithItems(token, _ambargcId!);
      if (mounted) {
        UiFeedback.showDeleted(context, "Silindi");
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) UiFeedback.showError(context, e.toString());
    }
  }

  // ─── KALEM DÜZENLE ───────────────────────────────────────
  Future<void> _editKalem(AmbargchareketDto k) async {
    final kopya = AmbargchareketDto()
      ..id = k.id
      ..ambargcid = k.ambargcid
      ..stokid = k.stokid
      ..stokozelliksabitid = k.stokozelliksabitid
      ..stokozelliksabit = k.stokozelliksabit
      ..dovizfiyat = k.dovizfiyat
      ..miktar2 = k.miktar2
      ..depoadresid = k.depoadresid
      ..tarih = k.tarih
      ..stok = k.stok
      ..depoid = k.depoid
      ..olcubrid = k.olcubrid
      ..olcubr = k.olcubr
      ..projeid = k.projeid
      ..miktar = k.miktar
      ..fiyat = k.fiyat
      ..tutar = k.tutar
      ..aciklama = k.aciklama;

    final guncellendi = await showAmbargcKalemForm(context,
        kalem: kopya,
        stoklar: _stoklar,
        projeler: _projeler,
        depolar: _depolar,
        dovizli: (_ambargc?.dovizid ?? 1) != 1,
        kur: _ambargc?.kur ?? 0);
    if (guncellendi == null || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await AmbargcService().updateHareket(token,
          guncellendi.toWarehouseJson(guncellendi.ambargcid!, includeId: true));
      if (mounted) {
        UiFeedback.showUpdated(context, "Kalem güncellendi");
        _load(_ambargcId!);
      }
    } catch (e) {
      if (mounted) UiFeedback.showError(context, e.toString());
    }
  }

  // ─── KALEM SİL ───────────────────────────────────────────
  Future<void> _deleteKalem(AmbargchareketDto k) async {
    final confirm = await UiFeedback.confirm(context,
        title: "Kalemi Sil",
        message: "${k.stok?.Ad ?? 'Kalem'} silinecek. Emin misiniz?",
        destructive: true);
    if (confirm != true || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      await AmbargcService().deleteHareket(token, k.id!);
      if (mounted) {
        UiFeedback.showDeleted(context, "Kalem silindi");
        _load(_ambargcId!);
      }
    } catch (e) {
      if (mounted) UiFeedback.showError(context, e.toString());
    }
  }

  // ─── BUILD ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading)
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    final a = _ambargc;
    if (a == null)
      return Scaffold(
          appBar: ErpPageAppBar(
              context: context,
              backgroundColor: _scheme.surface,
              foregroundColor: _scheme.onPrimary),
          body: Center(child: Text("Kayıt bulunamadı")));

    final taslak = (a.belgedurum ?? 0) == 0;
    final durumRenk = BelgeDurumHelper.renkById(a.belgedurum);
    final durumAd = BelgeDurumHelper.adById(a.belgedurum);
    final genelToplam =
        a.ambargchareket.fold(0.0, (s, k) => s + (k.tutar ?? 0));

    return Scaffold(
      backgroundColor: _surface,
      appBar: ErpPageAppBar(
        context: context,
        title: Text(a.belgeserino ?? "Ambar G/Ç",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        actions: [
          PermissionAction(
              modules: [1301],
              access: Access.update,
              child: IconButton(
                icon: Icon(Icons.edit_outlined),
                onPressed: () async {
                  final result = await Navigator.push(
                      context,
                      PermissionMaterialPageRoute(
                          builder: (_) =>
                              AmbargcEklePage(ambargcId: _ambargcId)));
                  if (result == true && mounted && _ambargcId != null)
                    _load(_ambargcId!);
                },
              )),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'tamamla') _belgeDurumDegistir(taslak ? 1 : 0);
              if (v == 'sil') _sil();
            },
            itemBuilder: (_) => [
              if (AuthorizationSession.instance.any([1301], Access.create))
                PopupMenuItem(
                    value: 'tamamla',
                    child: Row(children: [
                      Icon(
                          taslak
                              ? Icons.check_circle_outline
                              : Icons.undo_rounded,
                          color: taslak ? Color(0xFF2E7D32) : _scheme.primary,
                          size: 20),
                      SizedBox(width: 8),
                      Text(taslak ? "Belgeyi Tamamla" : "Taslağa Çek"),
                    ])),
              if (AuthorizationSession.instance.any([1301], Access.delete))
                PopupMenuItem(
                    value: 'sil',
                    child: Row(children: [
                      Icon(Icons.delete_outline,
                          color: _scheme.error, size: 20),
                      SizedBox(width: 8),
                      Text("Sil",
                          style: TextStyle(
                              fontFamily: 'Roboto', color: _scheme.error)),
                    ])),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _load(_ambargcId!),
        color: _accent,
        child: ListView(
          padding: EdgeInsets.all(12),
          children: [
            // ─ Üst Bilgi Kartı ─────────────────────────────
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: _scheme.surface,
                  borderRadius: BorderRadius.circular(
                      ErpDesignStyle.modern(context) ? 18 : 12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: Offset(0, 3))
                  ]),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Belge no + durum
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(a.belgeserino ?? '-',
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: _primary)),
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                                color:
                                    BelgeDurumHelper.arkaPlanById(a.belgedurum),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: durumRenk.withOpacity(0.4))),
                            child: Text(durumAd,
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: durumRenk)),
                          ),
                        ]),
                    Divider(height: 20),
                    _infoRow(Icons.swap_vert_outlined, "Giriş/Çıkış",
                        GiriscikisCouples.adByValue(a.giriscikis)),
                    _infoRow(Icons.location_on_outlined, "İşlem Yeri",
                        IslemyeriCouples.adByValue(a.islemyeri)),
                    if (a.masraf != null)
                      _infoRow(Icons.account_balance_outlined, "Masraf Merkezi",
                          "${a.masraf!.kod ?? ''} - ${a.masraf!.ad ?? ''}"),
                    if (a.plasiyer != null)
                      _infoRow(Icons.person_outline, "Plasiyer",
                          a.plasiyer!.Adsoyad ?? ''),
                    if (a.proje != null)
                      _infoRow(Icons.folder_outlined, "Proje",
                          "${a.proje!.kod ?? ''} - ${a.proje!.ad ?? ''}"),
                    _infoRow(Icons.calendar_today_outlined, "Tarih",
                        _fmtDate(a.tarih)),
                    if (a.aciklama != null && a.aciklama!.isNotEmpty)
                      _infoRow(Icons.notes_outlined, "Açıklama", a.aciklama!),
                  ]),
            ),
            SizedBox(height: 16),

            // ─ Genel Toplam ─────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: _scheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.orange.withOpacity(0.3),
                      blurRadius: 12,
                      offset: Offset(0, 6))
                ],
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("GENEL TOPLAM",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            color: _scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            letterSpacing: 1)),
                    Text("${_moneyFmt.format(genelToplam)} ₺",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            color: _scheme.onSurface,
                            fontSize: 22,
                            fontWeight: FontWeight.w900)),
                  ]),
            ),
            SizedBox(height: 16),

            // ─ Kalemler ─────────────────────────────────────
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text("Ambar G/Ç Kalemleri",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _scheme.onSurfaceVariant)),
              Text("${a.ambargchareket.length} kalem",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: _scheme.onSurfaceVariant)),
            ]),
            SizedBox(height: 10),

            if (a.ambargchareket.isEmpty)
              Container(
                padding: EdgeInsets.all(32),
                decoration: BoxDecoration(
                    color: _scheme.surface,
                    borderRadius: BorderRadius.circular(
                        ErpDesignStyle.modern(context) ? 18 : 12)),
                child: Center(
                    child: Text("Kalem bulunamadı",
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            color: _scheme.onSurfaceVariant,
                            fontSize: 14))),
              )
            else
              ...a.ambargchareket.map((k) => Container(
                    margin: EdgeInsets.only(bottom: 8),
                    decoration: BoxDecoration(
                        color: _scheme.surface,
                        borderRadius: BorderRadius.circular(
                            ErpDesignStyle.modern(context) ? 18 : 12),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 6,
                              offset: Offset(0, 2))
                        ]),
                    child: ListTile(
                      contentPadding: EdgeInsets.fromLTRB(14, 8, 8, 8),
                      title: Text("${k.stok?.Kod ?? ''} - ${k.stok?.Ad ?? '-'}",
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                      subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 4),
                            Text(
                                "${NumberFormatHelper.format(k.miktar ?? 0)} ${k.olcubr?.Ad ?? ''}"
                                "  ×  ${NumberFormatHelper.format(k.fiyat ?? 0)} ₺",
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    color: _scheme.onSurfaceVariant)),
                            Text(
                                "Tutar: ${NumberFormatHelper.format(k.tutar ?? 0)} ₺",
                                style: TextStyle(
                                    fontFamily: 'Roboto',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _primary)),
                          ]),
                      trailing: !taslak
                          ? null
                          : Row(mainAxisSize: MainAxisSize.min, children: [
                              PermissionAction(
                                  modules: [1301],
                                  access: Access.update,
                                  child: IconButton(
                                      icon: Icon(Icons.edit_outlined,
                                          size: 20, color: _scheme.primary),
                                      onPressed: () => _editKalem(k))),
                              PermissionAction(
                                  modules: [1301],
                                  access: Access.delete,
                                  child: IconButton(
                                      icon: Icon(Icons.delete_outline,
                                          size: 20, color: _scheme.error),
                                      onPressed: () => _deleteKalem(k))),
                            ]),
                    ),
                  )),
            SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) => Padding(
        padding: EdgeInsets.symmetric(vertical: 5),
        child: Row(children: [
          Icon(icon, size: 16, color: _scheme.onSurfaceVariant),
          SizedBox(width: 10),
          Text("$label:",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          SizedBox(width: 6),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis)),
        ]),
      );
}
