import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../../widgets/erp_ui.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/finans/kasa_islem_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/finans/kasa_islem/vw_finanskasatoplam_dto.dart';
import '../../../helpers/response.dart';
import '../../../widgets/yetki_hatasi_widget.dart';
import 'kasahareket_ekle_page.dart';
import 'kasahareket_liste_page.dart';

final _fmt = NumberFormat('#,##0.00', 'tr_TR');

class KasaIslemListPage extends StatefulWidget {
  const KasaIslemListPage({super.key});

  @override
  State<KasaIslemListPage> createState() => _KasaIslemListPageState();
}

class _KasaIslemListPageState extends State<KasaIslemListPage> {
  Color get _kRed => Theme.of(context).colorScheme.primary;
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  List<VwFinanskasatoplamDto> _all = [];
  List<VwFinanskasatoplamDto> _filtered = [];
  Map<String, String> _dovizAdBirim = {};
  bool _loading = true;
  bool _yetkiHatasi = false;

  final _searchCtrl = TextEditingController();

  String _dovizKisa(String? birim) {
    if (birim == null || birim.isEmpty) return 'TL';
    return _dovizAdBirim[birim] ?? birim;
  }

  bool _isDovizli(String? birim) {
    final kisa = _dovizKisa(birim);
    return kisa != 'TL' && kisa != '₺';
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
      setState(() {
        _dovizAdBirim = {
          for (final d in dovizler)
            if (d.Ad != null && d.Birim != null)
              d.Ad as String: d.Birim as String
        };
        _all = data;
        _filtered = List.from(data);
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
        debugPrint("Kasa İşlem Hatası: $e");
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
                    _buildSearchBar(),
                    _buildCountHeader(),
                    Expanded(child: _buildList()),
                  ],
                ),
      floatingActionButton: PermissionAction(
          modules: [1003],
          access: Access.create,
          child: FloatingActionButton.extended(
            backgroundColor: _kRed,
            foregroundColor: _scheme.onPrimary,
            icon: Icon(Icons.add_rounded, size: 20),
            label: Text("Yeni Hareket",
                style: TextStyle(
                    fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                PermissionMaterialPageRoute(
                    builder: (_) => KasahareketEklePage()),
              );
              if (result == true) _load();
            },
          )),
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
          Text(
            "Kasa İşlemleri",
            style: TextStyle(
              fontFamily: 'Roboto',
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: _scheme.onSurface,
            ),
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

  Widget _buildSearchBar() {
    return Container(
      color: _scheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
      child: TextField(
        controller: _searchCtrl,
        onChanged: _search,
        style: TextStyle(
            fontFamily: 'Roboto', fontSize: 14, color: _scheme.onSurface),
        decoration: InputDecoration(
          hintText: "Kasa kodu, adı veya para birimi...",
          hintStyle: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 13,
              color: _scheme.onSurfaceVariant),
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
          fillColor: _background,
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

  Widget _buildCountHeader() => ErpListOverview(
      count: _searchCtrl.text.isEmpty
          ? '${_all.length} kayıt'
          : '${_filtered.length} sonuç bulundu');

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
          SizedBox(height: 16),
          Text(
            _searchCtrl.text.isNotEmpty
                ? "Aramanızla eşleşen kasa bulunamadı"
                : "Henüz kasa kaydı yok",
            style: TextStyle(
              fontFamily: 'Roboto',
              fontSize: 15,
              color: _scheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (_searchCtrl.text.isNotEmpty) ...[
            SizedBox(height: 8),
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
    final balance = k.Bakiyetutar ?? 0;
    final unit = _dovizKisa(k.Dovizbirim);
    return ErpFinanceCard(
      title: k.Kasaisim ?? 'Kasa',
      icon: Icons.account_balance_wallet_outlined,
      metadata: [k.Kasakod ?? '', unit],
      amount: '${_fmt.format(balance)} ₺',
      amountColor: balance >= 0
          ? Color(0xFF2E7D32)
          : Theme.of(context).colorScheme.error,
      secondaryAmount: _isDovizli(k.Dovizbirim) && k.Dovizbakiyetutar != null
          ? '${_fmt.format(k.Dovizbakiyetutar)} $unit'
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
