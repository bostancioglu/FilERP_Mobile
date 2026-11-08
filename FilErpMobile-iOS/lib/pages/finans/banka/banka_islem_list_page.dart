import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../../widgets/erp_ui.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/finans/bankahesap_service.dart';
import '../../../models/entities/finans/banka/bankahesap_dto.dart';
import '../../../models/entities/finans/banka/vw_finansbankahesaptoplam_dto.dart';
import '../../../helpers/response.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../widgets/yetki_hatasi_widget.dart';
import 'bankahareket_liste_page.dart';
import 'bankahareket_ekle_page.dart';

const _kGreen = Color(0xFF059669);

class BankaIslemListPage extends StatefulWidget {
  const BankaIslemListPage({super.key});

  @override
  State<BankaIslemListPage> createState() => _BankaIslemListPageState();
}

class _BankaIslemListPageState extends State<BankaIslemListPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  List<BankahesapDto> _all = [];
  List<BankahesapDto> _filtered = [];
  Map<int, VwFinansbankahesaptoplamDto> _toplamMap = {};
  bool _loading = true;
  bool _yetkiHatasi = false;

  final _searchCtrl = TextEditingController();
  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');

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
      final token = prefs.getString('token_final') ?? '';
      final svc = BankahesapService();
      final results = await Future.wait([
        svc.getAllWithoutAuth(token),
        svc
            .getBankahesapToplam(token)
            .catchError((_) => <VwFinansbankahesaptoplamDto>[]),
      ]);
      if (!mounted) return;
      final hesaplar = results[0] as List<BankahesapDto>;
      final toplamlar = results[1] as List<VwFinansbankahesaptoplamDto>;
      setState(() {
        _all = hesaplar;
        _filtered = List.from(hesaplar);
        _toplamMap = {
          for (final t in toplamlar)
            if (t.Bankahesapid != null) t.Bankahesapid!: t
        };
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
        UiFeedback.showException(context, e);
      }
    }
  }

  void _search(String text) {
    final s = text.toLowerCase();
    setState(() {
      _filtered = s.isEmpty
          ? List.from(_all)
          : _all
              .where((b) =>
                  (b.Kod ?? '').toLowerCase().contains(s) ||
                  (b.Ad ?? '').toLowerCase().contains(s))
              .toList();
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
              : Column(children: [
                  _buildSearchBar(),
                  _buildCountHeader(),
                  Expanded(child: _buildList()),
                ]),
      floatingActionButton: PermissionAction(
          modules: [1004],
          access: Access.create,
          child: FloatingActionButton.extended(
            backgroundColor: _scheme.primary,
            foregroundColor: _scheme.onPrimary,
            icon: Icon(Icons.add_rounded, size: 20),
            label: Text('Yeni İşlem',
                style: TextStyle(
                    fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
            onPressed: () async {
              await Navigator.push(
                  context,
                  PermissionMaterialPageRoute(
                      builder: (_) => BankahareketEklePage()));
              _load();
            },
          )),
    );
  }

  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        centerTitle: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Banka İşlem',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _scheme.onSurface)),
        ]),
        actions: [
          IconButton(
              tooltip: 'Yenile',
              icon: Icon(Icons.refresh_rounded, color: _scheme.onSurface),
              onPressed: _load),
        ],
        bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: _scheme.surfaceContainerLow)),
      );

  Widget _buildSearchBar() => Container(
        color: _scheme.surface,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _search,
          style: TextStyle(
              fontFamily: 'Roboto', fontSize: 14, color: _scheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Hesap adı veya kodu...',
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
                    })
                : null,
            filled: true,
            fillColor: _background,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
      );

  Widget _buildCountHeader() => ErpListOverview(
      count: _searchCtrl.text.isEmpty
          ? '${_all.length} kayıt'
          : '${_filtered.length} sonuç bulundu');

  Widget _buildList() {
    if (_filtered.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _buildCard(_filtered[i]),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.account_balance_outlined,
              size: 64, color: _scheme.outlineVariant),
          SizedBox(height: 16),
          Text('Henüz banka hesabı yok',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _buildCard(BankahesapDto b) {
    final total = b.Id == null ? null : _toplamMap[b.Id];
    final balance = total?.Bakiyetutar ?? 0;
    final fx =
        !['TL', 'TRY', '₺', ''].contains((b.DovizBirim ?? '').toUpperCase());
    return ErpFinanceCard(
      title: b.Ad ?? 'Hesap',
      icon: Icons.account_balance_outlined,
      metadata: [b.Kod ?? '', b.BankaAd ?? '', b.DovizBirim ?? ''],
      amount: total == null ? null : '${_moneyFmt.format(balance)} ₺',
      amountColor: balance >= 0 ? _kGreen : Theme.of(context).colorScheme.error,
      secondaryAmount: fx && total?.Dovizbakiyetutar != null
          ? '${_moneyFmt.format(total!.Dovizbakiyetutar)} ${b.DovizBirim}'
          : null,
      onTap: () async {
        await Navigator.push(
            context,
            PermissionMaterialPageRoute(
                builder: (_) => BankahareketListePage(bankahesap: b)));
        if (mounted) _load();
      },
    );
  }
}
