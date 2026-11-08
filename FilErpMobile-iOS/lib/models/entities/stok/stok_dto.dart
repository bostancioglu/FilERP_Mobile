import 'stok_barkod_dto.dart';
import 'stok_kategori_dto.dart';
import 'stok_fiyat_dto.dart';
import 'stokolcubr_dto.dart';
import 'stokozellik_dto.dart';
import '../olcubirimi/olcubr_dto.dart';

class StokDto {
  double? multiplierFor(int? unitId) {
    if (unitId == null) return null;
    if (unitId == Temelolcubrid) return 1;
    return Stokolcubr.where((u) => u.Olcubrid == unitId).firstOrNull?.Carpim;
  }

  int? Id; // BaseDto
  int? Sirketid;
  int? Temelolcubrid;
  bool? Sirketortak;
  int? Stokkategoriid;
  int? Kartturu;
  int? Stokturu;
  int? Takipsekli;
  int? Partiseritakipmodu;

  String? Ad;
  String? Kod;
  String? Yabanciad;

  String? Aciklama1;
  String? Aciklama2;
  String? Aciklama3;

  double? Kdvalis;
  double? Kdvsatis;
  double? Tevkifatorani;

  String? Grupkodu;
  String? Kod1;
  String? Kod2;
  String? Kod3;
  String? Kod4;
  String? Kod5;

  bool? Stokozelligesahip;
  bool? Stokozellikcariden;

  /// Navigation Properties İLİŞKİLER
  List<StokBarkodDto> Stokbarkod;
  StokkategoriDto? Stokkategori;
  List<StokfiyatDto> Stokfiyat;
  List<StokolcubrDto> Stokolcubr;
  List<StokozellikDto> Stokozellik;
  OlcubrDto? Temelolcubr; // Ana ölçü birimi

  int? Istisnaid;
  String? Gtipkodu;
  double? Otvalis;
  double? Otvsatis;
  String? Muhkodu;
  double? En;
  double? Boy;
  double? Derinlik;
  String? Ebatbr;
  double? Agirlik;
  String? Agirlikbr;
  double? Eticaretmiktar;
  bool? Indirimyapilamaz;
  bool? Promosyonyapilamaz;
  bool? Iadeedilemez;
  bool? Tartilir;
  bool? Ortakkoduvar;
  String? Ortakkod;
  int? Uretimyeri;
  int? Uretimmetodu;
  DateTime? Uretimtarihi;
  int? Etiketolcubrid;
  int? Girisdepoid;
  int? Cikisdepoid;
  int? Stokdepoid;
  int? Yurticialishesapplaniid;
  int? Satistaniadehesapplaniid;
  int? Yurtdisialishesapplaniid;
  int? Fiyatfarkihesapplaniid;
  int? Yurticisatishesapplaniid;
  int? Yurtdisisatishesapplaniid;
  int? Ihrackayitlihesapplaniid;
  int? Alistaniadehesapplaniid;
  int? Satisindirimhesapplaniid;
  int? Hammaddehesapplaniid;
  int? Ilkmaddemalzemehesapplaniid;
  int? Mamulhesapplaniid;
  int? Yarimamulhesapplaniid;
  int? Satilanticarimalmaliyethesapplaniid;
  int? Satilanmamulmaliyethesapplaniid;
  int? Satilanhizmethesapplaniid;
  int? Firehesapplaniid;
  int? Sayimfazlasihesapplaniid;
  int? Sayimeksigihesapplaniid;
  Map<String, dynamic> extraCollections;
  StokDto({
    this.Id,
    this.extraCollections = const {},
    this.Istisnaid,
    this.Gtipkodu,
    this.Otvalis,
    this.Otvsatis,
    this.Muhkodu,
    this.En,
    this.Boy,
    this.Derinlik,
    this.Ebatbr,
    this.Agirlik,
    this.Agirlikbr,
    this.Eticaretmiktar,
    this.Indirimyapilamaz,
    this.Promosyonyapilamaz,
    this.Iadeedilemez,
    this.Tartilir,
    this.Ortakkoduvar,
    this.Ortakkod,
    this.Uretimyeri,
    this.Uretimmetodu,
    this.Uretimtarihi,
    this.Etiketolcubrid,
    this.Girisdepoid,
    this.Cikisdepoid,
    this.Stokdepoid,
    this.Yurticialishesapplaniid,
    this.Satistaniadehesapplaniid,
    this.Yurtdisialishesapplaniid,
    this.Fiyatfarkihesapplaniid,
    this.Yurticisatishesapplaniid,
    this.Yurtdisisatishesapplaniid,
    this.Ihrackayitlihesapplaniid,
    this.Alistaniadehesapplaniid,
    this.Satisindirimhesapplaniid,
    this.Hammaddehesapplaniid,
    this.Ilkmaddemalzemehesapplaniid,
    this.Mamulhesapplaniid,
    this.Yarimamulhesapplaniid,
    this.Satilanticarimalmaliyethesapplaniid,
    this.Satilanmamulmaliyethesapplaniid,
    this.Satilanhizmethesapplaniid,
    this.Firehesapplaniid,
    this.Sayimfazlasihesapplaniid,
    this.Sayimeksigihesapplaniid,
    this.Sirketid,
    this.Temelolcubrid,
    this.Sirketortak,
    this.Stokkategoriid,
    this.Stokturu,
    this.Kartturu,
    this.Takipsekli,
    this.Partiseritakipmodu,
    this.Ad,
    this.Kod,
    this.Yabanciad,
    this.Aciklama1,
    this.Aciklama2,
    this.Aciklama3,
    this.Kdvalis,
    this.Kdvsatis,
    this.Tevkifatorani,
    this.Grupkodu,
    this.Kod1,
    this.Kod2,
    this.Kod3,
    this.Kod4,
    this.Kod5,
    this.Stokkategori,
    this.Stokozelligesahip,
    this.Stokozellikcariden,
    List<StokolcubrDto>? Stokolcubr,
    List<StokBarkodDto>? Stokbarkod,
    List<StokfiyatDto>? Stokfiyat,
    List<StokozellikDto>? Stokozellik,
    this.Temelolcubr,
  })  : Stokolcubr = Stokolcubr ?? [],
        Stokbarkod = Stokbarkod ?? [],
        Stokfiyat = Stokfiyat ?? [],
        Stokozellik = Stokozellik ?? [];

