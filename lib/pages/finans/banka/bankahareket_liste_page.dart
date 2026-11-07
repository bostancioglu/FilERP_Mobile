import 'package:FilERP/services/auth/authorization_session.dart';
import 'package:FilERP/widgets/permission_page.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../../widgets/erp_ui.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/finans/bankahareket_service.dart';
import '../../../models/entities/finans/banka/bankahesap_dto.dart';
import '../../../models/entities/finans/banka/bankahareket_dto.dart';
import '../../../helpers/response.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../widgets/yetki_hatasi_widget.dart';
import 'bankahareket_ekle_page.dart';
import '../../../helpers/banka_couples.dart';

const _kGreen = Color(0xFF059669);

bool _isFX(String? birim) => birim != null && birim != 'TL' && birim != '₺';

class BankahareketListePage extends StatefulWidget {
  final BankahesapDto bankahesap;
  const BankahareketListePage({super.key, required this.bankahesap});

  @override
  State<BankahareketListePage> createState() => _BankahareketListePageState();
}

class _BankahareketListePageState extends State<BankahareketListePage> {
  Color get _kRed => Theme.of(context).colorScheme.primary;
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _background => Theme.of(context).scaffoldBackgroundColor;
  List<BankahareketDto> _list = [];
  bool _loading = true;
  bool _yetkiHatasi = false;

  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');
  final _dateFmt = DateFormat('dd.MM.yyyy');

  bool get _isFxHesap => _isFX(widget.bankahesap.DovizBirim);

  double get _toplamGiris => _list
      .where((h) => h.Giriscikis == 1)
      .fold(0.0, (s, h) => s + (h.Tutar ?? 0.0));
  double get _toplamCikis => _list
      .where((h) => h.Giriscikis == 2)
      .fold(0.0, (s, h) => s + (h.Tutar ?? 0.0));
  double get _bakiye => _toplamGiris - _toplamCikis;

  double get _dovizGiris => _list
      .where((h) => h.Giriscikis == 1)
      .fold(0.0, (s, h) => s + (h.Doviztutar ?? 0.0));
  double get _dovizCikis => _list
      .where((h) => h.Giriscikis == 2)
      .fold(0.0, (s, h) => s + (h.Doviztutar ?? 0.0));
  double get _dovizBakiye => _dovizGiris - _dovizCikis;

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
      final token = prefs.getString('token_final') ?? '';
      final data = await BankahareketService()
          .getByBankahesapid(token, widget.bankahesap.Id as int);
      if (!mounted) return;
      setState(() {
        _list = data;
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

  Future<void> _delete(BankahareketDto h) async {
    final onay = await UiFeedback.confirm(context,
        title: 'Hareket Sil',
        message: 'Bu banka hareketi silinecek. Emin misiniz?',
        confirmLabel: 'Sil',
        cancelLabel: 'Vazgeç');
    if (!onay || !mounted) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      await BankahareketService().delete(token, h.Id!);
      if (!mounted) return;
      UiFeedback.showSuccess(context, 'Hareket silindi.');
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
              : _list.isEmpty
                  ? _buildEmptyState()
                  : Column(children: [
                      _buildOzetKarti(),
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _list.length,
                          itemBuilder: (_, i) => _buildCard(_list[i]),
                        ),
                      ),
                    ]),
      floatingActionButton: PermissionAction(
          modules: [1004],
          access: Access.create,
          child: FloatingActionButton(
            backgroundColor: _scheme.primary,
            foregroundColor: _scheme.onPrimary,
            child: Icon(Icons.add_rounded),
            onPressed: () async {
              final result = await Navigator.push(
                  context,
                  PermissionMaterialPageRoute(
                      builder: (_) =>
                          BankahareketEklePage(bankahesap: widget.bankahesap)));
              if (result == true) _load();
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
          Text(widget.bankahesap.Ad ?? 'Banka Hareketleri',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: _scheme.onSurface)),
          Text('Finans • ${widget.bankahesap.Kod ?? ''}',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  color: _scheme.onSurfaceVariant)),
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

  Widget _buildOzetKarti() {
    final birim = widget.bankahesap.DovizBirim ?? 'TL';
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
              offset: Offset(0, 3))
        ],
      ),
      child: Column(children: [
        Row(children: [
          Expanded(
              child: _ozetItem('Giriş', _toplamGiris, _kGreen,
                  Icons.arrow_downward_rounded)),
          Container(width: 1, height: 34, color: _scheme.outlineVariant),
          Expanded(
              child: _ozetItem(
                  'Çıkış', _toplamCikis, _kRed, Icons.arrow_upward_rounded)),
          Container(width: 1, height: 34, color: _scheme.outlineVariant),
          Expanded(
              child: _ozetItem(
                  'Bakiye',
                  _bakiye,
                  _bakiye >= 0 ? _kGreen : _kRed,
                  Icons.account_balance_outlined)),
        ]),
        if (_isFxHesap) ...[
          SizedBox(height: 10),
          Container(height: 1, color: _scheme.surfaceContainerLow),
          SizedBox(height: 10),
          Row(children: [
            Expanded(
                child: _ozetItemFx('Giriş ($birim)', _dovizGiris, _kGreen)),
            Container(width: 1, height: 26, color: _scheme.outlineVariant),
            Expanded(child: _ozetItemFx('Çıkış ($birim)', _dovizCikis, _kRed)),
            Container(width: 1, height: 26, color: _scheme.outlineVariant),
            Expanded(
                child: _ozetItemFx('Bakiye ($birim)', _dovizBakiye,
                    _dovizBakiye >= 0 ? _kGreen : _kRed)),
          ]),
        ],
      ]),
    );
  }

  Widget _ozetItem(String label, double tutar, Color color, IconData icon) =>
      Column(
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(icon, size: 13, color: color),
            SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 11,
                    color: _scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600)),
          ]),
          SizedBox(height: 4),
          Text(_moneyFmt.format(tutar),
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      );

  Widget _ozetItemFx(String label, double tutar, Color color) => Column(
        children: [
          Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
          SizedBox(height: 3),
          Text(_moneyFmt.format(tutar),
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color)),
        ],
      );

  Widget _buildEmptyState() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.account_balance_outlined,
              size: 64, color: _scheme.outlineVariant),
          SizedBox(height: 16),
          Text('Henüz hareket yok',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 15,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  String? _karsiTaraf(BankahareketDto h) {
    switch (h.Islemtipi) {
      case 1:
        return h.IslemcariAd;
      case 2:
      case 3:
        return h.IslembankahesapAd;
      case 8:
        return h.IslemmasrafAd;
      default:
        return null;
    }
  }

  Widget _buildCard(BankahareketDto h) {
    final incoming = h.Giriscikis == 1;
    final type = BankaIslemtipiCouples.adByValue(h.Islemtipi);
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
      onDelete: !AuthorizationSession.instance.any([1004], Access.delete)
          ? null
          : () => _delete(h),
      onTap: () async {
        final result = await Navigator.push(
            context,
            PermissionMaterialPageRoute(
                builder: (_) => BankahareketEklePage(
                    bankahesap: widget.bankahesap, editHareket: h)));
        if (result == true && mounted) _load();
      },
    );
    return ErpSwipeDelete(
        key: ValueKey(h.Id),
        onDelete: !AuthorizationSession.instance.any([1004], Access.delete)
            ? null
            : () => _delete(h),
        child: card);
  }
}
