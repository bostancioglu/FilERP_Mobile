import '../../../widgets/erp_page_style.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../helpers/fis_yazdir_helper.dart';
import '../../../helpers/kullanici_plasiyer_helper.dart';
import '../../../helpers/plasiyer_depo_helper.dart';
import '../../../helpers/ui_feedback.dart';
import '../../../models/entities/cari/cari_dto_lite.dart';
import '../../../models/entities/depo/dat_dto.dart';
import '../../../models/entities/depo/depo_dto.dart';
import '../../../models/entities/fatura/fatura_list_dto.dart';
import '../../../models/entities/finans/tahsilat/tahsilat_dto.dart';
import '../../../models/entities/helper/doviz_dto.dart';
import '../../../models/entities/plasiyer/plasiyer_dto.dart';
import '../../../services/cari/cari_service.dart';
import '../../../services/depo/dat/dat_service.dart';
import '../../../services/depo/depo_service.dart';
import '../../../services/fatura/fatura_service.dart';
import '../../../services/finans/tahsilat_service.dart';
import '../../../services/helper/doviz_service.dart';
import '../../../services/plasiyer/plasiyer_service.dart';
import '../../../services/rapor/rapor_api.dart';
import '../../../services/rapor/rapor_tablo_aktar.dart';
import '../../../services/stok/stok_service.dart';
import '../../../services/yazici/fis_satir.dart';
import '../../../widgets/erp_selector.dart';
import '../ortak/rapor_modelleri.dart';

/// Plasiyer Özeti: seçilen tarih aralığında bir plasiyerin satış, tahsilat, kasa, cari ve araç stok durumu.
///
/// Formüller:
///  • Toplam Tahsilat            = Güncel Tahsilat + Cari Bakiyeden Tahsilat
///  • Güncel Tahsilat            = dönem satış faturalarına bağlı tahsilatlar
///  • Cari Bakiyeden Tahsilat    = faturaya bağlı olmayan (başka belge / cari bakiye) tahsilatlar
///  • Açık Hesapta Kalan         = Güncel Satış − Güncel Tahsilat
///  • Cari Eski Bakiye           = işlem yapılan carilerin dönem başından önceki bakiyesi (borç +, alacak −)
///  • Açık Hesapta Toplam        = Cari Eski Bakiye − Cari Bakiyeden Tahsilat + Açık Hesapta Kalan
///  • Sahaya Çıkış Stok Değeri   = araç deposuna giren transferler (net) × satış fiyatı
///  • Araçtaki Stok Değeri       = Sahaya Çıkış − Güncel Satışlar
/// Yalnızca tamamlanmış belgeler (taslak / iptal dışarıda) hesaba katılır.
class PlasiyerOzetiPage extends StatefulWidget {
  const PlasiyerOzetiPage({super.key});

  @override
  State<PlasiyerOzetiPage> createState() => _PlasiyerOzetiPageState();
}

class _Veri {
  double guncelSatis = 0, guncelTahsilat = 0, bakiyedenTahsilat = 0;
  double eskiBakiye = 0, sahayaCikis = 0;
  double get toplamTahsilat => guncelTahsilat + bakiyedenTahsilat;
  double get acikKalan => guncelSatis - guncelTahsilat;
  double get acikToplam => eskiBakiye - bakiyedenTahsilat + acikKalan;
  double get araciStok => sahayaCikis - guncelSatis;

  // Kasa durum: (kod, ad, tip, bakiye)
  final kasalar = <(String, String, String, double)>[];
  double get kasaToplam => kasalar.fold(0.0, (s, e) => s + e.$4);

  // Tahsilat detay: (belge no, tarih, cari ad, tür, tutar, faturaya bağlı mı)
  final tahsilatDetay = <(String, DateTime?, String, String, double, bool)>[];

  // Satışlar: (belge no, tarih, cari kod, cari ad, genel toplam)
  final satislar = <(String, DateTime?, String, String, double)>[];

  // Stok durum: (kod, ad, giriş, çıkış, bakiye)
  final stoklar = <(String, String, double, double, double)>[];
}

