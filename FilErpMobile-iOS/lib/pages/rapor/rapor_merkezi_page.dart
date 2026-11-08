import 'package:FilERP/services/auth/menu_access.dart';
import 'package:FilERP/widgets/permission_page.dart';
import 'package:FilERP/widgets/corporate_menu_icon.dart';
import '../../theme/app_theme.dart';
import '../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';

import '../plasiyer/plasiyer_harita_page.dart';
import 'cari/carihareket_raporu.dart';
import 'genel/gunluk_ozet_page.dart';
import 'kasa/kasa_sondurum_raporu.dart';
import 'kasa/z_raporu.dart';
import 'ortak/rapor_modelleri.dart';
import 'ortak/rapor_sayfasi.dart';
import 'plasiyer/plasiyer_ozeti_page.dart';
import 'rapor_tanimlari.dart';
import 'stok/stokhareket_raporu.dart';

class _Girdi {
  final String no;
  final String baslik;
  final String aciklama;
  final IconData ikon;
  final Color renk;
  final WidgetBuilder? sayfa; // null = yakında
  const _Girdi(
      this.no, this.baslik, this.aciklama, this.ikon, this.renk, this.sayfa);
}

class _Grup {
  final String ad;
  final List<_Girdi> girdiler;
  const _Grup(this.ad, this.girdiler);
}

Widget _rapor(RaporTanim t) => RaporSayfasi(tanim: t);

/// Tüm raporların numaralı, gruplu listesi.
class RaporMerkeziPage extends StatefulWidget {
  const RaporMerkeziPage({super.key});

  @override
  State<RaporMerkeziPage> createState() => _RaporMerkeziPageState();
}

