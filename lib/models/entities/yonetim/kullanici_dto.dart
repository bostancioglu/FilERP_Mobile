import '../firma/firma_dto.dart';
import 'sirket_dto.dart';
import 'sube_dto.dart';
import 'yetki_dto.dart';

class KullaniciDto {
  int? firmaId;
  int? sirketId;
  int? subeId;
  String? kullaniciAdi;
  String? ad;
  String? soyad;
  String? token;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;

  List<YetkiDto>? yetkiler;

  KullaniciDto({
    this.firmaId,
    this.sirketId,
    this.subeId,
    this.kullaniciAdi,
    this.ad,
    this.soyad,
    this.token,
    this.firma,
    this.sirket,
    this.sube,
    this.yetkiler,
  });

  factory KullaniciDto.fromJson(Map<String, dynamic> json) {
    return KullaniciDto(
      firmaId: json["Firmaid"],
      sirketId: json["Sirketid"],
      subeId: json["Subeid"],
      kullaniciAdi: json["Kullaniciadi"],
      ad: json["Ad"],
      soyad: json["Soyad"],
      token: json["Token"],

      firma: json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null,
      sirket: json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null,
      sube: json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null,

      yetkiler: json["Yetki"] != null
          ? (json["Yetki"] as List)
              .map((e) => YetkiDto.fromJson(e))
              .toList()
          : [],
    );
  }
}