class _PlasiyerOzetiPageState extends State<PlasiyerOzetiPage> {
  ColorScheme get _scheme => Theme.of(context).colorScheme;
  Color get _primary => _scheme.primary;
  Color get _surface => Theme.of(context).scaffoldBackgroundColor;
  Color get _mavi => _scheme.primary;
  Color get _borcRenk => _scheme.error;
  Color get _alacakRenk => Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF6EE7B7)
      : const Color(0xFF16704A);
  KullaniciPlasiyer _kp = const KullaniciPlasiyer();
  List<PlasiyerDto> _plasiyerler = [];
  List<DepoDto> _depolar = [];

  PlasiyerDto? _plasiyer;
  DepoDto? _arac;
  late DateTime _tarih1;
  late DateTime _tarih2;
  bool _sifirDahil = false;

  bool _hazirlaniyor = true;
  bool _yukleniyor = false;
  _Veri? _veri;
  final List<String> _uyarilar = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _tarih1 = DateTime(now.year, now.month, now.day);
    _tarih2 = _tarih1;
    _hazirla();
  }

  Future<String> _token() async =>
      (await SharedPreferences.getInstance()).getString('token_final') ?? '';

  Future<void> _hazirla() async {
    final token = await _token();
    _kp = await KullaniciPlasiyerHelper.getir();
    try {
      _plasiyerler = await PlasiyerService().getPlasiyerler(token);
    } catch (_) {}
    try {
      _depolar = await DepoService().getDepoList(token);
    } catch (_) {}

    if (_kp.kilitli) {
      _plasiyer = _plasiyerler.where((p) => p.Id == _kp.plasiyerid).firstOrNull;
    }
    if (!mounted) return;
    setState(() => _hazirlaniyor = false);
    if (_plasiyer != null || _kp.kilitli) {
      _hesapla();
    } else {
      // Yönetici girişi: önce plasiyer seçilmesi gerekir → filtre sayfası kendiliğinden açılır
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _filtreSayfasi();
      });
    }
  }

  // ── Hesaplama ─────────────────────────────────────────────────────────────────
  Future<T> _guvenli<T>(String ad, Future<T> Function() getir, T bos) async {
    try {
      return await getir();
    } catch (e) {
      _uyarilar.add('$ad alınamadı (yetki veya bağlantı sorunu olabilir)');
      debugPrint('Plasiyer özeti: $ad hata: $e');
      _uyarilar.add('  → ${e.toString().replaceFirst("Exception: ", "")}');
      return bos;
    }
  }

  bool _aralikta(DateTime? t) {
    if (t == null) return false;
    final bas = DateTime(_tarih1.year, _tarih1.month, _tarih1.day);
    final bit = DateTime(_tarih2.year, _tarih2.month, _tarih2.day, 23, 59, 59);
    return !t.isBefore(bas) && !t.isAfter(bit);
  }

  Future<void> _hesapla() async {
    final pid = _plasiyer?.Id ?? _kp.plasiyerid;
    if (pid == null) {
      UiFeedback.showError(context, 'Lütfen plasiyer seçiniz.');
      return;
    }
    setState(() {
      _yukleniyor = true;
      _uyarilar.clear();
    });

    try {
      final token = await _token();
      final v = _Veri();

      // 1) Ana kaynaklar (paralel)
      final sonuc = await Future.wait<Object?>([
        _guvenli<List<FaturaListDto>>('Satış faturaları',
            () => FaturaService().getSatisFaturaList(token), const []),
        _guvenli<List<TahsilatDto>>(
            'Tahsilatlar', () => _tahsilatlariAl(token, pid), const []),
        _guvenli<List<RaporKayit>>(
          'Kasa hareketleri',
          () => RaporApi.post(
              'VW_Finanskasahareket/Query',
              RaporApi.filtre(
                  tarih1: _tarih1, tarih2: _tarih2, plasiyerid: pid)),
          const [],
        ),
        _guvenli<List<CariDtoLite>>(
            'Cari listesi', () => CariService().getCariler(token), const []),
        _guvenli<List<DovizDto>>(
            'Döviz listesi', () => DovizService().getDovizler(token), const []),
        _aracDeposuBul(token, pid),
      ]);

      final faturalar = (sonuc[0] as List<FaturaListDto>)
          .where((f) =>
              f.belgedurum == 1 &&
              _aralikta(f.tarih) &&
              // Plasiyer kullanıcıda sunucu zaten süzüyor; yönetici girişinde plasiyere göre süzülür.
              (f.plasiyerid == pid || (f.plasiyerid == null && _kp.kilitli)))
          .toList();
      final tahsilatlar = (sonuc[1] as List<TahsilatDto>)
          .where((t) =>
              _aralikta(t.Tarih) &&
              (t.Plasiyerid == pid || (t.Plasiyerid == null && _kp.kilitli)))
          .toList();
      final kasaHareketler = sonuc[2] as List<RaporKayit>;
      final cariler = {
        for (final c in (sonuc[3] as List<CariDtoLite>)) c.Id: c
      };
      final dovizler = sonuc[4] as List<DovizDto>;
      final arac = sonuc[5] as DepoDto?;
      if (arac != null) _arac = arac;
      final aracId = (_arac ?? arac)?.id;

      // 2) Satış / tahsilat
      final faturaIdleri = <String>{};
      for (final f in faturalar) {
        if (f.id != null) faturaIdleri.add(f.id!.toLowerCase());
        v.guncelSatis += f.genelToplam ?? 0;
        final c = cariler[f.cariId];
        v.satislar.add((
          (f.belgeserino ?? '').isNotEmpty ? f.belgeserino! : (f.belgeno ?? ''),
          f.tarih,
          c?.Kod ?? '',
          c?.Ad ?? '',
          f.genelToplam ?? 0,
        ));
      }
      v.satislar.sort(
          (a, b) => (b.$2 ?? DateTime(2000)).compareTo(a.$2 ?? DateTime(2000)));

      var krediKarti = 0.0;
      for (final t in tahsilatlar) {
        final tutar = t.Tahsilattutari ?? 0;
        final faturayaBagli = t.Islembelgeid != null &&
            faturaIdleri.contains(t.Islembelgeid!.toLowerCase());
        if (faturayaBagli) {
          v.guncelTahsilat += tutar;
        } else {
          v.bakiyedenTahsilat += tutar;
        }
        if (t.Tip == 3) krediKarti += tutar;
        final tur = t.Tip == 1
            ? 'Nakit'
            : t.Tip == 2
                ? 'Banka'
                : t.Tip == 3
                    ? 'Kredi Kartı'
                    : 'Tahsilat';
        final no = (t.Belgeserino ?? '').isNotEmpty
            ? t.Belgeserino!
            : '${t.Belgeseri ?? ''}${t.Belgeno ?? ''}';
        v.tahsilatDetay.add((
          no,
          t.Tarih,
          cariler[t.Cariid]?.Ad ?? t.CariAd ?? '',
          tur,
          tutar,
          faturayaBagli
        ));
      }

      // Kasa Hareket ekranından girilen (belgeye bağlı olmayan) cari tahsilatları: kasaya giriş + işlem tipi cari.
      // Tahsilat ekranından gelenler (belge türü 72) yukarıda sayıldığı için atlanır.
      final cariIdleriKasa = <int>{};
      for (final r in kasaHareketler) {
        if (r.i("belgeturu") == 72) continue;
        if (r.i("islemtipi") != 1 || r.i("giriscikis") != 1) continue;
        final tutar = r.d("tutar") != 0 ? r.d("tutar") : r.d("borctutar");
        v.bakiyedenTahsilat += tutar;
        v.tahsilatDetay.add((
          r.s('belgeno'),
          r.t('tarih'),
          r.s('islemcariad'),
          'Nakit (Kasa Hareketi)',
          tutar,
          false
        ));
        final cid = r.i("islemcariid");
        if (cid != null) cariIdleriKasa.add(cid);
      }

      // 3) Kasa durum: dönemde plasiyerin kasa hareketleri, kasa bazında net (giriş − çıkış)
      final kasaGrup = <int, (String, String, double)>{};
      for (final r in kasaHareketler) {
        final id = r.i('kasaid') ?? 0;
        final girisMi = r.i('giriscikis') == 1 ||
            (r.i('giriscikis') == null && r.d('borctutar') > 0);
        final tutar = r.d('tutar') != 0
            ? r.d('tutar')
            : (girisMi ? r.d('borctutar') : r.d('alacaktutar'));
        final onceki = kasaGrup[id];
        kasaGrup[id] = (
          onceki?.$1 ?? r.s('kasakod'),
          onceki?.$2 ?? r.s('kasaisim'),
          (onceki?.$3 ?? 0) + (girisMi ? tutar : -tutar),
        );
      }
      for (final e in kasaGrup.values) {
        v.kasalar.add((e.$1, e.$2, 'Nakit', e.$3));
      }
      v.kasalar.sort((a, b) => a.$1.compareTo(b.$1));
      if (krediKarti != 0 || v.kasalar.isEmpty)
        v.kasalar
            .add(('', 'Kredi Kartı Tahsilatları', 'Kredi Kartı', krediKarti));

      // 4) Cari eski bakiye: işlem yapılan cariler, dönem başından önceki bakiye
      final cariIdleri = <int>{
        ...faturalar.map((f) => f.cariId).whereType<int>(),
        ...tahsilatlar.map((t) => t.Cariid).whereType<int>(),
        ...cariIdleriKasa,
      };
      v.eskiBakiye = await _eskiBakiye(cariIdleri);

      // 5) Araç deposu: sahaya çıkış değeri + stok durumu
      if (aracId != null) {
        await _aracHesapla(token, v, aracId, dovizler);
      } else {
        _uyarilar.add(
            'Araç deposu bulunamadı — "Araç Deposu" alanından seçerek sorgulayın.');
      }

      if (mounted)
        setState(() {
          _veri = v;
          _yukleniyor = false;
        });
    } catch (e) {
      if (mounted) {
        setState(() => _yukleniyor = false);
        UiFeedback.showException(context, e);
      }
    }
  }

  /// Seçili araç deposu yoksa, plasiyerin deposunu (Plasiyerdeposu = true, Plasiyerid = plasiyer) tam depo listesinden bulur.
  Future<DepoDto?> _aracDeposuBul(String token, int pid) async {
    if (_arac != null) return _arac;
    // Tam depo listesi → Depo/Search → (plasiyer kullanıcıda) Ayarlar > Varsayılan Depo
    final id = await PlasiyerDepoHelper.getId(token, pid,
        kilitli: _kp.kilitli, mevcutDepolar: _depolar);
    if (id == null) return null;
    return _depolar.where((d) => d.id == id).firstOrNull ??
        (DepoDto()..id = id);
  }

  /// Tahsilat listesi yetki ister (Tümünü okuma); plasiyerde yoksa cari hareket görünümünden (Belgeturu 72) okunur.
  Future<List<TahsilatDto>> _tahsilatlariAl(String token, int pid) async {
    try {
      return await TahsilatService().getAll(token);
    } catch (_) {
      final satirlar = await RaporApi.post(
        'VW_Carihareket/Filter',
        RaporApi.filtre(tarih1: _tarih1, tarih2: _tarih2, plasiyerid: pid),
      );
      return [
        for (final r in satirlar)
          if (r.i('belgeturu') == 72)
            TahsilatDto(
              Id: r.s('belgeid'),
              Cariid: r.i('cariid'),
              Tarih: r.t('tarih'),
              Tahsilattutari: r.d('alacaktutar'),
              Plasiyerid: pid,
              Islembelgeid: r.s('ekid').isEmpty ? null : r.s('ekid'),
              Belgeno: r.s('belgeno'),
            ),
      ];
    }
  }

  Future<double> _eskiBakiye(Set<int> cariIdleri) async {
    if (cariIdleri.isEmpty) return 0;
    // Cari eski bakiye: her zaman GÜNÜN TARİHİNDEN ÖNCEKİ bakiye (seçilen aralıktan bağımsız)
    final bugun = DateTime.now();
    final oncesi = DateTime(bugun.year, bugun.month, bugun.day)
        .subtract(const Duration(days: 1));
    var toplam = 0.0;
    final liste = cariIdleri.toList();
    for (var i = 0; i < liste.length; i += 8) {
      final dilim =
          liste.sublist(i, i + 8 > liste.length ? liste.length : i + 8);
      final sonuclar = await Future.wait(
          dilim.map((id) => _guvenli<double>('Cari bakiyesi', () async {
                final satirlar = await RaporApi.post(
                  'VW_Carihareket/Filter',
                  RaporApi.filtre(
                      tarih1: DateTime(2000, 1, 1), tarih2: oncesi, cariid: id),
                );
                // Bakiye kolonuna değil, hareket toplamına dayanır (borç − alacak)
                return satirlar.fold<double>(
                    0.0, (s, r) => s + r.d('borctutar') - r.d('alacaktutar'));
              }, 0.0)));
      toplam += sonuclar.fold(0.0, (a, b) => a + b);
    }
    return toplam;
  }

  Future<void> _aracHesapla(
      String token, _Veri v, int aracId, List<DovizDto> dovizler) async {
    // Tamamlanmış transferler
    Set<String>? tamamlanan;
    final datlar = await _guvenli<List<DatDto>>(
        'Transfer (DAT) listesi', () => DatService().getList(token), const []);
    if (datlar.isNotEmpty) {
      tamamlanan = {
        for (final d in datlar)
          if (d.belgedurum == 1 && d.id != null) d.id!.toLowerCase(),
      };
    }

    final satirlar = await _guvenli<List<RaporKayit>>(
      'Transfer detayları',
      () => RaporApi.post('VW_Datdetay/Query',
          RaporApi.filtre(tarih1: _tarih1, tarih2: _tarih2, depoid: aracId)),
      const [],
    );

    // Stok bazında net giriş (giriş − çıkış), yalnızca tamamlanmış transferler
    final net = <int, double>{};
    final olcubr = <int, int?>{};
    for (final r in satirlar) {
      final datid = r.s('datid').toLowerCase();
      if (tamamlanan != null && datid.isNotEmpty && !tamamlanan.contains(datid))
        continue;
      final stokid = r.i('stokid');
      if (stokid == null) continue;
      net[stokid] =
          (net[stokid] ?? 0) + r.d('girismiktar') - r.d('cikismiktar');
      olcubr[stokid] = r.i('olcubrid');
    }

    // Satış fiyatları (TL öncelikli), ölçü birimi çarpımı ile
    final ids = net.keys.toList();
    for (var i = 0; i < ids.length; i += 8) {
      final dilim = ids.sublist(i, i + 8 > ids.length ? ids.length : i + 8);
      final degerler = await Future.wait(dilim.map((id) async {
        try {
          final s = await StokService().getStokById(token, id);
          final fiyatlar = s.Stokfiyat;
          if (fiyatlar.isEmpty) return 0.0;
          final sirali = [...fiyatlar]
            ..sort((a, b) => (a.Sira ?? 99).compareTo(b.Sira ?? 99));
          final f = sirali.first; // Fiyat 1 (ilk sıradaki satış fiyatı)
          var carpim = 1.0;
          final birimId = olcubr[id];
          if (birimId != null && birimId != s.Temelolcubrid) {
            carpim = s.Stokolcubr.where((x) => x.Olcubrid == birimId)
                    .firstOrNull
                    ?.Carpim ??
                1.0;
          }
          return net[id]! * carpim * (f.Satisfiyat ?? 0);
        } catch (_) {
          return 0.0;
        }
      }));
      v.sahayaCikis += degerler.fold(0.0, (a, b) => a + b);
    }

    // Stok durum (araç deposunun güncel bakiyesi)
    final stok = await _guvenli<List<RaporKayit>>(
      'Araç stok bakiyesi',
      () => RaporApi.post(
          'VW_Stokbakiyesubedepo/Query', RaporApi.filtre(depoid: aracId)),
      const [],
    );
    for (final r in stok) {
      v.stoklar.add((
        r.s('kod'),
        r.s('ad'),
        r.d('girismiktar'),
        r.d('cikismiktar'),
        r.d('bakiye')
      ));
    }
    v.stoklar.sort((a, b) => a.$1.compareTo(b.$1));
  }

  // ── Dışa aktarma ──────────────────────────────────────────────────────────────
  String get _filtreOzeti =>
      '${_plasiyer?.Adsoyad ?? ''}  •  ${rapTarih(_tarih1)} - ${rapTarih(_tarih2)}${_arac != null ? '  •  Araç deposu: ${_arac!.kod ?? ''}' : ''}';

  List<RaporBolum> _bolumler(_Veri v) => [
        RaporBolum('Plasiyer Özeti', degerler: [
          ('Toplam Tahsilat', rapTutar(v.toplamTahsilat)),
          ('Güncel Satış', rapTutar(v.guncelSatis)),
          ('Güncel Tahsilat', rapTutar(v.guncelTahsilat)),
          ('Açık Hesapta Kalan', rapTutar(v.acikKalan)),
          ('Cari Eski Bakiye', rapTutar(v.eskiBakiye)),
          ('Cari Bakiyeden Tahsilat', rapTutar(v.bakiyedenTahsilat)),
          ('Açık Hesapta Toplam', rapTutar(v.acikToplam)),
          ('Sahaya Çıkış Stok Değeri', rapTutar(v.sahayaCikis)),
          ('Güncel Satışlar', rapTutar(v.guncelSatis)),
          ('Araçtaki Stok Değeri', rapTutar(v.araciStok)),
        ]),
        RaporBolum('Kasa Durum',
            sagBaslik: rapTutar(v.kasaToplam),
            tablo: RaporSonuc(const [
              RaporKolon('Kasa Kod'),
              RaporKolon('Kasa Adı'),
              RaporKolon('Kasa Tip'),
              RaporKolon('Bakiye', tip: RaporKolonTipi.tutar),
            ], [
              for (final k in v.kasalar) RaporSatir([k.$1, k.$2, k.$3, k.$4])
            ])),
        RaporBolum('Tahsilat Detay',
            sagBaslik: rapTutar(v.toplamTahsilat),
            tablo: RaporSonuc(const [
              RaporKolon('Belge No'),
              RaporKolon('Tarih', tip: RaporKolonTipi.tarih),
              RaporKolon('Cari'),
              RaporKolon('Tür'),
              RaporKolon('Tutar', tip: RaporKolonTipi.tutar),
            ], [
              for (final t in v.tahsilatDetay)
                RaporSatir([t.$1, t.$2, t.$3, t.$4, t.$5])
            ])),
        RaporBolum('Satışlar',
            sagBaslik: rapTutar(v.guncelSatis),
            tablo: RaporSonuc(const [
              RaporKolon('Fatura No'),
              RaporKolon('Tarih', tip: RaporKolonTipi.tarih),
              RaporKolon('Cari Kod'),
              RaporKolon('Cari Ad'),
              RaporKolon('Genel Toplam', tip: RaporKolonTipi.tutar),
            ], [
              for (final s in v.satislar)
                RaporSatir([s.$1, s.$2, s.$3, s.$4, s.$5])
            ])),
        RaporBolum('Stok Durum',
            tablo: RaporSonuc(const [
              RaporKolon('Stok Kodu'),
              RaporKolon('Stok Adı'),
              RaporKolon('Giriş', tip: RaporKolonTipi.miktar),
              RaporKolon('Çıkış', tip: RaporKolonTipi.miktar),
              RaporKolon('Bakiye', tip: RaporKolonTipi.miktar),
            ], [
              for (final s in v.stoklar)
                if (_sifirDahil || s.$5.abs() >= 0.00005)
                  RaporSatir([s.$1, s.$2, s.$3, s.$4, s.$5]),
            ])),
      ];

  Future<void> _pdf() async {
    final v = _veri;
    if (v == null) return;
    try {
      await RaporTabloAktar.pdfBolumlu(
          'Plasiyer Özeti', _filtreOzeti, _bolumler(v));
    } catch (e) {
      if (mounted) UiFeedback.showError(context, 'PDF hatası: $e');
    }
  }

  // ── Seçimler ──────────────────────────────────────────────────────────────────
  Future<void> _tarihSec(bool bas) async {
    final d = await showDatePicker(
      context: context,
      initialDate: bas ? _tarih1 : _tarih2,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (d == null) return;
    setState(() {
      if (bas) {
        _tarih1 = d;
        if (_tarih2.isBefore(d)) _tarih2 = d;
      } else {
        _tarih2 = d;
        if (_tarih1.isAfter(d)) _tarih1 = d;
      }
    });
  }

  Future<void> _plasiyerSec() async {
    final s = await showErpSelector<PlasiyerDto>(
      context: context,
      title: 'Plasiyer Seç',
      hintText: 'Plasiyer adı veya kodu',
      items: _plasiyerler,
      itemText: (p) => '${p.Kod ?? ''} - ${p.Adsoyad ?? ''}',
    );
    if (s != null)
      setState(() {
        _plasiyer = s;
        _arac = null;
        _veri = null;
      });
  }

  Future<void> _aracSec() async {
    final s = await showErpSelector<DepoDto>(
      context: context,
      title: 'Araç Deposu Seç',
      hintText: 'Depo adı veya kodu',
      items: _depolar,
      itemText: (d) => '${d.kod ?? ''} - ${d.ad ?? ''}',
    );
    if (s != null) setState(() => _arac = s);
  }

  // ── Görünüm ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final v = _veri;
    return Scaffold(
      backgroundColor: _surface,
      appBar: ErpPageAppBar(
        context: context,
        title: Text('Plasiyer Özeti',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontWeight: FontWeight.bold,
                fontSize: 17)),
        backgroundColor: _scheme.surface,
        foregroundColor: _scheme.onSurface,
        elevation: 0,
        actions: [
          if (v != null)
            PopupMenuButton<String>(
                tooltip: 'Dışa Aktar',
                icon: Icon(Icons.ios_share_rounded),
                onSelected: (value) {
                  if (value == 'pdf') {
                    _pdf();
                  } else {
                    _yazdir();
                  }
                },
                itemBuilder: (_) => [
                      PopupMenuItem(value: 'pdf', child: Text("PDF'e Aktar")),
                      PopupMenuItem(value: 'print', child: Text('Yazdır'))
                    ]),
          IconButton(
              icon: Icon(Icons.tune_rounded),
              tooltip: 'Filtreler',
              onPressed: _hazirlaniyor ? null : _filtreSayfasi),
        ],
      ),
      body: _hazirlaniyor
          ? Center(child: CircularProgressIndicator())
          : Column(children: [
              _filtreSeridi(),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.fromLTRB(12, 4, 12, 32),
                  children: [
                    if (_uyarilar.isNotEmpty) _uyariKutusu(),
                    if (_yukleniyor)
                      Padding(
                          padding: EdgeInsets.all(40),
                          child: Center(child: CircularProgressIndicator()))
                    else if (v == null)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 48),
                        child: Column(children: [
                          Text(
                            _kp.kilitli || _plasiyer != null
                                ? 'Sorgula\'ya dokunun'
                                : 'Önce plasiyer seçin',
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                color: _scheme.onSurfaceVariant),
                          ),
                          SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _filtreSayfasi,
                            icon: Icon(Icons.tune_rounded, size: 18),
                            label: Text('Filtreleri Aç'),
                          ),
                        ]),
                      )
                    else ...[
                      _ozetKarti(v),
                      _kasaKarti(v),
                      _tahsilatDetayKarti(v),
                      _satisKarti(v),
                      _stokKarti(v),
                    ],
                  ],
                ),
              ),
            ]),
    );
  }

  /// Filtre özeti şeridi (diğer raporlardaki gibi): dokununca filtre sayfası açılır.
  Widget _filtreSeridi() {
    final parcalar = <String>[
      _plasiyer != null
          ? (_plasiyer!.Adsoyad ?? _plasiyer!.Kod ?? '')
          : 'Plasiyer seçilmedi',
      '${rapTarih(_tarih1)} - ${rapTarih(_tarih2)}',
      if (_arac != null) 'Araç: ${_arac!.kod ?? ''}',
    ];
    return GestureDetector(
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
            child: Text(parcalar.join('  •  '),
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
    );
  }

  /// Filtreler alt sayfada (gizlenebilir) — diğer raporlarla aynı düzen.
  void _filtreSayfasi() {
    showModalBottomSheet(
      showDragHandle: false,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, yenile) {
        void y() => yenile(() {});
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
                    borderRadius: BorderRadius.circular(2)),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Filtreler',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
              ),
              Divider(),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(children: [
                    _secici(
                      'Plasiyer',
                      Icons.badge_outlined,
                      _plasiyer != null
                          ? '${_plasiyer!.Kod ?? ''} - ${_plasiyer!.Adsoyad ?? ''}'
                          : null,
                      _kp.kilitli
                          ? null
                          : () async {
                              await _plasiyerSec();
                              y();
                            },
                      kilitli: _kp.kilitli,
                    ),
                    SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                          child: _secici(
                              'Başlangıç',
                              Icons.calendar_today_outlined,
                              rapTarih(_tarih1), () async {
                        await _tarihSec(true);
                        y();
                      })),
                      SizedBox(width: 8),
                      Expanded(
                          child: _secici('Bitiş', Icons.calendar_today_outlined,
                              rapTarih(_tarih2), () async {
                        await _tarihSec(false);
                        y();
                      })),
                    ]),
                    SizedBox(height: 10),
                    _secici(
                      'Araç Deposu',
                      Icons.local_shipping_outlined,
                      _arac != null
                          ? '${_arac!.kod ?? ''} - ${_arac!.ad ?? ''}'
                          : null,
                      () async {
                        await _aracSec();
                        y();
                      },
                      bos: 'Otomatik',
                    ),
                  ]),
                ),
              ),
              SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _yukleniyor
                      ? null
                      : () {
                          Navigator.pop(ctx);
                          _hesapla();
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: _scheme.onPrimary,
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

  // ── Yazdır (önce ekranda fiş önizleme, sonra "Yazdır") ───────────────────────
  Future<void> _yazdir() async {
    final v = _veri;
    if (v == null) return;
    final kw = await FisYazdirHelper.satirGenisligi();
    final kullanici = await FisYazdirHelper.kullaniciAdi();
    if (!mounted) return;
    await FisYazdirHelper.onizleVeYazdir(
      context,
      baslik: 'Plasiyer Özeti',
      satirlar: _fisSatirlari(v, kw, kullanici),
      satirGenisligi: kw,
    );
  }

  List<FisSatir> _fisSatirlari(_Veri v, int kw, String? kullaniciAdi) {
    final f = FisBicim(kw);
    final now = DateTime.now();
    String p2(int x) => x.toString().padLeft(2, '0');
    final bolumler = _bolumler(v);

    final l = <FisSatir>[
      FisSatir('FilERP', ortali: true, kalin: true, buyuk: true),
      FisSatir('PLASİYER ÖZETİ', ortali: true, kalin: true),
      FisSatir(f.cizgi('=')),
      FisSatir(f.kes('Plasiyer : ${_plasiyer?.Adsoyad ?? ''}')),
      FisSatir('Aralık   : ${rapTarih(_tarih1)} - ${rapTarih(_tarih2)}'),
      if (_arac != null)
        FisSatir(
            f.kes('Araç Dep.: ${_arac!.kod ?? ''} ${_arac!.ad ?? ''}'.trim())),
      FisSatir(
          'Basım    : ${p2(now.day)}.${p2(now.month)}.${now.year} ${p2(now.hour)}:${p2(now.minute)}'),
      if (kullaniciAdi != null && kullaniciAdi.isNotEmpty)
        FisSatir(f.kes('Kullanıcı: $kullaniciAdi')),
      FisSatir(f.cizgi('-')),
      FisSatir('ÖZET', kalin: true),
      FisSatir(f.cizgi('-')),
      for (final d in bolumler.first.degerler) FisSatir(f.satir(d.$1, d.$2)),
      FisSatir(f.cizgi('=')),
      FisSatir(f.satir('KASA DURUM', rapTutar(v.kasaToplam)), kalin: true),
      FisSatir(f.cizgi('-')),
      for (final k in v.kasalar)
        FisSatir(f.satir('${k.$1} ${k.$2}'.trim(), rapTutar(k.$4))),
      FisSatir(f.cizgi('=')),
      FisSatir(f.satir('SATIŞLAR', rapTutar(v.guncelSatis)), kalin: true),
      FisSatir(f.cizgi('-')),
    ];
    if (v.satislar.isEmpty) l.add(FisSatir('Satış yok'));
    for (var i = 0; i < v.satislar.length; i++) {
      final s = v.satislar[i];
      l.add(FisSatir(f.satir(s.$1, rapTutar(s.$5))));
      l.add(FisSatir(f.kes('${rapTarih(s.$2)} ${s.$3} ${s.$4}'.trim())));
      if (i < v.satislar.length - 1) l.add(FisSatir(f.cizgi('-')));
    }
    l
      ..add(FisSatir(f.cizgi('=')))
      ..add(FisSatir('STOK DURUM', kalin: true))
      ..add(FisSatir(f.cizgi('-')));
    final stoklar =
        v.stoklar.where((s) => _sifirDahil || s.$5.abs() >= 0.00005).toList();
    if (stoklar.isEmpty) l.add(FisSatir('Araçta stok yok'));
    for (var i = 0; i < stoklar.length; i++) {
      final s = stoklar[i];
      l.add(FisSatir(f.kes('${s.$1} ${s.$2}'.trim())));
      l.add(FisSatir(f.satir('  G:${rapMiktar(s.$3)} Ç:${rapMiktar(s.$4)}',
          'K:${rapMiktar(s.$5)}')));
      if (i < stoklar.length - 1) l.add(FisSatir(f.cizgi('-')));
    }
    l.add(FisSatir(f.cizgi('=')));
    return l;
  }

  Widget _secici(
      String etiket, IconData ikon, String? deger, VoidCallback? onTap,
      {bool kilitli = false, String bos = 'Seçiniz'}) {
    final secili = deger != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color:
                  secili ? _primary.withOpacity(0.4) : _scheme.outlineVariant),
          color: kilitli
              ? _scheme.surfaceContainerLow
              : (secili
                  ? _primary.withOpacity(0.04)
                  : _scheme.surfaceContainerLow),
        ),
        child: Row(children: [
          Icon(ikon,
              size: 17, color: secili ? _primary : _scheme.onSurfaceVariant),
          SizedBox(width: 10),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(etiket,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 9.5,
                      color: _scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600)),
              Text(secili ? deger : bos,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: secili ? _primary : _scheme.onSurfaceVariant)),
            ]),
          ),
          if (kilitli)
            Icon(Icons.lock_outline_rounded,
                size: 15, color: _scheme.onSurfaceVariant),
        ]),
      ),
    );
  }

  Widget _uyariKutusu() => Container(
        margin: EdgeInsets.only(top: 10),
        padding: EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: _scheme.errorContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _scheme.error.withValues(alpha: .3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final u in _uyarilar.toSet())
              Padding(
                padding: EdgeInsets.symmetric(vertical: 1),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.warning_amber_rounded,
                          size: 15, color: _scheme.onErrorContainer),
                      SizedBox(width: 6),
                      Expanded(
                          child: Text(u,
                              style: TextStyle(
                                  fontFamily: 'Roboto',
                                  fontSize: 11.5,
                                  color: _scheme.onErrorContainer))),
                    ]),
              ),
          ],
        ),
      );

  Widget _kart(
          {required String baslik,
          String? sag,
          Color? sagRenk,
          required List<Widget> cocuklar,
          Widget? baslikSag}) =>
      Container(
        margin: EdgeInsets.only(top: 8),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _scheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: Offset(0, 2))
          ],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (baslikSag != null)
            Wrap(
                spacing: 12,
                runSpacing: 4,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(baslik,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _scheme.onSurface)),
                  baslikSag
                ])
          else
            Row(children: [
              Expanded(
                  child: Text(baslik,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: _scheme.onSurface))),
              if (sag != null)
                Expanded(
                    child: FittedBox(
                        alignment: Alignment.centerRight,
                        fit: BoxFit.scaleDown,
                        child: Text(sag,
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: sagRenk ?? _primary)))),
              const SizedBox(width: 18),
            ]),
          Divider(height: 12),
          ...cocuklar,
        ]),
      );

  Widget _satir(String etiket, double deger,
      {bool kalin = false,
      bool buyuk = false,
      Color? renk,
      VoidCallback? onTap}) {
    final govde = Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
          child: Text(etiket,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  fontWeight:
                      kalin || buyuk ? FontWeight.w800 : FontWeight.w500,
                  color: renk ?? _scheme.onSurface)),
        ),
        Expanded(
            child: FittedBox(
                alignment: Alignment.centerRight,
                fit: BoxFit.scaleDown,
                child: Text('${rapTutar(deger)} ₺',
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: buyuk ? 15 : 13,
                        fontWeight:
                            kalin || buyuk ? FontWeight.w800 : FontWeight.w600,
                        color: renk ?? _scheme.onSurface)))),
        SizedBox(
            width: 18,
            child: onTap == null
                ? null
                : Icon(Icons.chevron_right_rounded,
                    size: 18, color: _scheme.onSurfaceVariant)),
      ]),
    );
    return onTap == null
        ? govde
        : InkWell(
            onTap: onTap, borderRadius: BorderRadius.circular(8), child: govde);
  }

  /// Tahsilat satırına dokununca detay: belge no, cari, tarih, tür (Nakit / Kredi Kartı / Banka), tutar.
  /// [bagli]: null = hepsi, true = faturaya bağlı, false = cari bakiyeden.
  void _tahsilatDetayAc(_Veri v, String baslik, bool? bagli, {String? tur}) {
    final liste = v.tahsilatDetay
        .where((t) =>
            (bagli == null || t.$6 == bagli) &&
            (tur == null || t.$4.startsWith(tur)))
        .toList();
    final toplam = liste.fold(0.0, (s, t) => s + t.$5);
    final turToplam = <String, double>{};
    for (final t in liste) {
      turToplam[t.$4] = (turToplam[t.$4] ?? 0) + t.$5;
    }
    showModalBottomSheet(
      showDragHandle: false,
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (_, sc) => Container(
          decoration: BoxDecoration(
              color: _scheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(children: [
            Container(
                width: 40,
                height: 4,
                margin: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                    color: _scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2))),
            Row(children: [
              Expanded(
                  child: Text(baslik,
                      style: TextStyle(
                          fontFamily: 'Roboto',
                          fontSize: 17,
                          fontWeight: FontWeight.bold))),
              Text(rapTutar(toplam),
                  style: TextStyle(
                      fontFamily: 'Roboto',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: _mavi)),
            ]),
            if (turToplam.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 6),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 14, children: [
                    for (final e in turToplam.entries)
                      Text('${e.key}: ${rapTutar(e.value)}',
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12,
                              color: _scheme.onSurfaceVariant)),
                  ]),
                ),
              ),
            Divider(),
            Expanded(
              child: liste.isEmpty
                  ? Center(
                      child: Text('Tahsilat yok',
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              color: _scheme.onSurfaceVariant)))
                  : ListView.separated(
                      controller: sc,
                      itemCount: liste.length,
                      separatorBuilder: (_, __) => Divider(height: 1),
                      itemBuilder: (_, i) {
                        final t = liste[i];
                        return Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(t.$1.isEmpty ? '-' : t.$1,
                                            style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                                color: _primary)),
                                        Text(t.$3.isEmpty ? '-' : t.$3,
                                            style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 12.5),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis),
                                        Text(
                                            '${rapTarih(t.$2)}  •  ${t.$4}  •  ${t.$6 ? 'Faturaya bağlı' : 'Cari bakiyeden'}',
                                            style: TextStyle(
                                                fontFamily: 'Roboto',
                                                fontSize: 11,
                                                color:
                                                    _scheme.onSurfaceVariant)),
                                      ]),
                                ),
                                Text(rapTutar(t.$5),
                                    style: TextStyle(
                                        fontFamily: 'Roboto',
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w800)),
                              ]),
                        );
                      },
                    ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _ozetKarti(_Veri v) => _kart(baslik: 'Genel Özet', cocuklar: [
        _satir('Toplam Tahsilat', v.toplamTahsilat,
            buyuk: true,
            renk: _mavi,
            onTap: () => _tahsilatDetayAc(v, 'Toplam Tahsilat', null)),
        _satir('Güncel Satış', v.guncelSatis),
        _satir('Güncel Tahsilat', v.guncelTahsilat,
            onTap: () =>
                _tahsilatDetayAc(v, 'Güncel Tahsilat (faturaya bağlı)', true)),
        _satir('Açık Hesapta Kalan', v.acikKalan, kalin: true),
        _satir('Cari Eski Bakiye', v.eskiBakiye),
        _satir('Cari Bakiyeden Tahsilat', v.bakiyedenTahsilat,
            onTap: () => _tahsilatDetayAc(v, 'Cari Bakiyeden Tahsilat', false)),
        _satir('Açık Hesapta Toplam', v.acikToplam, kalin: true),
        Divider(height: 12),
        _satir('Sahaya Çıkış Stok Değeri', v.sahayaCikis, kalin: true),
        _satir('Güncel Satışlar', v.guncelSatis, kalin: true),
        _satir('Araçtaki Stok Değeri', v.araciStok, kalin: true, renk: _mavi),
      ]);

  /// Tahsilat Detay: türe göre (Nakit / Kredi Kartı / Banka ...) toplamlar; satıra dokununca o türün belge detayı açılır.
  Widget _tahsilatDetayKarti(_Veri v) {
    final turler = <String, (double, int)>{};
    for (final t in v.tahsilatDetay) {
      final ad = t.$4.startsWith('Nakit') ? 'Nakit' : t.$4;
      final o = turler[ad];
      turler[ad] = ((o?.$1 ?? 0) + t.$5, (o?.$2 ?? 0) + 1);
    }
    return _kart(
      baslik: 'Tahsilat Detayı',
      sag: rapTutar(v.toplamTahsilat),
      cocuklar: [
        for (final e in turler.entries)
          InkWell(
            onTap: () =>
                _tahsilatDetayAc(v, '${e.key} Tahsilatlar', null, tur: e.key),
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Row(children: [
                Icon(
                    e.key == 'Kredi Kartı'
                        ? Icons.credit_card_rounded
                        : e.key == 'Banka'
                            ? Icons.account_balance_rounded
                            : Icons.payments_rounded,
                    size: 20,
                    color: _primary),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.key,
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700)),
                        Text('${e.value.$2} işlem',
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: _scheme.onSurfaceVariant)),
                      ]),
                ),
                Text(rapTutar(e.value.$1),
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800)),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: _scheme.onSurfaceVariant),
              ]),
            ),
          ),
        if (turler.isEmpty) _bosYazi('Tahsilat yok'),
      ],
    );
  }

  Widget _kasaKarti(_Veri v) => _kart(
        baslik: 'Kasa Durumu',
        sag: rapTutar(v.kasaToplam),
        cocuklar: [
          for (final k in v.kasalar)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child: Row(children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            '${k.$1}${k.$1.isNotEmpty && k.$2.isNotEmpty ? ' - ' : ''}${k.$2}',
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 13,
                                fontWeight: FontWeight.w700)),
                        Text(k.$3,
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: _scheme.onSurfaceVariant)),
                      ]),
                ),
                Text(rapTutar(k.$4),
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 18),
              ]),
            ),
          if (v.kasalar.isEmpty) _bosYazi('Kasa hareketi yok'),
        ],
      );

  Widget _satisKarti(_Veri v) => _kart(
        baslik: 'Satışlar',
        sag: rapTutar(v.guncelSatis),
        cocuklar: [
          for (final s in v.satislar)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 5),
              child:
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.$1,
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: _primary)),
                        Text(
                            '${s.$3}${s.$3.isNotEmpty && s.$4.isNotEmpty ? ' - ' : ''}${s.$4}',
                            style:
                                TextStyle(fontFamily: 'Roboto', fontSize: 12.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                        Text(rapTarih(s.$2),
                            style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: 11,
                                color: _scheme.onSurfaceVariant)),
                      ]),
                ),
                Text(rapTutar(s.$5),
                    style: TextStyle(
                        fontFamily: 'Roboto',
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800)),
                const SizedBox(width: 18),
              ]),
            ),
          if (v.satislar.isEmpty) _bosYazi('Tamamlanmış satış faturası yok'),
        ],
      );

  Widget _stokKarti(_Veri v) {
    final liste =
        v.stoklar.where((s) => _sifirDahil || s.$5.abs() >= 0.00005).toList();
    return _kart(
      baslik: 'Stok Durumu',
      baslikSag: Row(mainAxisSize: MainAxisSize.min, children: [
        Text('Sıfır bakiye dahil',
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 11,
                color: _scheme.onSurfaceVariant)),
        Switch(
          value: _sifirDahil,
          activeColor: _primary,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          onChanged: (x) => setState(() => _sifirDahil = x),
        ),
      ]),
      cocuklar: [
        for (final s in liste)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 5),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.$1,
                          style: TextStyle(
                              fontFamily: 'Roboto',
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: _primary)),
                      Text(s.$2,
                          style:
                              TextStyle(fontFamily: 'Roboto', fontSize: 12.5),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ]),
              ),
              _miktarKutu('Giriş', s.$3, _scheme.onSurfaceVariant),
              _miktarKutu('Çıkış', s.$4, _scheme.onSurfaceVariant),
              _miktarKutu(
                  'Bakiye',
                  s.$5,
                  s.$5 > 0
                      ? _alacakRenk
                      : (s.$5 < 0 ? _borcRenk : _scheme.onSurfaceVariant)),
            ]),
          ),
        if (liste.isEmpty)
          _bosYazi(_arac == null && v.stoklar.isEmpty
              ? 'Araç deposu seçilmedi'
              : 'Stok kaydı yok'),
      ],
    );
  }

  Widget _miktarKutu(String e, double d, Color renk) => Padding(
        padding: EdgeInsets.only(left: 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(e,
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 9,
                  color: _scheme.onSurfaceVariant)),
          Text(rapMiktar(d),
              style: TextStyle(
                  fontFamily: 'Roboto',
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: renk)),
        ]),
      );

  Widget _bosYazi(String t) => Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text(t,
            style: TextStyle(
                fontFamily: 'Roboto',
                fontSize: 12.5,
                color: _scheme.onSurfaceVariant)),
      );
}
