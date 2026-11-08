import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import 'uretimpartinotip_dto.dart';

class UretimpartinoDto {
  int? id;

  int? firmaid;
  int? sirketid;
  int? subeid;
  String? partino;
  DateTime? tarih;
  int? uretimpartinotipid;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;
  UretimpartinotipDto? uretimpartinotip;

  UretimpartinoDto();

  UretimpartinoDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];
    partino = json["Partino"];
    tarih = json["Tarih"] != null ? DateTime.parse(json["Tarih"]) : null;
    uretimpartinotipid = json["Uretimpartinotipid"];

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube = json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;
    uretimpartinotip = json["Uretimpartinotip"] != null
        ? UretimpartinotipDto.fromJson(json["Uretimpartinotip"])
        : null;
  }
}
