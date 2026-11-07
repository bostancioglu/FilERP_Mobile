import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import '../stok/stok_dto.dart';
import '../stok/stokozelliksabit_dto.dart';
import '../olcubirimi/olcubr_dto.dart';
import '../siparis/siparis_dto.dart';
import '../siparis/siparishareket_dto.dart';
import '../palet/palettip_dto.dart';
import 'yuklemehazirlik_dto.dart';
import 'yuklemeplani_dto.dart';

class YuklemeplanihareketDto {
  int? id;

  int? firmaid;
  int? sirketid;
  int? subeid;
  String? yuklemeplaniid;
  String? siparisid;
  int? siparishareketid;
  int? stokid;
  int? stokozelliksabitid;
  int? olcubrid;
  int? palettipid;
  int? sevkpaletno;

  double? miktar;
  bool? yuklendi;
  DateTime? yuklemetarihi;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;
  YuklemeplaniDto? yuklemeplani;
  SiparisDto? siparis;
  SiparishareketDto? siparishareket;
  StokDto? stok;
  StokozelliksabitDto? stokozelliksabit;
  OlcubrDto? olcubr;
  PalettipDto? palettip;

  List<YuklemehazirlikDto>? yuklemehazirlik;

  YuklemeplanihareketDto();

  YuklemeplanihareketDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];
    yuklemeplaniid = json["Yuklemeplaniid"]?.toString();
    siparisid = json["Siparisid"]?.toString();
    siparishareketid = json["Siparishareketid"];
    stokid = json["Stokid"];
    stokozelliksabitid = json["Stokozelliksabitid"];
    olcubrid = json["Olcubrid"];
    palettipid = json["Palettipid"];
    sevkpaletno = json["Sevkpaletno"];

    miktar = (json["Miktar"] as num?)?.toDouble();
    yuklendi = json["Yuklendi"];
    yuklemetarihi = json["Yuklemetarihi"] != null
        ? DateTime.parse(json["Yuklemetarihi"])
        : null;

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube = json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;
    yuklemeplani = json["Yuklemeplani"] != null
        ? YuklemeplaniDto.fromJson(json["Yuklemeplani"])
        : null;
    siparis =
        json["Siparis"] != null ? SiparisDto.fromJson(json["Siparis"]) : null;
    siparishareket = json["Siparishareket"] != null
        ? SiparishareketDto.fromJson(json["Siparishareket"])
        : null;
    stok = json["Stok"] != null ? StokDto.fromJson(json["Stok"]) : null;
    stokozelliksabit = json["Stokozelliksabit"] != null
        ? StokozelliksabitDto.fromJson(json["Stokozelliksabit"])
        : null;
    olcubr =
        json["Olcubr"] != null ? OlcubrDto.fromJson(json["Olcubr"]) : null;
    palettip =
        json["Palettip"] != null ? PalettipDto.fromJson(json["Palettip"]) : null;

    yuklemehazirlik = (json["Yuklemehazirlik"] as List?)
        ?.map((e) => YuklemehazirlikDto.fromJson(e))
        .toList();
  }
}
