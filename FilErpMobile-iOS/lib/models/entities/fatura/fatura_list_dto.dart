import '../cari/cari_dto.dart';
import '../helper/doviz_dto.dart';

class FaturaListDto {
  final String? id; // Guid → STRING

  final String? belgeno;
  final DateTime? tarih;
  final DateTime? tahsilatTarihi;
  final DateTime? vadeTarihi;
  final String? belgeserino;

  final String? aciklama;

  final double? genelToplam;
  final double? dovizToplam;
  final double? sonGenelToplam;
  final double? kur;

  final int? cariId;
  final int? plasiyerid;
  final int? dovizId;
  final int? belgeturu;
  final int? belgedurum;
  final int? efaturadurum;

  final CariDto? cari;
  final DovizDto? doviz;

  FaturaListDto({
    this.id,
    this.belgeno,
    this.tarih,
    this.tahsilatTarihi,
    this.vadeTarihi,
    this.aciklama,
    this.genelToplam,
    this.dovizToplam,
    this.sonGenelToplam,
    this.kur,
    this.cariId,
    this.plasiyerid,
    this.dovizId,
    this.cari,
    this.doviz,
    this.belgeserino,
    this.belgeturu,
    this.belgedurum,
    this.efaturadurum,
  });

  factory FaturaListDto.fromJson(Map<String, dynamic> json) {
    return FaturaListDto(
      id: json["Id"]?.toString(), // Guid güvenli okuma

      belgeno: json["Belgeno"],
      tarih: json["Tarih"] != null ? DateTime.parse(json["Tarih"]) : null,
      tahsilatTarihi: json["Tahsilattarihi"] != null
          ? DateTime.parse(json["Tahsilattarihi"])
          : null,
      vadeTarihi: json["Vadetarihi"] != null
          ? DateTime.parse(json["Vadetarihi"])
          : null,

      aciklama: json["Aciklama"],

      genelToplam: (json["Geneltoplam"] as num?)?.toDouble(),
      dovizToplam: (json["Doviztoplam"] as num?)?.toDouble(),
      sonGenelToplam: (json["Songeneltoplam"] as num?)?.toDouble(),
      kur: (json["Kur"] as num?)?.toDouble(),

      cariId: json["Cariid"],
      plasiyerid: json["Plasiyerid"],
      dovizId: json["Dovizid"],
      belgeserino : json["Belgeserino"],
      belgeturu: json["Belgeturu"] ?? json["BelgeTuru"],
      belgedurum: json["Belgedurum"] ?? json["BelgeDurum"],
      efaturadurum: json["EFaturadurum"] ,
      // API şu an null dönüyor → güvenli
      cari: json["Cari"] != null ? CariDto.fromJson(json["Cari"]) : null,
      doviz: json["Doviz"] != null ? DovizDto.fromJson(json["Doviz"]) : null,
    );
  }
}
