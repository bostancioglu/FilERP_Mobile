import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import '../../../widgets/erp_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

import '../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../helpers/plasiyer_kasa_helper.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../models/entities/finans/kasa_islem/kasa_dto.dart';
import '../../../models/entities/finans/kasa_islem/kasahareket_dto.dart';
import '../../../services/finans/kasa_tanim_service.dart';
import '../../../services/finans/kasa_islem_service.dart';
import '../../../services/yazici/bluetooth_print_service.dart';
import '../../../services/yazici/yazici_sablon_service.dart';

class ZRaporuPage extends StatefulWidget {
  const ZRaporuPage({super.key});

  @override
  State<ZRaporuPage> createState() => _ZRaporuPageState();
}

class _ZRaporuPageState extends State<ZRaporuPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;
  Color get _kBlue => _scheme.primary;
  Color get _kBorder => _scheme.outlineVariant;
  Color get _kGreen => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFF6EE7B7)
      : Color(0xFF16704A);
  Color get _kRed => _scheme.error;
  bool _loadingKasalar = true;
  bool _sorgulaniyor = false;
  bool _yazdiriliyor = false;
  bool _sorgulandi = false;
  bool _ayrintili = false;

  List<KasaDto> _kasalar = [];
  KasaDto? _seciliKasa;

  late DateTime _tarih1;
  late DateTime _tarih2;

  List<KasahareketDto> _hareketler = [];

  final _dateFmt = DateFormat('dd.MM.yyyy');
  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tarih1 = DateTime(now.year, now.month, now.day);
    _tarih2 = _tarih1;
    _loadKasalar();
  }

  Future<void> _loadKasalar() async {
    setState(() => _loadingKasalar = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final kasalar = await KasaTanimService().getAllWithoutAuth(token);
      // Plasiyer kullanıcıda varsayılan kasa = plasiyerin kasası
      final kp = await KullaniciPlasiyerHelper.getir();
      KasaDto? plasiyerKasa;
      if (kp.kilitli) {
        plasiyerKasa = await PlasiyerKasaHelper.getir(token, kp.plasiyerid,
            mevcutKasalar: kasalar, kilitli: true);
      }
      if (mounted)
        setState(() {
          _kasalar = kasalar;
          _seciliKasa = kasalar
                  .where((k) => k.Id != null && k.Id == plasiyerKasa?.Id)
                  .firstOrNull ??
              kasalar.firstOrNull;
          _loadingKasalar = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingKasalar = false);
        UiFeedback.showError(context, e.toString());
      }
    }
  }

  Future<void> _sorgula() async {
    if (_seciliKasa?.Id == null) {
      UiFeedback.showError(context, 'Lütfen kasa seçiniz.');
      return;
    }
    setState(() => _sorgulaniyor = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final tum = await KasaIslemService()
          .getKasahareketByKasaid(token, _seciliKasa!.Id!);
      final bitisSonu =
          DateTime(_tarih2.year, _tarih2.month, _tarih2.day, 23, 59, 59);
      final filtreli = tum.where((h) {
        if (h.Tarih == null) return false;
        return !h.Tarih!.isBefore(_tarih1) && !h.Tarih!.isAfter(bitisSonu);
      }).toList()
        ..sort((a, b) =>
            (b.Tarih ?? DateTime(0)).compareTo(a.Tarih ?? DateTime(0)));
      if (!mounted) return;
      setState(() {
        _hareketler = filtreli;
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

  double get _toplamTahsilat => _hareketler
      .where((h) => h.Giriscikis == 1)
      .fold(0.0, (s, e) => s + (e.Tutar ?? 0));
  double get _toplamOdeme => _hareketler
      .where((h) => h.Giriscikis == 2)
      .fold(0.0, (s, e) => s + (e.Tutar ?? 0));

  String? _karsiTaraf(KasahareketDto h) {
    switch (h.Islemtipi) {
      case 1:
        return h.IslemcariAd;
      case 2:
        return h.IslembankahesapAd;
      case 3:
        return h.IslemkasaAd;
      default:
        return null;
    }
  }

  Future<void> _yazdir() async {
    if (_hareketler.isEmpty && _toplamTahsilat == 0 && _toplamOdeme == 0) {
      UiFeedback.showWarning(context, 'Yazdırılacak veri yok.');
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

      final satirlar = _ayrintili
          ? _hareketler
              .map((h) => ZRaporuSatir(
                    tarih: h.Tarih ?? DateTime.now(),
                    yon: h.Giriscikis == 1 ? 'TAHSİL' : 'ÖDEME',
                    aciklama: _karsiTaraf(h) ?? h.Aciklama ?? '',
                    tutar: h.Tutar ?? 0,
                  ))
              .toList()
          : <ZRaporuSatir>[];

      final satirGen = await YaziciSablonService.instance.getSatirGenisligi();
      final prefs = await SharedPreferences.getInstance();
      final kullaniciAdi = prefs.getString('kullanici_adi');
      final bytes = svc.buildZRaporuFisi(
        kasaAd: _seciliKasa?.Ad ?? '-',
        tarih1: _tarih1,
        tarih2: _tarih2,
        toplamTahsilat: _toplamTahsilat,
        toplamOdeme: _toplamOdeme,
        satirlar: satirlar,
        satirGenisligi: satirGen,
        kullaniciAdi: kullaniciAdi,
      );
      final ok = await svc.printBytes(bytes);
      if (!mounted) return;
      if (ok) {
        UiFeedback.showSuccess(context, 'Z raporu yazıcıya gönderildi.');
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
      body: _loadingKasalar
          ? Center(child: CircularProgressIndicator())
          : Column(children: [
              _buildFiltreBar(),
              if (_sorgulandi) _buildOzetBar(),
              Expanded(
                child: _sorgulaniyor
                    ? Center(child: CircularProgressIndicator())
                    : !_sorgulandi
                        ? _buildBaslangic()
                        : (!_ayrintili || _hareketler.isEmpty)
                            ? _buildOzetMesaji()
                            : _buildListe(),
              ),
            ]),
    );
  }

  PreferredSizeWidget _buildAppBar() => ErpPageAppBar(
        context: context,
        title: const Text('Z Raporu'),
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        actions: [
          if (_sorgulandi)
            IconButton(
                tooltip: 'Yazdır',
                onPressed: _yazdiriliyor ? null : _yazdir,
                icon: _yazdiriliyor
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.print_outlined))
        ],
      );

  Widget _buildFiltreBar() => Container(
        color: _scheme.surface,
        padding: EdgeInsets.fromLTRB(14, 10, 14, 12),
        child: Column(children: [
          _kasaSecici(),
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
          SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: Row(children: [
              Switch(
                  value: _ayrintili,
                  onChanged: (v) => setState(() => _ayrintili = v)),
              const Text('Ayrıntılı', style: TextStyle(fontSize: 12))
            ])),
            FilledButton.icon(
                style: FilledButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8)),
                onPressed: _sorgulaniyor ? null : _sorgula,
                icon: const Icon(Icons.search_rounded, size: 18),
                label: const Text('Sorgula')),
          ]),
        ]),
      );

  Widget _kasaSecici() => PopupMenuButton<KasaDto>(
        padding: EdgeInsets.zero,
        position: PopupMenuPosition.under,
        onSelected: (v) => setState(() => _seciliKasa = v),
        itemBuilder: (context) => _kasalar
            .map((k) => PopupMenuItem<KasaDto>(
                  value: k,
                  child: Text('${k.Kod ?? ''} - ${k.Ad ?? ''}',
                      style: TextStyle(fontFamily: 'Roboto', fontSize: 13.5)),
                ))
            .toList(),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _kBorder)),
          child: Row(children: [
            Icon(Icons.account_balance_wallet_outlined,
                size: 17, color: _scheme.onSurfaceVariant),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                  _seciliKasa != null
                      ? '${_seciliKasa!.Kod ?? ''} - ${_seciliKasa!.Ad ?? ''}'
                      : 'Kasa seçiniz',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: _kDark),
                  overflow: TextOverflow.ellipsis),
            ),
            Icon(Icons.expand_more_rounded,
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
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                ])),
          ]),
        ),
      );

  Widget _buildOzetBar() => Container(
        color: _scheme.surface,
        padding: EdgeInsets.fromLTRB(14, 0, 14, 10),
        child: Row(children: [
          Expanded(
              child: _ozetKutu(
                  'Tahsilat', _moneyFmt.format(_toplamTahsilat), _kGreen)),
          _dikeyAyrac(),
          Expanded(
              child: _ozetKutu('Ödeme', _moneyFmt.format(_toplamOdeme), _kRed)),
          _dikeyAyrac(),
          Expanded(
              child: _ozetKutu('Net',
                  _moneyFmt.format(_toplamTahsilat - _toplamOdeme), _kBlue)),
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
        FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$deger ₺',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: renk),
                overflow: TextOverflow.ellipsis)),
      ]);

  Widget _buildBaslangic() => Center(
      child:
          Text('Z Raporu', style: TextStyle(color: _scheme.onSurfaceVariant)));
  Widget _buildOzetMesaji() => Center(
      child: _hareketler.isEmpty
          ? Text('İşlem bulunamadı',
              style: TextStyle(color: _scheme.onSurfaceVariant))
          : TextButton.icon(
              onPressed: () => setState(() => _ayrintili = true),
              icon: const Icon(Icons.list_alt_rounded),
              label: Text('${_hareketler.length} İşlemi Göster')));

  Widget _buildListe() => ListView.builder(
        padding: EdgeInsets.fromLTRB(14, 8, 14, 24),
        itemCount: _hareketler.length,
        itemBuilder: (_, i) => _buildSatir(_hareketler[i]),
      );

  Widget _buildSatir(KasahareketDto h) {
    final giris = h.Giriscikis == 1;
    return ErpFinanceCard(
        title: _karsiTaraf(h) ?? h.Aciklama ?? '-',
        icon: giris ? Icons.south_west_rounded : Icons.north_east_rounded,
        metadata: [
          if (h.Tarih != null) _dateFmt.format(h.Tarih!),
          if ((h.Aciklama ?? '').isNotEmpty &&
              _karsiTaraf(h)?.isNotEmpty == true &&
              _karsiTaraf(h) != h.Aciklama)
            h.Aciklama!
        ],
        amount: '${giris ? '+' : '-'}${_moneyFmt.format(h.Tutar ?? 0)} ₺',
        amountColor: giris ? _kGreen : _kRed,
        secondaryAmount: giris ? 'Tahsilat' : 'Ödeme');
  }
}
