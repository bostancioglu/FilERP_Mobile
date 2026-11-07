import 'package:FilERP/widgets/permission_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../../widgets/erp_ui.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/finans/kasa_islem_service.dart';
import '../../../models/entities/finans/kasa_islem/kasahareket_dto.dart';
import '../../../helpers/response.dart';
import '../../../widgets/yetki_hatasi_widget.dart';
import 'kasahareket_ekle_page.dart';

const _kGreen = Color(0xFF2E7D32);

bool _isFX(String? birim) =>
    birim != null && birim.isNotEmpty && birim != 'TL' && birim != '₺';

final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');
final _dateFmt = DateFormat('dd.MM.yyyy');

const _islemTipiAdlari = {
  1: 'Cari',
  2: 'Banka',
  3: 'Kasa Transfer',
  4: 'Devir',
  5: 'Tahsilat',
  6: 'Ödeme',
  7: 'Masraf',
};

/// Bir kasaya ait hareket listesi — kasa son durum raporundan
/// (veya kasa işlemleri listesinden) bir kasaya tıklanınca açılır.
class KasahareketListePage extends StatefulWidget {
  final int kasaId;
  final String kasaAdi;
  final String? kasaKodu;

  const KasahareketListePage({
    super.key,
    required this.kasaId,
    required this.kasaAdi,
    this.kasaKodu,
  });

  @override
  State<KasahareketListePage> createState() => _KasahareketListePageState();
}

class _KasahareketListePageState extends State<KasahareketListePage> {
  Color get _kRed => Theme.of(context).colorScheme.primary;
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  List<KasahareketDto> _hareketler = [];
  bool _loading = true;
  bool _yetkiHatasi = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _yetkiHatasi = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final data =
          await KasaIslemService().getKasahareketByKasaid(token, widget.kasaId);
      data.sort((a, b) =>
          (b.Tarih ?? DateTime(1900)).compareTo(a.Tarih ?? DateTime(1900)));
      if (!mounted) return;
      setState(() {
        _hareketler = data;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      if (e is YetkiHatasi) {
        setState(() {
          _yetkiHatasi = true;
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
        debugPrint("Kasa Hareket Listesi Hatası: $e");
      }
    }
  }

  double get _toplamGiris => _hareketler
      .where((h) => h.Giriscikis == 1)
      .fold(0.0, (sum, h) => sum + (h.Tutar ?? 0.0));

  double get _toplamCikis => _hareketler
      .where((h) => h.Giriscikis == 2)
      .fold(0.0, (sum, h) => sum + (h.Tutar ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      appBar: _buildAppBar(),
      body: _yetkiHatasi
          ? YetkiHatasiWidget()
          : _loading
              ? Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (_hareketler.isNotEmpty) _buildOzetKarti(),
                    Expanded(child: _buildList()),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return ErpPageAppBar(
      context: context,
      backgroundColor: _scheme.surface,
      foregroundColor: _scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.kasaAdi,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _scheme.onSurface)),
          Text(
            widget.kasaKodu != null
                ? "Kasa Hareketleri • ${widget.kasaKodu}"
                : "Kasa Hareketleri",
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                color: _scheme.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        IconButton(
          tooltip: "Yenile",
          icon: Icon(Icons.refresh_rounded, color: _scheme.onSurface),
          onPressed: _load,
        ),
      ],
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: _scheme.surfaceContainerLow),
      ),
    );
  }

  Widget _buildOzetKarti() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: .015),
              blurRadius: 10,
              offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
              child: _ozetItem("Tahsil", _toplamGiris, _kGreen,
                  Icons.arrow_downward_rounded)),
          Container(width: 1, height: 34, color: _scheme.outlineVariant),
          Expanded(
              child: _ozetItem(
                  "Tediye", _toplamCikis, _kRed, Icons.arrow_upward_rounded)),
        ],
      ),
    );
  }

  Widget _ozetItem(String label, double tutar, Color color, IconData icon) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: color),
            SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: _scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ],
        ),
        SizedBox(height: 4),
        Text(_moneyFmt.format(tutar),
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }

  Widget _buildList() {
    if (_hareketler.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: _hareketler.length,
      itemBuilder: (context, i) => _buildCard(_hareketler[i]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: _scheme.outlineVariant),
          SizedBox(height: 16),
          Text("Bu kasaya ait hareket bulunamadı",
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  String? _karsiTaraf(KasahareketDto h) {
    switch (h.Islemtipi) {
      case 1:
        return h.IslemcariAd;
      case 2:
        return h.IslembankahesapAd;
      case 3:
        return h.IslemkasaAd;
      case 7:
        return h.IslemmasrafAd;
      default:
        return null;
    }
  }

  Widget _buildCard(KasahareketDto h) {
    final incoming = h.Giriscikis == 1;
    final type = _islemTipiAdlari[h.Islemtipi] ?? '-';
    final other = _karsiTaraf(h);
    final card = ErpFinanceCard(
      title: other?.isNotEmpty == true ? other! : type,
      icon: incoming ? Icons.south_west_rounded : Icons.north_east_rounded,
      metadata: [
        h.Tarih == null ? '-' : _dateFmt.format(h.Tarih!),
        type,
        h.Belgeserino ?? ''
      ],
      amount: '${incoming ? '+' : '-'}${_moneyFmt.format(h.Tutar ?? 0)} ₺',
      amountColor: incoming ? _kGreen : _kRed,
      secondaryAmount: _isFX(h.DovizBirim) && h.Doviztutar != null
          ? '${incoming ? '+' : '-'}${_moneyFmt.format(h.Doviztutar)} ${h.DovizBirim}'
          : null,
      onTap: () async {
        final result = await Navigator.push(
            context,
            PermissionMaterialPageRoute(
                builder: (_) => KasahareketEklePage(editHareket: h)));
        if (result == true && mounted) _load();
      },
    );
    return card;
  }
}