class _RaporMerkeziPageState extends State<RaporMerkeziPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _muted => _scheme.onSurfaceVariant;
  Color get _bg => Theme.of(context).scaffoldBackgroundColor;
  Color get _line => _scheme.outlineVariant;

  String _ara = '';

  late final List<_Grup> _gruplar = [
    _Grup('Plasiyer', [
      _Girdi(
          '',
          'Plasiyer Özeti',
          'Satış, tahsilat, kasa, cari ve araç stok durumu',
          Icons.person_pin_circle_rounded,
          Color(0xFF6366F1),
          (_) => PlasiyerOzetiPage()),
    ]),
    _Grup('Cari', [
      _Girdi(
          '1',
          'Cari Hesap Ekstresi',
          'Cari hareketleri, borç / alacak / bakiye',
          Icons.receipt_long_rounded,
          Color(0xFF6366F1),
          (_) => CariHareketRaporu()),
      _Girdi(
          '2',
          'Cari Borç / Alacak',
          'Carilerin borç, alacak ve bakiyeleri',
          cariBorcAlacakTanim.ikon,
          cariBorcAlacakTanim.renk,
          (_) => _rapor(cariBorcAlacakTanim)),
      const _Girdi('3', 'Cari Vade Raporu', 'Yakında', Icons.event_busy_rounded,
          Color(0xFF9CA3AF), null),
    ]),
    _Grup('Stok', [
      _Girdi(
          '11',
          'Stok Hareket',
          'Giriş / çıkış hareketleri ve bakiye',
          Icons.swap_vert_rounded,
          Color(0xFFF59E0B),
          (_) => StokHareketRaporu()),
      _Girdi(
          '12',
          'Stok Bakiye',
          'Stok ve depo bazında güncel bakiye',
          stokBakiyeTanim.ikon,
          stokBakiyeTanim.renk,
          (_) => _rapor(stokBakiyeTanim)),
    ]),
    _Grup('Fatura', [
      _Girdi(
          '21',
          'Fatura İcmali',
          'Satış ve alış faturaları belge bazında',
          faturaIcmaliTanim.ikon,
          faturaIcmaliTanim.renk,
          (_) => _rapor(faturaIcmaliTanim)),
      _Girdi(
          '22',
          'Fatura Detay',
          'Fatura kalemleri: stok, miktar, tutar',
          faturaDetayTanim.ikon,
          faturaDetayTanim.renk,
          (_) => _rapor(faturaDetayTanim)),
    ]),
    _Grup('Finans', [
      _Girdi('31', 'Çek / Senet', 'Çek ve senet listesi (müşteri / borç)',
          cekSenetTanim.ikon, cekSenetTanim.renk, (_) => _rapor(cekSenetTanim)),
      _Girdi(
          '41',
          'Kasalar Genel Durum',
          'Kasaların güncel bakiyeleri',
          Icons.account_balance_wallet_rounded,
          Color(0xFF0EA5A4),
          (_) => KasaSondurumRaporu()),
      _Girdi(
          '42',
          'Kasa Hareket',
          'Kasa bazında giriş / çıkış hareketleri',
          kasaHareketTanim.ikon,
          kasaHareketTanim.renk,
          (_) => _rapor(kasaHareketTanim)),
      _Girdi(
          '51',
          'Bankalar Genel Durum',
          'Banka hesaplarının güncel bakiyeleri',
          bankaGenelDurumTanim.ikon,
          bankaGenelDurumTanim.renk,
          (_) => _rapor(bankaGenelDurumTanim)),
      _Girdi(
          '52',
          'Banka Hareket',
          'Banka hesabı bazında hareketler',
          bankaHareketTanim.ikon,
          bankaHareketTanim.renk,
          (_) => _rapor(bankaHareketTanim)),
    ]),
    _Grup('Diğer', [
      _Girdi('', 'Z Raporu', 'Kasa gün sonu raporu', Icons.summarize_rounded,
          Color(0xFF14B8A6), (_) => ZRaporuPage()),
      _Girdi('', 'Günlük Özet', 'Günün satış, tahsilat ve kasa özeti',
          Icons.dashboard_rounded, Color(0xFF2F7BFF), (_) => GunlukOzetPage()),
      _Girdi(
          '',
          'Plasiyer Konumları',
          'Plasiyerlerin harita üzerindeki konumları',
          Icons.map_rounded,
          Color(0xFFEF4444),
          (_) => PlasiyerHaritaPage()),
    ]),
  ];

  @override
  Widget build(BuildContext context) {
    final q = _ara.trim().toLowerCase();
    final gorunen = <_Grup>[];
    for (final g in _gruplar) {
      final liste = g.girdiler
          .where((e) =>
              MenuAccess.visible(e.baslik) &&
              (q.isEmpty ||
                  e.baslik.toLowerCase().contains(q) ||
                  e.aciklama.toLowerCase().contains(q) ||
                  e.no == q))
          .toList();
      if (liste.isNotEmpty) gorunen.add(_Grup(g.ad, liste));
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: ErpPageAppBar(
        context: context,
        title: Text('Rapor Merkezi',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, 14, 16, 32),
        children: [
          TextField(
            onChanged: (v) => setState(() => _ara = v),
            decoration: InputDecoration(
              hintText: 'Rapor ara…',
              hintStyle:
                  TextStyle(fontFamily: 'Roboto', color: _muted, fontSize: 14),
              prefixIcon: Icon(Icons.search_rounded, color: _muted),
              filled: true,
              fillColor: _scheme.surface,
              contentPadding: EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none),
            ),
          ),
          if (gorunen.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(
                  child: Text('Eşleşen rapor bulunamadı',
                      style: TextStyle(fontFamily: 'Roboto', color: _muted))),
            ),
          for (final g in gorunen) ...[
            Padding(
              padding: EdgeInsets.fromLTRB(4, 18, 0, 8),
              child: Text(g.ad,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _muted,
                      letterSpacing: 0.1)),
            ),
            Container(
              decoration: BoxDecoration(
                color: _scheme.surface,
                borderRadius: BorderRadius.circular(
                    ErpDesignStyle.modern(context) ? 18 : 16),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 14,
                      offset: Offset(0, 4))
                ],
              ),
              child: Column(children: [
                for (var i = 0; i < g.girdiler.length; i++) ...[
                  _satir(g.girdiler[i],
                      ilk: i == 0, son: i == g.girdiler.length - 1),
                  if (i != g.girdiler.length - 1)
                    Padding(
                        padding: EdgeInsets.only(left: 72),
                        child: Divider(height: 1, color: _line)),
                ],
              ]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _satir(_Girdi e, {required bool ilk, required bool son}) {
    final aktif = e.sayfa != null;
    return Material(
      color: _scheme.surface,
      borderRadius: BorderRadius.vertical(
          top: Radius.circular(ilk ? 16 : 0),
          bottom: Radius.circular(son ? 16 : 0)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: aktif
            ? () => Navigator.push(
                context, PermissionMaterialPageRoute(builder: e.sayfa!))
            : null,
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(children: [
              Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                      color:
                          _scheme.primary.withValues(alpha: aktif ? .07 : .03),
                      borderRadius: BorderRadius.circular(10)),
                  child:
                      CorporateMenuIcon(e.baslik, size: 27, fallback: e.ikon)),
              SizedBox(width: 10),
              if (e.no.isNotEmpty) ...[
                Text(e.no.padLeft(2, '0'),
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: _scheme.onSurfaceVariant)),
                SizedBox(width: 8)
              ],
              Expanded(
                  child: Text(e.baslik,
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: aktif
                              ? _scheme.onSurface
                              : _scheme.onSurfaceVariant))),
              if (aktif)
                Icon(Icons.chevron_right_rounded,
                    size: 19, color: _scheme.onSurfaceVariant)
              else
                Text('Yakında',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 10,
                        color: _scheme.onSurfaceVariant)),
            ])),
      ),
    );
  }
}
