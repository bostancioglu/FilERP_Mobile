import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import 'uretimpartino_dto.dart';

class UretimpartinotipDto {
  int? id;

  int? firmaid;
  int? sirketid;
  int? subeid;
  String? ad;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;
  List<UretimpartinoDto>? uretimpartino;

  UretimpartinotipDto();

  UretimpartinotipDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];
    ad = json["Ad"];

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube = json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;

    uretimpartino = (json["Uretimpartino"] as List?)
        ?.map((e) => UretimpartinoDto.fromJson(e))
        .toList();
  }
}
