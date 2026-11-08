//import 'dart:convert';

// ── Enums ─────────────────────────────────────────────────────────────────────

enum SatirTipi { alan, metin, barkod, ayirici, bosluk, logo }

enum AlanKodu {
  stokKodu,
  stokAdi,
  barkodNo,
  olcuBirimi,
  tarih,
}

extension AlanKoduExt on AlanKodu {
  String get label {
    switch (this) {
      case AlanKodu.stokKodu:   return 'Stok Kodu';
      case AlanKodu.stokAdi:    return 'Stok Adı';
      case AlanKodu.barkodNo:   return 'Barkod Numarası';
      case AlanKodu.olcuBirimi: return 'Ölçü Birimi';
      case AlanKodu.tarih:      return 'Tarih / Saat';
    }
  }
}

enum Hizalama { sol, orta, sag }

extension HizalamaExt on Hizalama {
  String get label {
    switch (this) {
      case Hizalama.sol:  return 'Sol';
      case Hizalama.orta: return 'Orta';
      case Hizalama.sag:  return 'Sağ';
    }
  }
}

enum YaziBoyutu { normal, buyuk }

enum LogoBoyu { kucuk, orta, buyuk }

extension LogoBoyuExt on LogoBoyu {
  String get label {
    switch (this) {
      case LogoBoyu.kucuk: return 'Küçük';
      case LogoBoyu.orta:  return 'Orta';
      case LogoBoyu.buyuk: return 'Büyük';
    }
  }

  /// 58mm kağıt için piksel genişliği
  int px58mm() {
    switch (this) {
      case LogoBoyu.kucuk: return 70;
      case LogoBoyu.orta:  return 110;
      case LogoBoyu.buyuk: return 150;
    }
  }

  /// 80mm kağıt için piksel genişliği
  int px80mm() {
    switch (this) {
      case LogoBoyu.kucuk: return 100;
      case LogoBoyu.orta:  return 150;
      case LogoBoyu.buyuk: return 210;
    }
  }
}

// ── Satır ─────────────────────────────────────────────────────────────────────

class SablonSatir {
  final SatirTipi tip;
  final String?   staticMetin;   // tip == metin
  final AlanKodu? alanKodu;      // tip == alan
  final String    ayiriciKar;    // tip == ayirici
  final Hizalama  hizalama;
  final bool      kalin;
  final YaziBoyutu boy;
  final LogoBoyu  logoBoyu;      // tip == logo

  const SablonSatir({
    required this.tip,
    this.staticMetin,
    this.alanKodu,
    this.ayiriciKar = '-',
    this.hizalama   = Hizalama.sol,
    this.kalin      = false,
    this.boy        = YaziBoyutu.normal,
    this.logoBoyu   = LogoBoyu.kucuk,
  });

  SablonSatir copyWith({
    SatirTipi?  tip,
    String?     staticMetin,
    AlanKodu?   alanKodu,
    String?     ayiriciKar,
    Hizalama?   hizalama,
    bool?       kalin,
    YaziBoyutu? boy,
    LogoBoyu?   logoBoyu,
  }) =>
      SablonSatir(
        tip:         tip         ?? this.tip,
        staticMetin: staticMetin ?? this.staticMetin,
        alanKodu:    alanKodu    ?? this.alanKodu,
        ayiriciKar:  ayiriciKar  ?? this.ayiriciKar,
        hizalama:    hizalama    ?? this.hizalama,
        kalin:       kalin       ?? this.kalin,
        boy:         boy         ?? this.boy,
        logoBoyu:    logoBoyu    ?? this.logoBoyu,
      );

  Map<String, dynamic> toJson() => {
        'tip':      tip.name,
        'metin':    staticMetin,
        'alan':     alanKodu?.name,
        'ayirici':  ayiriciKar,
        'hizalama': hizalama.name,
        'kalin':    kalin,
        'boy':      boy.name,
        'logoBoyu': logoBoyu.name,
      };

  factory SablonSatir.fromJson(Map<String, dynamic> j) {
    SatirTipi tip = SatirTipi.values.firstWhere(
        (e) => e.name == j['tip'],
        orElse: () => SatirTipi.metin);

    AlanKodu? alan;
    if (j['alan'] != null) {
      alan = AlanKodu.values.firstWhere(
          (e) => e.name == j['alan'],
          orElse: () => AlanKodu.stokAdi);
    }

    return SablonSatir(
      tip:         tip,
      staticMetin: j['metin'] as String?,
      alanKodu:    alan,
      ayiriciKar:  j['ayirici'] as String? ?? '-',
      hizalama: Hizalama.values.firstWhere(
          (e) => e.name == (j['hizalama'] ?? 'sol'),
          orElse: () => Hizalama.sol),
      kalin: j['kalin'] as bool? ?? false,
      logoBoyu: LogoBoyu.values.firstWhere(
          (e) => e.name == (j['logoBoyu'] ?? 'kucuk'),
          orElse: () => LogoBoyu.kucuk),
      boy: YaziBoyutu.values.firstWhere(
          (e) => e.name == (j['boy'] ?? 'normal'),
          orElse: () => YaziBoyutu.normal),
    );
  }

