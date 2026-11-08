import '../../../widgets/erp_page_style.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/entities/fatura/resolve/alis_fatura_resolve_result.dart';
import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/stok/stok_list_dto.dart';
import '../../../models/entities/stok/stokcari_create_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../services/fatura/alis_fatura_resolve_service.dart';
import '../../../services/cari/cari_service.dart';
import '../../../services/stok/stok_service.dart';
import '../../../services/stok/stokcari_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../widgets/erp_selector.dart';

class FaturaTaramaPage extends StatefulWidget {
  const FaturaTaramaPage({super.key});

  @override
  State<FaturaTaramaPage> createState() => _FaturaTaramaPageState();
}

class _FaturaTaramaPageState extends State<FaturaTaramaPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _positive => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFF6EE7B7)
      : Color(0xFF16704A);
  Color get _kDark => _scheme.onSurface;
  Color get _kBg => Theme.of(context).scaffoldBackgroundColor;
  Color get _kBlue => _scheme.primary;
  Color get _kGreen => _positive;
  Color get _kRed => _scheme.error;
  Color get _kAmber => _scheme.primary;
  Color get _kBorder => _scheme.outlineVariant;

  File? _secilenDosya;
  bool _okunuyor = false;
  bool _senkronizeEdiliyor = false;
  String? _hata;
  AlisFaturaResolveResult? _sonuc;

  List<CariDtoLite> _cariler = [];
  List<StokListDto> _stoklar = [];
  List<DovizDto> _dovizler = [];
  bool _eslestiriliyor = false;

  final _dateFmt = DateFormat('dd.MM.yyyy');
  final _moneyFmt = NumberFormat('#,##0.00', 'tr_TR');

  Future<void> _resimSec(ImageSource kaynak) async {
    try {
      final picked = await ImagePicker()
          .pickImage(source: kaynak, imageQuality: 90, maxWidth: 2400);
      if (picked == null) return;
      setState(() {
        _secilenDosya = File(picked.path);
        _sonuc = null;
        _hata = null;
      });
      await _oku();
    } catch (e) {
      if (mounted) setState(() => _hata = 'Görüntü seçilemedi: $e');
    }
  }

  Future<void> _oku() async {
    if (_secilenDosya == null) return;
    setState(() {
      _okunuyor = true;
      _hata = null;
      _sonuc = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final bytes = await _secilenDosya!.readAsBytes();
      final dosyaAdi = _secilenDosya!.path.split(Platform.pathSeparator).last;
      final sonuc = await AlisFaturaResolveService()
          .resolveFromImage(token, bytes, dosyaAdi);
      if (!mounted) return;
      setState(() {
        _sonuc = sonuc;
        _okunuyor = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hata = e.toString().replaceFirst('Exception: ', '');
        _okunuyor = false;
      });
    }
  }

  /// Kullanıcı eksik cari/stok kaydını oluşturduktan sonra, aynı sonucu
  /// backend'e geri gönderip eşleştirmeyi (Eksikler/KaydaHazir) yeniden hesaplatır.
  Future<void> _senkronizeEt() async {
    if (_sonuc == null) return;
    setState(() => _senkronizeEdiliyor = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final yeni = await AlisFaturaResolveService().resolve(token, _sonuc!.raw);
      if (!mounted) return;
      setState(() {
        _sonuc = yeni;
        _senkronizeEdiliyor = false;
      });
      if (yeni.kaydaHazir) {
        UiFeedback.showSuccess(context, 'Fatura kayda hazır.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _senkronizeEdiliyor = false);
      UiFeedback.showError(
          context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Ham JSON içinde ilgili anahtarı (Pascal/camel hangisi mevcutsa) günceller.
  void _setRaw(Map<String, dynamic> m, String pascalKey, dynamic value) {
    final camel = pascalKey[0].toLowerCase() + pascalKey.substring(1);
    if (m.containsKey(pascalKey)) {
      m[pascalKey] = value;
    } else if (m.containsKey(camel)) {
      m[camel] = value;
    } else {
      m[pascalKey] = value;
    }
  }

  Map<String, dynamic>? get _ustbilgiRaw {
    final u = _sonuc?.raw['Ustbilgi'] ?? _sonuc?.raw['ustbilgi'];
    return u as Map<String, dynamic>?;
  }

  /// Var olan bir Cari'yi eksik satıcı eşleşmesine bağlar: AI'nın çıkardığı
  /// VKN/unvan alanlarını seçilen carinin gerçek bilgileriyle değiştirip
  /// backend'in (VKN/unvan birebir eşleşmesiyle çalışan) eşleştiricisinin
  /// artık bu cariyi bulmasını sağlar, sonra senkronize eder.
  Future<void> _cariSec() async {
    final ustbilgi = _ustbilgiRaw;
    if (ustbilgi == null) return;
    setState(() => _eslestiriliyor = true);
    try {
      if (_cariler.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token_final') ?? '';
        _cariler = await CariService().getCariler(token);
      }
      if (!mounted) return;
      setState(() => _eslestiriliyor = false);

      final secilen = await showErpSelector<CariDtoLite>(
        context: context,
        title: 'Cari Seç',
        hintText: 'Cari adı, kodu veya VKN ara...',
        items: _cariler,
        itemText: (c) => '${c.Kod ?? ''} - ${c.Ad ?? ''}',
      );
      if (secilen == null) return;

      _setRaw(ustbilgi, 'KaynakSaticiVergino', secilen.Vergino);
      _setRaw(ustbilgi, 'KaynakSaticiUnvan', secilen.Ad);
      await _senkronizeEt();
    } catch (e) {
      if (!mounted) return;
      setState(() => _eslestiriliyor = false);
      UiFeedback.showError(
          context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Var olan bir Döviz'i eşleştirir: backend Doviz.Birim ile KaynakDovizKodu'nun
  /// birebir eşleşmesine bakıyor, o yüzden seçilen dövizin Birim'ini yazıp senkronize ediyoruz.
  Future<void> _dovizSec() async {
    final ustbilgi = _ustbilgiRaw;
    if (ustbilgi == null) return;
    setState(() => _eslestiriliyor = true);
    try {
      if (_dovizler.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token_final') ?? '';
        _dovizler = await DovizService().getDovizler(token);
      }
      if (!mounted) return;
      setState(() => _eslestiriliyor = false);

      final secilen = await showErpSelector<DovizDto>(
        context: context,
        title: 'Döviz Seç',
        hintText: 'Döviz adı veya birimi ara...',
        items: _dovizler,
        itemText: (d) => '${d.Birim ?? ''} - ${d.Ad ?? ''}',
      );
      if (secilen == null) return;

      _setRaw(ustbilgi, 'KaynakDovizKodu', secilen.Birim);
      await _senkronizeEt();
    } catch (e) {
      if (!mounted) return;
      setState(() => _eslestiriliyor = false);
      UiFeedback.showError(
          context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  /// Var olan bir Stok'u eksik satıra bağlar: cari + AI'nın çıkardığı satıcı
  /// stok kodunu seçilen Stok'a eşleyen bir Stokcari kaydı oluşturur, sonra
  /// senkronize eder. Bu, İhesapp web'deki "Stok Seç" akışının backend
  /// karşılığıdır (Stokcari.Kod ↔ KaynakSaticiStokkodu eşleşmesi).
  Future<void> _stokSec(AlisFaturaResolveHareketlerModel h) async {
    final cariid = _sonuc?.ustbilgi.resolvedCariId;
    if (cariid == null) {
      UiFeedback.showWarning(
          context, 'Önce satıcı cariyi eşleştirin (Cari Seç + Senkronize Et).');
      return;
    }
    setState(() => _eslestiriliyor = true);
    try {
      if (_stoklar.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('token_final') ?? '';
        _stoklar = await StokService().getStokList(token);
      }
      if (!mounted) return;
      setState(() => _eslestiriliyor = false);

      final secilen = await showErpSelector<StokListDto>(
        context: context,
        title: 'Stok Seç',
        hintText: 'Stok adı, kodu veya barkod ara...',
        items: _stoklar,
        itemText: (s) => '${s.Kod ?? ''} - ${s.Ad ?? ''}',
        getBarcodes: (s) => s.getBarkodListesi(),
        getUnit: (s) => s.TemelolcubrAd ?? '',
      );
      if (secilen == null) return;

      // Eşleşme için Kod alanı boş olamaz — satıcı stok kodu yoksa barkoda,
      // o da yoksa stok adına düşülür (en azından biri genelde AI'dan gelir).
      final kod = [h.kaynakSaticiStokkodu, h.kaynakBarkod, h.kaynakStokadi]
          .firstWhere((v) => v != null && v.isNotEmpty, orElse: () => null);
      if (kod == null) {
        if (mounted)
          UiFeedback.showError(context,
              'Bu satırda eşleştirme için kullanılabilecek bir stok kodu/adı bulunamadı.');
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token_final') ?? '';
      final dto = StokcariCreateDto()
        ..stokid = secilen.Id
        ..cariid = cariid
        ..aktif = true
        ..kod = kod
        ..ad = h.kaynakStokadi
        ..barkod = h.kaynakBarkod
        // Backend'in KaynakOlcubrkodu'ndan çözdüğü ölçü birimi — hem eşleşme
        // koşulu (MatchCariOlcubr) hem de satırın ölçü birimi için gerekli.
        ..cariolcubrid = h.cariolcubrid
        ..olcubrid = h.cariolcubrid;
      await StokcariService().create(token, dto);
      await _senkronizeEt();
    } catch (e) {
      if (!mounted) return;
      setState(() => _eslestiriliyor = false);
      UiFeedback.showError(
          context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kBg,
      appBar: ErpPageAppBar(
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
            child:
                Icon(Icons.document_scanner_rounded, size: 17, color: _kBlue),
          ),
          SizedBox(width: 10),
          Text('Fatura Tara',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontWeight: FontWeight.w700,
                  fontSize: 15.5,
                  color: _kDark)),
        ]),
        bottom: PreferredSize(
            preferredSize: Size.fromHeight(1),
            child: Container(height: 1, color: _kBorder)),
      ),
      body: ListView(
        padding: EdgeInsets.all(14),
        children: [
          _buildUyariKarti(),
          SizedBox(height: 14),
          _buildSecimKarti(),
          if (_secilenDosya != null) ...[
            SizedBox(height: 14),
            _buildOnizleme(),
          ],
          if (_okunuyor) ...[
            SizedBox(height: 14),
            _buildYukleniyor(),
          ],
          if (_hata != null) ...[
            SizedBox(height: 14),
            _buildHataKarti(),
          ],
          if (_sonuc != null) ...[
            SizedBox(height: 14),
            _buildSonuc(),
          ],
        ],
      ),
    );
  }

  Widget _buildUyariKarti() => Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _scheme.primary.withValues(alpha: .08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _scheme.primary.withValues(alpha: .3))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded, size: 18, color: _scheme.primary),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Okunan bilgileri kontrol edin.',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11.5,
                  color: _scheme.primary,
                  height: 1.4),
            ),
          ),
        ]),
      );

  Widget _buildSecimKarti() => Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fatura Görseli',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _kDark)),
          SizedBox(height: 10),
          Row(children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed:
                      _okunuyor ? null : () => _resimSec(ImageSource.camera),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: _scheme.onPrimary,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  icon: Icon(Icons.camera_alt_rounded, size: 18),
                  label: Text('Kamera',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: SizedBox(
                height: 44,
                child: OutlinedButton.icon(
                  onPressed:
                      _okunuyor ? null : () => _resimSec(ImageSource.gallery),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: _kDark,
                      side: BorderSide(color: _kBorder),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10))),
                  icon: Icon(Icons.photo_library_outlined, size: 18),
                  label: Text('Galeriden Seç',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 13,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ),
          ]),
        ]),
      );

  Widget _buildOnizleme() => Container(
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder)),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Image.file(_secilenDosya!,
              height: 180, width: double.infinity, fit: BoxFit.cover),
          Padding(
            padding: EdgeInsets.all(10),
            child: SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                onPressed: _okunuyor ? null : _oku,
                style: OutlinedButton.styleFrom(
                    foregroundColor: _kBlue,
                    side: BorderSide(color: _kBlue.withOpacity(0.4)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9))),
                icon: Icon(Icons.refresh_rounded, size: 16),
                label: Text('Yeniden Oku',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        ]),
      );

  Widget _buildYukleniyor() => Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder)),
        child: Column(children: [
          SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.4)),
          SizedBox(height: 12),
          Text('Fatura okunuyor...',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12.5,
                  color: _scheme.onSurfaceVariant)),
        ]),
      );

  Widget _buildHataKarti() => Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: _kRed.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _kRed.withOpacity(0.25))),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.error_rounded, size: 18, color: _kRed),
          SizedBox(width: 10),
          Expanded(
              child: Text(_hata!,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12,
                      color: _kRed,
                      height: 1.4))),
        ]),
      );

  Widget _buildSonuc() {
    final s = _sonuc!;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _buildDurumKarti(s),
      SizedBox(height: 14),
      _buildUstbilgiKarti(s.ustbilgi),
      SizedBox(height: 14),
      _buildKalemlerKarti(s.hareketler),
    ]);
  }

  Widget _buildDurumKarti(AlisFaturaResolveResult s) {
    final hazir = s.kaydaHazir;
    final toplamEksik = s.ustbilgi.eksikler.length +
        s.hareketler.fold<int>(0, (t, h) => t + h.eksikler.length);
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: (hazir ? _kGreen : _kAmber).withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: (hazir ? _kGreen : _kAmber).withOpacity(0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(hazir ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
              size: 20, color: hazir ? _kGreen : _kAmber),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              hazir
                  ? 'Fatura kayda hazır'
                  : '$toplamEksik eksik bilgi var — aşağıdan eşleştirin, sonra senkronize edin',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: hazir ? _kGreen : _kAmber),
            ),
          ),
        ]),
        if (!hazir) ...[
          SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 38,
            child: OutlinedButton.icon(
              onPressed: _senkronizeEdiliyor ? null : _senkronizeEt,
              style: OutlinedButton.styleFrom(
                  foregroundColor: _kAmber,
                  side: BorderSide(color: _kAmber.withOpacity(0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(9))),
              icon: _senkronizeEdiliyor
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(Icons.sync_rounded, size: 16),
              label: Text('Senkronize Et',
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _buildUstbilgiKarti(AlisFaturaResolveUstbilgiModel u) => Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.receipt_long_rounded, size: 16, color: _kBlue),
            SizedBox(width: 8),
            Text('Üst Bilgi',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kDark)),
          ]),
          SizedBox(height: 10),
          _satir('Fatura No', u.kaynakFaturaNo),
          _satir('Fatura Tarihi',
              u.kaynakTarih != null ? _dateFmt.format(u.kaynakTarih!) : null),
          _satir('Döviz', u.kaynakDovizKodu),
          Divider(height: 20, color: _kBorder),
          _satir('Satıcı', u.kaynakSaticiUnvan),
          _satir('Satıcı VKN', u.kaynakSaticiVergino),
          Divider(height: 20, color: _kBorder),
          _satir('Alıcı', u.kaynakAliciUnvan),
          _satir('Alıcı VKN', u.kaynakAliciVergino),
          Divider(height: 20, color: _kBorder),
          _satir(
              'Ara Toplam',
              u.kaynakAratoplam != null
                  ? _moneyFmt.format(u.kaynakAratoplam)
                  : null),
          _satir(
              'KDV Toplam',
              u.kaynakKdvtutar != null
                  ? _moneyFmt.format(u.kaynakKdvtutar)
                  : null),
          _satir(
              'Genel Toplam',
              u.kaynakGeneltoplam != null
                  ? _moneyFmt.format(u.kaynakGeneltoplam)
                  : null,
              vurgu: true),
          if (u.eksikler.isNotEmpty) ...[
            SizedBox(height: 10),
            ...u.eksikler.map(_eksikSatiri),
          ],
        ]),
      );

  Widget _buildKalemlerKarti(
          List<AlisFaturaResolveHareketlerModel> hareketler) =>
      Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: _scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kBorder)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.inventory_2_rounded, size: 16, color: _kBlue),
            SizedBox(width: 8),
            Text('Kalemler (${hareketler.length})',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _kDark)),
          ]),
          SizedBox(height: 10),
          ...hareketler.map(_kalemKutusu),
        ]),
      );

  Widget _kalemKutusu(AlisFaturaResolveHareketlerModel h) => Container(
        margin: EdgeInsets.only(bottom: 8),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: h.kaydaHazir ? _kBg : _kAmber.withOpacity(0.06),
          borderRadius: BorderRadius.circular(9),
          border:
              h.kaydaHazir ? null : Border.all(color: _kAmber.withOpacity(0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${h.sira}. ${h.kaynakStokadi ?? '-'}',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _kDark)),
          SizedBox(height: 3),
          Text(
            '${_miktarStr(h.kaynakMiktar)} ${h.kaynakOlcubrkodu ?? ''}  ×  ${h.kaynakBirimFiyat != null ? _moneyFmt.format(h.kaynakBirimFiyat) : '-'}  •  KDV %${h.kaynakKdvorani != null ? h.kaynakKdvorani!.toStringAsFixed(0) : '-'}  •  Tutar: ${h.kaynakSatirTutari != null ? _moneyFmt.format(h.kaynakSatirTutari) : '-'}',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                color: _scheme.onSurfaceVariant),
          ),
          if (h.kaynakSaticiStokkodu != null &&
              h.kaynakSaticiStokkodu!.isNotEmpty) ...[
            SizedBox(height: 2),
            Text('Satıcı Stok Kodu: ${h.kaynakSaticiStokkodu}',
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 10.5,
                    color: _scheme.onSurfaceVariant)),
          ],
          if (h.eksikler.isNotEmpty) ...[
            SizedBox(height: 6),
            ...h.eksikler.map((e) => _eksikSatiri(e, hareket: h)),
          ],
        ]),
      );

  String _miktarStr(double? v) =>
      v == null ? '-' : NumberFormat('#,##0.####', 'tr_TR').format(v);

  Widget _eksikSatiri(AlisFaturaResolveEksiklerModel e,
          {AlisFaturaResolveHareketlerModel? hareket}) =>
      Padding(
        padding: EdgeInsets.only(top: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.error_outline_rounded, size: 13, color: _kAmber),
          SizedBox(width: 5),
          Expanded(
            child: Text(
              e.kaynakDeger != null && e.kaynakDeger!.isNotEmpty
                  ? '${e.mesaj} ("${e.kaynakDeger}")'
                  : e.mesaj,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 11,
                  color: _kAmber,
                  height: 1.3),
            ),
          ),
          if (e.eksikTipi == EksikTipiCouples.cariBulunamadi) ...[
            SizedBox(width: 6),
            _eslestirButonu('Cari Seç', _eslestiriliyor ? null : _cariSec),
          ] else if (e.eksikTipi == EksikTipiCouples.dovizBulunamadi) ...[
            SizedBox(width: 6),
            _eslestirButonu('Döviz Seç', _eslestiriliyor ? null : _dovizSec),
          ] else if (e.eksikTipi == EksikTipiCouples.stokBulunamadi &&
              hareket != null) ...[
            SizedBox(width: 6),
            _eslestirButonu(
                'Stok Seç', _eslestiriliyor ? null : () => _stokSec(hareket)),
          ],
        ]),
      );

  Widget _eslestirButonu(String label, VoidCallback? onTap) => InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
              color: _kAmber.withOpacity(onTap == null ? 0.06 : 0.12),
              borderRadius: BorderRadius.circular(7)),
          child: Text(label,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: _kAmber.withOpacity(onTap == null ? 0.5 : 1))),
        ),
      );

  Widget _satir(String label, String? deger, {bool vurgu = false}) {
    if (deger == null || deger.isEmpty) return SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.only(bottom: 6),
      child: Row(children: [
        SizedBox(
            width: 110,
            child: Text(label,
                style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: _scheme.onSurfaceVariant))),
        Expanded(
          child: Text(deger,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: vurgu ? 13.5 : 12.5,
                  fontWeight: vurgu ? FontWeight.w800 : FontWeight.w600,
                  color: vurgu ? _kGreen : _kDark)),
        ),
      ]),
    );
  }
}
