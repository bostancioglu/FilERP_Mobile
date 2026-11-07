import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../widgets/erp_page_style.dart';
import '../../../widgets/erp_ui.dart';
import 'package:flutter/material.dart';
import '../../../helpers/bordro_durum_islem.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/finans/cekverileniade_service.dart';
import '../../../models/entities/finans/cek/cekverileniade_dto.dart';
import '../../../helpers/response.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../helpers/cek_couples.dart';
import '../../../widgets/yetki_hatasi_widget.dart';
import 'cekverileniade_ekle_page.dart';

class CekverileniadeListePage extends StatefulWidget {
  const CekverileniadeListePage({super.key});

  @override
  State<CekverileniadeListePage> createState() =>
      _CekverileniadeListePageState();
}

class _CekverileniadeListePageState extends State<CekverileniadeListePage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;
  Color get _kBlue => _scheme.primary;
  Color get _kGreen => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF6EE7B7)
      : const Color(0xFF0E7C5A);
  Color get _kGold => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFFCD34D)
      : const Color(0xFF9A6700);

  List<CekverileniadeDto> _all = [];
  List<CekverileniadeDto> _filtered = [];
  bool _loading = true;
  bool _yetkiHatasi = false;

  final _searchCtrl = TextEditingController();
  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');
  final _dateFmt = DateFormat('dd.MM.yyyy');

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
      final data = await CekverileniadeService().getAll(token);
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
              .where((c) =>
                  (c.CariAd ?? '').toLowerCase().contains(s) ||
                  (c.Belgeserino ?? '').toLowerCase().contains(s))
              .toList();
    });
  }

  Future<void> _delete(CekverileniadeDto c) async {
    final onay = await UiFeedback.confirm(context,
        title: 'İade Bordrosu Sil',
        message:
            'Bu iade bordrosu silinecek, çekler eski durumuna dönecek. Emin misiniz?',
        confirmLabel: 'Sil',
        cancelLabel: 'Vazgeç',
        destructive: true);
    if (!onay || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      await CekverileniadeService().removeWithItems(token, c.Id!);
      if (!mounted) return;
      UiFeedback.showDeleted(context, 'İade bordrosu silindi.');
      _load();
    } catch (e) {
      if (mounted) UiFeedback.showException(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: _yetkiHatasi
          ? const YetkiHatasiWidget()
          : _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(children: [
                  _buildSearchBar(),
                  _buildCountHeader(),
                  Expanded(child: _buildList()),
                ]),
      floatingActionButton: PermissionAction(
          modules: [1014],
          access: Access.create,
          child: FloatingActionButton.extended(
            backgroundColor: _kBlue,
            foregroundColor: _scheme.onPrimary,
            icon: const Icon(Icons.add_rounded, size: 20),
            label: const Text('Yeni İade',
                style: TextStyle(
                    fontFamily: 'Roboto', fontWeight: FontWeight.w600)),
            onPressed: () async {
              await Navigator.push(
                  context,
                  PermissionMaterialPageRoute(
                      builder: (_) => const CekverileniadeEklePage()));
              _load();
            },
          )),
    );
  }

  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _kDark,
        elevation: 0,
        centerTitle: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Borç Çeki İade',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _kDark)),
        ]),
        actions: [
          IconButton(
              tooltip: 'Yenile',
              icon: Icon(Icons.refresh_rounded, color: _kDark),
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
          style: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: _kDark),
          decoration: InputDecoration(
            hintText: 'Cari veya belge no...',
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
            fillColor: _kBg,
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
      count: _searchCtrl.text.isNotEmpty
          ? '${_filtered.length} sonuç bulundu'
          : '${_all.length} bordro');

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
          Icon(Icons.keyboard_return_rounded,
              size: 64, color: _scheme.outlineVariant),
          const SizedBox(height: 12),
          Text('Henüz iade kaydı yok',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _buildCard(CekverileniadeDto c) {
    final taslak = c.Belgedurum == 0;
    final durumRenk = taslak ? _kGold : _kGreen;

    void islemler() => BordroDurumIslem.goster(context,
        prefix: 'Cekverileniade',
        id: c.Id!,
        taslak: taslak,
        baslik: c.Belgeserino ?? '',
        yenile: _load);
    return ErpSwipeDelete(
      key: ValueKey(c.Id),
      onDelete: !AuthorizationSession.instance.any([1014], Access.delete)
          ? null
          : () => _delete(c),
      child: ErpDocumentCard(
        number: c.Belgeserino?.isNotEmpty == true ? c.Belgeserino! : 'Bordro',
        date: c.Tarih != null ? _dateFmt.format(c.Tarih!) : '-',
        customer: c.CariAd ?? 'Cari',
        customerCode: '',
        amount: '${_moneyFmt.format(c.toplamTutar)} ₺',
        status:
            '${BelgeDurumCouples.adByValue(c.Belgedurum)} · ${c.cekSayisi} çek',
        statusColor: durumRenk,
        icon: Icons.receipt_long_rounded,
        onTap: AuthorizationSession.instance.can(1014, Access.create)
            ? islemler
            : null,
        action: !(AuthorizationSession.instance.can(1014, Access.create) ||
                AuthorizationSession.instance.can(1014, Access.delete))
            ? null
            : PopupMenuButton<String>(
                tooltip: 'İşlemler',
                icon: Icon(Icons.more_horiz_rounded,
                    color: _scheme.onSurfaceVariant),
                onSelected: (v) {
                  if (v == 'delete') {
                    _delete(c);
                  } else {
                    islemler();
                  }
                },
                itemBuilder: (_) => [
                  if (AuthorizationSession.instance.can(1014, Access.create))
                    const PopupMenuItem(
                        value: 'status', child: Text('Bordro İşlemleri')),
                  if (AuthorizationSession.instance.any([1014], Access.delete))
                    PopupMenuItem(
                        value: 'delete',
                        child: Text('Sil',
                            style: TextStyle(
                                fontFamily: 'Roboto', color: _scheme.error))),
                ],
              ),
      ),
    );
  }
}
