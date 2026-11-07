import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../models/entities/finans/kasa_islem/kasahareket_dto.dart';
import '../../../models/entities/fatura/fatura_list_dto.dart';
import '../../../models/entities/irsaliye/irsaliye_dto.dart';
import '../../../models/entities/siparis/siparis_dto.dart';
import '../../../models/entities/depo/dat_dto.dart';
import '../../../services/finans/kasa_tanim_service.dart';
import '../../../services/finans/kasa_islem_service.dart';
import '../../../services/fatura/fatura_service.dart';
import '../../../services/irsaliye/irsaliye_service.dart';
import '../../../services/siparis/siparis_service.dart';
import '../../../services/depo/dat/dat_service.dart';
import '../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../helpers/plasiyer_kasa_helper.dart';
import '../../../helpers/ui_feedback.dart';
import '../../irsaliye/irsaliye_detay_page.dart';
import '../../siparis/Satis/satissiparis_detay_page.dart';
import '../../depo/dat/dat_ekle_page.dart';

class GunlukOzetPage extends StatefulWidget {
  const GunlukOzetPage({super.key});

  @override
  State<GunlukOzetPage> createState() => _GunlukOzetPageState();
}

class _GunlukOzetPageState extends State<GunlukOzetPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;
  Color get _kBlue => _scheme.primary;
  Color get _kBorder => _scheme.outlineVariant;
  Color get _kGreen => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFF6EE7B7)
      : Color(0xFF16704A);
  bool _loading = true;

  late DateTime _tarih1;
  late DateTime _tarih2;

  List<KasahareketDto> _kasaHareketler = [];
  List<FaturaListDto> _faturalar = [];
  List<IrsaliyeDto> _irsaliyeler = [];
  List<SiparisDto> _siparisler = [];
  List<DatDto> _datlar = [];

  final _dateFmt = DateFormat('dd.MM.yyyy');
  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');

  double get _kasaTahsilat => _kasaHareketler
      .where((h) => h.Giriscikis == 1)
      .fold(0.0, (s, e) => s + (e.Tutar ?? 0));
  double get _kasaOdeme => _kasaHareketler
      .where((h) => h.Giriscikis == 2)
      .fold(0.0, (s, e) => s + (e.Tutar ?? 0));
  double get _faturaToplam =>
      _faturalar.fold(0.0, (s, e) => s + (e.genelToplam ?? 0));
  double get _siparisToplam =>
      _siparisler.fold(0.0, (s, e) => s + (e.geneltoplam ?? 0));

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tarih1 = DateTime(now.year, now.month, now.day);
    _tarih2 = now;
    _yukle();
  }

  /// Bir kaynağın hata vermesi (yetki yok, ağ vb.) diğerlerini engellemesin:
  /// hata olursa o kaynak için boş liste (yani 0) döner.
  Future<List<T>> _guvenli<T>(Future<List<T>> Function() getir) async {
    try {
      return await getir();
    } catch (e) {
      debugPrint('Günlük özet kaynağı alınamadı: $e');
      return <T>[];
    }
  }

  Future<void> _yukle() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final bitisSonu =
          DateTime(_tarih2.year, _tarih2.month, _tarih2.day, 23, 59, 59);
      bool inRange(DateTime? t) =>
          t != null && !t.isBefore(_tarih1) && !t.isAfter(bitisSonu);

      final sonuclar = await Future.wait([
        // Kasa — tüm kasaların hareketleri (her kasa ayrı korunur); plasiyer kullanıcıda yalnızca plasiyer kasası
        _guvenli<KasahareketDto>(() async {
          var kasalar = await KasaTanimService().getAllWithoutAuth(token);
          final kp = await KullaniciPlasiyerHelper.getir();
          if (kp.kilitli) {
            final kendi = await PlasiyerKasaHelper.getir(token, kp.plasiyerid,
                mevcutKasalar: kasalar, kilitli: true);
            if (kendi?.Id != null)
              kasalar = kasalar.where((k) => k.Id == kendi!.Id).toList();
          }
          final liste = <KasahareketDto>[];
          for (final k in kasalar) {
            if (k.Id == null) continue;
            final h = await _guvenli<KasahareketDto>(
                () => KasaIslemService().getKasahareketByKasaid(token, k.Id!));
            liste.addAll(h.where((x) => inRange(x.Tarih)));
          }
          return liste;
        }),
        _guvenli<FaturaListDto>(() async =>
            (await FaturaService().getSatisFaturaList(token))
                .where((f) => inRange(f.tarih) && f.belgedurum == 1)
                .toList()),
        _guvenli<IrsaliyeDto>(() async =>
            (await IrsaliyeService().getList(token))
                .where((i) => inRange(i.tarih) && i.belgedurum == 1)
                .toList()),
        _guvenli<SiparisDto>(() async =>
            (await SiparisService().getSatisList(token))
                .where((s) => inRange(s.tarih) && s.belgedurum == 1)
                .toList()),
        _guvenli<DatDto>(() async => (await DatService().getList(token))
            .where((d) => inRange(d.tarih) && d.belgedurum == 1)
            .toList()),
      ]);

      final kasaHareketler = sonuclar[0] as List<KasahareketDto>;
      final faturalar = sonuclar[1] as List<FaturaListDto>;
      final irsaliyeler = sonuclar[2] as List<IrsaliyeDto>;
      final siparisler = sonuclar[3] as List<SiparisDto>;
      final datlar = sonuclar[4] as List<DatDto>;

      if (!mounted) return;
      setState(() {
        _kasaHareketler = kasaHareketler
          ..sort((a, b) =>
              (b.Tarih ?? DateTime(0)).compareTo(a.Tarih ?? DateTime(0)));
        _faturalar = faturalar
          ..sort((a, b) =>
              (b.tarih ?? DateTime(0)).compareTo(a.tarih ?? DateTime(0)));
        _irsaliyeler = irsaliyeler
          ..sort((a, b) =>
              (b.tarih ?? DateTime(0)).compareTo(a.tarih ?? DateTime(0)));
        _siparisler = siparisler
          ..sort((a, b) =>
              (b.tarih ?? DateTime(0)).compareTo(a.tarih ?? DateTime(0)));
        _datlar = datlar
          ..sort((a, b) =>
              (b.tarih ?? DateTime(0)).compareTo(a.tarih ?? DateTime(0)));
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        UiFeedback.showError(context, e.toString());
      }
    }
  }

  Future<void> _tarihSec(bool ilkTarih) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: ilkTarih ? _tarih1 : _tarih2,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (ilkTarih) {
        _tarih1 = picked;
      } else {
        _tarih2 = picked;
      }
    });
    _yukle();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        title: Text("Günlük Özet",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        actions: [
          IconButton(
              icon: Icon(Icons.refresh_rounded),
              onPressed: _yukle,
              tooltip: "Yenile"),
        ],
      ),
      body: Column(children: [
        _buildTarihBar(),
        Expanded(
          child: _loading
              ? Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                  onRefresh: _yukle,
                  child: ListView(
                    padding: EdgeInsets.all(12),
                    children: [
                      _ozetKart(
                        title: "Kasa",
                        icon: Icons.point_of_sale_rounded,
                        color: _kBlue,
                        adet: _kasaHareketler.length,
                        altBilgi:
                            "Tahsilat ${_moneyFmt.format(_kasaTahsilat)} ₺ • Ödeme ${_moneyFmt.format(_kasaOdeme)} ₺",
                        onTap:
                            _kasaHareketler.isEmpty ? null : _kasaDetayGoster,
                      ),
                      SizedBox(height: 10),
                      _ozetKart(
                        title: "Satış Faturası",
                        icon: Icons.receipt_long_rounded,
                        color: _kGreen,
                        adet: _faturalar.length,
                        altBilgi: "Toplam ${_moneyFmt.format(_faturaToplam)} ₺",
                        onTap: _faturalar.isEmpty ? null : _faturaDetayGoster,
                      ),
                      SizedBox(height: 10),
                      _ozetKart(
                        title: "Satış İrsaliyesi",
                        icon: Icons.local_shipping_outlined,
                        color: _scheme.primary,
                        adet: _irsaliyeler.length,
                        altBilgi: "$_irsaliyeAdet belge",
                        onTap:
                            _irsaliyeler.isEmpty ? null : _irsaliyeDetayGoster,
                      ),
                      SizedBox(height: 10),
                      _ozetKart(
                        title: "Satış Siparişi",
                        icon: Icons.shopping_cart_outlined,
                        color: _scheme.primary,
                        adet: _siparisler.length,
                        altBilgi:
                            "Toplam ${_moneyFmt.format(_siparisToplam)} ₺",
                        onTap: _siparisler.isEmpty ? null : _siparisDetayGoster,
                      ),
                      SizedBox(height: 10),
                      _ozetKart(
                        title: "Depolar Arası Transfer",
                        icon: Icons.swap_horiz_rounded,
                        color: _kGreen,
                        adet: _datlar.length,
                        altBilgi: "$_datAdet transfer",
                        onTap: _datlar.isEmpty ? null : _datDetayGoster,
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
        ),
      ]),
    );
  }

  int get _irsaliyeAdet => _irsaliyeler.length;
  int get _datAdet => _datlar.length;

  Widget _buildTarihBar() {
    return Container(
      color: _scheme.surface,
      padding: EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Row(children: [
        Expanded(
            child: _tarihKutusu("Başlangıç", _tarih1, () => _tarihSec(true))),
        SizedBox(width: 10),
        Expanded(child: _tarihKutusu("Bitiş", _tarih2, () => _tarihSec(false))),
      ]),
    );
  }

  Widget _tarihKutusu(String label, DateTime deger, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: _scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined,
              size: 14, color: _scheme.onSurfaceVariant),
          SizedBox(width: 8),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: _scheme.onSurfaceVariant)),
              Text(_dateFmt.format(deger),
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      color: _scheme.onSurface,
                      fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
      ),
    );
  }

  Widget _ozetKart({
    required String title,
    required IconData icon,
    required Color color,
    required int adet,
    required String altBilgi,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: _scheme.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder),
          ),
          child: Row(children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: _kDark)),
                    SizedBox(height: 2),
                    Text(altBilgi,
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12,
                            color: _scheme.onSurfaceVariant)),
                  ]),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text("$adet",
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ),
            SizedBox(width: 6),
            Icon(Icons.chevron_right_rounded,
                color: _scheme.outlineVariant, size: 18),
          ]),
        ),
      ),
    );
  }

  // ── Detay listeleri ────────────────────────────────────────────────────

  void _detaySheetGoster(String title, List<Widget> rows) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: false,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scrollCtrl) => Column(children: [
          Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                  color: _scheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(title,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _kDark)),
          ),
          SizedBox(height: 8),
          Expanded(
            child: ListView(
                controller: scrollCtrl,
                padding: EdgeInsets.all(12),
                children: rows),
          ),
        ]),
      ),
    );
  }

  Widget _satirKart(
          {required String baslik,
          required String altBilgi,
          String? tutar,
          VoidCallback? onTap}) =>
      Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Material(
            color: _scheme.surface,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: _kBorder)),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
                onTap: onTap,
                child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                                child: Text(baslik,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600))),
                            if (onTap != null)
                              Icon(Icons.chevron_right_rounded,
                                  size: 18, color: _scheme.onSurfaceVariant)
                          ]),
                          if (altBilgi.isNotEmpty)
                            Text(altBilgi,
                                style: TextStyle(
                                    fontSize: 11,
                                    color: _scheme.onSurfaceVariant)),
                          if (tutar != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text(tutar,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700))),
                        ]))),
          ));

  void _kasaDetayGoster() {
    _detaySheetGoster(
        "Kasa Hareketleri",
        _kasaHareketler.map((h) {
          final yon = h.Giriscikis == 1 ? "Tahsilat" : "Ödeme";
          return _satirKart(
            baslik: "$yon — ${h.Aciklama ?? ''}",
            altBilgi: h.Tarih != null ? _dateFmt.format(h.Tarih!) : '',
            tutar: '${_moneyFmt.format(h.Tutar ?? 0)} ₺',
          );
        }).toList());
  }

  void _faturaDetayGoster() {
    _detaySheetGoster(
        "Satış Faturaları",
        _faturalar.map((f) {
          return _satirKart(
            baslik: f.belgeserino ?? f.belgeno ?? '-',
            altBilgi:
                "${f.cari?.Ad ?? '-'} • ${f.tarih != null ? _dateFmt.format(f.tarih!) : ''}",
            tutar: '${_moneyFmt.format(f.genelToplam ?? 0)} ₺',
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.pushNamed(
                  context, "/satis-fatura-detay",
                  arguments: f.id);
              if (result != null && mounted) _yukle();
            },
          );
        }).toList());
  }

  void _irsaliyeDetayGoster() {
    _detaySheetGoster(
        "Satış İrsaliyeleri",
        _irsaliyeler.map((i) {
          return _satirKart(
            baslik: i.belgeserino ?? i.belgeno ?? '-',
            altBilgi:
                "${i.cari?.Ad ?? '-'} • ${i.tarih != null ? _dateFmt.format(i.tarih!) : ''}",
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                  context,
                  PermissionMaterialPageRoute(
                      builder: (_) => IrsaliyeDetayPage(),
                      settings: RouteSettings(arguments: i.id)));
              if (result != null && mounted) _yukle();
            },
          );
        }).toList());
  }

  void _siparisDetayGoster() {
    _detaySheetGoster(
        "Satış Siparişleri",
        _siparisler.map((s) {
          return _satirKart(
            baslik: s.belgeserino ?? '-',
            altBilgi:
                "${s.cari?.Ad ?? '-'} • ${s.tarih != null ? _dateFmt.format(s.tarih!) : ''}",
            tutar: '${_moneyFmt.format(s.geneltoplam ?? 0)} ₺',
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                  context,
                  PermissionMaterialPageRoute(
                      builder: (_) => SatisSiparisDetayPage(),
                      settings: RouteSettings(arguments: s.id)));
              if (result != null && mounted) _yukle();
            },
          );
        }).toList());
  }

  void _datDetayGoster() {
    _detaySheetGoster(
        "Depolar Arası Transfer",
        _datlar.map((d) {
          return _satirKart(
            baslik: d.belgeserino ?? d.belgeno ?? '-',
            altBilgi:
                "${d.sube?.ad ?? '-'} → ${d.gidecegisube?.ad ?? '-'} • ${d.tarih != null ? _dateFmt.format(d.tarih!) : ''}",
            onTap: () async {
              Navigator.pop(context);
              final result = await Navigator.push(
                  context,
                  PermissionMaterialPageRoute(
                      builder: (_) => DatEklePage(datId: d.id)));
              if (result != null && mounted) _yukle();
            },
          );
        }).toList());
  }
}
