import '../../../widgets/erp_page_style.dart';
import '../../../widgets/erp_negotiable_report.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../models/entities/finans/cek/vw_finanscekalinan_dto.dart';
import '../../../helpers/response.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../widgets/yetki_hatasi_widget.dart';

/// Müşteri Çek raporları için tek, yeniden kullanılabilir liste sayfası.
/// 6 farklı rapor (Genel, Verilene Göre, Portföy, Tahsil, Teminat, Karşılıksız)
/// aynı görünüme sahip, sadece veri kaynağı (fetcher) değişiyor.
class CekalinanRaporPage extends StatefulWidget {
  final String title;
  final Future<List<VwFinanscekalinanDto>> Function(String token) fetcher;
  final bool showAsilBorclu;

  const CekalinanRaporPage({
    super.key,
    required this.title,
    required this.fetcher,
    this.showAsilBorclu = true,
  });

  @override
  State<CekalinanRaporPage> createState() => _CekalinanRaporPageState();
}

class _CekalinanRaporPageState extends State<CekalinanRaporPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;

  List<VwFinanscekalinanDto> _all = [];
  List<VwFinanscekalinanDto> _filtered = [];
  bool _loading = true;
  bool _yetkiHatasi = false;

  final _searchCtrl = TextEditingController();
  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');
  final _dateFmt = DateFormat('dd.MM.yyyy');

  double get _toplamTutar =>
      _filtered.fold(0.0, (s, e) => s + (e.Tutar ?? 0.0));

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
      final data = await widget.fetcher(token);
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
              .where((e) =>
                  (e.Cariad ?? '').toLowerCase().contains(s) ||
                  (e.Asilborclu ?? '').toLowerCase().contains(s) ||
                  (e.Cekno ?? '').toLowerCase().contains(s) ||
                  (e.Bordrono ?? '').toLowerCase().contains(s) ||
                  (e.Bankaadi ?? '').toLowerCase().contains(s))
              .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: _yetkiHatasi
          ? YetkiHatasiWidget()
          : _loading
              ? Center(child: CircularProgressIndicator())
              : Column(children: [
                  _buildSearchBar(),
                  _buildOzetBar(),
                  Expanded(child: _buildList()),
                ]),
    );
  }

  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _kDark,
        elevation: 0,
        centerTitle: false,
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            preferredSize: Size.fromHeight(1),
            child: Container(height: 1, color: _scheme.surfaceContainerLow)),
      );

  Widget _buildSearchBar() => Container(
        color: _scheme.surface,
        padding: EdgeInsets.fromLTRB(16, 8, 16, 14),
        child: TextField(
          controller: _searchCtrl,
          onChanged: _search,
          style: TextStyle(fontFamily: 'Roboto', fontSize: 14, color: _kDark),
          decoration: InputDecoration(
            hintText: 'Cari, çek no veya bordro no...',
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
            contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none),
          ),
        ),
      );

  Widget _buildOzetBar() => Padding(
        padding: EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Row(children: [
          Expanded(
              child: Text(
                  _searchCtrl.text.isNotEmpty
                      ? '${_filtered.length} sonuç bulundu'
                      : '${_all.length} kayıt',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: _scheme.onSurfaceVariant))),
          SizedBox(width: 8),
          Expanded(
              child: Text('Toplam ${_moneyFmt.format(_toplamTutar)} ₺',
                  textAlign: TextAlign.end,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _scheme.onSurface))),
        ]),
      );

  Widget _buildList() {
    if (_filtered.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: _filtered.length,
      itemBuilder: (_, i) => _buildCard(_filtered[i]),
    );
  }

  Widget _buildEmptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.receipt_long_outlined,
              size: 64, color: _scheme.outlineVariant),
          SizedBox(height: 16),
          Text('Kayıt bulunamadı',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _buildCard(VwFinanscekalinanDto e) {
    final currency = (e.Parabirimi ?? '').trim().toUpperCase();
    final fx = currency.isNotEmpty && !['TL', 'TRY', '₺'].contains(currency);
    return ErpNegotiableReportCard(
      customer: e.Cariad ?? '-',
      number: e.Cekno?.isNotEmpty == true ? e.Cekno! : '-',
      dueDate: e.Vadetarihi != null ? _dateFmt.format(e.Vadetarihi!) : '-',
      amount: '${_moneyFmt.format(e.Tutar ?? 0)} ₺',
      secondaryAmount: fx && (e.Doviztutar ?? 0) != 0
          ? '${_moneyFmt.format(e.Doviztutar)} $currency'
          : null,
      status: e.SuandaEvrakdurum,
      location: e.SuandaEvrakyeri,
      bank: e.Bankaadi,
      originalDebtor: widget.showAsilBorclu ? e.Asilborclu : null,
      batch: e.Bordrono,
    );
  }
}
