import '../helper/doviz_dto.dart';

class StokfiyatDto {
  int? Id;
  int? Stokid;
  double? Alisfiyat;
  double? Satisfiyat;
  double? Karyuzde;
  double? Maliyet;
  int? Dovizid;
  String? Aciklama;
  int? Sira;

  DovizDto? Doviz;

  StokfiyatDto({
    this.Id,
    this.Stokid,
    this.Alisfiyat,
    this.Satisfiyat,
    this.Karyuzde,
    this.Maliyet,
    this.Dovizid,
    this.Aciklama,
    this.Sira,
    this.Doviz,
  });

  factory StokfiyatDto.fromJson(Map<String, dynamic> json) {
    return StokfiyatDto(
      Id: json['Id'],
      Stokid: json['Stokid'],
      Alisfiyat: (json['Alisfiyat'] as num?)?.toDouble(),
      Satisfiyat: (json['Satisfiyat'] as num?)?.toDouble(),
      Karyuzde: (json['Karyuzde'] as num?)?.toDouble(),
      Maliyet: (json['Maliyet'] as num?)?.toDouble(),
      Dovizid: json['Dovizid'],
      Aciklama: json['Aciklama'],
      Sira: json['Sira'],
      Doviz: json['Doviz'] != null ? DovizDto.fromJson(json['Doviz']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'Id': Id,
      'Stokid': Stokid,
      'Alisfiyat': Alisfiyat,
      'Satisfiyat': Satisfiyat,
      'Karyuzde': Karyuzde,
      'Maliyet': Maliyet,
      'Dovizid': Dovizid,
      'Aciklama': Aciklama,
      'Sira': Sira,
      // DovizDto’da toJson yoksa sorun çıkarmasın diye sadece id ile gidiyoruz:
      'Doviz': Doviz == null
          ? null
          : {'Id': Doviz!.Id, 'Ad': Doviz!.Ad, 'Birim': Doviz!.Birim},
    };
  }
}
