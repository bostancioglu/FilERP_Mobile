import '../../../theme/app_theme.dart';
import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../helpers/plasiyer_depo_helper.dart';
import '../../../helpers/plasiyer_kasa_helper.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/depo/depo_dto.dart';
import '../../../models/entities/finans/banka/bankahesap_dto.dart';
import '../../../models/entities/finans/kasa_islem/kasa_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/stok/stok_list_dto.dart';
import '../../../services/cari/cari_service.dart';
import '../../../services/depo/depo_service.dart';
import '../../../services/finans/bankahesap_service.dart';
import '../../../services/finans/kasa_tanim_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../services/rapor/rapor_tablo_aktar.dart';
import '../../../services/stok/stok_service.dart';
import '../../../widgets/erp_selector.dart';
import 'rapor_modelleri.dart';

/// Tüm yeni raporlar için ortak sayfa: filtre sayfası + özet çubuğu + arama + kartlı liste + Excel/PDF.
/// Her rapor bir [RaporTanim] ile tarif edilir (bkz. rapor_tanimlari.dart).
class RaporSayfasi extends StatefulWidget {
  final RaporTanim tanim;

  /// Detay ekranından açılırken hazır filtre (ör. seçili cari + tarih aralığı).
  final RaporFiltre? baslangicFiltre;

  const RaporSayfasi({super.key, required this.tanim, this.baslangicFiltre});

  @override
  State<RaporSayfasi> createState() => _RaporSayfasiState();
}

