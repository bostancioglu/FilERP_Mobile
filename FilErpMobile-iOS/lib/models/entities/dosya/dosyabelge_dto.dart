import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';

class DosyabelgeDto {
  int? id;

  int? firmaid;
  int? sirketid; // C# tarafında zorunlu ama API null gönderebilir → ? yaptık
  int? subeid;

  String? belgeid; // Guid → String
  int? belgeid2;
  int? belgeturu;
  int? belgeturu2;
  int? dosyabelgetipi;

  String? belgeserino;
  DateTime? belgetarihi;

  String? ad;
  String? aciklama;
  String? fizikselad;
  int? boyut;
  String? uzanti;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;

  DosyabelgeDto();

  DosyabelgeDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];

    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];

    belgeid = json["Belgeid"]?.toString();
    belgeid2 = json["Belgeid2"];
    belgeturu = json["Belgeturu"];
    belgeturu2 = json["Belgeturu2"];
    dosyabelgetipi = json["Dosyabelgetipi"];

    belgeserino = json["Belgeserino"];
    belgetarihi = json["Belgetarihi"] != null
        ? DateTime.parse(json["Belgetarihi"])
        : null;

    ad = json["Ad"];
    aciklama = json["Aciklama"];
    fizikselad = json["Fizikselad"];
    boyut = json["Boyut"];
    uzanti = json["Uzanti"];

    firma =
        json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket =
        json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube =
        json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;
  }
}
