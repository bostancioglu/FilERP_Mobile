import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import '../firma/sube_dto.dart';
import '../stok/stok_dto.dart';
import '../stok/stokozelliksabit_dto.dart';
import '../olcubirimi/olcubr_dto.dart';
import 'yuklemeplani_dto.dart';
import 'yuklemeplanihareket_dto.dart';
import '../palet/palet_dto.dart';
import '../uretim/uretimpartino_dto.dart';

class YuklemehazirlikDto {
  int? id;

  int? firmaid;
  int? sirketid;
  int? subeid;
  String? yuklemeplaniid;
  int? yuklemeplanihareketid;
  String? paletid;
  int? stokid;
  int? stokozelliksabitid;
  int? olcubrid;
  int? uretimpartinoid;

  DateTime? skt;
  double? miktar;
  String? palethareketidlist;
  String? palethareketmiktarlist;
  String? aciklama;

  FirmaDto? firma;
  SirketDto? sirket;
  SubeDto? sube;
  YuklemeplaniDto? yuklemeplani;
  YuklemeplanihareketDto? yuklemeplanihareket;
  PaletDto? palet;
  StokDto? stok;
  StokozelliksabitDto? stokozelliksabit;
  OlcubrDto? olcubr;
  UretimpartinoDto? uretimpartino;

  YuklemehazirlikDto();

  YuklemehazirlikDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];
    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    subeid = json["Subeid"];
    yuklemeplaniid = json["Yuklemeplaniid"]?.toString();
    yuklemeplanihareketid = json["Yuklemeplanihareketid"];
    paletid = json["Paletid"]?.toString();
    stokid = json["Stokid"];
    stokozelliksabitid = json["Stokozelliksabitid"];
    olcubrid = json["Olcubrid"];
    uretimpartinoid = json["Uretimpartinoid"];

    skt = json["Skt"] != null ? DateTime.parse(json["Skt"]) : null;
    miktar = (json["Miktar"] as num?)?.toDouble();
    palethareketidlist = json["Palethareketidlist"];
    palethareketmiktarlist = json["Palethareketmiktarlist"];
    aciklama = json["Aciklama"];

    firma = json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket = json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    sube = json["Sube"] != null ? SubeDto.fromJson(json["Sube"]) : null;
    yuklemeplani = json["Yuklemeplani"] != null
        ? YuklemeplaniDto.fromJson(json["Yuklemeplani"])
        : null;
    yuklemeplanihareket = json["Yuklemeplanihareket"] != null
        ? YuklemeplanihareketDto.fromJson(json["Yuklemeplanihareket"])
        : null;
    palet =
        json["Palet"] != null ? PaletDto.fromJson(json["Palet"]) : null;
    stok = json["Stok"] != null ? StokDto.fromJson(json["Stok"]) : null;
    stokozelliksabit = json["Stokozelliksabit"] != null
        ? StokozelliksabitDto.fromJson(json["Stokozelliksabit"])
        : null;
    olcubr =
        json["Olcubr"] != null ? OlcubrDto.fromJson(json["Olcubr"]) : null;
    uretimpartino = json["Uretimpartino"] != null
        ? UretimpartinoDto.fromJson(json["Uretimpartino"])
        : null;
  }
}
