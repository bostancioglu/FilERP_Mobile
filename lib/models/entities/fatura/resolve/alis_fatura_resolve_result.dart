/// Backend'in [POST] FaturaAlis/ResolveFromImage yanıtı (multipart/form-data, UploadFile).
/// Camelcase/PascalCase serileştirme farkına karşı dayanıklı okuma yapılır.
dynamic _g(Map<String, dynamic> j, String pascal) {
  if (j.containsKey(pascal)) return j[pascal];
  final camel = pascal[0].toLowerCase() + pascal.substring(1);
  if (j.containsKey(camel)) return j[camel];
  return null;
}

double? _d(dynamic v) => v == null ? null : (v as num).toDouble();
DateTime? _dt(dynamic v) => v == null ? null : DateTime.tryParse(v.toString());

class AlisFaturaResolveResult {
  final bool kaydaHazir;
  final AlisFaturaResolveUstbilgiModel ustbilgi;
  final List<AlisFaturaResolveHareketlerModel> hareketler;
  final Map<String, dynamic>? faturaCreateDto; // KaydaHazir==true ise dolu — ileride kaydetme akışında kullanılacak

  /// Sunucudan gelen ham JSON — "Senkronize Et" (Resolve) çağrısında aynen
  /// geri gönderilir; backend eksik alanları (yeni oluşturulan cari/stok vb.)
  /// kendi tarafında yeniden çözer, bu yüzden client'ın DTO'yu yeniden
  /// serileştirmesine gerek yok.
  final Map<String, dynamic> raw;

  AlisFaturaResolveResult({
    required this.kaydaHazir,
    required this.ustbilgi,
    required this.hareketler,
    required this.raw,
    this.faturaCreateDto,
  });

  factory AlisFaturaResolveResult.fromJson(Map<String, dynamic> j) {
    final hareketlerRaw = (_g(j, 'Hareketler') as List?) ?? [];
    return AlisFaturaResolveResult(
      kaydaHazir: _g(j, 'KaydaHazir') == true,
      ustbilgi: AlisFaturaResolveUstbilgiModel.fromJson(
          (_g(j, 'Ustbilgi') as Map<String, dynamic>?) ?? {}),
      hareketler: hareketlerRaw
          .map((e) => AlisFaturaResolveHareketlerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      faturaCreateDto: _g(j, 'FaturaCreateDto') as Map<String, dynamic>?,
      raw: j,
    );
  }
}

class AlisFaturaResolveUstbilgiModel {
  final bool kaydaHazir;
  final List<AlisFaturaResolveEksiklerModel> eksikler;
  final String? kaynakFaturaNo;
  final DateTime? kaynakTarih;
  final String? kaynakDovizKodu;
  final String? kaynakSaticiUnvan;
  final String? kaynakSaticiVergino;
  final String? kaynakSaticiAdres;
  final String? kaynakAliciUnvan;
  final String? kaynakAliciVergino;
  final double? kaynakAratoplam;
  final double? kaynakKdvtutar;
  final double? kaynakGeneltoplam;
  final double? kaynakOdenecekTutar;

  /// FaturaDto.Cari.Id — sunucu cariyi (VKN/unvan eşleşmesiyle) bulmuşsa dolu gelir.
  final int? resolvedCariId;

  AlisFaturaResolveUstbilgiModel({
    required this.kaydaHazir,
    required this.eksikler,
    this.kaynakFaturaNo,
    this.kaynakTarih,
    this.kaynakDovizKodu,
    this.kaynakSaticiUnvan,
    this.kaynakSaticiVergino,
    this.kaynakSaticiAdres,
    this.kaynakAliciUnvan,
    this.kaynakAliciVergino,
    this.kaynakAratoplam,
    this.kaynakKdvtutar,
    this.kaynakGeneltoplam,
    this.kaynakOdenecekTutar,
    this.resolvedCariId,
  });

  factory AlisFaturaResolveUstbilgiModel.fromJson(Map<String, dynamic> j) {
    final eksiklerRaw = (_g(j, 'Eksikler') as List?) ?? [];
    final faturaDto = _g(j, 'FaturaDto') as Map<String, dynamic>?;
    final cariDto = faturaDto != null ? _g(faturaDto, 'Cari') as Map<String, dynamic>? : null;
    final resolvedCariId = cariDto != null ? (_g(cariDto, 'Id') as num?)?.toInt() : null;
    return AlisFaturaResolveUstbilgiModel(
      kaydaHazir: _g(j, 'KaydaHazir') == true,
      eksikler: eksiklerRaw
          .map((e) => AlisFaturaResolveEksiklerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      kaynakFaturaNo: _g(j, 'KaynakFaturaNo')?.toString(),
      kaynakTarih: _dt(_g(j, 'KaynakTarih')),
      kaynakDovizKodu: _g(j, 'KaynakDovizKodu')?.toString(),
      kaynakSaticiUnvan: _g(j, 'KaynakSaticiUnvan')?.toString(),
      kaynakSaticiVergino: _g(j, 'KaynakSaticiVergino')?.toString(),
      kaynakSaticiAdres: _g(j, 'KaynakSaticiAdres')?.toString(),
      kaynakAliciUnvan: _g(j, 'KaynakAliciUnvan')?.toString(),
      kaynakAliciVergino: _g(j, 'KaynakAliciVergino')?.toString(),
      kaynakAratoplam: _d(_g(j, 'KaynakAratoplam')),
      kaynakKdvtutar: _d(_g(j, 'KaynakKdvtutar')),
      kaynakGeneltoplam: _d(_g(j, 'KaynakGeneltoplam')),
      kaynakOdenecekTutar: _d(_g(j, 'KaynakOdenecekTutar')),
      resolvedCariId: resolvedCariId,
    );
  }
}

class AlisFaturaResolveHareketlerModel {
  final bool kaydaHazir;
  final List<AlisFaturaResolveEksiklerModel> eksikler;
  final int sira;
  final String? kaynakStokadi;
  final String? kaynakSaticiStokkodu;
  final String? kaynakBarkod;
  final String? kaynakOlcubrkodu;
  final double? kaynakMiktar;
  final double? kaynakBirimFiyat;
  final double? kaynakSatirTutari;
  final double? kaynakKdvorani;
  final double? kaynakKdvtutar;

