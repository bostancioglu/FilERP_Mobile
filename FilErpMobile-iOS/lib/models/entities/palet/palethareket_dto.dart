import '../firma/firma_dto.dart';
import '../firma/sirket_dto.dart';
import 'palet_dto.dart';
import '../stok/stok_dto.dart';
import '../stok/stokozelliksabit_dto.dart';
import '../olcubirimi/olcubr_dto.dart';
import '../uretim/uretimpartino_dto.dart';
import '../stok/stokhareket_dto.dart';
import '../uretim/uretimpartitakip_rec_dto.dart';

class PalethareketDto {
  int? id;

  int? firmaid;
  int? sirketid;
  String? paletid;
  int? stokid;
  int? stokozelliksabitid;
  int? olcubrid;
  int? uretimpartinoid;

  double? olcubrcarpim;
  DateTime? skt;
  double? miktar;
  String? aciklama;
  String? stokhareketid;

  FirmaDto? firma;
  SirketDto? sirket;
  PaletDto? palet;
  StokDto? stok;
  StokozelliksabitDto? stokozelliksabit;
  OlcubrDto? olcubr;
  UretimpartinoDto? uretimpartino;
  StokhareketDto? stokhareket;

  // Frontend ek
  UretimpartitakipRecDto? uretimpartitakip;

  PalethareketDto();

  PalethareketDto.fromJson(Map<String, dynamic> json) {
    id = json["Id"];

    firmaid = json["Firmaid"];
    sirketid = json["Sirketid"];
    paletid = json["Paletid"]?.toString();
    stokid = json["Stokid"];
    stokozelliksabitid = json["Stokozelliksabitid"];
    olcubrid = json["Olcubrid"];
    uretimpartinoid = json["Uretimpartinoid"];

    olcubrcarpim = (json["Olcubrcarpim"] as num?)?.toDouble();
    skt = json["Skt"] != null ? DateTime.parse(json["Skt"]) : null;
    miktar = (json["Miktar"] as num?)?.toDouble();
    aciklama = json["Aciklama"];
    stokhareketid = json["Stokhareketid"]?.toString();

    firma =
        json["Firma"] != null ? FirmaDto.fromJson(json["Firma"]) : null;
    sirket =
        json["Sirket"] != null ? SirketDto.fromJson(json["Sirket"]) : null;
    palet =
        json["Palet"] != null ? PaletDto.fromJson(json["Palet"]) : null;
    stok =
        json["Stok"] != null ? StokDto.fromJson(json["Stok"]) : null;
    stokozelliksabit = json["Stokozelliksabit"] != null
        ? StokozelliksabitDto.fromJson(json["Stokozelliksabit"])
        : null;
    olcubr =
        json["Olcubr"] != null ? OlcubrDto.fromJson(json["Olcubr"]) : null;
    uretimpartino = json["Uretimpartino"] != null
        ? UretimpartinoDto.fromJson(json["Uretimpartino"])
        : null;
    stokhareket = json["Stokhareket"] != null
        ? StokhareketDto.fromJson(json["Stokhareket"])
        : null;

    uretimpartitakip = json["Uretimpartitakip"] != null
        ? UretimpartitakipRecDto.fromJson(json["Uretimpartitakip"])
        : null;
  }
}
