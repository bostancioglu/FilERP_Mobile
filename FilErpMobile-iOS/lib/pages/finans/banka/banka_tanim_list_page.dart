import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../../widgets/erp_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/finans/bankahesap_service.dart';
import '../../../models/entities/finans/banka/bankahesap_dto.dart';
import '../../../helpers/response.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../widgets/yetki_hatasi_widget.dart';
import 'banka_tanim_ekle_page.dart';

class BankaTanimListPage extends StatefulWidget {
  const BankaTanimListPage({super.key});

  @override
  State<BankaTanimListPage> createState() => _BankaTanimListPageState();
}

class _BankaTanimListPageState extends State<BankaTanimListPage> {
  Color get _kRed => Theme.of(context).colorScheme.primary;
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  List<BankahesapDto> _all = [];
  List<BankahesapDto> _filtered = [];
  bool _loading = true;
  bool _yetkiHatasi = false;

  final _searchCtrl = TextEditingController();

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
      final data = await BankahesapService().getAll(token);
      if (!mounted) return;
      setState(() {
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
                  (b.Ad ?? '').toLowerCase().contains(s) ||
                  (b.BankaAd ?? '').toLowerCase().contains(s))
              .toList();
    });
  }

  Future<void> _openEkle({BankahesapDto? edit}) async {
    final result = await Navigator.push(
        context,
        PermissionMaterialPageRoute(
            builder: (_) => BankaTanimEklePage(editBanka: edit)));
    if (result == true) _load();
  }

  Future<void> _delete(BankahesapDto b) async {
    final onay = await UiFeedback.confirm(context,
        title: 'Banka Hesabı Sil',
        message:
            '"${b.Ad ?? b.Kod}" hesabını silmek istediğinize emin misiniz?',
        confirmLabel: 'Sil',
        cancelLabel: 'Vazgeç');
    if (!onay || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      await BankahesapService().delete(token, b.Id as int);
      if (!mounted) return;
      UiFeedback.showSuccess(context, 'Banka hesabı silindi.');
      _load();
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
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
          modules: [1002],
          access: Access.create,
          child: FloatingActionButton.extended(
            backgroundColor: _kRed,
            foregroundColor: _scheme.onPrimary,
            icon: Icon(Icons.add_rounded, size: 20),
            label: Text('Yeni Hesap',
                style: TextStyle(
                    fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
            onPressed: () => _openEkle(),
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
          Text('Banka Tanımları',
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
            hintText: 'Hesap kodu, adı veya banka...',
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
          Text(
            _searchCtrl.text.isNotEmpty
                ? 'Aramanızla eşleşen hesap bulunamadı'
                : 'Henüz banka hesabı yok',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 15,
                color: _scheme.onSurfaceVariant,
                fontWeight: FontWeight.w500),
          ),
        ]),
      );

  Widget _buildCard(BankahesapDto b) => ErpSwipeDelete(
        key: ValueKey('definition_${b.Id}'),
        onDelete: !AuthorizationSession.instance.any([1002], Access.delete)
            ? null
            : () => _delete(b),
        child: ErpFinanceCard(
            title: b.Ad ?? 'Hesap',
            icon: Icons.account_balance_outlined,
            metadata: [
              b.Kod ?? '',
              b.DovizBirim ?? '',
              if (b.BankaAd?.isNotEmpty == true) b.BankaAd!,
              if (b.HesapplaniKod?.isNotEmpty == true) b.HesapplaniKod!
            ],
            onTap: () => _openEkle(edit: b),
            onDelete: !AuthorizationSession.instance.any([1002], Access.delete)
                ? null
                : () => _delete(b)),
      );
}