  /// Backend'in KaynakOlcubrkodu'ndan çözdüğü Olcubr.Id — Stokcari eşleşmesi
  /// için gereklidir (MatchCariOlcubr, Cariolcubrid boşsa eşleşmeyi reddeder).
  final int? cariolcubrid;

  AlisFaturaResolveHareketlerModel({
    required this.kaydaHazir,
    required this.eksikler,
    required this.sira,
    this.kaynakStokadi,
    this.kaynakSaticiStokkodu,
    this.kaynakBarkod,
    this.kaynakOlcubrkodu,
    this.kaynakMiktar,
    this.kaynakBirimFiyat,
    this.kaynakSatirTutari,
    this.kaynakKdvorani,
    this.kaynakKdvtutar,
    this.cariolcubrid,
  });

  factory AlisFaturaResolveHareketlerModel.fromJson(Map<String, dynamic> j) {
    final eksiklerRaw = (_g(j, 'Eksikler') as List?) ?? [];
    return AlisFaturaResolveHareketlerModel(
      kaydaHazir: _g(j, 'KaydaHazir') == true,
      eksikler: eksiklerRaw
          .map((e) => AlisFaturaResolveEksiklerModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      sira: (_g(j, 'Sira') as num?)?.toInt() ?? 0,
      kaynakStokadi: _g(j, 'KaynakStokadi')?.toString(),
      kaynakSaticiStokkodu: _g(j, 'KaynakSaticiStokkodu')?.toString(),
      kaynakBarkod: _g(j, 'KaynakBarkod')?.toString(),
      kaynakOlcubrkodu: _g(j, 'KaynakOlcubrkodu')?.toString(),
      kaynakMiktar: _d(_g(j, 'KaynakMiktar')),
      kaynakBirimFiyat: _d(_g(j, 'KaynakBirimFiyat')),
      kaynakSatirTutari: _d(_g(j, 'KaynakSatirTutari')),
      kaynakKdvorani: _d(_g(j, 'KaynakKdvorani')),
      kaynakKdvtutar: _d(_g(j, 'KaynakKdvtutar')),
      cariolcubrid: (_g(j, 'Cariolcubrid') as num?)?.toInt(),
    );
  }
}

/// AlisFaturaResolveEksikTipi enum'una karşılık gelir (backend'de byte).
class EksikTipiCouples {
  const EksikTipiCouples._();
  static const cariBulunamadi = 1;
  static const dovizBulunamadi = 2;
  static const plasiyerBulunamadi = 3;
  static const projeBulunamadi = 4;
  static const stokBulunamadi = 10;
  static const olcubrBulunamadi = 11;
  static const depoBulunamadi = 12;
  static const stokOzellikBulunamadi = 13;
  static const depoAdresEksik = 14;

  static const _adlar = {
    cariBulunamadi: 'CariBulunamadi',
    dovizBulunamadi: 'DovizBulunamadi',
    plasiyerBulunamadi: 'PlasiyerBulunamadi',
    projeBulunamadi: 'ProjeBulunamadi',
    stokBulunamadi: 'StokBulunamadi',
    olcubrBulunamadi: 'OlcubrBulunamadi',
    depoBulunamadi: 'DepoBulunamadi',
    stokOzellikBulunamadi: 'StokOzellikBulunamadi',
    depoAdresEksik: 'DepoAdresEksik',
  };

  /// Backend hem int hem string enum adı gönderebilir — ikisini de çözer.
  static int? parse(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toInt();
    final s = v.toString();
    for (final e in _adlar.entries) {
      if (e.value == s) return e.key;
    }
    return int.tryParse(s);
  }
}

class AlisFaturaResolveEksiklerModel {
  final String alan;
  final String mesaj;
  final String? kaynakDeger;
  final int? eksikTipi;

  AlisFaturaResolveEksiklerModel({required this.alan, required this.mesaj, this.kaynakDeger, this.eksikTipi});

  factory AlisFaturaResolveEksiklerModel.fromJson(Map<String, dynamic> j) {
    return AlisFaturaResolveEksiklerModel(
      alan: _g(j, 'Alan')?.toString() ?? '',
      mesaj: _g(j, 'Mesaj')?.toString() ?? '',
      kaynakDeger: _g(j, 'KaynakDeger')?.toString(),
      eksikTipi: EksikTipiCouples.parse(_g(j, 'EksikTipi')),
    );
  }
}
