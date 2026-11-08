import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import '../lojistik/arac_dto.dart';
import '../lojistik/surucu_dto.dart';
import 'yuklemeplanihareket_dto.dart';

class YuklemeplaniDto {
  String? id;

  int? firmaid;
  int? sirketid;
  int? subeid;
  int? aracid;
  int? surucuid;

  String? belgeseri;
  int? belgeyil;
  String? belgeno;
  String? belgeserino;
  int? belgeturu;

  DateTime? hazirliktarihi;
  DateTime? yuklemetarihi;
  String? aciklama;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;
  AracDto? arac;
  SurucuDto? surucu;
  List<YuklemeplanihareketDto>? yuklemeplanihareket;

  YuklemeplaniDto();

  YuklemeplaniDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"]?.toString();
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];
    aracid = json["Aracid"];
    surucuid = json["Surucuid"];

    belgeseri = json["Belgeseri"];
    belgeyil = json["Belgeyil"];
    belgeno = json["Belgeno"];
    belgeserino = json["Belgeserino"];
    belgeturu = json["Belgeturu"];

    hazirliktarihi = json["Hazirliktarihi"] != null
        ? DateTime.parse(json["Hazirliktarihi"])
        : null;
    yuklemetarihi = json["Yuklemetarihi"] != null
        ? DateTime.parse(json["Yuklemetarihi"])
        : null;

    aciklama = json["Aciklama"];

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube = json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;
    arac = json["Arac"] != null ? AracDto.fromJson(json["Arac"]) : null;
    surucu = json["Surucu"] != null ? SurucuDto.fromJson(json["Surucu"]) : null;

    yuklemeplanihareket = (json["Yuklemeplanihareket"] as List?)
        ?.map((e) => YuklemeplanihareketDto.fromJson(e))
        .toList();
  }
}