  /// İnsan okunabilir özet
  String get ozet {
    switch (tip) {
      case SatirTipi.alan:
        return '${alanKodu?.label ?? '?'}  [${hizalama.label}${kalin ? ', Kalın' : ''}${boy == YaziBoyutu.buyuk ? ', Büyük' : ''}]';
      case SatirTipi.metin:
        return '"${(staticMetin ?? '').length > 24 ? '${staticMetin!.substring(0, 24)}…' : (staticMetin ?? '')}"\n'
            '[${hizalama.label}${kalin ? ', Kalın' : ''}]';
      case SatirTipi.barkod:
        return 'Barkod görseli (Code128)';
      case SatirTipi.ayirici:
        return 'Ayırıcı: ${ayiriciKar * 8}';
      case SatirTipi.bosluk:
        return 'Boş satır';
      case SatirTipi.logo:
        return 'FilERP Logosu — ${logoBoyu.label}  [${hizalama.label}]';
    }
  }
}

// ── Şablon ────────────────────────────────────────────────────────────────────

class YaziciSablon {
  final String         id;
  String               ad;
  List<SablonSatir>    satirlar;
  final bool           varsayilanMi; // silinemez

  YaziciSablon({
    required this.id,
    required this.ad,
    required this.satirlar,
    this.varsayilanMi = false,
  });

  Map<String, dynamic> toJson() => {
        'id':      id,
        'ad':      ad,
        'satirlar': satirlar.map((s) => s.toJson()).toList(),
        'varsayilan': varsayilanMi,
      };

  factory YaziciSablon.fromJson(Map<String, dynamic> j) => YaziciSablon(
        id:       j['id'] as String,
        ad:       j['ad'] as String,
        satirlar: (j['satirlar'] as List<dynamic>)
            .map((e) => SablonSatir.fromJson(e as Map<String, dynamic>))
            .toList(),
        varsayilanMi: j['varsayilan'] as bool? ?? false,
      );

  YaziciSablon copyWith({String? ad, List<SablonSatir>? satirlar}) =>
      YaziciSablon(
        id:           id,
        ad:           ad ?? this.ad,
        satirlar:     satirlar ?? this.satirlar,
        varsayilanMi: varsayilanMi,
      );

  // ── Fabrika şablonları ───────────────────────────────────────────────────

  static List<YaziciSablon> fabrika() => [
        YaziciSablon(
          id: '__kucuk_etiket__',
          ad: 'Küçük Etiket',
          varsayilanMi: false,
          satirlar: const [
            SablonSatir(
                tip: SatirTipi.alan,
                alanKodu: AlanKodu.stokKodu,
                hizalama: Hizalama.orta,
                kalin: true),
            SablonSatir(
                tip: SatirTipi.alan,
                alanKodu: AlanKodu.stokAdi,
                hizalama: Hizalama.sol),
            SablonSatir(tip: SatirTipi.ayirici),
            SablonSatir(tip: SatirTipi.barkod),
            SablonSatir(
                tip: SatirTipi.alan,
                alanKodu: AlanKodu.olcuBirimi,
                hizalama: Hizalama.sol),
          ],
        ),
        YaziciSablon(
          id: '__detayli_etiket__',
          ad: 'Detaylı Etiket',
          varsayilanMi: false,
          satirlar: const [
            SablonSatir(
                tip: SatirTipi.alan,
                alanKodu: AlanKodu.stokKodu,
                hizalama: Hizalama.orta,
                kalin: true,
                boy: YaziBoyutu.buyuk),
            SablonSatir(
                tip: SatirTipi.alan,
                alanKodu: AlanKodu.stokAdi,
                hizalama: Hizalama.orta),
            SablonSatir(tip: SatirTipi.ayirici, ayiriciKar: '='),
            SablonSatir(tip: SatirTipi.barkod),
            SablonSatir(tip: SatirTipi.ayirici),
            SablonSatir(
                tip: SatirTipi.alan,
                alanKodu: AlanKodu.olcuBirimi,
                hizalama: Hizalama.orta),
            SablonSatir(
                tip: SatirTipi.alan,
                alanKodu: AlanKodu.tarih,
                hizalama: Hizalama.sol),
          ],
        ),
        YaziciSablon(
          id: '__sadece_barkod__',
          ad: 'Sadece Barkod',
          varsayilanMi: false,
          satirlar: const [
            SablonSatir(
                tip: SatirTipi.alan,
                alanKodu: AlanKodu.stokAdi,
                hizalama: Hizalama.orta),
            SablonSatir(tip: SatirTipi.barkod),
            SablonSatir(
                tip: SatirTipi.alan,
                alanKodu: AlanKodu.barkodNo,
                hizalama: Hizalama.orta,
                kalin: true),
          ],
        ),
      ];
}