  // =============================
  //  FROM JSON
  // =============================
  factory StokDto.fromJson(Map<String, dynamic> json) {
    return StokDto(
      extraCollections: {
        for (final key in ['Stokalternatif', 'Stoksube']) key: json[key] ?? [],
        if (json.containsKey('Recetesivar')) 'Recetesivar': json['Recetesivar'],
        for (final key in [
          'Istisna',
          'Girisdepo',
          'Cikisdepo',
          'Stokdepo',
          'Etiketolcubr',
          ...[
            for (final key in json.keys)
              if (key.endsWith('hesapplani')) key
          ]
        ])
          if (json[key] is Map)
            key: {
              for (final label in ['Id', 'Kod', 'Ad', 'Aciklama'])
                label: json[key][label]
            }
      },
      Istisnaid: json['Istisnaid'],
      Gtipkodu: json['Gtipkodu'],
      Otvalis: (json['Otvalis'] as num?)?.toDouble(),
      Otvsatis: (json['Otvsatis'] as num?)?.toDouble(),
      Muhkodu: json['Muhkodu'],
      En: (json['En'] as num?)?.toDouble(),
      Boy: (json['Boy'] as num?)?.toDouble(),
      Derinlik: (json['Derinlik'] as num?)?.toDouble(),
      Ebatbr: json['Ebatbr'],
      Agirlik: (json['Agirlik'] as num?)?.toDouble(),
      Agirlikbr: json['Agirlikbr'],
      Eticaretmiktar: (json['Eticaretmiktar'] as num?)?.toDouble(),
      Indirimyapilamaz: json['Indirimyapilamaz'],
      Promosyonyapilamaz: json['Promosyonyapilamaz'],
      Iadeedilemez: json['Iadeedilemez'],
      Tartilir: json['Tartilir'],
      Ortakkoduvar: json['Ortakkoduvar'],
      Ortakkod: json['Ortakkod'],
      Uretimyeri: json['Uretimyeri'],
      Uretimmetodu: json['Uretimmetodu'],
      Uretimtarihi: DateTime.tryParse(json['Uretimtarihi']?.toString() ?? ''),
      Etiketolcubrid: json['Etiketolcubrid'],
      Girisdepoid: json['Girisdepoid'],
      Cikisdepoid: json['Cikisdepoid'],
      Stokdepoid: json['Stokdepoid'],
      Yurticialishesapplaniid: json['Yurticialishesapplaniid'],
      Satistaniadehesapplaniid: json['Satistaniadehesapplaniid'],
      Yurtdisialishesapplaniid: json['Yurtdisialishesapplaniid'],
      Fiyatfarkihesapplaniid: json['Fiyatfarkihesapplaniid'],
      Yurticisatishesapplaniid: json['Yurticisatishesapplaniid'],
      Yurtdisisatishesapplaniid: json['Yurtdisisatishesapplaniid'],
      Ihrackayitlihesapplaniid: json['Ihrackayitlihesapplaniid'],
      Alistaniadehesapplaniid: json['Alistaniadehesapplaniid'],
      Satisindirimhesapplaniid: json['Satisindirimhesapplaniid'],
      Hammaddehesapplaniid: json['Hammaddehesapplaniid'],
      Ilkmaddemalzemehesapplaniid: json['Ilkmaddemalzemehesapplaniid'],
      Mamulhesapplaniid: json['Mamulhesapplaniid'],
      Yarimamulhesapplaniid: json['Yarimamulhesapplaniid'],
      Satilanticarimalmaliyethesapplaniid:
          json['Satilanticarimalmaliyethesapplaniid'],
      Satilanmamulmaliyethesapplaniid: json['Satilanmamulmaliyethesapplaniid'],
      Satilanhizmethesapplaniid: json['Satilanhizmethesapplaniid'],
      Firehesapplaniid: json['Firehesapplaniid'],
      Sayimfazlasihesapplaniid: json['Sayimfazlasihesapplaniid'],
      Sayimeksigihesapplaniid: json['Sayimeksigihesapplaniid'],
      Id: json['Id'],
      Sirketid: json['Sirketid'],
      Temelolcubrid: json['Temelolcubrid'],
      Sirketortak: json['Sirketortak'],
      Stokkategoriid: json['Stokkategoriid'],
      Stokturu: json['Stokturu'],
      Kartturu: json['Kartturu'],
      Takipsekli: json['Takipsekli'],
      Partiseritakipmodu: json['Partiseritakipmodu'],
      Ad: json['Ad'],
      Kod: json['Kod'],
      Yabanciad: json['Yabanciad'],
      Aciklama1: json['Aciklama1'],
      Aciklama2: json['Aciklama2'],
      Aciklama3: json['Aciklama3'],
      Kdvalis: (json['Kdvalis'] as num?)?.toDouble(),
      Kdvsatis: (json['Kdvsatis'] as num?)?.toDouble(),
      Tevkifatorani: (json['Tevkifatorani'] as num?)?.toDouble(),
      Grupkodu: json['Grupkodu'],
      Kod1: json['Kod1'],
      Kod2: json['Kod2'],
      Kod3: json['Kod3'],
      Kod4: json['Kod4'],
      Kod5: json['Kod5'],
      Stokkategori: json['Stokkategori'] != null
          ? StokkategoriDto.fromJson(json['Stokkategori'])
          : null,
      Stokolcubr: (json['Stokolcubr'] as List<dynamic>?)
              ?.map((e) => StokolcubrDto.fromJson(e))
              .toList() ??
          [],
      Temelolcubr: json['Temelolcubr'] != null
          ? OlcubrDto.fromJson(json['Temelolcubr'])
          : null,
      Stokbarkod: (json['Stokbarkod'] as List<dynamic>?)
              ?.map((e) => StokBarkodDto.fromJson(e))
              .toList() ??
          [],
      Stokfiyat: (json['Stokfiyat'] as List<dynamic>?)
              ?.map((e) => StokfiyatDto.fromJson(e))
              .toList() ??
          [],
      Stokozelligesahip: json['Stokozelligesahip'],
      Stokozellikcariden: json['Stokozellikcariden'],
      Stokozellik: (json['Stokozellik'] as List<dynamic>?)
              ?.map((e) => StokozellikDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  // =============================
  //  TO JSON (NULL SAFE)
  // =============================
  Map<String, dynamic> toJson() {
    return {
      'Istisnaid': Istisnaid,
      'Gtipkodu': Gtipkodu,
      'Otvalis': Otvalis,
      'Otvsatis': Otvsatis,
      'Muhkodu': Muhkodu,
      'En': En,
      'Boy': Boy,
      'Derinlik': Derinlik,
      'Ebatbr': Ebatbr,
      'Agirlik': Agirlik,
      'Agirlikbr': Agirlikbr,
      'Eticaretmiktar': Eticaretmiktar,
      'Indirimyapilamaz': Indirimyapilamaz,
      'Promosyonyapilamaz': Promosyonyapilamaz,
      'Iadeedilemez': Iadeedilemez,
      'Tartilir': Tartilir,
      'Ortakkoduvar': Ortakkoduvar,
      'Ortakkod': Ortakkod,
      'Uretimyeri': Uretimyeri,
      'Uretimmetodu': Uretimmetodu,
      'Uretimtarihi': Uretimtarihi?.toIso8601String(),
      'Etiketolcubrid': Etiketolcubrid,
      'Girisdepoid': Girisdepoid,
      'Cikisdepoid': Cikisdepoid,
      'Stokdepoid': Stokdepoid,
      'Yurticialishesapplaniid': Yurticialishesapplaniid,
      'Satistaniadehesapplaniid': Satistaniadehesapplaniid,
      'Yurtdisialishesapplaniid': Yurtdisialishesapplaniid,
      'Fiyatfarkihesapplaniid': Fiyatfarkihesapplaniid,
      'Yurticisatishesapplaniid': Yurticisatishesapplaniid,
      'Yurtdisisatishesapplaniid': Yurtdisisatishesapplaniid,
      'Ihrackayitlihesapplaniid': Ihrackayitlihesapplaniid,
      'Alistaniadehesapplaniid': Alistaniadehesapplaniid,
      'Satisindirimhesapplaniid': Satisindirimhesapplaniid,
      'Hammaddehesapplaniid': Hammaddehesapplaniid,
      'Ilkmaddemalzemehesapplaniid': Ilkmaddemalzemehesapplaniid,
      'Mamulhesapplaniid': Mamulhesapplaniid,
      'Yarimamulhesapplaniid': Yarimamulhesapplaniid,
      'Satilanticarimalmaliyethesapplaniid':
          Satilanticarimalmaliyethesapplaniid,
      'Satilanmamulmaliyethesapplaniid': Satilanmamulmaliyethesapplaniid,
      'Satilanhizmethesapplaniid': Satilanhizmethesapplaniid,
      'Firehesapplaniid': Firehesapplaniid,
      'Sayimfazlasihesapplaniid': Sayimfazlasihesapplaniid,
      'Sayimeksigihesapplaniid': Sayimeksigihesapplaniid,
      'Id': Id,
      'Sirketid': Sirketid,
      'Stokozelligesahip': Stokozelligesahip,
      'Stokozellikcariden': Stokozellikcariden,
      'Temelolcubr': Temelolcubr?.toJson(),
      'Temelolcubrid': Temelolcubrid,
      'Sirketortak': Sirketortak,
      'Stokkategoriid': Stokkategoriid,
      'Stokturu': Stokturu,
      'Kartturu': Kartturu,
      'Takipsekli': Takipsekli,
      'Partiseritakipmodu': Partiseritakipmodu,
      'Ad': Ad,
      'Kod': Kod,
      'Yabanciad': Yabanciad,
      'Aciklama1': Aciklama1,
      'Aciklama2': Aciklama2,
      'Aciklama3': Aciklama3,
      'Kdvalis': Kdvalis,
      'Kdvsatis': Kdvsatis,
      'Tevkifatorani': Tevkifatorani,
      'Grupkodu': Grupkodu,
      'Kod1': Kod1,
      'Kod2': Kod2,
      'Kod3': Kod3,
      'Kod4': Kod4,
      'Kod5': Kod5,

      // 🔒 NULL SAFE BAĞLANTILAR
      'Stokkategori': Stokkategori == null ? null : Stokkategori!.toJson(),

      ...extraCollections,
      'Stokozellik': Stokozellik.map((e) => e.toJson()).toList(),
      'Stokbarkod':
          Stokbarkod.isEmpty ? [] : Stokbarkod.map((e) => e.toJson()).toList(),

      'Stokfiyat':
          Stokfiyat.isEmpty ? [] : Stokfiyat.map((e) => e.toJson()).toList(),

      'Stokolcubr':
          Stokolcubr.isEmpty ? [] : Stokolcubr.map((e) => e.toJson()).toList(),
    };
  }

  // =============================
  //  TO SAVE&UPDATE
  // =============================
  Map<String, dynamic> toSaveJson(
      {bool includeKod = true, bool includeId = false}) {
    final data = <String, dynamic>{};

    if (includeId) data["Id"] = Id;
    if (includeKod) data["Kod"] = Kod;

    data.addAll({
      'Istisnaid': Istisnaid,
      'Gtipkodu': Gtipkodu,
      'Otvalis': Otvalis,
      'Otvsatis': Otvsatis,
      'Muhkodu': Muhkodu,
      'En': En,
      'Boy': Boy,
      'Derinlik': Derinlik,
      'Ebatbr': Ebatbr,
      'Agirlik': Agirlik,
      'Agirlikbr': Agirlikbr,
      'Eticaretmiktar': Eticaretmiktar,
      'Indirimyapilamaz': Indirimyapilamaz,
      'Promosyonyapilamaz': Promosyonyapilamaz,
      'Iadeedilemez': Iadeedilemez,
      'Tartilir': Tartilir,
      'Ortakkoduvar': Ortakkoduvar,
      'Ortakkod': Ortakkod,
      'Uretimyeri': Uretimyeri,
      'Uretimmetodu': Uretimmetodu,
      'Uretimtarihi': Uretimtarihi?.toIso8601String(),
      'Etiketolcubrid': Etiketolcubrid,
      'Girisdepoid': Girisdepoid,
      'Cikisdepoid': Cikisdepoid,
      'Stokdepoid': Stokdepoid,
      'Yurticialishesapplaniid': Yurticialishesapplaniid,
      'Satistaniadehesapplaniid': Satistaniadehesapplaniid,
      'Yurtdisialishesapplaniid': Yurtdisialishesapplaniid,
      'Fiyatfarkihesapplaniid': Fiyatfarkihesapplaniid,
      'Yurticisatishesapplaniid': Yurticisatishesapplaniid,
      'Yurtdisisatishesapplaniid': Yurtdisisatishesapplaniid,
      'Ihrackayitlihesapplaniid': Ihrackayitlihesapplaniid,
      'Alistaniadehesapplaniid': Alistaniadehesapplaniid,
      'Satisindirimhesapplaniid': Satisindirimhesapplaniid,
      'Hammaddehesapplaniid': Hammaddehesapplaniid,
      'Ilkmaddemalzemehesapplaniid': Ilkmaddemalzemehesapplaniid,
      'Mamulhesapplaniid': Mamulhesapplaniid,
      'Yarimamulhesapplaniid': Yarimamulhesapplaniid,
      'Satilanticarimalmaliyethesapplaniid':
          Satilanticarimalmaliyethesapplaniid,
      'Satilanmamulmaliyethesapplaniid': Satilanmamulmaliyethesapplaniid,
      'Satilanhizmethesapplaniid': Satilanhizmethesapplaniid,
      'Firehesapplaniid': Firehesapplaniid,
      'Sayimfazlasihesapplaniid': Sayimfazlasihesapplaniid,
      'Sayimeksigihesapplaniid': Sayimeksigihesapplaniid,
      'Partiseritakipmodu': Partiseritakipmodu,
      'Stokozelligesahip': Stokozelligesahip,
      'Stokozellikcariden': Stokozellikcariden,
      "Ad": Ad,
      "Yabanciad": Yabanciad,
      "Aciklama1": Aciklama1,
      "Aciklama2": Aciklama2,
      "Aciklama3": Aciklama3,
      "Grupkodu": Grupkodu,
      "Kod1": Kod1,
      "Kod2": Kod2,
      "Kod3": Kod3,
      "Kod4": Kod4,
      "Kod5": Kod5,
      "Kdvalis": Kdvalis,
      "Kdvsatis": Kdvsatis,
      "Tevkifatorani": Tevkifatorani,
      "Temelolcubrid": Temelolcubrid,
      "Stokkategoriid": Stokkategoriid,
      "Kartturu": Kartturu,
      "Stokturu": Stokturu,
      "Takipsekli": Takipsekli,
      "Sirketortak": Sirketortak,
    });

    return data;
  }
}
