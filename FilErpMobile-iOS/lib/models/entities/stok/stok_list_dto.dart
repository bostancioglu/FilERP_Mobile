import 'stok_barkod_dto.dart';

class StokListDto {
  int? Id; //BaseDto
  String? Ad;
  String? Kod;
  String? Yabanciad;
  String? Aciklama1;
  String? Aciklama2;
  String? Aciklama3;
  String? Ortakkod;
  String? Barkodlar;
  String? Caristokad;
  String? Caristokkod;
  String? Caristokbarkod;
  String? Searchtext;
  String? TemelolcubrAd;
  String? TemelolcubrKod;
  String? Grupkodu;
  String? Kod1;
  String? Kod2;

  List<StokBarkodDto> stokbarkod;

  StokListDto({
    this.Id,
    this.Ad,
    this.Kod,
    this.Yabanciad,
    this.Aciklama1,
    this.Aciklama2,
    this.Aciklama3,
    this.Ortakkod,
    this.Barkodlar,
    this.Caristokad,
    this.Caristokkod,
    this.Caristokbarkod,
    this.Searchtext,
    this.TemelolcubrAd,
    this.TemelolcubrKod,
    this.Grupkodu,
    this.Kod1,
    this.Kod2,
    List<StokBarkodDto>? stokbarkod,
  }) : stokbarkod = stokbarkod ?? [];

  factory StokListDto.fromJson(Map<String, dynamic> json) {
    return StokListDto(
      Id: json['Id'],
      Ad: json['Ad'],
      Kod: json['Kod'],
      Yabanciad: json['Yabanciad'],
      Aciklama1: json['Aciklama1'],
      Aciklama2: json['Aciklama2'],
      Aciklama3: json['Aciklama3'],
      Ortakkod: json['Ortakkod'],
      Barkodlar: json['Barkodlar'],
      Caristokad: json['Caristokad'],
      Caristokkod: json['Caristokkod'],
      Caristokbarkod: json['Caristokbarkod'],
      Searchtext: json['Searchtext'],
      TemelolcubrAd: json['TemelolcubrAd'],
      TemelolcubrKod: json['TemelolcubrKod'],
      Grupkodu: json['Grupkodu'],
      Kod1: json['Kod1'],
      Kod2: json['Kod2'],
      stokbarkod: (json['Stokbarkod'] as List<dynamic>?)
              ?.map((e) => StokBarkodDto.fromJson(e))
              .toList() ??
          [],
    );
  }

  // Barkodları liste olarak döndüren metod
  List<String> getBarkodListesi() {
    // Önce stokbarkod listesini kontrol et
    if (stokbarkod.isNotEmpty) {
      return stokbarkod
          .where((b) => b.Barkod != null && b.Barkod!.isNotEmpty)
          .map((b) => b.Barkod!)
          .toList();
    }

    // Barkodlar string'ini parse et (" - " ile ayrılmış)
    if (Barkodlar != null && Barkodlar!.isNotEmpty) {
      return Barkodlar!
          .split(' - ')
          .map((b) => b.trim())
          .where((b) => b.isNotEmpty)
          .toList();
    }

    return [];
  }
}