class _RaporSayfasiState extends State<RaporSayfasi> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.primary;
  Color get _accent => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;
  Color get _borcRenk => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFFFF9C9C)
      : Color(0xFFB3261E);
  Color get _alacakRenk => Theme.of(context).brightness == Brightness.dark
      ? Color(0xFF6EE7B7)
      : Color(0xFF16704A);

  late RaporFiltre _f;
  RaporSonuc? _sonuc;
  bool _yukleniyor =
      true; // ilk sorgu plasiyer varsayılanları belirlendikten sonra çalışır
  String _ara = '';

  // Seçim listeleri: filtre sayfasında ilk ihtiyaç duyulunca yüklenir.
  List<CariDtoLite>? _cariler;
  List<StokListDto>? _stoklar;
  List<DepoDto>? _depolar;
  List<KasaDto>? _kasalar;
  List<BankahesapDto>? _bankalar;
  List<DovizDto>? _dovizler;

  RaporTanim get t => widget.tanim;

  @override
  void initState() {
    super.initState();
    _f = widget.baslangicFiltre ?? t.varsayilanFiltre();
    _baslat();
  }

  Future<void> _baslat() async {
    // Başka rapordan detay olarak açılmışsa (hazır filtre) varsayılanlara dokunulmaz.
    if (widget.baslangicFiltre == null) await _plasiyerVarsayilanlari();
    if (mounted) _sorgula();
  }

  /// Plasiyer kullanıcıda depo = plasiyerin (araç) deposu, kasa = plasiyerin kasası olarak seçili gelir.
  Future<void> _plasiyerVarsayilanlari() async {
    final depoVar = t.filtreler.contains(RaporFiltreTuru.depo);
    final kasaVar = t.filtreler.contains(RaporFiltreTuru.kasa);
    if (!depoVar && !kasaVar) return;
    final kp = await KullaniciPlasiyerHelper.getir();
    if (!kp.kilitli || !mounted) return;
    final token = await _token();
    if (depoVar) {
      _depolar = await _yukle(_depolar, (tk) => DepoService().getDepoList(tk));
      final depoId = await PlasiyerDepoHelper.getId(token, kp.plasiyerid,
          kilitli: true, mevcutDepolar: _depolar);
      if (depoId != null)
        _f.depo = _depolar!.where((d) => d.id == depoId).firstOrNull;
    }
    if (kasaVar) {
      _kasalar = await _yukle(
          _kasalar, (tk) => KasaTanimService().getAllWithoutAuth(tk));
      _f.kasa = await PlasiyerKasaHelper.getir(token, kp.plasiyerid,
          mevcutKasalar: _kasalar, kilitli: true);
    }
  }

  Future<String> _token() async =>
      (await SharedPreferences.getInstance()).getString('token_final') ?? '';

  Future<void> _sorgula() async {
    setState(() => _yukleniyor = true);
    try {
      final s = await t.getir(_f);
      if (mounted)
        setState(() {
          _sonuc = s;
          _yukleniyor = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _yukleniyor = false);
        UiFeedback.showException(context, e);
      }
    }
  }

  // ── Filtre özeti (başlık altı şerit + dışa aktarma) ──────────────────────────
  String get _filtreOzeti {
    final p = <String>[];
    if (t.filtreler.contains(RaporFiltreTuru.tarih)) {
      p.add(
          '${_f.tarih1 != null ? rapTarih(_f.tarih1) : 'Başlangıç'} - ${_f.tarih2 != null ? rapTarih(_f.tarih2) : 'Bugün'}');
    }
    if (_f.cari != null) p.add('Cari: ${_f.cari!.Kod ?? ''}');
    if (_f.stok != null) p.add('Stok: ${_f.stok!.Kod ?? ''}');
    if (_f.depo != null) p.add('Depo: ${_f.depo!.kod ?? ''}');
    if (_f.kasa != null) p.add('Kasa: ${_f.kasa!.Kod ?? ''}');
    if (_f.banka != null) p.add('Banka: ${_f.banka!.Kod ?? ''}');
    if (_f.doviz != null) p.add('Para birimi: ${_f.doviz!.Birim ?? ''}');
    if (t.filtreler.contains(RaporFiltreTuru.segment) &&
        t.segmentler.isNotEmpty) p.add(t.segmentler[_f.segment]);
    if (t.filtreler.contains(RaporFiltreTuru.segment2) &&
        t.segmentler2.isNotEmpty) p.add(t.segmentler2[_f.segment2]);
    if (t.filtreler.contains(RaporFiltreTuru.anahtar) && _f.anahtar)
      p.add(t.anahtarEtiketi);
    if ((_f.belgeno ?? '').isNotEmpty) p.add('Belge: ${_f.belgeno}');
    return p.join('  •  ');
  }

  bool get _filtreVar =>
      _f.cari != null ||
      _f.stok != null ||
      _f.depo != null ||
      _f.kasa != null ||
      _f.banka != null ||
      _f.doviz != null ||
      (_f.belgeno ?? '').isNotEmpty;

  // ── Lookups ───────────────────────────────────────────────────────────────────
  Future<List<T>> _yukle<T>(
      List<T>? onbellek, Future<List<T>> Function(String token) getir) async {
    if (onbellek != null) return onbellek;
    try {
      return await getir(await _token());
    } catch (e) {
      if (mounted) UiFeedback.showError(context, 'Liste alınamadı: $e');
      return <T>[];
    }
  }

  Future<void> _tarihSec(bool baslangic, void Function() yenile) async {
    final mevcut = (baslangic ? _f.tarih1 : _f.tarih2) ?? DateTime.now();
    final d = await showDatePicker(
        context: context,
        initialDate: mevcut,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100));
    if (d == null) return;
    setState(() => baslangic ? _f.tarih1 = d : _f.tarih2 = d);
    yenile();
  }

  // ── Filtre sayfası ────────────────────────────────────────────────────────────
  void _filtreSayfasi() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, yenile) {
        void y() => yenile(() {});

        Widget secici<T>({
          required String etiket,
          required IconData ikon,
          required T? deger,
          required String Function(T) yazi,
          required Future<void> Function() sec,
          required VoidCallback temizle,
        }) =>
            _seciciKutusu(etiket, ikon, deger == null ? null : yazi(deger),
                () async {
              await sec();
              y();
            },
                deger == null
                    ? null
                    : () {
                        setState(temizle);
                        y();
                      });

        final alanlar = <Widget>[];
        for (final k in t.filtreler) {
          switch (k) {
            case RaporFiltreTuru.tarih:
              alanlar.add(Row(children: [
                Expanded(
                    child: _tarihKutusu(
                        'Başlangıç',
                        _f.tarih1,
                        () => _tarihSec(true, y),
                        _f.tarih1 == null
                            ? null
                            : () {
                                setState(() => _f.tarih1 = null);
                                y();
                              })),
                SizedBox(width: 8),
                Expanded(
                    child: _tarihKutusu(
                        'Bitiş',
                        _f.tarih2,
                        () => _tarihSec(false, y),
                        _f.tarih2 == null
                            ? null
                            : () {
                                setState(() => _f.tarih2 = null);
                                y();
                              })),
              ]));
              break;
            case RaporFiltreTuru.cari:
              alanlar.add(secici<CariDtoLite>(
                etiket: 'Cari',
                ikon: Icons.business_outlined,
                deger: _f.cari,
                yazi: (c) => '${c.Kod ?? ''} - ${c.Ad ?? ''}',
                sec: () async {
                  _cariler = await _yukle(
                      _cariler, (tk) => CariService().getCariler(tk));
                  final s = await showErpSelector<CariDtoLite>(
                      context: context,
                      title: 'Cari Seç',
                      hintText: 'Cari adı veya kodu',
                      items: _cariler!,
                      itemText: (c) => '${c.Kod ?? ''} - ${c.Ad ?? ''}');
                  if (s != null) setState(() => _f.cari = s);
                },
                temizle: () => _f.cari = null,
              ));
              break;
            case RaporFiltreTuru.stok:
              alanlar.add(secici<StokListDto>(
                etiket: 'Stok',
                ikon: Icons.inventory_2_outlined,
                deger: _f.stok,
                yazi: (s) => '${s.Kod ?? ''} - ${s.Ad ?? ''}',
                sec: () async {
                  _stoklar = await _yukle(
                      _stoklar, (tk) => StokService().getStokList(tk));
                  final s = await showErpSelector<StokListDto>(
                      context: context,
                      title: 'Stok Seç',
                      hintText: 'Stok adı veya kodu',
                      items: _stoklar!,
                      itemText: (s) => '${s.Kod ?? ''} - ${s.Ad ?? ''}');
                  if (s != null) setState(() => _f.stok = s);
                },
                temizle: () => _f.stok = null,
              ));
              break;
            case RaporFiltreTuru.depo:
              alanlar.add(secici<DepoDto>(
                etiket: 'Depo',
                ikon: Icons.warehouse_outlined,
                deger: _f.depo,
                yazi: (d) => '${d.kod ?? ''} - ${d.ad ?? ''}',
                sec: () async {
                  _depolar = await _yukle(
                      _depolar, (tk) => DepoService().getDepoList(tk));
                  final s = await showErpSelector<DepoDto>(
                      context: context,
                      title: 'Depo Seç',
                      hintText: 'Depo adı veya kodu',
                      items: _depolar!,
                      itemText: (d) => '${d.kod ?? ''} - ${d.ad ?? ''}');
                  if (s != null) setState(() => _f.depo = s);
                },
                temizle: () => _f.depo = null,
              ));
              break;
            case RaporFiltreTuru.kasa:
              alanlar.add(secici<KasaDto>(
                etiket: 'Kasa',
                ikon: Icons.point_of_sale_rounded,
                deger: _f.kasa,
                yazi: (k) => '${k.Kod ?? ''} - ${k.Ad ?? ''}',
                sec: () async {
                  _kasalar = await _yukle(_kasalar,
                      (tk) => KasaTanimService().getAllWithoutAuth(tk));
                  final s = await showErpSelector<KasaDto>(
                      context: context,
                      title: 'Kasa Seç',
                      hintText: 'Kasa adı veya kodu',
                      items: _kasalar!,
                      itemText: (k) => '${k.Kod ?? ''} - ${k.Ad ?? ''}');
                  if (s != null) setState(() => _f.kasa = s);
                },
                temizle: () => _f.kasa = null,
              ));
              break;
            case RaporFiltreTuru.banka:
              alanlar.add(secici<BankahesapDto>(
                etiket: 'Banka Hesabı',
                ikon: Icons.account_balance_outlined,
                deger: _f.banka,
                yazi: (b) => '${b.Kod ?? ''} - ${b.Ad ?? ''}',
                sec: () async {
                  _bankalar = await _yukle(_bankalar,
                      (tk) => BankahesapService().getAllWithoutAuth(tk));
                  final s = await showErpSelector<BankahesapDto>(
                      context: context,
                      title: 'Banka Hesabı Seç',
                      hintText: 'Hesap adı veya kodu',
                      items: _bankalar!,
                      itemText: (b) => '${b.Kod ?? ''} - ${b.Ad ?? ''}');
                  if (s != null) setState(() => _f.banka = s);
                },
                temizle: () => _f.banka = null,
              ));
              break;
            case RaporFiltreTuru.doviz:
              alanlar.add(secici<DovizDto>(
                etiket: 'Para Birimi',
                ikon: Icons.currency_exchange_rounded,
                deger: _f.doviz,
                yazi: (d) => '${d.Birim ?? ''} - ${d.Ad ?? ''}',
                sec: () async {
                  _dovizler = await _yukle(
                      _dovizler, (tk) => DovizService().getDovizler(tk));
                  final s = await showErpSelector<DovizDto>(
                      context: context,
                      title: 'Para Birimi Seç',
                      hintText: 'Birim veya ad',
                      items: _dovizler!,
                      itemText: (d) => '${d.Birim ?? ''} - ${d.Ad ?? ''}');
                  if (s != null) setState(() => _f.doviz = s);
                },
                temizle: () => _f.doviz = null,
              ));
              break;
            case RaporFiltreTuru.segment:
              alanlar.add(_segmentKutusu(
                  t.segmentEtiketi, t.segmentler, _f.segment, (i) {
                setState(() => _f.segment = i);
                y();
              }));
              break;
            case RaporFiltreTuru.segment2:
              alanlar.add(_segmentKutusu(
                  t.segment2Etiketi, t.segmentler2, _f.segment2, (i) {
                setState(() => _f.segment2 = i);
                y();
              }));
              break;
            case RaporFiltreTuru.anahtar:
              alanlar.add(Material(
                  color: Colors.transparent,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    activeColor: _primary,
                    title: Text(t.anahtarEtiketi,
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    value: _f.anahtar,
                    onChanged: (v) {
                      setState(() => _f.anahtar = v);
                      y();
                    },
                  )));
              break;
          }
        }

        return Container(
          decoration: BoxDecoration(
              color: _scheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(
              16, 0, 16, MediaQuery.of(ctx).viewInsets.bottom + 16),
          child: SafeArea(
            top: false,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                  width: 40,
                  height: 4,
                  margin: EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                      color: _scheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2))),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Filtreler',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                if (_filtreVar)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _f.cari = null;
                        _f.stok = null;
                        _f.depo = null;
                        _f.kasa = null;
                        _f.banka = null;
                        _f.doviz = null;
                        _f.belgeno = null;
                      });
                      y();
                    },
                    icon: Icon(Icons.clear_all_rounded, size: 16),
                    label: Text('Temizle',
                        style: TextStyle(fontFamily: 'Roboto', fontSize: 13)),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.red.shade600),
                  ),
              ]),
              Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(children: [
                    for (final a in alanlar)
                      Padding(padding: EdgeInsets.only(bottom: 10), child: a),
                  ]),
                ),
              ),
              SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _yukleniyor
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _sorgula();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _scheme.surface,
                    foregroundColor: _scheme.onSurface,
                    padding: EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: Icon(Icons.search_rounded, size: 20),
                  label: Text('Sorgula',
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ),
              ),
            ]),
          ),
        );
      }),
    );
  }

  Widget _seciciKutusu(String etiket, IconData ikon, String? deger,
      VoidCallback onTap, VoidCallback? onClear) {
    final secili = deger != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  secili ? _primary.withOpacity(0.5) : _scheme.outlineVariant),
          color:
              secili ? _primary.withOpacity(0.04) : _scheme.surfaceContainerLow,
        ),
        child: Row(children: [
          Icon(ikon,
              size: 18, color: secili ? _primary : _scheme.onSurfaceVariant),
          SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(etiket,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: _scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              Text(secili ? deger : 'Tümü',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: secili ? _primary : _scheme.onSurfaceVariant)),
            ]),
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
  }

  Widget _tarihKutusu(String etiket, DateTime? d, VoidCallback onTap,
          VoidCallback? onClear) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _scheme.outlineVariant),
            color: _scheme.surfaceContainerLow,
          ),
          child: Row(children: [
            Icon(Icons.calendar_today_outlined,
                size: 14, color: _primary.withOpacity(0.7)),
            SizedBox(width: 6),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(etiket,
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 9,
                            color: _scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600)),
                    Text(
                        d != null
                            ? rapTarih(d)
                            : (etiket == 'Bitiş' ? 'Bugün' : 'Tümü'),
                        style: TextStyle(
                            fontFamily: 'Roboto',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: d != null
                                ? _primary
                                : _scheme.onSurfaceVariant)),
                  ]),
            ),
            if (onClear != null)
              GestureDetector(
                  onTap: onClear,
                  child: Icon(Icons.close_rounded,
                      size: 16, color: _scheme.onSurfaceVariant)),
          ]),
        ),
      );

  Widget _segmentKutusu(String etiket, List<String> secenekler, int secili,
          ValueChanged<int> degisti) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (etiket.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text(etiket,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 10,
                      color: _scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
            ),
          Wrap(spacing: 8, children: [
            for (var i = 0; i < secenekler.length; i++)
              ChoiceChip(
                label: Text(secenekler[i],
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: i == secili ? _scheme.onPrimary : _primary)),
                selected: i == secili,
                selectedColor: _primary,
                backgroundColor: _scheme.surface,
                side: BorderSide(color: _primary.withOpacity(0.3)),
                showCheckmark: false,
                onSelected: (_) => degisti(i),
              ),
          ]),
        ],
      );

  // ── Dışa aktarma ──────────────────────────────────────────────────────────────
  Future<void> _aktar(bool excel) async {
    final s = _sonuc;
    if (s == null || s.satirlar.isEmpty) return;
    try {
      final baslik = '${t.no} - ${t.baslik}';
      if (excel) {
        await RaporTabloAktar.excel(baslik, _filtreOzeti, s);
      } else {
        await RaporTabloAktar.pdf(baslik, _filtreOzeti, s);
      }
    } catch (e) {
      if (mounted)
        UiFeedback.showError(context, '${excel ? 'Excel' : 'PDF'} hatası: $e');
    }
  }

  // ── Görünüm ───────────────────────────────────────────────────────────────────
  List<RaporSatir> get _gorunenSatirlar {
    final s = _sonuc;
    if (s == null) return [];
    final q = _ara.trim().toLowerCase();
    if (q.isEmpty) return s.satirlar;
    return s.satirlar.where((r) {
      for (var j = 0; j < s.kolonlar.length && j < r.degerler.length; j++) {
        if (s.kolonlar[j].bicim(r.degerler[j]).toLowerCase().contains(q))
          return true;
      }
      return false;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final s = _sonuc;
    final dolu = s != null && s.satirlar.isNotEmpty;
    return Scaffold(
      backgroundColor: _surface,
      appBar: ErpPageAppBar(
        context: context,
        title: Text(t.baslik,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 16)),
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        actions: [
          if (dolu)
            PopupMenuButton<bool>(
                tooltip: 'Dışa Aktar',
                icon: Icon(Icons.ios_share_rounded, size: 21),
                onSelected: _aktar,
                itemBuilder: (_) => [
                      PopupMenuItem(value: true, child: Text("Excel'e Aktar")),
                      PopupMenuItem(value: false, child: Text("PDF'e Aktar"))
                    ]),
          Stack(children: [
            IconButton(
                icon: Icon(Icons.tune_rounded),
                tooltip: 'Filtreler',
                onPressed: _filtreSayfasi),
            if (_filtreVar)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                      color: _accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: _primary, width: 1.5)),
                ),
              ),
          ]),
          IconButton(
            icon: _yukleniyor
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _primary))
                : Icon(Icons.refresh_rounded),
            onPressed: _yukleniyor ? null : _sorgula,
          ),
        ],
      ),
      body: Column(children: [
        // Filtre özeti şeridi
        GestureDetector(
          onTap: _filtreSayfasi,
          child: Container(
            width: double.infinity,
            color: _scheme.surface,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              Icon(Icons.filter_alt_outlined,
                  size: 15, color: _scheme.onSurfaceVariant),
              SizedBox(width: 6),
              Expanded(
                child: Text(_filtreOzeti.isEmpty ? 'Filtreler' : _filtreOzeti,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: _scheme.onSurface)),
              ),
              Icon(Icons.expand_more_rounded,
                  size: 16, color: _scheme.onSurfaceVariant),
            ]),
          ),
        ),
        if (dolu) _ozetCubugu(s),
        if (dolu)
          Padding(
            padding: EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: TextField(
              onChanged: (v) => setState(() => _ara = v),
              decoration: InputDecoration(
                hintText: 'Listede ara…',
                hintStyle: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 13,
                    color: _scheme.onSurfaceVariant),
                prefixIcon: Icon(Icons.search_rounded, size: 20),
                isDense: true,
                filled: true,
                fillColor: _scheme.surface,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
        Expanded(
          child: _yukleniyor
              ? Center(child: CircularProgressIndicator())
              : s == null
                  ? SizedBox.shrink()
                  : s.satirlar.isEmpty
                      ? _bos()
                      : _liste(s),
        ),
      ]),
    );
  }

  Widget _ozetCubugu(RaporSonuc s) {
    final gor = _gorunenSatirlar;
    final cipler = <Widget>[
      _ozetCip(
          'Kayıt',
          gor.length == s.satirlar.length
              ? '${s.satirlar.length}'
              : '${gor.length} / ${s.satirlar.length}',
          _primary),
    ];
    for (var j = 0; j < s.kolonlar.length; j++) {
      final k = s.kolonlar[j];
      if (!k.toplamla) continue;
      final toplam = gor.fold<double>(
          0,
          (a, r) =>
              a +
              ((j < r.degerler.length && r.degerler[j] is num)
                  ? (r.degerler[j] as num).toDouble()
                  : 0));
      final renk = k.tip == RaporKolonTipi.bakiye
          ? (toplam > 0 ? _borcRenk : _alacakRenk)
          : _primary;
      cipler.add(_ozetCip(k.baslik, k.bicim(toplam), renk));
    }
    for (final o in s.ozetler) {
      cipler.add(_ozetCip(o.etiket, o.deger, _ozetRengi(o.renk)));
    }
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: _scheme.surface,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: Offset(0, 3))
        ],
      ),
      padding: EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          for (final c in cipler)
            Padding(padding: EdgeInsets.only(right: 8), child: c)
        ]),
      ),
    );
  }

  Color _ozetRengi(Color renk) {
    if (Theme.of(context).brightness != Brightness.dark) return renk;
    return HSLColor.fromColor(renk).withLightness(.76).toColor();
  }

  Widget _ozetCip(String etiket, String deger, Color renk) => Container(
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: renk.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: renk.withOpacity(0.25)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(etiket,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 9.5,
                  color: _scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
          Text(deger,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: renk)),
        ]),
      );

  Widget _liste(RaporSonuc s) {
    final satirlar = _gorunenSatirlar;
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: satirlar.length,
      itemBuilder: (_, i) => _kart(s.kolonlar, satirlar[i]),
    );
  }

  Widget _kart(List<RaporKolon> kolonlar, RaporSatir r) {
    if (const {'21', '22', '31', '42', '51', '52'}.contains(t.no))
      return _belgeKarti(kolonlar, r);
    final baslik = <String>[];
    final alanlar = <Widget>[];
    for (var j = 0; j < kolonlar.length && j < r.degerler.length; j++) {
      final k = kolonlar[j];
      final v = k.bicim(r.degerler[j]);
      if (k.baslikKolonu) {
        if (v.isNotEmpty) baslik.add(v);
        continue;
      }
      if (v.isEmpty) continue;
      var renk = _scheme.onSurface;
      if (k.tip == RaporKolonTipi.bakiye && r.degerler[j] is num) {
        final n = (r.degerler[j] as num).toDouble();
        if (n.abs() >= 0.005) renk = n > 0 ? _borcRenk : _alacakRenk;
      }
      final uzun = k.tip == RaporKolonTipi.metin && v.length > 24;
      alanlar.add(_Alan(k.baslik, v, renk, uzun));
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _scheme.surface,
        borderRadius:
            BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
        boxShadow: [
          BoxShadow(
              color: Colors.black
                  .withValues(alpha: ErpDesignStyle.modern(context) ? 0 : .04),
              blurRadius: 6,
              offset: Offset(0, 2))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius:
              BorderRadius.circular(ErpDesignStyle.modern(context) ? 18 : 12),
          onTap: r.detay == null ? null : () => r.detay!(context),
          child: Padding(
            padding: EdgeInsets.fromLTRB(12, 10, 12, 10),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                  child: Text(baslik.join('  •  '),
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: _primary)),
                ),
                if (r.detay != null)
                  Icon(Icons.chevron_right_rounded,
                      size: 20, color: _scheme.onSurfaceVariant),
              ]),
              if (alanlar.isNotEmpty) SizedBox(height: 8),
              LayoutBuilder(builder: (ctx, c) {
                final yarim = (c.maxWidth - 12) / 2;
                return Wrap(
                  spacing: 12,
                  runSpacing: 6,
                  children: [
                    for (final a in alanlar)
                      SizedBox(
                          width: (a as _Alan).uzun ? c.maxWidth : yarim,
                          child: a),
                  ],
                );
              }),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _belgeKarti(List<RaporKolon> kolonlar, RaporSatir r) {
    final basliklar = <String>[];
    final bilgiler = <Widget>[];
    final tutarlar = <Widget>[];
    for (var i = 0; i < kolonlar.length && i < r.degerler.length; i++) {
      final k = kolonlar[i];
      final value = k.bicim(r.degerler[i]);
      if (value.isEmpty) continue;
      if (k.baslikKolonu) {
        basliklar.add(value);
        continue;
      }
      final tutar =
          k.tip == RaporKolonTipi.tutar || k.tip == RaporKolonTipi.bakiye;
      final item = Text.rich(
          TextSpan(children: [
            TextSpan(
                text: '${k.baslik}: ',
                style: TextStyle(
                    color: _scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w400)),
            TextSpan(text: value),
          ]),
          style: TextStyle(
              fontSize: tutar ? 13 : 11,
              color: _scheme.onSurface,
              fontWeight: tutar ? FontWeight.w700 : FontWeight.w500));
      (tutar ? tutarlar : bilgiler).add(item);
    }
    return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: _scheme.surface,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(
                  ErpDesignStyle.modern(context) ? 18 : 12),
              side: BorderSide(
                  color: _scheme.outlineVariant.withValues(alpha: .6))),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: r.detay == null ? null : () => r.detay!(context),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              if (basliklar.isNotEmpty)
                                Text(basliklar.first,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: _scheme.onSurface)),
                              if (basliklar.length > 1)
                                Text(basliklar.skip(1).join(' • '),
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: _scheme.onSurfaceVariant)),
                            ])),
                        if (r.detay != null)
                          Icon(Icons.chevron_right_rounded,
                              size: 18, color: _scheme.onSurfaceVariant)
                      ]),
                      if (bilgiler.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(spacing: 12, runSpacing: 3, children: bilgiler)
                      ],
                      if (tutarlar.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Wrap(spacing: 16, runSpacing: 4, children: tutarlar)
                      ],
                    ]),
              )),
        ));
  }

  Widget _bos() => Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.inbox_outlined, size: 60, color: _scheme.outlineVariant),
          SizedBox(height: 12),
          Text('Kayıt bulunamadı',
              style: TextStyle(
                  fontFamily: 'Roboto',
                  color: _scheme.onSurfaceVariant,
                  fontSize: 15,
                  fontWeight: FontWeight.w500)),
        ]),
      );
}

class _Alan extends StatelessWidget {
  final String etiket;
  final String deger;
  final Color renk;
  final bool uzun;
  const _Alan(this.etiket, this.deger, this.renk, this.uzun);

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiket,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 9.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 1),
          Text(deger,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: renk)),
        ],
      );
}
