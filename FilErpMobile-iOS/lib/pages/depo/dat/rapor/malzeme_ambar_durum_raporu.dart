import '../../../../theme/app_theme.dart';
import '../../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../../helpers/plasiyer_depo_helper.dart';
import '../../../../helpers/ui_feedback.dart';
import '../../../../models/entities/rapor/stok/stokbakiye_dto.dart';
import '../../../../models/entities/depo/depo_dto.dart';
import '../../../../models/entities/stok/stok_list_dto.dart';
import '../../../../services/rapor/rapor_service.dart';
import '../../../../services/depo/depo_service.dart';
import '../../../../services/stok/stok_service.dart';
import '../../../../services/yazici/bluetooth_print_service.dart';
import '../../../../services/yazici/yazici_sablon_service.dart';
import '../../../../widgets/erp_selector.dart';

class MalzemeAmbarDurumRaporu extends StatefulWidget {
  const MalzemeAmbarDurumRaporu({super.key});

  @override
  State<MalzemeAmbarDurumRaporu> createState() =>
      _MalzemeAmbarDurumRaporuState();
}

class _MalzemeAmbarDurumRaporuState extends State<MalzemeAmbarDurumRaporu> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _positive => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFF6EE7B7)
      : Color(0xFF16704A);
  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;
  Color get _kBlue => _scheme.primary;
  Color get _kGreen => _positive;
  Color get _kRed => _scheme.error;
  Color get _kBorder => _scheme.outlineVariant;

  final _svc = RaporService();

  bool _loadingDepolar = true;
  bool _sorgulaniyor = false;
  bool _yazdiriliyor = false;

  List<DepoDto> _depolar = [];
  DepoDto? _seciliDepo; // null = Tümü

  List<StokListDto> _stoklar = [];
  StokListDto? _seciliStok; // null = Tümü

  late DateTime _tarih1;
  late DateTime _tarih2;

  List<StokbakiyeDto> _data = [];
  bool _sorgulandi = false;

  final _searchCtrl = TextEditingController();
  String _arama = '';

  final _dateFmt = DateFormat('dd.MM.yyyy');
  final _miktarFmt = NumberFormat('#,##0.####', 'tr_TR');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tarih1 = DateTime(now.year, now.month, now.day);
    _tarih2 = _tarih1;
    _searchCtrl.addListener(() {
      if (mounted)
        setState(() => _arama = _searchCtrl.text.trim().toLowerCase());
    });
    _loadDepolar();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDepolar() async {
    setState(() => _loadingDepolar = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final subeId = prefs.getInt('sube_id') ?? 0;

      List<DepoDto> depolar = [];
      List<StokListDto> stoklar = [];
      try {
        depolar = await DepoService().getAllBySubeId(token, subeId);
      } catch (_) {}
      try {
        stoklar = await StokService().getStokList(token);
      } catch (_) {}

      // Plasiyer kullanıcıda varsayılan depo = plasiyerin (araç) deposu
      DepoDto? plasiyerDepo;
      final kp = await KullaniciPlasiyerHelper.getir();
      if (kp.kilitli) {
        final depoId = await PlasiyerDepoHelper.getId(token, kp.plasiyerid,
            kilitli: true, mevcutDepolar: depolar);
        if (depoId != null)
          plasiyerDepo = depolar.where((d) => d.id == depoId).firstOrNull;
      }

      if (mounted) {
        setState(() {
          _depolar = depolar;
          _stoklar = stoklar;
          if (plasiyerDepo != null) _seciliDepo = plasiyerDepo;
          _loadingDepolar = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loadingDepolar = false);
        UiFeedback.showError(context, e.toString());
      }
    }
  }

  Future<void> _sorgula() async {
    setState(() => _sorgulaniyor = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final data = await _svc.getStokBakiye(token,
          tarih1: _tarih1,
          tarih2: _tarih2,
          depoid: _seciliDepo?.id,
          stokid: _seciliStok?.Id);
      if (!mounted) return;
      setState(() {
        _data = data;
        _sorgulaniyor = false;
        _sorgulandi = true;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _sorgulaniyor = false);
        UiFeedback.showError(context, e.toString());
      }
    }
  }

  List<StokbakiyeDto> get _filtered {
    if (_arama.isEmpty) return _data;
    return _data
        .where((s) =>
            (s.ad ?? '').toLowerCase().contains(_arama) ||
            (s.kod ?? '').toLowerCase().contains(_arama))
        .toList();
  }

  double get _toplamGiris =>
      _filtered.fold(0.0, (s, e) => s + (e.toplamGirismiktar ?? 0));
  double get _toplamCikis =>
      _filtered.fold(0.0, (s, e) => s + (e.toplamCikismiktar ?? 0));
  double get _toplamKalan =>
      _filtered.fold(0.0, (s, e) => s + (e.toplamBakiyemiktar ?? 0));

  Future<void> _yazdir() async {
    if (_filtered.isEmpty) {
      UiFeedback.showWarning(context, 'Yazdırılacak kayıt yok.');
      return;
    }
    setState(() => _yazdiriliyor = true);
    try {
      final svc = BluetoothPrintService.instance;
      var connected = await svc.isConnected;
      if (!connected) {
        final mac = await svc.getSavedMac();
        if (mac == null) {
          if (mounted)
            UiFeedback.showError(context,
                'Kayıtlı yazıcı yok. Ayarlar > Yazıcı Ayarları\'ndan bir yazıcı seçin.');
          return;
        }
        connected = await svc.connect(mac);
        if (!connected) {
          if (mounted) UiFeedback.showError(context, 'Yazıcıya bağlanılamadı.');
          return;
        }
      }

      final satirlar = _filtered
          .map((s) => AmbarDurumSatir(
                ad: '${s.kod ?? ''} ${s.ad ?? ''}'.trim(),
                giris: s.toplamGirismiktar ?? 0,
                cikis: s.toplamCikismiktar ?? 0,
                kalan: s.toplamBakiyemiktar ?? 0,
                olcubr: s.olcubr ?? '',
              ))
          .toList();

      final satirGen = await YaziciSablonService.instance.getSatirGenisligi();
      final prefs = await SharedPreferences.getInstance();
      final kullaniciAdi = prefs.getString('kullanici_adi');
      final bytes = svc.buildAmbarDurumFisi(
        depoAd: _seciliDepo?.ad ?? 'Tümü',
        tarih1: _tarih1,
        tarih2: _tarih2,
        satirlar: satirlar,
        satirGenisligi: satirGen,
        kullaniciAdi: kullaniciAdi,
      );
      final ok = await svc.printBytes(bytes);
      if (!mounted) return;
      if (ok) {
        UiFeedback.showSuccess(context, 'Rapor yazıcıya gönderildi.');
      } else {
        UiFeedback.showError(context, 'Yazdırma başarısız.');
      }
    } catch (e) {
      if (mounted) UiFeedback.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _yazdiriliyor = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: _buildAppBar(),
      body: _loadingDepolar
          ? Center(child: CircularProgressIndicator())
          : Column(children: [
              _buildFiltreBar(),
              if (_sorgulandi) _buildOzetBar(),
              Expanded(
                child: _sorgulaniyor
                    ? Center(child: CircularProgressIndicator())
                    : !_sorgulandi
                        ? _buildBaslangic()
                        : _filtered.isEmpty
                            ? _buildBosSonuc()
                            : _buildListe(),
              ),
            ]),
    );
  }

  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        backgroundColor: _scheme.surface,
        foregroundColor: _kDark,
        elevation: 0,
        titleSpacing: 0,
        title: Row(children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: _kBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(9)),
            child: Icon(Icons.warehouse_rounded, size: 17, color: _kBlue),
          ),
          SizedBox(width: 10),
          Expanded(
            child: Text('Malzeme Ambar Durum Raporu',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    color: _kDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        actions: [
          if (_sorgulandi)
            IconButton(
              tooltip: 'Yazdır',
              icon: _yazdiriliyor
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.print_rounded),
              onPressed: _yazdiriliyor ? null : _yazdir,
            ),
        ],
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Container(height: 1, color: _kBorder)),
      );

  Widget _buildFiltreBar() => Container(
        color: _scheme.surface,
        padding: EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(children: [
          Row(children: [
            Expanded(child: _depoSecici()),
            SizedBox(width: 8),
            Expanded(child: _stokSecici()),
          ]),
          SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: _tarihKutusu(
                    'Başlangıç', _tarih1, (d) => setState(() => _tarih1 = d))),
            SizedBox(width: 8),
            Expanded(
                child: _tarihKutusu(
                    'Bitiş', _tarih2, (d) => setState(() => _tarih2 = d))),
          ]),
          SizedBox(height: 10),
          SizedBox(
            width: 140,
            height: 40,
            child: ElevatedButton.icon(
              onPressed: _sorgulaniyor ? null : _sorgula,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: _scheme.onPrimary,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              icon: Icon(Icons.search_rounded, size: 18),
              label: Text('Sorgula',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
            ),
          ),
          if (_sorgulandi) ...[
            SizedBox(height: 8),
            SizedBox(
              height: 38,
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(fontFamily: 'Roboto', fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Malzeme adı veya kodu ara...',
                  hintStyle: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12.5,
                      color: _scheme.onSurfaceVariant),
                  prefixIcon: Icon(Icons.search_rounded, size: 18),
                  prefixIconConstraints: BoxConstraints(minWidth: 34),
                  isDense: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: _kBorder)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: _kBorder)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(9),
                      borderSide: BorderSide(color: _kBlue, width: 1.3)),
                ),
              ),
            ),
          ],
        ]),
      );

  Widget _depoSecici() => _seciciKutusu(
        icon: Icons.warehouse_outlined,
        label: _seciliDepo?.ad ?? 'Tümü Ambarlar',
        secili: _seciliDepo != null,
        onClear: _seciliDepo != null
            ? () => setState(() => _seciliDepo = null)
            : null,
        onTap: () async {
          final d = await showErpSelector<DepoDto>(
            context: context,
            title: 'Ambar Seç',
            hintText: 'Ambar adı ara...',
            items: _depolar,
            itemText: (d) => d.ad ?? '-',
          );
          if (d != null) setState(() => _seciliDepo = d);
        },
      );

  Widget _stokSecici() => _seciciKutusu(
        icon: Icons.inventory_2_outlined,
        label: _seciliStok != null
            ? '${_seciliStok!.Kod ?? ''} - ${_seciliStok!.Ad ?? ''}'
            : 'Tümü Malzemeler',
        secili: _seciliStok != null,
        onClear: _seciliStok != null
            ? () => setState(() => _seciliStok = null)
            : null,
        onTap: () async {
          final s = await showErpSelector<StokListDto>(
            context: context,
            title: 'Malzeme Seç',
            hintText: 'Malzeme adı, kodu veya barkod...',
            items: _stoklar,
            itemText: (s) => '${s.Kod ?? ''} - ${s.Ad ?? ''}',
            getBarcodes: (s) => s.getBarkodListesi(),
            getUnit: (s) => s.TemelolcubrAd ?? '',
          );
          if (s != null) setState(() => _seciliStok = s);
        },
      );

  Widget _seciciKutusu({
    required IconData icon,
    required String label,
    required bool secili,
    required VoidCallback onTap,
    VoidCallback? onClear,
  }) =>
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border:
                Border.all(color: secili ? _kBlue.withOpacity(0.4) : _kBorder),
            color: secili ? _kBlue.withOpacity(0.04) : null,
          ),
          child: Row(children: [
            Icon(icon,
                size: 17, color: secili ? _kBlue : _scheme.onSurfaceVariant),
            SizedBox(width: 8),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: secili ? _kBlue : _kDark),
                  overflow: TextOverflow.ellipsis),
            ),
            if (onClear != null)
              GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close_rounded,
                      size: 18, color: _scheme.onSurfaceVariant))
            else
              Icon(Icons.chevron_right_rounded,
                  size: 18, color: _scheme.onSurfaceVariant),
          ]),
        ),
      );

  Widget _tarihKutusu(
          String label, DateTime tarih, ValueChanged<DateTime> onChanged) =>
      InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () async {
          final d = await showDatePicker(
              context: context,
              initialDate: tarih,
              firstDate: DateTime(2000),
              lastDate: DateTime(2100));
          if (d != null) onChanged(d);
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder),
              color: _scheme.surfaceContainerLow),
          child: Row(children: [
            Icon(Icons.calendar_today_rounded,
                size: 14, color: _kBlue.withOpacity(0.7)),
            SizedBox(width: 7),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 9.5,
                      color: _scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              Text(_dateFmt.format(tarih),
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: _kBlue)),
            ]),
          ]),
        ),
      );

  Widget _buildOzetBar() => Container(
        color: _scheme.surface,
        padding: EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Row(children: [
          Expanded(
              child:
                  _ozetKutu('Giriş', _miktarFmt.format(_toplamGiris), _kGreen)),
          _dikeyAyrac(),
          Expanded(
              child:
                  _ozetKutu('Çıkış', _miktarFmt.format(_toplamCikis), _kRed)),
          _dikeyAyrac(),
          Expanded(
              child:
                  _ozetKutu('Kalan', _miktarFmt.format(_toplamKalan), _kBlue)),
        ]),
      );

  Widget _dikeyAyrac() => Container(
      width: 1,
      height: 30,
      color: _kBorder,
      margin: EdgeInsets.symmetric(horizontal: 4));

  Widget _ozetKutu(String label, String deger, Color renk) => Column(children: [
        Text(label,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 9.5,
                color: _scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4)),
        SizedBox(height: 3),
        Text(deger,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: renk),
            overflow: TextOverflow.ellipsis),
      ]);

  Widget _buildBaslangic() => Center(
      child: Text('Henüz sorgulanmadı',
          style: TextStyle(fontSize: 13, color: _scheme.onSurfaceVariant)));

  Widget _buildBosSonuc() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: _scheme.surfaceContainerLow, shape: BoxShape.circle),
            child: Icon(Icons.inventory_2_outlined,
                size: 26, color: _scheme.onSurfaceVariant),
          ),
          SizedBox(height: 14),
          Text('Bu aralıkta kayıt bulunamadı',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13.5,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500)),
        ]),
      );

  Widget _buildListe() => ListView.builder(
        padding: EdgeInsets.fromLTRB(14, 8, 14, 24),
        itemCount: _filtered.length,
        itemBuilder: (_, i) => _buildSatir(_filtered[i]),
      );

  Widget _buildSatir(StokbakiyeDto s) {
    final kalan = s.toplamBakiyemiktar ?? 0;
    final kalanRenk =
        kalan > 0 ? _kBlue : (kalan < 0 ? _kRed : _scheme.onSurfaceVariant);
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: _scheme.surface,
          borderRadius:
              BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
          border: Border.all(color: _kBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
            child: Text('${s.kod ?? ''} — ${s.ad ?? ''}',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: _kDark),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
        ]),
        SizedBox(height: 8),
        Row(children: [
          Expanded(
              child: _miktarKutusu('Giriş', s.toplamGirismiktar ?? 0,
                  s.olcubr ?? '', _kGreen, Icons.arrow_downward_rounded)),
          SizedBox(width: 6),
          Expanded(
              child: _miktarKutusu('Çıkış', s.toplamCikismiktar ?? 0,
                  s.olcubr ?? '', _kRed, Icons.arrow_upward_rounded)),
          SizedBox(width: 6),
          Expanded(
              child: _miktarKutusu('Kalan', kalan, s.olcubr ?? '', kalanRenk,
                  Icons.inventory_2_rounded)),
        ]),
      ]),
    );
  }

  Widget _miktarKutusu(String label, double deger, String birim, Color renk,
          IconData icon) =>
      Container(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
            color: renk.withOpacity(0.06),
            borderRadius: BorderRadius.circular(9)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 11, color: renk),
            SizedBox(width: 3),
            Text(label,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 9.5,
                    color: renk,
                    fontWeight: FontWeight.w700)),
          ]),
          SizedBox(height: 3),
          Text('${_miktarFmt.format(deger)} $birim',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: renk),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ]),
      );
}
