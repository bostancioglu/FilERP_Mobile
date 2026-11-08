import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/finans/kasa_islem_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/finans/kasa_islem/vw_finanskasatoplam_dto.dart';
import '../../../helpers/response.dart';
import '../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../helpers/plasiyer_kasa_helper.dart';
import '../../../widgets/yetki_hatasi_widget.dart';
import '../../../widgets/erp_ui.dart';
import '../../finans/kasa/kasahareket_liste_page.dart';

final _fmt = NumberFormat('#,##0.00', 'tr_TR');

/// Kasalar Son Durum Raporu — VW_Finanskasatoplam görünümü (web'deki
/// Finans/Rapor/Kasa/Sondurum.razor ile aynı veri kaynağı, filtresiz liste).
class KasaSondurumRaporu extends StatefulWidget {
  const KasaSondurumRaporu({super.key});

  @override
  State<KasaSondurumRaporu> createState() => _KasaSondurumRaporuState();
}

class _KasaSondurumRaporuState extends State<KasaSondurumRaporu> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;

  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;
  Color get _kGold => _scheme.primary;
  Color _balanceColor(double value) => value < 0
      ? _scheme.error
      : (Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF6EE7B7)
          : const Color(0xFF16704A));
  List<VwFinanskasatoplamDto> _tumVeri = [];
  List<VwFinanskasatoplamDto> _all = [];
  List<VwFinanskasatoplamDto> _filtered = [];

  // Plasiyer kullanıcı: kendi kasası varsayılan süzgeç
  bool _plasiyerKasaBelirlendi = false;
  int? _plasiyerKasaId;
  String _plasiyerKasaAd = '';
  bool _tumKasalar = false;
  Map<String, String> _dovizAdBirim = {};
  bool _loading = true;
  bool _yetkiHatasi = false;

  final _searchCtrl = TextEditingController();

  String _dovizKisa(String? birim) {
    if (birim == null || birim.isEmpty) return 'TL';
    return _dovizAdBirim[birim] ?? birim;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _yetkiHatasi = false;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString("token_final") ?? "";
      final results = await Future.wait([
        KasaIslemService().getKasaToplam(token),
        DovizService().getDovizler(token).catchError((_) => <DovizDto>[]),
      ]);
      if (!mounted) return;
      final data = results[0] as List<VwFinanskasatoplamDto>;
      final dovizler = results[1] as List;

      // Plasiyer kullanıcıda varsayılan kasa = plasiyerin kasası (istenirse "Tümünü göster")
      if (!_plasiyerKasaBelirlendi) {
        _plasiyerKasaBelirlendi = true;
        final kp = await KullaniciPlasiyerHelper.getir();
        if (kp.kilitli) {
          final kasa = await PlasiyerKasaHelper.getir(token, kp.plasiyerid,
              kilitli: true);
          if (kasa != null && data.any((k) => k.Kasaid == kasa.Id)) {
            _plasiyerKasaId = kasa.Id;
            _plasiyerKasaAd = '${kasa.Kod ?? ''} ${kasa.Ad ?? ''}'.trim();
          }
        }
      }
      final gorunen = (_plasiyerKasaId != null && !_tumKasalar)
          ? data.where((k) => k.Kasaid == _plasiyerKasaId).toList()
          : data;
      if (!mounted) return;
      setState(() {
        _dovizAdBirim = {
          for (final d in dovizler)
            if (d.Ad != null && d.Birim != null)
              d.Ad as String: d.Birim as String
        };
        _tumVeri = data;
        _all = gorunen;
        _filtered = List.from(gorunen);
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
        debugPrint("Kasa Sondurum Raporu Hatası: $e");
      }
    }
  }

  void _search(String text) {
    final s = text.toLowerCase();
    setState(() {
      _filtered = s.isEmpty
          ? List.from(_all)
          : _all.where((k) {
              return (k.Kasakod ?? '').toLowerCase().contains(s) ||
                  (k.Kasaisim ?? '').toLowerCase().contains(s) ||
                  (k.Dovizbirim ?? '').toLowerCase().contains(s);
            }).toList();
    });
  }

  double get _toplamBakiye =>
      _all.fold(0.0, (sum, k) => sum + (k.Bakiyetutar ?? 0.0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: _yetkiHatasi
          ? const YetkiHatasiWidget()
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    if (_all.isNotEmpty) _buildToplamKarti(),
                    if (_plasiyerKasaId != null) _buildPlasiyerKasaSeridi(),
                    _buildSearchBar(),
                    _buildCountHeader(),
                    Expanded(child: _buildList()),
                  ],
                ),
    );
  }

  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        title: Text('Kasalar Genel Durum'),
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        actions: [
          IconButton(
              tooltip: 'Yenile',
              icon: Icon(Icons.refresh_rounded),
              onPressed: _loading ? null : _load)
        ],
      );

  Widget _buildToplamKarti() => Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
        child: Row(children: [
          Expanded(
              child: Text('Toplam Bakiye',
                  style: TextStyle(
                      fontSize: 12, color: _scheme.onSurfaceVariant))),
          Flexible(
              child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text('${_fmt.format(_toplamBakiye)} ₺',
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: _balanceColor(_toplamBakiye))))),
        ]),
      );

  Widget _buildPlasiyerKasaSeridi() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
        decoration: BoxDecoration(
          color: _scheme.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _kGold.withOpacity(0.5)),
        ),
        child: Row(children: [
          Icon(Icons.person_pin_circle_outlined, size: 16, color: _kGold),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _tumKasalar
                  ? 'Tüm kasalar gösteriliyor'
                  : 'Plasiyer kasası: $_plasiyerKasaAd',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: _kDark),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            onPressed: () {
              _tumKasalar = !_tumKasalar;
              _searchCtrl.clear();
              final gorunen = _tumKasalar
                  ? _tumVeri
                  : _tumVeri.where((k) => k.Kasaid == _plasiyerKasaId).toList();
              setState(() {
                _all = gorunen;
                _filtered = List.from(gorunen);
              });
            },
            child: Text(_tumKasalar ? 'Kendi kasam' : 'Tümünü göster',
                style: TextStyle(fontSize: 12)),
          ),
        ]),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _search,
        style: TextStyle(fontSize: 14, color: _kDark),
        decoration: InputDecoration(
          hintText: 'Kasa ara...',
          hintStyle: TextStyle(fontSize: 13, color: _scheme.onSurfaceVariant),
          prefixIcon: Icon(Icons.search_rounded,
              color: _scheme.onSurfaceVariant, size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded,
                      size: 18, color: _scheme.onSurfaceVariant),
                  onPressed: () {
                    _searchCtrl.clear();
                    _search('');
                  },
                )
              : null,
          filled: true,
          fillColor: _scheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildCountHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
      child: Text(
        _searchCtrl.text.isNotEmpty
            ? "${_filtered.length} sonuç bulundu"
            : "${_all.length} kayıt",
        style: TextStyle(
          fontSize: 12,
          color: _scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildList() {
    if (_filtered.isEmpty) return _buildEmptyState();

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: _filtered.length,
      itemBuilder: (context, i) => _buildCard(_filtered[i]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.account_balance_wallet_outlined,
              size: 64, color: _scheme.outlineVariant),
          const SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty
                ? "Aramanızla eşleşen kasa bulunamadı"
                : "Henüz kasa kaydı yok",
            style: TextStyle(
              fontSize: 15,
              color: _scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                _searchCtrl.clear();
                _search('');
              },
              child: Text("Aramayı temizle"),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCard(VwFinanskasatoplamDto k) {
    final bakiye = k.Bakiyetutar ?? 0.0;
    final dovizBakiye = k.Dovizbakiyetutar;
    final birim = _dovizKisa(k.Dovizbirim);
    return ErpFinanceCard(
      title: k.Kasaisim ?? 'Kasa',
      metadata: [if ((k.Kasakod ?? '').isNotEmpty) k.Kasakod!, birim],
      icon: Icons.account_balance_wallet_outlined,
      amount: '${_fmt.format(bakiye)} ₺',
      amountColor: _balanceColor(bakiye),
      secondaryAmount: dovizBakiye != null && dovizBakiye != 0
          ? '${_fmt.format(dovizBakiye)} $birim'
          : null,
      onTap: k.Kasaid == null
          ? null
          : () => Navigator.push(
              context,
              PermissionMaterialPageRoute(
                  builder: (_) => KasahareketListePage(
                      kasaId: k.Kasaid!,
                      kasaAdi: k.Kasaisim ?? 'Kasa',
                      kasaKodu: k.Kasakod))),
    );
  }
}
